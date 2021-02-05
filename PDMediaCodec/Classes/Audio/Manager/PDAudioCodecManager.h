//
//  PDAudioCodecManager.h
//  PDMediaCodec
//
//  Created by liang on 2021/2/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDAudioCodecRequest;

/// @class PDAudioCodecManager
/// @brief 音频转码管理器
@interface PDAudioCodecManager : NSObject

@property (class, strong, readonly) PDAudioCodecManager *defaultManager;

- (void)setMaxConcurrentCodecCount:(NSInteger)maxConcurrentCodecCount;

- (void)addRequest:(PDAudioCodecRequest *)request;
- (void)cancelRequest:(PDAudioCodecRequest *)request;
- (void)cancenAllRequests;

@end

NS_ASSUME_NONNULL_END
