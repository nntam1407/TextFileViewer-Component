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
#import "TextSearchResult.h"
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

// Support for search text
@property (strong, nonatomic) NSString *currentSearchText;
@property (assign, atomic) BOOL isCancelling;

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
        
        // Get file encoding
        _fileEncoding = [self detectEncodingOfFile];
    }
    
    return self;
}

- (void)dealloc {
    [self cancelSearch];
    
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

- (NSStringEncoding)detectEncodingOfFile {
    NSStringEncoding encoding = NSUTF8StringEncoding; // Default is UTF-8
    
    /**
     * To get encoding of this file, we should get 12 fist bytes, because we have 3 bytes or 4 bytes encoding
     */
    NSRange readRange = NSMakeRange(0, 12);
    
    if (readRange.length > self.fileSize) {
        readRange.length = self.fileSize;
    }
    
    NSMutableData *data = [NSMutableData dataWithCapacity:readRange.length];
    [self.fileData getBytes:data.mutableBytes range:readRange];
    
    // Detect encoding of this data
    NSDictionary *documentAttributes = nil;
    NSAttributedString *text = [[NSMutableAttributedString alloc] initWithData:[NSData dataWithBytes:data.bytes length:readRange.length] options:nil documentAttributes:&documentAttributes error:nil];
    
    if (documentAttributes) {
        encoding = [documentAttributes[NSCharacterEncodingDocumentAttribute] integerValue];
    }
    
    NSLog(@"%@", text.string);
    return encoding;
}

- (NSArray *)searchResultsInBlockIndex:(NSUInteger)blockIndex {
    NSRange blockRange = NSMakeRange(blockIndex * self.blockSize, self.blockSize);
    
    if (blockRange.location + blockRange.length > self.fileSize) {
        blockRange.length = self.fileSize - blockRange.location;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (TextSearchResult *search in self.searchResult) {
        if (search.dataRange.location >= blockRange.location && search.dataRange.length <= blockRange.length) {
            [result addObject:search];
        }
    }
    
    return result;
}

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
            NSString *text = [[NSString alloc] initWithBytes:data length:byteToRead encoding:self.fileEncoding];
            
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

- (NSAttributedString *)readTextAtBlockIndex:(NSUInteger)blockIndex hightlightSearch:(BOOL)hightlightSearch {
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
    NSDictionary *documentAttributes = nil;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithData:blockTextData options:nil documentAttributes:&documentAttributes error:nil];
    
    if (text.length > 0 && hightlightSearch && self.currentSearchText.length > 0) {
        // Find all search result in data block
        NSRange searchRangeInText = NSMakeRange(0, text.string.length);
        
        while (searchRangeInText.location < text.string.length) {
            searchRangeInText.length = text.string.length - searchRangeInText.location;
            NSRange foundRange = [text.string rangeOfString:self.currentSearchText options:NSCaseInsensitiveSearch range:searchRangeInText];
            
            if (foundRange.location != NSNotFound) {
                searchRangeInText.location = foundRange.location + foundRange.length;
                
                // Hight light this ranges
                [text addAttribute:NSBackgroundColorAttributeName value:[UIColor yellowColor] range:foundRange];
            } else {
                // Found nothing. Break to start search in new block text
                break;
            }
        }
    }
    
    return text;
}

#pragma mark - Supoort for search

- (void)startSeachWithText:(NSString *)text {
    [self cancelSearch];
    
    if (!self.searchResult) {
        _searchResult = [NSMutableArray array];
    }
    
    // Start new search
    if (text && text.length > 0) {
        // Call delegate start search
        if (self.delegate && [self.delegate respondsToSelector:@selector(textDocument:beginSearchText:)]) {
            [self.delegate textDocument:self beginSearchText:text];
        }
        
        _isSearching = YES;
        self.currentSearchText = text;
        
        // Start search in background
        __weak TextDocument *weakSelf = self;
        __block NSString *searchText = [self.currentSearchText copy];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (!weakSelf || ![weakSelf.currentSearchText isEqualToString:searchText]) {
                return;
            }
            
            /**
             * We will read each block data, then convert to text, then crop last word to make sure all word be finished read/
             */
            
            // init new mapping file data to make sure perfomance when readText block method is called
            NSError *error = nil;
            NSData *searchFileData = [NSData dataWithContentsOfFile:self.filePath options:NSDataReadingMappedIfSafe error:&error];
            
            if (!searchFileData || error) {
                // Error when mapping file data
                _isSearching = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(textDocument:searchText:failedWithError:)]) {
                        [weakSelf.delegate textDocument:weakSelf searchText:searchText failedWithError:error];
                    }
                });
            } else {
                // Start of begin file
                NSUInteger readByteSeekPoint = 0;
                
                while (weakSelf && [weakSelf.currentSearchText isEqualToString:searchText] && readByteSeekPoint < weakSelf.fileSize) {
                    NSUInteger readLength = kBufferSize;
                    
                    if (readByteSeekPoint + readLength > weakSelf.fileSize) {
                        readLength = weakSelf.fileSize - readByteSeekPoint;
                    }
                    
                    // Read from file
                    @autoreleasepool {
                        NSMutableData *data = [NSMutableData dataWithCapacity:readLength];
                        [searchFileData getBytes:data.mutableBytes range:NSMakeRange(readByteSeekPoint, readLength)];
                        NSString *blockText = [[NSString alloc] initWithBytes:data.bytes length:readLength encoding:weakSelf.fileEncoding];
                        
                        if (blockText) {
                            // Remove last word of this block text
                            NSRange range = [blockText rangeOfString:@" " options:NSBackwardsSearch];
                            
                            if (range.location != NSNotFound) {
                                /**
                                 * We should calculator actualy how many bytes we need to read this time
                                 * then update readLength value
                                 */
                                NSString *deletedText = [blockText substringFromIndex:range.location+1];
                                NSData *deletedData = [deletedText dataUsingEncoding:weakSelf.fileEncoding];
                                readLength -= deletedData.length;
                                
                                // Take the first substring: from 0 to the space character
                                blockText = [blockText substringToIndex:range.location];
                            }
                            
                            // Now start search this text in blockText
                            NSRange searchRangeInText = NSMakeRange(0, blockText.length);
                            
                            while (searchRangeInText.location < blockText.length) {
                                searchRangeInText.length = blockText.length - searchRangeInText.location;
                                NSRange foundRange = [blockText rangeOfString:searchText options:NSCaseInsensitiveSearch range:searchRangeInText];
                                
                                if (foundRange.location != NSNotFound) {
                                    // Save search result into array
                                    if (weakSelf && [weakSelf.currentSearchText isEqualToString:searchText]) {
                                        // Update next search range
                                        searchRangeInText.location = foundRange.location + foundRange.length;
                                        
                                        // calculator range of byte on file of this result
                                        int resultByteLength = [[blockText substringWithRange:foundRange] dataUsingEncoding:weakSelf.fileEncoding].length;
                                        int resultByteOffset = [[blockText substringToIndex:foundRange.location] dataUsingEncoding:weakSelf.fileEncoding].length;
                                        
                                        TextSearchResult *result = [[TextSearchResult alloc] initWithDataRange:NSMakeRange(readByteSeekPoint + resultByteOffset, resultByteLength)];
                                        
                                        if (!weakSelf.isCancelling) {
                                            [weakSelf.searchResult addObject:result];
                                            
                                            // Call delegate did found text
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                if (weakSelf && weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(textDocument:searchText:didFoundResult:)]) {
                                                    [weakSelf.delegate textDocument:weakSelf searchText:searchText didFoundResult:result];
                                                }
                                            });
                                        } else {
                                            break;
                                        }
                                    } else {
                                        // Maybe document object has been dealloc, or start new search with difference text
                                        break;
                                    }
                                    
                                } else {
                                    // Found nothing. Break to start search in new block text
                                    break;
                                }
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // Call delegate did search in block text
                            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(textDocument:didSearchInBlocTextWithKeyword:)]) {
                                [weakSelf.delegate textDocument:weakSelf didSearchInBlocTextWithKeyword:searchText];
                            }
                        });
                        
                        // Set new read seek point
                        readByteSeekPoint += readLength;
                    }
                }
                
                // call delegate seach complete
                if (weakSelf && [weakSelf.currentSearchText isEqualToString:searchText]) {
                    _isSearching = NO;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(textDocument:finishedSearchText:)]) {
                            [weakSelf.delegate textDocument:weakSelf finishedSearchText:searchText];
                        }
                    });
                }
            }
        });
    }
}

- (void)cancelSearch {
    _isSearching = NO;
    self.currentSearchText = nil;
    self.isCancelling = YES;
    
    [self.searchResult removeAllObjects];
    _searchResult = nil;
    
    self.isCancelling = NO;
}

@end
