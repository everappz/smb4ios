#import "SmbMessage.h"


@interface SmbReadMessage : SmbMessage

@property (nonatomic, assign) UInt16 fid;
@property (nonatomic, assign) bool eof;
@property (nonatomic, strong) NSData *data;

@end
