#import "SMB4iOSNbtConnection.h"
#import "SMB4iOSDceRpcPrinterInfo2.h"


@interface SMB4iOSSmbConnection : SMB4iOSNbtConnection

@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) SMB4iOSDceRpcPrinterInfo2 *printerInfo;

- (void) connectToHost:(NSString *)host;
- (bool) enumDomains;
- (bool) enumServers:(NSString *)domain;
- (bool) enumShares;
- (bool) getPrinter:(NSString *)printerName;
- (bool) startPrint:(NSString *)printerName;
- (bool) endPrint;

@end
