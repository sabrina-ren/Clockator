//
//  CKLoginViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 11/25/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "CKLoginViewController.h"
#import "CKClockViewController.h"
#import "Reachability.h"
#import "UIColor+CKColours.h"
#import <Parse/Parse.h>

@interface CKLoginViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *blurredBackground;

@property (nonatomic) UILabel *clockatorLabel;
@property (nonatomic) UIButton *loginButton;
@property (nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation CKLoginViewController
@synthesize blurredBackground, loginButton, activityIndicator;
@synthesize clockatorLabel;

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
    
    CGFloat labelWidth = 140;
    CGFloat labelOriginY = self.view.center.y/2;
    clockatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.center.x - labelWidth/2, labelOriginY, labelWidth, 42)];
    [clockatorLabel setFont:[UIFont fontWithName:@"DistrictPro-Thin" size:24]];
    [clockatorLabel setTextColor:[UIColor whiteColor]];
    [clockatorLabel setText:@"CLOCKATOR"];
    clockatorLabel.alpha = 0;
    [self.view addSubview:clockatorLabel];

    loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loginButton setTitle:@"Log in with Facebook" forState:UIControlStateNormal];
    [loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [loginButton setBackgroundColor:[UIColor customTransparentSalmon]];
    [loginButton addTarget:self action:@selector(loginButtonTouchHandler:) forControlEvents:UIControlEventTouchUpInside];
    CGFloat buttonWidth = 220;
    CGFloat buttonHeight = 42;
    loginButton.frame = CGRectMake(self.view.center.x - buttonWidth/2, self.view.center.y - buttonHeight, buttonWidth, 42);
    loginButton.alpha = 0;
    [self.view addSubview:loginButton];
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicator.center = CGPointMake(self.view.center.x, self.view.center.y + self.view.center.y/2 - buttonHeight - activityIndicator.frame.size.height);
    activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicator];
    
    blurredBackground.alpha = 0;
    [UIView animateWithDuration:1.2 animations:^{
        blurredBackground.alpha = 1;
        clockatorLabel.alpha = 1;
        loginButton.alpha = 1;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loginButtonTouchHandler:(id)sender {
    if (self.isReachable) {
        [activityIndicator startAnimating];
        
        // Permissions requested
        NSArray *permissionsArray = @[@"user_about_me",@"user_relationships"];
        
        // Login PFUser with Facebook
        [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error){
            if (!user) {
                if (!error) {
                    NSLog(@"User cancelled Facebook login");
                } else {
                    NSLog(@"Error occured: %@", error);
                }
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error logging in" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                [activityIndicator stopAnimating];
            }
            else {
                NSLog(@"User with Facebook is new: %i", user.isNew);
                [self.delegate didLoginUserIsNew:user.isNew];
            }
        }];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)displayUserInfo:(NSData *)imageData forUser:(NSString *)name {
    // Called by delegate
    
    [activityIndicator stopAnimating];
    
    [loginButton setTitle:name forState:UIControlStateNormal];
    [loginButton setBackgroundColor:[UIColor customTransparentBlack]];
    
    UIImage *profile = [UIImage imageWithData:imageData];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:profile];
    CGFloat radius = 35;
    [imageView setFrame:CGRectMake(self.view.center.x - radius, activityIndicator.frame.origin.y, radius*2, radius*2)];
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = radius;
    [self.view addSubview:imageView];
    [self removeUserInfo:imageView];
}

- (void)removeUserInfo:(UIImageView *)imageView {
    CGPoint offscreen = CGPointMake(self.view.center.x, self.view.frame.size.height);
    [UIView animateWithDuration:1 delay:1 options:
     UIViewAnimationCurveEaseOut
                     animations:^{
                         clockatorLabel.center = offscreen;
                         loginButton.center = offscreen;
                         imageView.center = offscreen;
                         
                         clockatorLabel.alpha = 0;
                         loginButton.alpha = 0;
                         imageView.alpha = 0;
                         
                     } completion:^(BOOL finished) {
                     }];
    [self displayIntro];
}

- (void)displayIntro {
    CGFloat hPadding = 25;
    CGFloat vPadding = 40;
    
    // Transparent black background view
    CGFloat width = self.view.frame.size.width - hPadding*2;
    CGFloat height = self.view.frame.size.height - vPadding * 3;
    UIView *introView = [[UIView alloc] initWithFrame:CGRectMake(hPadding, -340, width, height)];
    introView.backgroundColor = [UIColor customTransparentBlack];
    introView.alpha = 0;
    [self.view addSubview:introView];
    
    // Labels
    NSArray *labelText = @[@"See friends' locations on clock", @"Add places to share", @"If you're at a saved place, your location is updated"];
    CGFloat labelHeight = 56;
    CGFloat space = introView.frame.size.height/labelText.count - labelHeight/labelText.count;

    for (int i=0; i<labelText.count; i++) {
        CGFloat originY = space*i + (i+1 == labelText.count)*8;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, originY, width, labelHeight)];
        label.text = labelText[i];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        [introView addSubview:label];
    }
    
    // Icons
    NSArray *iconNames = @[@"Clock", @"Globe", @"Marker"];
    NSMutableArray *icons = [NSMutableArray arrayWithCapacity:iconNames.count];
    CGFloat iconSize = 45;
    CGFloat originX = introView.frame.size.width/2 - iconSize/2;
    
    for (int i=0; i<iconNames.count; i++) {
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconNames[i]]];
        [iconView setContentMode:UIViewContentModeScaleAspectFit];
        
        iconView.frame = CGRectMake(originX, -iconSize, iconSize, iconSize);
        [introView addSubview:iconView];
        [icons addObject:iconView];
    }
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [doneButton setTitle:@"OK" forState:UIControlStateNormal];
    [doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    doneButton.backgroundColor = [UIColor customTransparentSalmon];
    [doneButton addTarget:self action:@selector(doneButtonActionHandler:) forControlEvents:UIControlEventTouchUpInside];
    CGFloat buttonWidth = 85;
    CGFloat buttonHeight = 44;
    [doneButton setFrame:CGRectMake(self.view.frame.size.width-hPadding-buttonWidth,-buttonHeight, buttonWidth, buttonHeight)];
    doneButton.alpha = 0;
    [self.view addSubview:doneButton];

    [UIView animateWithDuration:1 delay:1.2
                        options:UIViewAnimationCurveEaseIn
                     animations:^{
                         for (int i=0; i<icons.count; i++) {
                             CGFloat originY = space*i + labelHeight + (space-labelHeight)/2 + (i+1 == icons.count)*20;
                             [icons[i] setCenter:CGPointMake(((UIView *)icons[i]).center.x, originY)];
                         }
                         introView.alpha = 1;
                         introView.center = CGPointMake(introView.center.x, self.view.center.y - vPadding/2);
                         
                         doneButton.alpha = 1;
                         doneButton.center = CGPointMake(doneButton.center.x, self.view.frame.size.height - vPadding);
                     } completion:^(BOOL finished) {
                     }];
}

- (void)doneButtonActionHandler:(id)sender {
    [self.delegate shouldDismissLoginController];
}

@end
