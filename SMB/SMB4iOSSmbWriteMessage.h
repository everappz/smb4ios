#import "SMB4iOSSmbMessage.h"


@interface SMB4iOSSmbWriteMessage : SMB4iOSSmbMessage
{
}

@property (nonatomic, assign) UInt16 fid;
@property (nonatomic, strong) NSData *data;

@end
