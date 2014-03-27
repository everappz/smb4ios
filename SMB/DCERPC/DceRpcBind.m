#import "DceRpcBind.h"
#import "DceRpcDefines.h"
#import "NSMutableData+SMB.h"


@implementation DceRpcBind

- (int) requestFragments
{
	return 1;
}

- (NSData *) getRequestFragment:(int)idx
{
	NSMutableData *rpc = [NSMutableData data];

	[rpc appendByte:0x05]; // version
	[rpc appendByte:0x00]; // version
	[rpc appendByte:PTYPE_BIND]; // packet type
	[rpc appendByte:PFC_FIRST_FRAG|PFC_LAST_FRAG]; // packet flags
	[rpc appendUInt32LE:0x00000010]; // data representation
	[rpc appendWordLE:0]; // file length
	[rpc appendWordLE:0x0000]; // auth length
	[rpc appendUInt32LE:self.callId]; // call id

	[rpc appendWordLE:0x1000]; // max xmit frag
	[rpc appendWordLE:0x1000]; // max recv frag
	[rpc appendUInt32LE:0x00000000]; // assoc.group
	
	// p_cont_list_t
	[rpc appendByte:0x01]; // num. context items
	[rpc appendByte:0x00]; // reserved
	[rpc appendWordLE:0x0000]; // reserved

	// p_cont_elem_t[0]
	[rpc appendWordLE:0x0000]; // context id
	[rpc appendByte:0x01]; // number of items
	[rpc appendByte:0x00]; // reserved

	// abstract_syntax
	assert(self.abstractSyntax.length == 40);
	[self appendUUID:[self.abstractSyntax substringToIndex:36] toData:rpc];
	[rpc appendWordLE:[[self.abstractSyntax substringWithRange:NSMakeRange(37, 1)] intValue]];
	[rpc appendWordLE:[[self.abstractSyntax substringWithRange:NSMakeRange(39, 1)] intValue]];

	// transfer_syntax
	[self appendUUID:@"8a885d04-1ceb-11c9-9fe8-08002b104860" toData:rpc]; // NDR 2.0
	[rpc appendWordLE:0x0002]; // version
	[rpc appendWordLE:0x0000]; // version
	
	assert(rpc.length == 72);
	[rpc setWordLE:rpc.length at:8];

	return rpc;
}

- (void) appendUUID:(NSString *)uuid toData:(NSMutableData *)data
{
	assert(uuid.length == 36);
	
	[data appendByte:[self byteAt:6  inString:uuid]];
	[data appendByte:[self byteAt:4  inString:uuid]];
	[data appendByte:[self byteAt:2  inString:uuid]];
	[data appendByte:[self byteAt:0  inString:uuid]];
	
	[data appendByte:[self byteAt:11 inString:uuid]];
	[data appendByte:[self byteAt:9  inString:uuid]];
	
	[data appendByte:[self byteAt:16 inString:uuid]];
	[data appendByte:[self byteAt:14 inString:uuid]];
	
	[data appendByte:[self byteAt:19 inString:uuid]];
	[data appendByte:[self byteAt:21 inString:uuid]];
	
	[data appendByte:[self byteAt:24 inString:uuid]];
	[data appendByte:[self byteAt:26 inString:uuid]];
	[data appendByte:[self byteAt:28 inString:uuid]];
	[data appendByte:[self byteAt:30 inString:uuid]];
	[data appendByte:[self byteAt:32 inString:uuid]];
	[data appendByte:[self byteAt:34 inString:uuid]];
}

- (UInt8) byteAt:(int)pos inString:(NSString *)s
{
	return ([self hexValue:[s characterAtIndex:pos]] << 4) + [self hexValue:[s characterAtIndex:pos+1]];
}

- (UInt8) hexValue:(unichar)c
{
	if (c >= '0' && c <= '9')
		return (c - '0');
	if (c >= 'a' && c <= 'f')
		return (c - 'a') + 10;
	if (c >= 'A' && c <= 'F')
		return (c - 'A') + 10;
	return 0;
}

@end
