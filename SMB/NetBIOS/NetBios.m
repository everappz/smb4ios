#import "NetBios.h"
#import "Utils.h"
#import "SMB4iOSAsyncUdpSocket.h"
#import "NetBiosQuery.h"


#ifdef DEBUG
#define LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#define LOGDATA(data) [Utils logData:data]
#else
#define LOG(format, ...)
#define LOGDATA(data)
#endif

#define LISTEN_PORT 0
#define WRITE_TIMEOUT 5.0
#define READ_TIMEOUT  5.0

@interface NetBiosOperation : NSObject

@property (nonatomic, copy) NetBiosCompletionBlock completion;

@property (nonatomic, copy) NSString *serverName;

@property (nonatomic, assign) NSUInteger tag;

@end


@interface NetBios () <SMB4iOSAsyncUdpSocketDelegate>

@property (nonatomic, strong) SMB4iOSAsyncUdpSocket *udpSocket;

@property (nonatomic, strong) NSRecursiveLock *stateLock;

@end



@implementation NetBios{
    SMB4iOSAsyncUdpSocket *_udpSocket;
    NSMutableDictionary<NSNumber *,NetBiosOperation *> *_operations;
    long _nextOperationTag;
}

+ (NetBios *) instance{
    static dispatch_once_t onceToken;
    static NetBios *netBios = nil;
    dispatch_once(&onceToken, ^{
        netBios = [[NetBios alloc] init];
    });
    return netBios;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _operations = [[NSMutableDictionary<NSNumber *,NetBiosOperation *> alloc] init];
        _nextOperationTag = 1;
        _stateLock = [NSRecursiveLock new];
    }
    return self;
}

- (long)nextOperationTag{
    long result = 0;
    [self.stateLock lock];
    result = _nextOperationTag;
    _nextOperationTag++;
    if (_nextOperationTag >= 2048) {
        _nextOperationTag = 1;
    }
    [self.stateLock unlock];
    return result;
}

+ (void)performOnTreadWithRunLoopInDefaultModeBlock:(dispatch_block_t)block{
    NSString *runLoopMode = [NSRunLoop currentRunLoop].currentMode;
    if ([runLoopMode isEqualToString:NSDefaultRunLoopMode]) {
        if(block){
            block();
        }
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void) resolveMasterBrowser:(NetBiosCompletionBlock)aCompletion{
    [NetBios performOnTreadWithRunLoopInDefaultModeBlock: ^{
        [self resolveName:@"\1\2__MSBROWSE__\2"
                   suffix:'\1'
                   onHost:@"255.255.255.255"
               completion:aCompletion];
    }];
}

- (void) resolveAllOnHost:(NSString *)host
               completion:(NetBiosCompletionBlock)aCompletion
{
    // @"*\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
    [NetBios performOnTreadWithRunLoopInDefaultModeBlock: ^{
        [self resolveName:@"<all>"
                   suffix:'\0'
                   onHost:host
               completion:aCompletion];
    }];
}

- (void) resolveServer_0x20:(NSString *)nbtName
                 completion:(NetBiosCompletionBlock)aCompletion
{
    [NetBios performOnTreadWithRunLoopInDefaultModeBlock: ^{
        [self resolveName:nbtName
                   suffix:0x20
                   onHost:@"255.255.255.255"
               completion:aCompletion];
    }];
}

- (void) resolveServer_0x1D:(NSString *)nbtName
                 completion:(NetBiosCompletionBlock)aCompletion
{
    [NetBios performOnTreadWithRunLoopInDefaultModeBlock: ^{
        [self resolveName:nbtName
                   suffix:0x1d
                   onHost:@"255.255.255.255"
               completion:aCompletion];
    }];
}

- (SMB4iOSAsyncUdpSocket *)udpSocket{
    SMB4iOSAsyncUdpSocket *socket = nil;
    [self.stateLock lock];
    if (_udpSocket == nil) {
        _udpSocket = [[SMB4iOSAsyncUdpSocket alloc] initWithDelegate:self];
        if ([_udpSocket bindToPort:LISTEN_PORT error:NULL] == NO
            || [_udpSocket enableBroadcast:YES error:NULL] == NO)
        {
            LOG(@"error initializing SMB4iOSAsyncUdpSocket");
            [self closeSocket];
        }
    }
    socket = _udpSocket;
    [self.stateLock unlock];
    return socket;
}

- (void)closeSocket{
    [self.stateLock lock];
    if (_udpSocket) {
        _udpSocket.delegate = nil;
        [_udpSocket close];
        _udpSocket = nil;
    }
    [self.stateLock unlock];
}

- (void) resolveName:(NSString *)name
              suffix:(char)suffix
              onHost:(NSString *)host
          completion:(NetBiosCompletionBlock)aCompletion
{
    
    if (name == nil || name.length == 0) {
        LOG(@"name is empty");
        if (aCompletion) {
            aCompletion(nil);
        }
        return;
    }
    
    if (host == nil || host.length == 0) {
        LOG(@"host is empty");
        if (aCompletion) {
            aCompletion(nil);
        }
        return;
    }
    
    [self.stateLock lock];
    
    NetBiosOperation *op = [[NetBiosOperation alloc] init];
    op.completion = aCompletion;
    op.tag = [self nextOperationTag];
    op.serverName = name;
    
    NetBiosQuery *query = [[NetBiosQuery alloc] init];
    query.nbtName = name;
    query.nbtSuffix = suffix;
    query.transactionID = op.tag;
    NSData *request = [query getRequest];
    LOGDATA(request);
    
    if (self.udpSocket == nil) {
        if (aCompletion) {
            aCompletion(nil);
        }
        [self.stateLock unlock];
        return;
    }
    
    [_operations setObject:op forKey:@(op.tag)];
    
    BOOL sendDataResult = [self.udpSocket sendData:request
                                            toHost:host
                                              port:137
                                       withTimeout:WRITE_TIMEOUT
                                               tag:op.tag];
    
    if (sendDataResult == NO) {
        LOG(@"error sending SMB4iOSAsyncUdpSocket");
        if (aCompletion) {
            aCompletion(nil);
        }
        [_operations removeObjectForKey:@(op.tag)];
        [self.stateLock unlock];
        return;
    }
    
    [self.udpSocket receiveWithTimeout:READ_TIMEOUT tag:op.tag];
    
    [self.stateLock unlock];
}

- (void)onUdpSocket:(SMB4iOSAsyncUdpSocket *)sock
 didSendDataWithTag:(long)tag
{
    LOG(@"didSendDataWithTag: %@",@(tag));
}

- (void)onUdpSocket:(SMB4iOSAsyncUdpSocket *)sock
didNotSendDataWithTag:(long)tag
         dueToError:(NSError *)error
{
    LOG(@"didNotSendDataWithTag: %@ error: %@",@(tag),error);
}

- (BOOL)onUdpSocket:(SMB4iOSAsyncUdpSocket *)sock
     didReceiveData:(NSData *)data
            withTag:(long)tag
           fromHost:(NSString *)host
               port:(UInt16)port
{
    LOG(@"didReceiveData %@ from %@:%@", @(data.length), host, @(port));
    LOGDATA(data);
    BOOL result = NO;
    
    [self.stateLock lock];
    
    NSString *resolvedHost = nil;
    NetBiosQuery *query = [[NetBiosQuery alloc] init];
    query.transactionID = tag;
    
    if ([query parseResponse:data]) {
        resolvedHost = query.host;
        result = YES;
    }
    
    NetBiosOperation *op = [_operations objectForKey:@(tag)];
    if (result) {
        LOG(@"didResolveHost: %@ for: %@", resolvedHost, op.serverName);
    }
    else {
        LOG(@"didNotResolveHostFor: %@", op.serverName);
    }
    if (op.completion) {
        op.completion(resolvedHost);
    }
    
    [_operations removeObjectForKey:@(tag)];
    
    [self.stateLock unlock];
    
    return result;
}

- (void)onUdpSocket:(SMB4iOSAsyncUdpSocket *)sock
didNotReceiveDataWithTag:(long)tag
         dueToError:(NSError *)error
{
    LOG(@"didNotReceiveDataWithTag: %@ error: %@",@(tag),error);
    [self.stateLock lock];
    NetBiosOperation *op = [_operations objectForKey:@(tag)];
    if (op.completion) {
        op.completion(nil);
    }
    [_operations removeObjectForKey:@(tag)];
    [self.stateLock unlock];
}

- (void)onUdpSocketDidClose:(SMB4iOSAsyncUdpSocket *)sock{
    LOG(@"onUdpSocketDidClose");
    [self.stateLock lock];
    _udpSocket = nil;
    NSDictionary *operations = _operations;
    [operations enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key,
                                                    NetBiosOperation * _Nonnull obj,
                                                    BOOL * _Nonnull stop)
     {
        NetBiosOperation *op = obj;
        if (op.completion) {
            op.completion(nil);
        }
    }];
    [_operations removeAllObjects];
    [self.stateLock unlock];
}

@end


@implementation NetBiosOperation

@end
