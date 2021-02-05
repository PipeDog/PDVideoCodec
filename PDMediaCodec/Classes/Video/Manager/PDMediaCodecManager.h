//
//  PDMediaCodecManager.h
//  PDMediaCodec
//
//  Created by liang: on 2021/1/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDMediaCodecRequest;

/// @class PDMediaCodecManager
/// @brief 媒体资源编码管理器
@interface PDMediaCodecManager : NSObject

@property (class, strong, readonly) PDMediaCodecManager *defaultManager;

- (void)setMaxConcurrentCodecCount:(NSUInteger)maxConcurrentCodecCount;

- (void)addRequest:(PDMediaCodecRequest *)request;
- (void)cancelRequest:(PDMediaCodecRequest *)request;

@end

NS_ASSUME_NONNULL_END
