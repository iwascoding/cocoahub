//
//  CHGithubChangeListener.h
//  cocoahub
//
//  Created by ilja on 30.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHGithubChangeListener : NSObject

- (id)initWithPort:(NSUInteger) inPort repositoryDirectory:(NSString*) inRepoDir;
- (void) shutdown;

@end
