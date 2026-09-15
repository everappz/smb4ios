#import "SMB4iOSDceRpcMessage.h"


@interface SMB4iOSDceRpcOpenPrinterEx : SMB4iOSDceRpcMessage
{
}

@property (nonatomic, strong) NSString *printerName;
@property (nonatomic, strong) NSString *client;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSData *policyHandle;

@end
