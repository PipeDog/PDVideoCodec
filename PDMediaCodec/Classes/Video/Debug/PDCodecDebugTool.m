//
//  PDCodecDebugTool.m
//  PDMediaCodec
//
//  Created by liang on 2021/1/25.
//

#import "PDCodecDebugTool.h"

@implementation PDCodecDebugTool

+ (NSString *)fileSizeAtPath:(NSString *)filePath {
    unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil].fileSize;
    NSString *format = [self formatByte:fileSize];
    return format;
}

+ (void)saveMediaToAlbumWithPath:(NSString *)path {
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

#pragma mark - Private Methods
+ (NSString *)formatByte:(unsigned long long)byte {
    double convertedValue = byte;
    int multiplyFactor = 0;
    NSArray *tokens = @[@"B", @"KB", @"MB", @"GB", @"TB"];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor ++;
    }
    return [NSString stringWithFormat:@"%4.2f%@", convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

+ (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"保存视频失败 %@", error.localizedDescription);
    } else {
        NSLog(@"保存视频成功");
    }
}

@end
