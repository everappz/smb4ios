#import "SmbMessage.h"


@interface SmbWriteMessage : SmbMessage
{
}

@property (nonatomic, assign) UInt16 fid;
@property (nonatomic, strong) NSData *data;

@end
