#import "NetBios.h"
#import "Utils.h"
#import "AsyncUdpSocket.h"
#import "NetBiosQuery.h"

//#define LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#define LOG(format, ...)

//#define LOGDATA(data) [Utils logData:data]
#define LOGDATA(data)

#define LISTEN_PORT 55355
#define WRITE_TIMEOUT 2.0
#define READ_TIMEOUT  2.0

static NetBios *netBios = NULL;


@interface NetBios () <AsyncUdpSocketDelegate>

@end

@implementation NetBios
{
	AsyncUdpSocket *udpSocket;
	void(^completion)(NSString *host);
	NSString *resolvedHost;
}

+ (NetBios *) instance
{
	if (netBios == NULL)
		netBios = [[NetBios alloc] init];
	return netBios;
}

- (void) resolveMasterBrowser:(void(^)(NSString *host))aCompletion
{
	[self resolveName:@"\1\2__MSBROWSE__\2" suffix:'\1' onHost:@"255.255.255.255" completion:aCompletion];
}

- (void) resolveAllOnHost:(NSString *)host completion:(void(^)(NSString *host))aCompletion
{
	// @"*\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
	[self resolveName:@"<all>" suffix:'\0' onHost:host completion:aCompletion];
}

- (void) resolveServer:(NSString *)nbtName completion:(void(^)(NSString *host))aCompletion
{
	[self resolveName:nbtName suffix:0x20 onHost:@"255.255.255.255" completion:aCompletion];
}

- (void) resolveName:(NSString *)name suffix:(char)suffix onHost:(NSString *)host
	completion:(void(^)(NSString *host))aCompletion
{
	if (udpSocket != NULL)
	{
		NSLog(@"already running");
		return;
	}

	completion = aCompletion;

	NetBiosQuery *query = [[NetBiosQuery alloc] init];
	query.nbtName = name;
	query.nbtSuffix = suffix;
	NSData *request = [query getRequest];
	LOGDATA(request);
	
	resolvedHost = NULL;
	
	udpSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];

	if ( ![udpSocket bindToPort:LISTEN_PORT error:NULL]
		|| ![udpSocket enableBroadcast:true error:NULL]
		|| ![udpSocket sendData:request toHost:host port:137 withTimeout:WRITE_TIMEOUT tag:0])
	{
		NSLog(@"error initializing AsyncUdpSocket");
		completion(NULL);
		completion = NULL;
		[udpSocket close];
		udpSocket = NULL;
		return;
	}

	[udpSocket receiveWithTimeout:READ_TIMEOUT tag:0];
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
	LOG(@"didSendDataWithTag");
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	LOG(@"didNotSendDataWithTag");
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock
     didReceiveData:(NSData *)data
            withTag:(long)tag
           fromHost:(NSString *)host
               port:(UInt16)port
{
	LOG(@"didReceiveData %i from %@:%i", data.length, host, port);
	LOGDATA(data);
	
	NetBiosQuery *query = [[NetBiosQuery alloc] init];
	if (![query parseResponse:data])
		return false;
	
	resolvedHost = query.host;
	[udpSocket close];
	return true;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error
{
	LOG(@"didNotReceiveDataWithTag");

	[udpSocket close];
}

- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock
{
	LOG(@"onUdpSocketDidClose");

	udpSocket = NULL;

	if (completion != NULL)
		completion(resolvedHost);

	completion = NULL;
}

@end
