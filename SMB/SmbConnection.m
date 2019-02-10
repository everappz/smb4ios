#import "SmbConnection.h"
#import "SmbMessage.h"
#import "SmbNegotiateProtocolMessage.h"
#import "SmbSessionSetupMessage.h"
#import "SmbTreeConnectMessage.h"
#import "SmbTreeDisconnectMessage.h"
#import "SmbNtCreateMessage.h"
#import "SmbTransactionMessage.h"
#import "SmbReadMessage.h"
#import "SmbWriteMessage.h"
#import "SmbCloseMessage.h"
#import "SmbLogoffMessage.h"

#import "ntlm.h"
#import "DceRpc.h"
#import "RapNetServerEnum2.h"

#import "Utils.h"
#import "NSMutableData+SMB.h"
#import "NbtConnection.h"

//#define LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#define LOG(format, ...)

//#define LOGDATA(data) [Utils logData:data]
#define LOGDATA(data)


@implementation SmbConnection
{
	int pid;
	int mid;
	int uid;
	int tid;
	int fid;
	int dceCallId;
	NSData *printHandle;
	bool nbtWrite;
}

- (id) init
{
	if (self = [super init])
	{
		pid = 1;
		mid = 1;
		uid = 0;
		tid = 0;
		fid = 0;

		dceCallId = 1;
	
		self.error = NULL;
	}
	return self;
}

- (void) setError:(NSString *)value;
{
	_error = value;
	if (value != NULL)
		LOG(@"SMB error: %@", value);
}

- (void) connectToAddress:(NSString *)address
{
	NSLog(@"Method not supported by SmbConnection");
	assert(false);
}

- (void) connectToHost:(NSString *)host
{
	self.host = host;
	self.error = NULL;

    [super connectToAddress:self.host port:445];
}

- (bool) runSmb:(SmbMessage *)smb
{
	LOG(@"%@", [smb class]);

	smb.pid = pid;
	smb.mid = mid++;
	smb.uid = uid;
	smb.tid = tid;

	NSData *request = [smb getRequest];
	LOGDATA(request);

	if (![self writeNbtMessage:request])
	{
		self.error = [NSString stringWithFormat:@"%@: Write failed", [smb class]];
		return false;
	}
	
	NSData *response = [self read];
	LOGDATA(response);
	
	if (![smb parseResponse:response])
	{
		self.error = [NSString stringWithFormat:@"%@: %@", [smb class], smb.error];
		return false;
	}
	
	return true;
}

- (bool) runRpc:(DceRpcMessage *)rpc
{
	// We're writing and reading RPC data to a pipe. It may fragment on SMB level,
	// requiring SmbWrite and SmbRead. SMB chunk appears to be maybe 1024 bytes.
	// It may also fragment on RPC level, that's what FIRST_FRAG and LAST_FRAG are
	// for. RPC chunk appears to be 4280 bytes for some reason.

	rpc.callId = dceCallId++;
	[rpc prepareRequest];

	LOG(@"%@", [rpc class]);

	int frag = 0;
	while (frag < rpc.requestFragments-1)
	{
		LOG(@"write frag %i", frag);

		SmbWriteMessage *write = [[SmbWriteMessage alloc] init];
		write.fid = fid;
		write.data = [rpc getRequestFragment:frag];
		if (![self runSmb:write])
			return false;
	
		frag++;
	}
	
	NSMutableData *setup = [NSMutableData data];
	[setup appendWordLE:TRANS_TRANSACT_NMPIPE];
	[setup appendWordLE:fid];

	// Run Transact first
	SmbTransactMessage *transaction = [[SmbTransactMessage alloc] init];
	transaction.name = @"\\PIPE\\";
	transaction.expectedParameters = 0;
	transaction.setup = setup;
	transaction.transactionData = [rpc getRequestFragment:frag];
	if (![self runSmb:transaction])
		return false;

	SmbReadMessage *read = [[SmbReadMessage alloc] init];
	read.fid = fid;

	bool eof = transaction.eof;
	NSMutableData *fragment = [NSMutableData dataWithData:transaction.transactionData];

	while (true)
	{
		// Read until EOF
		while (!eof)
		{
			if (![self runSmb:read])
				return false;

			[fragment appendData:read.data];
			eof = read.eof;
		}

		// Now we have complete RPC fragment
		int res = [rpc receiveFragment:fragment];
		if (res == DCERPC_PARSE_MORE)
		{
			// Not the last fragment, read some more
			LOG(@"next frag");
			fragment.length = 0;
			eof = false;
			continue;
		}
		if (res == DCERPC_PARSE_ERROR)
		{
			self.error = [NSString stringWithFormat:@"%@: %@", [rpc class], rpc.error];
			return false;
		}

		// And it's the last fragment
		break;
	}

	if (![rpc parseResponse])
	{
		self.error = [NSString stringWithFormat:@"%@: %@", [rpc class], rpc.error];
		return false;
	}

	return true;
}

- (bool) treeConnect:(NSString *)path anonymous:(bool)anonymous
{
	// Negotiate Protocol
	SmbNegotiateProtocolMessage *negotiate = [[SmbNegotiateProtocolMessage alloc] init];
	if (![self runSmb:negotiate])
		return false;

	// Session Setup
	if (anonymous)
	{
		SmbSessionSetupMessage *sessionSetup = [[SmbSessionSetupMessage alloc] init];
		sessionSetup.anonymous = true;
		sessionSetup.sessionKey = negotiate.sessionKey;
		if (![self runSmb:sessionSetup])
			return false;
		
		uid = sessionSetup.uid;
	}
	else
	{
        
        tSmbNtlmAuthRequest authRequest;
        buildSmbNtlmAuthRequest(&authRequest, "", "");

        SmbSessionSetupMessage *sessionSetupN = [[SmbSessionSetupMessage alloc] init];
        sessionSetupN.sessionKey = negotiate.sessionKey;
        sessionSetupN.requestSecurityBlob = [NSData dataWithBytes:&authRequest length:sizeof(authRequest)];
        if (![self runSmb:sessionSetupN])
            return false;
        
        uid = sessionSetupN.uid;

        tSmbNtlmAuthChallenge challenge;
        memset(&challenge, 0, sizeof(challenge));
        memcpy(&challenge, sessionSetupN.responseSecurityBlob.bytes, sessionSetupN.responseSecurityBlob.length);

        NSString *username = (self.username == NULL ? @"" : self.username);
        NSString *password = (self.password == NULL ? @"" : self.password);

        tSmbNtlmAuthResponse authResponse;
        buildSmbNtlmAuthResponse(&challenge, &authResponse, [username UTF8String], [password UTF8String]);

        SmbSessionSetupMessage *sessionSetupA = [[SmbSessionSetupMessage alloc] init];
        sessionSetupA.sessionKey = negotiate.sessionKey;
        sessionSetupA.requestSecurityBlob = [NSData dataWithBytes:&authResponse length:sizeof(authResponse)];
        if (![self runSmb:sessionSetupA])
            return false;
        
	}

	// Tree Connect
	SmbTreeConnectMessage *treeConnect = [[SmbTreeConnectMessage alloc] init];
	treeConnect.path = path;
	if (![self runSmb:treeConnect])
		return false;

	tid = treeConnect.tid;

	return true;
}

- (bool) treeDisconnect
{
	SmbTreeDisconnectMessage *treeDisconnect = [[SmbTreeDisconnectMessage alloc] init];
	if (![self runSmb:treeDisconnect])
		return false;

	SmbLogoffMessage *logoff = [[SmbLogoffMessage alloc] init];
	if (![self runSmb:logoff])
		return false;
		
	return true;
}

- (bool) openPipe:(NSString *)filename syntax:(NSString *)syntax
{
	SmbNtCreateMessage *ntCreate = [[SmbNtCreateMessage alloc] init];
	ntCreate.filename = filename;
	if (![self runSmb:ntCreate])
		return false;

	fid = ntCreate.fid;

	DceRpcBind *rpcBind = [[DceRpcBind alloc] init];
	rpcBind.abstractSyntax = syntax;
	if (![self runRpc:rpcBind])
		return false;
		
	return true;
}

- (bool) enumDomains
{
	return [self enumServers:SV_TYPE_DOMAIN_ENUM domain:NULL];
}

- (bool) enumServers:(NSString *)domain
{
	return [self enumServers:SV_TYPE_ALL domain:domain];
}

- (bool) enumServers:(UInt32)serverType domain:(NSString *)domain
{
	if (![self treeConnect:[NSString stringWithFormat:@"\\\\%@\\IPC$", self.host] anonymous:true])
		return false;

	// This call can be fragmented by SMB or RAP, but this should be good
	// for maybe 100 records, so I don't care right now.
	RapNetServerEnum2 *netServerEnum2 = [[RapNetServerEnum2 alloc] init];
	netServerEnum2.serverType = serverType;
	netServerEnum2.domain = domain;

	SmbTransactMessage *transaction = [[SmbTransactMessage alloc] init];
	transaction.name = @"\\PIPE\\LANMAN";
	transaction.transactionParameters = [netServerEnum2 getRequest];
	transaction.expectedParameters = 8;
	if (![self runSmb:transaction])
		return false;

	if (![netServerEnum2 parseResponseParameters:transaction.transactionParameters
		data:transaction.transactionData])
	{
		self.error = [NSString stringWithFormat:@"%@: %@", [netServerEnum2 class], netServerEnum2.error];
		return false;
	}

	if (![self treeDisconnect])
		return false;
	
	self.items = netServerEnum2.shares;
	LOG(@"received %i shares", self.items.count);
	
	return true;
}

- (bool) enumShares
{
	if (![self treeConnect:[NSString stringWithFormat:@"\\\\%@\\IPC$", self.host] anonymous:false])
		return false;

	if (![self openPipe:SRVSVC_PATH syntax:SRVSVC_SYNTAX])
		return false;

	DceRpcEnumAll *rpcEnumAll = [[DceRpcEnumAll alloc] init];
	rpcEnumAll.host = self.host;
	if (![self runRpc:rpcEnumAll])
		return false;
		
	SmbCloseMessage *close = [[SmbCloseMessage alloc] init];
	close.fid = fid;
	if (![self runSmb:close])
		return false;

	if (![self treeDisconnect])
		return false;
	
	self.items = rpcEnumAll.shares;
	
	return true;
}

- (bool) getPrinter:(NSString *)printerName
{
	if (![self treeConnect:[NSString stringWithFormat:@"\\\\%@\\IPC$", self.host] anonymous:false])
		return false;

	if (![self openPipe:SPOOLSS_PATH syntax:SPOOLSS_SYNTAX])
		return false;

	DceRpcOpenPrinterEx *rpcOpenPrinter = [[DceRpcOpenPrinterEx alloc] init];
	rpcOpenPrinter.printerName = [NSString stringWithFormat:@"\\\\%@\\%@", self.host, printerName];
	if (![self runRpc:rpcOpenPrinter])
		return false;

	NSData *policyHandle = rpcOpenPrinter.policyHandle;

	DceRpcGetPrinter *rpcGetPrinter;

	do
	{
		rpcGetPrinter = [[DceRpcGetPrinter alloc] init];
		rpcGetPrinter.policyHandle = policyHandle;
		if (![self runRpc:rpcGetPrinter])
			break;
			
		if (rpcGetPrinter.statusCode == RPC_GETPRINTER_INSUFFICIENT_BUFFER)
		{
			if (![self runRpc:rpcGetPrinter])
				break;
		}

	} while (false);

	DceRpcClosePrinter *rpcClose = [[DceRpcClosePrinter alloc] init];
	rpcClose.policyHandle = policyHandle;
	if (![self runRpc:rpcClose])
		return false;

	if (![self treeDisconnect])
		return false;

	self.printerInfo = rpcGetPrinter.printerInfo;
	return true;
}

- (bool) startPrint:(NSString *)printerName
{
	if (![self treeConnect:[NSString stringWithFormat:@"\\\\%@\\IPC$", self.host] anonymous:false])
		return false;

	if (![self openPipe:SPOOLSS_PATH syntax:SPOOLSS_SYNTAX])
		return false;

	DceRpcOpenPrinterEx *rpcOpenPrinter = [[DceRpcOpenPrinterEx alloc] init];
	rpcOpenPrinter.printerName = [NSString stringWithFormat:@"\\\\%@\\%@", self.host, printerName];
	if (![self runRpc:rpcOpenPrinter])
		return false;

	printHandle = rpcOpenPrinter.policyHandle;

	DceRpcStartDocPrinter *rpcStartDoc = [[DceRpcStartDocPrinter alloc] init];
	rpcStartDoc.policyHandle = printHandle;
	rpcStartDoc.documentName = @"Untitled";
	rpcStartDoc.dataType = @"RAW";
	if (![self runRpc:rpcStartDoc])
		return false;
		
	return true;
}

- (bool) writeNbtMessage:(NSData *)data // override
{
	nbtWrite = true;
	bool result = [super writeNbtMessage:data];
	nbtWrite = false;
	return result;
}

- (bool) write:(NSData *)message // override
{
	// Just write normally if message sent from this class
	if (nbtWrite)
		return [super write:message];

	// Message sent from somewhere else, wrap in SMB stuff
	if (printHandle == NULL)
	{
		NSLog(@"SmbConnection: no printer opened");
		return false;
	}

	DceRpcWritePrinter *rpcWritePrinter = [[DceRpcWritePrinter alloc] init];
	rpcWritePrinter.policyHandle = printHandle;
	rpcWritePrinter.data = message;
	if (![self runRpc:rpcWritePrinter])
		return false;
		
	return true;
}

- (bool) endPrint
{
	if (printHandle == NULL)
	{
		NSLog(@"SmbConnection: no printer opened");
		return false;
	}

	DceRpcEndDocPrinter *rpcEndDoc = [[DceRpcEndDocPrinter alloc] init];
	rpcEndDoc.policyHandle = printHandle;
	if (![self runRpc:rpcEndDoc])
		return false;

	DceRpcClosePrinter *rpcClose = [[DceRpcClosePrinter alloc] init];
	rpcClose.policyHandle = printHandle;
	if (![self runRpc:rpcClose])
		return false;

	printHandle = NULL;

	if (![self treeDisconnect])
		return false;

	return true;
}

@end
