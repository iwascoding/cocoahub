//
//  CHHTTPRequestRelayConnection.m
//  cocoahub
//
//  Created by ilja on 02.04.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "CHHTTPRequestRelayConnection.h"
#import "CHHTTPResponse.h"

#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPServer.h"

#import "MACollectionUtilities.h"


@implementation CHHTTPRequestRelayConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	if ([method isEqualToString:@"POST"])
		return YES;
	if ([method isEqualToString:@"GET"])
		return YES;
	if ([method isEqualToString:@"PUT"])
		return YES;
	if ([method isEqualToString:@"DELETE"])
		return YES;
	return NO;
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	if ([method isEqualToString:@"POST"])
		return YES;
	if ([method isEqualToString:@"PUT"])
		return YES;
	return NO;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	NSArray		*pathComponents = [path pathComponents];
	NSString	*cgiName;
	
	if (pathComponents.count < 2)
		return nil;
	
	cgiName = pathComponents[1]; //pathComponents[0] is just a test
	if ([self hasCGIWithName:cgiName inDirectory:[[config server] documentRoot]])
	{
		CHHTTPResponse *response = [[CHHTTPResponse alloc] initWithCGIPath:[[[config server] documentRoot] stringByAppendingPathComponent:cgiName]
																   request:request];
		
		return response;
	}
	return nil;
}

- (BOOL) hasCGIWithName:(NSString*) inCGIName inDirectory:(NSString*) inCGIDir
{
	NSError *error;
	
	NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inCGIDir
																			   error:&error];
	
	return (nil != MATCH (dirContents, [obj isEqualToString:inCGIName]));
}

- (void)processBodyData:(NSData *)postDataChunk
{
	[request appendData:postDataChunk];
}


@end
