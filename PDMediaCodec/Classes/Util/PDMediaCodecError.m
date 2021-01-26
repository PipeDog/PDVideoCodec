//
//  NEMediaCodecError.m
//  PDMediaCodec
//
//  Created by liang on 2021/1/22.
//

#import "PDMediaCodecError.h"

NSErrorDomain const PDCodecErrorDomain = @"PDCodecErrorDomain";

PDCodecErrorCode const PDCodecFailedErrorCode           = 1000;
PDCodecErrorCode const PDCodecCancelledErrorCode        = 1001;
PDCodecErrorCode const PDInitVariableFailedErrorCode    = 2000;
PDCodecErrorCode const PDInvalidArgumentErrorCode       = 2001;
PDCodecErrorCode const PDRemoveFileFailedErrorCode      = 3000;
PDCodecErrorCode const PDCreateDirFailedErrorCode       = 3001;
PDCodecErrorCode const PDUnrecognizedMediaTypeErrorCode = 4000;

static NSString *const kPDErrorDomain = @"kPDErrorDomain";

NSError *PDErrorWithDomain(NSErrorDomain domain, NSInteger code, NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    
    NSError *error = [NSError errorWithDomain:domain code:code userInfo:@{@"message": message ?: @""}];
    return error;
}

NSError *PDError(NSInteger code, NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    
    NSError *error = [NSError errorWithDomain:kPDErrorDomain code:code userInfo:@{@"message": message ?: @""}];
    return error;
}

NSErrorDomain PDErrorGetDomain(NSError *error) {
    if (!error) {
        return nil;
    }
    return error.domain;
}

NSInteger PDErrorGetCode(NSError *error) {
    if (!error) {
        return 0;
    }
    return error.code;
}

NSString *PDErrorGetMessage(NSError *error) {
    if (!error) {
        return nil;
    }
    
    NSDictionary *userInfo = error.userInfo;
    NSString *message = userInfo[@"message"];
    return message;
}

