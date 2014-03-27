#import "NbtConnection.h"
#import "DceRpcPrinterInfo2.h"


@interface SmbConnection : NbtConnection

@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) DceRpcPrinterInfo2 *printerInfo;

- (void) connectToHost:(NSString *)host;
- (bool) enumDomains;
- (bool) enumServers:(NSString *)domain;
- (bool) enumShares;
- (bool) getPrinter:(NSString *)printerName;
- (bool) startPrint:(NSString *)printerName;
- (bool) endPrint;

@end
