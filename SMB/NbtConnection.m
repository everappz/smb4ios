#import "NbtConnection.h"
#import "NSMutableData+SMB.h"

const NSUInteger kNbtConnectionSessionHeaderLength = 4;

const Byte kNbtConnectionSessionMessageTypeKeepAlive = 0x85;
const Byte kNbtConnectionSessionMessageTypeDefault = 0x00;

const Byte NBT_CONN_EMPTY_1_BYTE[] = {0x0};

#define WRITE_TIMEOUT 5.0
#define READ_TIMEOUT  5.0
#define CONNECT_TIMEOUT 10.0


@implementation NbtConnection

- (BOOL) writeNbtMessage:(NSData *)data{
    NSData *smbPacketData = data;
    NSUInteger smbMessageLength = smbPacketData.length;
    NSMutableData *nbtData = [NSMutableData data];
    [nbtData appendByte:0];
    [nbtData appendByte:((Byte) (smbMessageLength >> 16))];
    [nbtData appendByte:((Byte) (smbMessageLength >> 8))];
    [nbtData appendByte:((Byte) (smbMessageLength & 0xFF))];
    [nbtData appendData:smbPacketData];
    return [self writeData:nbtData withTimeout:WRITE_TIMEOUT error:nil];
}

- (NSInteger)readData:(NSMutableData *)data length:(NSUInteger)length{
    NSInteger readDataLength = 0;
    if([self readDataWithTimeout:READ_TIMEOUT buffer:data maxLength:length error:nil]){
        readDataLength = length;
        return readDataLength;
    }
    return -1;
}

- (NSData *)readPacket{
    
    NSInteger dataLength = kNbtConnectionSessionHeaderLength;
    NSInteger n;
    NSMutableData *headerData = [[NSMutableData alloc] init];
    Byte netbiosMessageType = kNbtConnectionSessionMessageTypeDefault;
    
    if ((n = [self readData:headerData length:dataLength]) < dataLength){
        return nil;
    }
    
    netbiosMessageType = [headerData byteAt:0];
    [headerData replaceBytesInRange:NSMakeRange(0, 1) withBytes:NBT_CONN_EMPTY_1_BYTE];//1 st byte is NetBIOS message type;
    NSUInteger netBIOSPacketLength = [headerData uint32BEAt:0];
    
    if(netBIOSPacketLength>0){
        if(netbiosMessageType==kNbtConnectionSessionMessageTypeDefault){
            NSMutableData *smbPacketData = [[NSMutableData alloc] init];
            if ((n = [self readData:smbPacketData length:netBIOSPacketLength]) < netBIOSPacketLength){
                return nil;
            }
            return smbPacketData;
        }
        else{
            [self skip:netBIOSPacketLength];
        }
    }
    
    return nil;
}

- (BOOL)skip:(NSUInteger)len{
    NSInteger readDataLength = [self readData:[NSMutableData data] length:len];
    return (readDataLength==len);
}

- (NSData *)read{
    return [self readPacket];
}

- (void)close{
    [self disconnect];
}

- (BOOL)connectToAddress:(NSString *)addr port:(NSUInteger)port{
    self.ipAddress = addr;
    self.port = port;
    return [self connectWithTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL) write:(NSData *)data{
    return [self writeData:data withTimeout:WRITE_TIMEOUT error:nil];
}

@end
