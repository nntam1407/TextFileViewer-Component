/*============================================================================
 PROJECT: TextViewer
 FILE:    TextDocument.m
 AUTHOR:  Tam Nguyen
 DATE:    4/16/15
 =============================================================================*/

/*============================================================================
 IMPORT
 =============================================================================*/
#import "TextDocument.h"

/*============================================================================
 PRIVATE MACRO
 =============================================================================*/

#define kBufferSize         8192

/*============================================================================
 PRIVATE INTERFACE
 =============================================================================*/

@interface TextDocument()

@end

@implementation TextDocument

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    
    if (self) {
        _filePath = filePath;
        _pageNumber = 0;
        
        // Calculator page count
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSDate *startTime = [NSDate date];
            
            int pageCount = [self calculatePageCountWithBoundSize:CGSizeMake(320, 568)];
            
            NSDate *endTime = [NSDate date];
            
            NSLog(@"Result page count = %d, time = %f seconds", pageCount, [endTime timeIntervalSinceDate:startTime]);
        });
    }
    
    return self;
}

#pragma mark - Override methods

- (BOOL)fileNotFound {
    if (!self.filePath || self.filePath.length == 0) {
        return YES;
    } else {
        return ![[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
    }
}

#pragma mark - Private methods

/*----------------------------------------------------------------------------
 Method:      This method will be process and init basic information to draw this file
 -----------------------------------------------------------------------------*/
- (int)calculatePageCountWithBoundSize:(CGSize)boundSize {
    CGFloat totalHeight = 0;
    
    CGSize limmitSize = CGSizeMake(boundSize.width, MAXFLOAT);
    UIFont *font = [UIFont systemFontOfSize:13];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:self.filePath];
    [inputStream open];
    
    // Read data and calculator page count
    NSUInteger readPointer = 0;
    NSUInteger readByteCount = 0;
    
    do {
        @autoreleasepool {
            NSMutableData *data = [NSMutableData dataWithLength:kBufferSize];
            
            readByteCount = [inputStream read:data.mutableBytes maxLength:kBufferSize];
            
            // Convert to NSString data
            NSString *text = [[NSString alloc] initWithBytes:data.bytes length:readByteCount encoding:NSUTF8StringEncoding];
            
            if (text) {
                CGSize size = [text boundingRectWithSize:limmitSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
                totalHeight += size.height;
            }
            
            // Update read point
            readPointer += readByteCount;
        }
    } while (readByteCount > 0);
    
    [inputStream close];
    
    return (int)(totalHeight / boundSize.height);
}

@end
