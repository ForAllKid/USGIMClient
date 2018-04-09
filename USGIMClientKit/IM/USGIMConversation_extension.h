//
//  USGIMConversation_extension.h
//  BTYxyz
//
//  Created by ForKid on 2018/4/3.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGIMConversation.h"

@class USGIMClient;

@interface USGIMConversation ()

@property (nullable, nonatomic, copy) NSString *name;

/**
 当前会话中的成员
 */
@property (nullable, nonatomic, strong) NSArray <NSString *> *members;


+ (instancetype)createConversationId:(NSString *)conversationId
                              client:(USGIMClient *)imClient;

@end
