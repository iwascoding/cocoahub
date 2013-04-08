//
//  main.m
//  cocoahub
//
//  Created by ilja on 28.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHGithubChangeListener.h"
#import "CHHTTPRequestRelay.h"
#import "CHConfigFileParser.h"

#import "DDLog.h"
#import "DDFileLogger.h"
#import "DDTTYLogger.h"

int ddLogLevel;

void configureLogging ()
{
	
	DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
	fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
	fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
	
	ddLogLevel = LOG_LEVEL_VERBOSE;
	
	[DDLog addLogger:fileLogger];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
}

NSDictionary* defaultConfig ()
{
	return @{@"repoDir" : @"~/source",
		  @"cgiDir": @"~/cgi-bin",
		  @"httpPort" : @"3002",
		  @"githubPort": @"3001"};
}

int main(int argc, const char * argv[])
{
	@autoreleasepool
	{
		
		configureLogging();
		
		NSError			*error;
		NSDictionary	*config = [CHConfigFileParser configurationDictionaryAtPath:@"cocoahub.conf" error:&error defaultConfig:defaultConfig()];
		
		// TODO: configureable path for repo directory
		// TODO: check that these directories exist and are writeable
		CHGithubChangeListener *ghChangeListener = [[CHGithubChangeListener alloc] initWithPort:[config[@"githubPort"] integerValue]
													repositoryDirectory:config[@"repoDir"]
													CGIDirectory:config[@"cgiDir"]];
		if (nil == ghChangeListener)
		{
			exit (-1);
		}
		
		CHHTTPRequestRelay *requestRelay = [[CHHTTPRequestRelay alloc] initWithPort:[config[@"httpPort"] integerValue]
																	   GGIDirectory:config[@"cgiDir"]];
		if (nil == requestRelay)
		{
			exit (-1);
		}
		
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
	}
    return 0;
}



