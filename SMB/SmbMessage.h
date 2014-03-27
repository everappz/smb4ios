#import <Foundation/Foundation.h>


@interface SmbMessage : NSObject
{
}

@property (nonatomic, assign) UInt8 command;
@property (nonatomic, assign) UInt16 tid;
@property (nonatomic, assign) UInt16 pid;
@property (nonatomic, assign) UInt16 uid;
@property (nonatomic, assign) UInt16 mid;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, assign) int responseParametersOffset;
@property (nonatomic, strong) NSData *responseParameters;
@property (nonatomic, assign) int responseMessageOffset;
@property (nonatomic, strong) NSData *responseMessageData;

- (NSData *) getRequest;
- (bool) parseResponse:(NSData *)data;

@end














