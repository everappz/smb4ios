#import "SocketConnection.h"


@interface NbtConnection : SocketConnection

- (BOOL)writeNbtMessage:(NSData *)data;

- (void)close;

- (BOOL)connectToAddress:(NSString *)addr port:(NSUInteger)port;

- (BOOL)write:(NSData *)data;

- (NSData *)read;

@end
