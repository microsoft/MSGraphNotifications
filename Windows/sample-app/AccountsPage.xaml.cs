// Copyright (c) Microsoft. Licensed under the MIT License.

using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace SDKTemplate
{
    enum LoginState
    {
        LoginProgress,
        LoggedInMsa,
        LoggedInAad,
        LoggedOut
    }

    public sealed partial class AccountsPage : Page
    {
        private MainPage rootPage;
        private GraphNotificationsManager notificationsManager;
        private LoginState state = LoginState.LoggedOut;

        public AccountsPage()
        {
            this.InitializeComponent();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            rootPage = MainPage.Current;
            notificationsManager = ((App)Application.Current).NotificationsManager;
            UpdateView(GetCurrentLoginState());
        }

        private void ConnectedDevicesManager_AccountsChanged(object sender, System.EventArgs e)
        {
            UpdateView(GetCurrentLoginState());
        }

        private async void Button_LoginMSA(object sender, RoutedEventArgs e)
        {
            if (state == LoginState.LoggedOut)
            {
                UpdateView(LoginState.LoginProgress);
                bool success = await notificationsManager.SignInMSA();
                if (!success)
                {
                    rootPage.NotifyUser("MSA login failed!", NotifyType.ErrorMessage);
                    UpdateView(LoginState.LoggedOut);
                }
                else
                {
                    rootPage.NotifyUser("MSA login successful", NotifyType.StatusMessage);
                    UpdateView(LoginState.LoggedInMsa);
                }
            }
            else
            {
                LogoutCurrentAccount();
            }
        }

        private async void Button_LoginAAD(object sender, RoutedEventArgs e)
        {
            if (state == LoginState.LoggedOut)
            {
                UpdateView(LoginState.LoginProgress);
                bool success = await notificationsManager.SignInAAD();
                if (!success)
                {
                    rootPage.NotifyUser("AAD login failed!", NotifyType.ErrorMessage);
                    UpdateView(LoginState.LoggedOut);
                }
                else
                {
                    rootPage.NotifyUser("AAD login successful", NotifyType.StatusMessage);
                    UpdateView(LoginState.LoggedInAad);
                }
            }
            else
            {
                LogoutCurrentAccount();
            }
        }

        private void LogoutCurrentAccount()
        {
            UpdateView(LoginState.LoggedOut);
            notificationsManager.Reset();
            rootPage.NotifyUser("Logged out", NotifyType.ErrorMessage);
        }

        private LoginState GetCurrentLoginState()
        {
            LoginState currentState = LoginState.LoggedOut;
            if (notificationsManager.SignedInAccount != null)
            {
                currentState = notificationsManager.IsMSA ? LoginState.LoggedInMsa : LoginState.LoggedInAad;
            }
            return currentState;
        }

        private void UpdateView(LoginState state)
        {
            this.state = state;

            switch (state)
            {
                case LoginState.LoggedOut:
                    AadButton.IsEnabled = true;
                    AadButton.Content = "Login with AAD";
                    MsaButton.IsEnabled = true;
                    MsaButton.Content = "Login with MSA";
                    break;

                case LoginState.LoginProgress:
                    AadButton.IsEnabled = false;
                    AadButton.Content = "Logging In";
                    MsaButton.IsEnabled = false;
                    MsaButton.Content = "Logging In";
                    break;

                case LoginState.LoggedInAad:
                    AadButton.IsEnabled = true;
                    AadButton.Content = "Log Out";
                    MsaButton.IsEnabled = false;
                    MsaButton.Content = "Login with MSA";
                    break;

                case LoginState.LoggedInMsa:
                    MsaButton.IsEnabled = true;
                    MsaButton.Content = "Log Out";
                    AadButton.IsEnabled = false;
                    AadButton.Content = "Login with AAD";
                    break;
            }
        }

    }
}
