//
//  XFHTTPManager.m
//  XFNetworking
//
//  Created by x5 on 2017/11/28.
//

#import "XFHTTPManager.h"
#import "AFNetworking.h"
#import "XFBaseRequest.h"
#import "XFHTTPManagerConfig.h"
#import "AFNetworkReachabilityManager.h"

@interface XFBaseRequest ()
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, assign, readwrite) XFRequestState state;
@property (nonatomic, strong, readwrite) NSURLSessionTask *task;
@property (nonatomic, assign, readwrite) NSUInteger currentRetryTimes;
@end

@interface XFHTTPManager ()
@property (nonatomic, strong) NSMutableArray *taskArray;
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) AFHTTPSessionManager *imageManager;
@property (nonatomic, strong) AFNetworkReachabilityManager *taskManager;
@end

@implementation XFHTTPManager

+ (XFHTTPManager *)shareXFanager {
    static XFHTTPManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [XFHTTPManager new];
    });
    return instance;
}
- (AFHTTPSessionManager *)manager {
    if (!_manager) {
        _manager = [self managerWithType:XFResponseTypeDefault];
    }
    return _manager;
}
- (AFHTTPSessionManager *)imageManager {
    if (!_imageManager) {
        _imageManager = [self managerWithType:XFResponseTypeImage];
    }
    return _imageManager;
}
- (AFHTTPSessionManager *)managerWithType:(XFResponseType)type {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.securityPolicy = [XFHTTPManagerConfig securityPolicy];
    if (type == XFResponseTypeImage) {
        manager.responseSerializer = [AFImageResponseSerializer serializer];
    }else {
        manager.responseSerializer.acceptableContentTypes = [XFHTTPManagerConfig acceptableContentTypes];
    }
    return manager;
}

- (void)startRequest:(XFBaseRequest *)request {
    
    request.state = XFRequestStateReady;
    
    AFHTTPSessionManager *httpManager = request.responseType == XFResponseTypeDefault ? self.manager : self.imageManager;
    
    //clear requestSerializer header host
    [httpManager.requestSerializer setValue:nil forHTTPHeaderField:@"host"];
    
    __block NSString *baseUrl = nil;
    if ([request respondsToSelector:@selector(baseUrl)]) baseUrl = [request baseUrl];
    if (!baseUrl.length)  baseUrl = [XFHTTPManagerConfig defaultBaseUrl];
    
    //实现此方法，使用了dns，需要设置header host
    if ([request respondsToSelector:@selector(dNSWithBaseUrl:dNSBlock:)]) {
        [request dNSWithBaseUrl:baseUrl
                       dNSBlock:^(BOOL usedDNS, NSString *domain, NSString *newBaseUrl) {
                           if (usedDNS) {
                               baseUrl = [newBaseUrl copy];
                               [_manager.requestSerializer setValue:domain forHTTPHeaderField:@"host"];
                           }
                       }];
    }
    NSString *path = [request path];
    
    NSParameterAssert(baseUrl);
    NSParameterAssert(path);
    
    NSString *avalidUrl = [self avalidUrlWithBaseUrl:baseUrl path:path];
    NSDictionary *parameters = nil;
    if ([request respondsToSelector:@selector(parameters)]) {
        parameters = [request parameters];
    }
    
    if ([request respondsToSelector:@selector(timeOutInterval)] && [request timeOutInterval] > 0) {
        httpManager.requestSerializer.timeoutInterval = [request timeOutInterval];
    }else {
        httpManager.requestSerializer.timeoutInterval = [XFHTTPManagerConfig timeOutInterval];
    }
    
    if ([request respondsToSelector:@selector(HTTPHeaders)] && [request HTTPHeaders] != nil) {
        NSDictionary *headers = [request HTTPHeaders];
        [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [httpManager.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
    [self requestWithManager:httpManager
                         url:avalidUrl
                      method:[request method]
                  parameters:parameters
                     request:request];
    
}
- (void)requestWithManager:(AFHTTPSessionManager *)manager
                       url:(NSString *)url
                    method:(XFRequestMethod)method
                parameters:(NSDictionary *)parameters
                   request:(XFBaseRequest *)request {
    
    if (![[AFNetworkReachabilityManager sharedManager] isReachable]) {
        request.state = XFRequestStateUnreachable;
        NSError *error  = [NSError errorWithDomain:NSCocoaErrorDomain
                                              code:[XFHTTPManagerConfig unreachableErrorCode]
                                          userInfo:[XFHTTPManagerConfig unreachableErrorUserInfoWithUrl:url]];
        [self requestFinishedWithTask:nil request:request responseObject:nil error:error];
        return;
    }
    
    NSURLSessionDataTask *task = nil;
    request.state = XFRequestStateExcuting;
    switch (method) {
        case XFRequestGET:
        {
            task = [manager GET:url
                     parameters:parameters
                       progress:^(NSProgress * _Nonnull downloadProgress) {
                           
                       } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                           [self requestFinishedWithTask:task
                                                 request:request
                                          responseObject:responseObject
                                                   error:nil];
                       } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                           [self requestFinishedWithTask:task
                                                 request:request
                                          responseObject:nil
                                                   error:error];
                       }];
        }
            break;
        case XFRequestPOST:
        {
            if (request.dataFile == nil || request.dataFileName == nil || request.mimeType == nil ) {
                task = [manager POST:url
                          parameters:parameters
                            progress:^(NSProgress * _Nonnull downloadProgress) {
                                
                            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                [self requestFinishedWithTask:task
                                                      request:request
                                               responseObject:responseObject
                                                        error:nil];
                            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                [self requestFinishedWithTask:task
                                                      request:request
                                               responseObject:nil
                                                        error:error];
                            }];
            } else {
                task = [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    
                    [formData appendPartWithFileData: request.dataFile name: request.dataFileName fileName:request.dataFileName mimeType:request.mimeType];
                    
                } progress: nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [self requestFinishedWithTask:task
                                          request:request
                                   responseObject:responseObject
                                            error:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [self requestFinishedWithTask:task
                                          request:request
                                   responseObject:nil
                                            error:error];
                }];
            }
            
        }
            break;
        case XFRequestDELET:
        {
            task = [manager DELETE:url
                        parameters:parameters
                           success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                               [self requestFinishedWithTask:task
                                                     request:request
                                              responseObject:responseObject
                                                       error:nil];
                           } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                               [self requestFinishedWithTask:task
                                                     request:request
                                              responseObject:nil
                                                       error:error];
                           }];
        }
            break;
        case XFRequestHEAD:
        {
            task = [manager HEAD:url
                      parameters:parameters
                         success:^(NSURLSessionDataTask * _Nonnull task) {
                             [self requestFinishedWithTask:task
                                                   request:request
                                            responseObject:nil
                                                     error:nil];
                         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                             [self requestFinishedWithTask:task
                                                   request:request
                                            responseObject:nil
                                                     error:error];
                         }];
        }
            break;
        case XFRequestPUT:
        {
            task = [manager PUT:url
                     parameters:parameters
                        success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                            [self requestFinishedWithTask:task
                                                  request:request
                                           responseObject:responseObject
                                                    error:nil];
                        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                            [self requestFinishedWithTask:task
                                                  request:request
                                           responseObject:nil
                                                    error:error];
                        }];
        }
            break;
        case XFRequestPATCH:
        {
            task = [manager PATCH:url
                       parameters:parameters
                          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                              [self requestFinishedWithTask:task
                                                    request:request
                                             responseObject:responseObject
                                                      error:nil];
                          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                              [self requestFinishedWithTask:task
                                                    request:request
                                             responseObject:nil
                                                      error:error];
                          }];
        }
            break;
        default:
            break;
    }
    
}

- (void)requestFinishedWithTask:(NSURLSessionDataTask *)task
                        request:(XFBaseRequest *)request
                 responseObject:(id)responseObject
                          error:(NSError *)error {
    request.task = task;
    
    if (error && ((task && task.state == NSURLSessionTaskStateCanceling) || error.code == NSURLErrorCancelled)) {
        request.state = XFRequestStateCanceled;
    }
    if (error && task && task.state == NSURLSessionTaskStateCompleted) {
        request.state = XFRequestStateFailed;
    }
    request.error = error;
    request.responseObject = responseObject;
    
    // retry, 如果需要处理无网 重复请求，可加逻辑 && request.state == XFRequestStateUnreachable
    if (error && [request retryTimes] > request.currentRetryTimes && request.state == XFRequestStateUnreachable) {
        //        [request retry];
        [self monitoringTarget:request performSelector:@selector(retry)];
        return;
    }
    // error 为 nil 时，请求成功
    if (error == nil) {
        request.state = XFRequestStateFinished;
    }
    // 没有重试则请求完成
    [request requestTerminate];
}

- (BOOL)cancelRequest:(XFBaseRequest *)request {
    if (request.task && request.task.state == NSURLSessionTaskStateRunning) {
        [request.task cancel];
        return YES;
    }
    return NO;
}
- (NSString *)avalidUrlWithBaseUrl:(NSString *)base path:(NSString *)path{
    
    NSString *baseUrlStr = [base stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *pathStr = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    pathStr = [pathStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSMutableString *avalidUrl = [NSMutableString stringWithString:baseUrlStr];
    
    NSAssert([avalidUrl hasPrefix:@"http"], @"request is not a http or https type!");
    
    BOOL urlSlash = [avalidUrl hasSuffix:@"/"];
    
    BOOL pathSlash = [pathStr hasPrefix:@"/"];
    
    if (urlSlash && pathSlash) {
        [avalidUrl deleteCharactersInRange:NSMakeRange(avalidUrl.length - 1, 1)];
    }
    else if (!urlSlash && !pathSlash){
        [avalidUrl appendString:@"/"];
    }
    
    [avalidUrl appendString:pathStr];
    
    return avalidUrl;
    
}
#pragma mark - monitoring
- (void)monitoringTarget:(id)target performSelector:(SEL)selector {
    if ( target && selector) {
        NSDictionary *dict = @{@"target":target,@"selector":NSStringFromSelector(selector)};
        [self.taskArray addObject:dict];
        __weak __typeof(self) weakSelf = self;
        [self.taskManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                case AFNetworkReachabilityStatusReachableViaWiFi: {
                    [strongSelf.taskManager stopMonitoring];
                    [strongSelf.taskArray enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [obj[@"target"] performSelector:NSSelectorFromString(obj[@"selector"]) withObject:nil afterDelay:0];
                    }];
                    [strongSelf.taskArray removeAllObjects];
                }
            }
        }];
        [self.taskManager startMonitoring];
    }
}
#pragma mark - lazy init
- (AFNetworkReachabilityManager *)taskManager {
    if (!_taskManager) {
        _taskManager = [AFNetworkReachabilityManager manager];
    }
    return _taskManager;
}
- (NSMutableArray *)taskArray {
    if (!_taskArray) {
        _taskArray = [NSMutableArray arrayWithCapacity:3];
    }
    return _taskArray;
}
@end

