//
//  DMRepositoryDetailViewController.m
//  aGHC
//
//  Created by Daniel Miedema on 4/19/13.
//  Copyright (c) 2013 Daniel Miedema. All rights reserved.
//

#import "DMRepositoryDetailViewController.h"
#import "DMRepositoryDetailTableViewController.h"
#import "DMRepositoryCommitsTableViewController.h"
#import <CoreGraphics/CoreGraphics.h>
#import "MMMarkdown.h"
#import "MF_Base64Additions.h"
#import "JSNotifier.h"
#import "DTCoreText.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"


@interface DMRepositoryDetailViewController ()
@property (nonatomic, strong) NSString *rawHTML;
@property (nonatomic, strong) JSNotifier *notifier;

#define stylestring @"<style>*{margin:0;padding:0;}body {font:13.34px helvetica,arial,freesans,clean,sans-serif;color:black;	line-height:1.4em;background-color: #F8F8F8;padding: 0.7em;}p {margin:1em 0;	line-height:1.5em;}table {	font-size:inherit;font:100%margin:1em;}table th{border-bottom:1px solid #bbb;padding:.2em 1em;}table td{border-bottom:1px solid #ddd;padding:.2em 1em;}input[type=text],input[type=password],input[type=image],textarea{font:99% helvetica,arial,freesans,sans-serif;}select,option{padding:0 .25em;}optgroup{margin-top:.5em;}pre,code{font:12px Monaco,'Courier New','DejaVu Sans Mono','Bitstream Vera Sans Mono',monospace;}pre {margin:1em 0;	font-size:12px;	background-color:#eee;border:1px solid #ddd;padding:5px;line-height:1.5em;color:#444;overflow:auto;-webkit-box-shadow:rgba(0,0,0,0.07) 0 1px 2px inset;-webkit-border-radius:3px;-moz-border-radius:3px;border-radius:3px;}pre code {padding:0;font-size:12px;background-color:#eee;border:none;}code {font-size:12px;background-color:#f8f8ff;color:#444;padding:0 .2em;border:1px solid #dedede;}img{border:0;max-width:100%;}abbr{border-bottom:none;}a{color:#4183c4;text-decoration:none;}a:hover{text-decoration:underline;}a code,a:link code,a:visited code{color:#4183c4;}h2,h3{margin:1em 0;}h1,h2,h3,h4,h5,h6{border:0;}h1{font-size:170%;border-top:4px solid #aaa;padding-top:.5em;margin-top:1.5em;}h1:first-child{margin-top:0;padding-top:.25em;border-top:none;}h2{font-size:150%;margin-top:1.5em;border-top:4px solid #e0e0e0;padding-top:.5em;}h3{margin-top:1em;}hr{border:1px solid #ddd;}ul{margin:1em 0 1em 2em;}ol{margin:1em 0 1em 2em;}ul li,ol li{margin-top:.5em;margin-bottom:.5em;}ul ul,ul ol,ol ol,ol ul{margin-top:0;margin-bottom:0;}blockquote{margin:1em 0;border-left:5px solid #ddd;padding-left:.6em;color:#555;}dt{font-weight:bold;margin-left:1em;}dd{margin-left:2em;margin-bottom:1em;}@media screen and (min-width: 768px) {body {width: 748px;margin:10px auto;}}</style>"


@end

@implementation DMRepositoryDetailViewController

#define LABEL_WIDTH  280
#define LABEL_HEIGHT 54

#define BUTTON_WIDTH  73
#define BUTTON_HEIGHT 44

#define PADDING 10

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self navigationController] setTitle:@"Details"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setLabelInformation) name:@"aGHC-RepoDetailsLoaded" object:nil];

    if (![self repo] && [self repoName] && [self ownerName]) {
        // perform operation to get shit
        NSLog(@"no repo, repoName and ownerName");
        NSString *token     = [[NSUserDefaults standardUserDefaults] objectForKey:kAccessToken];
        NSString *tokenType = [[NSUserDefaults standardUserDefaults] objectForKey:kTokenType];
        NSString *requestString;
        
        // repos/:user/:repo
        if (token && tokenType) requestString = [NSString stringWithFormat:@"%@repos/%@/%@?%@=%@&%@=%@", kGitHubApiURL, [self ownerName], [self repoName], kAccessToken, token, kTokenType, tokenType];
        else requestString = [NSString stringWithFormat:@"%@repos/%@/%@", kGitHubApiURL, [self ownerName], [self repoName]];
         
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
        [request setValue:kResourceContentTypeDefault forHTTPHeaderField:@"Accept"];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            [self setRepo:JSON];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"aGHC-RepoDetailsLoaded" object:self];
            NSLog(@"Operation to get information run");
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"Failure to load details - %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:^{
                    NSLog(@"Error loading details, Dismissed view controller");
                }];
            });
        }];
        [operation start];
    } else
        [self setLabelInformation];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setLabelInformation {
    // create icon factory
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory buttonIconFactory];

    NSLog(@"\n\nInformation to load: %@", [self repo]);
    NSDictionary *owner = [[self repo] objectForKey:@"owner"];
    // Custom initialization
    // create scroll view
    float x = 20.0;
    float y = 0.0;
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    UIFont *defaultFont = [UIFont fontWithName:kFontName size:20.0];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, y, 320, 320)];
    [imageView setFrame:CGRectMake(0, y, 320, 320)];
    [imageView setImageWithURL:[NSURL URLWithString:[owner objectForKey:@"avatar_url"]] placeholderImage:[UIImage imageNamed:@"gravatar-user-420"]];
    //    [imageView setImage:[UIImage imageNamed:@"sL7cyZ5Oa7-2-1"]];

    // currently 320 down after image
    y+=320;
    NSLog(@"%f", y);
    
    // set up repository name label
    UILabel *repositoryNameLabel = [[UILabel alloc] init];
    // set it a glow
    [[repositoryNameLabel layer] setShadowColor:[[UIColor blackColor] CGColor]];
    [[repositoryNameLabel layer] setShadowRadius:1.0f];
    [[repositoryNameLabel layer] setShadowOpacity:1];
    [[repositoryNameLabel layer] setShadowOffset:CGSizeZero];
    [[repositoryNameLabel layer] setMasksToBounds:NO];
    // set it up
    [repositoryNameLabel setFont:[UIFont fontWithName:kFontName size:32.0]];
    [repositoryNameLabel setAdjustsFontSizeToFitWidth:YES];
    [repositoryNameLabel setMinimumScaleFactor:.1];
    [repositoryNameLabel setNumberOfLines:1];
    [repositoryNameLabel setAdjustsFontSizeToFitWidth:YES];
    [repositoryNameLabel setText:[[self repo] objectForKey:@"name"]];
    [repositoryNameLabel setBackgroundColor:[UIColor clearColor]];
    [repositoryNameLabel setTextColor:[UIColor whiteColor]];
    [repositoryNameLabel setFrame:CGRectMake((self.view.frame.size.width / 2)-45, 220, LABEL_WIDTH-75, LABEL_HEIGHT)];
    NSLog(@"%f", y);
    
    // set up description label
    UILabel *descriptionLabel = [[UILabel alloc] init];
    [descriptionLabel setFont:defaultFont];
    [descriptionLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel setBackgroundColor:[UIColor clearColor]];
    [descriptionLabel setTextColor:[UIColor darkGrayColor]];
    NSString *descrption = [[self repo] objectForKey:@"description"];
    if ((NSNull *)descrption == [NSNull null]) descrption = @"";
    CGSize constraintSize = CGSizeMake(LABEL_WIDTH, MAXFLOAT);
    CGSize labelSize = [descrption sizeWithFont:defaultFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    [descriptionLabel setFrame:CGRectMake(x, y, labelSize.width, labelSize.height)];
    [descriptionLabel setText:descrption];
    //
    y += labelSize.height;
    NSLog(@"%f", y);
    // set up username label
    
    UILabel *usernameLabel = [[UILabel alloc] init];
    [usernameLabel setFont:defaultFont];
    if ([[[self repo] objectForKey:@"fork"] integerValue] == NO)
        [usernameLabel setText:[NSString stringWithFormat:@"Created by - %@", [owner objectForKey:@"login"]]];
    else [usernameLabel setText:[NSString stringWithFormat:@"Forked by - %@", [owner objectForKey:@"login"]]];
    [usernameLabel setBackgroundColor:[UIColor clearColor]];
    [usernameLabel setFrame:CGRectMake(x, y, LABEL_WIDTH, LABEL_HEIGHT)];
    //
    y += LABEL_HEIGHT;
    NSLog(@"%f", y);
    // set up forks button
    UIButton *forksButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [forksButton setTitle:@"Fork" forState:UIControlStateNormal];
    [forksButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [forksButton setImage:[factory createImageForIcon:NIKFontAwesomeIconCodeFork] forState:UIControlStateNormal];
    [forksButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [forksButton setFrame:CGRectMake(x+10, y, BUTTON_WIDTH, BUTTON_HEIGHT)];
    // Set up watch button
    UIButton *watchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [watchButton setTitle:@"Watch" forState:UIControlStateNormal];
    [watchButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [watchButton setImage:[factory createImageForIcon:NIKFontAwesomeIconEyeOpen] forState:UIControlStateNormal];
    [watchButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [watchButton setFrame:CGRectMake((x+(10*2.5)) + BUTTON_WIDTH, y, BUTTON_WIDTH+10, BUTTON_HEIGHT)];
    // set up star button
    UIButton *starButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [starButton setTitle:@"Star" forState:UIControlStateNormal];
    [starButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [starButton setImage:[factory createImageForIcon:NIKFontAwesomeIconStar] forState:UIControlStateNormal];
    [starButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [starButton setFrame:CGRectMake((x+(10*5)) + (BUTTON_WIDTH * 2), y, BUTTON_WIDTH, BUTTON_HEIGHT)];
/*
     Incase I want it again, image setting code
     [starButton setImage:[UIImage imageNamed:@"StarButtonNormal"] forState:UIControlStateNormal];
     [starButton setImage:[UIImage imageNamed:@"StarButtonHighlighted"] forState:UIControlStateHighlighted];
     //    [starButton setImage:[UIImage imageNamed:@"SmallButtonNormal"] forState:UIControlStateNormal];
     //    [starButton setImage:[UIImage imageNamed:@"SmallButtonHighlighted"] forState:UIControlStateHighlighted];
*/
    // increase y, again.
    y += BUTTON_HEIGHT;
    NSLog(@"%f", y);
    // set up labels below buttons
    UILabel *forksLabel = [[UILabel alloc] init];
    [forksLabel setFont:defaultFont];
    [forksLabel setText:[NSString stringWithFormat:@"Forks - %@",[[self repo] objectForKey:@"forks_count"]]];
    [forksLabel setBackgroundColor:[UIColor clearColor]];
    [forksLabel setFrame:CGRectMake(x, y, LABEL_WIDTH/2, LABEL_HEIGHT)];
    // set up watchers label below buttons
    UILabel *watchersLabel = [[UILabel alloc] init];
    [watchersLabel setFont:defaultFont];
    [watchersLabel setText:[NSString stringWithFormat:@"Watchers - %@", [[self repo] objectForKey:@"watchers_count"]]];
    [watchersLabel setBackgroundColor:[UIColor clearColor]];
    [watchersLabel setFrame:CGRectMake((LABEL_WIDTH+x) / 2, y, LABEL_WIDTH/2, LABEL_HEIGHT)];
    //
    y += LABEL_HEIGHT;
    NSLog(@"%f", y);
    // issues label
    UILabel *issuesLabel = [[UILabel alloc] init];
    [issuesLabel setFont:defaultFont];
    [issuesLabel setText:[NSString stringWithFormat:@"Open Issues - %@",[[self repo] objectForKey:@"open_issues_count"]]];
    [issuesLabel setBackgroundColor:[UIColor clearColor]];
    [issuesLabel setFrame:CGRectMake(x, y, LABEL_WIDTH, LABEL_HEIGHT)];
    //
    y += LABEL_HEIGHT;
    NSLog(@"%f", y);
    // explore code button
    UIButton *exploreCode = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [exploreCode setTitle:@"Explore Code" forState:UIControlStateNormal];
    [exploreCode setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [exploreCode setImage:[factory createImageForIcon:NIKFontAwesomeIconCode] forState:UIControlStateNormal];
//    [exploreCode setImage:[UIImage imageNamed:@"ExploreCodeNormal"] forState:UIControlStateNormal];
//    [exploreCode setImage:[UIImage imageNamed:@"ExploreCodeHighlighted"] forState:UIControlStateHighlighted];
    [exploreCode addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [exploreCode setFrame:CGRectMake(x, y, LABEL_WIDTH, BUTTON_HEIGHT)];
    y += BUTTON_HEIGHT + PADDING;
    NSLog(@"%f", y);
    // check out commits button
    UIButton *checkCommits = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [checkCommits setTitle:@"Check Commits" forState:UIControlStateNormal];
    [checkCommits setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [checkCommits setImage:[factory createImageForIcon:NIKFontAwesomeIconComment] forState:UIControlStateNormal];
//    [checkCommits setImage:[UIImage imageNamed:@"CheckCommitsNormal"] forState:UIControlStateNormal];
//    [checkCommits setImage:[UIImage imageNamed:@"CheckCommitsHighlighted"] forState:UIControlStateHighlighted];
    [checkCommits addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [checkCommits setFrame:CGRectMake(x, y, LABEL_WIDTH, BUTTON_HEIGHT)];
    y += BUTTON_HEIGHT + PADDING;
    
    // create readme markdown view
    UIWebView *readmeView = [[UIWebView alloc] init];
    // Accept Header
    // application/vnd.github.v3.html+json
    // on https://api.github.com/repos/dmiedema/dropboxcollection/readme
    // or kGitHubApiURL /repos/:user/:repo/readme
    // and render output to webview
    NSString *requestString;
    NSString *token     = [[NSUserDefaults standardUserDefaults] objectForKey:kAccessToken];
    NSString *tokenType = [[NSUserDefaults standardUserDefaults] objectForKey:kTokenType];
    NSString *login     = [owner objectForKey:@"login"];
    NSString *reponame  = [[self repo] objectForKey:@"name"];
    
    if (token && tokenType)
        requestString = [NSString stringWithFormat:@"%@repos/%@/%@/readme?%@=%@&%@=%@", kGitHubApiURL, login, reponame, kAccessToken, token, kTokenType, tokenType];
    else
        requestString = [NSString stringWithFormat:@"%@repos/%@/%@/readme", kGitHubApiURL, login, reponame];

        
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    NSLog(@"Request - %@", request);
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"Response -- %@", JSON);
        NSLog(@"Content - %@", [JSON objectForKey:@"content"]);
        NSLog(@"Decoded - %@", [NSString stringFromBase64String:[JSON objectForKey:@"content"]]);
        [self setRawHTML:[NSString stringWithFormat:@"%@%@", stylestring, [NSString stringFromBase64String:[JSON objectForKey:@"content"]]]];
        
        NSLog(@"HTML - %@", [MMMarkdown HTMLStringWithMarkdown:[NSString stringFromBase64String:[JSON objectForKey:@"content"]] error:nil]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [readmeView loadHTMLString:[MMMarkdown HTMLStringWithMarkdown:[self rawHTML] error:nil] baseURL:nil];
        });
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"HTML -- %@", JSON);
        NSLog(@"Error - %@", error);
        NSLog(@"Error loading README");
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        [operation start];
    });
    
    [readmeView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
    
    [readmeView setFrame:CGRectMake(0, y, self.view.frame.size.width, [[readmeView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"] floatValue])];
    [readmeView sizeToFit];
    y += readmeView.frame.size.height;
    
    // add subviews to scroll view. And there are a lot of them holy fuck.
    [scrollView addSubview:imageView];
    [scrollView addSubview:repositoryNameLabel];
    [scrollView addSubview:descriptionLabel];
    [scrollView addSubview:usernameLabel];
    [scrollView addSubview:forksButton];
    [scrollView addSubview:watchButton];
    [scrollView addSubview:starButton];
    [scrollView addSubview:forksLabel];
    [scrollView addSubview:watchersLabel];
    [scrollView addSubview:issuesLabel];
    [scrollView addSubview:exploreCode];
    [scrollView addSubview:checkCommits];
    [scrollView addSubview:readmeView];
    
    // add the scroll view into the view
    [scrollView setContentSize:CGSizeMake(self.view.frame.size.width, y)];
    [scrollView setBackgroundColor:[UIColor whiteColor]];
    [[self view] addSubview:scrollView];
    [[self view] setNeedsDisplay];
}

- (void)buttonPressed:(UIButton *)sender {
    NSLog(@"sender: %@", [[sender titleLabel] text]);
    // create activity indicator
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    // create JSNotifier
    JSNotifier *notifier = [[JSNotifier alloc] initWithTitle:[NSString stringWithFormat:@"%@ing", [[sender titleLabel] text]]];
    // set accessory view
    [notifier setAccessoryView:activityIndicator];
    [notifier show];
    // animate and show once i need to
    
    NSDictionary *owner = [[self repo] objectForKey:@"owner"];
    NSString *token     = [[NSUserDefaults standardUserDefaults] objectForKey:kAccessToken];
    NSString *tokenType = [[NSUserDefaults standardUserDefaults] objectForKey:kTokenType];
    NSString *ownername = [owner objectForKey:@"login"];
    NSString *reponame  = [[self repo] objectForKey:@"name"];
    
    if ([[[sender titleLabel] text] isEqualToString:@"X"] || [[[sender titleLabel] text] isEqualToString:@":("]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if ([[[sender titleLabel] text] isEqualToString:@"Fork"]) {
        [activityIndicator startAnimating];
        [notifier show];
        //POST /repos/:owner/:repo/forks
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@repos/%@/%@/forks?%@=%@&%@=%@", kGitHubApiURL, ownername, reponame, kAccessToken, token, kTokenType, tokenType]]];
        [request setHTTPMethod:@"POST"];
//        [request setValue:token forHTTPHeaderField:kAccessToken];
//        [request setValue:tokenType forHTTPHeaderField:tokenType];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck"]]];
                [notifier setTitle:@"Forked" animated:YES];
                [notifier hideIn:2.0];
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error Forking - %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyX"]]];
                [notifier setTitle:@"Error" animated:YES];
                [notifier hideIn:2.0];
            });
        }];
        [operation start];
        
    } else if ([[[sender titleLabel] text] isEqualToString:@"Watch"]) {
        [activityIndicator startAnimating];
        [notifier show];
        // PUT /repos/:owner/:repo/subscription
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@repos/%@/%@/subscription?%@=%@&%@=%@", kGitHubApiURL, ownername, reponame, kAccessToken, token, kTokenType, tokenType]]];
        [request setHTTPMethod:@"PUT"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        NSString *jsonInput = @"{\"subscribed\" : true, \"ignored\" : false }";
        [request setHTTPBody:[jsonInput dataUsingEncoding:NSUTF8StringEncoding]];
//        [request setValue:token forHTTPHeaderField:kAccessToken];
//        [request setValue:tokenType forHTTPHeaderField:tokenType];
        NSLog(@"request string -- %@", [request URL]);
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck"]]];
                [notifier setTitle:@"Watched" animated:YES];
                [notifier hideIn:2.0];
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error Watching - %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyX"]]];
                [notifier setTitle:@"Error" animated:YES];
                [notifier hideIn:2.0];
            });
        }];
        [operation start];
    } else if ([[[sender titleLabel] text] isEqualToString:@"Star"]) {
        [activityIndicator startAnimating];
        [notifier show];
        // PUT /user/starred/:owner/:repo
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@user/starred/%@/%@?%@=%@&%@=%@", kGitHubApiURL, ownername, reponame, kAccessToken, token, kTokenType, tokenType]]];
        [request setHTTPMethod:@"PUT"];
        
//        [request setValue:token forHTTPHeaderField:kAccessToken];
//        [request setValue:tokenType forHTTPHeaderField:tokenType];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck"]]];
                [notifier setTitle:@"Starred" animated:YES];
                [notifier hideIn:2.0];
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error Staring - %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyX"]]];
                [notifier setTitle:@"Error" animated:YES];
                [notifier hideIn:2.0];
            });
        }];
        [operation start];
    } else if ([[[sender titleLabel] text] isEqualToString:@"Explore Code"]) {
        [notifier setTitle:@"Exploring Code"];
        // Code View.
        //        /repos/:owner/:repo/contents/:path
        NSString *baseURL = [NSString stringWithFormat:@"%@repos/%@/%@/contents/", kGitHubApiURL, ownername, reponame];
        NSString *requestURL;
        if( [[NSUserDefaults standardUserDefaults] objectForKey:kAccessToken])
//            NSString *requestURL = [NSString stringb][NSString stringWithFormat:@"%@repos/%@/%@/contents"]
            requestURL = [NSString stringWithFormat:@"%@?%@=%@&%@=%@", baseURL, kAccessToken, token, kTokenType, tokenType];
        else requestURL = baseURL;
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            NSLog(@"JSON : %@", JSON);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showTheCode:JSON];
                [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck"]]];
                [notifier setTitle:@"Loaded" animated:YES];
                [notifier hideIn:2.0];
            });
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"Error : %@", error);
            [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyX"]]];
            [notifier setTitle:@"Error" animated:YES];
            [notifier hideIn:2.0];
        }];
        [operation start];
    } else if ([[[sender titleLabel] text] isEqualToString:@"Check Commits"]) {
        [notifier setTitle:@"Checking Commits"];
        // GET /repos/:owner/:repo/commits
        NSString *baseURL = [NSString stringWithFormat:@"%@repos/%@/%@/commits", kGitHubApiURL, ownername, reponame];
        NSString *requestURL;
        if (token && tokenType) 
            requestURL = [NSString stringWithFormat:@"%@?%@=%@&%@=%@", baseURL, kAccessToken, token, kTokenType, tokenType];
        else requestURL = baseURL;
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showTheCommits:JSON];
                [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck"]]];
                [notifier setTitle:@"Loaded" animated:YES];
                [notifier hideIn:2.0];
            });
            NSLog(@"JSON : %@", JSON);
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"Error : %@", error);
            [notifier setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyX"]]];
            [notifier setTitle:@"Error" animated:YES];
            [notifier hideIn:2.0];
        }];
        [operation start];
    } else {
        NSLog(@"Unknown button pressed");
    }
}

- (void) showTheCode:(NSArray *)jsonArray {
    DMRepositoryDetailTableViewController *tableView = [[DMRepositoryDetailTableViewController alloc] init];
    [tableView setCurrentPath:@"/"];
    [tableView setTitle:@"/"];
    [tableView setDirectoryContents:jsonArray];
    [tableView setReponame:[[self repo] objectForKey:@"name"]];
    [tableView setOwner:[[self repo] objectForKey:@"owner"]];
    [[self navigationController] pushViewController:tableView animated:YES];
}

- (void)showTheCommits:(NSArray *)commits {
    DMRepositoryCommitsTableViewController *commitsTableView = [[DMRepositoryCommitsTableViewController alloc] init];
    [commitsTableView setTitle:@"Commits"];
    [commitsTableView setCommits:commits];
    [[self navigationController] pushViewController:commitsTableView animated:YES];
}

@end
