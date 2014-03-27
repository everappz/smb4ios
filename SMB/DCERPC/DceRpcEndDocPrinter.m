#import "DceRpcEndDocPrinter.h"
#import "DceRpcDefines.h"
#import "NSMutableData+SMB.h"


@implementation DceRpcEndDocPrinter

- (void) prepareRequest
{
	[super prepareRequest];

	self.opnum = RPC_ENDDOCPRINTER;

	NSMutableData *rpc = [NSMutableData data];
	
	assert(self.policyHandle.length == 20);
	[rpc appendData:self.policyHandle];

	self.request = rpc;
}

@end


