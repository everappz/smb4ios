#import "SMB4iOSSmbTreeDisconnectMessage.h"
#import "NSMutableData+SMB4iOS.h"
#import "SMB4iOSSmbDefines.h"

@implementation SMB4iOSSmbTreeDisconnectMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_TREE_DISCONNECT;
	}
	return self;
}

@end
