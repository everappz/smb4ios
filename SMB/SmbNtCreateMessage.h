#import <Foundation/Foundation.h>
#import "SmbMessage.h"

@interface SmbNtCreateMessage : SmbMessage
{
}

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, assign) UInt16 fid;

@end
