//
//  USGIMCommand.h
//  BTYxyz
//
//  Created by 周宏辉 on 2018/4/8.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface USGIMBasicCommand : NSObject

@property (nonatomic, copy) NSString *fromUser;

@property (nonatomic, copy) NSString *toUser;

@property (nonatomic, copy) NSString *socketFlag;

@property (nonatomic, copy) NSString *msgType;

- (NSData *)contentData;

@end

NS_ASSUME_NONNULL_END
