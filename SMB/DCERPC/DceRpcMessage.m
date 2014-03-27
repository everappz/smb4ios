#import "DceRpcMessage.h"
#import "DceRpcDefines.h"
#import "NSMutableData+SMB.h"

// http://pubs.opengroup.org/onlinepubs/9629399/chap12.htm

#define DCERPC_HEADER_LENGTH 16
#define DCERPC_FIELD_PTYPE   2
#define DCERPC_FIELD_PFLAGS  3
#define DCERPC_FIELD_LENGTH  8


@implementation DceRpcMessage

- (void) prepareRequest
{
	self.response = NULL;
}

- (int) requestFragments
{
	return self.request.length / MAX_XMIT + 1;
}

- (NSData *) getRequestFragment:(int)idx
{
	NSMutableData *frag = [NSMutableData data];

	int headerLen = 24;
	int chunk = MAX_XMIT - headerLen;
	int offset = idx * chunk;
	int dataLen = MIN(self.request.length - offset, chunk);
	
	int flags = 0;
	if (idx == 0)
		flags |= PFC_FIRST_FRAG;
	if (idx == self.requestFragments - 1)
		flags |= PFC_LAST_FRAG;
		
	[frag appendByte:0x05]; // version
	[frag appendByte:0x00]; // version
	[frag appendByte:PTYPE_REQUEST]; // packet type
	[frag appendByte:flags]; // packet flags
	[frag appendUInt32LE:0x00000010]; // data representation
	[frag appendWordLE:headerLen + dataLen]; // file length
	[frag appendWordLE:0x0000]; // auth length
	[frag appendUInt32LE:self.callId]; // call id

	[frag appendUInt32LE:0x00000000]; // alloc hint
	[frag appendWordLE:0x0000]; // context id
	[frag appendWordLE:self.opnum]; // opnum

	[frag appendBytes:self.request.bytes + offset length:dataLen];

	return frag;
}

- (int) receiveFragment:(NSData *)data
{
	if (data.length < DCERPC_HEADER_LENGTH || data.length != [data wordLEAt:DCERPC_FIELD_LENGTH])
	{
		self.error = @"Incorrect fragment length";
		return DCERPC_PARSE_ERROR;
	}
	
	UInt8 ptype = [data byteAt:DCERPC_FIELD_PTYPE];
	
	UInt16 headerLength = DCERPC_HEADER_LENGTH;
	if (ptype == PTYPE_REQUEST || ptype == PTYPE_RESPONSE || ptype == PTYPE_FAULT)
		headerLength += 8;
	
	if (ptype == PTYPE_FAULT)
	{
		if (data.length == 32)
		{
			UInt32 errorCode = [data uint32LEAt:headerLength];
			self.error = [NSString stringWithFormat:@"error 0x%x", (unsigned int)errorCode];
		}
		else
			self.error = @"Failure status";
		return DCERPC_PARSE_ERROR;
	}
	
	UInt8 flags = [data byteAt:DCERPC_FIELD_PFLAGS];
	if (self.response == NULL)
	{
		if ((flags & PFC_FIRST_FRAG) == 0)
		{
			self.error = @"First packet expected";
			return DCERPC_PARSE_ERROR;
		}
		
		self.response = [NSMutableData data];
	}
	
	[self.response appendBytes:data.bytes + headerLength length:data.length - headerLength];

	return ((flags & PFC_LAST_FRAG) == 0 ? DCERPC_PARSE_MORE : DCERPC_PARSE_OK);
}

- (bool) parseResponse
{
	return true;
}

- (void) appendTo:(NSMutableData *)rpc data:(NSData *)data
{
	if (data == NULL)
	{
		[rpc appendUInt32LE:0];
	}
	else
	{
		[rpc appendUInt32LE:0x00000001];
		[rpc appendUInt32LE:data.length];
		[rpc appendData:data];
	}
}

- (void) appendTo:(NSMutableData *)rpc string:(NSString *)string
{
	[rpc padTo4From:0];
	[rpc appendUInt32LE:string.length+1]; // max count
	[rpc appendUInt32LE:0x00000000]; // offset
	[rpc appendUInt32LE:string.length+1]; // actual count
	[rpc appendUStringNT:string];
}

@end
