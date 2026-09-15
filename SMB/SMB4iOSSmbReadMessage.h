#import "SMB4iOSSmbMessage.h"


@interface SMB4iOSSmbReadMessage : SMB4iOSSmbMessage

@property (nonatomic, assign) UInt16 fid;
@property (nonatomic, assign) bool eof;
@property (nonatomic, strong) NSData *data;

@end
