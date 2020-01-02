//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "GlobalApnsToken.h"
@implementation GlobalApnsToken
static NSString *g_apnsToken = 0;
+(NSString *) apnsDeviceToken {
    @synchronized ([GlobalApnsToken class]) {
        if (!g_apnsToken)
        {
            g_apnsToken = [NSString string];
        }
        return g_apnsToken;
    }
}
+(void) setGlobalApnsToken:(NSString*)apnsToken
{
    g_apnsToken = apnsToken;
}
@end

