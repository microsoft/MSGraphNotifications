// Copyright (c) Microsoft. Licensed under the MIT License.

// Important Note for running this sample:
// The sample as-is will not be able to get auth tokens
// without having Application (client) ID and Redirect URI
// matching to a registered application in Microsoft Azure Portal.

namespace SDKTemplate
{
    public class Secrets
    {
        // Get the following from Microsoft Azure Portal (https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps)
        // AUTH_CLIENT_ID:         Application (client) ID
        // AUTH_REDIRECT_ID:       Redirect URI
        public static readonly string AUTH_CLIENT_ID = "<<enter value>>";
        public static readonly string AUTH_REDIRECT_ID = "<<enter value>>";
    }
}
