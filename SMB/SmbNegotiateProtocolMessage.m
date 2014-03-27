#import "SmbNegotiateProtocolMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"

#define SMB_NEGOTIATE_PROTOCOL_DIALECT_LM012 "NT LM 0.12"

#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_DIALECT_INDEX_SHORT        0
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_SECURITY_MODE_BYTE         2
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_MAX_MPX_COUNT_SHORT        3
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_MAX_NUMBER_VCS_SHORT       5
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_MAX_BUFFER_SIZE_INT        7
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_MAX_RAW_SIZE_INT           11
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_SESSION_KEY_INT            15
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_CAPABILITIES_INT           19
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_SYSTEM_TIME_LOW_INT        23
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_SYSTEM_TIME_HIGH_INT       27
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_SERVER_TIME_ZONE_SHORT     31
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_ENCRYPTION_KEY_LENGTH_BYTE 33
#define SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_LENGTH                     34

@implementation SmbNegotiateProtocolMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_NEGOTIATE;
	}
	return self;
}

- (NSData *) getMessageData
{
	NSMutableData *result = [NSMutableData data];
	
	[result appendByte:0x02]; // Buffer format - dialect
	[result appendBytes:SMB_NEGOTIATE_PROTOCOL_DIALECT_LM012
		length:strlen(SMB_NEGOTIATE_PROTOCOL_DIALECT_LM012)+1];
	
	return result;
}

- (bool) parseResponse:(NSData *)data
{
	if (![super parseResponse:data])
		return false;

	if (self.responseParameters.length != SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_LENGTH)
	{
		self.error = @"Incorrect parameters length";
		return false;
	}
	
	self.sessionKey = [self.responseParameters uint32LEAt:SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_SESSION_KEY_INT];
	
	unsigned int capabilities = [self.responseParameters uint32LEAt:SMB_NEGOTIATE_PROTOCOL_RSP_PARAMETERS_CAPABILITIES_INT];
	if ((capabilities & CAP_EXTENDED_SECURITY) == 0)
	{
		self.error = @"Extended Security unsupported";
		return false;
	}

	return true;
}

@end
