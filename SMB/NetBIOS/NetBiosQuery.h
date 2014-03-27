
@interface NetBiosQuery : NSObject

@property (nonatomic, strong) NSString *nbtName;
@property (nonatomic, assign) char nbtSuffix;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) NSString *host;

- (NSData *) getRequest;
- (bool) parseResponse:(NSData *)response;

@end
