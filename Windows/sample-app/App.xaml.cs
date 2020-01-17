// Copyright (c) Microsoft. Licensed under the MIT License.

using Newtonsoft.Json;
using System;
using System.Diagnostics;
using Windows.ApplicationModel.Activation;
using Windows.ApplicationModel.Background;
using Windows.Networking.PushNotifications;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

// The Blank Application template is documented at http://go.microsoft.com/fwlink/?LinkId=402347&clcid=0x409

namespace SDKTemplate
{
    public class AppLauchArgs
    {
        public string Type { get; set; }
        public string NotificationId { get; set; }
    }

    /// <summary>
    /// Provides application-specific behavior to supplement the default Application class.
    /// </summary>
    sealed partial class App : Application
    {
        public GraphNotificationsManager NotificationsManager { get; set; } = new GraphNotificationsManager();

        /// <summary>
        /// Initializes the singleton application object.  This is the first line of authored code
        /// executed, and as such is the logical equivalent of main() or WinMain().
        /// </summary>
        public App()
        {
            this.InitializeComponent();
        }

        /// <summary>
        /// Invoked when the application is launched normally by the end user.  Other entry points
        /// will be used such as when the application is launched to open a specific file.
        /// </summary>
        /// <param name="e">Details about the launch request and process.</param>
        protected override async void OnLaunched(LaunchActivatedEventArgs e)
        {
#if DEBUG
            if (System.Diagnostics.Debugger.IsAttached)
            {
                this.DebugSettings.EnableFrameRateCounter = false;
            }
#endif
            Debug.WriteLine($"App Launched with {e.Arguments}");

            Frame rootFrame = Window.Current.Content as Frame;

            // Do not repeat app initialization when the Window already has content,
            // just ensure that the window is active
            if (rootFrame == null)
            {
                // Create a Frame to act as the navigation context and navigate to the first page
                rootFrame = new Frame
                {
                    // Set the default language
                    Language = Windows.Globalization.ApplicationLanguages.Languages[0]
                };

                rootFrame.NavigationFailed += OnNavigationFailed;

                if (e.PreviousExecutionState == ApplicationExecutionState.Terminated)
                {
                    // Load state from previously suspended application
                }

                // Place the frame in the current Window
                Window.Current.Content = rootFrame;
            }

            if (rootFrame.Content == null)
            {
                // When the navigation stack isn't restored navigate to the first page,
                // configuring the new page by passing required information as a navigation
                // parameter
                rootFrame.Navigate(typeof(MainPage), e.Arguments);
            }

            if (!string.IsNullOrEmpty(e.Arguments))
            {
                var result = JsonConvert.DeserializeObject<AppLauchArgs>(e.Arguments);
                await NotificationsManager.ActivateAsync(result.NotificationId, false);
            }

            // Ensure the current window is active
            Window.Current.Activate();
        }

        /// <summary>
        /// Invoked when Navigation to a certain page fails
        /// </summary>
        /// <param name="sender">The Frame which failed navigation</param>
        /// <param name="e">Details about the navigation failure</param>
        void OnNavigationFailed(object sender, NavigationFailedEventArgs e)
        {
            throw new Exception("Failed to load Page " + e.SourcePageType.FullName);
        }

        private BackgroundTaskDeferral deferral;
        protected override async void OnBackgroundActivated(BackgroundActivatedEventArgs args)
        {
            base.OnBackgroundActivated(args);
            deferral = args.TaskInstance.GetDeferral();
            args.TaskInstance.Canceled += (s, r) =>
            {
                Debug.WriteLine($"Task canceled for {r}");
                deferral.Complete();
            };

            Debug.WriteLine($"{args.TaskInstance.Task.Name} activated in background with {args.TaskInstance.TriggerDetails.GetType().ToString()}");

            if (args.TaskInstance.TriggerDetails is RawNotification)
            {
                var rawNotification = args.TaskInstance.TriggerDetails as RawNotification;
                Debug.WriteLine($"RawNotification received {rawNotification.Content}");

                if (NotificationsManager == null)
                {
                    NotificationsManager = new GraphNotificationsManager();
                }

                await NotificationsManager.HandlePushNotificationAsync(rawNotification.Content);
            }

            deferral.Complete();
            Debug.WriteLine($"Task completed");
        }
    }
}
