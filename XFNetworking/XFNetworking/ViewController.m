//
//  ViewController.m
//  XFNetworking
//
//  Created by x5 on 2017/11/28.
//

#import "ViewController.h"
#import "TestRequest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[TestRequest new] startWithCompletion:^(id  _Nullable result, XFRequestState state, NSError * _Nullable error) {
        NSLog(@"error >> %@ ",error);
    }];
}

@end
