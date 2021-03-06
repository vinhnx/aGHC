//
//  DMSearchResultsTableViewController.m
//  aGHC
//
//  Created by Daniel Miedema on 4/17/13.
//  Copyright (c) 2013 Daniel Miedema. All rights reserved.
//

#import "DMSearchResultsTableViewController.h"
#import "DMRepositoryTableViewCell.h"
#import "JSNotifier.h"
#import "DMRepositoryDetailViewController.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"

@interface DMSearchResultsTableViewController ()

@property (nonatomic, strong) NSMutableArray *repositories;
@property (nonatomic, strong) IBOutlet UITextField *searchTextBox;

@property (nonatomic, strong) NSDictionary *fulldetails;

@property (nonatomic, strong) NIKFontAwesomeIconFactory *factory;

- (IBAction)dismissMe:(id)sender;
- (IBAction)runSearch:(id)sender;

@end

@implementation DMSearchResultsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
        _factory = [NIKFontAwesomeIconFactory tabBarItemIconFactory];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
//    UIBarButtonItem *homeButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissMe:)];
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory barButtonItemIconFactory];

    UIBarButtonItem *homeButton = [UIBarButtonItem new];
    [homeButton setImage:[factory createImageForIcon:NIKFontAwesomeIconHome]];
    [homeButton setAction:@selector(dismissMe:)];
    [homeButton setTarget:self];
    [homeButton setEnabled:YES];
    [homeButton setStyle:UIBarButtonItemStyleBordered];
    
    self.navigationItem.leftBarButtonItem = homeButton;
    
    [[self tableView] registerNib:[UINib nibWithNibName:@"RepositoryTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"Repository Cell"];
    
    
}

- (void)runSearch:(id)sender {
    [[self searchTextBox] resignFirstResponder];
    NSString *searchString = [[self searchTextBox] text];
    searchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionAllowLossy]; // remove spaces and put in escapes == no-crash
    JSNotifier *notifier = [[JSNotifier alloc] initWithTitle:@"Loading..."];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    [notifier setAccessoryView: activityIndicator];
    [notifier show];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@legacy/repos/search/%@", kGitHubApiURL, searchString]]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *reponse, id JSON){
        NSLog(@"JSON: %@", JSON);
        //        NSLog(@"Repositories count: %i",[[self repositories] count]);
        
        // Change the notifier
        [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck"]]];
        [notifier setTitle:@"Complete" animated:YES];
        // Set notifier to hide.
        [notifier hideIn:2.0];
        // set data
        [self setRepositories:[JSON objectForKey:@"repositories"]];
        // load dat table
        [[self tableView] reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error: %@", error);
        DDLogError(@"Error loading repositores!");
        NSLog(@"JSON: %@", JSON);
        
        // Change notifier to error
        [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyX"]]];
        [notifier setTitle:@"Error"];
        // Make it go away
        [notifier hideIn:2.0];
    }];
    
    [operation start];
    
}

- (void)dismissMe:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self repositories] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    DMRepositoryTableViewCell *tableCellView = [[DMRepositoryTableViewCell alloc] init];
    [cell addSubview:[tableCellView createTableViewCellWithDictionary:[_repositories objectAtIndex:[indexPath row]]]];
    return cell;

}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 64.0f;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory buttonIconFactory];
    // create view to hold it all
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    // Create search box
    self.searchTextBox = [[UITextField alloc] initWithFrame:CGRectMake(20, 20, 192, 30)];
    [[self searchTextBox] setPlaceholder:@"Search..."];
    [[self searchTextBox] setReturnKeyType:UIReturnKeyGo];
    [[self searchTextBox] setAutocorrectionType:UITextAutocorrectionTypeNo];
    // create button to run search
    UIButton *runSearchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [runSearchButton setFrame:CGRectMake(224, 13, 88, 44)];
    [runSearchButton setTitle:@"Search" forState:UIControlStateNormal];
    [runSearchButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [runSearchButton setImage:[factory createImageForIcon:NIKFontAwesomeIconSearch] forState:UIControlStateNormal];
//    [runSearchButton setBackgroundColor:[UIColor grayColor]];
    [runSearchButton addTarget:self action:@selector(runSearch:) forControlEvents:UIControlEventAllTouchEvents];
    // add textbox and button to view
    [view addSubview:[self searchTextBox]];
    [view addSubview:runSearchButton];
    // give the view back
    return view;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    NSDictionary *selectedRepo = [[self repositories] objectAtIndex:[indexPath row]];

    DMRepositoryDetailViewController *viewController = [[DMRepositoryDetailViewController alloc] init];
    [viewController setModalPresentationStyle:UIModalPresentationCurrentContext];
    [viewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    NSLog(@"Full details - %@", [self fulldetails]);
    [viewController setOwnerName:[selectedRepo objectForKey:@"owner"]];
    [viewController setRepoName:[selectedRepo objectForKey:@"name"]];

    [[self navigationController] pushViewController:viewController animated:YES];

    }

@end
