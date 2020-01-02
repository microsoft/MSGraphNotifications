//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//


#ifndef APNSToken_h
#define APNSToken_h

@interface GlobalApnsToken: NSObject
+(NSString *) apnsDeviceToken;
+(void) setGlobalApnsToken:(NSString*)apnsToken;
@end

#endif /* APNSToken_h */
