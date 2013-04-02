//
//  CHGithubHookConnection.m
//  cocoahub
//
//  Created by ilja on 28.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "CHGithubHookConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "GCDAsyncSocket.h"

#import "DDLog.h"

extern int ddLogLevel;

NSString *const kCHConnectionReceivedChangeRecordNotification = @"CHConnectionReceivedChangeRecord";

@implementation CHGithubHookConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{	
	if ([method isEqualToString:@"POST"])
		return YES;
	return NO;
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{		
	if ([method isEqualToString:@"POST"])
		return YES;
	
	return NO;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	NSError *error;
	id		receivedObject;
	NSString *decodedBodyString = [[NSString alloc] initWithData:[request body] encoding:NSUTF8StringEncoding];
	
	decodedBodyString = [decodedBodyString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	DDLogVerbose(@"received data: %@", decodedBodyString);

	if ([decodedBodyString hasPrefix:@"payload="]) // seems NSJson chokes on 'payload=' part of body data
	{
		decodedBodyString = [decodedBodyString substringFromIndex:[@"payload=" length]];
	}
	receivedObject = [NSJSONSerialization JSONObjectWithData:[decodedBodyString dataUsingEncoding:NSUTF8StringEncoding]
													 options:NSJSONReadingAllowFragments error:&error];
	if (nil == receivedObject)
	{
		DDLogError(@"couldn't deserialize received data, error: %@", error);
		return [[HTTPDataResponse alloc] initWithData:[@"Error\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	DDLogVerbose(@"received JSON data from %@:\n%@", [asyncSocket connectedHost], receivedObject);
	
	if (![receivedObject isKindOfClass:[NSDictionary class]])
	{
		DDLogError(@"received data is not a dictionary");
		return [[HTTPDataResponse alloc] initWithData:[@"Error\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:[@"OK\n" dataUsingEncoding:NSUTF8StringEncoding]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kCHConnectionReceivedChangeRecordNotification
														object:self
													  userInfo:@{@"repositoryURL": [receivedObject valueForKeyPath:@"repository.url"]}];
	
	return response;
}

- (void)processBodyData:(NSData *)postDataChunk
{	
	[request appendData:postDataChunk];
}

@end
