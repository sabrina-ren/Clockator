//
//  PlaceIconViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlaceIconViewController;

@protocol PlaceIconControllerDelegate <NSObject>
- (void)placeIconController:(PlaceIconViewController *)controller didChangeIconIndex:(NSInteger)index;
@end

@interface PlaceIconViewController : UITableViewController

@property (nonatomic) NSMutableArray *clockPlaces;

@property BOOL isIconView;
@property NSInteger currentIconIndex;
@property (nonatomic, weak) id <PlaceIconControllerDelegate> delegate;

@end
