
#import <Foundation/Foundation.h>

@interface NetBiosQuery : NSObject

@property (nonatomic, strong) NSString *nbtName;
@property (nonatomic, assign) char nbtSuffix;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) UInt16 transactionID;

- (NSData *) getRequest;
- (bool) parseResponse:(NSData *)response;

@end
