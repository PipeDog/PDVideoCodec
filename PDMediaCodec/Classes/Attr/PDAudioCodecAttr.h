//
//  PDAudioCodecAttr.h
//  PDMediaCodec
//
//  Created by liang: on 2021/1/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// @class PDAudioCodecAttr
/// @brief 音频转码配置
@interface PDAudioCodecAttr : NSObject

@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *trackOutputSettings; ///< 采集输出配置
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *writeOutputSettings; ///< 转码目标配置

+ (instancetype)defaultCodecAttr;

@end

NS_ASSUME_NONNULL_END
