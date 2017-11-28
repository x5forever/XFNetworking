//
//  XFBaseRequest.h
//  XFNetworking
//
//  Created by x5 on 2017/11/28.
//  
//  XFNetworking V1.0.0

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, XFRequestMethod) {
    XFRequestGET,
    XFRequestPOST,
    XFRequestHEAD,
    XFRequestPUT,
    XFRequestPATCH,
    XFRequestDELET
};

typedef NS_ENUM(NSUInteger, XFRequestState) {
    XFRequestStateReady,
    XFRequestStateExcuting,
    XFRequestStateCanceled,
    XFRequestStateFinished,
    XFRequestStateFailed,
    XFRequestStateUnreachable
};

typedef NS_ENUM(NSUInteger, XFResponseType) {
    XFResponseTypeDefault,      // default is json
    XFResponseTypeImage         // this response is image object
};

typedef void (^XFDNSBlock)(BOOL usedDNs, NSString * _Nonnull domain, NSString * _Nonnull newBaseUrl);
typedef void (^XFCompletion)(id _Nullable result, XFRequestState state, NSError * _Nullable error);

@interface XFBaseRequest : NSObject
// 上传的二进制文件
@property (nonatomic, strong, nullable) NSData  *dataFile;

// 上传二进制名称
@property (nonatomic, strong, nullable) NSString  *dataFileName;

// 上传二进制文件类型
@property (nonatomic, strong, nullable) NSString  *mimeType;
/**
 *  请求的参数
 */
@property (nonatomic, strong, nullable) NSDictionary *parameters;

/**
 * request的状态，（准备，执行中，被取消，结束）
 */
@property (nonatomic, readonly) XFRequestState state;

/**
 * 请求error
 */
@property (nonatomic, strong, readonly, nullable) NSError *error;

#pragma mark - override methods for subclass
/**
 *  发出请求的方法，参数是回调block
 */
- (void)startWithCompletion:(XFCompletion _Nullable)comp;

/**
 *  请求服务器的baseUrl
 *  Note : default base url is setted in XFHTTPManagerConfig and you can also set base url.
 */
- (NSString * _Nonnull)baseUrl;

/**
 *  请求服务器的路径
 */
- (NSString * _Nonnull)path;
/**
 *  请求的重试次数，默认为0
 */
- (NSUInteger)retryTimes;

/**
 *  请求的超时时间，默认为30秒
 */
- (NSTimeInterval)timeOutInterval;

- (NSDictionary * _Nullable)HTTPHeaders;

/**
 请求方式
 @return XFRequestMethod
 */
- (XFRequestMethod)method;

/**
 *  返回的类型
 */
- (XFResponseType)responseType;

/**
 *  选择实现此方法，在使用baseUrl前调用，主要为了项目中处理DNS问题，选择是使用IP还是域名
 */
- (void)dNSWithBaseUrl:(NSString * _Nullable)baseUrl dNSBlock:(XFDNSBlock _Nullable)dnsBlock;

#pragma mark - pravite methods
/**
 *  请求重试
 */
- (void)retry;

/**
 *  请求结束后的统一回调，请勿重写
 */
- (void)requestTerminate;

@end

