#import "SMB4iOSDceRpcMessage.h"


@interface SMB4iOSDceRpcWritePrinter : SMB4iOSDceRpcMessage

@property (nonatomic, strong) NSData *policyHandle;
@property (nonatomic, strong) NSData *data;

@end
