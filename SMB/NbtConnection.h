#import "SocketConnection.h"


@interface NbtConnection : SocketConnection

- (bool) writeNbtMessage:(NSData *)data;

@end
