#import <Foundation/Foundation.h>
#import "SMB4iOSSmbMessage.h"


@interface SMB4iOSSmbCloseMessage : SMB4iOSSmbMessage
{
}

@property (nonatomic, assign) UInt16 fid;

@end
