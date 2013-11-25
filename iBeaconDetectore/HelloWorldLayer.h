//
//  HelloWorldLayer.h
//  iBeaconDetectore
//
//  Created by yasuhisa.arakawa on 2013/11/26.
//  Copyright Yasuhisa Arakawa 2013年. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
