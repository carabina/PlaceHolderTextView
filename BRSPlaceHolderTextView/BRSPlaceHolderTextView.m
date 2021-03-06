//       MIT License
//      
//       Copyright (c) 2017 bindurs
//      
//       Permission is hereby granted, free of charge, to any person obtaining a copy
//       of this software and associated documentation files (the "Software"), to deal
//       in the Software without restriction, including without limitation the rights
//       to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//       copies of the Software, and to permit persons to whom the Software is
//       furnished to do so, subject to the following conditions:
//      
//       The above copyright notice and this permission notice shall be included in all
//       copies or substantial portions of the Software.
//      
//       THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//       IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//       FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//       AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//       LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//       OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//       SOFTWARE.
//
//  BRSPlaceHolderTextView.m
//

#import "BRSPlaceHolderTextView.h"

// Manually-selected label offsets to align placeholder label with text entry.
static CGFloat const kLabelLeftOffset = 8.f;
static CGFloat const kLabelTopOffset = 0.f;

// When instantiated from IB, the text view has an 8 point top offset:
static CGFloat const kLabelTopOffsetFromIB = 8.f;
// On retina iPhones and iPads, the label is offset by 0.5 points:
static CGFloat const kLabelTopOffsetRetina = 0.5f;

@interface BRSPlaceHolderTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;

// The top offset differs when the view is instantiated from IB or programmatically.
// Use this to track the instantiation route and offset the label accordingly.
@property (nonatomic, assign) CGFloat topLabelOffset;

// Handle text changed event so we can update the placeholder appropriately
- (void)textChanged:(NSNotification *)note;

@end


@implementation BRSPlaceHolderTextView

#pragma mark - Initializers

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Account for IB offset:
        _topLabelOffset = kLabelTopOffsetFromIB;
        [self finishInitialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _topLabelOffset = kLabelTopOffset;
        [self finishInitialization];
    }
    return self;
}

// Private method for finishing initialization.
// Since this class isn't documented for subclassing,
// I don't feel comfortable changing the initializer chain.
// Let's do it this way rather than overriding UIView's designated initializer.
- (void)finishInitialization {
    // Sign up for notifications for text changes:
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textChanged:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];

    CGFloat labelLeftOffset = kLabelLeftOffset;
    // Use our calculated label offset from initWith…:
    CGFloat labelTopOffset = self.topLabelOffset;

    // On retina iPhones and iPads, the label is offset by 0.5 points.
    if ([[UIScreen mainScreen] scale] == 2.0) {
        labelTopOffset += kLabelTopOffsetRetina;
    }

    CGSize labelOffset = CGSizeMake(labelLeftOffset, labelTopOffset);
    CGRect labelFrame = [self placeholderLabelFrameWithOffset:labelOffset];
    [self createPlaceholderLabel:labelFrame];
}


#pragma mark - Placeholder label helpers

// Create our label:
- (void)createPlaceholderLabel:(CGRect)labelFrame {
    self.placeholderLabel = [[UILabel alloc] initWithFrame:labelFrame];
    self.placeholderLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.placeholderLabel.numberOfLines = 0;
    if (self.placeholderFont) {
        self.placeholderLabel.font = self.placeholderFont;
    } else {
        self.placeholderLabel.font = self.font;
    }
    self.placeholderLabel.backgroundColor = [UIColor clearColor];
    self.placeholderLabel.text = self.placeholderText;
    // Color-matched to UITextField's placeholder text color:
    if (self.placeholderColor) {
        self.placeholderLabel.textColor = self.placeholderColor;
    } else {
        self.placeholderLabel.textColor = [UIColor colorWithWhite:0.71f alpha:1.0f];
    }

    // UIKit effects on the UITextView, like selection ranges
    // and the cursor, are done in a view above the text view,
    // so no need to order this below anything else.
    // Add the label as a subview.
    [self addSubview:self.placeholderLabel];
}

- (CGRect)placeholderLabelFrameWithOffset:(CGSize)labelOffset {
    return CGRectMake(labelOffset.width,
                      labelOffset.height,
                      self.bounds.size.width  - (2 * labelOffset.width),
                      self.bounds.size.height - (2 * labelOffset.height));
}


#pragma mark - Custom accessors

- (void)setPlaceholderText:(NSString *)string {
    _placeholderText = [string copy];
    self.placeholderLabel.text = string;
    [self.placeholderLabel sizeToFit];
}

- (void)setPlaceholderColor:(UIColor *)color {
    self.placeholderLabel.textColor = color;
    [self.placeholderLabel sizeToFit];
}

- (void)setPlaceholderFont:(UIFont *)font {
    self.placeholderLabel.font = font;
    [self.placeholderLabel sizeToFit];
}

- (void)setTextViewBorderWidth:(CGFloat)textViewBorderWidth {
    self.layer.borderWidth =textViewBorderWidth;
    [self sizeToFit];
}

-(void)setTextViewCornerRadius:(CGFloat)textViewCornerRadius {
    self.layer.cornerRadius =textViewCornerRadius;
    [self sizeToFit];
}

-(void)setTextViewBorderColor:(UIColor *)textViewBorderColor {
    self.layer.borderColor =textViewBorderColor.CGColor;
    [self sizeToFit];
}

-(void)setTextViewTintColor:(UIColor *)textViewTintColor {
    self.tintColor = textViewTintColor;
    [self sizeToFit];
}

#pragma mark - UITextView subclass methods

// Keep the placeholder label font in sync with the view's text font.
- (void)setFont:(UIFont *)font {
    // Call super.
    [super setFont:font];

    self.placeholderLabel.font = self.font;
}

// Keep placeholder label alignment in sync with the view's text alignment.
- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    // Call super.
    [super setTextAlignment:textAlignment];

    self.placeholderLabel.textAlignment = textAlignment;
}

// Todo: override setAttributedText to capture changes
// in text alignment?


#pragma mark - UITextInput overrides

// Listen to dictation events to hide the placeholder as is appropriate.

// Hide when there's a dictation result placeholder
- (id)insertDictationResultPlaceholder {
    // Call super.
    id placeholder = [super insertDictationResultPlaceholder];

    // Use -[setHidden] here instead of setAlpha:
    // these events also trigger -[textChanged],
    // which has a different criteria by which it shows the label,
    // but we undeniably know we want this placeholder hidden.
    self.placeholderLabel.hidden = YES;
    return placeholder;
}

// Update visibility when dictation ends.
- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult {
    // Call super.
    [super removeDictationResultPlaceholder:placeholder willInsertResult:willInsertResult];

    // Unset the hidden flag from insertDictationResultPlaceholder.
    self.placeholderLabel.hidden = NO;

    // Update our text label based on the entered text.
    [self updatePlaceholderLabelVisibility];
}


#pragma mark - Text change listeners

- (void)updatePlaceholderLabelVisibility {
    if ([self.text length] == 0) {
        self.placeholderLabel.alpha = 1.f;
    } else {
        self.placeholderLabel.alpha = 0.f;
    }
}

// When text is set or changed, update the label's visibility.

- (void)setText:(NSString *)text {
    // Call super.
    [super setText:text];

    [self updatePlaceholderLabelVisibility];
}

- (void)textChanged:(NSNotification *)notification {
    [self updatePlaceholderLabelVisibility];
}

@end
