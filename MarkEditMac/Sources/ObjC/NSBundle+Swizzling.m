//
//  NSBundle+Swizzling.m
//  MarkEditMac
//
//  Created by cyan on 9/19/25.
//

#import "NSBundle+Swizzling.h"
#import <objc/runtime.h>

@implementation NSBundle (Swizzling)

+ (void)swizzleInfoDictionaryOnce {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class cls = [self class];
    SEL originalSelector = @selector(infoDictionary);
    SEL swizzledSelector = @selector(swizzled_infoDictionary);
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    if (class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
      class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod);
    }
  });
}

- (NSDictionary<NSString *, id> *)swizzled_infoDictionary {
  NSMutableDictionary *dict = [[self swizzled_infoDictionary] mutableCopy];
  dict[@"UIDesignRequiresCompatibility"] = @(YES);

  return dict;
}

@end
