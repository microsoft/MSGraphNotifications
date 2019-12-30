//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//

#import "AppDelegate.h"
#import <GraphNotificationsLibrary/UserNotificationApi.h>
#import <GraphNotificationsLibrary/UserNotification.h>
#import "APNSToken.h"
@implementation AppDelegate {
    
}

-(instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (BOOL)application:(UIApplication*)application
        didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    NSDictionary* notificationInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (!notificationInfo) {
        // User launched app by tapping the app icon
        NSLog(@"GraphNotificationsSample launching without user info");
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound
                 | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            NSLog(@"GraphNotificationsSample granted: %d error: %@", granted, error);
        }];

        [application registerForRemoteNotifications];
        center.delegate = self;
    } else {
        // App running in background and received a push notification, launched by user tapping the alert view
    }
    return YES;
}

- (void)application:(__unused UIApplication*)application
        didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError*)error {
    NSLog(@"GraphNotificationsSample failed to register for remote notifications with %@", error);
}

- (void)application:(UIApplication*)application
        didRegisterUserNotificationSettings:(__unused UNNotificationSettings*)notificationSettings {
    // Do registerForRemoteNotifications after registerUserNotificationSettings is finished
    [application registerForRemoteNotifications];
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
}

- (void)application:(__unused UIApplication*)application
        didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    // Retrieve the deviceToken, convert it to HEX encoded NSString
    NSMutableString* deviceTokenStr = [NSMutableString stringWithCapacity:deviceToken.length * 2];
    const unsigned char* byteBuffer = deviceToken.bytes;
    for (NSUInteger i = 0; i < deviceToken.length; ++i) {
        [deviceTokenStr appendFormat:@"%02X", (unsigned int)byteBuffer[i]];
    }
    NSLog(@"GraphNotificationsSample APNs token: %@", deviceTokenStr);

    @try {
        [[APNSToken accessToken] setAccessToken:deviceTokenStr];
    } @catch (NSException* exception) {
        NSLog(@"Failed to update notification registration with exception %@", exception);
    }
}

- (void)application:(UIApplication*)application
        didReceiveRemoteNotification:(NSDictionary*)notificationInfo
        fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    // App running in foreground and received a push notification
    NSLog(@"GraphNotificationsSample received push notification...");
    [notificationInfo enumerateKeysAndObjectsUsingBlock:^( id _Nonnull key, id _Nonnull obj, __unused BOOL* _Nonnull stop) {
        NSLog(@"%@: %@", key, obj);
    }];
    [self.manager.userNotificationApi processPushNotificationAsync:notificationInfo completionHandler:^(ProcessPushNotificationResult *result) {
        if(result.isUserNotificationPush)
        {
            [self.manager _handleNotifications:result.userNotifications];
        }
    }];
}


- (void)userNotificationCenter:(__unused UNUserNotificationCenter*)center
       willPresentNotification:(UNNotification*)notification
       withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert
                      | UNNotificationPresentationOptionBadge
                      | UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter*)center
        didReceiveNotificationResponse:(UNNotificationResponse*)response
        withCompletionHandler:(void (^)(void))completionHandler {

}

- (void)applicationWillResignActive:(UIApplication*)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary
    // interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the
    // transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks.
    // Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state
    // information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes
    // made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive.
    // If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication*)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

void uncaughtExceptionHandler(NSException* uncaughtException) {
    NSLog(@"Uncaught exception: %@", uncaughtException.description);
}

@end
