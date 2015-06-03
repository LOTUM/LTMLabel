//
// Copyright (c) 2015 LOTUM GmbH (http://lotum.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <UIKit/UIKit.h>

@interface LTMLabel : UIView <NSCopying>

@property (nonatomic) NSAttributedString *attributedText;

@property (nonatomic) CGFloat minimumScaleFactor;
@property (nonatomic) CGSize maxSize;

@property (nonatomic) NSArray* strokeWidths; //NSNumber
@property (nonatomic) NSArray* strokeColors; //UIColor

@property (nonatomic) NSArray* gradientColors; //UIColor
@property (nonatomic) CGPoint gradientStartPoint;
@property (nonatomic) CGPoint gradientEndPoint;

@property (nonatomic) NSArray* innerShadows; //NSShadow
@property (nonatomic) NSArray* innerShadowBlendModes; //NSNumber (CGBlendMode)

@end

@interface LTMLabel (Convenient)

@property (nonatomic) CGFloat strokeWidth;
@property (nonatomic) UIColor *strokeColor;

@property (nonatomic) UIColor* gradientStartColor;
@property (nonatomic) UIColor* gradientEndColor;

@property (nonatomic) NSShadow* innerShadow;
@property (nonatomic) CGBlendMode innerShadowBlendMode;

@end

@interface LTMLabel (UILabelCompatibility)

@property (nonatomic) NSString* text;
@property (nonatomic) UIFont* font;
@property (nonatomic) UIColor* textColor;
@property (nonatomic) NSTextAlignment textAlignment;

@end

@interface NSAttributedString (LTMFactory)

+ (instancetype)ltm_attributedString:(NSString *)string;

+ (instancetype)ltm_attributedString:(NSString *)string
                            textFont:(UIFont *)font;

+ (instancetype)ltm_attributedString:(NSString *)string
                            textFont:(UIFont *)font
                           textColor:(UIColor *)textColor;

+ (instancetype)ltm_attributedString:(NSString *)string
                            textFont:(UIFont *)font
                           textColor:(UIColor *)textColor
                           alignment:(NSTextAlignment)alignment;

@end

@interface NSAttributedString (LTMHelper)

-(instancetype)ltm_attributedStringWithForegroundColor:(UIColor *)color;

@end