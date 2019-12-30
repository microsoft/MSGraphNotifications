//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "NotificationsManager.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>
@property (strong, nonatomic) UIWindow* window;
@property (strong, nonatomic) NotificationsManager* manager;
@end

