#import "SmbMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"
#import "Utils.h"

#define SMB_FLAGS_CANONICAL_PATHNAMES 0x10   // Obsolete, set for compatibility
#define SMB_FLAGS_CASELESS_PATHNAMES  0x08   // Pathes are treated as caseless (like on windows system)
#define SMB_FLAGS_SERVER_TO_REDIR     0x80   // 0: request, 1: reply from server

#define SMB_FLAGS2_UNICODE_STRINGS    0x8000 // Strings encoded as unicode
#define SMB_FLAGS2_32BIT_STATUS       0x4000 // Use NT_STATUS response codes in STATUS field
#define SMB_FLAGS2_READ_IF_EXECUTE    0x2000 // Execute permission also grants read
#define SMB_FLAGS2_DFS_PATHNAME       0x1000 // Client knows about distributed file systems
#define SMB_FLAGS2_EXTENDED_SECURITY  0x0800 // Extened security features
#define SMB_FLAGS2_IS_LONG_NAME       0x0040 // Long filenames are supported (not only 8.3 names)
#define SMB_FLAGS2_SECURITY_SIGNATURE 0x0004 // MAC included in signature
#define	SMB_FLAGS2_EAS                0x0002 // Client understands Extened Attributes
#define SMB_FLAGS2_KNOWS_LONG_NAMES   0x0001 // Client accepts long filenames in response


@implementation SmbMessage

- (void) populateHeader:(unsigned char *)buffer_ptr
{
	// Protocol
	*(buffer_ptr) = 0xff;
	*(buffer_ptr + 1) = 'S';
	*(buffer_ptr + 2) = 'M';
	*(buffer_ptr + 3) = 'B';
	
	// Command
	*(unsigned char *)(buffer_ptr + SMB_HEADER_COMMAND_BYTE) = self.command;
	
	// Status
	*(unsigned int *)(buffer_ptr + SMB_HEADER_STATUS_INT) = 0x00;
	
	// Flags
	*(unsigned char *)(buffer_ptr + SMB_HEADER_FLAGS_BYTE) = 0x00;
	*(unsigned char *)(buffer_ptr + SMB_HEADER_FLAGS_BYTE) |= SMB_FLAGS_CASELESS_PATHNAMES;

	// Flags2
	*(unsigned short *)(buffer_ptr + SMB_HEADER_FLAGS2_SHORT) = 0x0000;
	*(unsigned short *)(buffer_ptr + SMB_HEADER_FLAGS2_SHORT) |= SMB_FLAGS2_UNICODE_STRINGS;
	*(unsigned short *)(buffer_ptr + SMB_HEADER_FLAGS2_SHORT) |= SMB_FLAGS2_32BIT_STATUS;
	*(unsigned short *)(buffer_ptr + SMB_HEADER_FLAGS2_SHORT) |= SMB_FLAGS2_IS_LONG_NAME;
	*(unsigned short *)(buffer_ptr + SMB_HEADER_FLAGS2_SHORT) |= SMB_FLAGS2_KNOWS_LONG_NAMES;
	*(unsigned short *)(buffer_ptr + SMB_HEADER_FLAGS2_SHORT) |= SMB_FLAGS2_EXTENDED_SECURITY;
	
	// Extra
	
	// TID
	*(unsigned short *)(buffer_ptr + SMB_HEADER_TID_SHORT) = self.tid;
	// PID
	*(unsigned short *)(buffer_ptr + SMB_HEADER_PID_SHORT) = self.pid;
	// UID
	*(unsigned short *)(buffer_ptr + SMB_HEADER_UID_SHORT) = self.uid;
	// MID
	*(unsigned short *)(buffer_ptr + SMB_HEADER_MID_SHORT) = self.mid;
}

- (NSData *) getParametersData
{
	return NULL;
}

- (NSData *) getMessageData
{
	return NULL;
}

- (NSData *) getRequest
{
	NSMutableData *result = [NSMutableData dataWithLength:SMB_HEADER_LENGTH];
	[self populateHeader:(unsigned char *)result.bytes];
	
	NSData *params = [self getParametersData];

	assert(params.length % 2 == 0);
	
	[result appendByte:(params.length / 2)];
	[result appendData:params];
	
	NSData *message = [self getMessageData];
	[result appendWordLE:message.length];
	[result appendData:message];

	return result;
}

- (bool) parseResponse:(NSData *)data
{
	self.error = NULL;

	// Length of all parts
	if (data.length < SMB_HEADER_LENGTH + 1)
	{
		self.error = @"Invalid length";
		return false;
	}

	unsigned char *buffer_ptr = (unsigned char *)data.bytes;

	int paramLength = *(unsigned char *)(buffer_ptr + SMB_HEADER_LENGTH) * 2;
	if (data.length < SMB_HEADER_LENGTH + 1 + paramLength + 2)
	{
		self.error = @"Invalid length";
		return false;
	}
	
	int dataLength = *(unsigned short *)(buffer_ptr + SMB_HEADER_LENGTH + 1 + paramLength);
	if (data.length < SMB_HEADER_LENGTH + 1 + paramLength + 2 + dataLength)
	{
		self.error = @"Invalid length";
		return false;
	}

	// Header
	if (*(buffer_ptr) != 0xff ||
		*(buffer_ptr + 1) != 'S' ||
		*(buffer_ptr + 2) != 'M' ||
		*(buffer_ptr + 3) != 'B')
	{
		self.error = @"Invalid header";
		return false;
	}
	
	unsigned int ntStatus = *(unsigned int *)(buffer_ptr + SMB_HEADER_STATUS_INT);

	//if (ntStatus != 0) NSLog(@"NT_STATUS %08X", ntStatus);

	if (ntStatus == 0x00010002)
	{
		self.error = @"Client Error"; // undocumented
		return false;
	}
	
	unsigned short ntStatusLevel = ((ntStatus >> 30) & 0x03);
	if (ntStatusLevel != NT_STATUS_SUCCESS && ![self expectNtStatus:ntStatus])
	{
		if (ntStatus == NT_STATUS_BAD_NETWORK_NAME)
			self.error = @"Bad Network Name";
		else if (ntStatus == NT_STATUS_ACCESS_DENIED)
			self.error = @"Access Denied";
		else if (ntStatus == NT_STATUS_LOGON_FAILURE)
			self.error = @"Logon Failure";
		else if (ntStatus == NT_STATUS_LOGON_TYPE_NOT_GRANTED)
			self.error = @"Logon Type Not Granted";
		else if (ntStatus == NT_STATUS_INVALID_PARAMETER)
			self.error = @"Invalid Parameter";
		else
			self.error = [NSString stringWithFormat:@"NT_STATUS %08X", ntStatus];
		return false;
	}
	
	unsigned char receivedCommand = *(unsigned char *)(buffer_ptr + SMB_HEADER_COMMAND_BYTE);
	if (receivedCommand != self.command)
	{
		self.error = @"Mismatching command";
		return false;
	}

	self.responseParametersOffset = SMB_HEADER_LENGTH + 1;
	self.responseParameters = [NSData dataWithBytes:buffer_ptr + self.responseParametersOffset
		length:paramLength];

	self.responseMessageOffset = SMB_HEADER_LENGTH + 1 + paramLength + 2;
	self.responseMessageData = [NSData dataWithBytes:buffer_ptr + self.responseMessageOffset
		length:dataLength];

	return true;
}

- (bool) expectNtStatus:(unsigned int)status
{
	return false;
}

@end
