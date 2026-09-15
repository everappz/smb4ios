
#import <Foundation/Foundation.h>

#define RapNetServerInfo1Size 26

@interface SMB4iOSRapNetServerInfo1 : NSObject

@property (nonatomic, strong) NSString *serverName;
@property (nonatomic, strong) NSString *serverComment;
@property (nonatomic, assign) int serverType;

- (bool) parseData:(NSData *)data offset:(int)offset converter:(int)converter;

@end
