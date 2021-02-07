//
//  NEMediaCodecUtil.m
//  PDMediaCodec
//
//  Created by liang on 2021/1/24.
//

#import "PDMediaCodecUtil.h"

void PDDispatchOnMainQueue(void (^block)(void)) {
    if (0 == strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL),
                    dispatch_queue_get_label(dispatch_get_main_queue()))) {
        !block ?: block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            !block ?: block();
        });
    }
}
