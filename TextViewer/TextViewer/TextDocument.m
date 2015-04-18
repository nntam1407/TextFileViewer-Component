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

#define kBufferSize                     8192//8192
#define kDefaultTextCacheSize           49152

/*============================================================================
 PRIVATE INTERFACE
 =============================================================================*/

@interface TextDocument()

@property (strong, nonatomic) NSData *fileData; // Only map on memory, not read all file to memory

/**
 * temporary text for each time read from file. 
 * It may should be 48kb (This number is only guessing). Because character can be 2, 3 or 4 bytes, so 48*1024 % 12 = 0. This make sure all character will be converted to NSString
 */
@property (strong, nonatomic) NSData *readTextCacheData;

/**
 * Range of readTextCache from file.
 * This will be used for getBlockText method. 
 * First should check range of block need to get in temp text, if out of range, we should read new temp text
 */
@property (assign, nonatomic) NSRange readTextCacheDataRange;

@end

@implementation TextDocument

@synthesize delegate = _delegate;

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    
    if (self) {
        _filePath = filePath;
        
        _blockSize = kBufferSize;
        _readTextCacheDataRange = NSMakeRange(0, 0); // Zero
        
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
    _readTextCacheData = nil;
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
    
    /**
     * First, before read this data from file, we should check this range is contained in readTextCache
     * If out of range, we will get new temp text, then get text from that
     */
    NSData *blockTextData = nil;
    
    if (rangeToRead.location >= self.readTextCacheDataRange.location &&
        rangeToRead.location + rangeToRead.length <= self.readTextCacheDataRange.location + self.readTextCacheDataRange.length &&
        self.readTextCacheData.length > 0) {
        
        // Get data from cache
        blockTextData = [self.readTextCacheData subdataWithRange:NSMakeRange(rangeToRead.location - self.readTextCacheDataRange.location, rangeToRead.length)];
    } else {
        // Should read temp data from file
        self.readTextCacheDataRange = NSMakeRange(rangeToRead.location, kDefaultTextCacheSize);
        
        if (self.readTextCacheDataRange.location + self.readTextCacheDataRange.length > self.fileSize) {
            _readTextCacheDataRange.length = self.fileSize - self.readTextCacheDataRange.location;
        }
        
        // Read from file
        NSMutableData *data = [NSMutableData dataWithCapacity:_readTextCacheDataRange.length];
        [self.fileData getBytes:data.mutableBytes range:_readTextCacheDataRange];
        
        // Save this cache
        self.readTextCacheData = [NSData dataWithBytes:data.bytes length:self.readTextCacheDataRange.length];
        
        // Get block data after read from file
        blockTextData = [self.readTextCacheData subdataWithRange:NSMakeRange(rangeToRead.location - self.readTextCacheDataRange.location, rangeToRead.length)];
    }
    
    // Return text
    return [[NSString alloc] initWithData:blockTextData encoding:NSUTF8StringEncoding];
}

#pragma mark - Supoort for search

- (void)startSeachWithText:(NSString *)text {
    [self cancelSearch];
}

- (void)cancelSearch {
    _isSearching = NO;
    
    if (self.searchResult) {
        [self.searchResult removeAllObjects];
    }
}

@end
