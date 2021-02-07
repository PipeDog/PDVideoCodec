//
//  PDCodecUUID.h
//  PDMediaCodec
//
//  Created by liang on 2021/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDCodecUUID : NSObject

@property (readonly, copy) NSString *UUIDString;

+ (instancetype)UUID;
- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
