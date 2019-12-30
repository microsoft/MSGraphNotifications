//
//  APNSToken.m
//  GraphNotificationsSample
//
//  Created by Adam Crabtree on 12/27/19.
//  Copyright © 2019 Microsoft. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "APNSToken.h"
@implementation APNSToken
static APNSToken* _APNSToken;
static NSString* apnsToken;
+(id)accessToken{
    @synchronized ([APNSToken class]) {
        if(!_APNSToken)
        {
            _APNSToken = [[self alloc]init];
        }
        return _APNSToken;
    }
    return nil;
}
-(void)setAccessToken:(NSString*)token
{
    apnsToken = token;
}
-(NSString*)getAccessToken
{
    return apnsToken;
}

@end
