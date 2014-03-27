
@interface DceRpcDataReader : NSObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) int position;
@property (nonatomic, readonly) int remaining;

- (id) initWithData:(NSData *)data;

- (UInt8) readByte;
- (UInt16) readWord;
- (UInt32) readInt;
- (NSString *) readNTString;
- (NSString *) readString;
- (void) alignTo:(int)value;

@end
