#import <Foundation/Foundation.h>

@interface TestClass : NSObject
@property (nonatomic, strong) NSString *message;
- (void)displayMessage;
@end

@implementation TestClass
- (instancetype)init {
    self = [super init];
    if (self) {
        self.message = @"Hello Objective-C";
    }
    return self;
}

- (void)displayMessage {
    NSLog(@"%@", self.message);
}
@end

int main() {
    TestClass *test = [[TestClass alloc] init];
    [test displayMessage];
    return 0;
}