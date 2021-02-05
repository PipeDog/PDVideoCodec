//
//  PDAudioCodecRequest+Build.h
//  PDMediaCodec
//
//  Created by liang on 2021/2/1.
//

#import "PDAudioCodecRequest.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PDAudioCodecRequestBuilder <NSObject>

@property (nonatomic, strong) NSURL *srcURL;
@property (nonatomic, strong) NSURL *dstURL;
@property (nonatomic, strong) NEAudioFileType outputFileType;

@end

/// @category PDAudioCodecRequest+Build
/// @brief 音频转码请求构造类目
@interface PDAudioCodecRequest (Build)

+ (instancetype)requestWithBuilder:(void (^)(id<PDAudioCodecRequestBuilder> builder))block;

@end

NS_ASSUME_NONNULL_END
