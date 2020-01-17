# Sample App for running the Microsoft Graph notifications client library for Windows applications

## Getting Started

### Prerequisites

1. Be running Windows 10 version 1703, the Creators Update, or later.
1. Install Visual Studio and the Windows 10 SDK for version 1903,
   the May 2019 update (build 10.0.18362).
1. Follow the on-boarding steps for a Graph notifications application,
   including the cross-device app registration in Microsoft Partner Center
   and the Azure Active Directory app registration in Azure Portal.

### Building the sample app
1. Update [`Secrets.cs`](Secrets.cs) with the following values from your
   Azure AD app registration in Azure Portal:
   * `AUTH_CLIENT_ID`: this is the client ID of your Azure AD client app
   * `AUTH_REDIRECT_ID`: this is a redirect URL set up for your Azure AD client app
1. Use Visual Studio (recommended) or MSBuild.exe to build.

Note that if you use MSBuild from the command line, you might see errors
that the .appx package for the sample application could not be signed
because the signing certificate is missing. This is OK as you don't need to [sign the package](https://docs.microsoft.com/windows/msix/package/signing-package-overview)
until you distribute it or upload it to the Microsoft Store; to test the
application you can [register and run it from an unpackaged binary
"layout"](https://docs.microsoft.com/windows/uwp/debug-test-perf/loose-file-registration).

### Running the sample app
1. Start it from Visual Studio (recommended) or by registering the binaries built by MSBuild.
   * If the app crashes on startup with an "client ID is not a GUID" error,
     check that you've updated `Secrets.cs` as in the "Building the sample app" section.
1. Sign in with an Azure AD account or personal Microsoft account.
1. Navigate to the Notifications tab and click the "Refresh History" button to display
   a history of past notifications.
1. Exercise the various functions offered for each notification in the history.
1. Post a new notification from Graph explorer. You might not see a notification popup
   immediately, but if you click "Refresh History" then it will appear.

## Other tips

1. Getting duplicate push notifications? This is a known server-side issue in some cases.
   See the [README for the web client](https://www.npmjs.com/package/@microsoft/user-notifications-client) to learn more. Look for the text starting with:
   > userNotificationApiImpl.processPushNotificationAsync(notificationPayload) may call back to the Graph notification server to fetch notification data
