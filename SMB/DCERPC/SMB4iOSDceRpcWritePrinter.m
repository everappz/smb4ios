#import "SMB4iOSDceRpcWritePrinter.h"
#import "SMB4iOSDceRpcDefines.h"
#import "NSMutableData+SMB4iOS.h"


@implementation SMB4iOSDceRpcWritePrinter

- (void) prepareRequest
{
	[super prepareRequest];

	self.opnum = RPC_WRITEPRINTER;

	NSMutableData *rpc = [NSMutableData data];
	
  // HANDLE hPrinter
	assert(self.policyHandle.length == 20);
	[rpc appendData:self.policyHandle];
  
	// LPVOID pBuf
	[rpc appendUInt32LE:self.data.length];
	[rpc appendData:self.data];

  // DWORD cbBuf
	[rpc padTo4From:0];
	[rpc appendUInt32LE:self.data.length];

	self.request = rpc;
}

@end

