#import "NetBios.h"
#import "Utils.h"
#import "SMB4iOSAsyncUdpSocket.h"
#import "NetBiosQuery.h"

#define LOG(format, ...) NSLog(format, ## __VA_ARGS__)
//#define LOG(format, ...)

#define LOGDATA(data) [Utils logData:data]
//#define LOGDATA(data)

#define LISTEN_PORT 0
#define WRITE_TIMEOUT 5.0
#define READ_TIMEOUT  5.0


@interface NetBiosOperation : NSObject

@property (nonatomic,copy)NetBiosCompletionBlock completion;
@property (nonatomic,assign)NSUInteger tag;

@end


@interface NetBios () <SMB4iOSAsyncUdpSocketDelegate>

@property (nonatomic,strong)SMB4iOSAsyncUdpSocket *udpSocket;

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
    if(self){
        _operations = [[NSMutableDictionary<NSNumber *,NetBiosOperation *> alloc] init];
        _nextOperationTag = 1;
    }
    return self;
}

- (long)nextOperationTag{
    long result = _nextOperationTag;
    _nextOperationTag++;
    if(_nextOperationTag>=2048){
        _nextOperationTag = 1;
    }
    return result;
}

- (void) resolveMasterBrowser:(void(^)(NSString *host))aCompletion{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resolveName:@"\1\2__MSBROWSE__\2" suffix:'\1' onHost:@"255.255.255.255" completion:aCompletion];
    });
}

- (void) resolveAllOnHost:(NSString *)host completion:(void(^)(NSString *host))aCompletion{
	// @"*\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resolveName:@"<all>" suffix:'\0' onHost:host completion:aCompletion];
    });
}

- (void) resolveServer_0x20:(NSString *)nbtName completion:(void(^)(NSString *host))aCompletion{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resolveName:nbtName suffix:0x20 onHost:@"255.255.255.255" completion:aCompletion];
    });
}

- (void) resolveServer_0x1D:(NSString *)nbtName completion:(void(^)(NSString *host))aCompletion{
    dispatch_async(dispatch_get_main_queue(), ^{
         [self resolveName:nbtName suffix:0x1d onHost:@"255.255.255.255" completion:aCompletion];
    });
}

- (SMB4iOSAsyncUdpSocket *)udpSocket{
    if(_udpSocket==nil){
        _udpSocket = [[SMB4iOSAsyncUdpSocket alloc] initWithDelegate:self];
        if ( [_udpSocket bindToPort:LISTEN_PORT error:NULL]==NO
            || [_udpSocket enableBroadcast:YES error:NULL]==NO){
            LOG(@"error initializing SMB4iOSAsyncUdpSocket");
            [self closeSocket];
        }
    }
    return _udpSocket;
}

- (void)closeSocket{
    if(_udpSocket){
        _udpSocket.delegate = nil;
        [_udpSocket close];
        _udpSocket = nil;
    }
}

- (void) resolveName:(NSString *)name
              suffix:(char)suffix
              onHost:(NSString *)host
	completion:(void(^)(NSString *host))aCompletion{

    @synchronized(self){
        
        NetBiosOperation *op = [[NetBiosOperation alloc] init];
        op.completion = aCompletion;
        op.tag = [self nextOperationTag];
        
        NetBiosQuery *query = [[NetBiosQuery alloc] init];
        query.nbtName = name;
        query.nbtSuffix = suffix;
        query.transactionID = op.tag;
        NSData *request = [query getRequest];
        LOGDATA(request);
        
        if(self.udpSocket==nil){
            dispatch_async(dispatch_get_main_queue(), ^{
                if(aCompletion){
                    aCompletion(nil);
                }
            });
            return;
        }
        
        [_operations setObject:op forKey:@(op.tag)];
        
        if ([self.udpSocket sendData:request toHost:host port:137 withTimeout:WRITE_TIMEOUT tag:op.tag]==NO){
            LOG(@"error sending SMB4iOSAsyncUdpSocket");
            dispatch_async(dispatch_get_main_queue(), ^{
                if(aCompletion){
                    aCompletion(nil);
                }
            });
            [_operations removeObjectForKey:@(op.tag)];
            return;
        }
        
        [self.udpSocket receiveWithTimeout:READ_TIMEOUT tag:op.tag];
        
    }
    
}

- (void)onUdpSocket:(SMB4iOSAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    LOG(@"didSendDataWithTag: %@",@(tag));
}

- (void)onUdpSocket:(SMB4iOSAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    LOG(@"didNotSendDataWithTag: %@ error: %@",@(tag),error);
}

- (BOOL)onUdpSocket:(SMB4iOSAsyncUdpSocket *)sock
     didReceiveData:(NSData *)data
            withTag:(long)tag
           fromHost:(NSString *)host
               port:(UInt16)port{
	LOG(@"didReceiveData %@ from %@:%@", @(data.length), host, @(port));
	LOGDATA(data);
    @synchronized(self){
        BOOL result = NO;
        NSString *resolvedHost = nil;
        NetBiosQuery *query = [[NetBiosQuery alloc] init];
        query.transactionID = tag;
        if ([query parseResponse:data]){
            resolvedHost = query.host;
            result = YES;
        }
        NetBiosOperation *op = [_operations objectForKey:@(tag)];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(op.completion){
                op.completion(resolvedHost);
            }
        });
        [_operations removeObjectForKey:@(tag)];
        return result;
    }
}

- (void)onUdpSocket:(SMB4iOSAsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error{
    LOG(@"didNotReceiveDataWithTag: %@ error: %@",@(tag),error);
     @synchronized(self){
        NetBiosOperation *op = [_operations objectForKey:@(tag)];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(op.completion){
                op.completion(nil);
            }
        });
        [_operations removeObjectForKey:@(tag)];
     }
}

- (void)onUdpSocketDidClose:(SMB4iOSAsyncUdpSocket *)sock{
	LOG(@"onUdpSocketDidClose");
    @synchronized(self){
        _udpSocket = nil;
        NSDictionary *operations = _operations;
        dispatch_async(dispatch_get_main_queue(), ^{
            [operations enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NetBiosOperation * _Nonnull obj, BOOL * _Nonnull stop) {
                NetBiosOperation *op = obj;
                if(op.completion){
                    op.completion(nil);
                }
            }];
        });
        [_operations removeAllObjects];
    }
}

@end


@implementation NetBiosOperation

@end
