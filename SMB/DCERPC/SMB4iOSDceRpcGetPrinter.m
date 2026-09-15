#import "SMB4iOSDceRpcGetPrinter.h"
#import "SMB4iOSDceRpcDefines.h"
#import "SMB4iOSDceRpcData.h"
#import "NSMutableData+SMB4iOS.h"


@implementation SMB4iOSDceRpcGetPrinter

- (void) prepareRequest
{
	[super prepareRequest];

	self.opnum = RPC_GETPRINTER;

	NSMutableData *rpc = [NSMutableData data];

  // HANDLE hPrinter
	assert(self.policyHandle.length == 20);
	[rpc appendData:self.policyHandle];

  // DWORD Level
	[rpc appendUInt32LE:2];

  // LPBYTE pPrinter
	if (self.bufferSize == 0)
		[self appendTo:rpc data:NULL];
	else
		[self appendTo:rpc data:[NSMutableData dataWithLength:self.bufferSize]];

  // DWORD cbBuf
	[rpc padTo4From:0];
	[rpc appendUInt32LE:self.bufferSize];

	self.request = rpc;
}

- (bool) parseResponse
{
	if (self.response.length < 8)
	{
		self.error = @"Incorrect response length";
		return false;
	}

	SMB4iOSDceRpcDataReader *reader = [[SMB4iOSDceRpcDataReader alloc] initWithData:self.response];
	reader.position = 0;

	self.printerInfo = [[SMB4iOSDceRpcPrinterInfo2 alloc] initWithReader:reader];
	self.bufferSize = [reader readInt];
	self.statusCode = [reader readInt];
	
	if (self.statusCode == RPC_GETPRINTER_INSUFFICIENT_BUFFER)
		return true;
	
	if (self.statusCode != RPC_GETPRINTER_SUCCESS)
	{
		self.error = [NSString stringWithFormat:@"DCE/RPC error 0x%x", (unsigned int)self.statusCode];
		return false;
	}
	
	if (self.printerInfo == NULL)
	{
		self.error = @"Failed to read PrinterInfo2";
		return false;
	}

	return true;
}

@end
