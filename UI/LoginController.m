#import "LoginController.h"
#import "UIViewSizeShortcuts.h"
#import "SharesController.h"
#import <SMB4iOSFramework/SMB4iOSFramework.h>

@interface LoginController () <UITextFieldDelegate>

@end

@implementation LoginController
{
	UITextField *txtUsername;
	UITextField *txtPassword;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Login";
	
	self.view.backgroundColor = [UIColor whiteColor];

	txtUsername = [[UITextField alloc] init];
	txtUsername.translatesAutoresizingMaskIntoConstraints = NO;
	txtUsername.placeholder = @"Username";
	txtUsername.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
	txtUsername.clearButtonMode = UITextFieldViewModeWhileEditing;
	txtUsername.autocapitalizationType = UITextAutocapitalizationTypeNone;
	txtUsername.autocorrectionType = UITextAutocorrectionTypeNo;
	txtUsername.delegate = self;
	[self.view addSubview:txtUsername];

	txtPassword = [[UITextField alloc] init];
	txtPassword.translatesAutoresizingMaskIntoConstraints = NO;
	txtPassword.placeholder = @"Password";
	txtPassword.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
	txtPassword.clearButtonMode = UITextFieldViewModeWhileEditing;
	txtPassword.autocapitalizationType = UITextAutocapitalizationTypeNone;
	txtPassword.autocorrectionType = UITextAutocorrectionTypeNo;
	txtPassword.secureTextEntry = true;
	txtPassword.delegate = self;
	[self.view addSubview:txtPassword];

	UIButton *btnGuest = [UIButton buttonWithType:UIButtonTypeSystem];
	btnGuest.translatesAutoresizingMaskIntoConstraints = NO;
	[btnGuest setTitle:@"Use GUEST" forState:UIControlStateNormal];
	[btnGuest addTarget:self action:@selector(btnGuest_Touched) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnGuest];

	UIButton *btnLogin = [UIButton buttonWithType:UIButtonTypeSystem];
	btnLogin.translatesAutoresizingMaskIntoConstraints = NO;
	[btnLogin setTitle:@"Login" forState:UIControlStateNormal];
	[btnLogin addTarget:self action:@selector(btnLogin_Touched) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnLogin];

	UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
	[NSLayoutConstraint activateConstraints:@[
		[txtUsername.topAnchor constraintEqualToAnchor:safe.topAnchor constant:20],
		[txtUsername.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:10],
		[txtUsername.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-10],
		[txtUsername.heightAnchor constraintEqualToConstant:38],

		[txtPassword.topAnchor constraintEqualToAnchor:txtUsername.bottomAnchor constant:12],
		[txtPassword.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:10],
		[txtPassword.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-10],
		[txtPassword.heightAnchor constraintEqualToConstant:38],

		[btnGuest.topAnchor constraintEqualToAnchor:txtPassword.bottomAnchor constant:20],
		[btnGuest.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:10],

		[btnLogin.centerYAnchor constraintEqualToAnchor:btnGuest.centerYAnchor],
		[btnLogin.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-10],
	]];
}

- (void) btnGuest_Touched
{
	txtUsername.text = NULL;
	txtPassword.text = NULL;
	[self action];
}

- (void) btnLogin_Touched
{
	[self action];
}

- (void) action
{
	[txtUsername resignFirstResponder];
	[txtPassword resignFirstResponder];
	
	SharesController *ctr = [[SharesController alloc] init];
	ctr.server = self.server;
	ctr.username = txtUsername.text;
	ctr.password = txtPassword.text;
	[self.navigationController pushViewController:ctr animated:true];
}

// UITextField

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == txtUsername)
		[txtPassword becomeFirstResponder];
	else
		[self action];
	return false;
}

@end
