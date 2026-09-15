#import "SMB4iOSSmbTreeConnectMessage.h"
#import "NSMutableData+SMB4iOS.h"
#import "SMB4iOSSmbDefines.h"

@implementation SMB4iOSSmbTreeConnectMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_TREE_CONNECT_ANDX;
	}
	return self;
}

- (NSData *) getParametersData
{
	NSMutableData *result = [NSMutableData data];
	
	[result appendByte:SMB_COM_NONE]; // AndX Command
	[result appendByte:0]; // reserved
	[result appendWordLE:0]; // AndX Offset

	[result appendWordLE:0x0008]; // Flags
	[result appendWordLE:1]; // Password Length
	
	assert(result.length == 8);
	
	return result;
}

- (NSData *) getMessageData
{
	NSMutableData *result = [NSMutableData data];

	[result appendCStringNT:@""]; // Password
	// Pad
	[result appendUStringNT:self.path]; // Path
	[result appendCStringNT:@"?????"]; // Service

	return result;
}

- (bool) parseResponse:(NSData *)data
{
	if (![super parseResponse:data])
		return false;

	self.tid = [data wordLEAt:SMB_HEADER_TID_SHORT];

	return true;
}

@end
