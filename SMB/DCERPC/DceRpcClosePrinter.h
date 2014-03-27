#import "DceRpcMessage.h"


@interface DceRpcClosePrinter : DceRpcMessage

@property (nonatomic, strong) NSData *policyHandle;

@end
