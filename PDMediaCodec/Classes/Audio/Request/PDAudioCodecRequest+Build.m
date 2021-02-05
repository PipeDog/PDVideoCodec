//
//  PDAudioCodecRequest+Build.m
//  PDMediaCodec
//
//  Created by liang on 2021/2/1.
//

#import "PDAudioCodecRequest+Build.h"

@implementation PDAudioCodecRequest (Build)

+ (instancetype)requestWithBuilder:(void (^)(id<PDAudioCodecRequestBuilder> _Nonnull))block {
    PDAudioCodecRequest *request = [[self alloc] init];
    
    id<PDAudioCodecRequestBuilder> builder = (id<PDAudioCodecRequestBuilder>)request;
    !block ?: block(builder);
    
    NSAssert(builder.srcURL, @"The property `srcURL` can not be nil!");
    NSAssert(builder.dstURL, @"The property `dstURL` can not be nil!");
    return request;
}

@end
