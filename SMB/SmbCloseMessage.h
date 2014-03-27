#import <Foundation/Foundation.h>
#import "SmbMessage.h"


@interface SmbCloseMessage : SmbMessage
{
}

@property (nonatomic, assign) UInt16 fid;

@end
