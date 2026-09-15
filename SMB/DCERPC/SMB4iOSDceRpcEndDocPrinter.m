#import "SMB4iOSDceRpcEndDocPrinter.h"
#import "SMB4iOSDceRpcDefines.h"
#import "NSMutableData+SMB4iOS.h"


@implementation SMB4iOSDceRpcEndDocPrinter

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


