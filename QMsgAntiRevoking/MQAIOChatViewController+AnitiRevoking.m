//
//  MQAIOChatViewController+AnitiRevoking.m
//  QMsgAntiRevoking
//
//  Created by Bers on 2017/3/24.
//  Copyright © 2017年 Bers. All rights reserved.
//

#import "MQAIOChatViewController+AnitiRevoking.h"
#import <objc/runtime.h>
#import <objc/objc-runtime.h>

NS_ENUM(NSInteger, BHMessageModelMsgType) {
    BHMessageModelMsgText = 0x400,
    BHMessageModelMsgRevoke = 0x14c,
    BHMessageModelMsgFile = 0x4,
    BHMessageModelMsgVoice = 0x3,
};

NS_ENUM(NSInteger, BHMessageModelSessionType) {
    BHMessageModelSessionGroup = 101,
    BHMessageModelSessionChatGroup = 201,
    BHMessageModelSessionPerson = 1,
};

static NSString *kMessageHasRevoked = @"_Bers_Revoked_";

static unsigned long byte_length(NSString *str) {
    if(str == NULL) return 0L;
    const char *c_str = [str cStringUsingEncoding:NSUTF8StringEncoding];
    return strlen(c_str);
}

static NSString *get_snippet(NSString *str, unsigned long maxLength) {
    if (str == NULL) return NULL;
    if(byte_length(str) > maxLength) {
        NSString *snippet = [NSString stringWithFormat:@"%@...%@", [str substringToIndex:3], [str substringFromIndex:[str length] - 3]];
        return snippet;
    }
    return str;
}

@implementation NSObject (AnitiRevoking)

- (void)my_revokeMessage:(id<NSFastEnumeration>)messages {
    id topVC = [self topMsgListViewController];
    for (BHMessageModel *msg in messages) {
        NSString *info = [msg smallContent];
        NSString *msgType = @"Unknown";

        NSData *contentData = [info dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObject = [NSJSONSerialization JSONObjectWithData:contentData
                                        options:NSJSONReadingMutableLeaves
                                          error:nil];
        NSArray *jsonArray = nil;
        if ([jsonObject isKindOfClass:[NSArray class]]) {
            jsonArray = jsonObject;
        } else if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            jsonArray = @[jsonObject];
        }
        info = @"";
        for (NSDictionary *contentJSONDic in jsonArray) {
            if ([contentJSONDic valueForKey:@"msg-type"] != nil) {
                msgType = @"消息";
                NSString *text = [contentJSONDic valueForKey:@"text"];
                if (text == nil && [contentJSONDic valueForKey:@"image-width"] != nil) {
                    info = [info stringByAppendingString:@"[图片]"];
                } else if (text != nil) {
                    info = [info stringByAppendingString:text];
                }
            } else if ([contentJSONDic valueForKey:@"duration"] != nil) {
                msgType = @"语音";
                NSNumber *duration = [contentJSONDic valueForKey:@"duration"];
                info = [NSString stringWithFormat:@"时长%lu秒", [duration unsignedLongValue]];
            } else if ([contentJSONDic valueForKey:@"file_md5"] != nil) {
                msgType = @"文件";
                NSString *fileName = [contentJSONDic valueForKey:@"file_name"];
                info = fileName ? fileName : @"Unknown";
            } else if ([contentJSONDic valueForKey:@"text"]) {
                info = [contentJSONDic valueForKey:@"text"];
            }
        }
        NSString *content = get_snippet(info ,18);
        NSString *nickname = get_snippet([msg nickname], 18);
        if ([msg isSelfSend]) {
            nickname = @"我";
        } else if ([msg msgSessionType] == BHMessageModelSessionPerson) {
            nickname = @"对方";
        }
        NSString *str = [NSString stringWithFormat:@"%@ 撤回了%@: %@", nickname, msgType , content];
        [msg setSmallContent:str];
        
        [topVC appendMessage:msg];
    }
    [[topVC msgView] scrollToBottom];
}

- (id)my_getInfomativeMsgContent:(id)arg1 {
    int type = [arg1 msgType];
    if(type == 0x14c) {
        return [arg1 smallContent];
    } else {
        return [self my_getInfomativeMsgContent:arg1];
    }
}


- (void)my_solveRecallNotify:(struct RecallModel *)arg1 isOnline:(BOOL)arg2 {
    int original_type = 0x400;
    if (arg1->addr != arg1->addr2) {
        MsgDbService *db = [objc_getClass("MsgDbService") sharedInstance];
        NSString *identityUin = [[objc_getClass("QQDataCenter") GetInstance] uin];
        int sesstype = (uint32_t)arg1->sesstype;
        id model = [db getMessageWithUin:(sesstype == 0x65 || sesstype == 0xc9) ? arg1->groupUin : arg1->uin
                                sessType:sesstype
                             identityUin:[identityUin unsignedLongLongValue]
                                  msgSeq:arg1->addr->info->msgSeq
                                    time:arg1->addr->info->time
                                  random:arg1->addr->info->random];
        original_type = [model msgType];
        [model setMsgType:0x14c];
        NSString *keys[] = {@"type"};
        NSArray *keyArray = [NSArray arrayWithObjects:keys count:1];
        [db updateQQMessageModel:model keyArray:keyArray];
    }
    [self my_solveRecallNotify:arg1 isOnline:arg2];
    
    if (arg1->addr != arg1->addr2) {
        MsgDbService *db = [objc_getClass("MsgDbService") sharedInstance];
        NSString *uin = [[objc_getClass("QQDataCenter") GetInstance] uin];
        int sesstype = (uint32_t)arg1->sesstype;
        id model = [db getMessageWithUin:(sesstype == 0x65 || sesstype == 0xc9) ? arg1->groupUin : arg1->uin
                                sessType:sesstype
                             identityUin:[uin unsignedLongLongValue]
                                  msgSeq:arg1->addr->info->msgSeq
                                    time:arg1->addr->info->time
                                  random:arg1->addr->info->random];
        [model setMsgType:original_type];
        [[model exInfo] setStringValue:@"revoked" forKey:kMessageHasRevoked];
        NSString *keys[] = {@"type", @"exInfo"};
        NSArray *keyArray = [NSArray arrayWithObjects:keys count:2];
        [db updateQQMessageModel:model keyArray:keyArray];
    }
}

+ (BOOL)my_supportRevokeMessage:(id)arg1 {
    if ([[arg1 exInfo] stringValueForKey:kMessageHasRevoked]) {
        return NO;
    }
    return [objc_getClass("RevokeHelper") my_supportRevokeMessage:arg1];
}


@end


static void __attribute__((constructor)) initialize(void) {
    Class class = objc_getClass("MQAIOChatViewController");
    Method ori1 = class_getInstanceMethod(class, @selector(revokeMessages:));
    Method my1 = class_getInstanceMethod(class, @selector(my_revokeMessage:));
    method_exchangeImplementations(ori1, my1);
    
    Class class2 = objc_getClass("MQInfoMessageViewModel");
    Method ori2 = class_getInstanceMethod(class2, @selector(getInfomativeMsgContent:));
    Method my2 = class_getInstanceMethod(class2, @selector(my_getInfomativeMsgContent:));
    method_exchangeImplementations(ori2, my2);

    Class class3 = objc_getClass("RecallProcessor");
    Method ori3 = class_getInstanceMethod(class3, @selector(solveRecallNotify:isOnline:));
    Method my3 = class_getInstanceMethod(class3, @selector(my_solveRecallNotify:isOnline:));
    method_exchangeImplementations(ori3, my3);
    
    Class class4 = objc_getClass("RevokeHelper");
    Method ori4 = class_getClassMethod(class4, @selector(supportRevokeMessage:));
    Method my4 = class_getClassMethod(class4, @selector(my_supportRevokeMessage:));
    method_exchangeImplementations(ori4, my4);
    
    NSLog(@"---AnitiRevoking dylib inserted successfully");
    
}
