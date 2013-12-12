//
//  DetecroreScene.m
//  DetectoreIBeacon
//
//  Created by yasuhisa.arakawa on 2013/11/25.
//  Copyright 2013年 Yasuhisa Arakawa. All rights reserved.
//

#import "DetecroreScene.h"
#import "AppDelegate.h"

// ターミナルから $ uuidgen
static NSString * const kBeaconUUID         = @"FB71B678-3BDE-4820-B2CE-9E6930B585C7";
// 任意の識別子
static NSString * const kBeaconIdentifier   = @"detectore";
// 今回はMajor内のBeaconを全て測定する
static NSInteger const kTargetBeaconMajor   = 1;
// 正解BeaconのMinor
static NSInteger const kTargetBeaconMinor   = 1;
static NSInteger const kParticleTag         = 101;

@implementation DetecroreScene {
    CCLabelTTF *labelBeaconName_;
    CCLabelTTF *labelDescription_;
    CCMenu *menu_;
    CGSize winSize_;
    int missCount_;
    int stayCount_;
    int isFirstRanging;
    BOOL isCorrectTreasure_;
}

#pragma mark - coco2d methods

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
        
        winSize_ = [[CCDirector sharedDirector] winSize];
        
        labelDescription_ = [CCLabelTTF labelWithString:@"Tresure Detectore\nFind the No,1Treasure" fontName:@"Marker Felt" fontSize:32.0f];
        labelDescription_.position = ccp(winSize_.width / 2, winSize_.height / 2);
        [self addChild:labelDescription_];
        
        labelBeaconName_ = [CCLabelTTF labelWithString:@"" fontName:@"Marker Felt" fontSize:26.0f];
        labelBeaconName_.position = ccp(winSize_.width / 2, labelDescription_.position.y + 100);
        [self addChild:labelBeaconName_];
        
        CCMenuItem *menuStart = [CCMenuItemFont itemWithString:@"Start!" target:self selector:@selector(pushStart:)];
        menu_ = [CCMenu menuWithItems:menuStart, nil];
        [menu_ setPosition:ccp(winSize_.width / 2, winSize_.height / 5)];
        [self addChild:menu_];
    }
    return self;
}

- (void)onEnter
{
    [super onEnter];
}

#pragma mark - CLLocationManagerDelegate methods

// 画面を表示した時に通知を受け取る
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    CCLOG(@"Determine State");
    
    // 観測可能領域内かつ測定可能
    if(state == CLRegionStateInside && [CLLocationManager isRangingAvailable]) {
        [self.locationManager_ startRangingBeaconsInRegion:self.beaconRegion_];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    CCLOG(@"Start Monitoring Region");
    
    if([CLLocationManager isRangingAvailable]) {
        [self.locationManager_ startRangingBeaconsInRegion:self.beaconRegion_];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    CCLOG(@"Enter Region");
    
    // 測定開始
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager_ startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    CCLOG(@"Exit Region");
    
    // 測定停止
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager_ stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    
    // for (CLBeacon *beacon in beacons) {
        /*
         複数台のBeaconからの距離を測定したい場合はここに処理を記述（距離が近い順にソートされている）
         注）Bluetooth Low Energyの電波強度でBeaconを検知しているため、
         環境次第（Beaconの配置の仕方や電波障害等）では正確な距離順にはならない
         */
    // }
    
    
    /*
     Ranging再スタート時に限り、初回のみどこから測定してもCLProximityImmediateに必ずなってしまうため初回は測定しない。
     */
    if (isFirstRanging) {
        
        [labelDescription_ setString:@"Searching..."];
        isFirstRanging = NO;

        return;
    }
    
    
    if (beacons.count > 0) {
        
        // 最も測定距離の近いBeaconを取得
        CLBeacon *nearestBeacon = beacons.firstObject;
        
        float distance = 1.0f / nearestBeacon.accuracy;
        
        switch (nearestBeacon.proximity) {
            case CLProximityImmediate: {
                stayCount_++;
                missCount_ = 0;
                
                [self showParticleWithEmmisionRate:300 * distance speed:100 * distance];
                [labelDescription_ setString:@"Treasure is hear!!"];
                
                // 電波強度のブレでクリア判定にいかないためにstayCountとaccuracyで判定
                if (nearestBeacon.accuracy < 0.2f) { // （20cm未満まで接近したらTreasure Get）
                    [labelDescription_ setString:@"Find Treasure!!"];
                    
                    if (stayCount_ > 3) {
                        
                        stayCount_ = 0;
                        int minor = [nearestBeacon.minor intValue];
                        
                        if (minor == kTargetBeaconMinor) {
                            [labelBeaconName_ setString:[NSString stringWithFormat:@"This is No,%dTreasure.", minor]];
                            isCorrectTreasure_ = YES;
                        } else {
                            [labelBeaconName_ setString:@"Warning! Get out of hear!!"];
                            isCorrectTreasure_ = NO;
                        }
                        
                        [self labelScaling:1.5f afterScale:1.0f];
                        
                        // 1秒待機後にgetTreasure()を実行
                        [self scheduleOnce:@selector(getTreasure) delay:1.0f];
                        nearestBeacon = nil;
                        [self stopMonitoring:region];
                    }
                }
                
                break;
            }
            case CLProximityNear: {
                stayCount_ = 0;
                missCount_ = 0;
                [self showParticleWithEmmisionRate:200 * distance speed:100 * distance];
                
                [labelDescription_ setString:@"Treasure is near!"];
                [labelBeaconName_ setString:@""];
                [self labelScaling:1.2f afterScale:1.0f];
                
                break;
            }
            case CLProximityFar: {
                stayCount_ = 0;
                missCount_ = 0;
                [self showParticleWithEmmisionRate:100 * distance speed:80 * distance];
                
                [labelDescription_ setString:@"Treasure is far."];
                [labelBeaconName_ setString:@""];
                [self labelScaling:0.9f afterScale:1.0f];

                break;
            }
            default:
                stayCount_ = 0;
                missCount_++;
                
                [labelDescription_ setString:@"Searching..."];
                
                // 測定を止める
                if (missCount_ > 4) {
                    [labelDescription_ setString:@"Sorry.\nTreasure is missed."];
                }
                
                break;
        }
        
        CCLOG(@"%@", [NSString stringWithFormat:@"major:%@\n minor:%@\n accuracy:%f\n rssi:%d",
                      nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, nearestBeacon.rssi]);
    }

}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    if(error.code == kCLErrorRegionMonitoringFailure) {
        CCLOG(@"Fail for Region");
    } else {
        [[[UIAlertView alloc] initWithTitle:@"error"
                                    message:error.description
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

#pragma mark - UIAlertView delegate method

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            (isCorrectTreasure_) ? [self gameComplete] : [self gameOver];
            break;
        default:
            [labelBeaconName_ setString:@""];
            [labelDescription_ setString:@"Searching..."];
            [self startMonitoring];
            break;
    }
}


#pragma mark - Private methods

// Beaconによる領域観測を開始
- (void)startMonitoring
{
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        
        // CLLocationManagerの生成とデリゲートの設定
        self.locationManager_ = [CLLocationManager new];
        self.locationManager_.delegate = self;
        
        // 生成したUUIDからNSUUIDを作成
        self.proximityUUID_ = [[NSUUID alloc] initWithUUIDString:kBeaconUUID];
        // CLBeaconRegionを作成
        self.beaconRegion_ = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID_
                                                                     major:kTargetBeaconMajor
                                                                identifier:kBeaconIdentifier];
        
        [self.locationManager_ startMonitoringForRegion:self.beaconRegion_];
    }
}

// 指定ビーコンの測定・監視を止める
- (void)stopMonitoring:(CLBeaconRegion *)region
{
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager_ stopMonitoringForRegion:self.beaconRegion_];
        [self.locationManager_ stopRangingBeaconsInRegion:region];
        self.locationManager_.delegate = nil;
        self.locationManager_ = nil;
        self.proximityUUID_ = nil;
        self.beaconRegion_ = nil;
    }
}

- (void)pushStart:(CCMenuItem *)menu
{
    menu_.visible = NO;
    isFirstRanging = YES;
    
    [labelDescription_ setString:@""]; 
    
    [self removeChild:[self getChildByTag:kParticleTag]];
    [labelDescription_ stopAllActions];
    labelDescription_.position = ccp(winSize_.width / 2, winSize_.height / 2);
    
    [self startMonitoring];
}

- (void)labelScaling:(float)beforeScale afterScale:(float)afterScale
{
    CCScaleTo *scaleToBef = [CCScaleTo actionWithDuration:0.25f scale:beforeScale];
    CCScaleTo *scaleToAf = [CCScaleTo actionWithDuration:0.25f scale:afterScale];
    
    CCSequence *sequence = [CCSequence actions:scaleToBef, scaleToAf, nil];
    [labelDescription_ runAction:sequence];
}

- (void)getTreasure
{
    [[[UIAlertView alloc] initWithTitle:@"Find Treasure"
                                message:@"Open?"
                               delegate:self
                      cancelButtonTitle:@"No!"
                      otherButtonTitles:@"Yes!!", nil] show];
}

- (void)gameComplete
{
    [labelBeaconName_ setString:@""];
    [self showCompleteParticle];
    
    [labelDescription_ setString:@"Congratulations!!\n You find the Treasure!!"];

    CCJumpBy __block *jumpBy = [CCJumpBy actionWithDuration:2.0f
                                                   position:ccp(0, 0)
                                                     height:100
                                                      jumps:1];
    
    CCRepeatForever *repeat = [CCRepeatForever actionWithAction:jumpBy];
    
    [labelDescription_ runAction:repeat];
    
    menu_.visible = YES;
}

- (void)gameOver
{
    [labelBeaconName_ setString:@"You were caught in a Trap..."];
    [labelDescription_ setString:@"Game Over"];
    
    CCFadeOut *fadeOut = [CCFadeOut actionWithDuration:3.0f];
    CCMoveBy *moveBy = [CCMoveBy actionWithDuration:4.0f position:ccp(0, - winSize_.height)];
    
    CCSpawn *spawn = [CCSpawn actions:fadeOut, moveBy, nil];
    
    CCEaseIn *easeIn = [CCEaseIn actionWithAction:spawn rate:5];
    
    CCCallBlockN *callBlockN = [CCCallBlockN actionWithBlock:^(CCNode *node) {
        menu_.visible = YES;
        [labelBeaconName_ setString:@""];
        [labelDescription_ setString:@""];
        [labelDescription_ setOpacity:255];
    }];

    CCSequence *sequence = [CCSequence actions:easeIn, callBlockN, nil];
    
    [labelDescription_ runAction:sequence];
}

- (void)showParticleWithEmmisionRate:(int)emmisionRate speed:(float)speed
{
    CCParticleFire *particle = [CCParticleFire node];
    particle.emitterMode = kCCParticleModeGravity;                      // パーティクルベース
    particle.texture = [[CCTextureCache sharedTextureCache] addImage:@"fire.png"];   // テクスチャー
    particle.blendFunc = (ccBlendFunc) { GL_SRC_ALPHA, GL_ONE };        // 描画方式
    particle.duration = 1.0f;                                           // 秒間放出
    particle.position = ccp(winSize_.width / 2, winSize_.height / 4);   // 発生基準地点
    particle.posVar = ccp(0, 0);                                        // 変動値
    particle.life = 1.0f;                                               // 消滅するまでの時間
    particle.lifeVar = 0.5f;                                            // 変動値
    particle.angle = 0;                                                 // 角度
    particle.angleVar = 360;                                            // 変動値
    particle.gravity = ccp(0, 0);                                       // 加速方向と速度
    particle.speed = speed;                                             // 射出速度
    particle.speedVar = 0;                                              // 変動値
    particle.radialAccel = 50;                                          // 加速度
    particle.radialAccelVar = 50;                                       // 変動値
    particle.tangentialAccel = 0;                                       // 放出点を中心とした回転　ひねり
    particle.tangentialAccelVar = 0;                                    // 変動値
    particle.startSpin = 0;                                             // 放出時にパーティクルが回転する角度
    particle.emissionRate = emmisionRate;                               // 1秒間に放出するパーティクルの数
    particle.totalParticles = 1000;                                     // 存在できるパーティクルの総数（超えた分は消滅、重い場合は下げる）
    
    particle.autoRemoveOnFinish = YES;                                  // 使い終わったらインスタンスが消える

    [self addChild:particle];
}

- (void)showCompleteParticle
{
    CCParticleGalaxy *particle = [CCParticleGalaxy node];
    particle.emitterMode = kCCParticleModeGravity;
    particle.texture = [[CCTextureCache sharedTextureCache] addImage:@"Default.png"];
    particle.blendFunc = (ccBlendFunc) { GL_SRC_ALPHA, GL_ONE };
    particle.position = ccp(winSize_.width / 2, winSize_.height / 2);
    particle.posVar = ccp(0, 0);
    particle.life = 1.0f;
    particle.lifeVar = 0.5f;
    particle.angle = 0;
    particle.angleVar = 360;
    particle.gravity = ccp(0, 0);
    particle.speed = 500;
    particle.speedVar = 300;
    particle.radialAccel = 50;
    particle.radialAccelVar = 50;
    particle.tangentialAccel = 0;
    particle.tangentialAccelVar = 360;
    particle.startSpin = 0;
    particle.startSize = 10;
    particle.endSize = 80;
    particle.emissionRate = 300;
    particle.totalParticles = 1000;
    
    particle.autoRemoveOnFinish = YES;
    particle.tag = kParticleTag;
    
    [self addChild:particle];
}

@end
