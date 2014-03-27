#import "SmbLogoffMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"


@implementation SmbLogoffMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_LOGOFF_ANDX;
	}
	return self;
}

- (NSData *) getParametersData
{
	NSMutableData *result = [NSMutableData data];
	
	[result appendByte:SMB_COM_NONE]; // AndX Command
	[result appendByte:0]; // reserved
	[result appendWordLE:0]; // AndX Offset
	
	assert(result.length == 4);
	
	return result;
}

@end
