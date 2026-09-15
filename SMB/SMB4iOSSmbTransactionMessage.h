#import "SMB4iOSSmbMessage.h"

#define TRANS_TRANSACT_NMPIPE 0x0026


@interface SMB4iOSSmbTransactMessage : SMB4iOSSmbMessage
{
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSData *setup;
@property (nonatomic, strong) NSData *transactionParameters;
@property (nonatomic, strong) NSData *transactionData;
@property (nonatomic, assign) int expectedParameters;
@property (nonatomic, assign) bool eof;

@end
