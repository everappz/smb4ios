#import "NetBiosQuery.h"
#import "NSMutableData+SMB.h"

#define TRANSACTION_ID 0x1234

#define TYPE_NB     0x20
#define TYPE_NBSTAT 0x21


@implementation NetBiosQuery

char *L1_Encode(char *dst, const char *name, const char sfx)
{
	char pad = ' ';

	int i = 0;
	int j = 0;
	int k = 0;

	while( ('\0' != name[i]) && (i < 15) )
	{
		k = toupper( name[i++] );
		dst[j++] = 'A' + ((k & 0xF0) >> 4);
		dst[j++] = 'A' +  (k & 0x0F);
	}

	i = 'A' + ((pad & 0xF0) >> 4);
	k = 'A' +  (pad & 0x0F);
	while( j < 30 )
	{
		dst[j++] = i;
		dst[j++] = k;
	}

	dst[30] = 'A' + ((sfx & 0xF0) >> 4);
	dst[31] = 'A' +  (sfx & 0x0F);

	return dst;
}

- (NSData *) getRequest
{
	char encodedName[32];
	
	UInt16 flags;
	UInt8 type;
	
	if ([self.nbtName isEqual:@"<all>"])
	{
		encodedName[0] = 'A' + (('*' & 0xF0) >> 4);
		encodedName[1] = 'A' +  ('*' & 0x0F);
		for (int i = 2; i < 32; i++)
			encodedName[i] = 'A';
			
		flags = 0x0000;
		type = TYPE_NBSTAT;
	}
	else
	{
		L1_Encode(encodedName, [self.nbtName UTF8String], self.nbtSuffix);
		
		flags = 0x0110;
		type = TYPE_NB;
	}

	NSMutableData *request = [NSMutableData data];
	
	[request appendWordBE:TRANSACTION_ID]; // Transaction ID
	[request appendWordBE:flags]; // Flags
	[request appendWordBE:0x0001]; // Questions
	[request appendWordBE:0x0000]; // Answer RRs
	[request appendWordBE:0x0000]; // Authority RRs
	[request appendWordBE:0x0000]; // Additional RRs
	
	[request appendByte:' '];
	[request appendBytes:encodedName length:32];
	[request appendByte:0];

	[request appendWordBE:type]; // Type
	[request appendWordBE:0x0001]; // Class
	
	return request;
}

- (bool) parseResponse:(NSData *)data
{
	if (data.length < 12 + 40)
	{
		self.error = @"Incorrect response length";
		return false;
	}
	
	int n = 0;
	
	int transactionId = [data wordBEAt:n]; n += 2;
	if (transactionId != TRANSACTION_ID)
	{
		self.error = @"Not the requested packet";
		return false;
	}

	int flags = [data wordBEAt:n]; n += 2;
	if ((flags & 0x000F) != 0)
	{
		self.error = [NSString stringWithFormat:@"error 0x%x", (unsigned int)flags];
		return false;
	}
	
	n += 2; // questions
	
	int answers = [data wordBEAt:n]; n += 2;
	if (answers != 1)
	{
		self.error = @"Expected one answer";
		return false;
	}

	n += 2; // authority
	n += 2; // additional
	
	// answer
	n += 34; // nbt address
	int type = [data wordBEAt:n]; n += 2; // type
	n += 2; // class
	n += 4; // ttl
	n += 2; // data length
	
	if (type == TYPE_NB)
	{
		n += 2; // flags
		int a1 = [data byteAt:n]; n += 1;
		int a2 = [data byteAt:n]; n += 1;
		int a3 = [data byteAt:n]; n += 1;
		int a4 = [data byteAt:n]; n += 1;
		self.host = [NSString stringWithFormat:@"%i.%i.%i.%i", a1, a2, a3, a4];
	}
	
	if (type == TYPE_NBSTAT)
	{
		/*
		int count = [data byteAt:n]; n++;
		
		for (int i = 0; i < count; i++)
		{
			NSString *name = @"";
			for (int j = 0; j < 15; j++)
			{
				UInt8 c = [data byteAt:n+j];
				if (c == ' ' || c == 0)
					break;
				name = [name stringByAppendingFormat:@"%c", c];
			}
			n += 15;
			
			UInt8 suffix = [data byteAt:n]; n += 1;
			UInt16 flags = [data wordBEAt:n]; n += 2;
		}
		*/
	}

	return true;
}

@end
