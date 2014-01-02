//
//  AppDelegate.h
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "LoginViewController.h"
#import <UIKit/UIKit.h>
#import <sqlite3.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLConnectionDelegate, LoginControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
