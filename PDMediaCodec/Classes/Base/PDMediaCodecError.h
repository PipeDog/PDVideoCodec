//
//  NEMediaCodecError.h
//  PDMediaCodec
//
//  Created by liang on 2021/1/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const PDCodecErrorDomain;

typedef NSInteger PDCodecErrorCode;

FOUNDATION_EXPORT PDCodecErrorCode const PDCodecFailedErrorCode;            ///< 通用解码错误
FOUNDATION_EXPORT PDCodecErrorCode const PDCodecCancelledErrorCode;         ///< 取消操作
FOUNDATION_EXPORT PDCodecErrorCode const PDInitVariableFailedErrorCode;     ///< 初始化变量失败
FOUNDATION_EXPORT PDCodecErrorCode const PDInvalidArgumentErrorCode;        ///< 无效参数
FOUNDATION_EXPORT PDCodecErrorCode const PDRemoveFileFailedErrorCode;       ///< 删除文件失败
FOUNDATION_EXPORT PDCodecErrorCode const PDCreateDirFailedErrorCode;        ///< 创建文件路径失败
FOUNDATION_EXPORT PDCodecErrorCode const PDUnrecognizedMediaTypeErrorCode;  ///< 未识别媒体类型错误

/// @brief 构建 NSError 实例
/// @param domain 错误域
/// @param code 错误码
/// @param fmt 错误信息
/// @return NSError 实例对象
FOUNDATION_EXPORT NSError *PDErrorWithDomain(NSErrorDomain domain, NSInteger code, NSString *fmt, ...);

/// @brief 构建 NSError 实例
/// @param code 错误码
/// @param fmt 错误信息
/// @return NSError 实例对象
FOUNDATION_EXPORT NSError *PDError(NSInteger code, NSString *fmt, ...);

/// @brief 获取 NSError 的 domain 内容
/// @param error NSError 实例对象
/// @return domain 内容
FOUNDATION_EXPORT NSErrorDomain PDErrorGetDomain(NSError *error);

/// @brief 获取 NSError 的错误码
/// @param error NSError 实例对象
/// @return 错误码
FOUNDATION_EXPORT NSInteger PDErrorGetCode(NSError *error);

/// @brief 获取 NSError 的错误信息
/// @param error NSError 实例对象
/// @return 错误信息
FOUNDATION_EXPORT NSString *PDErrorGetMessage(NSError *error);

NS_ASSUME_NONNULL_END
