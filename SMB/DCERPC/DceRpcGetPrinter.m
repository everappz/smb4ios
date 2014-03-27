#import "DceRpcGetPrinter.h"
#import "DceRpcDefines.h"
#import "DceRpcData.h"
#import "NSMutableData+SMB.h"


@implementation DceRpcGetPrinter

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

	DceRpcDataReader *reader = [[DceRpcDataReader alloc] initWithData:self.response];
	reader.position = 0;

	self.printerInfo = [[DceRpcPrinterInfo2 alloc] initWithReader:reader];
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
