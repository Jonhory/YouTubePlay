//
//  LameTool.h
//  YouTube
//
//  Created by Jonhory on 2019/2/20.
//  Copyright © 2019 jk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LameTool : NSObject

+ (void)cafToMp3:(NSString*)cafFileName;
+ (NSString *)audioCAFtoMP3:(NSString *)wavPath;
    
@end

