// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

self.importScripts("./graph-notifications-library.js")
let accessToken = null;

console.info("create the UserNotificationApiImpl");
let userNotificationApiImpl = new userNotificationsClient.UserNotificationApiImpl(accessToken);

/**
 * Adds an 'message' event handler.
 * This will be called when the ouath access token is sent from the browser context to the service worker.
 * This is how the service worker gets the oauth access token (the access token is obtained in the browser)
*/
self.addEventListener('message', event => {
    console.info("received message in service worker");
    console.log("token value: ", event.data.token);
    if (event.data.token != null) {
        console.info("update token in library");
        userNotificationApiImpl.oAuthAccessToken = event.data.token;
        console.info("updated the token");
    } else {
        console.info("the received token is null");
    }
});

/**
 * Adds a 'push' event handler.
 * When a push notification is sent the browser receives it (from the push service) and it dispatches to the service worker.
 * This gets called when the servicer worker receives the push notification.
 */
self.addEventListener('push', (event) => {
    console.info("push notification received ", JSON.stringify(event));

    event.waitUntil((async () => {
        // get the content of the push notification as string
        let payloadText = event.data != null ? event.data.text() : "";
        console.debug("service-worker push notification received!", payloadText);

        // call the sdk to proces the push notification
        console.debug("call sdk to process the push notification");
        let processedPushNotification = await userNotificationApiImpl.processPushNotificationAsync(payloadText);

        // print to console the result
        console.log(JSON.stringify(processedPushNotification));
        console.log(processedPushNotification);


        if (!processedPushNotification.isUserNotificationPush) {
            console.error("not a push from Graph notification server. don't show notification pop-up");
            return;
        }

        if (processedPushNotification.userNotifications.length === 0) {
            console.log("push contains 0 Graph notifications. don't show notification pop-up");
            return;
        }

        // prepare the pop-up notification's text
        let title = 'Notification received';
        let body = 'sample';
        if (processedPushNotification.status !== userNotificationsClient.UserNotificationApiResultStatus.Succeeded) {
            body = "there were problems when parsing or fetching. Open the Dev Tools -> Console for more details!";
        } else {
            // sort the notifications from latest to earliest last-modified time
            let notifications = processedPushNotification.userNotifications.slice();
            notifications.sort((a, b) => {
                // lastModifiedDateTime is null when the notification has not been
                // modified since creation
                let aTime = a.lastModifiedDateTime || a.creationDateTime;
                let bTime = b.lastModifiedDateTime || b.creationDateTime;

                if (aTime < bTime) { return 1; }
                else if (aTime > bTime) { return -1; }
                else { return 0; }
            });

            // display the content of the most recently created notification
            let latestNotification = notifications[0];
            let payload = latestNotification.payload;
            if (payload.rawContent != null) {
                body = payload.rawContent;
            } else if (payload.title != null && payload.body != null) {
                title = payload.title;
                body = payload.body;
            } else {
                body = "there were some problems. Open the console for more details!";
            }
        }

        // show the pop-up notification
        await registration.showNotification(title, { body });
    })());
});

/**
 * Adds a 'notificationclick' event handler.
 * This is called when the displayed notification is clicked.
 */
self.addEventListener('notificationclick', async function (event) {
    console.info('notification clicked: ', event.notification.body, event.notification.title);

    event.notification.close();
});
