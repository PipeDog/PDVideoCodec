//
//  PDMediaCodecExecutor.h
//  PDMediaCodec
//
//  Created by liang on 2021/1/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDMediaCodecRequest;

/// @class PDMediaCodecExecutor
/// @brief 媒体资源编码执行器
@interface PDMediaCodecExecutor : NSObject

@property (nonatomic, weak, readonly, nullable) PDMediaCodecRequest *request;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRequest:(PDMediaCodecRequest *)request NS_DESIGNATED_INITIALIZER;

- (void)executeWithDoneHandler:(void (^)(BOOL success, NSError * _Nullable error))doneHandler;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
