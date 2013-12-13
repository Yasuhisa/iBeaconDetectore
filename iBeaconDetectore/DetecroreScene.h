//
//  DetecroreScene.h
//  DetectoreIBeacon
//
//  Created by yasuhisa.arakawa on 2013/11/25.
//  Copyright 2013年 Yasuhisa Arakawa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#import <CoreLocation/CoreLocation.h>

@interface DetecroreScene : CCLayer <CLLocationManagerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager_;
@property (nonatomic, strong) NSUUID *proximityUUID_;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion_;

+(CCScene *) scene;

@end
