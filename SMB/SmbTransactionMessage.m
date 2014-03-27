#import "SmbTransactionMessage.h"
#import "NSMutableData+SMB.h"
#import "SmbDefines.h"

#define PARAM_LEN 28

@implementation SmbTransactMessage

- (id) init
{
	if (self = [super init])
	{
		self.command = SMB_COM_TRANSACTION;
	}
	return self;
}

- (NSData *) getParametersData
{
	NSMutableData *result = [NSMutableData data];
	
	int n = SMB_HEADER_LENGTH + 1 + PARAM_LEN + self.setup.length + 2;
	n = [NSData pad:n to:2];
	n += (self.name.length + 1) * 2;
	n = [NSData pad:n to:4];
	int paramOffset = (self.transactionParameters.length == 0 ? 0 : n);
	n += self.transactionParameters.length;
	n = [NSData pad:n to:4];
	int dataOffset = (self.transactionData.length == 0 ? 0 : n);

	[result appendWordLE:self.transactionParameters.length]; // TotalParameterCount
	[result appendWordLE:self.transactionData.length]; // TotalDataCount
	[result appendWordLE:self.expectedParameters]; // MaxParameterCount
	[result appendWordLE:0xFFFF]; // MaxDataCount
	[result appendByte:0]; // MaxSetupCount
	[result appendByte:0]; // Reserved1
	[result appendWordLE:0]; // Flags
	[result appendUInt32LE:0]; // Timeout
	[result appendWordLE:0]; // Reserved2
	[result appendWordLE:self.transactionParameters.length]; // ParameterCount
	[result appendWordLE:paramOffset]; // ParameterOffset
	[result appendWordLE:self.transactionData.length]; // DataCount
	[result appendWordLE:dataOffset]; // DataOffset
	[result appendByte:self.setup.length / 2]; // SetupCount
	[result appendByte:0]; // Reserved3
	[result appendData:self.setup];

	assert(result.length == PARAM_LEN + self.setup.length);
	
	return result;
}

- (NSData *) getMessageData
{
	NSMutableData *result = [NSMutableData data];

	int offset = SMB_HEADER_LENGTH + 1 + PARAM_LEN + self.setup.length + 2;

	[result padTo2From:offset];
	[result appendUStringNT:self.name]; // Name

	[result padTo4From:offset];
	[result appendData:self.transactionParameters];

	[result padTo4From:offset];
	[result appendData:self.transactionData];

	return result;
}

- (bool) parseResponse:(NSData *)data
{
	self.eof = true;

	if (![super parseResponse:data])
		return false;

	if (self.responseParameters.length < 20)
	{
		self.error = @"Incorrect parameters length";
		return false;
	}

	// not supporting multiple transactions
	//UInt16 TotalParameterCount = [self.responseParameters wordLEAt:0];
	//UInt16 TotalDataCount = [self.responseParameters wordLEAt:2];
	//UInt16 ParameterDisplacement = [self.responseParameters wordLEAt:10];
	//UInt16 DataDisplacement = [self.responseParameters wordLEAt:16];

	UInt16 ParameterCount = [self.responseParameters wordLEAt:6];
	UInt16 ParameterOffset = [self.responseParameters wordLEAt:8];
	UInt16 DataCount = [self.responseParameters wordLEAt:12];
	UInt16 DataOffset = [self.responseParameters wordLEAt:14];
	UInt8 SetupCount = [self.responseParameters byteAt:18];

	if (self.responseParameters.length != 20 + SetupCount
		|| ParameterOffset - self.responseMessageOffset + ParameterCount > self.responseMessageData.length
		|| DataOffset - self.responseMessageOffset + DataCount > self.responseMessageData.length)
	{
		self.error = @"Incorrect parameters length";
		return false;
	}

	self.transactionParameters = [NSData dataWithBytes:(self.responseMessageData.bytes +
		ParameterOffset - self.responseMessageOffset) length:ParameterCount];
	self.transactionData = [NSData dataWithBytes:(self.responseMessageData.bytes +
		DataOffset - self.responseMessageOffset) length:DataCount];

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

