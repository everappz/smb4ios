#import "DceRpcData.h"
#import "NSMutableData+SMB.h"


@implementation DceRpcDataReader

@synthesize data;
@synthesize position;

- (id) initWithData:(NSData *)aData
{
	if (self = [super init])
	{
		self.data = aData;
		self.position = 0;
	}
	return self;
}

- (int) remaining
{
	return data.length - position;
}

- (UInt8) readByte
{
	UInt8 result = [data byteAt:position];
	position += 1;
	return result;
}

- (UInt16) readWord
{
	UInt16 result = [data wordLEAt:position];
	position += 2;
	return result;
}

- (UInt32) readInt
{
	UInt32 result = [data uint32LEAt:position];
	position += 4;
	return result;
}

- (NSString *) readNTString
{
	int st = position;
	while (position < data.length-1 && [self readWord] != 0)
		;
	if (position-st <= 1)
		return NULL;
	return [[NSString alloc] initWithBytes:data.bytes+st length:position-st-1
		encoding:NSUTF16LittleEndianStringEncoding];
}

- (NSString *) readString
{
	position += 4; // max count
	position += 4; // offset
	int cnt1 = [data uint32LEAt:position]; position += 4; // actual count
	
	NSString *result = [[NSString alloc] initWithBytes:data.bytes+position length:cnt1*2
		encoding:NSUTF16LittleEndianStringEncoding];
	position += cnt1*2;
	
	return result;
}

- (void) alignTo:(int)value
{
	int mod = (position % value);
	if (mod > 0)
		position += value - mod;
}

@end
