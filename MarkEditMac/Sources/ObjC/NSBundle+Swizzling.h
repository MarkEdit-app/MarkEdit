//
//  NSBundle+Swizzling.h
//  MarkEditMac
//
//  Created by cyan on 9/19/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (Swizzling)

+ (void)swizzleInfoDictionaryOnce;

@end

NS_ASSUME_NONNULL_END
