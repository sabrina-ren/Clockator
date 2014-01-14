//
//  CKAppConstants.m
//  Clockator
//
//  Created by Sabrina Ren on 1/2/2014.
//  Copyright (c) 2014 Sabrina Ren. All rights reserved.
//

#import "CKAppConstants.h"

#pragma mark - PFUser
NSString *const CKUserDisplayNameKey = @"displayName";
NSString *const CKUserFacebookKey = @"fbID";
NSString *const CKUserFriendsKey = @"friends";
NSString *const CKUserIconKey = @"iconIndex";
NSString *const CKUserLocationKey = @"location";
NSString *const CKUserObjectId = @"objectId";
NSString *const CKUserProfileKey = @"profilePicture";
NSString *const CKUserUpdateDateKey = @"updateDate";

#pragma  mark - PFObject FriendRequest class
NSString *const CKFriendReqClass = @"FriendRequest";
NSString *const CKFriendReqFromUserKey = @"fromUser";
NSString *const CKFriendReqToUserKey = @"toUser";
NSString *const CKFriendReqStatusKey = @"status";

#pragma mark - Notification Center
NSString *const CKNotificationShouldLogOut = @"logOutNotification"; // Observers: AppDelegate and ClockViewController

#pragma mark - NSUserDefaults
NSString *const CKUserPreferencesClockFace = @"clockFacePreferences";
NSString *const CKUserPreferencesFriendsIds = @"friendIds";