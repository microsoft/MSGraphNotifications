﻿// Copyright (c) Microsoft. Licensed under the MIT License.

using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Background;
using Windows.UI.Core;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;

// The Blank Page item template is documented at http://go.microsoft.com/fwlink/?LinkId=402352&clcid=0x409

namespace SDKTemplate
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class MainPage : Page
    {
        public static MainPage Current;
        static readonly string PushTaskName = "GraphNotificationsPush";

        public MainPage()
        {
            this.InitializeComponent();

            // This is a static public property that allows downstream pages to get a handle to the MainPage instance
            // in order to call methods that are in this class.
            Current = this;
            SampleTitle.Text = FEATURE_NAME;
        }

        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            // Applications must have lock screen privileges in order to receive raw notifications 
            BackgroundAccessStatus backgroundStatus = await BackgroundExecutionManager.RequestAccessAsync();

            // Make sure the user allowed privileges 
            if (backgroundStatus != BackgroundAccessStatus.DeniedByUser &&
                backgroundStatus != BackgroundAccessStatus.DeniedBySystemPolicy &&
                backgroundStatus != BackgroundAccessStatus.Unspecified)
            {
                RegisterBackgroundTask();
            }
            else
            {
                NotifyUser("Background access is denied", NotifyType.ErrorMessage);
            }

            // Populate the scenario list from the SampleConfiguration.cs file
            ScenarioControl.ItemsSource = scenarios;

            // Go to NotificationsPage if launched from Toast
            ScenarioControl.SelectedIndex = string.IsNullOrEmpty(e.Parameter as string) ? 0 : 1;
        }

        private void RegisterBackgroundTask()
        {
            // Unregister first
            UnregisterBackgroundTask();

            try
            {
                BackgroundTaskBuilder taskBuilder = new BackgroundTaskBuilder
                {
                    Name = PushTaskName
                };

                // Do not set BackgroundTaskBuilder.TaskEntryPoint for in-process background tasks
                // Here we register the task and work will start based on the time trigger.

                taskBuilder.SetTrigger(new PushNotificationTrigger());

                BackgroundTaskRegistration task = taskBuilder.Register();
            }
            catch (Exception ex)
            {
                NotifyUser("BackgroundTaskRegistration error: " + ex.Message, NotifyType.ErrorMessage);
                UnregisterBackgroundTask();
            }
        }

        private bool UnregisterBackgroundTask()
        {
            foreach (var iter in BackgroundTaskRegistration.AllTasks)
            {
                IBackgroundTaskRegistration task = iter.Value;
                if (task.Name == PushTaskName)
                {
                    task.Unregister(true);
                    return true;
                }
            }
            return false;
        }

        /// <summary>
        /// Called whenever the user changes selection in the scenarios list.  This method will navigate to the respective
        /// sample scenario page.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void ScenarioControl_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            // Clear the status block when navigating scenarios.
            NotifyUser(String.Empty, NotifyType.StatusMessage);

            ListBox scenarioListBox = sender as ListBox;
            Scenario s = scenarioListBox.SelectedItem as Scenario;
            if (s != null)
            {
                ScenarioFrame.Navigate(s.ClassType);
                if (Window.Current.Bounds.Width < 640)
                {
                    Splitter.IsPaneOpen = false;
                }
            }
        }

        public List<Scenario> Scenarios
        {
            get { return this.scenarios; }
        }

        /// <summary>
        /// Used to display messages to the user
        /// </summary>
        /// <param name="strMessage"></param>
        /// <param name="type"></param>
        public async void NotifyUser(string strMessage, NotifyType type = NotifyType.StatusMessage)
        {
            await Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                switch (type)
                {
                    case NotifyType.StatusMessage:
                        StatusBorder.Background = new SolidColorBrush(Windows.UI.Colors.Green);
                        break;
                    case NotifyType.ErrorMessage:
                        StatusBorder.Background = new SolidColorBrush(Windows.UI.Colors.Red);
                        break;
                }
                StatusBlock.Text = strMessage;

                // Collapse the StatusBlock if it has no text to conserve real estate.
                StatusBorder.Visibility = (StatusBlock.Text != String.Empty) ? Visibility.Visible : Visibility.Collapsed;
                if (StatusBlock.Text != String.Empty)
                {
                    StatusBorder.Visibility = Visibility.Visible;
                    StatusPanel.Visibility = Visibility.Visible;
                }
                else
                {
                    StatusBorder.Visibility = Visibility.Collapsed;
                    StatusPanel.Visibility = Visibility.Collapsed;
                }
            });
        }

        async void Footer_Click(object sender, RoutedEventArgs e)
        {
            await Windows.System.Launcher.LaunchUriAsync(new Uri(((HyperlinkButton)sender).Tag.ToString()));
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            Splitter.IsPaneOpen = !Splitter.IsPaneOpen;
        }
    }

    public enum NotifyType
    {
        StatusMessage,
        ErrorMessage
    };

    public class ScenarioBindingConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            Scenario s = value as Scenario;
            return (MainPage.Current.Scenarios.IndexOf(s) + 1) + ") " + s.Title;
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            return true;
        }
    }
}
