//
//  GHRepositoryURLParser.m
//  cocoahub
//
//  Created by ilja on 02.04.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "GHRepositoryURLParser.h"

@implementation GHRepositoryURLParser
/*" Depending on how a repostiory was cloned (HTTP or SSH), the URLs might be different. This class mitigates this be extracting account and project from both URL formats. "*/

+ (NSString*) githubAccountFromURLString:(NSString*) inRepoURLString
{
	if ([inRepoURLString hasPrefix:@"https://github.com/"])
	{
		return [self githubAccountFromRepoHTTPURLString:inRepoURLString];
	}
	else if ([inRepoURLString hasPrefix:@"git@github.com:"])
	{
		return [self githubAccountFromRepoSSHURLString:inRepoURLString];
	}
	return nil;
}

+ (NSString*) githubProjectFromURLString:(NSString*) inRepoURLString
{
	if ([inRepoURLString hasPrefix:@"https://github.com/"])
	{
		return [self githubProjectFromRepoHTTPURLString:inRepoURLString];
	}
	else if ([inRepoURLString hasPrefix:@"git@github.com:"])
	{
		return [self githubProjectFromRepoSSHURLString:inRepoURLString];
	}
	return nil;
}

+ (NSString*) githubAccountFromRepoHTTPURLString:(NSString*) inRepoURLString
{
	NSArray *components;
	
	if (![inRepoURLString hasPrefix:@"https://github.com/"])
	{
		return nil;
	}
	inRepoURLString = [inRepoURLString substringFromIndex:[@"https://github.com/" length]];
	
	components = [inRepoURLString pathComponents];
	if (components.count)
		return components[0];
	
	return nil;
}

+ (NSString*) githubProjectFromRepoHTTPURLString:(NSString*) inRepoURLString
{
	NSArray *components;
	
	if (![inRepoURLString hasPrefix:@"https://github.com/"])
	{
		return nil;
	}
	inRepoURLString = [inRepoURLString substringFromIndex:[@"https://github.com/" length]];
	
	components = [inRepoURLString pathComponents];
	if (components.count > 1)
	{
		NSString *project = components[1];
		
		if ([project hasSuffix:@".git"])
		{
			project = [project stringByDeletingPathExtension];
		}
		return project;
	}
	
	return nil;
}

+ (NSString*) githubAccountFromRepoSSHURLString:(NSString*) inRepoURLString
{
	NSArray *components;
	
	if (![inRepoURLString hasPrefix:@"git@github.com:"])
	{
		return nil;
	}
	inRepoURLString = [inRepoURLString substringFromIndex:[@"git@github.com:" length]];
	
	components = [inRepoURLString pathComponents];
	if (components.count)
		return components[0];
	
	return nil;
}

+ (NSString*) githubProjectFromRepoSSHURLString:(NSString*) inRepoURLString
{
	NSArray *components;
	
	if (![inRepoURLString hasPrefix:@"git@github.com:"])
	{
		return nil;
	}
	inRepoURLString = [inRepoURLString substringFromIndex:[@"git@github.com:" length]];
	
	components = [inRepoURLString pathComponents];
	if (components.count > 1)
	{
		NSString *project = components[1];
		
		if ([project hasSuffix:@".git"])
		{
			project = [project stringByDeletingPathExtension];
		}
		return project;
	}
	
	return nil;
}

@end
