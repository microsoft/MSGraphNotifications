//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import <GraphNotificationsLibrary/UserNotification.h>
#import <GraphNotificationsLibrary/UserNotificationApi.h>

@interface NotificationsManager : NSObject
- (instancetype)initWithAccount:(NSString*)accountId;

@property NSMutableArray<UserNotification*>* notifications;
@property UserNotificationApi* userNotificationApi;

- (NSInteger)addNotificationsChangedListener:(void(^)(void))listener;
- (void)removeListener:(NSInteger)token;
- (void)refresh;
- (void)_handleNotifications:(NSArray<UserNotification*>*)notifications;
- (void)markRead:(UserNotification*)notificationId;
- (void)deleteNotification:(UserNotification*)notificationId;
- (void)dismissNotification:(UserNotification*)notificationId;
@end
