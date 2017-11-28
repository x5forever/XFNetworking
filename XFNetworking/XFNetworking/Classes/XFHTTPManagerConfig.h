//
//  XFHTTPManagerConfig.h
//  XFNetworking
//
//  Created by x5 on 2017/11/28.
//

#import <Foundation/Foundation.h>

@class AFSecurityPolicy;

@interface XFHTTPManagerConfig : NSObject

+ (NSString *)defaultBaseUrl;

+ (AFSecurityPolicy *)securityPolicy;

+ (NSSet *)acceptableContentTypes;

+ (NSTimeInterval)timeOutInterval;

+ (NSInteger)unreachableErrorCode;

+ (NSDictionary *)unreachableErrorUserInfoWithUrl:(NSString *)url;

@end
