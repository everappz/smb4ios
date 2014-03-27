#import "DceRpcEnumAll.h"
#import "DceRpcDefines.h"
#import "NSMutableData+SMB.h"
#import "Utils.h"


@implementation DceRpcEnumAll

- (void) prepareRequest
{
	[super prepareRequest];

	self.opnum = RPC_ENUMALL;

	NSMutableData *rpc = [NSMutableData data];

	[rpc appendUInt32LE:0x00000001]; // referent id
	
	[rpc appendUInt32LE:self.host.length+1]; // max count
	[rpc appendUInt32LE:0x00000000]; // offset
	[rpc appendUInt32LE:self.host.length+1]; // actual count
	[rpc appendUStringNT:self.host];
	
	[rpc appendUInt32LE:0x00000001]; // level
	[rpc appendUInt32LE:0x00000001]; // ctr
	[rpc appendUInt32LE:0x00000001]; // referent id
	[rpc appendUInt32LE:0x00000000]; // ctrl count
	[rpc appendUInt32LE:0x00000000]; // pointer
	[rpc appendUInt32LE:0xffffffff]; // max buffer
	[rpc appendUInt32LE:0x00000001]; // referent id
	[rpc appendUInt32LE:0x00000000]; // resume handle

	self.request = rpc;
}

- (bool) parseResponse
{
	int n = 0;

	NSMutableArray *result = [NSMutableArray array];

	n += 4; // level 1
	
	// srvsvc_NetShareCtr (no idea)
	n += 4; // ctr
	
	// srvsvc_NetShareCtr1
	n += 4; // referent id
	int count = [self.response uint32LEAt:n]; n += 4; // array count

	// array[srvsvc_NetShareInfo1]
	n += 4; // referent id
	n += 4; // max count
	
	for (int i = 0; i < count; i++)
	{
		n += 4; // name referent id
		int type = [self.response uint32LEAt:n]; n += 4; // share type
		n += 4; // comment referent id
		
		NSMutableDictionary *rec = [NSMutableDictionary dictionary];
		[rec setObject:[NSNumber numberWithInt:type] forKey:@"type"];
		[result addObject:rec];
	}

	int offset = n;

	for (int i = 0; i < count; i++)
	{
		n += 4; // max count
		n += 4; // offset
		int cnt1 = [self.response uint32LEAt:n]; n += 4; // actual count
		
		NSString *name = [[NSString alloc] initWithBytes:self.response.bytes+n length:cnt1*2
			encoding:NSUTF16LittleEndianStringEncoding];
		n += cnt1*2;
		
		while ((n - offset) % 4 != 0) // align to 4
			n++;

		n += 4; // max count
		n += 4; // offset
		int cnt2 = [self.response uint32LEAt:n]; n += 4; // actual count
		
		NSString *comment = [[NSString alloc] initWithBytes:self.response.bytes+n length:cnt2*2
			encoding:NSUTF16LittleEndianStringEncoding];
		n += cnt2*2;

		while ((n - offset) % 4 != 0) // align to 4
			n++;

		NSMutableDictionary *rec = [result objectAtIndex:i];
		[rec setObject:name forKey:@"name"];
		[rec setObject:comment forKey:@"comment"];
	}
	
	n += 4; // total entries
	n += 4; // resume handle - referent id
	n += 4; // resume handle
	n += 4; // windows error
	
	if (n != self.response.length)
	{
		self.error = @"Incorrect data length";
		return false;
	}
	
	self.shares = result;
	return true;
}

@end
