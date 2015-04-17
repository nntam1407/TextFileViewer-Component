/*============================================================================
 PROJECT: TextViewer
 FILE:    TextFileView.h
 AUTHOR:  Tam Nguyen
 DATE:    4/17/15
 =============================================================================*/

/*============================================================================
 IMPORT
 =============================================================================*/
#import <UIKit/UIKit.h>
#import "TextDocument.h"
/*============================================================================
 MACRO
 =============================================================================*/

/*============================================================================
 PROTOCOL
 =============================================================================*/

/*============================================================================
 Interface:   TextFileView
 =============================================================================*/

@interface TextFileView : UITextView

- (void)beginRenderDocument:(TextDocument *)document;

@end
