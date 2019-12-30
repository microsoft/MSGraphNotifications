//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NotificationsViewController.h"
#import "NotificationsManager.h"
#import <GraphNotificationsLibrary/GraphNotificationsLibrary.h>
#import "UserNotificationApi.h"
#import "AppDelegate.h"
@implementation NotificationsViewController {
    NotificationsManager* _notificationsManager;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refresh];
}

- (void)_initNotificationsManager {
    @synchronized (self) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if (_notificationsManager == nil) {
            _notificationsManager = appDelegate.manager;
            __weak typeof(self) weakSelf = self;
            [_notificationsManager addNotificationsChangedListener: ^{
                NSLog(@"NotificationsViewController notified of changes!");
                [weakSelf _updateView];
            }];
        }
    }
}

- (void)_updateView {
    dispatch_async(dispatch_get_main_queue(), ^{
           [self.tableView reloadData];
       });
}

- (IBAction)refresh {
    [self _initNotificationsManager];
    if (_notificationsManager != nil) {
        [_notificationsManager refresh];
    }
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull __unused UITableView*)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return _notificationsManager.notifications.count;
}

- (nonnull UITableViewCell*)tableView:(nonnull UITableView*)tableView cellForRowAtIndexPath:(nonnull NSIndexPath*)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell" forIndexPath:indexPath];
    UserNotification* notification = _notificationsManager.notifications[indexPath.row];
    NSLog(@"NotificationsViewController updating cell for notification %@", [notification getAppNotificationId]);

    UILabel* idLabel = (UILabel*)[cell viewWithTag:1];
    [idLabel setText:[notification getAppNotificationId]];
    [idLabel setFont:[UIFont boldSystemFontOfSize:20]];

    UILabel* contentLabel = (UILabel*)[cell viewWithTag:2];
    VisualNotificationPayload* convertedNotification = (VisualNotificationPayload*)notification;
    if(convertedNotification)
    {
        [contentLabel setText:convertedNotification.body];
    }
    else
    {
        RawNotificationPayload* rawPayload = (RawNotificationPayload*)notification;
        [contentLabel setText:rawPayload.rawContent];
    }

    UILabel* actionStateLabel = (UILabel*)[cell viewWithTag:3];
    UIButton* dismissButton = (UIButton*)[cell viewWithTag:5];
    [dismissButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [dismissButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    if ([notification getUserNotificationActionState] == NONE) {
        [actionStateLabel setText:@"No Interaction"];
        dismissButton.enabled = YES;
        [dismissButton addTarget:self action:@selector(handleDismiss:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [actionStateLabel setText:@"Dismissed"];
        dismissButton.enabled = NO;
    }

    UIButton* readButton = (UIButton*)[cell viewWithTag:4];
    [readButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [readButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    if ([notification getReadStatus] == FALSE) {
        [idLabel setTextColor:[UIColor greenColor]];
        readButton.enabled = YES;
        [readButton addTarget:self action:@selector(handleRead:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [idLabel setTextColor:[UIColor redColor]];
        readButton.enabled = NO;
    }
    
    UIButton* deleteButton = (UIButton*)[cell viewWithTag:6];
    [deleteButton setTag:indexPath.row]; 
    [deleteButton addTarget:self action:@selector(handleDelete:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (IBAction)handleRead:(UIButton*)button {
    CGPoint touchPoint = [button convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *clickedButtonIndexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    UserNotification* selected = _notificationsManager.notifications[clickedButtonIndexPath.row];
    [_notificationsManager markRead:selected];
}

- (IBAction)handleDismiss:(UIButton*)button {
    CGPoint touchPoint = [button convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *clickedButtonIndexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    UserNotification* selected = _notificationsManager.notifications[clickedButtonIndexPath.row];
    [_notificationsManager dismissNotification:selected];
}

- (IBAction)handleDelete:(UIButton*)button {
    UserNotification* selected = _notificationsManager.notifications[button.tag];
    [_notificationsManager deleteNotification:selected];
}

@end
