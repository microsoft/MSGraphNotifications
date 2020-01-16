// Copyright (c) Microsoft. Licensed under the MIT License.

using Microsoft.UserNotifications.Client;
using System;
using System.Collections.ObjectModel;
using Windows.UI;
using Windows.UI.Core;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;

namespace SDKTemplate
{
    class NotificationListItem
    {
        public string Id { get; set; }
        public string Title { get; set; }
        public string Content { get; set; }
        public bool UnreadState { get; set; }
        public string UserActionState { get; set; }
        public string Priority { get; set; }
        public string ExpirationTime { get; set; }
        public string ChangeTime { get; set; }
    }

    public class BoolColorConverter : IValueConverter
    {
        object IValueConverter.Convert(object value, Type targetType, object parameter, string language)
        {
            return new SolidColorBrush(((bool)value) ? Colors.Green : Colors.Red);
        }

        object IValueConverter.ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }

    public partial class NotificationsPage : Page
    {
        private MainPage rootPage;
        private ObservableCollection<NotificationListItem> activeNotifications = new ObservableCollection<NotificationListItem>();
        private GraphNotificationsManager notificationsManager;

        public NotificationsPage()
        {
            InitializeComponent();
            UnreadView.ItemsSource = activeNotifications;
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            rootPage = MainPage.Current;
            notificationsManager = ((App)Application.Current).NotificationsManager;
            RefreshButton.IsEnabled = (notificationsManager != null);
            if (notificationsManager != null)
            {
                Description.Text = "Welcome " + notificationsManager.SignedInAccount?.Username;
                if (notificationsManager.UserNotificationSubscriptionId != null)
                {
                    TextBox_SubscriptionId.Text = notificationsManager.UserNotificationSubscriptionId;
                }

                notificationsManager.CacheUpdated += Cache_CacheUpdated;
            }
            notificationsManager?.SubscribeAsync();
        }

        protected override void OnNavigatedFrom(NavigationEventArgs e)
        {
            if (notificationsManager != null)
            {
                notificationsManager.CacheUpdated -= Cache_CacheUpdated;
            }
        }

        private async void Cache_CacheUpdated(object sender, EventArgs e)
        {
            await Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                UpdateNotificationsView();
            });
        }

        private void UpdateNotificationsView()
        {
            activeNotifications.Clear();

            foreach (UserNotification notification in notificationsManager.HistoricalNotifications)
            {
                activeNotifications.Add(new NotificationListItem()
                {
                    Id = notification.Id,
                    Title = notification.AppNotificationId,
                    UnreadState = !notification.ReadState,
                    UserActionState = notification.UserActionState.ToString(),
                    Content = $"  Content: {notification.Payload.RawContent}",
                    Priority = $"  Priority: {notification.Priority.ToString()}",
                    ExpirationTime = $"  Expiry: {notification.ExpirationDateTime.ToLocalTime().ToString()}",
                    ChangeTime = $"  Last Updated: {notification.LastModifiedDateTime.ToLocalTime().ToString()}",
                });
            }

            if (notificationsManager.NewNotifications)
            {
                rootPage.NotifyUser("History is up-to-date. New notifications available", NotifyType.StatusMessage);
            }
            else
            {
                rootPage.NotifyUser("History is up-to-date", NotifyType.StatusMessage);
            }
        }

        private async void Button_Refresh(object sender, RoutedEventArgs e)
        {
            await notificationsManager.RefreshAsync();
        }

        private async void Button_MarkRead(object sender, RoutedEventArgs e)
        {
            var item = ((Grid)((Border)((Button)sender).Parent).Parent).DataContext as NotificationListItem;
            await notificationsManager.MarkReadAsync(item.Id);
        }

        private async void Button_Delete(object sender, RoutedEventArgs e)
        {
            var item = ((Grid)((Border)((Button)sender).Parent).Parent).DataContext as NotificationListItem;
            await notificationsManager.DeleteAsync(item.Id);
        }
    }
}