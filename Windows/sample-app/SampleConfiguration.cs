// Copyright (c) Microsoft. Licensed under the MIT License.

using System;
using System.Collections.Generic;
using Windows.UI.Xaml.Controls;

namespace SDKTemplate
{
    public partial class MainPage : Page
    {
        public const string FEATURE_NAME = "Graph Notifications";

        List<Scenario> scenarios = new List<Scenario>
        {
            new Scenario() { Title="Accounts", ClassType=typeof(AccountsPage)},
            new Scenario() { Title="Notifications", ClassType=typeof(NotificationsPage)},
        };
    }

    public class Scenario
    {
        public string Title { get; set; }
        public Type ClassType { get; set; }
    }
}
