#import "SmbSessionSetupMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"

#define STATUS_MORE_PROCESSING_REQUIRED (0xC0000000 | 0x0016)



@implementation SmbSessionSetupMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_SESSION_SETUP_ANDX;
	}
	return self;
}

- (NSData *) getParametersData
{
	NSMutableData *result = [NSMutableData data];
	
	[result appendByte:SMB_COM_NONE]; // AndX Command
	[result appendByte:0]; // reserved
	[result appendWordLE:0]; // AndX Offset

	[result appendWordLE:0xFFFF]; // MaxBufferSize
	[result appendWordLE:1]; // MaxMpxCount (requests from different sessions)
	[result appendWordLE:1]; // VcNumber (transport streams)
	[result appendUInt32LE:self.sessionKey]; // SessionKey

	if (self.anonymous) // described in MS-CIFS
	{
		[result appendWordLE:0]; // OEMPasswordLen
		[result appendWordLE:0]; // UnicodePasswordLen
		[result appendUInt32LE:0]; // Reserved
		[result appendUInt32LE:CAP_UNICODE|CAP_STATUS32]; // Capabilities
	}
	else // described in MS-SMB
	{
		[result appendWordLE:self.requestSecurityBlob.length]; // SecurityBlobLength
		[result appendUInt32LE:0]; // Reserved
		[result appendUInt32LE:CAP_EXTENDED_SECURITY|CAP_UNICODE|CAP_STATUS32]; // Capabilities
	}
	
	return result;
}

- (NSData *) getMessageData
{
	NSMutableData *result = [NSMutableData data];
	
	if (self.anonymous)
	{
		// OEMPassword[]
		// UnicodePassword[]
		[result appendByte:0]; // Pad[]
		[result appendWordLE:0]; // AccountName[]
		[result appendWordLE:0]; // PrimaryDomain[]
	}
	else
	{
		[result appendData:self.requestSecurityBlob]; // SecurityBlob
	}

	[result appendUStringNT:@"iOS"]; // NativeOS
	[result appendUStringNT:@"smb4ios"]; // NativeLanMan

	return result;
}

#define SECURITY_BLOB_LENGTH_OFFSET 6

- (bool) expectNtStatus:(unsigned int)status
{
	return (status == STATUS_MORE_PROCESSING_REQUIRED);
}

- (bool) parseResponse:(NSData *)data
{
	if (![super parseResponse:data])
		return false;

	self.uid = [data wordLEAt:SMB_HEADER_UID_SHORT];

	int blobLength = [self.responseParameters wordLEAt:SECURITY_BLOB_LENGTH_OFFSET];

	if (self.responseMessageData.length < blobLength)
	{
		self.error = @"Incorrect data length";
		return false;
	}
	
	self.responseSecurityBlob = [NSData dataWithBytes:self.responseMessageData.bytes length:blobLength];

	return true;
}

@end
