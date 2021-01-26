//
//  PDMediaCodecRequest+Build.h
//  PDMediaCodec
//
//  Created by liang on 2021/1/21.
//

#import "PDMediaCodecRequest.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PDMediaCodecRequestBuilder <NSObject>

@property (nonatomic, strong) NSURL *srcURL;
@property (nonatomic, strong) NSURL *dstURL;
@property (nonatomic, strong) PDVideoCodecAttr *videoCodecAttr;
@property (nonatomic, strong) PDAudioCodecAttr *audioCodecAttr;

@end

/// @category PDMediaCodecRequest+Build
/// @brief 转码请求构造类目
@interface PDMediaCodecRequest (Build)

+ (instancetype)requestWithBuilder:(void (^)(id<PDMediaCodecRequestBuilder> builder))block;

@end

NS_ASSUME_NONNULL_END
