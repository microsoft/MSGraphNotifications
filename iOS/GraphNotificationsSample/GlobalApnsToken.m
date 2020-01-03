//  Copyright (c) Microsoft. Licensed under the MIT license.



#import <Foundation/Foundation.h>
#import "GlobalApnsToken.h"
@implementation GlobalApnsToken
static NSString *apnsToken = 0;
+(NSString *) apnsDeviceToken {
    @synchronized ([GlobalApnsToken class]) {
        if (!apnsToken)
        {
            apnsToken = [NSString string];
        }
        return apnsToken;
    }
}
+(void) setApnsDeviceToken:(NSString*)apnsToken
{
    apnsToken = apnsToken;
}
@end

