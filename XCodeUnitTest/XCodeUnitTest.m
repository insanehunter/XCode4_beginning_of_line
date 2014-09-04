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

extern NSRange findMatchingBracket(NSString * text, NSRange range, bool forward, bool square, bool opening);
extern void wrapper(NSTextView * textView, SEL _cmd, SEL selector);

@implementation XCodeUnitTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    NSRange r = findMatchingBracket(@"aaa(bbb(ccc)ddd)eee", NSMakeRange(4, 1), true, false, true);
    XCTAssertEqual(r.location, 4);
    XCTAssertEqual(r.length, 3);
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
    XCTAssertEqual(textView.selectedRange.location, 301);
    XCTAssertEqual(textView.selectedRange.length, 9);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    XCTAssertEqual(textView.selectedRange.location, 291);
    XCTAssertEqual(textView.selectedRange.length, 19);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    XCTAssertEqual(textView.selectedRange.location, 291);
    XCTAssertEqual(textView.selectedRange.length, 43);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    XCTAssertEqual(textView.selectedRange.location, 279);
    XCTAssertEqual(textView.selectedRange.length, 56);
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
    XCTAssertEqual(textView.selectedRange.location, 51);
    XCTAssertEqual(textView.selectedRange.length, 53);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 50);
    XCTAssertEqual(textView.selectedRange.length, 55);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 26);
    XCTAssertEqual(textView.selectedRange.length, 87);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 21);
    XCTAssertEqual(textView.selectedRange.length, 94);
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
    XCTAssertEqual(textView.selectedRange.location, 8);
    XCTAssertEqual(textView.selectedRange.length, 159);
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
    XCTAssertEqual(textView.selectedRange.length, 10);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 186);
    XCTAssertEqual(textView.selectedRange.length, 16);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 183);
    XCTAssertEqual(textView.selectedRange.length, 21);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 171);
    XCTAssertEqual(textView.selectedRange.length, 34);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 106);
    XCTAssertEqual(textView.selectedRange.length, 99);
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
    XCTAssertEqual(textView.selectedRange.length, 116);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 84);
    XCTAssertEqual(textView.selectedRange.length, 124);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 80);
    XCTAssertEqual(textView.selectedRange.length, 128);
    wrapper(textView, nil, @selector(moveParagraphBackwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 80);
    XCTAssertEqual(textView.selectedRange.length, 128);
}

-(void)testLineShrink {
    NSString * text = @"if ((range.location + calculatedEnd) > (lineRange.location + lineRange.length)) {";
    NSTextView * textView = [[NSTextView alloc] init];
    textView.string = text;
    textView.selectedRange = NSMakeRange(0, 55);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 3);
    XCTAssertEqual(textView.selectedRange.length, 46);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 10);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 10);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 10);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 10);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 10);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 10);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 10);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 10);
    wrapper(textView, nil, @selector(moveParagraphForwardAndModifySelection:));
    NSLog(@"%@", [text substringWithRange:textView.selectedRange]);
    XCTAssertEqual(textView.selectedRange.location, 192);
    XCTAssertEqual(textView.selectedRange.length, 10);
}

/*- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}*/

@end
