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
		NSData			*taskOutput;
		
		[cgiTask setLaunchPath:inCGIPath];
		[cgiTask setCurrentDirectoryPath:[inCGIPath stringByDeletingLastPathComponent]];
		
		[cgiTask setEnvironment:[self environmentFromRequest:inRequest]];
		
		[cgiTask setStandardInput:inputPipe];
		[cgiTask setStandardOutput:pipe];

		[cgiTask launch];
		
		[inputHandle writeData:[inRequest body]];
		[inputHandle closeFile];
	
		taskOutput = [[pipe fileHandleForReading] readDataToEndOfFile];

		[cgiTask waitUntilExit];
		exitCode =  [cgiTask terminationStatus];
		
		if (taskOutput && exitCode == 0)
		{
			self.status = 200; //fall-back status if not received from CGI
			[self extractHeadersAndResponseBodyFromCGIOutput:taskOutput];
		}
		else
		{
			//TODO: extract status code and headers from CGI output
			self.status = 500; // internal server error
		}
	}
	return self;
}

- (NSDictionary*) environmentFromRequest:(HTTPMessage*) inRequest
{
	NSMutableDictionary *environment = [NSMutableDictionary dictionary];
	
	// TODO: collect CGI keys as documented here: http://www.cgi101.com/book/ch3/text.html
	environment[@"REQUEST_METHOD"] = [inRequest method];
	environment[@"REQUEST_URI"] = [[inRequest url] absoluteString] ;
	// TODO: access remote address from here
	//environment[@"REMOTE_ADDR"] = [asyncSocket connectedHost]

	return environment;
}

- (UInt64)contentLength
{
	return [self.bodyData length];
}

- (BOOL) isDone
{
	return YES;
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	//TODO: should we compute remaining bytes starting from offset
	if (length > self.bodyData.length)
	{
		length = self.bodyData.length;
	}
	return [self.bodyData subdataWithRange:NSMakeRange(self.offset, length)];
}

- (void) extractHeadersAndResponseBodyFromCGIOutput:(NSData*) inData
{
	// we got to split the CGI's output into headers and body data, so we can get the pieces back
	// into the CocoaHTTPServer world
	NSData	*headerDelimiter = [@"\n\n" dataUsingEncoding:NSUTF8StringEncoding];
	NSData	*headerData = inData;
	NSRange	headerDelimiterRange = [inData rangeOfData:headerDelimiter
											   options:0
												 range:NSMakeRange(0, [inData length])];
	

	self.bodyData = nil;
	if (headerDelimiterRange.location != NSNotFound)
	{
		headerData = [inData subdataWithRange:NSMakeRange (0, headerDelimiterRange.location)];
		self.bodyData = [inData subdataWithRange:NSMakeRange(headerDelimiterRange.location + headerDelimiterRange.length,
														[inData length] - (headerDelimiterRange.location + headerDelimiterRange.length))];
	}
	[self extractHeadersFromHeaderData:headerData];
}

- (void) extractHeadersFromHeaderData:(NSData*) inData
{
	NSString			*headerString = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
	NSArray				*headerFields = [headerString componentsSeparatedByString:@"\n"];
	NSMutableDictionary *headerDict = [NSMutableDictionary dictionary];
	
	for (NSString *headerLine in headerFields)
	{
		NSArray *headerLineComponents = [headerLine componentsSeparatedByString:@": "];
		
		if (headerLineComponents.count != 2)
			continue;
		
		if ([headerLineComponents[0] isEqualToString:@"Status"])
		{
			self.status = [headerLineComponents[1] integerValue];
			continue;
		}
		
		headerDict[headerLineComponents[0]] = headerLineComponents[1];
	}
	self.httpHeaders = [NSMutableDictionary dictionaryWithDictionary:headerDict];
}


@end
