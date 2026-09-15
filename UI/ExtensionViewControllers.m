#import "ExtensionViewControllers.h"
#import <QuartzCore/QuartzCore.h>


@implementation EmptyTableViewController

- (void) viewDidLoad
{
	[super viewDidLoad];

	self.view.backgroundColor = [UIColor whiteColor];
	self.tableView.backgroundColor = [UIColor whiteColor];
	self.tableView.tableFooterView = [[UIView alloc] init];

	_emptyLabel = [[UILabel alloc] init];
	_emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_emptyLabel.text = @"Nothing found";
	_emptyLabel.textColor = [UIColor darkGrayColor];
	_emptyLabel.backgroundColor = [UIColor clearColor];
	_emptyLabel.numberOfLines = 0;
	_emptyLabel.hidden = true;
	[self.view addSubview:_emptyLabel];

	UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
	[NSLayoutConstraint activateConstraints:@[
		[_emptyLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
		[_emptyLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:10],
		[_emptyLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-10],
	]];
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

	activityView = [[UIView alloc] init];
	activityView.translatesAutoresizingMaskIntoConstraints = NO;
	activityView.layer.cornerRadius = 5.0;
	activityView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
	[self.view addSubview:activityView];

	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
		UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
	[activityView addSubview:activityIndicator];
	[activityIndicator startAnimating];

	UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
	[NSLayoutConstraint activateConstraints:@[
		[activityView.widthAnchor constraintEqualToConstant:60],
		[activityView.heightAnchor constraintEqualToConstant:60],
		[activityView.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
		[activityView.centerYAnchor constraintEqualToAnchor:safe.centerYAnchor],
		[activityIndicator.centerXAnchor constraintEqualToAnchor:activityView.centerXAnchor],
		[activityIndicator.centerYAnchor constraintEqualToAnchor:activityView.centerYAnchor],
	]];
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
	}
	else
	{
		[self.tableView reloadData];
	}
}

@end
