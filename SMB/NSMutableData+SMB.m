#import "NSMutableData+SMB.h"

#define CheckIndexAndReturnTypeLength(__INDEX__,__RETURN_TYPE__) if(self.length<(__INDEX__+sizeof(__RETURN_TYPE__))){return 0;}

@implementation NSMutableData (SMB)

- (void) appendByte:(UInt8)byte
{
	[self appendBytes:&byte length:1];
}

- (void) appendWordLE:(UInt16)number;
{
	[self appendBytes:&number length:2];
}

- (void) appendWordBE:(UInt16)number;
{
	UInt16 bigEndian = htons(number);
	[self appendBytes:&bigEndian length:2];
}

- (void) appendUInt32LE:(UInt32)number // 0x12000034 = 34 00 00 12
{
	[self appendBytes:&number length:4];
}

- (void) appendUInt32BE:(UInt32)number // 0x12000034 = 12 00 00 34
{
	UInt32 bigEndian = htonl(number);
	[self appendBytes:&bigEndian length:4];
}

- (void) appendUInt64LE:(UInt64)number
{
	[self appendBytes:&number length:8];
}

- (void) appendCString:(NSString *)string
{
	[self appendBytes:[string UTF8String] length:string.length];
}

- (void) appendCStringNT:(NSString *)string
{
	[self appendBytes:[string UTF8String] length:string.length+1];
}

- (void) appendUString:(NSString *)string
{
	[self appendData:[string dataUsingEncoding:NSUTF16LittleEndianStringEncoding]];
}

- (void) appendUStringNT:(NSString *)string
{
	[self appendData:[string dataUsingEncoding:NSUTF16LittleEndianStringEncoding]];
	[self appendWordLE:0x0000];
}

- (void) padTo2From:(int)offset
{
	while ((offset + self.length) % 2 != 0)
		[self appendByte:0];
}

- (void) padTo4From:(int)offset
{
	while ((offset + self.length) % 4 != 0)
		[self appendByte:0];
}

- (void) setUInt32LE:(int)value at:(int)index
{
	*(unsigned int *)(((unsigned char *)self.bytes) + index) = value;
}

- (void) setWordLE:(UInt16)value at:(int)index
{
	*(unsigned short *)(((unsigned char *)self.bytes) + index) = value;
}

@end


@implementation NSData (SMB)

- (UInt8) byteAt:(int)index
{
    CheckIndexAndReturnTypeLength(index,UInt8);
    UInt8 value = 0;
    NSUInteger length = sizeof(UInt8);
    void *buffer = malloc(length);
    [self getBytes:buffer range:NSMakeRange(index, length)];
    value = (*(const UInt8 *)buffer);
    free(buffer);
    return value;
}

- (UInt16) wordLEAt:(int)index
{
    CheckIndexAndReturnTypeLength(index,UInt16);
    UInt16 value = 0;
    NSUInteger length = sizeof(UInt16);
    void *buffer = malloc(length);
    [self getBytes:buffer range:NSMakeRange(index, length)];
    value = CFSwapInt16LittleToHost(*(const UInt16 *)buffer);
    free(buffer);
    return value;
}

- (UInt16) wordBEAt:(int)index
{
    CheckIndexAndReturnTypeLength(index,UInt16);
    UInt16 value = 0;
    NSUInteger length = sizeof(UInt16);
    void *buffer = malloc(length);
    [self getBytes:buffer range:NSMakeRange(index, length)];
    value = CFSwapInt16BigToHost(*(const UInt16 *)buffer);
    free(buffer);
    return value;
}

- (UInt32) uint32LEAt:(int)index
{
    CheckIndexAndReturnTypeLength(index,UInt32);
    UInt32 value = 0;
    NSUInteger length = sizeof(UInt32);
    void *buffer = malloc(length);
    [self getBytes:buffer range:NSMakeRange(index, length)];
    value = CFSwapInt32LittleToHost(*(const UInt32 *)buffer);
    free(buffer);
    return value;
}

- (UInt32)uint32BEAt:(int)index{
    CheckIndexAndReturnTypeLength(index,UInt32);
    UInt32 value = 0;
    NSUInteger length = sizeof(UInt32);
    void *buffer = malloc(length);
    [self getBytes:buffer range:NSMakeRange(index, length)];
    value = CFSwapInt32BigToHost(*(const UInt32 *)buffer);
    free(buffer);
    return value;
}

+ (int)pad:(int)index to:(int)value{
	int rem = index % value;
    if (rem == 0){
		return index;
    }
    else{
		return index + value - rem;
    }
}

@end
