#import "ServersController.h"
#import "LoginController.h"
#import <SMB4iOSFramework/SMB4iOSFramework.h>


@implementation ServersController
{
    NSArray *items;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Servers";
    
    [[NetBios instance]
     resolveMasterBrowser:^(NSString *host)
     {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (host == NULL)
            {
                [self finishActivityWithEmptySet:true error:@"Failed to resolve NetBIOS master browser"];
                return;
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                           {
                SmbConnection *conn = [[SmbConnection alloc] init];
                [conn connectToHost:host];
                bool success = [conn enumServers:self.domain];
                [conn close];
                
                NSString *error = (success ? NULL : (conn.error == NULL ? @"SMB error" : conn.error));
                
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                    items = conn.items;
                    [self finishActivityWithEmptySet:(items.count == 0) error:error];
                });
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NULL];
    
    NSString *server = [items objectAtIndex:indexPath.row];
    cell.textLabel.text = server;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *server = [items objectAtIndex:indexPath.row];
    
    LoginController *ctr = [[LoginController alloc] init];
    ctr.server = server;
    [self.navigationController pushViewController:ctr animated:true];
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
