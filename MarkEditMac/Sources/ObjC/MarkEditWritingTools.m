//
//  MarkEditWritingTools.m
//  MarkEditMac
//
//  Created by cyan on 8/14/24.
//

#import "MarkEditWritingTools.h"

@implementation MarkEditWritingTools

+ (BOOL)isAvailable {
  NSInvocation *invocation = [self invocationWithTarget:[NSTextView class]
                                         selectorString:@"_supportsWritingTools"];
  [invocation invoke];

  BOOL returnValue = NO;
  [invocation getReturnValue:&returnValue];
  return returnValue;
}

+ (void)showTool:(WritingTool)tool
            rect:(CGRect)rect
            view:(NSView *)view
        delegate:(id)delegate {
  NSString *selectorString = @"showTool:forSelectionRect:ofView:forDelegate:";
  NSInvocation *invocation = [self invocationWithTarget:[self writingToolsInstance]
                                         selectorString:selectorString];

  [invocation setArgument:&tool atIndex:2];
  [invocation setArgument:&rect atIndex:3];
  [invocation setArgument:&view atIndex:4];
  [invocation setArgument:&delegate atIndex:5];
  [invocation invoke];
}

+ (id)writingToolsInstance {
  NSInvocation *invocation = [self invocationWithTarget:NSClassFromString(@"WTWritingTools")
                                         selectorString:@"sharedInstance"];
  [invocation invoke];

  __unsafe_unretained id returnValue = nil;
  [invocation getReturnValue:&returnValue];

  NSAssert(returnValue != nil, @"Failed to get WTWritingTools instance");
  return returnValue;
}

+ (NSInvocation *)invocationWithTarget:(id)target
                        selectorString:(NSString *)selectorString {
  SEL selector = NSSelectorFromString(selectorString);
  NSMethodSignature *signature = [target methodSignatureForSelector:selector];
  if (signature == nil) {
    NSAssert(NO, @"Missing method signature for: %@, %@", target, selectorString);
    return nil;
  }

  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  invocation.target = target;
  invocation.selector = selector;
  return invocation;
}

@end
