//
//  DMRepositoryDetailViewController.m
//  aGHC
//
//  Created by Daniel Miedema on 4/19/13.
//  Copyright (c) 2013 Daniel Miedema. All rights reserved.
//

#import "DMRepositoryDetailViewController.h"

@interface DMRepositoryDetailViewController ()

//@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *repositoryNameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *description;
@property (nonatomic, strong) UILabel *forksLabel;
@property (nonatomic, strong) UILabel *starsLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UILabel *issuesLabel;

@property (nonatomic, strong) UIButton *forkButton;
@property (nonatomic, strong) UIButton *watchButton;
@property (nonatomic, strong) UIButton *starButton;
@property (nonatomic, strong) UIButton *exploreCodeButton;

@end

@implementation DMRepositoryDetailViewController

#define LABEL_WIDTH  280
#define LABEL_HEIGHT 54

#define BUTTON_WIDTH  73
#define BUTTON_HEIGHT 44

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
	// Do any additional setup after loading the view.
    // TODO: Add a dismissal button/titlebar thing.
    NSLog(@"\n\nInformation to load: %@", [self repo]);
    // Custom initialization
    // create scroll view
    float x = 20.0;
    float y = 0.0;
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    UIFont *defaultFont = [UIFont fontWithName:@"Avenir" size:20.0];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, y, 320, 320)];
    [imageView setImage:[UIImage imageNamed:@"sL7cyZ5Oa7-2-1"]];
    // currently 320 down after image
    y+=320;
    NSLog(@"%f", y);
    // set up repository name label
    UILabel *repositoryNameLabel = [[UILabel alloc] init];
    [repositoryNameLabel setFont:defaultFont];
    [repositoryNameLabel setText:[[self repo] objectForKey:@"name"]];
    [repositoryNameLabel setBackgroundColor:[UIColor clearColor]];
    [repositoryNameLabel setFrame:CGRectMake((self.view.frame.size.width / 2), 290, LABEL_WIDTH, LABEL_HEIGHT)];
    // set up description label
    UILabel *descriptionLabel = [[UILabel alloc] init];
    [descriptionLabel setFont:defaultFont];
    [descriptionLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel setBackgroundColor:[UIColor clearColor]];
    [descriptionLabel setTextColor:[UIColor darkGrayColor]];
    NSString *descrption = [[self repo] objectForKey:@"description"];
    CGSize constraintSize = CGSizeMake(LABEL_WIDTH, MAXFLOAT);
    CGSize labelSize = [descrption sizeWithFont:defaultFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    [descriptionLabel setFrame:CGRectMake(x, y, labelSize.width, labelSize.height)];
    [descriptionLabel setText:descrption];
    //
    y += labelSize.height;
    NSLog(@"%f", y);
    // set up username label
    NSDictionary *owner = [[self repo] objectForKey:@"owner"];
    UILabel *usernameLabel = [[UILabel alloc] init];
    [usernameLabel setFont:defaultFont];
    [usernameLabel setText:[NSString stringWithFormat:@"Creator - %@", [owner objectForKey:@"login"]]];
    [usernameLabel setBackgroundColor:[UIColor clearColor]];
    [usernameLabel setFrame:CGRectMake(x, y, LABEL_WIDTH, LABEL_HEIGHT)];
    //
    y += LABEL_HEIGHT;
    NSLog(@"%f", y);
    // set up forks button
    UIButton *forksButton = [[UIButton alloc] init];
    [forksButton setTitle:@"Fork" forState:UIControlStateNormal];
    [forksButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [forksButton setTitleColor:[UIColor blackColor] forState:UIControlStateApplication];
    [forksButton setFrame:CGRectMake(x, y, BUTTON_WIDTH, BUTTON_HEIGHT)];
    // Set up watch button
    UIButton *watchButton = [[UIButton alloc] init];
    [watchButton setTitle:@"Watch" forState:UIControlStateNormal];
    [watchButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [watchButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [watchButton setFrame:CGRectMake((x*2) + BUTTON_WIDTH, y, BUTTON_WIDTH, BUTTON_HEIGHT)];
    // set up star button
    UIButton *starButton = [[UIButton alloc] init];
    [starButton setTitle:@"Star" forState:UIControlStateNormal];
    [starButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [starButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [starButton setFrame:CGRectMake((x*4) + (BUTTON_WIDTH * 2), y, BUTTON_WIDTH, BUTTON_HEIGHT)];
    //
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
    UIButton *exploreCode = [[UIButton alloc] init];
    [exploreCode setTitle:@"Explore Code" forState:UIControlStateNormal];
    [exploreCode setTitleColor:[UIColor darkGrayColor] forState:UIControlStateApplication];
    [exploreCode addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [exploreCode setFrame:CGRectMake(x, y, LABEL_WIDTH, BUTTON_HEIGHT)];
    y += BUTTON_HEIGHT;
    NSLog(@"%f", y);
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
    
    // add the scroll view into the view
    [scrollView setContentSize:CGSizeMake(self.view.frame.size.width, y)];
    [scrollView setBackgroundColor:[UIColor redColor]];
    [[self view] addSubview:scrollView];
    
    NSLog(@"current y : %f", y);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)buttonPressed:(UIButton *)sender {
    NSLog(@"sender: %@", [[sender titleLabel] text]);
}
@end
