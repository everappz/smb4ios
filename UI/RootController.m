#import "RootController.h"
#import "ServersController.h"
#import <SMB4iOSFramework/SMB4iOSFramework.h>


@implementation RootController
{
    NSArray *items;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Domains";
    
    [[NetBios instance]
     resolveMasterBrowser:^(NSString *host)
     {
        dispatch_async(dispatch_get_main_queue(), ^
                       {
            if (host == NULL)
            {
                [self finishActivityWithEmptySet:true error:@"Failed to resolve NetBIOS master browser"];
                return;
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                           {
                SmbConnection *conn = [[SmbConnection alloc] init];
                [conn connectToHost:host];
                bool success = [conn enumDomains];
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
    
    NSString *domain = [items objectAtIndex:indexPath.row];
    cell.textLabel.text = domain;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *domain = [items objectAtIndex:indexPath.row];
    
    ServersController *ctr = [[ServersController alloc] init];
    ctr.domain = domain;
    [self.navigationController pushViewController:ctr animated:true];
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
