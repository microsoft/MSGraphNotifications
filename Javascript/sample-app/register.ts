// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

// This public key is the VAPID application server key for Microsoft Graph notifications server
const appPubKey = "BAJ6h7VPNP4MH6cn11kfmuA2Ht9Zy_WrIxeKNsOqJZAXcfTSleho4xmuPF_X278Wd9_qHWRYQjDX-Ju23pNKJpk";
import { UserNotificationApiImpl, UserNotificationUserActionState } from "@microsoft/user-notifications-client"
import { UserNotificationSubscriptionResult } from "@microsoft/user-notifications-client/dist/definitions/src/userNotificationSubscriptionResult";
import { UserNotificationUpdateResult } from "@microsoft/user-notifications-client/dist/definitions/src/userNotificationUpdateResult";

/**
 * Registers the service worker
 * @param serviceWorkerUri
 */
async function registerServiceWorker(serviceWorkerUri: string): Promise<ServiceWorkerRegistration> {
    try {
        console.info(`try to register the service worker ${serviceWorkerUri}...`);
        var registration = await navigator.serviceWorker.register(serviceWorkerUri);

        if (registration == null) {
            console.error("Failed to register service worker");
            return null;
        }

        console.log("Service worker registered. Initializing push channel")
        return await navigator.serviceWorker.ready;
    }
    catch (err) {
        console.error(err);
        return null;
    }
}

/**
 * Sends the access token to the service worker by posting a message to it.
 * https://developer.mozilla.org/en-US/docs/Web/API/Worker/postMessage
 * @param serviceWorkerRegistration
 * @param accessToken
 */
function sendAccessTokenToServicerWorker(serviceWorkerRegistration: ServiceWorkerRegistration, accessToken: string): void {
    console.info("sending the token to the service worker...");
    var info = {
        token: accessToken
    }

    serviceWorkerRegistration.active.postMessage(info);
}

/**
 * Gets a push subscription or creates one (if did not exist before).
 * @param serviceWorkerRegistration
 */
async function getPushSubscription(serviceWorkerRegistration: ServiceWorkerRegistration): Promise<PushSubscription> {
    var pushSubscription = await serviceWorkerRegistration.pushManager.getSubscription();
    if (pushSubscription) {
        console.log("Push channel subscription already exists");
    }
    else {
        pushSubscription = await serviceWorkerRegistration.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: urlBase64ToUint8Array(appPubKey)
        });

        console.log("Push channel subscription created.")
    }

    return pushSubscription;
}

/**
 * Handles the interaction with the user notification client
 */
export class UserNotificationClientWrapper {
    private _userNotificationApiImpl: UserNotificationApiImpl;
    private _userNotificationsSubscription: UserNotificationSubscriptionResult;

    constructor(private pushSub: PushSubscription, private token: string) {
        this._userNotificationApiImpl = new UserNotificationApiImpl(token);
    }

    async subscribeToUserNotificationsAsync(crossDeviceAppId: string) {
        this._userNotificationsSubscription = await this._userNotificationApiImpl.subscribeToUserNotificationsAsync(crossDeviceAppId, "webpush sample app", this.pushSub);
        console.log("user notifications subscription is:");
        console.log(this._userNotificationsSubscription);
    }

    async getAllNotificationsAsync() {
        let userNotifications = await this._userNotificationApiImpl.getAllNotificationsAsync();
        console.log("userNotifications received");
        console.log(userNotifications);
    }

    async updateNotificationReadStateAsync(notificationId: string, readState: boolean) {
        let userNotificationUpdateResult = await this._userNotificationApiImpl.updateNotificationReadStateAsync(notificationId, readState);
        this._printUserNotificationUpdateResult(userNotificationUpdateResult, "userNotificationUpdateResult");
    }

    async updateNotificationUserActionStateAsync(notificationId: string, userActionStateNumber: number) {
        let userActionState = UserNotificationUserActionState.None;
        if (userActionStateNumber === 1) {
            userActionState = UserNotificationUserActionState.Activated;
        } else if (userActionStateNumber === 2) {
            userActionState = UserNotificationUserActionState.Dismissed;
        } else if (userActionStateNumber === 3) {
            userActionState = UserNotificationUserActionState.Snoozed;
        }

        let userNotificationUpdateResult = await this._userNotificationApiImpl.updateNotificationUserActionStateAsync(notificationId, userActionState);
        this._printUserNotificationUpdateResult(userNotificationUpdateResult, "updateNotificationUserActionStateAsync");
    }

    private _printUserNotificationUpdateResult(userNotificationUpdateResult: UserNotificationUpdateResult, actionName: string) {
        console.log(`${actionName} (stringify): `, JSON.stringify(userNotificationUpdateResult));
        console.log(`${actionName}: `, userNotificationUpdateResult);
    }

    async deleteNotificationAsync(notificationId: string) {
        let userNotificationUpdateResult = await this._userNotificationApiImpl.deleteNotificationAsync(notificationId);
        this._printUserNotificationUpdateResult(userNotificationUpdateResult, "deleteNotificationAsync");
    }

    async unsubscribeFromUserNotificationsAsync() {
        let userNotificationUpdateResult = await this._userNotificationApiImpl.unsubscribeFromUserNotificationsAsync();
        this._printUserNotificationUpdateResult(userNotificationUpdateResult, "unsubscribeFromUserNotificationsAsync");
    }

    refreshToken(newToken: string) {
        console.info("UserNotificationClientWrapper.refreshToken refresh the token for its instance");
        this._userNotificationApiImpl.oAuthAccessToken = newToken;

    }
}

let globalUserNotificationClientWrapper: UserNotificationClientWrapper = null;
var thisCopy = this;

// The following methods are called from the index.html

/**
 * Refreshes the token inside the sdk.
 */
export async function refreshToken() {
    console.info("reading token2 from local storage...");
    let newToken = localStorage.getItem("token2");
    console.info("Update the token in sdk:", newToken);
    thisCopy.globalUserNotificationClientWrapper.refreshToken(newToken);

    console.info("RegisterTopLevel.refresh sends message to servier worker with the new token...");
    let serviceWorkerRegistration = await navigator.serviceWorker.ready;
    sendAccessTokenToServicerWorker(serviceWorkerRegistration, newToken);
}

/**
 * Register the service worker and subscribes to Microsoft Graph notifications
 */
export async function subscribe(crossDeviceAppId: string) {
    let localStorageToken = localStorage.getItem("token2");
    let tokens = {
        ownToken: localStorageToken
    };

    let token = tokens.ownToken;
    console.log("localStorageToken", localStorageToken);
    let serviceWorkerRegistration = await registerServiceWorker("service-worker.js");
    sendAccessTokenToServicerWorker(serviceWorkerRegistration, token);
    let pushSub = await getPushSubscription(serviceWorkerRegistration);

    console.log("push subscription", pushSub);

    let userNotificationClientWrapper = new UserNotificationClientWrapper(pushSub, token);
    await userNotificationClientWrapper.subscribeToUserNotificationsAsync(crossDeviceAppId);
    thisCopy.globalUserNotificationClientWrapper = userNotificationClientWrapper;
    console.log("globalUserNotificationClientWrapper is initialized...");
}

/**
 * Gets all notifications
 */
export async function getAllNotificationsAsync() {
    await thisCopy.globalUserNotificationClientWrapper.getAllNotificationsAsync();
}

/**
 * Updates the read state for a notification.
 */
export async function updateNotificationReadStateAsync() {
    let notificationId = prompt("notificationId:");
    let readState = JSON.parse(prompt("read state:")) as boolean;
    await thisCopy.globalUserNotificationClientWrapper.updateNotificationReadStateAsync(notificationId, readState);
}

/**
 * Updates the user action state for a notification.
 */
export async function updateNotificationUserActionStateAsync() {
    let notificationId = prompt("notificationId:");
    let userActionState = +prompt("user action state(None=0, Activated = 1, Dismissed = 2, Snoozed = 3");
    await thisCopy.globalUserNotificationClientWrapper.updateNotificationUserActionStateAsync(notificationId, userActionState);

}

/**
 * Deletes a notification.
 */
export async function deleteNotificationAsync() {
    let notificationId = prompt("notificationId (to be deleted):");
    await thisCopy.globalUserNotificationClientWrapper.deleteNotificationAsync(notificationId);
}

/**
 * Unsubscribes to receiving notification from Microsoft Graph notifications.
 */
export async function unsubscribeFromUserNotificationsAsync() {
    await thisCopy.globalUserNotificationClientWrapper.unsubscribeFromUserNotificationsAsync();
}

/** @ignore */
function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
        .replace(/\-/g, '+')
        .replace(/_/g, '/');

    const rawData = atob(base64);
    const outputArray = new Uint8Array(rawData.length);

    for (let i = 0; i < rawData.length; ++i) {
        outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
}