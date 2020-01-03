//  Copyright (c) Microsoft. Licensed under the MIT license.

#import "LoginViewController.h"
#import <MSAL/MSAL.h>
#import "AppDelegate.h"
#import "Secrets.h"
typedef NS_ENUM(NSInteger, LoginState) {
    AAD,
    MSA,
    SIGNED_OUT
};

@implementation LoginViewController {
    LoginState loginState;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    
    [self _setButtonTextAndVisibilityForState:[self _getState]];
}

- (IBAction)loginMSA {
    LoginState state = [self _getState];
    
    if (state == SIGNED_OUT) {
        [self _setStatusText:@"Signing in MSA..."];
        [self loginInternal:MSA finishBlock:^(NSError *error, NSString* accessToken) {
            if (!error)
            {
                // You'll want to get the account identifier to retrieve and reuse the account
                // for later acquireToken calls
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.manager = [appDelegate.manager initWithAccount:accessToken];
                if(appDelegate.manager)
                {
                    [self _setButtonTextAndVisibilityForState:MSA];
                    [self _setState:MSA];
                }
                else
                {
                    [self _setStatusText:[NSString stringWithFormat:@"Initialization of the notifications manager failed!"]];
                }
            }
            else
            {
                [self _setStatusText:[NSString stringWithFormat:@"MSA sign-in failed with error %@", error]];
            }
        }];
    } else {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [[appDelegate.manager userNotificationApi] setOAuthAccessToken:nil];
        [self _setButtonTextAndVisibilityForState:SIGNED_OUT];
        //MSAL does not have an invalidate/remove token, so we just make the access token nil so calls will fail if logged out. This is equivalent to signing out.
    }
}

-(void)loginInternal:(LoginState)accountToLogin finishBlock:(void (^)(NSError* error, NSString* accessToken))finishBlock
{
    NSError* msalError = [[NSError alloc] init];
    MSALAuthority* authority;
    MSALPublicClientApplicationConfig *config;
    NSArray<NSString *> *scopes;
    if(accountToLogin==AAD)
    {
        authority = [MSALAuthority authorityWithURL:[NSURL URLWithString:@"https://login.microsoftonline.com/common/oauth2"] error:&msalError];
        config = [[MSALPublicClientApplicationConfig alloc] initWithClientId:APPLICATION_CLIENT_ID];
        scopes = @[@"https://activity.microsoft.com/UserActivity.ReadWrite.CreatedByApp", @"https://activity.microsoft.com/Notifications.ReadWrite.CreatedByApp"];
    }
    else if(accountToLogin==MSA)
    {
        authority = [MSALAuthority authorityWithURL:[NSURL URLWithString:@"https://login.microsoftonline.com/consumers/"] error:&msalError];
        config = [[MSALPublicClientApplicationConfig alloc] initWithClientId:APPLICATION_CLIENT_ID];
        scopes = @[@"https://activity.windows.com/UserActivity.ReadWrite.CreatedByApp", @"https://activity.windows.com/Notifications.ReadWrite.CreatedByApp"];
    }
    
    MSALWebviewParameters* params = [[MSALWebviewParameters alloc] initWithParentViewController:self];
    MSALPublicClientApplication *application = [[MSALPublicClientApplication alloc] initWithConfiguration:config error:&msalError];
    MSALInteractiveTokenParameters *interactiveParams = [[MSALInteractiveTokenParameters alloc] initWithScopes:scopes webviewParameters:params];
    interactiveParams.authority = authority;
    interactiveParams.promptType = MSALPromptTypeSelectAccount;
    [application acquireTokenWithParameters:interactiveParams completionBlock:^(MSALResult *result, NSError *error) {
        if (!error)
        {
            finishBlock(nil, result.accessToken);
        }
        else
        {
            finishBlock(error, nil);
        }
    }];

}

- (IBAction)loginAAD {
    LoginState state = [self _getState];

    if (state == SIGNED_OUT) {
        [self _setStatusText:@"Signing in AAD..."];
        [self loginInternal:AAD finishBlock:^(NSError *error, NSString* accessToken) {
            if (!error)
            {
                // You'll want to get the account identifier to retrieve and reuse the account
                // for later acquireToken calls
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.manager = [appDelegate.manager initWithAccount:accessToken];
                if(appDelegate.manager)
                {
                    [self _setButtonTextAndVisibilityForState:AAD];
                    [self _setState:AAD];
                }
                else
                {
                    [self _setStatusText:[NSString stringWithFormat:@"Initialization of the notifications manager failed!"]];
                }
            }
            else
            {
                [self _setStatusText:[NSString stringWithFormat:@"AAD sign-in failed with error %@", error]];
            }
        }];
    } else {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [[appDelegate.manager userNotificationApi] setOAuthAccessToken:nil];
        [self _setButtonTextAndVisibilityForState:SIGNED_OUT];
        //MSAL does not have an invalidate/remove token, so we just make the access token nil so calls will fail if logged out. This is equivalent to signing out.
    }

}

- (LoginState)_getState {
    return self->loginState;
}
-(void)_setState:(LoginState)state
{
    self->loginState = state;
}

- (void)_setButtonTextAndVisibilityForState:(LoginState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
           switch (state) {
               case SIGNED_OUT:
                   [self.aadButton setTitle:@"Login with AAD" forState:UIControlStateNormal];
                   [self.msaButton setTitle:@"Login with MSA" forState:UIControlStateNormal];
                   self.aadButton.hidden = FALSE;
                   self.msaButton.hidden = FALSE;
                   self.loginStatusLabel.text = @"Currently signed-out";
                   break;
               case AAD:
                   [self.aadButton setTitle:@"Logout" forState:UIControlStateNormal];
                   [self.msaButton setTitle:@"" forState:UIControlStateNormal];
                   self.msaButton.hidden = TRUE;
                   self.loginStatusLabel.text = @"Currently signed-in with AAD";
                   break;
               case MSA:
                   [self.aadButton setTitle:@"" forState:UIControlStateNormal];
                   [self.msaButton setTitle:@"Logout" forState:UIControlStateNormal];
                   self.aadButton.hidden = TRUE;
                   self.loginStatusLabel.text = @"Currently signed-in with MSA";
                   break;
           }
       });
}

- (void)_setStatusText:(NSString*)text {
    NSLog(@"%@", text);
    dispatch_async(dispatch_get_main_queue(), ^{ self.loginStatusLabel.text = text; });
}

@end
