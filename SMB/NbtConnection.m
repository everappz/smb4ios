#import "NbtConnection.h"
#import "NSMutableData+SMB.h"


@implementation NbtConnection

- (bool) writeNbtMessage:(NSData *)data;
{
	NSMutableData *nbtData = [NSMutableData data];
	[nbtData appendUInt32BE:data.length];
	[nbtData appendData:data];

	return [self write:nbtData];
}

- (NSData *) read
{
	NSData *nbtData = [super read];
	if (nbtData.length < 4)
		return NULL;

	return [NSData dataWithBytes:(((UInt8 *)nbtData.bytes) + 4) length:(nbtData.length - 4)];
}

- (bool) shouldContinueReading
{
	if (self.receivedData == NULL || self.receivedData.length < 4)
		return true;
		
	UInt32 messageLength = ntohl(*((UInt32 *)self.receivedData.bytes));
	return (self.receivedData.length < messageLength + 4);
}

@end
