/*============================================================================
 PROJECT: TextViewer
 FILE:    TextBlock.h
 AUTHOR:  Tam Nguyen
 DATE:    4/17/15
 =============================================================================*/

/*============================================================================
 IMPORT
 =============================================================================*/
#import <UIKit/UIKit.h>

/*============================================================================
 MACRO
 =============================================================================*/

/*============================================================================
 PROTOCOL
 =============================================================================*/

/*============================================================================
 Interface:   TextBlock
 =============================================================================*/


@interface TextBlock : NSObject

@property (strong, nonatomic) NSAttributedString *text;
@property (assign, nonatomic) CGRect displayRect;
@property (assign, nonatomic) NSUInteger blockIndex;

@end
