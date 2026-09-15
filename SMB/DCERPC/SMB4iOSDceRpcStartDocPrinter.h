#import "SMB4iOSDceRpcMessage.h"


@interface SMB4iOSDceRpcStartDocPrinter : SMB4iOSDceRpcMessage

@property (nonatomic, strong) NSString *documentName;
@property (nonatomic, strong) NSString *dataType;
@property (nonatomic, strong) NSData *policyHandle;

@end
