

#import <Foundation/Foundation.h>
#import "SMB4iOSRapMessage.h"
#import "SMB4iOSRapNetServerInfo1.h"

#define SV_TYPE_DOMAIN_ENUM 0x80000000
#define SV_TYPE_ALL         0xFFFFFFFF


@interface SMB4iOSRapNetServerEnum2 : SMB4iOSRapMessage

@property (nonatomic, strong) NSString *domain;
@property (nonatomic, assign) UInt32 serverType;
@property (nonatomic, strong) NSArray *shares;

@end
