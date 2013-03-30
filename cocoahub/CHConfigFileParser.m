//
//  CHConfigFileParser.m
//  cocoahub
//
//  Created by ilja on 30.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "CHConfigFileParser.h"

@implementation CHConfigFileParser

+ (NSDictionary*) configurationDictionaryAtPath:(NSString*) inFilePath error:(NSError**) outError
{
	NSMutableDictionary	*configKeys = [NSMutableDictionary dictionary];
	
	NSString	*fileContents = [[NSString alloc] initWithContentsOfFile:inFilePath
															 encoding:NSUTF8StringEncoding
																error:outError];
	if (nil == fileContents)
	{
		return nil;
	}
	for (NSString *line in [fileContents componentsSeparatedByString:@"\n"])
	{
		if ([line hasPrefix:@"#"])
		{
			continue;
		}
		
		NSRange separatorRange = [line rangeOfString:@"="];
		if (separatorRange.location == NSNotFound || separatorRange.location == 0 )
		{
			continue;
		}
		NSString *key = [line substringToIndex:separatorRange.location];
		NSString *value = @"";
		
		if ([line length] > separatorRange.location + 1)
		{
			value= [line substringFromIndex:separatorRange.location + 1];
		}
		[configKeys setObject:value forKey:key];
	}
	return configKeys;
}
@end
