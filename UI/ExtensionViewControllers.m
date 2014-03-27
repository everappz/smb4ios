#import "ExtensionViewControllers.h"
#import <QuartzCore/QuartzCore.h>


@implementation EmptyTableViewController

- (void) viewDidLoad
{
	[super viewDidLoad];

	self.view.backgroundColor = [UIColor whiteColor];
	self.tableView.backgroundColor = [UIColor whiteColor];
	self.tableView.tableFooterView = [[UIView alloc] init];

	_emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.width-20, 120)];
	_emptyLabel.text = @"Nothing found";
	_emptyLabel.textColor = [UIColor darkGrayColor];
	_emptyLabel.backgroundColor = [UIColor clearColor];
	_emptyLabel.numberOfLines = 0;
	_emptyLabel.hidden = true;
	[self.view addSubview:_emptyLabel];
}

@end


@implementation ActivityTableViewController
{
	UIView *activityView;
	UIActivityIndicatorView *activityIndicator;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	activityView = [[UIView alloc] initWithFrame:CGRectMake((self.view.width - 60) / 2,
		(self.view.height - 60) / 2, 60, 60)];
	activityView.autoresizingMask = FlexibleLeft | FlexibleRight | FlexibleTop | FlexibleBottom;
	activityView.layer.cornerRadius = 5.0;
	activityView.backgroundColor = RGBACOLOR(0, 0, 0, 0.4);
	[self.view addSubview:activityView];
		
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
		UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.origin = CGPointMake((activityView.width - activityIndicator.width) / 2,
		(activityView.height - activityIndicator.height) / 2);
	[activityView addSubview:activityIndicator];
	[activityIndicator startAnimating];
}

- (void) finishActivityWithEmptySet:(bool)emptySet error:(NSString *)error
{
	[activityIndicator stopAnimating];
	[activityView removeFromSuperview];

	if (emptySet || error != NULL)
	{
		if (error != NULL)
			self.emptyLabel.text = error;
		self.emptyLabel.hidden = false;
		[self.emptyLabel sizeToFit];
	}
	else
	{
		[self.tableView reloadData];
	}
}

@end
