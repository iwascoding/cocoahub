//
//  CHGithubChangeListener.m
//  cocoahub
//
//  Created by ilja on 30.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "CHGithubChangeListener.h"
#import "CHGithubHookConnection.h"


#import "HTTPServer.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "GTRepository.h"
#import "GTRemote.h"
#import "GTConfiguration.h"
#import "MACollectionUtilities.h"

extern int ddLogLevel;

@interface CHGithubChangeListener ()

@property (strong) HTTPServer			*httpServer;
@property (strong) NSString				*repositoryDirectory;


@end

@implementation CHGithubChangeListener

- (id)initWithPort:(NSUInteger) inPort repositoryDirectory:(NSString*) inRepoDir
{
	NSParameterAssert(inRepoDir);
	
    self = [super init];
    if (self)
	{
		NSError				*error;
		
		self.httpServer = [[HTTPServer alloc] init];
		[self.httpServer setPort:inPort];
		[self.httpServer setConnectionClass:[CHGithubHookConnection class]];
		if (NO == [self.httpServer start:&error])
		{
			DDLogError (@"Failed to start HTTP server on port %ld, %@", inPort, [error localizedDescription]);
			return nil;
		}
		DDLogInfo (@"GitHub listener started on port %ld", inPort);
		
		self.repositoryDirectory = [[inRepoDir stringByExpandingTildeInPath] stringByStandardizingPath];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(changeRecordReceived:)
													 name:kCHConnectionReceivedChangeRecordNotification
												   object:nil];
    }
    return self;
}

- (void) changeRecordReceived:(NSNotification*) inNotifcation
{
	NSString *changedRepoURL = inNotifcation.userInfo[@"repositoryURL"];
	NSString *localRepoPath;
	
	if (![changedRepoURL hasSuffix:@".git"])
	{
		// change notification from git hub seem to be lack the .git URL suffix
		changedRepoURL = [changedRepoURL stringByAppendingString:@".git"];
	}
	
	localRepoPath = [self localPathForRepositoryWithURL:changedRepoURL];
	if (nil == localRepoPath)
	{
		DDLogWarn(@"No local repository cloned from URL %@ in repos directory %@", changedRepoURL, self.repositoryDirectory);
		return;
	}
	[self updateRepoAtPath:localRepoPath];
}

- (void) shutdown
{
	[self.httpServer stop];
}

- (NSString*) localPathForRepositoryWithURL:(NSString*) inRepoURL
{
	NSError			*error;
	NSArray		*dirContents;
	
	dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.repositoryDirectory
																	  error:&error];
	
	for (NSString *fileName in dirContents)
	{
		NSString		*filePath = [self.repositoryDirectory stringByAppendingPathComponent:fileName];
		GTRepository	*repo;
		
		repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:filePath] error:&error];
		
		if (nil == repo)
			continue;
		
		if (MATCH (repo.configuration.remotes, [[obj URLString] isEqualToString:inRepoURL]))
		{
			return filePath;
		}
	}
	return nil;
}

- (void) updateRepoAtPath:(NSString*) inRepoPath
{
	NSTask *gitPullTask = [[NSTask alloc] init];
	
	DDLogInfo(@"updating repo at path %@", inRepoPath);
	
	[gitPullTask setCurrentDirectoryPath:inRepoPath];
	[gitPullTask setLaunchPath:@"/usr/bin/git"];
	[gitPullTask setArguments:@[@"pull"]];
	
	[gitPullTask launch];
	[gitPullTask waitUntilExit];
	
	NSLog (@"git pull termination status: %d", [gitPullTask terminationStatus]);
}

@end