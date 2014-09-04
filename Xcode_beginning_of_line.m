#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP original_doCommandBySelector = nil;

@interface Xcode_beginning_of_line : NSObject
@end

@implementation Xcode_beginning_of_line

NSRange findMatchingBracket(NSString * text, NSRange range, bool forward, bool square, bool opening) {
    NSCharacterSet * charset = [NSCharacterSet characterSetWithCharactersInString:square?@"[]":@"()"];
    NSString * search = square?(opening?@"[":@"]"):(opening?@"(":@")");
    int level = 1;
    NSRange startRange = forward ? NSMakeRange(range.location, text.length - range.location - 1) : NSMakeRange(0, range.location + range.length - 1);
    while(1) {
        NSRange r = [text rangeOfCharacterFromSet:charset options:forward?0:NSBackwardsSearch range:startRange];
        if (r.location == NSNotFound) return range;
        if ([[text substringWithRange:r] isEqualToString:search]) {
            --level;
            if (level == 0) {
                if (r.location > range.location && r.location < (range.location + range.length)) {
                    return range;
                } else {
                    return forward ? NSMakeRange(range.location, r.location - range.location) : NSMakeRange(r.location + 1, range.location + range.length - r.location - 1);
                }
            }
        } else {
            ++level;
        }
        startRange = forward ? NSMakeRange(r.location + 1, text.length - r.location - 1) : NSMakeRange(0, r.location);
    }
}

NSRange leftExtendRange(NSString * text, NSRange range, NSCharacterSet * chr, NSRange lineRange) {
    NSRange backwardTo = [text rangeOfCharacterFromSet:chr options:NSBackwardsSearch range:NSMakeRange(0, range.location - 1)];
    if (backwardTo.location == NSNotFound) return range;
    if (backwardTo.location < lineRange.location) return NSMakeRange(lineRange.location, range.location + range.length - lineRange.location);
    return NSMakeRange(backwardTo.location + 1, range.location + range.length - backwardTo.location - 1);
}

NSRange rightExtendRange(NSString * text, NSRange range, NSCharacterSet * chr, NSRange lineRange) {
    NSUInteger end = range.location + range.length;
    NSRange forwardTo = [text rangeOfCharacterFromSet:chr options:0 range:NSMakeRange(end + 1, text.length - end - 1)];
    if (forwardTo.location == NSNotFound) return range;
    NSUInteger calculatedEnd = forwardTo.location - range.location;
    if ((range.location + calculatedEnd) > (lineRange.location + lineRange.length)) {
        calculatedEnd = lineRange.location + lineRange.length - range.location;
    }
    return NSMakeRange(range.location, calculatedEnd);
}

NSRange leftShrinkRange(NSString * text, NSRange range, NSCharacterSet * chr) {
    NSRange backwardTo = [text rangeOfCharacterFromSet:chr options:0 range:range];
    if (backwardTo.location == NSNotFound) return NSMakeRange(range.location + 1, range.length - 2);
    return NSMakeRange(backwardTo.location + 1, range.location + range.length - backwardTo.location - 2);
}


NSRange rightShrinkRange(NSString * text, NSRange range, NSCharacterSet * chr) {
    NSRange forwardTo = [text rangeOfCharacterFromSet:chr options:NSBackwardsSearch range:range];
    if (forwardTo.location == NSNotFound) return NSMakeRange(range.location+1, range.length - 1);
    return NSMakeRange(range.location + 1, forwardTo.location - range.location - 1);
}


static NSRange extendRange(NSString * text, NSRange range) {
    NSUInteger end = range.location + range.length;
    NSRange lineRange = [text lineRangeForRange:range];
    NSCharacterSet * spaces = [NSCharacterSet whitespaceCharacterSet];
    NSCharacterSet * nonAlpha = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSCharacterSet * nonSpaces = [spaces invertedSet];
    
    if (range.location > 0 && end < text.length) {
        unichar begChar = [text characterAtIndex:range.location - 1];
        unichar endChar = [text characterAtIndex:range.location + range.length];
        
        if (begChar == '"' && endChar != '"') {
            return rightExtendRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"\""], lineRange);
        }
        
        if (endChar == '"' && begChar != '"') {
            return leftExtendRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"\""], lineRange);
        }
        
        if (begChar == '(' && endChar != ')') {
            return findMatchingBracket(text, range, true, false, false);
        }
        
        if (endChar == ')' && begChar != '(') {
            return findMatchingBracket(text, range, false, false, true);
        }
        
        if (begChar == '[' && endChar != ']') {
            return findMatchingBracket(text, range, true, true, false);
        }
        
        if (endChar == ']' && begChar != '[') {
            return findMatchingBracket(text, range, false, true, true);
        }
        
        if (begChar == '.' && endChar != '.') {
            return leftExtendRange(text, range, nonAlpha, lineRange);
        }
        
        if (endChar == '.' && begChar != '.') {
            return rightExtendRange(text, range, nonAlpha, lineRange);
        }
        if (([spaces characterIsMember:begChar] && range.location > lineRange.location) || ([spaces characterIsMember:endChar] && end < (lineRange.location + lineRange.length))) {
            if ([spaces characterIsMember:begChar] && range.location > lineRange.location) {
                range = leftExtendRange(text, range, nonSpaces, lineRange);
            }
            if ([spaces characterIsMember:endChar] && end < (lineRange.location + lineRange.length)) {
                range = rightExtendRange(text, range, nonSpaces, lineRange);
            }
            return extendRange(text, range);
        }
    }
    
    NSUInteger backwardTo = basicSearchBack(text, range);
    NSUInteger forwardTo = basicSearchForward(text, range);
    
    NSUInteger calculatedEnd = forwardTo - backwardTo;
    if (forwardTo > (lineRange.location + lineRange.length)) {
        forwardTo = lineRange.location + lineRange.length;
        calculatedEnd = forwardTo - backwardTo;
    }
    if (backwardTo < lineRange.location) {
        backwardTo = lineRange.location;
        calculatedEnd = forwardTo - backwardTo;
    }
    return NSMakeRange(backwardTo, calculatedEnd);
}

NSUInteger basicSearchBack(NSString * text, NSRange range) {
    if (range.location < 1) return 0;
    NSRange backwardTo = [text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] options:NSBackwardsSearch range:NSMakeRange(0, range.location - 1)];
    if (backwardTo.location == NSNotFound) return 0;
    return backwardTo.location + 1;
}

NSUInteger basicSearchForward(NSString * text, NSRange range) {
    NSUInteger end = range.location + range.length;
    if (end > (text.length - 2)) return text.length;
    NSRange forwardTo = [text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] options:0 range:NSMakeRange(end + 1, text.length - end - 1)];
    if (forwardTo.location == NSNotFound) forwardTo.location = end + 1;
    return forwardTo.location;
}

static NSRange shrinkRange(NSString * text, NSRange range) {
    if (range.length < 2) return range;
    NSUInteger end = range.location + range.length;
    NSCharacterSet * spaces = [NSCharacterSet whitespaceCharacterSet];
    NSCharacterSet * nonSpaces = [spaces invertedSet];
    
    if (range.location > 0 && end < text.length) {
        unichar begChar = [text characterAtIndex:range.location];
        unichar endChar = [text characterAtIndex:range.location + range.length - 1];
        
        if (begChar == '"' && endChar != '"') {
            return rightShrinkRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"\""]);
        }
        
        if (endChar == '"' && begChar != '"') {
            return rightShrinkRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"\""]);
        }
        
        if (begChar == '(' && endChar != ')') {
            return rightShrinkRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@")"]);
        }
        
        if (endChar == ')' && begChar != '(') {
            return leftShrinkRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"("]);
        }
        
        if (begChar == '[' && endChar != ']') {
            return rightShrinkRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"]"]);
            return findMatchingBracket(text, range, true, true, false);
        }
        
        if (endChar == ']' && begChar != '[') {
            return leftShrinkRange(text, range, [NSCharacterSet characterSetWithCharactersInString:@"["]);
        }
        
        if ([spaces characterIsMember:begChar] || [spaces characterIsMember:endChar]) {
            if ([spaces characterIsMember:begChar]) {
                range = leftShrinkRange(text, range, nonSpaces);
            }
            if ([spaces characterIsMember:endChar]) {
                range = rightShrinkRange(text, range, nonSpaces);
            }
            return range;
        }
    }
    
    NSRange backwardTo = [text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] options:0 range:range];
    if (backwardTo.location == NSNotFound) return range;
    NSRange forwardTo = [text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] options:NSBackwardsSearch range:range];
    if (forwardTo.location == NSNotFound) return range;
    if (forwardTo.location <= backwardTo.location) return NSMakeRange(range.location, forwardTo.location - range.location);
    return NSMakeRange(backwardTo.location + 1, forwardTo.location - backwardTo.location - 1);
}

void wrapper(NSTextView * textView, SEL _cmd, SEL selector) {
    doCommandBySelector(textView, _cmd, selector);
}

static void doCommandBySelector( id self_, SEL _cmd, SEL selector )
{
    do {
        bool selectionModified = selector == @selector(moveToBeginningOfLineAndModifySelection:) ||
        selector == @selector(moveToLeftEndOfLineAndModifySelection:);
        
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
            /*if (caretLocation < codeStartRange.location && caretLocation != 0)
                break;*/
            
            NSUInteger start = lineRange.location;
            if (selectedRange.location != (lineRange.location + codeStartRange.location))
                start += codeStartRange.location;
            
            NSUInteger end = selectionModified ? (selectedRange.location + selectedRange.length) : start;
            
            if (end < start)
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
