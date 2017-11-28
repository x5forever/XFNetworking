//
//  XFBaseRequest.m
//  XFNetworking
//
//  Created by x5 on 2017/11/28.
//

#import "XFBaseRequest.h"
#import "XFHTTPManager.h"

@interface XFBaseRequest ()
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, assign, readwrite) XFRequestState state;
@property (nonatomic, copy, readwrite) XFCompletion completion;

@property (nonatomic, strong, readwrite) NSURLSessionTask *task;       // 请求的任务
@property (nonatomic, assign, readwrite) NSUInteger currentRetryTimes; // 当前请求重试次数, default is 0
@end

@implementation XFBaseRequest

#pragma mark - pravite methods
- (void)retry {
    _currentRetryTimes++;
    [self startRequest];
}
- (void)startRequest {
    [[XFHTTPManager shareXFanager] startRequest:self];
}
- (void)requestTerminate {
    if (self.completion) {
        self.completion(self.responseObject, self.state, self.error);
    }
}

#pragma mark - subclass can override method
- (void)startWithCompletion:(XFCompletion)comp {
    self.completion = comp;
    [self startRequest];
}

- (XFRequestMethod)method {
    return XFRequestPOST;
}
- (XFResponseType)responseType {
    return XFResponseTypeDefault;
}
- (NSDictionary *)HTTPHeaders {
    return nil;
}
- (NSTimeInterval)timeOutInterval {
    return 0;
}
- (NSUInteger)retryTimes {
    return 0;
}
- (NSString *)baseUrl {
    return @"";
}
- (NSString *)path {
    return @"";
}
- (void)dNSWithBaseUrl:(NSString * _Nullable)baseUrl dNSBlock:(XFDNSBlock _Nullable)dnsBlock{}
@end

