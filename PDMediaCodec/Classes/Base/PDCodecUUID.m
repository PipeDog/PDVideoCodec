//
//  PDCodecUUID.m
//  PDMediaCodec
//
//  Created by liang on 2021/2/7.
//

#import "PDCodecUUID.h"

@implementation PDCodecUUID

static NSUInteger counter = 0;

+ (instancetype)UUID {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self executeBlock:^{
            counter++;
            self->_UUIDString = [NSString stringWithFormat:@"%lu", (unsigned long)counter];
        }];
    }
    return self;
}

- (void)executeBlock:(void (^)(void))block {
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    !block ?: block();
    dispatch_semaphore_signal(lock);
}

@end
