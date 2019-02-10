#import "SmbMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"
#import "Utils.h"

#define SMB_FLAGS_CANONICAL_PATHNAMES 0x10   // Obsolete, set for compatibility
#define SMB_FLAGS_CASELESS_PATHNAMES  0x08   // Pathes are treated as caseless (like on windows system)
#define SMB_FLAGS_SERVER_TO_REDIR     0x80   // 0: request, 1: reply from server

#define SMB_FLAGS2_UNICODE_STRINGS    0x8000 // Strings encoded as unicode
#define SMB_FLAGS2_32BIT_STATUS       0x4000 // Use NT_STATUS response codes in STATUS field
#define SMB_FLAGS2_READ_IF_EXECUTE    0x2000 // Execute permission also grants read
#define SMB_FLAGS2_DFS_PATHNAME       0x1000 // Client knows about distributed file systems
#define SMB_FLAGS2_EXTENDED_SECURITY  0x0800 // Extened security features
#define SMB_FLAGS2_IS_LONG_NAME       0x0040 // Long filenames are supported (not only 8.3 names)
#define SMB_FLAGS2_SECURITY_SIGNATURE 0x0004 // MAC included in signature
#define	SMB_FLAGS2_EAS                0x0002 // Client understands Extened Attributes
#define SMB_FLAGS2_KNOWS_LONG_NAMES   0x0001 // Client accepts long filenames in response

const Byte SMB_PROTOCOL_ID[4] = {(Byte) 0xFF, 'S', 'M', 'B'};

@implementation SmbMessage

- (void) populateHeader:(NSMutableData *)buffer
{
	// Protocol
    [buffer replaceBytesInRange:NSMakeRange(0, 4) withBytes:SMB_PROTOCOL_ID];
	
	// Command
    unsigned char command = self.command;
    [buffer replaceBytesInRange:NSMakeRange(SMB_HEADER_COMMAND_BYTE, sizeof(command)) withBytes:&command];
	
	// Status
    unsigned int status = 0x00;
    [buffer replaceBytesInRange:NSMakeRange(SMB_HEADER_STATUS_INT, sizeof(status)) withBytes:&status];
	
	// Flags
    unsigned char flags = 0x00;
    flags |= SMB_FLAGS_CASELESS_PATHNAMES;
    [buffer replaceBytesInRange:NSMakeRange(SMB_HEADER_FLAGS_BYTE, sizeof(flags)) withBytes:&flags];
    
	// Flags2
    unsigned short flags2 = 0x0000;
    flags2 |= SMB_FLAGS2_UNICODE_STRINGS;
    flags2 |= SMB_FLAGS2_32BIT_STATUS;
    flags2 |= SMB_FLAGS2_IS_LONG_NAME;
    flags2 |= SMB_FLAGS2_KNOWS_LONG_NAMES;
    flags2 |= SMB_FLAGS2_EXTENDED_SECURITY;
    [buffer replaceBytesInRange:NSMakeRange(SMB_HEADER_FLAGS2_SHORT, sizeof(flags2)) withBytes:&flags2];
    
	// Extra
	
	// TID
	unsigned short tid = self.tid;
    [buffer replaceBytesInRange:NSMakeRange(SMB_HEADER_TID_SHORT, sizeof(tid)) withBytes:&tid];
    
	// PID
	unsigned short pid = self.pid;
    [buffer replaceBytesInRange:NSMakeRange(SMB_HEADER_PID_SHORT, sizeof(pid)) withBytes:&pid];
    
	// UID
	unsigned short uid = self.uid;
    [buffer replaceBytesInRange:NSMakeRange(SMB_HEADER_UID_SHORT, sizeof(uid)) withBytes:&uid];
    
	// MID
    unsigned short mid = self.mid;
    [buffer replaceBytesInRange:NSMakeRange(SMB_HEADER_MID_SHORT, sizeof(mid)) withBytes:&mid];
    
}

- (NSData *) getParametersData
{
	return NULL;
}

- (NSData *) getMessageData
{
	return NULL;
}

- (NSData *) getRequest
{
	NSMutableData *result = [NSMutableData dataWithLength:SMB_HEADER_LENGTH];
	[self populateHeader:result];
	
	NSData *params = [self getParametersData];

	assert(params.length % 2 == 0);
	
	[result appendByte:(params.length / 2)];
	[result appendData:params];
	
	NSData *message = [self getMessageData];
	[result appendWordLE:message.length];
	[result appendData:message];

	return result;
}

- (bool) parseResponse:(NSData *)data
{
	self.error = NULL;

	// Length of all parts
	if (data.length < SMB_HEADER_LENGTH + 1)
	{
		self.error = @"Invalid length";
		return false;
	}

    int paramLength = [data byteAt:SMB_HEADER_LENGTH]*2;
	if (data.length < SMB_HEADER_LENGTH + 1 + paramLength + 2)
	{
		self.error = @"Invalid length";
		return false;
	}
	
    int dataLength = [data wordLEAt:SMB_HEADER_LENGTH + 1 + paramLength];
	if (data.length < SMB_HEADER_LENGTH + 1 + paramLength + 2 + dataLength)
	{
		self.error = @"Invalid length";
		return false;
	}

	// Header
    if ([data byteAt:0] != 0xff ||
        [data byteAt:1] != 'S' ||
        [data byteAt:2] != 'M' ||
        [data byteAt:3] != 'B')
	{
		self.error = @"Invalid header";
		return false;
	}
	
	unsigned int ntStatus = [data uint32LEAt:SMB_HEADER_STATUS_INT];

	//if (ntStatus != 0) NSLog(@"NT_STATUS %08X", ntStatus);

	if (ntStatus == 0x00010002)
	{
		self.error = @"Client Error"; // undocumented
		return false;
	}
	
	unsigned short ntStatusLevel = ((ntStatus >> 30) & 0x03);
	if (ntStatusLevel != NT_STATUS_SUCCESS && ![self expectNtStatus:ntStatus])
	{
		if (ntStatus == NT_STATUS_BAD_NETWORK_NAME)
			self.error = @"Bad Network Name";
		else if (ntStatus == NT_STATUS_ACCESS_DENIED)
			self.error = @"Access Denied";
		else if (ntStatus == NT_STATUS_LOGON_FAILURE)
			self.error = @"Logon Failure";
		else if (ntStatus == NT_STATUS_LOGON_TYPE_NOT_GRANTED)
			self.error = @"Logon Type Not Granted";
		else if (ntStatus == NT_STATUS_INVALID_PARAMETER)
			self.error = @"Invalid Parameter";
		else
			self.error = [NSString stringWithFormat:@"NT_STATUS %08X", ntStatus];
		return false;
	}
	
	unsigned char receivedCommand = [data byteAt:SMB_HEADER_COMMAND_BYTE];
	if (receivedCommand != self.command)
	{
		self.error = @"Mismatching command";
		return false;
	}

	self.responseParametersOffset = SMB_HEADER_LENGTH + 1;
    self.responseParameters = [data subdataWithRange:NSMakeRange(self.responseParametersOffset, paramLength)];

	self.responseMessageOffset = SMB_HEADER_LENGTH + 1 + paramLength + 2;
    self.responseMessageData = [data subdataWithRange:NSMakeRange(self.responseMessageOffset, dataLength)];
    
	return true;
}

- (bool) expectNtStatus:(unsigned int)status
{
	return false;
}

@end
