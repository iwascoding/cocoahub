//
//  CHHTTPRequestRelay.m
//  cocoahub
//
//  Created by ilja on 02.04.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "CHHTTPRequestRelay.h"
#import "CHHTTPRequestRelayConnection.h"

#import "HTTPServer.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface CHHTTPRequestRelay ()

@property (strong) HTTPServer			*httpServer;
@property (assign) dispatch_queue_t		buildQueue;

@end

@implementation CHHTTPRequestRelay


- (id)initWithPort:(NSUInteger) inPort GGIDirectory:(NSString*) inCGIDir
{
	if (self = [super init])
	{
		NSError				*error;
		
		self.httpServer = [[HTTPServer alloc] init];
		[self.httpServer setPort:inPort];
		[self.httpServer setConnectionClass:[CHHTTPRequestRelayConnection class]];
		[self.httpServer setDocumentRoot:[[inCGIDir stringByExpandingTildeInPath] stringByStandardizingPath]];
		if (NO == [self.httpServer start:&error])
		{
			DDLogError (@"Failed to start HTTP server on port %ld, %@", inPort, [error localizedDescription]);
			return nil;
		}
		DDLogInfo (@"HTTP request relay started on port %ld", inPort);
	}
	return self;
}

@end
