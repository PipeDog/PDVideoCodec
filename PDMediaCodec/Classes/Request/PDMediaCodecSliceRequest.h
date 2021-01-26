//
//  PDMediaCodecSliceRequest.h
//  PDMediaCodec
//
//  Created by liang on 2021/1/23.
//
//  WARN:
//      经真机 case 验证，切片转码效率要低于直接转码，主要增加媒体资源切片、拼接两步操作，其中，资源切片开销
//      最大，具体的时间消耗与文件大小和单个切片的时间长度大小相关，切片越小，耗费时间越多，不建议使用切片转码
//

#import "PDMediaCodecRequest.h"

NS_ASSUME_NONNULL_BEGIN

/// @class PDMediaCodecSliceRequest
/// @brief 媒体资源切片转码
@interface PDMediaCodecSliceRequest : PDMediaCodecRequest

@end

NS_ASSUME_NONNULL_END
