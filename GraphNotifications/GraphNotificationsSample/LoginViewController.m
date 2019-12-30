//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//

#import "LoginViewController.h"

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
        /*TODO: sign in with MSAL then
         [self _setButtonTextAndVisibilityForState:MSA];
         [self _setState:MSA];
         AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
         [appdelegate.notificationsManager initWithAccountId];
         
         /*
         
    } else {
        //TODO: Sign out with MSAL
        [self _setStatusText:[NSString stringWithFormat:@"Currently signed out"]];
        [self _setButtonTextAndVisibilityForState:SIGNED_OUT];
        /* TODO: sign out with MSAL, this is if sign out fails
        [self _setStatusText:[NSString stringWithFormat:@"MSA sign-out failed!"]];
         */
    }
}

- (IBAction)loginAAD {
    LoginState state = [self _getState];
    
    if (state == SIGNED_OUT) {
        [self _setStatusText:@"Signing in AAD..."];
        /*TODO: sign in with MSAL then
         [self _setButtonTextAndVisibilityForState:AAD];
         [self _setState:AAD];
         /*
    } else {
        //TODO: Sign out with MSAL
        /* Call when signed out successfully
            [self _setStatusText:[NSString stringWithFormat:@"Currently signed out"]];
            [self _setButtonTextAndVisibilityForState:SIGNED_OUT];
         /*
        /* TODO: sign out with MSAL, this is if sign out fails
         [self _setStatusText:[NSString stringWithFormat:@"MSA sign-out failed!"]];
         */
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
