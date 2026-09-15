#import "SceneDelegate.h"
#import "RootController.h"


@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
	UIWindowScene *windowScene = (UIWindowScene *)scene;
	self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
	RootController *ctr = [[RootController alloc] init];
	UINavigationController *navctr = [[UINavigationController alloc] initWithRootViewController:ctr];
	navctr.navigationBar.translucent = false;

	// iOS 13+ appearance API: keep the navigation bar opaque in every scroll
	// state so titles never render transparently over the content.
	if (@available(iOS 13.0, *))
	{
		UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
		[appearance configureWithOpaqueBackground];
		navctr.navigationBar.standardAppearance = appearance;
		navctr.navigationBar.scrollEdgeAppearance = appearance;
		navctr.navigationBar.compactAppearance = appearance;
	}

	self.window.rootViewController = navctr;
	[self.window makeKeyAndVisible];
}

@end
