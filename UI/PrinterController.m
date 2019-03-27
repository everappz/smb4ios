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
		SmbConnection *conn = [[SmbConnection alloc] init];
		conn.username = self.username;
		conn.password = self.password;
		[conn connectToHost:self.serverIP];
		bool success = [conn getPrinter:self.printerName];
		[conn close];

		DceRpcPrinterInfo2 *info = conn.printerInfo;
		NSString *error = (success ? NULL : (conn.error == NULL ? @"SMB error" : conn.error));

		dispatch_async(dispatch_get_main_queue(), ^
		{
			if (error)
			{
				UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.width-20, 20)];
				errorLabel.text = error;
				errorLabel.textColor = [UIColor darkGrayColor];
				[self.view addSubview:errorLabel];
			}
			else
			{
				UILabel *serverLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.width-20, 20)];
				serverLabel.text = info.serverName;
				[self.view addSubview:serverLabel];

				UILabel *printerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, self.view.width-20, 20)];
				printerLabel.text = info.printerName;
				[self.view addSubview:printerLabel];

				UILabel *commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, self.view.width-20, 20)];
				commentLabel.text = info.comment;
				[self.view addSubview:commentLabel];

				UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 70, self.view.width-20, 20)];
				locationLabel.text = info.location;
				[self.view addSubview:locationLabel];
				
				UIButton *printButton = [UIButton buttonWithType:UIButtonTypeSystem];
				printButton.frame = CGRectMake(10, 100, self.view.width - 20, 20);
				[printButton setTitle:@"Print Hello World" forState:UIControlStateNormal];
				[printButton addTarget:self action:@selector(printButton_Touched) forControlEvents:UIControlEventTouchUpInside];
				[self.view addSubview:printButton];
			}
		});
	});
}

- (void) printButton_Touched
{
	NSData *data = [@"Hello World!\f" dataUsingEncoding:NSASCIIStringEncoding];

	SmbConnection *conn = [[SmbConnection alloc] init];
	conn.username = self.username;
	conn.password = self.password;
	[conn connectToHost:self.serverIP];
	[conn startPrint:self.printerName];
	[conn write:data];
	[conn endPrint];
	[conn close];
}

@end
