#import "SMB4iOSDceRpcClosePrinter.h"
#import "SMB4iOSDceRpcDefines.h"
#import "NSMutableData+SMB4iOS.h"


@implementation SMB4iOSDceRpcClosePrinter

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


