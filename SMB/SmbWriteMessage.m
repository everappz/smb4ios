#import "SmbWriteMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"

#define PARAM_LEN 28


@implementation SmbWriteMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_WRITE_ANDX;
	}
	return self;
}

- (NSData *) getParametersData
{
	NSMutableData *result = [NSMutableData data];

	int dataOffset = SMB_HEADER_LENGTH + 1 + PARAM_LEN + 2 + 1;

	[result appendByte:SMB_COM_NONE]; // AndX Command
	[result appendByte:0]; // reserved
	[result appendWordLE:0]; // AndX Offset

	[result appendWordLE:self.fid]; // FID
	[result appendUInt32LE:0]; // Offset
	[result appendUInt32LE:0]; // Timeout
	[result appendWordLE:0]; // WriteMode
	[result appendWordLE:0]; // Remaining
	[result appendWordLE:0]; // Reserved
	[result appendWordLE:self.data.length]; // DataLength
	[result appendWordLE:dataOffset]; // DataOffset
	[result appendUInt32LE:0]; // OffsetHigh
	
	assert(result.length == PARAM_LEN);
	return result;
}

- (NSData *) getMessageData
{
	NSMutableData *result = [NSMutableData data];

	[result appendByte:0]; // Pad
	[result appendData:self.data];

	return result;
}

- (bool) parseResponse:(NSData *)data
{
	if (![super parseResponse:data])
		return false;

	return true;
}

@end
