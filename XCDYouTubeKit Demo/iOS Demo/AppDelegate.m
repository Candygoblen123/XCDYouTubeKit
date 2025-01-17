//
//  Copyright (c) 2013-2016 Cédric Luthi. All rights reserved.
//

#import "AppDelegate.h"

@import AVFoundation;
#import <XCDLumberjackNSLogger/XCDLumberjackNSLogger.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>

#import "ContextLogFormatter.h"
#import "XCDYouTubeKit_iOS_Demo-Swift.h"
#import "ConsentViewController.h"


@implementation AppDelegate

@synthesize window = _window;

- (instancetype) init
{
	if (!(self = [super init]))
		return nil;
	
	return self;
}

static DDLogLevel LogLevelForEnvironmentVariable(NSString *levelEnvironment, DDLogLevel defaultLogLevel)
{
	NSString *logLevelString = [[[NSProcessInfo processInfo] environment] objectForKey:levelEnvironment];
	return logLevelString ? strtoul(logLevelString.UTF8String, NULL, 0) : defaultLogLevel;
}

static void InitializeLoggers(void)
{
	DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
	DDLogLevel defaultLogLevel = LogLevelForEnvironmentVariable(@"DefaultLogLevel", DDLogLevelInfo);
	DDLogLevel youTubeLogLevel = LogLevelForEnvironmentVariable(@"XCDYouTubeLogLevel", DDLogLevelWarning);
	ttyLogger.logFormatter = [[ContextLogFormatter alloc] initWithLevels:@{ @(XCDYouTubeKitLumberjackContext) : @(youTubeLogLevel) } defaultLevel:defaultLogLevel];
	ttyLogger.colorsEnabled = YES;
	[DDLog addLogger:ttyLogger];
	
	NSString *bonjourServiceName = [[NSUserDefaults standardUserDefaults] objectForKey:@"NSLoggerBonjourServiceName"];
	XCDLumberjackNSLogger *logger = [[XCDLumberjackNSLogger alloc] initWithBonjourServiceName:bonjourServiceName];
	logger.tags = @{ @0: @"Movie Player", @(XCDYouTubeKitLumberjackContext) : @"XCDYouTubeKit" };
	[DDLog addLogger:logger];
}

static void InitializeUserDefaults(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"VideoIdentifier": @"6v2L2UGZJAM" }];
}

static void InitializeAudioSession(void)
{
	NSString *category = [[NSUserDefaults standardUserDefaults] objectForKey:@"AudioSessionCategory"];
	if (category)
	{
		NSError *error = nil;
		BOOL success = [[AVAudioSession sharedInstance] setCategory:category error:&error];
		if (!success)
			NSLog(@"Audio Session Category error: %@", error);
	}
}

static void InitializeAppearance(UINavigationController *rootViewController)
{
	UINavigationBar *navigationBarAppearance = [UINavigationBar appearance];
	navigationBarAppearance.titleTextAttributes = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:17] };
	UIBarButtonItem *settingsButtonItem = rootViewController.topViewController.navigationItem.rightBarButtonItem;
	[settingsButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:26] } forState:UIControlStateNormal];
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	InitializeLoggers();
	InitializeUserDefaults();
	InitializeAudioSession();
	InitializeAppearance((UINavigationController *)self.window.rootViewController);
	[self checkConsent];
	return YES;
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	[[AVPlayerViewControllerManager shared]disconnectPlayer];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	[[AVPlayerViewControllerManager shared]reconnectPlayerWithRootViewController:self.window.rootViewController];
}

-(void)checkConsent {
	[[XCDYouTubeClient defaultClient] getVideoWithIdentifier:@"6v2L2UGZJAM" completionHandler:^(XCDYouTubeVideo * _Nullable video, NSError * _Nullable error) {
		
		if (error.code == -6) {
			if (error.userInfo[@"consentHtmlData"] != nil) {
				NSString* errorResponseString = error.userInfo[@"consentHtmlData"];
				ConsentViewController* consentVc = [[ConsentViewController alloc] init];
				consentVc.htmlData = errorResponseString;
				[self.window.rootViewController presentViewController:consentVc animated:true completion:nil];
				}
			
			}
	}];
}

@end
