#import <Foundation/Foundation.h>
#import "SMB4iOSSmbMessage.h"

@interface SMB4iOSSmbTreeConnectMessage : SMB4iOSSmbMessage
{
}

@property (nonatomic, strong) NSString *path;

@end
