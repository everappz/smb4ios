#import <Foundation/Foundation.h>


@interface SocketConnection : NSObject 
{
	CFSocketRef socket;
	NSMutableData *buffer;
	__block CFRunLoopRef threadRunLoop;
	NSCondition *condition;
}

@property (nonatomic, retain) NSMutableData *receivedData;

- (void) connectToAddress:(NSString *)address;
- (NSData *) read;
- (bool) write:(NSData *)message;
- (void) writeBuffered:(NSData *)message;
- (bool) flush;
- (void) close;

@end
