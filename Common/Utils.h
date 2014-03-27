#import <Foundation/Foundation.h>

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

#define FlexibleWidth UIViewAutoresizingFlexibleWidth
#define FlexibleHeight UIViewAutoresizingFlexibleHeight
#define FlexibleTop UIViewAutoresizingFlexibleTopMargin
#define FlexibleBottom UIViewAutoresizingFlexibleBottomMargin
#define FlexibleRight UIViewAutoresizingFlexibleRightMargin
#define FlexibleLeft UIViewAutoresizingFlexibleLeftMargin


@interface Utils : NSObject
{
}

+ (NSString *) RFC3986EncodeString:(NSString *)s;
+ (bool) isPortrait;
+ (NSString *) sockaddrToString:(const void *)sockaddr;
+ (NSData *) sockaddrFromHost:(NSString *)host port:(int)port;
+ (NSData *) sockaddrFromAddress:(NSString *)address;
+ (NSString *) hostOfAddress:(NSString *)addr;

+ (void) logData:(NSData *)data;
+ (void) logData:(NSData *)data byteLimit:(int)limit;
+ (NSString *) uniqueDeviceId;

+ (void) alert:(NSString *)msg title:(NSString *)title;
+ (void) alertError:(NSString *)msg;

@end
