#import "SmbNtCreateMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"

#define EXT_FILE_ATTR_NORMAL 0x00000080

#define NT_CREATE_REQUEST_OPLOCK 0x00000002
#define NT_CREATE_REQUEST_OPBATCH 0x00000004
#define NT_CREATE_OPEN_TARGET_DIR 0x00000008
#define NT_CREATE_EXTENDED_RESPONSE 0x00000010 // wireshark

#define FILE_READ_DATA 0x00000001
#define FILE_WRITE_DATA 0x00000002
#define FILE_APPEND_DATA 0x00000004
#define FILE_READ_EA 0x00000008
#define FILE_WRITE_EA 0x00000010
#define FILE_EXECUTE 0x00000020
#define FILE_READ_ATTRIBUTES 0x00000080
#define FILE_WRITE_ATTRIBUTES 0x00000100
#define DELETE 0x00010000
#define READ_CONTROL 0x00020000
#define WRITE_DAC 0x00040000
#define WRITE_OWNER 0x00080000
#define SYNCHRONIZE 0x00100000
#define ACCESS_SYSTEM_SECURITY 0x01000000
#define MAXIMUM_ALLOWED 0x02000000
#define GENERIC_ALL 0x10000000
#define GENERIC_EXECUTE 0x20000000
#define GENERIC_WRITE 0x40000000
#define GENERIC_READ 0x80000000

#define FILE_SHARE_NONE   0x00000000
#define FILE_SHARE_READ   0x00000001
#define FILE_SHARE_WRITE  0x00000002
#define FILE_SHARE_DELETE 0x00000004

#define FILE_SUPERSEDE    0x00000000
#define FILE_OPEN         0x00000001
#define FILE_CREATE       0x00000002
#define FILE_OPEN_IF      0x00000003
#define FILE_OVERWRITE    0x00000004
#define FILE_OVERWRITE_IF 0x00000005

#define SEC_ANONYMOUS     0x00000000
#define SEC_IDENTIFY      0x00000001
#define SEC_IMPERSONATE   0x00000002

/*
	SMB_Parameters
	{
		UCHAR AndXCommand;
		UCHAR AndXReserved;
		USHORT AndXOffset;
		UCHAR OpLockLevel;
		USHORT FID;
		...
*/

#define NTCREATE_RESPONSE_FID_OFFSET 5


@implementation SmbNtCreateMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_NT_CREATE_ANDX;
	}
	return self;
}

- (NSData *) getParametersData
{
	NSMutableData *result = [NSMutableData data];
	
	[result appendByte:SMB_COM_NONE]; // AndX Command
	[result appendByte:0]; // reserved
	[result appendWordLE:0]; // AndX Offset

	[result appendByte:0]; // Reserved
	[result appendWordLE:(self.filename.length+1)*2]; // NameLength
	[result appendUInt32LE:NT_CREATE_EXTENDED_RESPONSE]; // Flags
	[result appendUInt32LE:0]; // RootDirectoryFID
	[result appendUInt32LE:GENERIC_READ|GENERIC_WRITE]; // DesiredAccess
	[result appendUInt64LE:0]; // AllocationSize
	[result appendUInt32LE:EXT_FILE_ATTR_NORMAL]; // ExtFileAttributes
	[result appendUInt32LE:FILE_SHARE_READ|FILE_SHARE_WRITE]; // ShareAccess
	[result appendUInt32LE:FILE_OPEN]; // CreateDisposition
	[result appendUInt32LE:0]; // CreateOptions
	[result appendUInt32LE:SEC_IMPERSONATE]; // ImpersonationLevel
	[result appendByte:0]; // SecurityFlags
	
	assert(result.length == 48);
	
	return result;
}

- (NSData *) getMessageData
{
	NSMutableData *result = [NSMutableData data];

	int offset = SMB_HEADER_LENGTH + 1 + 48 + 2;

	[result padTo2From:offset];
	[result appendUStringNT:self.filename]; // FileName

	return result;
}

- (bool) parseResponse:(NSData *)data
{
	if (![super parseResponse:data])
		return false;

	if (self.responseParameters.length < NTCREATE_RESPONSE_FID_OFFSET + 2)
	{
		self.error = @"Incorrect response parameters";
		return false;
	}
	
	self.fid = [self.responseParameters wordLEAt:NTCREATE_RESPONSE_FID_OFFSET];
	
	return true;
}

/*
0000   ff 53 4d 42 a2 00 00 00 00 08 01 c8 00 00 00 00  .SMB............
0010   00 00 00 00 00 00 00 00 06 08 01 00 00 10 05 00  ................
0020   18 ff 00 00 00 00 12 00 10 00 00 00 00 00 00 00  ................
0030   00 00 00 c0 00 00 00 00 00 00 00 00 80 00 00 00  ................
0040   03 00 00 00 01 00 00 00 00 00 00 00 02 00 00 00  ................
0050   00 13 00 00 5c 00 73 00 70 00 6f 00 6f 00 6c 00  ....\.s.p.o.o.l.
0060   73 00 73 00 00 00                                s.s...
*/

@end
