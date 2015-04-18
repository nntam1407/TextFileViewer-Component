/*============================================================================
 PROJECT: TextViewer
 FILE:    TextSearchResult.m
 AUTHOR:  Tam Nguyen
 DATE:    4/18/15
 =============================================================================*/

/*============================================================================
 IMPORT
 =============================================================================*/
#import "TextSearchResult.h"

/*============================================================================
 PRIVATE MACRO
 =============================================================================*/
/*============================================================================
 PRIVATE INTERFACE
 =============================================================================*/

@interface TextSearchResult()

@end

@implementation TextSearchResult

- (instancetype)initWithBlockDataRange:(NSRange)blockDataRange rangeOfKeywordInBlockText:(NSRange)rangeInBlockText {
    self = [super init];
    
    if (self) {
        _blockDataRange = blockDataRange;
        _rangeInBlockText = rangeInBlockText;
    }
    
    return self;
}

@end
