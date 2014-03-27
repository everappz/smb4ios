#import <Foundation/Foundation.h>
#import "DceRpcMessage.h"


@interface DceRpcBind : DceRpcMessage
{
}

@property (nonatomic, strong) NSString *abstractSyntax;

@end
