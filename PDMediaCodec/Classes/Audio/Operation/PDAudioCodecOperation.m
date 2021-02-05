//
//  PDAudioCodecOperation.m
//  PDMediaCodec
//
//  Created by liang on 2021/2/3.
//

#import "PDAudioCodecOperation.h"
#import "PDMediaCodecError.h"
#import "PDMediaCodecUtil.h"

@implementation PDAudioCodecOperation

- (instancetype)initWithRequest:(PDAudioCodecRequest *)request delegate:(id<PDAudioCodecOperationDelegate>)delegate {
    if (!request || !delegate) {
        NSAssert(NO, @"The arguments `request` and `delegate` can not be nil!");
        return nil;
    }
    
    self = [super init];
    if (self) {
        _request = request;
        _delegate = delegate;
        
        NSAssert([_delegate respondsToSelector:@selector(operationDidFinishCodec:)] &&
                 [_delegate respondsToSelector:@selector(operation:didFailCodecWithError:)],
                 @"These methods should be impl!");
    }
    return self;
}

- (BOOL)prepareRunningContextWithError:(NSError **)error {
    BOOL isDir = NO;
    BOOL srcExist = [[NSFileManager defaultManager] fileExistsAtPath:self.request.srcURL.path isDirectory:&isDir];
    if (!srcExist || isDir) {
        *error = PDErrorWithDomain(PDCodecErrorDomain, PDInvalidArgumentErrorCode,
                                   @"Can not found local file for request `%@`!", self.request);
        return NO;
    }
    
    unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:self.request.srcURL.path error:nil].fileSize;
    if (!fileSize) {
        *error = PDErrorWithDomain(PDCodecErrorDomain, PDInvalidArgumentErrorCode,
                                   @"Src file size is invalid for request `%@`!", self.request);
        return NO;
    }
    
    isDir = NO;
    BOOL dstExist = [[NSFileManager defaultManager] fileExistsAtPath:self.request.dstURL.path isDirectory:&isDir];
    if (dstExist && !isDir) {
        if (![[NSFileManager defaultManager] removeItemAtPath:self.request.dstURL.path error:nil]) {
            *error = PDErrorWithDomain(PDCodecErrorDomain, PDRemoveFileFailedErrorCode,
                                       @"Remove file failed for request `%@`!", self.request);
            return NO;
        }
    }
    
    NSString *dirPath = [self.request.dstURL.path stringByDeletingLastPathComponent]; isDir = NO;
    BOOL dirExist = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir];
    if (!dirExist || !isDir) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            *error = PDErrorWithDomain(PDCodecErrorDomain, PDCreateDirFailedErrorCode,
                                       @"Create dir path failed for request `%@`!", self.request);
            return NO;
        }
    }
    
    return YES;
}

- (void)notifyWithResult:(BOOL)result error:(NSError *)error {
    PDDispatchOnMainQueue(^{
        !self.request.doneHandler ?: self.request.doneHandler(result, error);
        
        if (result) {
            if ([self.delegate respondsToSelector:@selector(operationDidFinishCodec:)]) {
                [self.delegate operationDidFinishCodec:self];
            }
            return;
        }
        
        NSAssert(error, @"The argument `error` can not be nil!");
        if ([self.delegate respondsToSelector:@selector(operation:didFailCodecWithError:)]) {
            [self.delegate operation:self didFailCodecWithError:error];
        }
    });
}

@end
