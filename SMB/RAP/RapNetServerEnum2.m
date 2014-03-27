#import "RapNetServerEnum2.h"
#import "NSMutableData+SMB.h"


@implementation RapNetServerEnum2

- (NSData *) getRequest
{
	NSMutableData *request = [NSMutableData data];

	[request appendWordLE:0x0068]; // RAPOpcode
	[request appendCStringNT:(self.domain != NULL ? @"WrLehDz" : @"WrLehDO")]; // ParamDesc
	[request appendCStringNT:@"B16BBDz"]; // DataDesc (descriptor for InfoLevel 1)
	
	// RAPParams
	[request appendWordLE:0x0001]; // InfoLevel
	[request appendWordLE:0xFFFF]; // ReceiveBufferSize
	[request appendUInt32LE:self.serverType]; // ServerType

	if (self.domain != NULL)
		[request appendCStringNT:self.domain];
	
	return request;
}

- (bool) parseResponseParameters:(NSData *)params data:(NSData *)data
{
	if (![super parseResponseParameters:params data:data])
		return false;

	if (params.length < RAP_HEADER_LENGTH + 4)
	{
		self.error = @"Incorrect response length";
		return false;
	}
	
	int entriesReturned = [params wordLEAt:RAP_HEADER_LENGTH];
	
	NSMutableArray *shares = [NSMutableArray array];
	for (int i = 0; i < entriesReturned; i++)
	{
		RapNetServerInfo1 *info = [[RapNetServerInfo1 alloc] init];
		if (![info parseData:data offset:RapNetServerInfo1Size * i converter:self.converter])
		{
			self.error = @"Unexpected response";
			return false;
		}
		[shares addObject:info.serverName];
	}
	self.shares = shares;

	return true;
}

@end
