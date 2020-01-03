//  Copyright (c) Microsoft. Licensed under the MIT license.

#pragma once

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIButton* msaButton;
@property (strong, nonatomic) IBOutlet UIButton* aadButton;
@property (strong, nonatomic) IBOutlet UILabel* loginStatusLabel;
- (IBAction)loginMSA;
- (IBAction)loginAAD;
@end

