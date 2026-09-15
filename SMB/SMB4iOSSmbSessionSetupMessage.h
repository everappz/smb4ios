#import <Foundation/Foundation.h>
#import "SMB4iOSSmbMessage.h"

@interface SMB4iOSSmbSessionSetupMessage : SMB4iOSSmbMessage
{
}

@property (nonatomic, assign) bool anonymous;
@property (nonatomic, assign) UInt32 sessionKey;
@property (nonatomic, strong) NSData *requestSecurityBlob;
@property (nonatomic, strong) NSData *responseSecurityBlob;

@end
