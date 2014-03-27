#import "DceRpcMessage.h"


@interface DceRpcWritePrinter : DceRpcMessage

@property (nonatomic, strong) NSData *policyHandle;
@property (nonatomic, strong) NSData *data;

@end
