/*============================================================================
 PROJECT: TextViewer
 FILE:    TextFileView.m
 AUTHOR:  Tam Nguyen
 DATE:    4/17/15
 =============================================================================*/

/*============================================================================
 IMPORT
 =============================================================================*/
#import "TextFileView.h"
#import "TextBlock.h"
#import "TextSearchResult.h"
/*============================================================================
 PRIVATE MACRO
 =============================================================================*/

#define kMaxTextBlockCount 3

/*============================================================================
 PRIVATE INTERFACE
 =============================================================================*/

@interface TextFileView() <UITextViewDelegate>

@property (strong, nonatomic) TextDocument *document;
@property (strong, nonatomic) NSMutableArray *textBlocks;

@end


@implementation TextFileView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.delegate = self;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.layoutManager.allowsNonContiguousLayout = NO;
    self.delegate = self;
    
    // Should keep temporary text block to re-render without get from file when scroll up or down
    _textBlocks = [NSMutableArray array];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    [self setNeedsLayout];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString:attributedText];
    [text addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, attributedText.length)];
    
    [super setAttributedText:text];
}

#pragma mark - Private methods

- (NSAttributedString *)getAllTextWithAppend:(NSAttributedString *)appendText {
    if (self.textBlocks.count == 0) {
        return appendText;
    }
    
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithAttributedString:[(TextBlock *)self.textBlocks[0] text]];
    
    for (int i = 1; i < self.textBlocks.count; i++) {
        TextBlock *block = (TextBlock *)[self.textBlocks objectAtIndex:i];
        [result appendAttributedString:block.text];
    }
    
    if (appendText) {
        [result appendAttributedString:appendText];
    }
    
    return result;
}

- (NSAttributedString *)getAllTextWithPreappend:(NSAttributedString *)preappenText {
    if (self.textBlocks.count == 0) {
        return preappenText;
    }
    
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] initWithAttributedString:[(TextBlock *)self.textBlocks[0] text]];
    
    for (int i = 1; i < self.textBlocks.count; i++) {
        TextBlock *block = (TextBlock *)[self.textBlocks objectAtIndex:i];
        [resultString appendAttributedString:block.text];
    }
    
    if (preappenText) {
        [resultString insertAttributedString:preappenText atIndex:0];
    }
    
    return resultString;
}

- (void)removeAllDisplayText {
    self.attributedText = nil;
    [self setNeedsLayout];
    
    // Remove all object text block
    [self.textBlocks removeAllObjects];
}

#pragma mark - Methods

- (void)beginRenderDocument:(TextDocument *)document {
    _document = document;
    
    // Begin render
    NSAttributedString *firstBlockText = [self.document readTextAtBlockIndex:0 hightlightSearch:YES];
    self.attributedText = firstBlockText;
    [self layoutIfNeeded];
    
    TextBlock *firstBlock = [[TextBlock alloc] init];
    firstBlock.text = firstBlockText;
    firstBlock.displayRect = CGRectMake(0, self.contentInset.top, self.bounds.size.width, self.contentSize.height);
    firstBlock.blockIndex = 0;
    [self.textBlocks addObject:firstBlock];
}

- (void)refreshContent {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    
    for (TextBlock *block in self.textBlocks) {
        NSAttributedString *blockText = [self.document readTextAtBlockIndex:block.blockIndex hightlightSearch:YES];
        
        block.text = blockText;
        [text appendAttributedString:blockText];
    }
    
    // Update new text
    self.attributedText = text;
    [self setNeedsLayout];
}

- (void)refreshContentAtBlockIndex:(int)blockIndex {
    BOOL isDisplayingBlockIndex = NO;
    
    for (TextBlock *block in self.textBlocks) {
        if (block.blockIndex == blockIndex) {
            isDisplayingBlockIndex = YES;
            break;
        }
    }
    
    if (isDisplayingBlockIndex) {
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
        
        for (TextBlock *block in self.textBlocks) {
            NSAttributedString *blockText = [self.document readTextAtBlockIndex:block.blockIndex hightlightSearch:YES];
            
            block.text = blockText;
            [text appendAttributedString:blockText];
        }
        
        // Update new text
        self.attributedText = text;
        [self setNeedsLayout];
    }
}

- (void)gotoSearchResult:(TextSearchResult *)searchResult animated:(BOOL)animated {
    if (searchResult) {
        int blockIndex = searchResult.dataRange.location / self.document.blockSize;
        
        // Should remove all currently text
        BOOL isDisplayingBlock = NO;
        
        for (TextBlock *block in self.textBlocks) {
            if (block.blockIndex == blockIndex) {
                isDisplayingBlock = YES;
                break;
            }
        }
        
        // Should display this block and scroll to focus text
        if (!isDisplayingBlock) {
            // Should remove all block is displaying
            [self removeAllDisplayText];
            
            NSAttributedString *blockText = [self.document readTextAtBlockIndex:blockIndex hightlightSearch:YES];
            
            if (self.textBlocks.count >= kMaxTextBlockCount) {
                // Remove first block
                while (self.textBlocks.count == kMaxTextBlockCount - 1) {
                    [self.textBlocks removeObjectAtIndex:0];
                }
            }
            
            TextBlock *firstBlock = [[TextBlock alloc] init];
            firstBlock.text = blockText;
            firstBlock.displayRect = CGRectMake(0, self.contentInset.top, self.bounds.size.width, self.contentSize.height);
            firstBlock.blockIndex = blockIndex;
            [self.textBlocks addObject:firstBlock];
            
            NSLog(@"Add goto search %d", blockIndex);
            
            self.attributedText = blockText;
            [self layoutIfNeeded];
        }
        
        // Should find range of this text, then scroll to that
        CGRect textVisibleRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        NSUInteger firstBlockIndex = ((TextBlock *)[self.textBlocks firstObject]).blockIndex;
        NSRange dataFromBeginToKeywordRange = NSMakeRange(firstBlockIndex * self.document.blockSize, (searchResult.dataRange.location + searchResult.dataRange.length) - firstBlockIndex * self.document.blockSize);
        
        // Get text from this data range, then calculate how height of that text
        NSAttributedString *prefixText = [self.document readTextInRange:dataFromBeginToKeywordRange];
        CGSize textSize = [self textSizeWithText:prefixText.string];
        
        // Update origin y of frame need to scroll to
        textVisibleRect.origin.y = textSize.height;
        
        // Scroll to range
        [self scrollRectToVisible:textVisibleRect animated:animated];
    }
}

#pragma mark - UITextVie's delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint contentOffset = self.contentOffset;
    
    TextBlock *firstBlock = [self.textBlocks firstObject];
    TextBlock *lastBlock = [self.textBlocks lastObject];
    
    if (contentOffset.y + self.bounds.size.height >= self.contentSize.height - 100) {
        // Should read next blocks
        NSAttributedString *nextBlockText = [self.document readTextAtBlockIndex:lastBlock.blockIndex + 1 hightlightSearch:YES];
        
        if (nextBlockText) {
            float currentHeight = self.contentSize.height;
            
            if (self.textBlocks.count >= kMaxTextBlockCount) {
                // Remove first block
                while (self.textBlocks.count == kMaxTextBlockCount - 1) {
                    [self.textBlocks removeObjectAtIndex:0];
                }
                
                currentHeight -= firstBlock.displayRect.size.height;
                contentOffset.y -= firstBlock.displayRect.size.height;
            }
            
            // Set new text
            NSAttributedString *newText = [self getAllTextWithAppend:nextBlockText];
            
            TextBlock *textBlock = [[TextBlock alloc] init];
            textBlock.text = nextBlockText;
            textBlock.displayRect = CGRectMake(0, currentHeight, self.bounds.size.width, self.contentSize.height - currentHeight);
            textBlock.blockIndex = lastBlock.blockIndex + 1;
            [self.textBlocks addObject:textBlock];
            
            self.attributedText = newText;
            self.contentOffset = contentOffset;
            [self layoutIfNeeded]; // Refesh to update content size, content offset
            
            NSLog(@"Add scroll down %d", textBlock.blockIndex);
        }
    } else if (firstBlock.blockIndex > 0 && contentOffset.y <= 100) {
        // Should read previous block
        NSAttributedString *previousBlockText = [self.document readTextAtBlockIndex:firstBlock.blockIndex - 1 hightlightSearch:YES];
        
        if (previousBlockText) {
            float currentHeight = self.contentSize.height;
            
            if (self.textBlocks.count >= kMaxTextBlockCount) {
                // Remove last block
                while (self.textBlocks.count == kMaxTextBlockCount - 1) {
                    [self.textBlocks removeLastObject];
                }
                
                currentHeight -= lastBlock.displayRect.size.height;
                
                if (contentOffset.y > currentHeight - lastBlock.displayRect.size.height) {
                    contentOffset.y = currentHeight - lastBlock.displayRect.size.height;
                }
            }
            
            // Set new text
            NSAttributedString *newText = [self getAllTextWithPreappend:previousBlockText];
            self.attributedText = newText;
            
            TextBlock *textBlock = [[TextBlock alloc] init];
            textBlock.text = previousBlockText;
            textBlock.displayRect = CGRectMake(0, 0, self.bounds.size.width, self.contentSize.height - currentHeight);
            textBlock.blockIndex = firstBlock.blockIndex - 1;
            [self.textBlocks insertObject:textBlock atIndex:0]; // Insert to first object
            NSLog(@"Add scroll up %d", textBlock.blockIndex);
            
            // Recalculate content offset
            contentOffset.y += textBlock.displayRect.size.height;
            self.contentOffset = contentOffset;
            [self layoutIfNeeded]; // Refesh to update content size, content offset
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

#pragma mark - Utils methods

- (CGSize)textSizeWithText:(NSString *)text {
    CGSize limitSize = CGSizeMake(self.bounds.size.width, CGFLOAT_MAX);
    NSDictionary *attributes = @{NSFontAttributeName: self.font};
    
    return [text boundingRectWithSize:limitSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil].size;
}


@end
