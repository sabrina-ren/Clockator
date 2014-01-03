//
//  UserInfoViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 11/25/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "UserInfoViewController.h"
#import <Parse/Parse.h>

@interface UserInfoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (nonatomic, strong) NSMutableData *imageData;
- (IBAction)logoutButtonTouchHandler:(id)sender;
- (IBAction)nextButtonTouchHandler:(id)sender;
@end

@implementation UserInfoViewController
@synthesize userImageView, userNameLabel, imageData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.translucent = NO;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setFont:[UIFont fontWithName:@"ChannelSlanted1" size:20]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Clockator"];
    self.navigationItem.titleView = titleLabel;
    self.navigationItem.hidesBackButton = YES;
    
    // Create request for user's Facebook data
    FBRequest *request = [FBRequest requestForMe];

    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];
            NSString *name = userData[@"name"];
            
            [[PFUser currentUser] setObject:facebookID forKey:@"fbID"];
            [[PFUser currentUser] setObject:name forKey:@"displayName"];
            [[PFUser currentUser] saveInBackground];
            
            userNameLabel.text = name;
            imageData = [[NSMutableData alloc] init];
            
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:imageURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2.0f];
            // Run network request asynchronously
            NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
        } else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"The facebook session was invalidated");
            [self logoutButtonTouchHandler:nil];
        } else {
            NSLog(@"Some other error: %@", error);
        }
    }];
}

// Called everytime piece of data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [imageData appendData:data];
}

// Called when entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    // Set imageview
    userImageView.image = [UIImage imageWithData:imageData];
}

- (IBAction)logoutButtonTouchHandler:(id)sender {
    [PFUser logOut]; // Log out
    
    // Return to login page
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)nextButtonTouchHandler:(id)sender {
//    [self.navigationController popToRootViewControllerAnimated:NO];

    [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"ClockViewController"] animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
