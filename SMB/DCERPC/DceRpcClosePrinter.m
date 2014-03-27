#import "DceRpcClosePrinter.h"
#import "DceRpcDefines.h"
#import "NSMutableData+SMB.h"


@implementation DceRpcClosePrinter

- (void) prepareRequest
{
	[super prepareRequest];

	self.opnum = RPC_CLOSEPRINTER;

	NSMutableData *rpc = [NSMutableData data];
	
	assert(self.policyHandle.length == 20);
	[rpc appendData:self.policyHandle];

	self.request = rpc;
}

@end


