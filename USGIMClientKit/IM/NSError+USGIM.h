//
//  NSError+USGIM.h
//  BTYxyz
//
//  Created by ForKid on 2018/4/3.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (USGIM)

+ (nullable NSError *)errorWithCode:(NSInteger)code reason:(nullable NSString *)reason;

@end

NS_ASSUME_NONNULL_END
