//
//  AppDelegate.h
//  DetectoreIBeacon
//
//  Created by yasuhisa.arakawa on 2013/11/25.
//  Copyright Yasuhisa Arakawa 2013年. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

#import <CoreLocation/CoreLocation.h>

// Added only for iOS 6 support
@interface MyNavigationController : UINavigationController <CCDirectorDelegate>
@end

@interface AppController : NSObject <UIApplicationDelegate, CLLocationManagerDelegate>
{
	UIWindow *window_;
	MyNavigationController *navController_;

	CCDirectorIOS	*director_;							// weak ref
}

@property (nonatomic, retain) UIWindow *window;
@property (readonly) MyNavigationController *navController;
@property (readonly) CCDirectorIOS *director;

@end
