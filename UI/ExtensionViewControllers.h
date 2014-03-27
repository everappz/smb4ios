#import "UIViewSizeShortcuts.h"
#import "Utils.h"


@interface EmptyTableViewController : UITableViewController

@property (nonatomic, strong) UILabel *emptyLabel;

@end


@interface ActivityTableViewController : EmptyTableViewController

- (void) finishActivityWithEmptySet:(bool)emptySet error:(NSString *)error;

@end
