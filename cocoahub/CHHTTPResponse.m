//
//  CHHTTPResponse.m
//  cocoahub
//
//  Created by ilja on 02.04.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "CHHTTPResponse.h"

#import "HTTPMessage.h"

@implementation CHHTTPResponse

- (id) initWithCGIPath:(NSString*) inCGIPath request:(HTTPMessage*) inRequest
{
	self = [super init];
	if (self)
	{
		NSTask			*cgiTask = [[NSTask alloc] init];
		NSPipe			*pipe = [NSPipe pipe];
		NSPipe			*inputPipe = [NSPipe pipe];
		NSFileHandle	*inputHandle = [inputPipe fileHandleForWriting];
		NSInteger		exitCode;
		
		[cgiTask setLaunchPath:inCGIPath];
		[cgiTask setCurrentDirectoryPath:[inCGIPath stringByDeletingLastPathComponent]];
		
		[cgiTask setEnvironment:[self environmentFromRequest:inRequest]];
		
		[cgiTask setStandardInput:inputHandle];
		[inputHandle writeData:[inRequest body]];
		
		[cgiTask setStandardOutput:pipe];
		
		[cgiTask launch];
		//[inputHandle closeFile];
		
		self.data = [[pipe fileHandleForReading] readDataToEndOfFile];

		[cgiTask waitUntilExit];
		exitCode =  [cgiTask terminationStatus];
		
		//TODO extract status code and headers from CGI output
		self.status = 200;
		self.httpHeaders = @{@"Content-Type" : @"text/html"};
	}
	return self;
}

- (NSDictionary*) environmentFromRequest:(HTTPMessage*) inRequest
{
	NSMutableDictionary *environment = [NSMutableDictionary dictionary];
	
	// collect CGI keys as documented here: http://www.cgi101.com/book/ch3/text.html
	environment[@"REQUEST_METHOD"] = [inRequest method];
	environment[@"REQUEST_URI"] = [[inRequest url] absoluteString] ;


	return environment;
}

- (UInt64)contentLength
{
	return [self.data length];
}

- (BOOL) isDone
{
	return YES;
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	if (length > self.data.length)
	{
		length = self.data.length;
	}
	return [self.data subdataWithRange:NSMakeRange(self.offset, length)];
}


@end
