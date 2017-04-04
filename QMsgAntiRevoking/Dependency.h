//
//  Dependency.h
//  QMsgAntiRevoking
//
//  Created by Bers on 2017/3/24.
//  Copyright © 2017年 Bers. All rights reserved.
//

#ifndef Dependency_h
#define Dependency_h

#import <AppKit/AppKit.h>

struct Info {
    struct {
        int32_t time, msgSeq, random;
    } *info;
};

struct RecallModel {
    uint64_t unknown1;
    uint32_t sesstype, unknown2;
    struct Info *addr, *addr2;
    uint64_t unknown3, unknown4;
    long long uin, groupUin;
};

@interface TXTopTextView : NSObject

- (void)scrollToBottom;

@end

@interface MQAIOTopViewController : NSObject

@property TXTopTextView *msgView;

- (void)appendMessage:(id)msg;

@end

@interface BHMessageExInfo : NSObject

- (id)stringValueForKey:(id)arg1;
- (void)setStringValue:(id)arg1 forKey:(id)arg2;

@end

@class BHStructMessage;

@interface BHMessageModel : NSObject

@property(nonatomic) int msgType;
@property(nonatomic) int msgSessionType;
@property(readonly) BOOL isSelfSend;
@property(retain, nonatomic) NSString *nickname;
@property(readonly, nonatomic) BHMessageExInfo *exInfo;
@property(readonly, nonatomic) BHStructMessage *smMessage;

- (void)setSmallContent:(id)content;
- (id)smallContent;
- (id)textContent;

@end

@interface MQAIOMessageViewModel : NSObject

- (id)initWithMessageModel:(id)arg1;

@end

@interface RecallProcessor : NSObject

- (void)solveRecallNotify:(struct RecallModel *)arg1 isOnline:(BOOL)arg2;

@end

@interface RevokeHelper : NSObject

+ (BOOL)supportRevokeMessage:(id)arg1;

@end

@interface MsgDbService : NSObject

+ (id)sharedInstance;
- (id)getMessageWithUin:(long long)arg1 sessType:(int)arg2 identityUin:(unsigned long long)arg3 msgSeq:(int)arg4 time:(int)arg5 random:(int)arg6;
- (void)updateQQMessageModel:(id)arg1 keyArray:(id)arg2;

@end

@interface QQDataCenter : NSObject

+ (id)GetInstance;
@property(copy, nonatomic) NSString *uin;

@end

@interface NSString (ULL)

- (unsigned long long)unsignedLongLongValue;

@end

@interface NSObject(MQAIOChatViewControllerHook)

- (id)topMsgListViewController;
- (void)revokeMessages:(id<NSFastEnumeration>)msgs;
- (id)getInfomativeMsgContent:(id)msg;

@end

#endif /* Dependency_h */
