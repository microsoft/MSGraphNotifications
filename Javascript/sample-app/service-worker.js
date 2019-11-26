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

        // show the notification
        const title = 'Notification received';
        let options = {
            body: "sample"
        };

        if (!processedPushNotification.isUserNotificationPush) {
            console.error("it was not a user notification. dont show notification")
            return;
        }

        if (processedPushNotification.userNotifications.length === 0){
            console.log("received 0 user notifications. dont show notification");
            return;
        }

        if (processedPushNotification.status !== userNotificationsClient.UserNotificationApiResultStatus.Succeeded) {
            options = {
                body: "there were problems when parsing or fetching. Open the Dev Tools -> Console for more details!"
            };
        } else {
            options = {
                body: processedPushNotification.userNotifications[0].payload.rawContent || "there were some problems. Open the console for more details!"
            };
        }

        await registration.showNotification(title, options);
    })());
});

/**
 * Adds a 'notificationclick' event handler.
 * This is called when the displayed notification is clicked.
 */
self.addEventListener('notificationclick', async function (event) {
    console.info('notificaton clicked', event.notification.body);

    event.notification.close();
});
