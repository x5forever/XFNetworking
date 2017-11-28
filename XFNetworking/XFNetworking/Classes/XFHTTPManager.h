//
//  XFHTTPManager.h
//  XFNetworking
//
//  Created by x5 on 2017/11/28.
//

#import <Foundation/Foundation.h>

@class XFBaseRequest;

@interface XFHTTPManager : NSObject

+ (XFHTTPManager *)shareXFanager;

- (void)startRequest:(XFBaseRequest *)request;

- (BOOL)cancelRequest:(XFBaseRequest *)request;

@end
