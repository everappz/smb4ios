#import <Foundation/Foundation.h>
#import "DceRpcMessage.h"


@interface DceRpcEnumAll : DceRpcMessage
{
}

@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSArray *shares;

@end
