#import "RapMessage.h"
#import "RapNetServerInfo1.h"

#define SV_TYPE_DOMAIN_ENUM 0x80000000
#define SV_TYPE_ALL         0xFFFFFFFF


@interface RapNetServerEnum2 : RapMessage

@property (nonatomic, strong) NSString *domain;
@property (nonatomic, assign) UInt32 serverType;
@property (nonatomic, strong) NSArray *shares;

@end
