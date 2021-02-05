//
//  PDCodecDebugTool.h
//  PDMediaCodec
//
//  Created by liang on 2021/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDCodecDebugTool : NSObject

+ (NSString *)fileSizeAtPath:(NSString *)filePath;
+ (void)saveMediaToAlbumWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
