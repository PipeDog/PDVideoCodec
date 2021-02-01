//
//  PDMediaCodecRequest+Build.m
//  PDMediaCodec
//
//  Created by liang on 2021/1/21.
//

#import "PDMediaCodecRequest+Build.h"

@implementation PDMediaCodecRequest (Build)

+ (instancetype)requestWithBuilder:(void (^)(id<PDMediaCodecRequestBuilder> _Nonnull))block {
    PDMediaCodecRequest *request = [[self alloc] init];
    
    id<PDMediaCodecRequestBuilder> builder = (id<PDMediaCodecRequestBuilder>)request;    
    !block ?: block(builder);
    
    NSAssert(builder.srcURL, @"The property `srcURL` can not be nil!");
    NSAssert(builder.dstURL, @"The property `dstURL` can not be nil!");
    return request;
}

@end
