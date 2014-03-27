#import "DceRpcData.h"


@interface DceRpcPrinterInfo2 : NSObject

@property (nonatomic, strong) NSString *serverName;
@property (nonatomic, strong) NSString *printerName;
@property (nonatomic, strong) NSString *shareName;
@property (nonatomic, strong) NSString *portName;
@property (nonatomic, strong) NSString *driverName;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSString *location;

- (id) initWithReader:(DceRpcDataReader *)reader;

@end
