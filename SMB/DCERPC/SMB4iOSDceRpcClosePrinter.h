#import "SMB4iOSDceRpcMessage.h"


@interface SMB4iOSDceRpcClosePrinter : SMB4iOSDceRpcMessage

@property (nonatomic, strong) NSData *policyHandle;

@end
