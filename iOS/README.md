# Sample App for running the Microsoft Graph notifications client library in your iOS application

## Getting Started

### Prerequisites

1. Have xCode and Cocoapods installed installed. More details [here](https://cocoapods.org/)

### Building the sample
1. ``pod install`` (from directory of podfile)
2. ``build from xCode``

### Running the sample
1. Build the sample (if is not built already).
1. Initialize and setup MSAL using the directions given [here](https://github.com/AzureAD/microsoft-authentication-library-for-objc) 
1. Set the following values:
- ``APPLICATION_CLIENT_ID`` in Secrets.h: this is the client ID of your Azure AD client app
- ``APP_HOST_NAME`` in secrets.h: this is the "cross-device domain name" that you have registered
and verified in your Cross-Device App registration in Partner Center (https://partner.microsoft.com/dashboard )
2. Sign in with an Azure AD or MSA account.
3. Click Subscribe, then grant permissions for the iOS app to read and write notifications.
4. Click the other buttons to exercise the various functions.
5. Post a new notification from Graph explorer and see a notification popup. Click the popup to be redirected to https://docs.microsoft.com/en-us/graph/notifications-concept-overview
## Other tips

1. Getting duplicate push notifications? This is a known server-side issue in some cases.
See the [README for the client itself](https://www.npmjs.com/package/@microsoft/user-notifications-client) to learn more. Look for the text starting with:
> userNotificationApiImpl.processPushNotificationAsync(notificationPayload) may call back to the Graph notification server to fetch notification data

1. To look at the logs of the sample app and the client library, the best way to do it is to set the xCode environment variable
``CFNETWORK_DIAGNOSTICS`` = 3

