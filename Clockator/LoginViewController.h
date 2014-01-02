//
//  LoginViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 11/25/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoginControllerDelegate <NSObject>
- (void)didLoginUserIsNew:(BOOL)isNew;
@end

@interface LoginViewController : UIViewController

@property (nonatomic, weak) id <LoginControllerDelegate> delegate;

@end
