#import "RapMessage.h"
#import "NSMutableData+SMB.h"

// [MS-RAP]: msdn.microsoft.com/en-us/library/cc240190.aspx


@implementation RapMessage

- (NSData *) getRequest
{
	return NULL;
}

- (bool) parseResponseParameters:(NSData *)params data:(NSData *)data
{
	if (params.length < RAP_HEADER_LENGTH)
	{
		self.error = @"Incorrect resonse length";
		return false;
	}
	
	int errorCode = [params wordLEAt:0];
	if (errorCode != 0)
	{
		self.error = [NSString stringWithFormat:@"error 0x%x", (unsigned int)errorCode];
		return false;
	}

	self.converter = [params wordLEAt:2];

	return true;
}

@end
