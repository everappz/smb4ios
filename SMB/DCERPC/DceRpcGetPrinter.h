#import "DceRpcMessage.h"
#import "DceRpcPrinterInfo2.h"

#define RPC_GETPRINTER_SUCCESS             0x00
#define RPC_GETPRINTER_INSUFFICIENT_BUFFER 0x7A


@interface DceRpcGetPrinter : DceRpcMessage

@property (nonatomic, strong) NSData *policyHandle;
@property (nonatomic, assign) int bufferSize;
@property (nonatomic, assign) int statusCode;
@property (nonatomic, strong) DceRpcPrinterInfo2 *printerInfo;

@end
