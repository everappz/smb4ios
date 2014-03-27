#import <Foundation/Foundation.h>
#import "SmbMessage.h"

@interface SmbSessionSetupMessage : SmbMessage
{
}

@property (nonatomic, assign) bool anonymous;
@property (nonatomic, assign) UInt32 sessionKey;
@property (nonatomic, strong) NSData *requestSecurityBlob;
@property (nonatomic, strong) NSData *responseSecurityBlob;

@end
