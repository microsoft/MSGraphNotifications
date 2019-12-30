//
//  UserNotificationApi.m
//  GraphNotificationsSample
//
//  Created by Adam Crabtree on 12/26/19.
//  Copyright © 2019 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserNotificationApi.h"
#import "NotificationsManager.h"
@implementation UserNotificationApiImpl
static UserNotificationApiImpl* _userNotificationApiImpl;
UserNotificationApi* _userNotificationApi;
+(id)UserNotificationApiImpl
{
    @synchronized ([UserNotificationApiImpl class]) {
        if(!_userNotificationApiImpl)
        {
            _userNotificationApiImpl  = [[self alloc] init];
            _userNotificationApi = [[self alloc] init];
            NotificationsManager* _notificationsManager = [[self alloc]init];

        }
        return _userNotificationApiImpl;
    }
    return nil;
}
-(void)setMSALAccessToken:(NSString*)accessToken
{
    [_userNotificationApi setOAuthAccessToken:accessToken];
}
-(void)subscribeToUserNotificationsAsync:(NSString *)pushTokenFromPlatform appPackageNameForPushPlatform:(NSString *)appPackageNameForPushPlatform appDisplayNameForUnsAnalytics:(NSString *)appDisplayNameForUnsAnalytics completionHandler:(void (^)(UserNotificationSubscriptionResult* ))returnHandler
{
    [_userNotificationApiImpl subscribeToUserNotificationsAsync:pushTokenFromPlatform appPackageNameForPushPlatform:appDisplayNameForUnsAnalytics appDisplayNameForUnsAnalytics:appDisplayNameForUnsAnalytics completionHandler:^(UserNotificationSubscriptionResult * output) {
            returnHandler(output);
    }];
}
-(void)unsubscribeFromUserNotificationsAsync:(NSString*)userNotificationSubscriptionId
                           completionHandler: (void (^)(NSError* error)) handler;
{
    [_userNotificationApiImpl unsubscribeFromUserNotificationsAsync:userNotificationSubscriptionId completionHandler:^(NSError *error) {
        handler(error);
    }];
}
@end
