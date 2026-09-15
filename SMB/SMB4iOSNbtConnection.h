#import "SMB4iOSSocketConnection.h"


@interface SMB4iOSNbtConnection : SMB4iOSSocketConnection

- (BOOL)writeNbtMessage:(NSData *)data;

- (void)close;

- (BOOL)connectToAddress:(NSString *)addr port:(NSUInteger)port;

- (BOOL)write:(NSData *)data;

- (NSData *)read;

@end
