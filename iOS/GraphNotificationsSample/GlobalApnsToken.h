//  Copyright (c) Microsoft. Licensed under the MIT license.


#ifndef APNSToken_h
#define APNSToken_h

@interface GlobalApnsToken: NSObject
+(NSString *) apnsDeviceToken;
+(void) setApnsDeviceToken:(NSString*)apnsToken;
@end

#endif /* APNSToken_h */
