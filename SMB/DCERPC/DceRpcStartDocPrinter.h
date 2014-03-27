#import "DceRpcMessage.h"


@interface DceRpcStartDocPrinter : DceRpcMessage

@property (nonatomic, strong) NSString *documentName;
@property (nonatomic, strong) NSString *dataType;
@property (nonatomic, strong) NSData *policyHandle;

@end
