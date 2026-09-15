#import "SMB4iOSSmbCloseMessage.h"
#import "NSMutableData+SMB4iOS.h"
#import "SMB4iOSSmbDefines.h"


@implementation SMB4iOSSmbCloseMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_CLOSE;
	}
	return self;
}

- (NSData *) getParametersData
{
	NSMutableData *result = [NSMutableData data];
	
	[result appendWordLE:self.fid]; // FID
	[result appendUInt32LE:0xffffffff]; // Time Not Modified
	
	assert(result.length == 6);
	
	return result;
}

@end
