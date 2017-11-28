//
//  XFHTTPManagerConfig.m
//  XFNetworking
//
//  Created by x5 on 2017/11/28.
//

#import "XFHTTPManagerConfig.h"

@implementation XFHTTPManagerConfig

+ (NSString *)defaultBaseUrl {
    return @"http://www.baidu.com";
}

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
}

+ (AFSecurityPolicy *)securityPolicy {
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;
    return securityPolicy;
}

+ (NSTimeInterval)timeOutInterval {
    return 30;
}

+ (NSInteger)unreachableErrorCode {
    return NSURLErrorNotConnectedToInternet;
}

+ (NSDictionary *)unreachableErrorUserInfoWithUrl:(NSString *)url {
    NSMutableDictionary *userInfo = [@{NSLocalizedDescriptionKey: @"网络异常，请检查网络",
                                       NSLocalizedFailureReasonErrorKey: @"unreachable",
                                       NSLocalizedRecoverySuggestionErrorKey: @"无法连接网络，检查网络是否连接"
                                       } mutableCopy];
    if (url) {
        [userInfo setObject:url forKey:@"NSErrorFailingURLKey"];
    }
    return userInfo;
}
@end
