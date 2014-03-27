#import "DceRpcOpenPrinterEx.h"
#import "DceRpcDefines.h"
#import "NSMutableData+SMB.h"


@implementation DceRpcOpenPrinterEx

- (void) prepareRequest
{
	[super prepareRequest];

	self.opnum = RPC_OPENPRINTEREX;

	NSMutableData *rpc = [NSMutableData data];
	
	[rpc appendUInt32LE:0x00000001]; // referent id
	[rpc appendUInt32LE:self.printerName.length+1]; // max count
	[rpc appendUInt32LE:0x00000000]; // offset
	[rpc appendUInt32LE:self.printerName.length+1]; // actual count
	[rpc appendUStringNT:self.printerName];

	[rpc padTo4From:0];
	[rpc appendUInt32LE:0x00000000]; // printer datatype

	[rpc appendUInt32LE:0x00000000]; // devicemode ctr size
	[rpc appendUInt32LE:0x00000000]; // devicemode ptr

	[rpc appendUInt32LE:0x00000008]; // access required

	// user level container
	[rpc appendUInt32LE:0x00000001]; // info level
	// user level
	[rpc appendUInt32LE:0x00000001]; // referent id
	[rpc appendUInt32LE:0x00000001]; // info level
	[rpc appendUInt32LE:0x00000028]; // size
	[rpc appendUInt32LE:0x00000001]; // referent id - client
	[rpc appendUInt32LE:0x00000001]; // referent id - user
	[rpc appendUInt32LE:0x00000000]; // build
	[rpc appendUInt32LE:0x00000000]; // major
	[rpc appendUInt32LE:0x00000000]; // minor
	[rpc appendUInt32LE:0x00000000]; // processor
	
	[rpc padTo4From:0];
	[rpc appendUInt32LE:self.client.length+1]; // max count
	[rpc appendUInt32LE:0x00000000]; // offset
	[rpc appendUInt32LE:self.client.length+1]; // actual count
	[rpc appendUStringNT:self.client];
	
	[rpc padTo4From:0];
	[rpc appendUInt32LE:self.user.length+1]; // max count
	[rpc appendUInt32LE:0x00000000]; // offset
	[rpc appendUInt32LE:self.user.length+1]; // actual count
	[rpc appendUStringNT:self.user];
	
	self.request = rpc;
}

- (bool) parseResponse
{
	if (self.response.length < 20)
	{
		self.error = @"Incorrect response length";
		return false;
	}

	self.policyHandle = [NSData dataWithBytes:self.response.bytes length:20];
	return true;
}

@end
