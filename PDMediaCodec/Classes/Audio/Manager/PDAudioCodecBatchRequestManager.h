//
//  PDAudioCodecBatchRequestManager.h
//  PDMediaCodec
//
//  Created by liang on 2021/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDAudioCodecBatchRequest;

/// @class PDAudioCodecBatchRequestManager
/// @brief 音频批量转码管理器
@interface PDAudioCodecBatchRequestManager : NSObject

@property (class, strong, readonly) PDAudioCodecBatchRequestManager *defaultManager;

- (void)addRequest:(PDAudioCodecBatchRequest *)request;
- (void)removeRequest:(PDAudioCodecBatchRequest *)request;

@end

NS_ASSUME_NONNULL_END
