//
//  APNSToken.h
//  GraphNotificationsSample
//
//  Created by Adam Crabtree on 12/27/19.
//  Copyright © 2019 Microsoft. All rights reserved.
//

#ifndef APNSToken_h
#define APNSToken_h

@interface APNSToken : NSObject
+(id)accessToken;
-(void)setAccessToken:(NSString*)token;
-(NSString*)getAccessToken;
@end

#endif /* APNSToken_h */
