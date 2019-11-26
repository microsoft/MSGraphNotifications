# Sample App for running the Microsoft Graph notifications client library in your browser

## Getting Started

### Prerequisites

1. Have node and npm installed. More details [here](https://www.npmjs.com/get-npm)
2. [Install http-server](https://www.npmjs.com/package/http-server#installing-globally) **globally**: ``npm install http-server -g``

### Building the sample
1. ``npm install`` (most of the time, only once is enough)
1. ``npm run build``

### Running the sample
1. Build the sample (if is not built already).
1. Add the reply url ``http://localhost:8080/authreply.html`` (please see [this](https://github.com/AzureAD/microsoft-authentication-library-for-js/wiki/MSAL-JS:-1.2.0-beta.0#feature-iframes-support-and-performance-enhancements) for more details about the empty page for the reply url) to the redirect URIs list within the Authentication page of your Azure Active Directory client app registration.
1. Set the following values:
   - ``msalConfig.auth.clientId`` in index.html: this is the client ID of your Azure AD client app
   - `crossDeviceAppId` in index.html: this is the "cross-device domain name" that you have registered
     and verified in your Cross-Device App registration in Partner Center (https://partner.microsoft.com/dashboard )
1. Open command prompt, powershell, or git for windows and start the http-server (by running ``http-server``) within the folder of the sample app (i.e.: ~/repository-source-path/sample-app).
1. Open the page ``http://localhost:8080/index.html`` (check the port with the one given by http-server).
   - if the port is other than 8080 the 2nd step needs to be redone with the new given port. 
   - don't go to `http://localhost:8080/` without `index.html`, as that doesn't work
     in http-server.
1. Sign in with an Azure AD account.
   - see "Login with a personal Microsoft account (MSA)" below if you want to use that
     form of account.
1. Click Subscribe, then click Allow on the Chrome browser prompt regarding notification permission.
   - the JavaScript console can be opened to see the logs and results. Make sure that all the log levels are selected.
1. Click the other buttons to exercise the various functions.
   - as before, look in the JavaScript console for the logs and results.
1. Post a new notification from Graph explorer and see a notification popup. Click the popup to be redirected to https://docs.microsoft.com/en-us/graph/notifications-concept-overview

## How-to (mostly specific to Chrome and Firefox)
1. Login with a personal Microsoft account (MSA) instead of AAD:
   1. Change ``msalConfig.auth.authority`` to ``https://login.microsoftonline.com/consumers``
   1. Change ``requestObj.scopes`` to ``["https://activity.windows.com/useractivity.readwrite.createdbyapp"]``
   1. The clientId might need to be changed as well (in case 2 different apps are used) from the one used for an Azure AD account
   1. Reload the page

1. Unregister the service worker created by this app:
   - Chrome:
      1. Option 1: Go to Dev Tools -> Application -> Service Workers -> (The one that you want) Unregister. More details in [here](https://stackoverflow.com/a/41907900)
      2. Option 2: chrome://serviceworker-internals/. More details in [here (first option)](https://stackoverflow.com/a/47515250)
    - Firefox:
        - Go to ``about:serviceworkers`` and unregister the one that you want
    - It's necessary to unregister the service worker when signing out and then signing in as a different user, or to troubleshoot when a push notification is not received.

1. Check if Chrome has received a push notification: go to ``chrome://gcm-internals`` (Receive Message Log section). Also here the connection can be checked. More details in [Payload Encryption Issue](https://developers.google.com/web/fundamentals/push-notifications/common-issues-and-reporting-bugs#payload_encryption_issue)

1. Force the ``acquireTokenSilent`` to call Azure AD instead of waiting 1 hour until the cached token expires; The following are 2 options for doing it:
   1. one of key entry is deleted from the localStorage; more specially ``{"authority":"https://login.microsoftonline.com/consumers/","clientId":"..","scopes":"https://activity.windows.com/UserActivity.ReadWrite.CreatedByApp","homeAccountIdentifier":"…"};`` the one that has the scope set to ``activity.*.com`` (as there are 2 with the previous template)
   2. [forceRefresh flag](https://www.npmjs.com/package/msal#forcerefresh-to-skip-cache)

## Other tips

1. Getting duplicate push notifications? This is a known server-side issue in some cases.
   See the [README for the client itself](https://www.npmjs.com/package/@microsoft/user-notifications-client) to learn more. Look for the text starting with:
   > userNotificationApiImpl.processPushNotificationAsync(notificationPayload) may call back to the Graph notification server to fetch notification data

1. To look at the logs of the sample app and the client library, open the developer tools -> console.

1. Wondering how the reload of index.html is avoided? Please see [MSAL JS: 1.2.0 beta.0](https://github.com/AzureAD/microsoft-authentication-library-for-js/wiki/MSAL-JS:-1.2.0-beta.0)
