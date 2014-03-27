#import "RapNetServerInfo1.h"
#import "NSMutableData+SMB.h"


@implementation RapNetServerInfo1

- (bool) parseData:(NSData *)data offset:(int)n converter:(int)converter
{
	if (n + 32 > data.length)
		return false;
		
	int m = n;
	while (m < n + 16 && ((UInt8 *)data.bytes)[m] != 0)
		m++;
	self.serverName = [[NSString alloc] initWithBytes:data.bytes + n length:m - n
		encoding:NSASCIIStringEncoding]; n += 16;

	n++; // MajorVerson
	n++; // MinorVersion
	self.serverType = [data uint32LEAt:n]; n += 4; // ServerType
	int commentOffset = [data wordLEAt:n] - converter;

	n = commentOffset;
	while (n < data.length && ((UInt8 *)data.bytes)[n] != 0)
		n++;
	if (n >= data.length)
		return false;
	self.serverComment = [[NSString alloc] initWithBytes:data.bytes + commentOffset length:n - commentOffset
		encoding:NSASCIIStringEncoding];

	return true;
}

@end
