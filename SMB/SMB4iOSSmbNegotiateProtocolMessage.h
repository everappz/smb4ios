#import <Foundation/Foundation.h>
#import "SMB4iOSSmbMessage.h"

@interface SMB4iOSSmbNegotiateProtocolMessage : SMB4iOSSmbMessage
{
}

@property (nonatomic, assign) UInt32 sessionKey;

@end

