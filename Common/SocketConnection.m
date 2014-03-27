#import "SocketConnection.h"
#import "Utils.h"
#include <netinet/in.h>

// -fno-objc-arc

//#define LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#define LOG(format, ...)

#define BUFFER_SIZE 1024
#define CONNECT_TIMEOUT  10.0
#define SENDDATA_TIMEOUT 5.0
#define READ_TIMEOUT     5.0


@implementation SocketConnection

@synthesize receivedData;

static SocketConnection *instance = NULL;

- (id) init
{
	if (self = [super init])
	{
		instance = self;
		buffer = [[NSMutableData alloc] initWithCapacity:BUFFER_SIZE];
	}
	return self;
}

- (void) dealloc
{
	[self close];
	instance = NULL;
	[receivedData release];
	[buffer release];
	[super dealloc];
}

- (void) connectToAddress:(NSString *)address
{
	if (socket != NULL)
		[self close];

	NSData *sockaddr = [Utils sockaddrFromAddress:address];
	
	socket = CFSocketCreate(NULL, PF_INET, SOCK_STREAM, IPPROTO_TCP, 
		kCFSocketDataCallBack, SocketCallBack, NULL);
	if (CFSocketConnectToAddress(socket, (CFDataRef)sockaddr, CONNECT_TIMEOUT) != kCFSocketSuccess)
		NSLog(@"connection error");
}

void SocketCallBack(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address,
   const void *data, void *info)
{
	[instance receiveData:data];
}

- (void) close
{
	if (socket != NULL)
	{
		LOG(@"close socket");
		[self cancelRead];
		CFSocketInvalidate(socket);
		CFRelease(socket);
		socket = NULL;
	}
}

- (bool) write:(NSData *)message
{
	if (socket == NULL)
	{
		NSLog(@"SocketConnection.write: where's my socket bro?");
		return false;
	}

	// This may generate SIGPIPE, which is disabled by signal() in main.m, so does not cause crash,
	// but still shows in debugger and will return "false" as a result
	LOG(@"write %i bytes", message.length);
	return (CFSocketSendData(socket, NULL, (CFDataRef)message, SENDDATA_TIMEOUT) == kCFSocketSuccess);
}

- (void) writeBuffered:(NSData *)message
{
	LOG(@"buffer %i bytes", message.length);
	if (buffer.length + message.length > BUFFER_SIZE)
		[self flush];
	[buffer appendData:message];
}

- (bool) flush
{
	if (buffer.length == 0)
		return false;
	LOG(@"flush...");
	bool result = [self write:buffer];
	[buffer setLength:0];
	return result;
}

- (NSData *) read
{
	LOG(@"reading...");

	NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:READ_TIMEOUT];

	self.receivedData = NULL;
	threadRunLoop = CFRunLoopGetCurrent();

	CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(NULL, socket, 0);
	CFRunLoopAddSource(threadRunLoop, source, kCFRunLoopDefaultMode);

	while ([self shouldContinueReading])
	{
		NSTimeInterval interval = [timeoutDate timeIntervalSinceNow];
		if (interval <= 0)
		{
			LOG(@"read timeout");
			break;
		}
	
		// Manually running run loop, call from background thread
		if (CFRunLoopRunInMode(kCFRunLoopDefaultMode, interval, YES) != kCFRunLoopRunHandledSource)
		{
			LOG(@"run loop exit");
			break;
		}
	}
	
	CFRunLoopRemoveSource(threadRunLoop, source, kCFRunLoopDefaultMode);
	CFRelease(source);

	threadRunLoop = NULL;

	LOG(@"reading end");
	return self.receivedData;
}

- (bool) shouldContinueReading
{
	return (self.receivedData == NULL);
}

- (void) receiveData:(NSData *)data
{
	LOG(@"received %d bytes", data.length);
	if (self.receivedData == NULL)
		self.receivedData = [[[NSMutableData alloc] initWithData:data] autorelease];
	else
		[self.receivedData appendData:data];
}

- (void) cancelRead
{
	if (threadRunLoop != NULL)
	{
		NSLog(@"stopping runloop");
		CFRunLoopStop(threadRunLoop);
	}
}

@end
