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

#define kBufferSize         49152//8192

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
    
    NSData *fileData = [NSData dataWithContentsOfFile:self.filePath options:NSDataReadingMappedIfSafe error:nil];
    int dataLength = [fileData length];
    
    // Read data and calculator page count
    NSUInteger readPointer = 0;

    while (readPointer < dataLength) {
        @autoreleasepool {
            int remainByteCount = dataLength - readPointer;
            int byteToRead = kBufferSize < remainByteCount ? kBufferSize : remainByteCount;
            uint8_t* data = malloc(byteToRead);
            
            [fileData getBytes:data range:NSMakeRange(readPointer, byteToRead)];
            
            // Convert to NSString data
            NSString *text = [[NSString alloc] initWithBytes:data length:byteToRead encoding:NSUTF8StringEncoding];
            
            if (text) {
                CGSize size = [text boundingRectWithSize:limmitSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
                totalHeight += size.height;
            }
            
            free(data);
            
            // Update read point
            readPointer += byteToRead;
        }
    }
    
    return (int)(totalHeight / boundSize.height);
}

@end
