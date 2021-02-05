//
//  PDMediaCodecRequest.m
//  PDMediaCodec
//
//  Created by liang: on 2021/1/21.
//

#import "PDMediaCodecRequest.h"
#import "PDMediaCodecManager.h"

@implementation PDMediaCodecRequest

@synthesize srcURL = _srcURL;
@synthesize dstURL = _dstURL;
@synthesize outputFileType = _outputFileType;
@synthesize videoCodecAttr = _videoCodecAttr;
@synthesize audioCodecAttr = _audioCodecAttr;
@synthesize doneHandler = _doneHandler;

- (instancetype)init {
    self = [super init];
    if (self) {
        _outputFileType = AVFileTypeMPEG4;
        _videoCodecAttr = [PDVideoCodecAttr defaultCodecAttr];
        _audioCodecAttr = [PDAudioCodecAttr defaultCodecAttr];
    }
    return self;
}

- (instancetype)send {
    return [self sendWithDoneHandler:nil];
}

- (instancetype)sendWithDoneHandler:(void (^)(BOOL, NSError * _Nullable))doneHandler {
    self.doneHandler = doneHandler;
    [[PDMediaCodecManager defaultManager] addRequest:self];
    return self;
}

- (void)cancel {
    [[PDMediaCodecManager defaultManager] cancelRequest:self];
}

- (PDMediaCodecRequestID)requestID {
    PDMediaCodecRequestID requestID = [NSString stringWithFormat:@"%lu", (unsigned long)[self hash]];
    return requestID;
}

- (NSString *)description {
    NSMutableString *format = [NSMutableString string];
    [format appendString:@"\n<request : \n"];
    [format appendFormat:@"\t srcURL = %@, \n", self.srcURL];
    [format appendFormat:@"\t dstURL = %@, \n", self.dstURL];
    [format appendFormat:@"\t requestID = %@, \n", self.requestID];
    [format appendString:@">\n"];
    return format;
}

@end
