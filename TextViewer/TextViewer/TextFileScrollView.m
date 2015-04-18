/*============================================================================
 PROJECT: TextViewer
 FILE:    TextFileScrollView.m
 AUTHOR:  Tam Nguyen
 DATE:    4/17/15
 =============================================================================*/

/*============================================================================
 IMPORT
 =============================================================================*/
#import "TextFileScrollView.h"
#import "TextBlock.h"
#import "FTCoreTextView.h"
/*============================================================================
 PRIVATE MACRO
 =============================================================================*/

#define kMaxTextBlockCount 3

/*============================================================================
 PRIVATE INTERFACE
 =============================================================================*/

@interface TextFileScrollView() <UIScrollViewDelegate>

@property (strong, nonatomic) FTCoreTextView *contentTextView;

@property (strong, nonatomic) TextDocument *document;
@property (strong, nonatomic) NSMutableArray *textBlocks;

@end

@implementation TextFileScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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
    
    // Create UI
    [self createBaseUI];
    
    self.delegate = self;
    _textBlocks = [NSMutableArray array];
    
    FTCoreTextStyle *defaultStyle = [FTCoreTextStyle new];
    defaultStyle.name = FTCoreTextTagDefault;	//thought the default name is already set to FTCoreTextTagDefault
    defaultStyle.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:14.f];
    defaultStyle.textAlignment = FTCoreTextAlignementLeft;
    [self.contentTextView addStyle:defaultStyle];

}

- (void)layoutContentSize {
    [self.contentTextView fitToSuggestedHeight];
//    self.contentTextView.frame = CGRectMake(0, 0, 320, 4000);
    
    // Update content size
    CGSize contentSize = self.contentSize;
    contentSize.width = self.bounds.size.width;
    contentSize.height = self.contentTextView.frame.size.height;
    self.contentSize = contentSize;
}

#pragma mark - Private methods

- (void)createBaseUI {
    if (!self.contentTextView) {
        _contentTextView = [[FTCoreTextView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        [self addSubview:self.contentTextView];
    }
}

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
    self.contentTextView.text = firstBlockText;
    [self layoutContentSize];
    
    TextBlock *firstBlock = [[TextBlock alloc] init];
    firstBlock.text = firstBlockText;
    firstBlock.displayRect = CGRectMake(0, self.contentInset.top, self.bounds.size.width, self.contentTextView.bounds.size.height);
    firstBlock.blockIndex = 0;
    [self.textBlocks addObject:firstBlock];
}

#pragma mark - UIScrollView's delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint contentOffset = self.contentOffset;
    
    TextBlock *firstBlock = [self.textBlocks firstObject];
    TextBlock *lastBlock = [self.textBlocks lastObject];
    
    if (contentOffset.y + self.bounds.size.height >= self.contentSize.height - 100) {
        // Should read next blocks
        NSString *nextBlockText = [self.document readTextAtBlockIndex:lastBlock.blockIndex + 1];
        
        if (nextBlockText) {
            float currentHeight = self.contentTextView.bounds.size.height;
            
            if (self.textBlocks.count >= kMaxTextBlockCount) {
                // Remove first block
                [self.textBlocks removeObjectAtIndex:0];
                
                currentHeight -= firstBlock.displayRect.size.height;
                contentOffset.y -= firstBlock.displayRect.size.height;
            }
            
            // Set new text
            NSString *newText = [self getAllTextWithAppend:nextBlockText];
            self.contentTextView.text = newText;
            [self layoutContentSize];
            
            // Update new scroll offset
            self.contentOffset = contentOffset;
            
            TextBlock *textBlock = [[TextBlock alloc] init];
            textBlock.text = nextBlockText;
            textBlock.displayRect = CGRectMake(0, currentHeight, self.bounds.size.width, self.contentTextView.bounds.size.height - currentHeight);
            textBlock.blockIndex = lastBlock.blockIndex + 1;
            [self.textBlocks addObject:textBlock];
            
        }
        
        NSLog(@"Draw next");
    } else if (firstBlock.blockIndex > 0 && contentOffset.y - 1 <= 100) {
        // Should read previous block
        NSString *previousBlockText = [self.document readTextAtBlockIndex:firstBlock.blockIndex - 1];
        
        if (previousBlockText) {
            float currentHeight = self.contentTextView.bounds.size.height;
            
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
            self.contentTextView.text = newText;
            [self layoutContentSize];
            
            TextBlock *textBlock = [[TextBlock alloc] init];
            textBlock.text = previousBlockText;
            textBlock.displayRect = CGRectMake(0, 0, self.bounds.size.width, self.contentTextView.bounds.size.height - currentHeight);
            textBlock.blockIndex = firstBlock.blockIndex - 1;
            [self.textBlocks insertObject:textBlock atIndex:0]; // Insert to first object
            
            
            // Recalculate content offset
            contentOffset.y += textBlock.displayRect.size.height;
            self.contentOffset = contentOffset;
        }
        
        NSLog(@"Draw previous");
    }
}

@end
