#import "SmbCloseMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"


@implementation SmbCloseMessage

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
