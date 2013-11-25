//
//  DetecroreScene.m
//  DetectoreIBeacon
//
//  Created by yasuhisa.arakawa on 2013/11/25.
//  Copyright 2013年 Yasuhisa Arakawa. All rights reserved.
//

#import "DetecroreScene.h"
#import "AppDelegate.h"

@implementation DetecroreScene

+ (CCScene *)scene {
    CCScene *scene = [CCScene node];
    DetecroreScene *detectoreScene = [DetecroreScene node];
    [scene addChild:detectoreScene];
    return scene;
}

- (id)init
{
    self = [super init];
    if (self) {
        if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
            // CLLocationManagerの生成とデリゲートの設定
            locationManager_ = [CLLocationManager new];
            locationManager_.delegate = self;
            
            // 生成したUUIDからNSUUIDを作成
            proximityUUID_ = [[NSUUID alloc] initWithUUIDString:@"Your iOS7 UUID"];
            // CLBeaconRegionを作成
            beaconRegion_ = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID_
                                                                   identifier:@"detectore"];
            // Beaconによる領域観測を開始
            [locationManager_ startMonitoringForRegion:beaconRegion_];
        }

    }
    return self;
}

- (void)onEnter
{
    [super onEnter];
    
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    CCLabelTTF *label = [CCLabelTTF labelWithString:@"iBeacon" fontName:@"Arial-BoldMT" fontSize:24];
    label.position = ccp(size.width / 2, size.height / 2);
    [self addChild:label];
    
    int __block xMove = 0;
    int __block yMove = 0;
    int __block jHeight = 150;
    
    CCJumpBy __block *jumpBy = [CCJumpBy actionWithDuration:2.0f
                                           position:ccp(xMove, yMove)
                                             height:100
                                              jumps:2];
    
    CCSequence __block *sequence = nil;
    CCRepeatForever __block *repeat = nil;
    
    CCCallBlockN __block *callBlockN = [CCCallBlockN actionWithBlock:^(CCNode *node) {
        if (node.position.x < 70 || node.position.x > 250) {
            [node stopAllActions];
            
            xMove = -xMove;
            yMove = -yMove;
            
            jumpBy = [CCJumpBy actionWithDuration:2.0f
                                         position:ccp(xMove, yMove)
                                           height:jHeight
                                            jumps:2];
            
            sequence = [CCSequence actions:jumpBy, callBlockN, nil];
            repeat = [CCRepeatForever actionWithAction:sequence];
            
            [node runAction:repeat];
        }
    }];
    
    sequence = [CCSequence actions:jumpBy, callBlockN, nil];
    repeat = [CCRepeatForever actionWithAction:sequence];
    
    [label runAction:repeat];
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Start Monitoring Region"];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Enter Region"];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [locationManager_ startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Exit Region"];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [locationManager_ stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0) {
        CLBeacon *nearestBeacon = beacons.firstObject;
        
        NSString *rangeMessage;
        
        switch (nearestBeacon.proximity) {
            case CLProximityImmediate:
                rangeMessage = @"Range Immediate: ";
                break;
            case CLProximityNear:
                rangeMessage = @"Range Near: ";
                break;
            case CLProximityFar:
                rangeMessage = @"Range Far: ";
                break;
            default:
                rangeMessage = @"Range Unknown: ";
                break;
        }
        
        NSString *message = [NSString stringWithFormat:@"major:%@, minor:%@, accuracy:%f, rssi:%d",
                             nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, nearestBeacon.rssi];
        [self sendLocalNotificationForMessage:[rangeMessage stringByAppendingString:message]];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [self sendLocalNotificationForMessage:@"Exit Region"];
}

#pragma mark - Private methods

- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end
