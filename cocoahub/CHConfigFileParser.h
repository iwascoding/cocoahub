//
//  CHConfigFileParser.h
//  cocoahub
//
//  Created by ilja on 30.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHConfigFileParser : NSObject

+ (NSDictionary*) configurationDictionaryAtPath:(NSString*) inFilePath error:(NSError**) outError defaultConfig:(NSDictionary*) inDictionary;

@end
