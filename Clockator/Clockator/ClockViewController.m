//
//  ViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "ClockViewController.h"

@interface ClockViewController ()

@end

@implementation ClockViewController
@synthesize locations, friends, friendsAtLocation, hands;

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setFont:[UIFont fontWithName:@"ChannelSlanted1" size:20]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Clockator"];
    self.navigationItem.titleView = titleLabel;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
//    CGFloat screenHeight = screenRect.size.height;
    NSLog(@"%f",screenWidth);
    

    friends = appDelegate.friends;
    locations = appDelegate.locations;
    friendsAtLocation = appDelegate.friendsAtLocation;
    
    double angle = 2*M_PI/locations.count;
    
    for (int i=0; i<locations.count; i++) {
        CGFloat locRadius = 140;
        CGFloat x = 140 + locRadius*cos(angle*i + M_PI/2);
        CGFloat y = 270 - locRadius*sin(angle*i + M_PI/2);
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x,y,2,40)];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[locations objectAtIndex:i] iconPicture]];
        [imageView setFrame:CGRectMake(0, 0, 40, 30)];
        [view addSubview:imageView];
        [[self view] addSubview:view];
        
        
        if ([friendsAtLocation[i] count]==1) {
            CGFloat radius = 90;
            x = 140 + radius*cos(angle*i + M_PI/2);
            y = 270 - radius*sin(angle*i + M_PI/2);
            
            UIImageView *newHand = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"hand.png"]];
            [newHand setFrame:CGRectMake(52, 285, 217, 10)];
            [hands addObject:newHand];
            [[self view] addSubview:newHand];
            [self.view sendSubviewToBack:newHand];
            
            CABasicAnimation *rotationAnimation;
            rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            rotationAnimation.toValue = [NSNumber numberWithFloat:angle*(-i)+M_PI/2+M_PI*3];
            rotationAnimation.duration = 1.5;
            rotationAnimation.cumulative = NO;
            rotationAnimation.fillMode = kCAFillModeForwards;
            rotationAnimation.removedOnCompletion = NO;
            [newHand.layer setAnchorPoint:CGPointMake(0.5,0.5)];
            [newHand.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
                        
            Friend *locatedFriend = [[Friend alloc] init];
            locatedFriend = [friendsAtLocation[i] objectAtIndex:0];
            UIView *friendView = [[UIView alloc] initWithFrame:CGRectMake(x,y,2,40)];
            UIImageView *friendImage = [[UIImageView alloc] initWithImage:locatedFriend.picture];
            [friendImage setFrame:CGRectMake(0,0,45,45)];
            [friendView addSubview:friendImage];
            [[self view] addSubview:friendView];
        }
        
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
