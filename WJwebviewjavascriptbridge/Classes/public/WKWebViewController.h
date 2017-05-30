//
//  WKWebViewController.h
//
//
//  Created by wujie on 2017-5-29.
//  Copyright (c) 2017 wujie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

/// 导航栏标题样式
typedef NS_ENUM (NSInteger, webNavigationStyle) {
    /// 文字标题
    webNavigationStyleText,
    /// 图片标题
    webNavigationStylePicture
};

/// 展示数据的类型
typedef NS_ENUM (NSInteger, webViewControllerType) {
    /// 网络数据
    webViewControllerTypeURL,
    /// 本地页面
    webViewControllerTypeHTMLString
};


@protocol WKWebViewControllerDelegate <NSObject>

-(void)goToNativeLogin;

-(void)webView:(WKWebView *)webview navigationFailedWithError:(NSError *)error;


@end

@interface WKWebViewController : UIViewController<WKNavigationDelegate>

/// 导航栏是否显示
@property (nonatomic, assign) BOOL navigationBarHidden;
/// 禁止网页title调整
@property (nonatomic, assign) BOOL disableTitleAdjust;
/// 禁止网页改变导航栏右边按钮
@property (nonatomic, assign) BOOL disableRightNavigationItemAdjust;

@property (nonatomic, assign) BOOL canGoBack;//默认YES

@property (nonatomic, assign) webNavigationStyle navigationStyle;/// 导航栏Title样式默认文字标题

@property (nonatomic, weak)id <WKWebViewControllerDelegate> delegate;


/**
 *  初始化WKWebViewController的方法
 *
 *  @param title       控制器的标题 为空则取JS的titile
 *  @param urlString   链接地址 不可为空
 *  @param paramenters 网页需要的参数
 *  @param needLogin   网页是否需要登录
 *
 *  @return
 */
- (instancetype)initWithTitle:(nullable NSString *)title
                    urlString:(NSString *)urlString
                  paramenters:(nullable NSDictionary *)paramenters
                    needLogin:(BOOL)needLogin;


/**
 *  初始化WKWebViewController的方法
 *
 *  @param title       控制器的标题 为空则取JS的titile
 *  @param HTMLString  需要展示的htmlString
 *
 *  @return
 */
- (instancetype)initWithTitle:(nullable NSString *)title
                   HTMLString:(NSString *)HTMLString;


/**
 设置导航栏隐藏状态,没有动画效果,同时调整状态栏以及view的布局
 
 @param hidden 是否隐藏
 */
- (void)setNavigationBarHidden:(BOOL)hidden;

/**
 关闭页面
 */
- (void)closeWebPage;


@end
