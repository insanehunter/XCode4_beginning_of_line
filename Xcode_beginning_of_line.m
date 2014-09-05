#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP original_doCommandBySelector = nil;

@interface Xcode_beginning_of_line : NSObject
@end

@implementation Xcode_beginning_of_line

NSUInteger matchingBracketPosition(NSString * text, NSRange range, bool isForward, unichar bracket) {
    unichar pair = 0;
    switch (bracket) {
        case '}':
            pair = '{';
            break;
        case '{':
            pair = '}';
            break;
        case '[':
            pair = ']';
            break;
        case ']':
            pair = '[';
            break;
        case '(':
            pair = ')';
            break;
        case ')':
            pair = '(';
            break;
    }
    NSString * searchStr = [NSString stringWithCharacters:&pair length:1];
    NSRange r = range;
    int level = 1;
    NSCharacterSet * searchset = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%c%c", bracket, pair]];
    while(true) {
        r = [text rangeOfCharacterFromSet:searchset options:isForward?0:NSBackwardsSearch range:r];
        if (r.location == NSNotFound) return NSNotFound;
        if ([[text substringWithRange:r] isEqualToString:searchStr]) {
            --level;
            if (level == 0) {
                return r.location;
            }
        } else {
            ++level;
        }
        r = isForward ? NSMakeRange(r.location + 1, range.location + range.length - r.location - 1) : NSMakeRange(range.location, r.location - range.location);
    }
}

NSUInteger matchingQuotePosition(NSString * text, NSUInteger position, bool isDouble) {
    int count = 0;
    NSString * searchStr = isDouble ? @"\"" : @"'";
    NSCharacterSet * searchSet = [NSCharacterSet characterSetWithCharactersInString:searchStr];
    bool countForward = position > (text.length - position);
    NSUInteger currPosition = countForward ? position : position;
    while (true) {
        currPosition = symbolsFromSetPosition(text, countForward ? NSMakeRange(currPosition + 1, text.length - currPosition - 1) : NSMakeRange(0, currPosition), countForward, searchSet);
        if (currPosition == NSNotFound) break;
        if (currPosition == 0 || (![[text substringWithRange:NSMakeRange(currPosition - 1, 1)] isEqualToString:@"\\"])) count++;
    }
    bool searchForward = countForward ^ (count%2 == 0);
    currPosition = searchForward ? position : position;
    while (true) {
        currPosition = symbolsFromSetPosition(text, searchForward ? NSMakeRange(currPosition + 1, text.length - currPosition - 1) : NSMakeRange(0, currPosition), searchForward, searchSet);
        if (currPosition == NSNotFound) return NSNotFound;
        if (currPosition == 0 || (![[text substringWithRange:NSMakeRange(currPosition - 1, 1)] isEqualToString:@"\\"])) return currPosition;
    }
}

NSUInteger symbolsFromSetPosition(NSString * text, NSRange range, bool isForward, NSCharacterSet * set) {
    NSRange r = [text rangeOfCharacterFromSet:set options:isForward ? 0 : NSBackwardsSearch range:range];
    return r.location;
}

NSRange extendRangeToMatchingQuote(NSString * text, NSRange range, NSUInteger position, bool isDouble) {
    NSUInteger bPos = matchingQuotePosition(text, position, isDouble);
    if (bPos == NSNotFound || (bPos > range.location && bPos < (range.location + range.length)))
        return position < range.location ? NSMakeRange(position, range.location + range.length - position) : NSMakeRange(range.location, position + 1 - range.location);
    if (bPos < position) return NSMakeRange(bPos, position + 1 - bPos);
    return NSMakeRange(position, bPos + 1 - position);
}

NSRange shrinkRangeToMatchingQuote(NSString * text, NSRange range, NSUInteger position, bool isDouble) {
    bool begin = (position == range.location);
    NSUInteger bPos = matchingQuotePosition(text, position, isDouble);
    if (bPos == NSNotFound || bPos < range.location || bPos > (range.location + range.length))
        return begin ? NSMakeRange(position, range.location + range.length - position) : NSMakeRange(range.location, position + 1 - range.location);
    if (bPos < position) return NSMakeRange(bPos, position + 1 - bPos);
    return NSMakeRange(position, bPos + 1- position);
}

NSRange extendRangeToMatchingBracket(NSString * text, NSRange range, NSRange lineRange, NSUInteger position, unichar bracket, bool isForward) {
    NSRange searchRange = isForward ? NSMakeRange(position + 1, lineRange.location + lineRange.length - position - 1) : NSMakeRange(lineRange.location, position - lineRange.location);
    NSUInteger bPos = matchingBracketPosition(text, searchRange, isForward, bracket);
    if (bPos == NSNotFound || (bPos > range.location && bPos < (range.location + range.length)))
        return isForward ? NSMakeRange(position, range.location + range.length - position) : NSMakeRange(range.location, position - range.location);
    if (isForward) return NSMakeRange(range.location, bPos - range.location);
    return NSMakeRange(bPos, range.location + range.length + 1 - bPos);
}

NSRange shrinkRangeToMatchingBracket(NSString * text, NSRange range, NSUInteger position, unichar bracket, bool isForward) {
    NSRange searchRange = isForward ? NSMakeRange(position + 1, range.location + range.length - position - 1) : NSMakeRange(range.location, position - range.location);
    NSUInteger bPos = matchingBracketPosition(text, searchRange, isForward, bracket);
    if (bPos == NSNotFound)
        return isForward ? NSMakeRange(position + 1, range.location + range.length - position - 1) : NSMakeRange(range.location, position - 1 - range.location);
    if (isForward) return NSMakeRange(range.location, bPos + 1 - range.location);
    return NSMakeRange(bPos, range.location + range.length - bPos);
}

NSRange extendRangeToSymbolFromSet(NSString * text, NSRange range, NSRange lineRange, NSCharacterSet * charset, bool isForward) {
    NSRange searchRange = isForward ? NSMakeRange(range.location + range.length, lineRange.location + lineRange.length - range.location - range.length) : NSMakeRange(lineRange.location, range.location - lineRange.location);
    NSUInteger sPos = symbolsFromSetPosition(text, searchRange, isForward, charset);
    if (sPos == NSNotFound) return range;
    if (isForward) return NSMakeRange(range.location, sPos - range.location);
    return NSMakeRange(sPos + 1, range.location + range.length - sPos - 1);
}

NSRange shrinkRangeToSymbolFromSet(NSString * text, NSRange range, NSCharacterSet * charset, bool isForward) {
    NSRange searchRange = isForward ? NSMakeRange(range.location + 1, range.length - 1) : NSMakeRange(range.location, range.length - 1);
    NSUInteger sPos = symbolsFromSetPosition(text, searchRange, isForward, charset);
    if (sPos == NSNotFound) return searchRange;
    if (isForward) return NSMakeRange(sPos, range.location + range.length - sPos);
    return NSMakeRange(range.location, sPos + 1 - range.location);
}

NSRange extendRange(NSString * text, NSRange range) {
    NSUInteger end = range.location + range.length;
    NSRange lineRange = [text lineRangeForRange:range];
    NSCharacterSet * alpha = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet * spaces = [NSCharacterSet whitespaceCharacterSet];
    NSCharacterSet * nonAlpha = [alpha invertedSet];
    NSCharacterSet * nonSpaces = [spaces invertedSet];
    
    bool hasBefore = (range.location > lineRange.location && symbolsFromSetPosition(text, NSMakeRange(lineRange.location, range.location - lineRange.location), false, nonSpaces) != NSNotFound);
    bool hasAfter = ((lineRange.location + lineRange.length) > end && symbolsFromSetPosition(text, NSMakeRange(end, lineRange.location + lineRange.length - end), true, nonSpaces) != NSNotFound);
    
    if (range.location > 0 && end < text.length) {
        unichar begChar = [text characterAtIndex:range.location - 1];
        unichar endChar = [text characterAtIndex:range.location + range.length];
        
        if (begChar == '"' && endChar != '"') {
            return extendRangeToMatchingQuote(text, range, range.location - 1, true);
        }
        
        if (endChar == '"' && begChar != '"') {
            return extendRangeToMatchingQuote(text, range, range.location + range.length, true);
        }
        
        if (begChar == '\'' && endChar != '\'') {
            return extendRangeToMatchingQuote(text, range, range.location - 1, false);
        }
        
        if (endChar == '\'' && begChar != '\'') {
            return extendRangeToMatchingQuote(text, range, range.location + range.length, false);
        }
        
        if (begChar == '(') {
            NSUInteger pos = matchingBracketPosition(text, NSMakeRange(range.location, lineRange.location + lineRange.length - range.location), true, begChar);
            if (pos != NSNotFound && pos != end)
                return extendRangeToMatchingBracket(text, range, lineRange, range.location - 1, begChar, true);
        }
        
        if (endChar == ')') {
            NSUInteger pos = matchingBracketPosition(text, NSMakeRange(lineRange.location, range.location + range.length - lineRange.location), false, endChar);
            if (pos != NSNotFound && pos != (range.location - 1))
                return extendRangeToMatchingBracket(text, range, lineRange, range.location + range.length, endChar, false);
        }
        
        if (endChar == '(') {
            NSRange r = extendRangeToMatchingBracket(text, range, lineRange, range.location + range.length, endChar, true);
            return NSMakeRange(r.location, r.length + 1);
        }
        
        if (begChar == ')') {
            NSRange r = extendRangeToMatchingBracket(text, range, lineRange, range.location - 1, begChar, false);
            return NSMakeRange(r.location - 1, r.length + 1);
        }
        
        if (begChar == '[') {
            NSUInteger pos = matchingBracketPosition(text, NSMakeRange(range.location, lineRange.location + lineRange.length - range.location), true, begChar);
            if (pos != NSNotFound && pos != end)
                return extendRangeToMatchingBracket(text, range, lineRange, range.location - 1, begChar, true);
        }
        
        if (endChar == ']') {
            NSUInteger pos = matchingBracketPosition(text, NSMakeRange(lineRange.location, range.location + range.length - lineRange.location), false, endChar);
            if (pos != NSNotFound && pos != (range.location - 1))
                return extendRangeToMatchingBracket(text, range, lineRange, range.location + range.length, endChar, false);
        }
        
        if (begChar == '.' && endChar != '.') {
            return extendRangeToSymbolFromSet(text, NSMakeRange(range.location - 1, range.length + 1), lineRange, nonAlpha, false);
        }
        
        if (endChar == '.' && begChar != '.') {
            return extendRangeToSymbolFromSet(text, NSMakeRange(range.location, range.length + 1), lineRange, nonAlpha, true);
        }
        
        if ([alpha characterIsMember:begChar] && ![alpha characterIsMember:endChar]) {
            return extendRangeToSymbolFromSet(text, range, lineRange, nonAlpha, false);
        }
        
        if (([spaces characterIsMember:begChar] && range.location > lineRange.location) || ([spaces characterIsMember:endChar] && end < (lineRange.location + lineRange.length))) {
            bool changes = false;
            if ([spaces characterIsMember:begChar] && range.location > lineRange.location && hasBefore) {
                range = extendRangeToSymbolFromSet(text, range, lineRange, nonSpaces, false);
                changes = true;
            }
            if ([spaces characterIsMember:endChar] && end < (lineRange.location + lineRange.length) && hasAfter) {
                range = extendRangeToSymbolFromSet(text, range, lineRange, nonSpaces, true);
                changes = true;
            }
            if (changes) return extendRange(text, range);
            //return range;
        }
    }
    
    NSUInteger backwardTo = range.location;
    if (hasBefore) {
        backwardTo = symbolsFromSetPosition(text, NSMakeRange(lineRange.location, range.location - lineRange.location), false, nonAlpha);
        if (backwardTo == NSNotFound) backwardTo = lineRange.location;
        else backwardTo++;
        if (backwardTo == range.location && backwardTo > lineRange.location) backwardTo--;
    }
    
    NSUInteger forwardTo = end - 1;
    if (hasAfter) {
        forwardTo = symbolsFromSetPosition(text, NSMakeRange(range.location + range.length, lineRange.location + lineRange.length - range.location - range.length), true, nonAlpha);
        if (forwardTo == NSNotFound) forwardTo = lineRange.location + lineRange.length - 1;
        else forwardTo--;
        
        if (forwardTo == (range.location + range.length - 1) && forwardTo < (lineRange.location + lineRange.length - 1)) forwardTo++;
    }
    
    NSUInteger calculatedEnd = forwardTo - backwardTo + 1;
    return NSMakeRange(backwardTo, calculatedEnd);
}

NSRange shrinkRange(NSString * text, NSRange range) {
    if (range.length < 2) return range;
    NSUInteger end = range.location + range.length;
    NSCharacterSet * spaces = [NSCharacterSet whitespaceCharacterSet];
    NSCharacterSet * nonSpaces = [spaces invertedSet];
    NSCharacterSet * nonAlpha = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    
    unichar begChar = [text characterAtIndex:range.location];
    unichar endChar = [text characterAtIndex:range.location + range.length - 1];
    
    if (begChar == '"' && endChar != '"') {
        return shrinkRangeToMatchingQuote(text, range, range.location, true);
    }
    
    if (endChar == '"' && begChar != '"') {
        return shrinkRangeToMatchingQuote(text, range, range.location + range.length - 1, true);
    }
    
    if (begChar == '\'' && endChar != '\'') {
        return shrinkRangeToMatchingQuote(text, range, range.location, false);
    }
    
    if (endChar == '\'' && begChar != '\'') {
        return shrinkRangeToMatchingQuote(text, range, range.location + range.length - 1, false);
    }
    
    if (begChar == '(') {
        NSUInteger pos = matchingBracketPosition(text, NSMakeRange(range.location + 1, range.length - 1), true, begChar);
        if (pos != NSNotFound && pos != (end - 1))
            return shrinkRangeToMatchingBracket(text, range, range.location, begChar, true);
        if (pos != NSNotFound) return NSMakeRange(range.location + 1, range.length - 2);
    }
    
    if (endChar == ')') {
        NSUInteger pos = matchingBracketPosition(text, NSMakeRange(range.location, range.length - 1), false, endChar);
        if (pos != NSNotFound && pos != (range.location - 1))
            return shrinkRangeToMatchingBracket(text, range, range.location + range.length - 1, endChar, false);
        if (pos != NSNotFound) return NSMakeRange(range.location + 1, range.length - 2);
    }
    
    if (begChar == '[') {
        NSUInteger pos = matchingBracketPosition(text, NSMakeRange(range.location + 1, range.length - 1), true, begChar);
        if (pos != NSNotFound && pos != end)
            return shrinkRangeToMatchingBracket(text, range, range.location, begChar, true);
        if (pos != NSNotFound) return NSMakeRange(range.location + 1, range.length - 2);
    }
    
    if (endChar == ']') {
        NSUInteger pos = matchingBracketPosition(text, NSMakeRange(range.location, range.length - 1), false, endChar);
        if (pos != NSNotFound && pos != (range.location - 1))
            return shrinkRangeToMatchingBracket(text, range, range.location + range.length - 1, endChar, false);
        if (pos != NSNotFound) return NSMakeRange(range.location + 1, range.length - 2);
    }
    
    if ([spaces characterIsMember:begChar] || [spaces characterIsMember:endChar]) {
        if ([spaces characterIsMember:begChar]) {
            range = shrinkRangeToSymbolFromSet(text, range, nonSpaces, true);
        }
        if ([spaces characterIsMember:endChar]) {
            range = shrinkRangeToSymbolFromSet(text, range, nonSpaces, false);
        }
        return range;
    }
    
    NSUInteger backwardTo = symbolsFromSetPosition(text, range, true, nonAlpha);
    if (backwardTo == NSNotFound) backwardTo = range.location + 1;
    NSUInteger forwardTo = symbolsFromSetPosition(text, range, false, nonAlpha);
    if (forwardTo == NSNotFound) forwardTo = range.location + range.length - 2;
    
    if (backwardTo < forwardTo) return NSMakeRange(backwardTo, forwardTo - backwardTo);
    return range;
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
