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

+ (WritingTool)requestedTool {
  for (NSWindow *window in [NSApp windows]) {
    NSViewController *controller = window.contentViewController;
    if ([controller.className isEqualToString:@"WTWritingToolsViewController"]) {
      controller = ^{
        // WTWritingToolsConfiguration
        NSInvocation *invocation = [self invocationWithTarget:controller
                                               selectorString:@"writingToolsConfiguration"];
        [invocation invoke];
        __unsafe_unretained id returnValue = nil;
        [invocation getReturnValue:&returnValue];
        return returnValue ?: controller;
      }();

      NSInvocation *invocation = [self invocationWithTarget:controller
                                             selectorString:@"requestedTool"];
      [invocation invoke];
      WritingTool returnValue = 0;
      [invocation getReturnValue:&returnValue];
      return returnValue;
    }
  }

  return WritingToolPanel;
}

+ (NSImage *)affordanceIcon {
  NSImageSymbolConfiguration *configuration = [NSImageSymbolConfiguration configurationWithPointSize:12.5 weight:NSFontWeightMedium];
  NSImage *symbolImage = [NSImage imageWithSystemSymbolName:@"apple.writing.tools" accessibilityDescription:nil] ?: [NSImage imageWithSystemSymbolName:@"_gm" accessibilityDescription:nil];
  if (symbolImage) {
    return [symbolImage imageWithSymbolConfiguration:configuration];
  }

  Class affordanceClass = NSClassFromString(@"WTAffordanceView");
  NSAssert(affordanceClass != nil, @"Missing WTAffordanceView class");

  NSView *affordanceView = [[affordanceClass alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  NSAssert(affordanceView != nil, @"Missing WTAffordanceView instance");

  for (NSImageView *imageView in affordanceView.subviews) {
    if ([imageView isKindOfClass:[NSImageView class]]) {
      return [imageView.image imageWithSymbolConfiguration:configuration];
    }
  }

  NSAssert(NO, @"Failed to retrieve affordance icon");
  return nil;
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

+ (BOOL)shouldReselectWithItem:(id)item {
  if (![item isKindOfClass:[NSMenuItem class]]) {
    return NO;
  }

  return [self shouldReselectWithTool:[(NSMenuItem *)item tag]];
}

+ (BOOL)shouldReselectWithTool:(WritingTool)tool {
  // Compose mode can start without text selections
  return tool != WritingToolCompose;
}

// MARK: - Private

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
  if (![target respondsToSelector:selector]) {
    NSLog(@"Missing method selector for: %@, %@", target, selectorString);
    return nil;
  }

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
