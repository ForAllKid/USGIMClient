//
//  USGIMMessage.m
//  BTYxyz
//
//  Created by ForKid on 2018/3/23.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGIMMessage.h"
#import "USGIMMessage_extension.h"

@implementation USGIMMessage

+ (USGIMMessage *)messageWithContent:(NSString *)content {
    USGIMMessage *one = [[USGIMMessage alloc] init];
    one.content = content.copy;
    one->_type = USGIMMessageTypeText;
    return one;
}

@end
