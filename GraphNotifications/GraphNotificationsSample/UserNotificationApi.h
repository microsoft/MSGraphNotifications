//
//  UserNotificationApi.h
//  GraphNotificationsSample
//
//  Created by Adam Crabtree on 12/26/19.
//  Copyright © 2019 Microsoft. All rights reserved.
//

#ifndef UserNotificationApi_h
#define UserNotificationApi_h
#import <GraphNotificationsLibrary/UserNotificationApi.h>
@interface UserNotificationApiImpl : NSObject
@property (strong, nonatomic) UserNotificationApi* userNotificationApi;
+(id)UserNotificationApiImpl;
-(void)setMSALAccessToken:(NSString*)accessToken;
-(void)subscribeToUserNotificationsAsync:(NSString *)pushTokenFromPlatform
           appPackageNameForPushPlatform:(NSString *)appPackageNameForPushPlatform
           appDisplayNameForUnsAnalytics:(NSString *)appDisplayNameForUnsAnalytics
                       completionHandler:(void (^)(UserNotificationSubscriptionResult*))handler;

-(void)unsubscribeFromUserNotificationsAsync:(NSString*)userNotificationSubscriptionId
                           completionHandler: (void (^)(NSError* error)) handler;

@end

#endif /* UserNotificationApi_h */
