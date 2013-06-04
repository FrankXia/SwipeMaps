//
//  SwipeViewsViewController.h
//  SwipeMapViews
//
//  Created by Frank on 5/30/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface SwipeViewsViewController : UIViewController <UIGestureRecognizerDelegate>


@property (nonatomic, strong) IBOutlet AGSMapView *mainMapView;
@property (nonatomic, strong) IBOutlet AGSMapView *topMapView;
@property (nonatomic, strong) IBOutlet UIImageView *slider;

@end
