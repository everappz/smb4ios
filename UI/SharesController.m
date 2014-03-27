#import "SharesController.h"
#import "SmbConnection.h"
#import "DceRpc.h"
#import "NetBios.h"
#import "PrinterController.h"


@implementation SharesController
{
	NSString *serverIP;
	NSArray *items;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Shares";

	[[NetBios instance]
		resolveServer:self.server completion:^(NSString *host)
		{
			if (host == NULL)
			{
				[self finishActivityWithEmptySet:true error:@"Failed to resolve NetBIOS server"];
				return;
			}
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
			{
				SmbConnection *conn = [[SmbConnection alloc] init];
				conn.username = self.username;
				conn.password = self.password;
				[conn connectToHost:host];
				bool success = [conn enumShares];
				[conn close];

				NSString *error = (success ? NULL : (conn.error == NULL ? @"SMB error" : conn.error));

				dispatch_async(dispatch_get_main_queue(), ^
				{
					serverIP = host;
					items = conn.items;
					[self finishActivityWithEmptySet:(items.count == 0) error:error];
				});
			});
		}];
}


// UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NULL];
	if (cell == NULL)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NULL];
		
	NSDictionary *rec = [items objectAtIndex:indexPath.row];
	cell.textLabel.text = [rec objectForKey:@"name"];
		
	NSString *sType = NULL;
	int type = [[rec objectForKey:@"type"] intValue];
	switch (type & 3)
	{
		case STYPE_DISKTREE:
			sType = @"Disk";
			break;
		case STYPE_PRINTQ:
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			sType = @"Printer";
			break;
		case STYPE_DEVICE:
			sType = @"Device";
			break;
		case STYPE_IPC:
			sType = @"IPC";
			break;
	}

	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", sType, [rec objectForKey:@"comment"]];
		
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *rec = [items objectAtIndex:indexPath.row];
	if (([[rec objectForKey:@"type"] intValue] & 3) == STYPE_PRINTQ)
	{
		PrinterController *ctr = [[PrinterController alloc] init];
		ctr.serverIP = serverIP;
		ctr.printerName = [rec objectForKey:@"name"];
		ctr.username = self.username;
		ctr.password = self.password;
		[self.navigationController pushViewController:ctr animated:true];
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
