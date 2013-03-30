//
//  main.m
//  cocoahub
//
//  Created by ilja on 28.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHGithubChangeListener.h"
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

int main(int argc, const char * argv[])
{
	@autoreleasepool
	{
		configureLogging();
		
		CHGithubChangeListener *ghChangeListener = [[CHGithubChangeListener alloc] initWithPort:3001
													repositoryDirectory:@"~/source"];
		if (nil == ghChangeListener)
		{
			exit (-1);
		}
		
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
		
		[ghChangeListener shutdown];
	}
    return 0;
}

