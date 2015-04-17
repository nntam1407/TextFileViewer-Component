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

#define kBufferSize         8192//8192

/*============================================================================
 PRIVATE INTERFACE
 =============================================================================*/

@interface TextDocument()

@property (strong, nonatomic) NSData *fileData; // Only map on memory, not read all file to memory

@end

@implementation TextDocument

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    
    if (self) {
        _blockSize = kBufferSize;
        _filePath = filePath;
        
        NSError *error = nil;
        _fileData = [NSData dataWithContentsOfFile:self.filePath options:NSDataReadingMappedIfSafe error:&error];
        
        if (!error) {
            _fileSize = [self.fileData length];
        } else {
            _fileData = nil;
        }
    }
    
    return self;
}

- (void)dealloc {
    _fileData = nil;
}

#pragma mark - Override methods

- (BOOL)fileNotFound {
    if (!self.filePath || self.filePath.length == 0) {
        return YES;
    } else {
        return ![[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
    }
}

- (NSUInteger)blockNumbers {
    NSUInteger blocks = self.fileSize / self.blockSize;
    
    if (self.fileSize % self.blockSize > 0) {
        blocks += 1;
    }
    
    return blocks;
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
    NSUInteger dataLength = [fileData length];
    
    // Read data and calculator page count
    NSUInteger readPointer = 0;

    while (readPointer < dataLength) {
        @autoreleasepool {
            NSUInteger remainByteCount = dataLength - readPointer;
            NSUInteger byteToRead = kBufferSize < remainByteCount ? kBufferSize : remainByteCount;
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

#pragma mark - Methods

- (NSString *)readTextAtBlockIndex:(NSUInteger)blockIndex {
    if (blockIndex >= self.blockNumbers || !self.fileData) {
        return nil;
    }
    
    // Read data from file at block index
    NSRange rangeToRead = NSMakeRange(blockIndex * self.blockSize, self.blockSize);
    
    if (rangeToRead.location + rangeToRead.length > self.fileSize) {
        rangeToRead.length = self.fileSize - rangeToRead.location;
    }
    
    NSMutableData *data = [NSMutableData dataWithCapacity:rangeToRead.length];
    [self.fileData getBytes:data.mutableBytes range:rangeToRead];
    
    // Convert to NSString data
    NSString *text = [[NSString alloc] initWithBytes:data.bytes length:rangeToRead.length encoding:NSUTF8StringEncoding];
    
    // Return text
    return text;
}

@end
