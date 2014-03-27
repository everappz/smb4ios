#import <Foundation/Foundation.h>

@interface NSMutableData (SMB)

- (void) appendByte:(UInt8)byte;
- (void) appendWordLE:(UInt16)number;
- (void) appendWordBE:(UInt16)number;
- (void) appendUInt32LE:(UInt32)number;
- (void) appendUInt32BE:(UInt32)number;
- (void) appendUInt64LE:(UInt64)number;
- (void) appendCString:(NSString *)string;
- (void) appendCStringNT:(NSString *)string;
- (void) appendUString:(NSString *)string;
- (void) appendUStringNT:(NSString *)string;
- (void) padTo2From:(int)offset;
- (void) padTo4From:(int)offset;
- (void) setUInt32LE:(int)value at:(int)index;
- (void) setWordLE:(UInt16)value at:(int)index;

@end


@interface NSData (SMB)

- (UInt8) byteAt:(int)index;
- (UInt16) wordLEAt:(int)index;
- (UInt16) wordBEAt:(int)index;
- (UInt32) uint32LEAt:(int)index;

+ (int) pad:(int)index to:(int)value;

@end
