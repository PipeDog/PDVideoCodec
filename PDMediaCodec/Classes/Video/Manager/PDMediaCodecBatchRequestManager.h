//
//  PDMediaCodecBatchRequestManager.h
//  PDMediaCodec
//
//  Created by liang on 2021/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDMediaCodecBatchRequest;

/// @class PDMediaCodecBatchRequestManager
/// @brief 视频批量转码管理器
@interface PDMediaCodecBatchRequestManager : NSObject

@property (class, strong, readonly) PDMediaCodecBatchRequestManager *defaultManager;

- (void)addRequest:(PDMediaCodecBatchRequest *)request;
- (void)removeRequest:(PDMediaCodecBatchRequest *)request;

@end

NS_ASSUME_NONNULL_END
