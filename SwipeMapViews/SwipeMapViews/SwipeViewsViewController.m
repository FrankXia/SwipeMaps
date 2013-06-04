//
//  SwipeViewsViewController.m
//  SwipeMapViews
//
//  Created by Frank on 5/30/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "SwipeViewsViewController.h"

#define kWorldStreetMap @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
#define kWorldTopoMap @"http://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
#define kWorldImageryMap @"http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"

#define kMooreAfterImgery @"http://tiles1.arcgis.com/tiles/DO4gTjwJVIJ7O9Ca/arcgis/rest/services/MooreTornado1/MapServer"

@interface SwipeViewsViewController ()

@property (nonatomic) BOOL startFromMainMap;
@property (nonatomic) BOOL startFromTopMap;

@end

@implementation SwipeViewsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSURL *mapUrl = [NSURL URLWithString:kWorldImageryMap];
    AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
    [self.mainMapView addMapLayer:tiledLyr withName:@"Bottom Map Layer"];
    CGRect frame = self.mainMapView.frame;
    NSLog(@"x=%f. y=%f", frame.origin.x, frame.origin.y);
    
    mapUrl = [NSURL URLWithString:kMooreAfterImgery];
    tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
    [self.topMapView addMapLayer:tiledLyr withName:@"Top Map Layer"];

    AGSMutableEnvelope *initialExtent = [AGSMutableEnvelope envelopeWithXmin:-1.0874972654227614E7 ymin:4197204.221307395 xmax:-1.0837521428820089E7 ymax:4219032.935544925 spatialReference:self.topMapView.visibleAreaEnvelope.spatialReference];
    
    //[-97.5241, 35.3198],[-97.5171, 35.3228]
    initialExtent = [AGSMutableEnvelope envelopeWithXmin:-97.5241 ymin:35.3198 xmax:-97.5171 ymax:35.3228 spatialReference:[AGSSpatialReference spatialReferenceWithWKID:4326]];
    [self.mainMapView zoomToEnvelope:initialExtent animated:YES];
    
    // add observers for mapView notifications (pan/zoom)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainmapDidEndZooming:) name:AGSMapViewDidEndZoomingNotification object:self.mainMapView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainmapDidEndPanning:) name:AGSMapViewDidEndPanningNotification object:self.mainMapView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(topmapDidEndZooming:) name:AGSMapViewDidEndZoomingNotification object:self.topMapView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(topmapDidEndPanning:) name:AGSMapViewDidEndPanningNotification object:self.topMapView];
    
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGestureRecognizer.delegate = self;
    [self.slider addGestureRecognizer:panGestureRecognizer];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}



#pragma mark
#pragma mark UIGestureRecognizerDelegate
#pragma mark

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

-(void)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{   
    //NSLog(@"y=%f, x=%f, w=%f, h=%f",self.slider.frame.origin.y, self.slider.frame.origin.x, self.slider.frame.size.width, self.slider.frame.size.height);
    CGRect frame = self.topMapView.frame;;
    CGPoint translation = [recognizer translationInView:self.view];

    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,recognizer.view.center.y);
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    frame.origin.x += translation.x;

    self.startFromMainMap = YES;
    self.startFromTopMap = NO;
    self.topMapView.frame = frame;
    [self computeEnvelopeForMainMap];

}


#pragma mark MapPan/zoomed

-(void)mainmapDidEndPanning:(NSNotification *)notification {
    if (self.startFromTopMap) {
        self.startFromTopMap = NO;
        return;
    }
    self.startFromMainMap = YES;
    [self computeEnvelopeForMainMap];
}

-(void)mainmapDidEndZooming:(NSNotification *)notification {
    if (self.startFromTopMap) {
        self.startFromTopMap = NO;
        return;
    }
    self.startFromMainMap = YES;
    [self computeEnvelopeForMainMap];
}

-(void)topmapDidEndPanning:(NSNotification *)notification {
    if (self.startFromMainMap) {
        self.startFromMainMap = NO;
        return;
    }
    self.startFromTopMap = YES;
    [self computeEnvelopeForTopMap];
}

-(void)topmapDidEndZooming:(NSNotification *)notification {
    if (self.startFromMainMap) {
        self.startFromMainMap = NO;
        return;
    }
    self.startFromTopMap = YES;
    [self computeEnvelopeForTopMap];
}

-(void)computeEnvelopeForMainMap
{

    AGSEnvelope *mainEnvelope = [self.mainMapView.visibleArea envelope];
    AGSMutableEnvelope *newEnvelope = [AGSMutableEnvelope envelopeWithXmin:mainEnvelope.xmin ymin:mainEnvelope.ymin xmax:mainEnvelope.xmax ymax:mainEnvelope.ymax spatialReference:mainEnvelope.spatialReference];
    CGRect rect = [self.mainMapView toScreenRect:mainEnvelope];
    float factor = (float)(self.slider.frame.origin.x+12.5) / rect.size.width;
    [newEnvelope offsetByX:(mainEnvelope.xmax-mainEnvelope.xmin)*factor y:0.0];
    
    [self.topMapView zoomToEnvelope:newEnvelope animated:YES];
    
    NSLog(@"main map w=%f, h=%f, start from main map=%@", rect.size.width, rect.size.height, self.startFromMainMap?@"true":@"false");
//    rect = [self.topMapView toScreenRect:mainEnvelope];
//    NSLog(@"top map w=%f, h=%f", rect.size.width, rect.size.height);
}

-(void)computeEnvelopeForTopMap
{

    AGSEnvelope *topEnvelope = [self.topMapView.visibleArea envelope];
    AGSMutableEnvelope *newEnvelope = [AGSMutableEnvelope envelopeWithXmin:topEnvelope.xmin ymin:topEnvelope.ymin xmax:topEnvelope.xmax ymax:topEnvelope.ymax spatialReference:topEnvelope.spatialReference];
    CGRect rect = [self.topMapView toScreenRect:topEnvelope];

    float factor = (float)(self.slider.frame.origin.x+12.5) / rect.size.width;
    [newEnvelope offsetByX:-(topEnvelope.xmax-topEnvelope.xmin)*factor y:0.0];

    
    [self.mainMapView zoomToEnvelope:newEnvelope animated:YES];
    
    NSLog(@"top map w=%f, h=%f, x=%f, y=%f, factor=%f, start top map=%@", rect.size.width, rect.size.height, rect.origin.x, rect.origin.y, factor, self.startFromTopMap?@"true":@"false");
//
//    rect = [self.topMapView toScreenRect:topEnvelope];
//    NSLog(@"top map w=%f, h=%f, x=%f, y=%f, delta x=%f", rect.size.width, rect.size.height, rect.origin.x, rect.origin.y, (topEnvelope.xmax-topEnvelope.xmin));

}

@end
