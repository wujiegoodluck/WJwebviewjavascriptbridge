//
//  WKWebViewController.m
//
//
//  Created by wujie on 2017-5-29.
//  Copyright (c) 2017 wujie. All rights reserved.
//

#import "WKWebViewController.h"
#import "WKWebViewJavascriptBridge.h"
#import "WebViewJavascriptBridgeBase.h"





@interface WKWebViewController ()

@property (nonatomic, strong) UIProgressView * progressView;/// 进度条

@property(nonatomic, copy) NSString *urlString;

@property(nonatomic, copy) NSString *externalTitle;

@property (nonatomic, assign) BOOL needLogin;/// 是否需要登录

@property (nonatomic, strong) UIImageView *imageTitleView;/// 图片title

@property (nonatomic, copy) NSString *HTMLString;/// 展示本地数据的htmlString

@property (nonatomic, assign) webViewControllerType presentType;/// 展示的状态

@end

@implementation WKWebViewController

- (instancetype)initWithTitle:( NSString *_Nullable)title
                    urlString:(NSString *)urlString
                  paramenters:( NSDictionary *_Nullable)paramenters
                    needLogin:(BOOL)needLogin {
    if (self = [super init]) {
        _externalTitle = title;
        _urlString = [self getUrlStringWithBaseUrl:urlString Paramenters:paramenters];
        _needLogin = needLogin;
        
    }
    return self;
}

- (instancetype)initWithTitle:( NSString *_Nullable)title
                   HTMLString:(NSString *)HTMLString {
    if (self = [super init]) {
        _externalTitle = title;
        _HTMLString = HTMLString;
        _presentType = webViewControllerTypeHTMLString;
        
    }
    return self;
}


#pragma mark - setting

- (NSString *)getUrlStringWithBaseUrl:(NSString *)baseString Paramenters:(NSDictionary *)paramenters {
    if (!paramenters || paramenters.allKeys.count == 0) {
        return baseString;
    }
    NSMutableString *urlString = [NSMutableString stringWithString:baseString];
    [urlString appendString:@"?"];
    NSArray *allKeys = paramenters.allKeys;
    [allKeys enumerateObjectsUsingBlock: ^(NSString *key, NSUInteger idx, BOOL *stop) {
        if (idx == allKeys.count - 1) {
            [urlString appendFormat:@"%@=%@", key, paramenters[key]];
        }
        else {
            [urlString appendFormat:@"%@=%@&", key, paramenters[key]];
        }
    }];
    return [urlString copy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpNavigationItem];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds  configuration:[WKWebViewConfiguration new]];
    /// 允许左滑返回上一个页面
    self.webView.allowsBackForwardNavigationGestures = YES;
    self.webView.scrollView.keyboardDismissMode =  UIScrollViewKeyboardDismissModeOnDrag;
    self.webView.navigationDelegate = self;
    self.webView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.webView];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progressTintColor = [UIColor  lightGrayColor];
    self.progressView.trackTintColor = [UIColor clearColor];
    self.progressView.progress = 0.0;
    [self.progressView setFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+[[UIApplication sharedApplication] statusBarFrame].size.height,self.view.bounds.size.width,2)];
    [self.view addSubview:self.progressView];
    
    UIImageView *imageTitleView = [[UIImageView alloc] init];
    imageTitleView.frame = CGRectMake(0, 0, 140.f, 24.f);
    imageTitleView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageTitleView = imageTitleView;
    
    
    [self  addKVOObserver];
    [WKWebViewJavascriptBridge enableLogging];
    self.bridge = [WKWebViewJavascriptBridge bridgeForWebView:self.webView];
    [self.bridge setWebViewDelegate:self];

    [self startRequest];
    
   }

- (void)setUpNavigationItem {
    UIImage *backItemImage = [UIImage imageNamed:@"webView_pop.png"];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithImage:backItemImage style:UIBarButtonItemStylePlain target:self action:@selector(goBackIfNeeded:)];
    self.navigationItem.leftBarButtonItems = @[backBtn];
}

#pragma mark - go back action

- (void)startRequest {
    self.navigationItem.title = self.externalTitle;
    switch (self.presentType) {
        case webViewControllerTypeURL:
            [self requestFromURL];
            break;
            
        case webViewControllerTypeHTMLString:
            [self.webView loadHTMLString:self.HTMLString baseURL:nil];
            break;
            
        default:
            break;
    }
}

- (void)requestFromURL {
    
    if (self.needLogin) {
       if(self.delegate&&[self.delegate  respondsToSelector:@selector(goToNativeLogin)])
       {
           [self.delegate goToNativeLogin];
       }
    }
    else {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
    }
    
}


- (void)goBackIfNeeded:(UIBarButtonItem *)button {
    if (self.webView.canGoBack) {
        [self.webView goBack];
    }
    else {
        [self closeWebPage];
    }
}


- (void)closeWebPage {
    if (self.navigationController.viewControllers.count == 1) {
        if (self.navigationController.tabBarController) {
            if (self.navigationController.tabBarController.navigationController.viewControllers.count == 1) {
                [self.navigationController.tabBarController dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                [self.navigationController.tabBarController.navigationController popViewControllerAnimated:YES];
            }
        }
        else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - KVO Observing
- (void)addKVOObserver {
    [self.webView addObserver:self forKeyPath:@"canGoBack" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary <NSString *, id> *)change context:(void *)context {
    if ([@"estimatedProgress" isEqualToString:keyPath]) {
        [self updateViewWithProgress];
    }
    else if ([@"canGoBack" isEqualToString:keyPath]) {
        [self updateLeftNavigationItems];
    }
    else if ([@"title" isEqualToString:keyPath] && !_disableTitleAdjust) {
        [self updateViewWithWebViewTitle];
    }
}

#pragma mark - dealloc

- (void)dealloc {
    [_webView removeObserver:self forKeyPath:@"title"];
    [_webView removeObserver:self forKeyPath:@"canGoBack"];
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
}


#pragma mark - update view with KVO

- (void)updateViewWithProgress {
    if (self.progressView.progress == 1 && self.webView.estimatedProgress != 1) {
        /// regression
        self.progressView.progress = 0.f;
        self.progressView.alpha = 1.f;
    }
    [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
    if (self.webView.estimatedProgress >= 0.95) {
        __weak typeof(self) weakSelf = self;
        
        [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveLinear animations: ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.progressView.alpha = 1 - self.webView.estimatedProgress;
        } completion:nil];
    }
}

- (void)updateLeftNavigationItems {
    UIImage *backItemImage = [UIImage imageNamed:@"webView_pop"];
    
    if (!self.navigationItem.leftBarButtonItems || self.navigationItem.leftBarButtonItems.count < 2) {
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithImage:backItemImage style:UIBarButtonItemStylePlain target:self action:@selector(goBackIfNeeded:)];
        UIBarButtonItem *closeBtn = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(leftItemDone:)];
        
        self.navigationItem.leftBarButtonItems = @[backBtn, closeBtn];
    }
}
- (void)leftItemDone:(UIBarButtonItem *)barButtonItem {
    [self closeWebPage];
}

- (BOOL)isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if (![string isKindOfClass:[NSString class]]) {
        return YES;
    }
    if ([string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        return YES;
    }
    return NO;
}


- (void)updateViewWithWebViewTitle {
    /// webView的title不允许覆盖通过Bridge传递过来的title
    if (self.navigationStyle != webNavigationStyleText) {
        return;
    }
    
    BOOL shouldUseWebPageTitle = [self isBlankString:self.externalTitle];
    if (shouldUseWebPageTitle) {
        self.navigationItem.title = self.webView.title;
    }
    else {
        self.navigationItem.title = self.externalTitle;
    }
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidFinishLoad");
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
     NSLog(@"webViewDidStartLoad");
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    
    if (error.code == NSURLErrorCancelled) {
        /// -code:999 不作为错误信息
        return;
    }
    
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) {
        /// Frame interrupt(例如跳转到ituns store)不作为错误信息
        return;
    }
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:self.webView navigationFailedWithError:error];
    }
}

@end
