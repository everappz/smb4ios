#import "DceRpcStartDocPrinter.h"
#import "DceRpcDefines.h"
#import "NSMutableData+SMB.h"


@implementation DceRpcStartDocPrinter

- (void) prepareRequest
{
	[super prepareRequest];

	self.opnum = RPC_STARTDOCPRINTER;

	NSMutableData *rpc = [NSMutableData data];
	
	assert(self.policyHandle.length == 20);
	[rpc appendData:self.policyHandle];
	
	// document info container
	[rpc appendUInt32LE:0x00000001]; // info level
	// document info
	[rpc appendUInt32LE:0x00000001]; // info level
	// document info
	[rpc appendUInt32LE:0x00000001]; // referent id
	// document info level 1
	[rpc appendUInt32LE:0x00000001]; // referent id - document name
	[rpc appendUInt32LE:0x00000000]; // output file pointer
	[rpc appendUInt32LE:0x00000001]; // referent id - data type
	
	[rpc padTo4From:0];
	[rpc appendUInt32LE:(self.documentName.length+1)]; // max count
	[rpc appendUInt32LE:0x00000000]; // offset
	[rpc appendUInt32LE:(self.documentName.length+1)]; // actual count
	[rpc appendUStringNT:self.documentName];

	[rpc padTo4From:0];
	[rpc appendUInt32LE:(self.dataType.length+1)]; // max count
	[rpc appendUInt32LE:0x00000000]; // offset
	[rpc appendUInt32LE:(self.dataType.length+1)]; // actual count
	[rpc appendUStringNT:self.dataType];

	self.request = rpc;
}

- (bool) parseResponse
{
	if (self.response.length < 8)
	{
		self.error = @"Incorrect response length";
		return false;
	}

	UInt32 code = [self.response uint32LEAt:4];
	if (code != 0)
	{
		self.error = [NSString stringWithFormat:@"DCE/RPC error 0x%x", (unsigned int)code];
		return false;
	}
		
	return true;
}

@end
