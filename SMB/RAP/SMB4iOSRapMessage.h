
#import <Foundation/Foundation.h>

#define RAP_HEADER_LENGTH 4


@interface SMB4iOSRapMessage : NSObject

@property (nonatomic, strong) NSString *error;
@property (nonatomic, assign) int converter;

- (NSData *) getRequest;
- (bool) parseResponseParameters:(NSData *)params data:(NSData *)data;

@end
