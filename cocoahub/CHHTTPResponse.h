//
//  CHHTTPResponse.h
//  cocoahub
//
//  Created by ilja on 02.04.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HTTPResponse.h"

@class HTTPMessage;

@interface CHHTTPResponse : NSObject <HTTPResponse>

@property (assign) NSInteger	status;
@property (strong) NSData		*data;
@property (assign) UInt64		offset;
@property (strong) NSDictionary	*httpHeaders;

- (id) initWithCGIPath:(NSString*) inCGIPath request:(HTTPMessage*) inRequest;

@end
