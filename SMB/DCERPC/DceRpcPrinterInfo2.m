#import "DceRpcPrinterInfo2.h"


@implementation DceRpcPrinterInfo2

- (id) initWithReader:(DceRpcDataReader *)reader
{
	int refid = [reader readInt];
	if (refid == 0)
		return NULL;
	
	int size = [reader readInt];
	if (reader.remaining < size)
		return NULL;
		
	if (self = [super init])
	{
		int startPos = reader.position;
		
		self.serverName = [self readStringInBuffer:reader startPos:startPos];
		self.printerName = [self readStringInBuffer:reader startPos:startPos];
		self.shareName = [self readStringInBuffer:reader startPos:startPos];
		self.portName = [self readStringInBuffer:reader startPos:startPos];
		self.driverName = [self readStringInBuffer:reader startPos:startPos];
		self.comment = [self readStringInBuffer:reader startPos:startPos];
		self.location = [self readStringInBuffer:reader startPos:startPos];
		
		reader.position = startPos + size;
	}
	return self;
}

- (NSString *) readStringInBuffer:(DceRpcDataReader *)reader startPos:(int)startPos
{
	int strPos = [reader readInt];
	if (strPos == 0 || strPos >= reader.data.length)
		return NULL;
	
	int rdPos = reader.position;
	reader.position = startPos + strPos;
	NSString *result = [reader readNTString];
	reader.position = rdPos;
	return result;
}

@end
