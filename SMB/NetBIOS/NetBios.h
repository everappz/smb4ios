
#import <Foundation/Foundation.h>

typedef void(^NetBiosCompletionBlock)(NSString *host);


@interface NetBios : NSObject

+ (NetBios *) instance;
- (void) resolveMasterBrowser:(NetBiosCompletionBlock)completion;
- (void) resolveAllOnHost:(NSString *)host completion:(NetBiosCompletionBlock)aCompletion;
- (void) resolveServer_0x20:(NSString *)nbtName completion:(NetBiosCompletionBlock)aCompletion;
- (void) resolveServer_0x1D:(NSString *)nbtName completion:(NetBiosCompletionBlock)aCompletion;

@end
