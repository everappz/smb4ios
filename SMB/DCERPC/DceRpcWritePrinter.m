#import "DceRpcWritePrinter.h"
#import "DceRpcDefines.h"
#import "NSMutableData+SMB.h"


@implementation DceRpcWritePrinter

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

