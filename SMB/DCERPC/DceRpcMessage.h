#import <Foundation/Foundation.h>

#define DCERPC_PARSE_OK    0
#define DCERPC_PARSE_ERROR 1
#define DCERPC_PARSE_MORE  2


@interface DceRpcMessage : NSObject
{
}

@property (nonatomic, assign) UInt16 callId;
@property (nonatomic, assign) UInt16 opnum;
@property (nonatomic, strong) NSData *request;
@property (nonatomic, readonly) int requestFragments;
@property (nonatomic, strong) NSMutableData *response;
@property (nonatomic, strong) NSString *error;

- (void) prepareRequest;
- (NSData *) getRequestFragment:(int)idx;
- (int) receiveFragment:(NSData *)data;
- (bool) parseResponse;

- (void) appendTo:(NSMutableData *)rpc data:(NSData *)data;
- (void) appendTo:(NSMutableData *)rpc string:(NSString *)string;

@end
