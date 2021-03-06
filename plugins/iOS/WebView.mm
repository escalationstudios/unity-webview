/*
 * Copyright (C) 2011 Keijiro Takahashi
 * Copyright (C) 2012 GREE, Inc.
 * 
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 * 
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 * 
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

#import <UIKit/UIKit.h>

void UnityPause(bool pause);
extern void UnitySendMessage(const char *, const char *, const char *);
extern UIViewController *UnityGetGLViewController();

@interface WebViewPlugin : NSObject<UIWebViewDelegate>
{
	UIWebView *webView;
	NSString *gameObjectName;
	
	NSString *failAlertTitle;
	NSString *failAlertMessage;
	NSString *failAlertButton;
}
@end

@implementation WebViewPlugin

- (id)initWithGameObjectName:(const char *)gameObjectName_
		failAlertTitle:(const char *)failAlertTitle_
		failAlertMessage:(const char *)failAlertMessage_
		failAlertButton:(const char *)failAlertButton_
{
	self = [super init];

	UIView *view = UnityGetGLViewController().view;
	webView = [[UIWebView alloc] initWithFrame:view.frame];
	webView.delegate = self;
	webView.hidden = YES;
	[view addSubview:webView];
	gameObjectName = [[NSString stringWithUTF8String:gameObjectName_] retain];
	
	failAlertTitle = [[NSString stringWithUTF8String:failAlertTitle_] retain];
	failAlertMessage = [[NSString stringWithUTF8String:failAlertMessage_] retain];
	failAlertButton = [[NSString stringWithUTF8String:failAlertButton_] retain];
	
	return self;
}

- (void)dealloc
{
	[webView removeFromSuperview];
	[webView release];
	[gameObjectName release];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *url = [[request URL] absoluteString];
	if ([url hasPrefix:@"unity:"]) {
		NSString *command = [url substringFromIndex:6];
		
		if( [command isEqualToString: @"touchStart"] ) {
			UnityPause( YES );
		} else if( [command isEqualToString: @"touchEnd"] ) {
			UnityPause( NO );
		} else {
			UnityPause( NO );
			UnitySendMessage([gameObjectName UTF8String], "CallFromJS", [command UTF8String]);
		}
		
		return NO;
	} else {
		return YES;
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	UnitySendMessage([gameObjectName UTF8String], "CallFromJS", "close");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	UIAlertView *alert = [[UIAlertView alloc]
		initWithTitle: failAlertTitle
		message: failAlertMessage
		delegate: self
		cancelButtonTitle: failAlertButton
		otherButtonTitles: nil];
		
	[alert show];
	[alert release];
}

- (void)setMargins:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
	UIView *view = UnityGetGLViewController().view;

	CGRect frame = view.frame;
	CGFloat scale = view.contentScaleFactor;
	frame.size.width -= (left + right) / scale;
	frame.size.height -= (top + bottom) / scale;
	frame.origin.x += left / scale;
	frame.origin.y += top / scale;
	webView.frame = frame;
}

- (void)setVisibility:(BOOL)visibility
{
	webView.hidden = !visibility;
}

- (void)loadURL:(const char *)url
{
	NSString *urlStr = [NSString stringWithUTF8String:url];
	NSURL *nsurl = [NSURL URLWithString:urlStr];
	NSURLRequest *request = [NSURLRequest requestWithURL:nsurl];
	[webView loadRequest:request];
}

- (void)evaluateJS:(const char *)js
{
	NSString *jsStr = [NSString stringWithUTF8String:js];
	[webView stringByEvaluatingJavaScriptFromString:jsStr];
}

@end

extern "C" {
	void *_WebViewPlugin_Init(const char *gameObjectName, const char *failAlertTitle, const char *failAlertMessage, const char *failAlertButton);
	void _WebViewPlugin_Destroy(void *instance);
	void _WebViewPlugin_SetMargins(
	void *instance, int left, int top, int right, int bottom);
	void _WebViewPlugin_SetVisibility(void *instance, BOOL visibility);
	void _WebViewPlugin_LoadURL(void *instance, const char *url);
	void _WebViewPlugin_EvaluateJS(void *instance, const char *url);
}

void *_WebViewPlugin_Init(const char *gameObjectName, const char *failAlertTitle, const char *failAlertMessage, const char *failAlertButton)
{
	id instance = [[WebViewPlugin alloc] initWithGameObjectName:gameObjectName failAlertTitle:failAlertTitle failAlertMessage:failAlertMessage failAlertButton:failAlertButton];
	return (void *)instance;
}

void _WebViewPlugin_Destroy(void *instance)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin release];
}

void _WebViewPlugin_SetMargins(
	void *instance, int left, int top, int right, int bottom)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin setMargins:left top:top right:right bottom:bottom];
}

void _WebViewPlugin_SetVisibility(void *instance, BOOL visibility)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin setVisibility:visibility];
	UnityPause( visibility );
}

void _WebViewPlugin_LoadURL(void *instance, const char *url)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin loadURL:url];
	UnityPause( YES );
}

void _WebViewPlugin_EvaluateJS(void *instance, const char *js)
{
	WebViewPlugin *webViewPlugin = (WebViewPlugin *)instance;
	[webViewPlugin evaluateJS:js];
}
