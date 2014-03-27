#import "AppDelegate.h"
#import "RootController.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	RootController *ctr = [[RootController alloc] init];
	UINavigationController *navctr = [[UINavigationController alloc] initWithRootViewController:ctr];
	navctr.navigationBar.translucent = false;
	self.window.rootViewController = navctr;
	[self.window makeKeyAndVisible];
	return YES;
}
							
@end
