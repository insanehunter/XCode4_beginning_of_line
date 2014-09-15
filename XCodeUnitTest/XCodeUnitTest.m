//
//  XCodeUnitTest.m
//  XCodeUnitTest
//
//  Created by Dmitry Matyushkin on 03/09/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

@interface XCodeUnitTest : XCTestCase

@end

extern void wrapper(NSTextView * textView, SEL _cmd, SEL selector);

extern NSUInteger matchingBracketPosition(NSString * text, NSRange range, bool isForward, unichar bracket);
extern NSUInteger symbolsFromSetPosition(NSString * text, NSRange range, bool isForward, NSCharacterSet * set);
extern NSUInteger matchingQuotePosition(NSString * text, NSUInteger position, bool isDouble);
extern NSRange extendRangeToMatchingQuote(NSString * text, NSRange range, NSUInteger position, bool isDouble);
extern NSRange shrinkRangeToMatchingQuote(NSString * text, NSRange range, NSUInteger position, bool isDouble);
extern NSRange extendRangeToMatchingBracket(NSString * text, NSRange range, NSRange lineRange, NSUInteger position, unichar bracket, bool isForward);
extern NSRange shrinkRangeToMatchingBracket(NSString * text, NSRange range, NSUInteger position, unichar bracket, bool isForward);
extern NSRange extendRangeToSymbolFromSet(NSString * text, NSRange range, NSRange lineRange, NSCharacterSet * charset, bool isForward);
extern NSRange shrinkRangeToSymbolFromSet(NSString * text, NSRange range, NSCharacterSet * charset, bool isForward);
extern NSRange extendRange(NSString * text, NSRange range);
extern NSRange shrinkRange(NSString * text, NSRange range);


@implementation XCodeUnitTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testMatchingBracketPosition {
    NSString * text = @"( aaa ( bbb ( ccc ) ddd ) eee ) fff";
    NSUInteger c = matchingBracketPosition(text, NSMakeRange(2, text.length - 2), true, '(');
    XCTAssertEqual(c, 30);
    c = matchingBracketPosition(text, NSMakeRange(0, text.length), true, '(');
    XCTAssertEqual(c, NSNotFound);
    c = matchingBracketPosition(text, NSMakeRange(8, text.length - 8), true, '(');
    XCTAssertEqual(c, 24);
    c = matchingBracketPosition(text, NSMakeRange(8, text.length - 8), true, ')');
    XCTAssertEqual(c, 12);
    
    c = matchingBracketPosition(text, NSMakeRange(0, text.length - 8), false, ')');
    XCTAssertEqual(c, 0);
    c = matchingBracketPosition(text, NSMakeRange(0, text.length), false, ')');
    XCTAssertEqual(c, NSNotFound);
    c = matchingBracketPosition(text, NSMakeRange(0, text.length - 14), false, ')');
    XCTAssertEqual(c, 6);
    c = matchingBracketPosition(text, NSMakeRange(0, text.length), false, '(');
    XCTAssertEqual(c, 30);
}

-(void)testSymbolsFromSetPosition {
    NSString * text = @"abcdefgh ijklmn opqr rqpo nmlkji hgfedcba";
    NSUInteger c = symbolsFromSetPosition(text, NSMakeRange(0, text.length), true, [NSCharacterSet characterSetWithCharactersInString:@"jkilm"]);
    XCTAssertEqual(c, 9);
    c = symbolsFromSetPosition(text, NSMakeRange(0, text.length), false, [NSCharacterSet characterSetWithCharactersInString:@"jkilm"]);
    XCTAssertEqual(c, 31);
}

-(void)testMatchingQuotesPosition {
    NSString * text = @"asdfasfasf \" asdfasdfasf \\\" sfefadfa \\\" aasdflaksja;\" lkj;kj;lkj";
    NSUInteger c = matchingQuotePosition(text, 11, true);
    XCTAssertEqual(c, 52);
    c = matchingQuotePosition(text, 52, true);
    XCTAssertEqual(c, 11);
}

-(void)testExtendRangeToMatchingQuote {
    NSString * text = @"asdfasfasf \" asdfasdfasf \\\" sfefadfa \\\" aasdflaksja;\" lkj;kj;lkj";
    NSRange r = extendRangeToMatchingQuote(text, NSMakeRange(12, 5), 11, true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 11);
    XCTAssertEqual(r.length, 42);
    r = extendRangeToMatchingQuote(text, NSMakeRange(46, 5), 52, true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 11);
    XCTAssertEqual(r.length, 42);
    r = extendRangeToMatchingQuote(text, NSMakeRange(10, 41), 52, true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 10);
    XCTAssertEqual(r.length, 43);
}

-(void)testShrinkRangeToMatchingQuote {
    NSString * text = @"asdfasfasf \" asdfasdfasf \\\" sfefadfa \\\" aasdflaksja;\" lkj;kj;lkj";
    NSRange r = shrinkRangeToMatchingQuote(text, NSMakeRange(11, 44), 11, true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 11);
    XCTAssertEqual(r.length, 42);
    r = shrinkRangeToMatchingQuote(text, NSMakeRange(2, 50), 52, true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 11);
    XCTAssertEqual(r.length, 42);
    r = shrinkRangeToMatchingQuote(text, NSMakeRange(2, 49), 52, true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 11);
    XCTAssertEqual(r.length, 42);
}

-(void)testExtendRangeToMatchingBracket {
    NSString * text = @"if (selector == @selector(deleteToBeginningOfLine:)) {";
    NSRange r = extendRangeToMatchingBracket(text, NSMakeRange(4, 5), NSMakeRange(0, text.length), 3, '(', true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 4);
    XCTAssertEqual(r.length, 47);
    r = extendRangeToMatchingBracket(text, NSMakeRange(4, 49), NSMakeRange(0, text.length), 3, ')', true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 3);
    XCTAssertEqual(r.length, 50);
}

-(void)testShrinkRangeToMatchingBracket {
    NSString * text = @"if (selector == @selector(deleteToBeginningOfLine:)) {aaa";
    NSRange r = shrinkRangeToMatchingBracket(text, NSMakeRange(5, 47), 52, ')', false);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 5);
    XCTAssertEqual(r.length, 46);
    r = shrinkRangeToMatchingBracket(text, NSMakeRange(3, 6), 3, '(', true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 4);
    XCTAssertEqual(r.length, 5);
    r = shrinkRangeToMatchingBracket(text, NSMakeRange(3, 52), 3, '(', true);
    NSLog(@"%@", [text substringWithRange:r]);
    XCTAssertEqual(r.location, 3);
    XCTAssertEqual(r.length, 49);
}

-(void)testExtendRangeToSymbolFromSet {
    NSCharacterSet * nonAlpha = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString * text = @"if (selector == @selector(deleteToBeginningOfLine:)) {aaa";
    NSRange lineRange = NSMakeRange(0, text.length);
    
    NSRange range = extendRangeToSymbolFromSet(text, NSMakeRange(45, 1), lineRange, nonAlpha, false);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 26);
    XCTAssertEqual(range.length, 20);
    
    range = extendRangeToSymbolFromSet(text, NSMakeRange(40, 1), lineRange, nonAlpha, true);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 40);
    XCTAssertEqual(range.length, 9);
}

-(void)testShrinkRangeToSymbolFromSet {
    NSCharacterSet * nonAlpha = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString * text = @"if (selector == @selector(deleteToBeginningOfLine:)) {aaa";
    
    NSRange range = shrinkRangeToSymbolFromSet(text, NSMakeRange(20, 25), nonAlpha, false);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 20);
    XCTAssertEqual(range.length, 6);
    
    range = shrinkRangeToSymbolFromSet(text, NSMakeRange(20, 25), nonAlpha, true);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 25);
    XCTAssertEqual(range.length, 20);
}

-(void)testExtendRange {
    NSString * text = @"if (selector == @selector(deleteToBeginningOfLine:)) {aaa";
    NSRange range = NSMakeRange(45, 1);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 26);
    XCTAssertEqual(range.length, 23);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 26);
    XCTAssertEqual(range.length, 24);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 25);
    XCTAssertEqual(range.length, 26);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 3);
    XCTAssertEqual(range.length, 49);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 2);
    XCTAssertEqual(range.length, 51);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 2);
    XCTAssertEqual(range.length, 51);
}

-(void)testShrinkRange {
    NSString * text = @"if (selector == @selector(deleteToBeginningOfLine:)) {aaa";
    NSRange range = NSMakeRange(0, text.length);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 2);
    XCTAssertEqual(range.length, 51);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 3);
    XCTAssertEqual(range.length, 49);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 4);
    XCTAssertEqual(range.length, 47);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 25);
    XCTAssertEqual(range.length, 26);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 26);
    XCTAssertEqual(range.length, 24);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 26);
    XCTAssertEqual(range.length, 24);
}

-(void)testSmartExtend {
    NSString * text = @"    return NSMakeRange(backwardTo, calculatedEnd);";
    NSRange range = NSMakeRange(7, 1);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 4);
    XCTAssertEqual(range.length, 6);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 4);
    XCTAssertEqual(range.length, 18);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 4);
    XCTAssertEqual(range.length, 45);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 4);
    XCTAssertEqual(range.length, 46);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 4);
    XCTAssertEqual(range.length, 46);
}

-(void)testSelection {
    NSString * text = @"if (selector == @selector(deleteToBeginningOfLine:)) {\n\
    // handle deleteToBeginningOfLine: method\n\
    NSRange deleteRange;\n\
    if (caretLocation == codeStartRange.location) {\n\
    // we are already at the beginnig of code, delete all the way to start of line\n\
    deleteRange = NSMakeRange(lineRange.location, codeStartRange.location);\n\
    }\n\
    else {\n\
    // delete from caret to code start\n\
    deleteRange = NSMakeRange(lineRange.location+codeStartRange.location, caretLocation-codeStartRange.location);\n\
    }\n\
    \n\
    [self setSelectedRange:deleteRange];\n\
    // We cannot undo if we use -replaceCharactersInRange:withString:,\n\
    // we need to use -insertText: to delete the text instead.\n\
    [self insertText:@""];\n\
    }";
    NSTextView * textView = [[NSTextView alloc] init];
    textView.string = text;
    textView.selectedRange = NSMakeRange(308, 1);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 301);
    XCTAssertEqual(textView.selectedRange.length, 8);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 291);
    XCTAssertEqual(textView.selectedRange.length, 18);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 291);
    XCTAssertEqual(textView.selectedRange.length, 43);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 290);
    XCTAssertEqual(textView.selectedRange.length, 45);
}

-(void)testBracketMatching {
    NSString * text = @"NSRange forwardTo = [text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] options:0 range:NSMakeRange(end + 1, text.length - end - 1)];";
    NSTextView * textView = [[NSTextView alloc] init];
    textView.string = text;
    textView.selectedRange = NSMakeRange(95, 1);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 93);
    XCTAssertEqual(textView.selectedRange.length, 11);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 50);
    XCTAssertEqual(textView.selectedRange.length, 55);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 49);
    XCTAssertEqual(textView.selectedRange.length, 64);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 26);
    XCTAssertEqual(textView.selectedRange.length, 87);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 21);
    XCTAssertEqual(textView.selectedRange.length, 92);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 21);
    XCTAssertEqual(textView.selectedRange.length, 144);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 20);
    XCTAssertEqual(textView.selectedRange.length, 146);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 18);
    XCTAssertEqual(textView.selectedRange.length, 149);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 17);
    XCTAssertEqual(textView.selectedRange.length, 150);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 8);
    XCTAssertEqual(textView.selectedRange.length, 159);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 7);
    XCTAssertEqual(textView.selectedRange.length, 160);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 0);
    XCTAssertEqual(textView.selectedRange.length, 167);
}

-(void)testLineBorders {
    NSString * text = @"NSRange leftExtendRange(NSString * text, NSRange range, NSCharacterSet * chr) {\n\
    NSRange backwardTo = [text rangeOfCharacterFromSet:chr options:NSBackwardsSearch range:NSMakeRange(0, range.location - 1)];\n\
    if (backwardTo.location == NSNotFound) return range;\n\
    return NSMakeRange(backwardTo.location + 1, range.location + range.length - backwardTo.location - 1);\n\
    }\n\
    ";
    NSTextView * textView = [[NSTextView alloc] init];
    textView.string = text;
    textView.selectedRange = NSMakeRange(200, 1);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 9);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 186);
    XCTAssertEqual(textView.selectedRange.length, 15);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 184);
    XCTAssertEqual(textView.selectedRange.length, 18);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 183);
    XCTAssertEqual(textView.selectedRange.length, 19);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 183);
    XCTAssertEqual(textView.selectedRange.length, 21);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 182);
    XCTAssertEqual(textView.selectedRange.length, 23);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 105);
    XCTAssertEqual(textView.selectedRange.length, 101);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 103);
    XCTAssertEqual(textView.selectedRange.length, 104);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 92);
    XCTAssertEqual(textView.selectedRange.length, 115);
}

-(void)testLineShrink {
    NSString * text = @"if ((range.location + calculatedEnd) > (lineRange.location + lineRange.length)) {";
    NSTextView * textView = [[NSTextView alloc] init];
    textView.string = text;
    textView.selectedRange = NSMakeRange(0, 55);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 2);
    XCTAssertEqual(textView.selectedRange.length, 47);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 3);
    XCTAssertEqual(textView.selectedRange.length, 46);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 3);
    XCTAssertEqual(textView.selectedRange.length, 36);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 3);
    XCTAssertEqual(textView.selectedRange.length, 35);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 3);
    XCTAssertEqual(textView.selectedRange.length, 34);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 3);
    XCTAssertEqual(textView.selectedRange.length, 33);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 4);
    XCTAssertEqual(textView.selectedRange.length, 32);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 5);
    XCTAssertEqual(textView.selectedRange.length, 30);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 10);
    XCTAssertEqual(textView.selectedRange.length, 11);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 10);
    XCTAssertEqual(textView.selectedRange.length, 10);
}

-(void)testShortShrink {
    NSString * text = @"    NSUInteger end = range.location + range.length;";
    NSTextView * textView = [[NSTextView alloc] init];
    textView.string = text;
    textView.selectedRange = NSMakeRange(0, 55);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 4);
    XCTAssertEqual(textView.selectedRange.length, 47);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 14);
    XCTAssertEqual(textView.selectedRange.length, 36);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 15);
    XCTAssertEqual(textView.selectedRange.length, 35);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 18);
    XCTAssertEqual(textView.selectedRange.length, 25);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 19);
    XCTAssertEqual(textView.selectedRange.length, 24);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 19);
    XCTAssertEqual(textView.selectedRange.length, 18);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 19);
    XCTAssertEqual(textView.selectedRange.length, 17);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 19);
    XCTAssertEqual(textView.selectedRange.length, 16);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 19);
    XCTAssertEqual(textView.selectedRange.length, 7);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 19);
    XCTAssertEqual(textView.selectedRange.length, 1);
}

-(void)testBugReportTwo {
    NSString * text = @"NSCharacterSet * searchset = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@\"%c%c\", bracket, pair]];";
    NSRange range = NSMakeRange(0, text.length);
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 14);
    XCTAssertEqual(range.length, 117);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 29);
    XCTAssertEqual(range.length, 102);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 30);
    XCTAssertEqual(range.length, 100);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 80);
    XCTAssertEqual(range.length, 50);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 81);
    XCTAssertEqual(range.length, 48);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 89);
    XCTAssertEqual(range.length, 35);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 90);
    XCTAssertEqual(range.length, 34);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 106);
    XCTAssertEqual(range.length, 17);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 106);
    XCTAssertEqual(range.length, 9);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 106);
    XCTAssertEqual(range.length, 8);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 108);
    XCTAssertEqual(range.length, 6);
    
    range = shrinkRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 108);
    XCTAssertEqual(range.length, 5);
}

-(void)testBugReportThree {
    NSString * text = @"case '(':\n\
    pair = ')';\n\
    break;";
    NSRange range = NSMakeRange(16, 1);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 14);
    XCTAssertEqual(range.length, 4);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 14);
    XCTAssertEqual(range.length, 6);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 14);
    XCTAssertEqual(range.length, 8);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 14);
    XCTAssertEqual(range.length, 9);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 14);
    XCTAssertEqual(range.length, 10);
    
    range = extendRange(text, range);
    NSLog(@"%@", [text substringWithRange:range]);
    XCTAssertEqual(range.location, 14);
    XCTAssertEqual(range.length, 11);
}

/*- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}*/

@end
