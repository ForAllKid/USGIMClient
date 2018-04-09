//
//  USGIMClient_extension.h
//  BTYxyz
//
//  Created by ForKid on 2018/4/3.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGIMClient.h"
#import "USGIMCommon.h"

@class USGIMMessage;
@class USGIMConversation;
@class USGIMSocketWrapper;

@interface USGIMClient ()

@property (nonatomic, copy) NSString *clientId;

@property (nonatomic) USGIMClientStatus status;

@property (nonatomic, strong) USGIMSocketWrapper *socketWrapper;

@property (nonatomic, strong) NSObject *coversationCache;

- (void)setStatus:(USGIMClientStatus)status;

- (void)sendMessage:(USGIMMessage *)message;

- (void)sendMessage:(USGIMMessage *)message callback:(nullable USGIMBooleanCallback)callback;


@end
