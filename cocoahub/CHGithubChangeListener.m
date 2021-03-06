//
//  CHGithubChangeListener.m
//  cocoahub
//
//  Created by ilja on 30.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "CHGithubChangeListener.h"
#import "CHGithubHookConnection.h"
#import "GHRepositoryURLParser.h"


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
@property (strong) NSString				*CGIDir;
@property (assign) dispatch_queue_t		buildQueue;


@end

@implementation CHGithubChangeListener

- (id)initWithPort:(NSUInteger) inPort repositoryDirectory:(NSString*) inRepoDir CGIDirectory:(NSString*) inCGIDir
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
		self.CGIDir = [[inCGIDir stringByExpandingTildeInPath] stringByStandardizingPath];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(changeRecordReceived:)
													 name:kCHConnectionReceivedChangeRecordNotification
												   object:nil];
		
		self.buildQueue = dispatch_queue_create("com.cocoahub.buildqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void) dealloc
{
	dispatch_release(self.buildQueue);
}

- (void) changeRecordReceived:(NSNotification*) inNotifcation
{
	dispatch_async(self.buildQueue,^{
		NSString *changedRepoURL = inNotifcation.userInfo[@"repositoryURL"];
		NSString *localRepoPath;
		
		localRepoPath = [self localPathForRepositoryWithURL:changedRepoURL];
		if (nil == localRepoPath)
		{
			DDLogWarn(@"No local repository cloned from URL %@ in repos directory %@", changedRepoURL, self.repositoryDirectory);
			return;
		}
		NSInteger exitStatus;
		
		exitStatus = [self updateRepoAtPath:localRepoPath];
		if (exitStatus)
		{
			return;
		}
		if ([self podfileExistsInDirectory:localRepoPath])
		{
			exitStatus = [self installCocoaPodsAtPath:localRepoPath];
			if (exitStatus)
			{
				return;
			}
			exitStatus = [self updateCocoaPodsAtPath:localRepoPath];
			if (exitStatus)
			{
				return;
			}
		}		
		exitStatus = [self buildXcodeProjectAtPath:localRepoPath];
		if (0 == exitStatus)
		{
			DDLogInfo(@"compiled project successfully at path %@", localRepoPath);
		}
	});
}

- (void) shutdown
{
	[self.httpServer stop];
}

- (NSString*) localPathForRepositoryWithURL:(NSString*) inRepoURL
{
	NSError		*error;
	NSArray		*dirContents;
	NSString	*account = [GHRepositoryURLParser githubAccountFromURLString:inRepoURL];
	NSString	*project = [GHRepositoryURLParser githubProjectFromURLString:inRepoURL];

	dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.repositoryDirectory
																	  error:&error];
	
	for (NSString *fileName in dirContents)
	{
		NSString		*filePath = [self.repositoryDirectory stringByAppendingPathComponent:fileName];
		GTRepository	*repo;
		
		repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:filePath] error:&error];
		
		if (nil == repo)
			continue;
		
		for (GTRemote *remote in repo.configuration.remotes)
		{
			NSString* remoteURL = [remote URLString];
			
			if ([[GHRepositoryURLParser githubAccountFromURLString:remoteURL] isEqualToString:account] &&
				[[GHRepositoryURLParser githubProjectFromURLString:remoteURL] isEqualToString:project])
			{
				return filePath;
			}
		}
	}
	return nil;
}

- (NSInteger) updateRepoAtPath:(NSString*) inRepoPath
{
	NSTask		*gitPullTask = [[NSTask alloc] init];
	NSInteger	terminationStatus;
	
	DDLogInfo(@"updating repo at path %@", inRepoPath);
	
	[gitPullTask setCurrentDirectoryPath:inRepoPath];
	[gitPullTask setLaunchPath:@"/usr/bin/git"];
	[gitPullTask setArguments:@[@"pull"]];
	
	[gitPullTask launch];
	[gitPullTask waitUntilExit];
	
	terminationStatus = [gitPullTask terminationStatus];
	if (terminationStatus)
	{
		DDLogError(@"git pull at path %@ failed with status %ld", inRepoPath, (long) terminationStatus);
	}
	
	return terminationStatus;
}

- (BOOL) podfileExistsInDirectory:(NSString*) inRepoPath
{
	NSArray *dirContents;
	NSError *error;
	
	dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inRepoPath
																	  error:&error];
	
	return (nil != MATCH (dirContents, [obj isEqualToString:@"Podfile"]));
}

- (NSInteger) updateCocoaPodsAtPath:(NSString*) inRepoPath
{
	NSTask		*podTask = [[NSTask alloc] init];
	NSInteger	terminationStatus;

	DDLogInfo(@"updating CocoaPods at path %@", inRepoPath);
	
	[podTask setCurrentDirectoryPath:inRepoPath];
	[podTask setLaunchPath:@"/usr/bin/pod"];
	[podTask setArguments:@[@"update"]];
	
	[podTask launch];
	[podTask waitUntilExit];
	
	terminationStatus = [podTask terminationStatus];
	if (terminationStatus)
	{
		DDLogError(@"updating CocoaPods at path %@ failed with status %ld", inRepoPath, (long) terminationStatus);
	}
	
	return terminationStatus;
}

- (NSInteger) installCocoaPodsAtPath:(NSString*) inRepoPath
{
	NSTask		*podTask = [[NSTask alloc] init];
	NSInteger	terminationStatus;
	
	DDLogInfo(@"installing CocoaPods at path %@", inRepoPath);
	
	[podTask setCurrentDirectoryPath:inRepoPath];
	[podTask setLaunchPath:@"/usr/bin/pod"];
	[podTask setArguments:@[@"install"]];
	
	[podTask launch];
	[podTask waitUntilExit];
	
	terminationStatus = [podTask terminationStatus];
	if (terminationStatus)
	{
		DDLogError(@"installing CocoaPods at path %@ failed with status %ld", inRepoPath, (long) terminationStatus);
	}
	
	return terminationStatus;
}

- (NSInteger) buildXcodeProjectAtPath:(NSString*) inRepoPath
{
	NSTask			*xcodeBuildTask = [[NSTask alloc] init];
	NSInteger		terminationStatus;
	NSArray			*dirContents;
	NSString		*workspaceFilename;
	NSError			*error;
	NSMutableArray	*arguments = [NSMutableArray array];
	
	DDLogInfo(@"building Xcode project at path %@", inRepoPath);
	
	[xcodeBuildTask setCurrentDirectoryPath:inRepoPath];
	[xcodeBuildTask setLaunchPath:@"/usr/bin/xcodebuild"];
	
	// check if there is an xcodeworkspace file we should use
	dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inRepoPath
																	  error:&error];
	
	workspaceFilename = MATCH (dirContents, [obj hasSuffix:@".xcworkspace"]);
	if (workspaceFilename)
	{
		// TODO: a way to configure scheme name, for now pretend scheme is called like the containing directory
		[arguments addObjectsFromArray:@[@"-workspace", workspaceFilename, @"-scheme", [inRepoPath lastPathComponent]]];
	}
	// make sure product goes into configured CGI dir
	[arguments addObjectsFromArray:@[@"install", [NSString stringWithFormat:@"DSTROOT=%@", self.CGIDir] , @"INSTALL_PATH=/" ]];
	[xcodeBuildTask setArguments:arguments];
	[xcodeBuildTask launch];
	[xcodeBuildTask waitUntilExit];
	
	terminationStatus = [xcodeBuildTask terminationStatus];
	if (terminationStatus)
	{
		DDLogError(@"building Xcode project %@ failed with status %ld", inRepoPath, (long) terminationStatus);
	}
	
	return terminationStatus;
}


@end 