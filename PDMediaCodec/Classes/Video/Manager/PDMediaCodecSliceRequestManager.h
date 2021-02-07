//
//  PDMediaCodecSliceRequestManager.h
//  PDMediaCodec
//
//  Created by liang on 2021/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDMediaCodecSliceRequest;

/// @class PDMediaCodecSliceRequestManager
/// @brief 视频切片转码管理器
@interface PDMediaCodecSliceRequestManager : NSObject

@property (class, strong, readonly) PDMediaCodecSliceRequestManager *defaultManager;

- (void)addRequest:(PDMediaCodecSliceRequest *)request;
- (void)removeRequest:(PDMediaCodecSliceRequest *)request;

@end

NS_ASSUME_NONNULL_END
