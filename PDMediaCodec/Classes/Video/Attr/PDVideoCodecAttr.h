//
//  PDVideoCodecAttr.h
//  PDMediaCodec
//
//  Created by liang: on 2021/1/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Auto fix video size constant value, width and height.
FOUNDATION_EXPORT CGFloat const PDVideoCodecVideoAutoFixWidthValue;
FOUNDATION_EXPORT CGFloat const PDVideoCodecVideoAutoFixHeightValue;

/// @class PDVideoCodecAttr
/// @brief 视频转码配置
@interface PDVideoCodecAttr : NSObject

@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *trackOutputSettings; ///< 采集输出配置
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *writeOutputSettings; ///< 转码目标配置

+ (instancetype)defaultCodecAttr;

@end

NS_ASSUME_NONNULL_END
