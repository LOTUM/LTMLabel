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