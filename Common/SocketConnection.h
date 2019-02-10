#import <Foundation/Foundation.h>


extern NSString * const SocketConnectionErrorDomain;


typedef NS_ENUM(NSUInteger, SocketConnectionErrorCode) {
    SocketConnectionErrorCodeNone = 0,
    SocketConnectionErrorCodeUnknown = 1,
    SocketConnectionErrorCodeCanNotGetAddressInfo,
    SocketConnectionErrorCodeConnectionFailed,
};

@interface SocketConnection : NSObject

@property (nonatomic,copy) NSString *ipAddress;
@property (nonatomic,assign) NSUInteger port;

- (instancetype)init;

- (BOOL)connectWithTimeout:(NSTimeInterval)timeout
                     error:(NSError **)error;

- (void)disconnect;

- (BOOL)isConnected;

- (BOOL)hasBytesAvailable:(NSError **)errPtr;

- (BOOL)writeData:(NSData *)data
      withTimeout:(NSTimeInterval)timeout
            error:(NSError **)errPtr;

- (BOOL)readDataWithTimeout:(NSTimeInterval)timeout
                     buffer:(NSMutableData *)mutableData
                  maxLength:(NSUInteger)length
                      error:(NSError **)errPtr;

- (NSString *)ipAddress;

- (NSUInteger)port;

@end
