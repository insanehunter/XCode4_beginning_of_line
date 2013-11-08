#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP original_doCommandBySelector = nil;

@interface Xcode_beginning_of_line : NSObject
@end

@implementation Xcode_beginning_of_line
static void doCommandBySelector( id self_, SEL _cmd, SEL selector )
{
    do {
        bool selectionModified = selector == @selector(moveToBeginningOfLineAndModifySelection:) ||
        selector == @selector(moveToLeftEndOfLineAndModifySelection:);
        
        if (selector == @selector(deleteToBeginningOfLine:) ||
            selector == @selector(moveToBeginningOfLine:) ||
            selector == @selector(moveToLeftEndOfLine:) || selectionModified)
        {
            NSTextView *self = (NSTextView *)self_;
            NSString *text = self.string;
            NSRange selectedRange = self.selectedRange;
            NSRange lineRange = [text lineRangeForRange:selectedRange];
            
            if (lineRange.length == 0)
                break;
            
            NSString *line = [text substringWithRange:lineRange];
            NSRange codeStartRange = [line rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
            
            if (codeStartRange.location == NSNotFound)
                break;
            
            NSUInteger caretLocation = selectedRange.location - lineRange.location;
            if (caretLocation < codeStartRange.location && caretLocation != 0)
                break;
            
            int start = lineRange.location;
            if (selectedRange.location != (lineRange.location + codeStartRange.location))
                start += codeStartRange.location;
            
            int end = selectionModified ? (selectedRange.location + selectedRange.length) : start;
            
            if (end - start < 0)
                break;
            
            NSRange range = NSMakeRange(start, end - start);
            
            if (selector == @selector(deleteToBeginningOfLine:)) {
                // handle deleteToBeginningOfLine: method
                NSRange deleteRange;
                if (caretLocation == codeStartRange.location) {
                    // we are already at the beginnig of code, delete all the way to start of line
                    deleteRange = NSMakeRange(lineRange.location, codeStartRange.location);
                }
                else {
                    // delete from caret to code start
                    deleteRange = NSMakeRange(lineRange.location+codeStartRange.location, caretLocation-codeStartRange.location);
                }
                
                [self setSelectedRange:deleteRange];
                // We cannot undo if we use -replaceCharactersInRange:withString:,
                // we need to use -insertText: to delete the text instead.
                [self insertText:@""];
            }
            else {
                // handle other methods
                [self setSelectedRange:range];
                [self scrollRangeToVisible:range];
            }
            
            return;
        }
    } while (0);
    
    return ((void (*)(id, SEL, SEL))original_doCommandBySelector)(self_, _cmd, selector);
}

+ (void) pluginDidLoad:(NSBundle *)plugin
{
    Class class = nil;
    Method originalMethod = nil;
    
    NSLog(@"%@ initializing...", NSStringFromClass([self class]));
    
    if (!(class = NSClassFromString(@"DVTSourceTextView")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(doCommandBySelector:))))
        goto failed;
    
    if (!(original_doCommandBySelector = method_setImplementation(originalMethod, (IMP)&doCommandBySelector)))
        goto failed;
    
    NSLog(@"%@ complete!", NSStringFromClass([self class]));
    return;
    
failed:
    NSLog(@"%@ failed :(", NSStringFromClass([self class]));
}
@end
