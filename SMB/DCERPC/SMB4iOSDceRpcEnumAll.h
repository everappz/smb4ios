#import <Foundation/Foundation.h>
#import "SMB4iOSDceRpcMessage.h"


@interface SMB4iOSDceRpcEnumAll : SMB4iOSDceRpcMessage
{
}

@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSArray *shares;

@end
