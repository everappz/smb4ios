#import <Foundation/Foundation.h>
#import "SmbMessage.h"

@interface SmbTreeConnectMessage : SmbMessage
{
}

@property (nonatomic, strong) NSString *path;

@end
