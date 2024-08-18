//
//  MarkEditWritingTools.h
//  MarkEditMac
//
//  Created by cyan on 8/14/24.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(long long, WritingTool) {
  WritingToolPanel = 0,
  WritingToolProofread = 1,
  WritingToolRewrite = 2,
  WritingToolMakeFriendly = 11,
  WritingToolMakeProfessional = 12,
  WritingToolMakeConcise = 13,
  WritingToolSummarize = 21,
  WritingToolCreateKeyPoints = 22,
  WritingToolMakeList = 23,
  WritingToolMakeTable = 24,
} API_AVAILABLE(macos(15.1));

API_AVAILABLE(macos(15.1))
@interface MarkEditWritingTools : NSObject

@property (class, readonly, nonatomic) BOOL isAvailable;
@property (class, readonly, nonatomic) WritingTool requestedTool;
@property (class, readonly, nonatomic, nullable) NSImage *affordanceIcon;

+ (void)showTool:(WritingTool)tool
            rect:(CGRect)rect
            view:(NSView *)view
        delegate:(id)delegate;

@end

NS_ASSUME_NONNULL_END
