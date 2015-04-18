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

#pragma mark - Private methods

- (NSString *)getAllTextWithAppend:(NSString *)appendText {
    if (self.textBlocks.count == 0) {
        return appendText;
    }
    
    NSString *result = [self.textBlocks[0] text];
    
    for (int i = 1; i < self.textBlocks.count; i++) {
        TextBlock *block = (TextBlock *)[self.textBlocks objectAtIndex:i];
        result = [result stringByAppendingString:block.text];
    }
    
    if (appendText) {
        result = [result stringByAppendingString:appendText];
    }
    
    return result;
}

- (NSString *)getAllTextWithPreappend:(NSString *)preappenText {
    if (self.textBlocks.count == 0) {
        return preappenText;
    }
    
    NSString *result = [self.textBlocks[0] text];
    
    for (int i = 1; i < self.textBlocks.count; i++) {
        TextBlock *block = (TextBlock *)[self.textBlocks objectAtIndex:i];
        result = [result stringByAppendingString:block.text];
    }
    
    if (preappenText) {
        result = [preappenText stringByAppendingString:result];
    }
    
    return result;
}

#pragma mark - Methods

- (void)beginRenderDocument:(TextDocument *)document {
    _document = document;
    
    // Begin render
    NSString *firstBlockText = [self.document readTextAtBlockIndex:0];
    self.text = firstBlockText;
    [self layoutIfNeeded];
    
    TextBlock *firstBlock = [[TextBlock alloc] init];
    firstBlock.text = firstBlockText;
    firstBlock.displayRect = CGRectMake(0, self.contentInset.top, self.bounds.size.width, self.contentSize.height);
    firstBlock.blockIndex = 0;
    [self.textBlocks addObject:firstBlock];
}

#pragma mark - UITextVie's delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint contentOffset = self.contentOffset;
    
    TextBlock *firstBlock = [self.textBlocks firstObject];
    TextBlock *lastBlock = [self.textBlocks lastObject];
    
    if (contentOffset.y + self.bounds.size.height >= self.contentSize.height - 100) {
        // Should read next blocks
        NSString *nextBlockText = [self.document readTextAtBlockIndex:lastBlock.blockIndex + 1];
        
        if (nextBlockText) {
            float currentHeight = self.contentSize.height;
            
            if (self.textBlocks.count >= kMaxTextBlockCount) {
                // Remove first block
                [self.textBlocks removeObjectAtIndex:0];
                
                currentHeight -= firstBlock.displayRect.size.height;
                contentOffset.y -= firstBlock.displayRect.size.height;
            }
            
            // Set new text
            NSString *newText = [self getAllTextWithAppend:nextBlockText];
            self.text = newText;
            self.contentOffset = contentOffset;
            [self layoutIfNeeded]; // Refesh to update content size, content offset
            
            TextBlock *textBlock = [[TextBlock alloc] init];
            textBlock.text = nextBlockText;
            textBlock.displayRect = CGRectMake(0, currentHeight, self.bounds.size.width, self.contentSize.height - currentHeight);
            textBlock.blockIndex = lastBlock.blockIndex + 1;
            [self.textBlocks addObject:textBlock];
        }
    } else if (firstBlock.blockIndex > 0 && contentOffset.y <= 100) {
        // Should read previous block
        NSString *previousBlockText = [self.document readTextAtBlockIndex:firstBlock.blockIndex - 1];
        
        if (previousBlockText) {
            float currentHeight = self.contentSize.height;
            
            if (self.textBlocks.count >= kMaxTextBlockCount) {
                // Remove last block
                [self.textBlocks removeLastObject];
                
                currentHeight -= lastBlock.displayRect.size.height;
                
                if (contentOffset.y > currentHeight - lastBlock.displayRect.size.height) {
                    contentOffset.y = currentHeight - lastBlock.displayRect.size.height;
                }
            }
            
            // Set new text
            NSString *newText = [self getAllTextWithPreappend:previousBlockText];
            self.text = newText;
            
            TextBlock *textBlock = [[TextBlock alloc] init];
            textBlock.text = previousBlockText;
            textBlock.displayRect = CGRectMake(0, 0, self.bounds.size.width, self.contentSize.height - currentHeight);
            textBlock.blockIndex = firstBlock.blockIndex - 1;
            [self.textBlocks insertObject:textBlock atIndex:0]; // Insert to first object
            
            
            // Recalculate content offset
            contentOffset.y += textBlock.displayRect.size.height;
            self.contentOffset = contentOffset;
            [self layoutIfNeeded]; // Refesh to update content size, content offset
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

@end
