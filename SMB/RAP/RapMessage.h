
#define RAP_HEADER_LENGTH 4


@interface RapMessage : NSObject

@property (nonatomic, strong) NSString *error;
@property (nonatomic, assign) int converter;

- (NSData *) getRequest;
- (bool) parseResponseParameters:(NSData *)params data:(NSData *)data;

@end
