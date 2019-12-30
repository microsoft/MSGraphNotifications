//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//

#import "NotificationsManager.h"
#import <UserNotifications/UserNotifications.h>
#import "Secrets.h"
#import "APNSToken.h"

@implementation NotificationsManager {
    NSMutableArray<UserNotification*>* _notifications;
    NSInteger _listenerValue;
    NSMutableDictionary<NSNumber*, void(^)(void)>* _listenerMap;
    
}


- (void)dismissNotificationFromTrayWithId:(NSString *)notificationId {
    [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:@[notificationId]];
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[notificationId]];
}

- (void)_clearAll {
    @synchronized (self) {
        [_notifications removeAllObjects];
        [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
        [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
    }
}

- (void)_handleNotifications:(NSArray<UserNotification*>*)notifications {
    @synchronized (self) {
        for (UserNotification* notification in notifications) {
            NSUInteger index = [_notifications
                                indexOfObjectPassingTest:^BOOL(UserNotification* existingNotification, NSUInteger __unused innerIndex, BOOL* stop) {
                                    if ([[existingNotification getAppNotificationId] isEqualToString:[notification getAppNotificationId]]) {
                                        *stop = YES;
                                        return YES;
                                    }
                                    return NO;
                                }];
            if (index != NSNotFound) {
                [_notifications removeObjectAtIndex:index];
            }
            
            if ([notification getUserNotificationActionState] == ACTIVE) {
                NSLog(@"Notification %@ is active", [notification getAppNotificationId]);
                if(index != NSNotFound) {
                    [_notifications insertObject:notification atIndex:index];
                } else {
                    [_notifications insertObject:notification atIndex:0];
                }
                
                if (([notification getUserNotificationActionState] == NONE)
                    && ([notification getReadStatus] == FALSE)) {
                    UNMutableNotificationContent* content = [UNMutableNotificationContent new];
                    content.title = @"New Graph Notification";
                    RawNotificationPayload* payload = [notification getNotificationPayload];
                    if(payload)
                    {
                        content.body = payload.rawContent;
                    }
                    else
                    {
                        VisualNotificationPayload* visualPayload = [notification getNotificationPayload];
                        content.body = visualPayload.title;
                    }
                    UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
                                                                  triggerWithTimeInterval:1 repeats:NO];
                    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:[notification getAppNotificationId]
                                                                                          content:content trigger:trigger];
                    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                                           withCompletionHandler:^(NSError * _Nullable error) {
                                                                               if (error) {
                                                                                   NSLog(@"Failed to post local notification with error %@", error);
                                                                               } else {
                                                                                   NSLog(@"Successfully posted local notification request");
                                                                               }
                                                                           }];
                    for (void (^listener)(void) in _listenerMap.allValues) {
                        listener();
                    }
                } else {
                    [self dismissNotificationFromTrayWithId:[notification getAppNotificationId]];
                }
            } else {
                NSLog(@"Notification %@ is deleted", [notification getAppNotificationId]);
                [self dismissNotificationFromTrayWithId:[notification getAppNotificationId]];
            }
        }
        
        NSLog(@"NotificationsManager now has %ld notifications", _notifications.count);
    }
}
- (instancetype)initWithAccount:(NSString*)accountId {
    if (self = [super init]) {
        _notifications = [NSMutableArray array];
        _listenerValue = 0;
        _listenerMap = [NSMutableDictionary dictionary];
        _userNotificationApi =  [[UserNotificationApi alloc] init];
        [_userNotificationApi setOAuthAccessToken:accountId];
        [_userNotificationApi subscribeToUserNotificationsAsync:[[APNSToken accessToken] getAccessToken] appPackageNameForPushPlatform:APP_HOST_NAME appDisplayNameForUnsAnalytics:@"GraphNotificationsSample" completionHandler:^(UserNotificationSubscriptionResult * result) {
            if(result.getStatus==SUCCEEDED)
            {
                NSLog(@"Registered for remote notifications successfully");
            }
            else
            {
                NSLog(@"Failed to update notification registration with exception %u", [result getStatus]);
            }
        }];
    }
    return self;
}
- (NSInteger)addNotificationsChangedListener:(void(^)(void))listener {
    @synchronized (self) {
        _listenerMap[[NSNumber numberWithInteger:(++_listenerValue)]] = listener;
        return _listenerValue;
    }
}


- (void)removeListener:(NSInteger)token {
    @synchronized (self) {
        [_listenerMap removeObjectForKey:[NSNumber numberWithInteger:token]];
    }
}
 

- (void)markRead:(UserNotification*)notification {
    if ([notification getReadStatus] == FALSE) {
        NSLog(@"Marking notification %@ as read", [notification getAppNotificationId]);
        [_userNotificationApi updateNotificationReadStateAsync:[notification getAppNotificationId] readState:TRUE completionHandler:^(BOOL *successResult) {
            if(successResult==FALSE)
            {
                NSLog(@"Failed to mark the notification as read");
            }
            else
            {
                NSLog(@"Successfully marked the notification as read");
            }
        }];
    }
}

- (void)deleteNotification:(UserNotification*)notification {
    NSLog(@"Deleting notification %@", [notification getAppNotificationId]);
    [_userNotificationApi deleteNotificationAsync:[notification getAppNotificationId] completionHandler:^(NSDate *Date) {
        if(Date)
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"YYYY-MM-dd"];
            NSLog(@"Successfully deleted the notification at date %@", [formatter stringFromDate:Date]);
        }
        else
        {
            NSLog(@"Failed to delete notifications");
        }
    }];
}

- (void)dismissNotification:(UserNotification*)notification {
    if ([notification getUserNotificationActionState] == NONE) {
        NSLog(@"Dismissing notification %@", [notification getAppNotificationId]);
        [self dismissNotificationFromTrayWithId:[notification getAppNotificationId]];
        [_userNotificationApi updateNotificationUserActionStateAsync:[notification getAppNotificationId] newUserActionState:ACTIVATED completionHandler:^(BOOL *successResult) {
            if(successResult==TRUE)
            {
                NSLog(@"Successfully dismissed the notification");
            }
            else
            {
                NSLog(@"Failed to dismiss notifications.");
            }
        }];
    }
}

@end
