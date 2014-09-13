#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP original_doCommandBySelector = nil;

@interface Xcode_beginning_of_line : NSObject
@end

@implementation Xcode_beginning_of_line

static NSRange leftExtendRange(NSString * text, NSRange range, NSCharacterSet * chr) {
    NSRange backwardTo = [text rangeOfCharacterFromSet:chr options:NSBackwardsSearch range:NSMakeRange(0, range.location - 1)];
    if (backwardTo.location == NSNotFound) return range;
    return NSMakeRange(backwardTo.location + 1, range.location + range.length - backwardTo.location - 1);
}

static NSRange rightExtendRange(NSString * text, NSRange range, NSCharacterSet * chr) {
    unsigned long end = range.location + range.length;
    NSRange forwardTo = [text rangeOfCharacterFromSet:chr options:0 range:NSMakeRange(end + 1, text.length - end - 1)];
    if (forwardTo.location == NSNotFound) return range;
    return NSMakeRange(range.location, forwardTo.location - range.location);
}

static NSRange extendRange(NSString * text, NSRange range) {
    unsigned long end = range.location + range.length;
    
    unichar begChar = [text characterAtIndex:range.location - 1];
    unichar endChar = [text characterAtIndex:range.location + range.length];
    
    if (begChar == '"' && endChar != '"') {
        return rightExtendRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"\""]);
    }
    
    if (endChar == '"' && begChar != '"') {
        return leftExtendRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"\""]);
    }
    
    if (begChar == '(' && endChar != ')') {
        return rightExtendRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@")"]);
    }
    
    if (endChar == ')' && begChar != '(') {
        return leftExtendRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"("]);
    }
    
    if (begChar == '[' && endChar != ']') {
        return rightExtendRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"]"]);
    }
    
    if (endChar == ']' && begChar != '[') {
        return leftExtendRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"["]);
    }
    
    if (begChar == '.' && endChar != '.') {
        return leftExtendRange(text, range, [[NSCharacterSet alphanumericCharacterSet] invertedSet]);
    }
    
    if (endChar == '.' && begChar != '.') {
        return rightExtendRange(text, range, [[NSCharacterSet alphanumericCharacterSet] invertedSet]);
    }
    
    NSRange backwardTo = [text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] options:NSBackwardsSearch range:NSMakeRange(0, range.location - 1)];
    if (backwardTo.location == NSNotFound) return range;
    NSRange forwardTo = [text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] options:0 range:NSMakeRange(end + 1, text.length - end - 1)];
    if (forwardTo.location == NSNotFound) return range;
    return NSMakeRange(backwardTo.location + 1, forwardTo.location - backwardTo.location - 1);
}

static NSRange shrinkRange(NSString * text, NSRange range) {
    NSRange backwardTo = [text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] options:0 range:range];
    if (backwardTo.location == NSNotFound) return range;
    NSRange forwardTo = [text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] options:NSBackwardsSearch range:range];
    if (forwardTo.location == NSNotFound) return range;
    if (forwardTo.location <= backwardTo.location) return NSMakeRange(range.location, forwardTo.location - range.location);
    return NSMakeRange(backwardTo.location + 1, forwardTo.location - backwardTo.location - 1);
}

static void doCommandBySelector( id self_, SEL _cmd, SEL selector )
{
    do {
        bool selectionModified = selector == @selector(moveToBeginningOfLineAndModifySelection:) ||
        selector == @selector(moveToLeftEndOfLineAndModifySelection:) ||
        selector == @selector(moveToBeginningOfParagraphAndModifySelection:);
        
        if (selector == @selector(deleteToBeginningOfLine:) ||
            selector == @selector(moveToBeginningOfLine:) ||
            selector == @selector(moveToBeginningOfParagraph:) ||
            selector == @selector(moveToLeftEndOfLine:) || selectionModified ||
            selector == @selector(moveParagraphBackwardAndModifySelection:) ||
            selector == @selector(moveParagraphForwardAndModifySelection:))
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
                if (selector == @selector(moveParagraphBackwardAndModifySelection:)) {
                    range = extendRange(text, selectedRange);
                }
                if (selector == @selector(moveParagraphForwardAndModifySelection:)) {
                    range = shrinkRange(text, selectedRange);
                }
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
    if (!(class = NSClassFromString(@"DVTSourceTextView")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(doCommandBySelector:))))
        goto failed;
    
    if (!(original_doCommandBySelector = method_setImplementation(originalMethod, (IMP)&doCommandBySelector)))
        goto failed;
    return;
    
failed:
    NSLog(@"%@ failed to launch :(", NSStringFromClass([self class]));
}
@end
