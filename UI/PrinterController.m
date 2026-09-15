#import "PrinterController.h"
#import "UIViewSizeShortcuts.h"
#import <SMB4iOSFramework/SMB4iOSFramework.h>

@implementation PrinterController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Printer";
	self.view.backgroundColor = [UIColor whiteColor];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		SMB4iOSSmbConnection *conn = [[SMB4iOSSmbConnection alloc] init];
		conn.username = self.username;
		conn.password = self.password;
		[conn connectToHost:self.serverIP];
		bool success = [conn getPrinter:self.printerName];
		[conn close];

		SMB4iOSDceRpcPrinterInfo2 *info = conn.printerInfo;
		NSString *error = (success ? NULL : (conn.error == NULL ? @"SMB error" : conn.error));

		dispatch_async(dispatch_get_main_queue(), ^
		{
			UIStackView *stack = [[UIStackView alloc] init];
			stack.translatesAutoresizingMaskIntoConstraints = NO;
			stack.axis = UILayoutConstraintAxisVertical;
			stack.spacing = 10;
			stack.alignment = UIStackViewAlignmentFill;
			[self.view addSubview:stack];

			UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
			[NSLayoutConstraint activateConstraints:@[
				[stack.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
				[stack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:10],
				[stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-10],
			]];

			if (error)
			{
				UILabel *errorLabel = [[UILabel alloc] init];
				errorLabel.text = error;
				errorLabel.textColor = [UIColor darkGrayColor];
				errorLabel.numberOfLines = 0;
				[stack addArrangedSubview:errorLabel];
			}
			else
			{
				UILabel *serverLabel = [[UILabel alloc] init];
				serverLabel.text = info.serverName;
				[stack addArrangedSubview:serverLabel];

				UILabel *printerLabel = [[UILabel alloc] init];
				printerLabel.text = info.printerName;
				[stack addArrangedSubview:printerLabel];

				UILabel *commentLabel = [[UILabel alloc] init];
				commentLabel.text = info.comment;
				[stack addArrangedSubview:commentLabel];

				UILabel *locationLabel = [[UILabel alloc] init];
				locationLabel.text = info.location;
				[stack addArrangedSubview:locationLabel];

				UIButton *printButton = [UIButton buttonWithType:UIButtonTypeSystem];
				[printButton setTitle:@"Print Hello World" forState:UIControlStateNormal];
				[printButton addTarget:self action:@selector(printButton_Touched) forControlEvents:UIControlEventTouchUpInside];
				[stack addArrangedSubview:printButton];
			}
		});
	});
}

- (void) printButton_Touched
{
	NSData *data = [@"Hello World!\f" dataUsingEncoding:NSASCIIStringEncoding];

	SMB4iOSSmbConnection *conn = [[SMB4iOSSmbConnection alloc] init];
	conn.username = self.username;
	conn.password = self.password;
	[conn connectToHost:self.serverIP];
	[conn startPrint:self.printerName];
	[conn write:data];
	[conn endPrint];
	[conn close];
}

@end
