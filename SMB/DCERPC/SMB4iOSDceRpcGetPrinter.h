#import "SMB4iOSDceRpcMessage.h"
#import "SMB4iOSDceRpcPrinterInfo2.h"

#define RPC_GETPRINTER_SUCCESS             0x00
#define RPC_GETPRINTER_INSUFFICIENT_BUFFER 0x7A


@interface SMB4iOSDceRpcGetPrinter : SMB4iOSDceRpcMessage

@property (nonatomic, strong) NSData *policyHandle;
@property (nonatomic, assign) int bufferSize;
@property (nonatomic, assign) int statusCode;
@property (nonatomic, strong) SMB4iOSDceRpcPrinterInfo2 *printerInfo;

@end
