
@interface NetBios : NSObject

+ (NetBios *) instance;
- (void) resolveMasterBrowser:(void(^)(NSString *host))completion;
- (void) resolveAllOnHost:(NSString *)host completion:(void(^)(NSString *host))aCompletion;
- (void) resolveServer:(NSString *)nbtName completion:(void(^)(NSString *host))completion;

@end
