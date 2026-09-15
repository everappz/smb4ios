#import <Foundation/Foundation.h>
#import "SMB4iOSSmbMessage.h"

@interface SMB4iOSSmbNtCreateMessage : SMB4iOSSmbMessage
{
}

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, assign) UInt16 fid;

@end
