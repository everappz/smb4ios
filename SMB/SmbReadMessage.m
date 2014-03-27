#import "SmbReadMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"

#define PARAM_LEN 24


@implementation SmbReadMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_READ_ANDX;
	}
	return self;
}

- (NSData *) getParametersData
{
	NSMutableData *result = [NSMutableData data];

	[result appendByte:SMB_COM_NONE]; // AndX Command
	[result appendByte:0]; // reserved
	[result appendWordLE:0]; // AndX Offset

	[result appendWordLE:self.fid]; // FID
	[result appendUInt32LE:0]; // Offset
	[result appendWordLE:1024]; // MaxCountOfBytesToReturn
	[result appendWordLE:1024]; // MinCountOfBytesToReturn
	[result appendUInt32LE:0]; // Timeout
	[result appendWordLE:0]; // Remaining
	[result appendUInt32LE:0]; // OffsetHigh
	
	assert(result.length == PARAM_LEN);
	return result;
}

- (bool) parseResponse:(NSData *)data
{
	self.eof = true;

	if (![super parseResponse:data])
		return false;

	if (self.responseParameters.length != 24)
	{
		self.error = @"Incorrect parameters length";
		return false;
	}
	
	int n = 0;
	n += 1; // AndXCommand
	n += 1; // AndXReserved
	n += 2; // AndXOffset
	n += 2; // Available (not always relevant)
	n += 2; // DataCompactionMode
	n += 2; // Reserved1
	int dataLength = [self.responseParameters wordLEAt:n]; n += 2; // DataLength
	n += 2; // DataOffset

	if (dataLength + 1 != self.responseMessageData.length)
	{
		self.error = @"Incorrect data length";
		return false;
	}

	self.data = [NSData dataWithBytes:self.responseMessageData.bytes + 1 length:dataLength];
	return true;
}

- (bool) expectNtStatus:(unsigned int)status
{
	if (status == NT_STATUS_BUFFER_OVERFLOW)
	{
		self.eof = false;
		return true;
	}
	return false;
}

@end
