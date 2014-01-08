//
//  LoginViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 11/25/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Reachability;

@protocol LoginControllerDelegate <NSObject>
- (void)didLoginUserIsNew:(BOOL)isNew;
- (void)shouldDismissLoginController;
@end

@interface LoginViewController : UIViewController

@property BOOL isReachable;
@property (nonatomic, weak) id <LoginControllerDelegate> delegate;

- (void)displayUserInfo:(NSData *)imageData forUser:(NSString *)name;

@end
