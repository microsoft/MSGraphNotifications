// Copyright (c) Microsoft. Licensed under the MIT License.

using Microsoft.Identity.Client;
using Microsoft.UserNotifications.Client;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Windows.Data.Xml.Dom;
using Windows.Networking.PushNotifications;
using Windows.Storage;

namespace SDKTemplate
{
    public class GraphNotificationsManager
    {
        static readonly IReadOnlyList<string> AadScopes = new List<string>
        {
            "https://activity.microsoft.com/Notifications.ReadWrite.CreatedByApp"
        };
        static readonly IReadOnlyList<string> MsaScopes = new List<string>
        {
            "https://activity.windows.com/Notifications.ReadWrite.CreatedByApp"
        };

        private readonly MainPage rootPage;
        private IPublicClientApplication authClient;
        private UserNotificationApi apiClient;
        private ApplicationDataContainer localSettings = ApplicationData.Current.LocalSettings;

        public event EventHandler CacheUpdated;

        private List<UserNotification> historicalNotifications = new List<UserNotification>();
        public IReadOnlyList<UserNotification> HistoricalNotifications
        {
            get
            {
                return historicalNotifications.AsReadOnly();
            }
        }

        public bool NewNotifications { get; private set; }

        public IAccount SignedInAccount { get; private set; } = null;

        public bool IsMSA { get; private set; }

        public string UserNotificationSubscriptionId { get; private set; } = null;

        public GraphNotificationsManager()
        {
            rootPage = MainPage.Current;
            CheckAccounts();
        }

        public void Reset()
        {
            SignedInAccount = null;
            UserNotificationSubscriptionId = null;
            apiClient = null;
            historicalNotifications.Clear();
            localSettings.Values.Clear();
            CacheUpdated?.Invoke(this, new EventArgs());
        }

        public async Task<bool> SignInAAD()
        {
            try
            {
                IsMSA = false;
                authClient = PublicClientApplicationBuilder.Create(Secrets.AUTH_CLIENT_ID)
                    .WithAuthority("https://login.microsoftonline.com/organizations")
                    .WithRedirectUri(Secrets.AUTH_REDIRECT_ID)
                    .Build();
                var authResult = await authClient.AcquireTokenInteractive(AadScopes).ExecuteAsync();
                Debug.WriteLine($"Sign-in successful for {authResult.Account.Username}, token={authResult.AccessToken}");
                SignedInAccount = authResult.Account;
                apiClient = new UserNotificationApi(authResult.AccessToken);
                localSettings.Values["AccountType"] = "AAD";
                return true;
            }
            catch (Exception error)
            {
                Debug.WriteLine($"Sign-in failed; Error={error.Message}", NotifyType.ErrorMessage);
                return false;
            }
        }

        public async Task<bool> SignInMSA()
        {
            try
            {
                IsMSA = true;
                authClient = PublicClientApplicationBuilder.Create(Secrets.AUTH_CLIENT_ID)
                    .WithAuthority("https://login.microsoftonline.com/consumers")
                    .WithRedirectUri(Secrets.AUTH_REDIRECT_ID)
                    .Build();
                var authResult = await authClient.AcquireTokenInteractive(MsaScopes).ExecuteAsync();
                Debug.WriteLine($"Sign-in successful for {authResult.Account.Username}, token = {authResult.AccessToken}");
                SignedInAccount = authResult.Account;
                apiClient = new UserNotificationApi(authResult.AccessToken);
                localSettings.Values["AccountType"] = "MSA";
                return true;
            }
            catch (Exception error)
            {
                Debug.WriteLine($"Sign-in failed; Error={error.Message}", NotifyType.ErrorMessage);
                return false;
            }
        }

        public async Task SubscribeAsync()
        {
            PushNotificationChannel channel = await PushNotificationChannelManager.CreatePushNotificationChannelForApplicationAsync();
            channel.PushNotificationReceived += PushNotificationReceived;
            var result = await apiClient.SubscribeToUserNotificationsAsync(channel);
            if (result.Status != UserNotificationApiResultStatus.Succeeded)
            {
                throw new Exception($"GraphNotificationsSample failed to subscribe for notifications, status: {result.Status}");
            }
            else
            {
                // Save the last good subscription
                rootPage?.NotifyUser($"GraphNotificationsSample subscribed with {result.UserNotificationSubscriptionId} valid till {result.ExpirationDateTime}");

                UserNotificationSubscriptionId = result.UserNotificationSubscriptionId;

                // This App should send "UserNotificationSubscriptionId" to its appservice.
                // Appservice can use UserNotificationSubscriptionId to POST new notification
                // to https://graph.microsoft.com/beta/me/notifications without OAuth tokens.
            }
        }

        public async Task RefreshAsync()
        {
            historicalNotifications.Clear();

            var result = await apiClient.GetAllNotificationsAsync();
            rootPage?.NotifyUser($"GraphNotificationsSample refresh completed with status: {result.Status}, count = {result.UserNotifications?.Count}");

            if (result.Status == UserNotificationApiResultStatus.FailedDueToInvalidAccessToken)
            {
                RenewAccessToken();

                // Try the same call again
                result = await apiClient.GetAllNotificationsAsync();
            }

            if (result.Status != UserNotificationApiResultStatus.Succeeded)
            {
                throw new Exception($"GraphNotificationsSample failed to subscribe for notifications, status: {result.Status}");
            }

            UpdateCache(result.UserNotifications);
        }

        public async Task HandlePushNotificationAsync(string content)
        {
            CheckAccounts();

            var result = await apiClient.ProcessPushNotificationAsync(content);
            rootPage?.NotifyUser($"GraphNotificationsSample push handled with status: {result.Status}");

            if (result.Status == UserNotificationApiResultStatus.FailedDueToInvalidAccessToken)
            {
                RenewAccessToken();

                // Try the same call again
                result = await apiClient.ProcessPushNotificationAsync(content);
            }

            if (result.Status != UserNotificationApiResultStatus.Succeeded)
            {
                throw new Exception($"GraphNotificationsSample failed to subscribe for notifications, status: {result.Status}");
            }

            if (result.IsUserNotificationPush)
            {
                UpdateCache(result.UserNotifications);
            }
        }

        public async Task ActivateAsync(string id, bool dismiss)
        {
            var notification = historicalNotifications.Find((n) => { return (n.Id == id); });
            if (notification != null)
            {
                var newState = dismiss ? UserNotificationUserActionState.Dismissed : UserNotificationUserActionState.Activated;
                await apiClient.UpdateNotificationUserActionStateAsync(notification.Id, newState);
                RemoveToastNotification(notification.Id);
                rootPage?.NotifyUser($"{notification.Id} is now " + (dismiss ? "DISMISSED" : "ACTIVATED"));
            }
        }

        public async Task MarkReadAsync(string id)
        {
            var notification = historicalNotifications.Find((n) => { return (n.Id == id); });
            if (notification != null)
            {
                await apiClient.UpdateNotificationReadStateAsync(notification.Id, true);
                rootPage?.NotifyUser($"{notification.Id} is now READ");
            }
        }

        public async Task DeleteAsync(string id)
        {
            var notification = historicalNotifications.Find((n) => { return (n.Id == id); });
            if (notification != null)
            {
                await apiClient.DeleteNotificationAsync(notification.Id);
                rootPage?.NotifyUser($"{notification.Id} is now DELETED");
            }
        }

        private async void CheckAccounts()
        {
            if (SignedInAccount == null)
            {
                if (authClient == null)
                {
                    authClient = PublicClientApplicationBuilder.Create(Secrets.AUTH_CLIENT_ID).Build();
                }

                var accounts = await authClient.GetAccountsAsync();
                var firstAccount = accounts.FirstOrDefault();
                if (firstAccount != null)
                {
                    Debug.WriteLine($"Account found {firstAccount.Username}");

                    SignedInAccount = firstAccount;

                    if (localSettings.Values.ContainsKey("AccountType"))
                    {
                        var accountType = localSettings.Values["AccountType"] as string;
                        IsMSA = accountType.Equals("MSA");

                        if (apiClient == null)
                        {
                            IReadOnlyList<string> scopes = IsMSA ? MsaScopes : AadScopes;
                            var authResult = await authClient.AcquireTokenSilent(scopes, SignedInAccount).ExecuteAsync();
                            apiClient = new UserNotificationApi(authResult.AccessToken);
                        }
                    }
                }
            }
        }

        private async void RenewAccessToken()
        {
            if (SignedInAccount != null)
            {
                IReadOnlyList<string> scopes = IsMSA ? MsaScopes : AadScopes;
                var authResult = await authClient.AcquireTokenSilent(scopes, SignedInAccount).ExecuteAsync();
                apiClient.OAuthAccessToken = authResult.AccessToken;
            }
        }

        private async void PushNotificationReceived(PushNotificationChannel sender, PushNotificationReceivedEventArgs args)
        {
            if (args.NotificationType == PushNotificationType.Raw)
            {
                Debug.WriteLine($"PushNotificationReceived {args.RawNotification.Content}");
                await HandlePushNotificationAsync(args.RawNotification.Content);
            }
        }

        private void UpdateCache(IReadOnlyList<UserNotification> notifications)
        {
            Debug.WriteLine($"Updating cache with {notifications?.Count} notifications");
            foreach (var notification in notifications)
            {
                if (notification.Status != UserNotificationStatus.Deleted)
                {
                    if (notification.UserActionState == UserNotificationUserActionState.None)
                    {
                        // Brand new notification
                        NewNotifications = true;
                        Debug.WriteLine($"UserNotification not interacted: {notification.Id}");
                        if (!string.IsNullOrEmpty(notification.Payload.RawContent) && !notification.ReadState)
                        {
                            RemoveToastNotification(notification.Id);
                            ShowToastNotification(BuildToastNotification(notification.Id, notification.AppNotificationId,notification.Payload.RawContent));
                        }
                    }
                    else
                    {
                        RemoveToastNotification(notification.Id);
                    }

                    historicalNotifications.RemoveAll((n) => { return (n.Id == notification.Id); });
                    historicalNotifications.Insert(0, notification);
                }
                else
                {
                    // Historical notification is marked as deleted, remove from display
                    historicalNotifications.RemoveAll((n) => { return (n.Id == notification.Id); });
                    RemoveToastNotification(notification.Id);
                }
            }

            CacheUpdated?.Invoke(this, new EventArgs());
        }

        // Raise a new toast with UserNotification.Id as tag
        private void ShowToastNotification(Windows.UI.Notifications.ToastNotification toast)
        {
            var toastNotifier = Windows.UI.Notifications.ToastNotificationManager.CreateToastNotifier();
            toast.Activated += async (s, e) => await ActivateAsync(s.Tag, false);
            toastNotifier.Show(toast);
        }

        // Remove a toast with UserNotification.Id as tag
        private void RemoveToastNotification(string notificationId)
        {
            Windows.UI.Notifications.ToastNotificationManager.History.Remove(notificationId);
        }

        public static Windows.UI.Notifications.ToastNotification BuildToastNotification(string notificationId, string title, string content)
        {
            XmlDocument toastXml = Windows.UI.Notifications.ToastNotificationManager.GetTemplateContent(Windows.UI.Notifications.ToastTemplateType.ToastText02);
            XmlNodeList toastNodeList = toastXml.GetElementsByTagName("text");
            toastNodeList.Item(0).AppendChild(toastXml.CreateTextNode(title));
            toastNodeList.Item(1).AppendChild(toastXml.CreateTextNode(content));
            IXmlNode toastNode = toastXml.SelectSingleNode("/toast");
            ((XmlElement)toastNode).SetAttribute("launch", "{\"type\":\"toast\",\"notificationId\":\"" + notificationId + "\"}");
            XmlElement audio = toastXml.CreateElement("audio");
            audio.SetAttribute("src", "ms-winsoundevent:Notification.SMS");
            return new Windows.UI.Notifications.ToastNotification(toastXml)
            {
                Tag = notificationId
            };
        }
    }
}
