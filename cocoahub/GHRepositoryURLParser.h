//
//  GHRepositoryURLParser.h
//  cocoahub
//
//  Created by ilja on 02.04.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GHRepositoryURLParser : NSObject

+ (NSString*) githubAccountFromURLString:(NSString*) inRepoURLString;
+ (NSString*) githubProjectFromURLString:(NSString*) inRepoURLString;

@end
