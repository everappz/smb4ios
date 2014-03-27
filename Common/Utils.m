#import "Utils.h"
#import <arpa/inet.h>
#import <netdb.h>


@implementation Utils

// Utils

+ (NSString *) RFC3986EncodeString:(NSString *)s
{
	NSMutableString *result = [NSMutableString string];
	const char *p = [s UTF8String];
	unsigned char c;
	
	for(; (c = *p); p++)
	{
		switch(c)
		{
			case '0' ... '9':
			case 'A' ... 'Z':
			case 'a' ... 'z':
			case '.':
			case '-':
			case '~':
			case '_':
				[result appendFormat:@"%c", c];
				break;
			default:
				[result appendFormat:@"%%%02X", c];
				break;
		}
	}
	return result;
}

+ (bool) isPortrait
{
	UIDeviceOrientation ornt = [[UIDevice currentDevice] orientation];
	bool portrait = (ornt == UIInterfaceOrientationPortrait || ornt == UIInterfaceOrientationPortraitUpsideDown);
	bool landscape = (ornt == UIInterfaceOrientationLandscapeLeft || ornt == UIInterfaceOrientationLandscapeRight);
	
	if (portrait || landscape)
		return portrait;
	else
		return UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
}

+ (NSString *) sockaddrToString:(const void *)sockaddr
{
	if (sockaddr == NULL)
		return NULL;
	return [NSString stringWithFormat:@"%s:%i",
            inet_ntoa(((struct sockaddr_in *)sockaddr)->sin_addr),
            ntohs(((struct sockaddr_in *)sockaddr)->sin_port)];
}

+ (NSData *) sockaddrFromHost:(NSString *)host port:(int)port
{
	struct addrinfo *res0;
	NSString *portStr = [NSString stringWithFormat:@"%u", port];
	if (getaddrinfo([host UTF8String], [portStr UTF8String], NULL, &res0) != 0)
	{
		NSLog(@"getaddrinfo failed");
		freeaddrinfo(res0);
		return NULL;
	}
	NSData *address = [NSData dataWithBytes:res0->ai_addr length:res0->ai_addrlen];
	freeaddrinfo(res0);
	return address;
}

+ (NSData *) sockaddrFromAddress:(NSString *)address
{
	NSArray *args = [address componentsSeparatedByString:@":"];
	if (args.count != 2)
	{
		NSLog(@"error: unexpected address format %@", address);
		return NULL;
	}
	return [Utils sockaddrFromHost:[args objectAtIndex:0] port:[[args objectAtIndex:1] intValue]];
}

+ (NSString *) hostOfAddress:(NSString *)addr
{
	NSArray *args = [addr componentsSeparatedByString:@":"];
	if (args.count != 2)
		return NULL;
	return [args objectAtIndex:0];
}

+ (void) logData:(NSData *)data
{
	[Utils logData:data byteLimit:1000];
}

+ (void) logData:(NSData *)data byteLimit:(int)limit
{
	if (data.length == 0)
	{
		printf("zero length data\n");
		return;
	}

	unsigned char *buffer = (unsigned char *)data.bytes;
	int length = MIN(limit, data.length);

	const unsigned char *ptr = buffer;
	while (ptr < buffer + length) {
		size_t charsToPrintInRow = (buffer + length) - ptr;
		if (charsToPrintInRow > 16) {
			charsToPrintInRow = 16;
		}
		
		printf("%08d |", ptr - buffer);
		
		for (unsigned int i=0; i<charsToPrintInRow; i++) {
			printf(" %02x", *(ptr + i));
		}
		
		for (unsigned int i=0; i<16 - charsToPrintInRow; i++) {
			printf("   ");
		}
		
		printf(" | ");
		
		for (unsigned int i=0; i<charsToPrintInRow; i++) {
			char c = *(ptr + i); 
			if (c < 32 || c > 126) {
				c = '.';
			}
			printf("%c", c);
		}
		
		printf("\n");
		
		ptr += charsToPrintInRow;
	}
}

+ (NSString *) uniqueDeviceId
{
	if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0)
		// just register as new device every time, it's an old iOS which nobody use anymore
		return [[NSUUID UUID] UUIDString];
	else
		return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

// Alerts

+ (void) alertError:(NSString *)msg
{
	[Utils alert:msg title:@"Error"];
}

+ (void) alert:(NSString *)msg title:(NSString *)title
{
	UIAlertView *alert = [[UIAlertView alloc] init];
	alert.title = title;
	alert.message = msg;
	[alert addButtonWithTitle:@"OK"];
	[alert show];
}

@end


