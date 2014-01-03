//
//  LoginViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 11/25/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "LoginViewController.h"
#import "ClockViewController.h"
#import <Parse/Parse.h>

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)loginButtonTouchHandler:(id)sender;
@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check if user is cached and linked to Facebook, if so, bypass login
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        NSLog(@"skipping to clock view controller");
        [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"UserInfoViewController"] animated:NO];
    }
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setFont:[UIFont fontWithName:@"ChannelSlanted1" size:20]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Clockator"];
    self.navigationItem.titleView = titleLabel;

    
    _activityIndicator.hidesWhenStopped = YES;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonTouchHandler:(id)sender {
    [_activityIndicator startAnimating];
    // Permissions requested
    NSArray *permissionsArray = @[@"user_about_me",@"user_relationships"];
    
    // Login PFUser with Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error){
        [_activityIndicator stopAnimating];
        
        if (!user) {
            if (!error) {
                NSLog(@"User cancelled Facebook login");
            } else {
                NSLog(@"Error occured: %@", error);
            }
        } else if (user.isNew) {
            NSLog(@"User with Facebook signed up and logged in!");
            [self.delegate didLoginUserIsNew:YES];
        } else {
            NSLog(@"User with Facebook logged in!");
            [self.delegate didLoginUserIsNew:NO];
        }
        
    }];
}
@end
