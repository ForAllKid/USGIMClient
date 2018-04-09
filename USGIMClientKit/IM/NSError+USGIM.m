//
//  NSError+USGIM.m
//  BTYxyz
//
//  Created by ForKid on 2018/4/3.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "NSError+USGIM.h"

@implementation NSError (USGIM)

+ (NSError *)errorWithCode:(NSInteger)code reason:(NSString *)reason {
    NSDictionary *userInfo;
    if (reason) {
        userInfo = @{NSLocalizedDescriptionKey:reason};
    }
    NSError *error = [NSError errorWithDomain:@"USGIMErrorDomain" code:code userInfo:userInfo];
    return error;
}

@end
