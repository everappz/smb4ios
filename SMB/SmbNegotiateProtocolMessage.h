#import <Foundation/Foundation.h>
#import "SmbMessage.h"

@interface SmbNegotiateProtocolMessage : SmbMessage
{
}

@property (nonatomic, assign) UInt32 sessionKey;

@end

