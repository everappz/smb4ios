#import "SocketConnection.h"
#include <netinet/in.h>
#include <netdb.h>
#import <sys/ioctl.h>
#import <sys/poll.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>


#define SOCKET_NULL -1
#define SOCKET_CONNECT_SUCCESS 0
#define GET_ADDR_INFO_SUCCESS 0
#define CHUNK_SIZE 512

NSString * const SocketConnectionErrorDomain = @"SocketConnectionErrorDomain";

@interface SocketConnection()

@property (nonatomic,assign) int socket;
@property (nonatomic,assign,getter=isConnected) BOOL connected;

@end


@implementation SocketConnection

- (instancetype)init{
    self = [super init];
    if(self){
        self.socket = SOCKET_NULL;
        self.connected = NO;
    }
    return self;
}

- (BOOL)connectWithTimeout:(NSTimeInterval)timeout error:(NSError **)error{
    
    @synchronized(self){
        
        struct addrinfo *remoteAddr, *addrInfoResult;
        
        struct addrinfo hints;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_UNSPEC;
        hints.ai_flags = AI_ADDRCONFIG;
        hints.ai_socktype = SOCK_STREAM;
        
        int gettAddrInfoResult = getaddrinfo([self.ipAddress UTF8String], [[NSString stringWithFormat:@"%@",@(self.port)] UTF8String], &hints, &addrInfoResult);
        if (gettAddrInfoResult!=GET_ADDR_INFO_SUCCESS) {
            if(error){
                *error = [self errorWithCode:SocketConnectionErrorCodeCanNotGetAddressInfo description:[NSString stringWithFormat:@"getaddrinfo:%@",@(gettAddrInfoResult)]];
            }
            return NO;
        }
        
        NSError *connectionError = nil;
        BOOL success = NO;
        
        for (remoteAddr = addrInfoResult; remoteAddr; remoteAddr = remoteAddr->ai_next) {
            
            self.socket = socket(remoteAddr->ai_family,SOCK_STREAM,0);
            
            if(self.socket!=SOCKET_NULL){
                
                // Prevent SIGPIPE signals
                int nosigpipe = 1;
                setsockopt(self.socket, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
                
                // Enable non-blocking IO on the socket
                int result = fcntl(self.socket, F_SETFL, O_NONBLOCK);
                if (result == -1){
                    connectionError = [self errorWithCode:SocketConnectionErrorCodeConnectionFailed description:@"Error enabling non-blocking IO on socket (fcntl)"];
                }
                else{
                    
                    connect(self.socket, remoteAddr->ai_addr , remoteAddr->ai_addrlen);
                    
                    fd_set fdset;
                    struct timeval tv;
                    FD_ZERO(&fdset);
                    FD_SET(self.socket, &fdset);
                    tv.tv_sec = timeout;
                    tv.tv_usec = 0;
                    
                    if (select(self.socket + 1, NULL, &fdset, NULL, &tv) == 1){
                        int so_error;
                        socklen_t len = sizeof so_error;
                        getsockopt(self.socket, SOL_SOCKET, SO_ERROR, &so_error, &len);
                        if (so_error == 0) {
                            success = YES;
                            connectionError = nil;
                            break;
                        }
                        else{
                            connectionError = [self errorWithCode:SocketConnectionErrorCodeConnectionFailed description:[NSString stringWithFormat:@"getsockopt:%@",@(so_error)]];
                        }
                    }
                    
                }
            }
        }
        
        freeaddrinfo(addrInfoResult);
        
        if(success==NO){
            [self disconnect];
            if(error){
                *error = connectionError;
            }
        }
        else{
            
            //Set blocking IO on the socket
            int arg = fcntl(self.socket, F_GETFL, NULL);
            arg &= (~O_NONBLOCK);
            fcntl(self.socket, F_SETFL, arg);
            
            self.connected = YES;
        }
        return success;
    }
}

- (void)disconnect{
    @synchronized(self){
        if (self.socket != SOCKET_NULL){
            close(self.socket);
            self.socket = SOCKET_NULL;
        }
        self.connected = NO;
    }
}

- (BOOL)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr{
    
    @synchronized(self){
        
        if([self isConnected]){
            
            struct timeval tv;
            tv.tv_sec = timeout;
            tv.tv_usec = 0;
            
            if(setsockopt(self.socket, SOL_SOCKET, SO_SNDTIMEO, (char *)&tv, sizeof(struct timeval))<0){
                if (errPtr)
                    *errPtr = [self errnoErrorWithReason:@"Error setting send timeout on socket (setsockopt)"];
                return NO;
            }
            
            int result = -1;
            const void *bufferPtr = [data bytes];
            size_t bytesToSend = data.length;
            
            while ((result = (int)send(self.socket, bufferPtr, bytesToSend, 0)) < bytesToSend && result > 0) {
                bytesToSend -= result;
                bufferPtr += result;
            }
            
            if (result < 0){
                if (errPtr){
                    *errPtr = [self errnoErrorWithReason:@"Error in send() function"];
                }
                return NO;
            }
            
            return YES;
            
        }
        
        if (errPtr){
            *errPtr = [self errorWitDescription:@"Transport disconnected"];
        }
        
        return NO;
    }
}

- (BOOL)readDataWithTimeout:(NSTimeInterval)timeout
                     buffer:(NSMutableData *)mutableData
                  maxLength:(NSUInteger)length
                      error:(NSError **)errPtr{
    
    @synchronized(self){
        
        if([self isConnected]){
            
            struct timeval tv;
            tv.tv_sec = timeout;
            tv.tv_usec = 0;
            
            if(setsockopt(self.socket, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv, sizeof(struct timeval))<0){
                if (errPtr){
                    *errPtr = [self errnoErrorWithReason:@"Error setting receive timeout on socket (setsockopt)"];
                }
                return NO;
            }
            
            int socketFD = self.socket;
            int result = -1;
            
            struct pollfd pollfd[1];
            pollfd->fd = socketFD;
            pollfd->events = POLLIN;
            pollfd->revents = 0;
            
            result = poll(pollfd, 1, timeout*1000); // Wait for available data
            
            //Error during poll()
            if(result < 0) {
                if (errPtr){
                    *errPtr = [self errnoErrorWithReason:@"Error in pool() function"];
                }
                return NO;
            }
            
            //Timeout during poll()
            if(result == 0) {
                if (errPtr){
                    *errPtr = [self errnoErrorWithReason:@"Timeout in pool() function"];
                }
                return NO;
            }
            
            size_t bytesToReceive = length;
            char chunk[CHUNK_SIZE];
            
            while (bytesToReceive > 0) {
                memset(chunk ,0 , CHUNK_SIZE);  //clear the variable
                size_t chunkSize = MIN(CHUNK_SIZE,bytesToReceive);
                result = (int)recv(socketFD , chunk , chunkSize , 0);
                
                //Error
                if( result < 0){
                    if (errPtr){
                        *errPtr = [self errnoErrorWithReason:@"Error in recv() function"];
                    }
                    break;
                }
                // Timeout
                else if(result == 0) {
                    if (errPtr){
                        *errPtr = [self errnoErrorWithReason:@"Timeout in recv() function"];
                    }
                    break;
                }
                else{
                    bytesToReceive -= result;
                    if(result>0){
                        [mutableData appendBytes:chunk length:result];
                    }
                }
                
            }
            
            BOOL success = (mutableData.length==length);
            
            return success;
        }
        
        if (errPtr){
            *errPtr = [self errorWitDescription:@"Transport disconnected"];
        }
        
        return NO;
    }
    
}

- (BOOL)hasBytesAvailable:(NSError **)errPtr{
    @synchronized(self){
        if([self isConnected]){
            int socketFD = self.socket;
            size_t nbytes = 0;
            if (ioctl(socketFD, FIONREAD, (char *)&nbytes) < 0 )  {
                if (errPtr){
                    *errPtr = [self errnoErrorWithReason:@"Error in ioctl() function"];
                }
                return NO;
            }
            return (long)nbytes>0;
        }
        return NO;
    }
}

- (NSError *)errnoErrorWithReason:(NSString *)reason{
    @synchronized(self){
        NSString *errMsg = [NSString stringWithFormat:@"%@:%@",reason,[self errnoErrorMessage]];
        return [self errorWithCode:SocketConnectionErrorCodeUnknown description:errMsg];
    }
}

- (NSString *)errnoErrorMessage{
    @synchronized(self){
        NSString *errMsg = [NSString stringWithUTF8String:strerror(errno)];
        return errMsg;
    }
}

- (NSError *)errorWitDescription:(NSString *)description{
    @synchronized(self){
        return [self errorWithCode:SocketConnectionErrorCodeUnknown description:description];
    }
}

- (NSError *)errorWithCode:(SocketConnectionErrorCode)errorCode description:(NSString *)description{
    @synchronized(self){
        NSDictionary *userInfo = nil;
        if(description){
            userInfo = @{NSLocalizedDescriptionKey : description};
        }
        NSError *error = [NSError errorWithDomain:SocketConnectionErrorDomain code:errorCode userInfo:userInfo];
        return error;
    }
}

@end
