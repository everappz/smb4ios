#import <Foundation/Foundation.h>

@interface Utils : NSObject
{
}

+ (NSString *) RFC3986EncodeString:(NSString *)s;
+ (NSString *) sockaddrToString:(const void *)sockaddr;
+ (NSData *) sockaddrFromHost:(NSString *)host port:(int)port;
+ (NSData *) sockaddrFromAddress:(NSString *)address;
+ (NSString *) hostOfAddress:(NSString *)addr;

+ (void) logData:(NSData *)data;
+ (void) logData:(NSData *)data byteLimit:(int)limit;

@end
