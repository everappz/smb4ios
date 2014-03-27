#import "SmbTreeDisconnectMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"

@implementation SmbTreeDisconnectMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_TREE_DISCONNECT;
	}
	return self;
}

@end
