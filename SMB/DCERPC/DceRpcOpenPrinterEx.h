#import "DceRpcMessage.h"


@interface DceRpcOpenPrinterEx : DceRpcMessage
{
}

@property (nonatomic, strong) NSString *printerName;
@property (nonatomic, strong) NSString *client;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSData *policyHandle;

@end
