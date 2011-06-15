#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP original_doCommandBySelector = nil;

@interface XCode4_beginning_of_line : NSObject
@end

@implementation XCode4_beginning_of_line
static void doCommandBySelector( id self_, SEL _cmd, SEL selector )
{
    if (selector == @selector(moveToBeginningOfLine:))
    {
        NSTextView *self = (NSTextView *)self_;
        NSString *text = self.string;
        NSRange selectedRange = self.selectedRange;
        NSRange lineRange = [text lineRangeForRange:selectedRange];
        if (lineRange.length != 0)
        {
            NSString *line = [text substringWithRange:lineRange];
            NSRange codeStartRange = [line rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
            if (codeStartRange.location != NSNotFound)
            {
                NSUInteger caretLocation = selectedRange.location - lineRange.location;
                if (caretLocation > codeStartRange.location || caretLocation == 0)
                {
                    [self setSelectedRange:NSMakeRange(lineRange.location + codeStartRange.location, 0)];
                    return;
                }
            }
        }
    }
    return ((void (*)(id, SEL, SEL))original_doCommandBySelector)(self_, _cmd, selector);
}

+ (void) pluginDidLoad:(NSBundle *)plugin
{
    Class class = nil;
    Method originalMethod = nil;
    
    if (!(class = NSClassFromString(@"DVTSourceTextView")))
        return;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(doCommandBySelector:))))
        return;
    
    if (!(original_doCommandBySelector = method_setImplementation(originalMethod, (IMP)&doCommandBySelector)))
        return;
}
@end
