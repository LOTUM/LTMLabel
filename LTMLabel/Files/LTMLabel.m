#import "LTMLabel.h"

@interface LTMLabelLayoutManager : NSLayoutManager

@property (nonatomic) NSArray* strokeWidths;
@property (nonatomic) NSArray* strokeColors;

@property (nonatomic) CGPoint gradientStartPoint;
@property (nonatomic) CGPoint gradientEndPoint;
@property (nonatomic) NSArray* gradientColors;

@property (nonatomic) NSArray* innerShadows;
@property (nonatomic) NSArray* innerShadowBlendModes;

-(void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow
                       atPoint:(CGPoint)origin
                        inRect:(CGRect)rect;

@end

@implementation LTMLabelLayoutManager
{
    BOOL _renderMask;
    BOOL _renderOnlyStroke;
}

-(void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow
                       atPoint:(CGPoint)origin
                        inRect:(CGRect)rect
{
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    BOOL hasGradient = self.gradientColors.count > 1;
    BOOL hasInnerShadow = self.innerShadows.count > 0;
    BOOL needsAlphaMask = hasGradient || hasInnerShadow;
    
    CGImageRef alphaMask = NULL;
    if(needsAlphaMask)
    {
        //create mask from text without stroke
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
        CGContextRef alphaMaskContext = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(alphaMaskContext);
        
        // Invert everything, because CG works with an inverted coordinate system.
        CGContextTranslateCTM(alphaMaskContext, 0.0, CGRectGetHeight(rect));
        CGContextScaleCTM(alphaMaskContext, 1.0, -1.0);
        
        // Draw alpha mask.
        _renderMask = YES;
        [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
        _renderMask = NO;
        
        // Save alpha mask.
        alphaMask = CGBitmapContextCreateImage(alphaMaskContext);
        
        // Clear the content.
        CGContextClearRect(alphaMaskContext, rect);
        CGContextRestoreGState(alphaMaskContext);
        UIGraphicsEndImageContext();
    }
    
    if(hasGradient)
    {
        //render stroke in background
        _renderMask = NO;
        _renderOnlyStroke = YES;
        [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
        
        // Clip the current context to alpha mask.
        CGContextSaveGState(currentContext);
        CGContextClipToMask(currentContext, rect, alphaMask);
        [self drawGradientWithColors:self.gradientColors
                          startPoint:self.gradientStartPoint
                            endPoint:self.gradientEndPoint
                                rect:rect
                           inContext:currentContext];
        CGContextRestoreGState(currentContext);
    }
    else
    {
        _renderMask = NO;
        _renderOnlyStroke = NO;
        [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
    }
    
    if(hasInnerShadow)
    {
        CGContextSaveGState(currentContext);
        
        // Clip the current context to alpha mask.
        CGContextClipToMask(currentContext, rect, alphaMask);
        
        // Invert to draw the inner shadow correctly.
        CGContextTranslateCTM(currentContext, 0.0, CGRectGetHeight(rect));
        CGContextScaleCTM(currentContext, 1.0, -1.0);
        
        // Draw inner shadow.
        CGImageRef shadowImage = [self inverseMaskFromAlphaMask:alphaMask withRect:rect];
        
        for(NSInteger i = 0; i < self.innerShadows.count; i++)
        {
            NSShadow* shadow = self.innerShadows[i];
            CGBlendMode blendMode = (CGBlendMode)(i < self.innerShadowBlendModes.count ? ((NSNumber *)self.innerShadowBlendModes[i]).integerValue : kCGBlendModeNormal);
            CGContextSetShadowWithColor(currentContext, shadow.shadowOffset, shadow.shadowBlurRadius, ((UIColor *)shadow.shadowColor).CGColor);
            CGContextSetBlendMode(currentContext, blendMode);
            CGContextDrawImage(currentContext, rect, shadowImage);
        }
        
        // Clean up.
        CGImageRelease(shadowImage);
        
        CGContextRestoreGState(currentContext);
    }
    
    if(needsAlphaMask)
    {
        CGImageRelease(alphaMask);
    }
}

-(void)drawGradientWithColors:(NSArray *)arrayOfColors
                   startPoint:(CGPoint)gradientStartPoint
                     endPoint:(CGPoint)gradientEndPoint
                         rect:(CGRect)textRect
                    inContext:(CGContextRef)context
{
    // Get gradient colors as CGColor.
    NSMutableArray *gradientColors = [NSMutableArray arrayWithCapacity:arrayOfColors.count];
    for (UIColor *color in arrayOfColors) {
        [gradientColors addObject:(__bridge id)color.CGColor];
    }
    
    // Create gradient.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, NULL);
    CGPoint startPoint = CGPointMake(textRect.origin.x + gradientStartPoint.x * CGRectGetWidth(textRect),
                                     textRect.origin.y + gradientStartPoint.y * CGRectGetHeight(textRect));
    CGPoint endPoint = CGPointMake(textRect.origin.x + gradientEndPoint.x * CGRectGetWidth(textRect),
                                   textRect.origin.y + gradientEndPoint.y * CGRectGetHeight(textRect));
    
    // Draw gradient.
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    
    // Clean up.
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
}

- (CGImageRef)inverseMaskFromAlphaMask:(CGImageRef)alphaMask
                              withRect:(CGRect)rect CF_RETURNS_RETAINED
{
    // Create context.
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Fill rect, clip to alpha mask and clear.
    [[UIColor whiteColor] setFill];
    UIRectFill(rect);
    CGContextClipToMask(context, rect, alphaMask);
    CGContextClearRect(context, rect);
    
    // Return image.
    CGImageRef image = CGBitmapContextCreateImage(context);
    UIGraphicsEndImageContext();
    return image;
}


-(void)showCGGlyphs:(const CGGlyph *)glyphs
          positions:(const CGPoint *)positions
              count:(NSUInteger)glyphCount
               font:(UIFont *)font
             matrix:(CGAffineTransform)textMatrix
         attributes:(NSDictionary *)attributes
          inContext:(CGContextRef)graphicsContext
{
    BOOL drawStroke = self.strokeWidths.count > 0;
    CGFloat maxStroke = 0;
    
    if(drawStroke)
    {
        maxStroke = ((NSNumber *)[self.strokeWidths valueForKeyPath:@"@max.self"]).floatValue;
    }
    
    if(_renderMask)
    {
        if(drawStroke)
        {
            CGContextSetTextDrawingMode(graphicsContext, kCGTextFillStroke);
            CGContextSetLineWidth(graphicsContext, maxStroke);
            CGContextSetLineJoin(graphicsContext, kCGLineJoinRound);
            [[UIColor clearColor] setStroke];
        }
        [[UIColor whiteColor] setFill];
        [super showCGGlyphs:glyphs
                  positions:positions
                      count:glyphCount
                       font:font
                     matrix:textMatrix
                 attributes:attributes
                  inContext:graphicsContext];
        return;
    }
    
    if(drawStroke)
    {
        for(NSInteger i = self.strokeWidths.count - 1; i >= 0; i--)
        {
            NSNumber* strokeSize = self.strokeWidths[i];
            UIColor* strokeColor = i < self.strokeColors.count ? self.strokeColors[i] : [UIColor blackColor];
            CGContextSetTextDrawingMode(graphicsContext, kCGTextStroke);
            CGContextSetLineWidth(graphicsContext, strokeSize.floatValue);
            CGContextSetLineJoin(graphicsContext, kCGLineJoinRound);
            [strokeColor setStroke];
            
            [super showCGGlyphs:glyphs
                      positions:positions
                          count:glyphCount
                           font:font
                         matrix:textMatrix
                     attributes:attributes
                      inContext:graphicsContext];
        }
        
        CGContextSetTextDrawingMode(graphicsContext, kCGTextFillStroke);
        CGContextSetLineWidth(graphicsContext, maxStroke);
        CGContextSetLineJoin(graphicsContext, kCGLineJoinRound);
        [[UIColor clearColor] setStroke];
    }
    
    if(!_renderOnlyStroke)
    {
        [super showCGGlyphs:glyphs
                  positions:positions
                      count:glyphCount
                       font:font
                     matrix:textMatrix
                 attributes:attributes
                  inContext:graphicsContext];
    }
}

@end


@interface LTMLabelTextContainer : NSTextContainer

@end

@implementation LTMLabelTextContainer

@end


@implementation LTMLabel
{
    NSTextStorage* _textStorage;
    LTMLabelLayoutManager* _layoutManager;
    LTMLabelTextContainer* _textContainer;
    CGFloat _maxStrokeWidth;
    
    //compatibility - handled in category
    UIColor* _textColor;
    NSString* _text;
    NSTextAlignment _textAlignment;
    UIFont* _font;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
        [self initialize];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
        [self initialize];
    return self;
}

- (void)initialize
{
    _maxSize = self.bounds.size;
    _maxStrokeWidth = 0;
    _minimumScaleFactor = 1.f;
    _layoutManager = [[LTMLabelLayoutManager alloc] init];
    _textContainer = [[LTMLabelTextContainer alloc] init];
    [_layoutManager addTextContainer:_textContainer];
    _gradientStartPoint = CGPointMake(0.5f, 0);
    _gradientEndPoint = CGPointMake(0.5f, 1);
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
}

#pragma mark - Setter

-(void)setStrokeColors:(NSArray *)strokeColors
{
    _strokeColors = strokeColors;
    [self setNeedsDisplay];
}

-(void)setStrokeWidths:(NSArray *)strokeWidths
{
    _strokeWidths = strokeWidths;
    _maxStrokeWidth = ((NSNumber *)[_strokeWidths valueForKeyPath:@"@max.self"]).floatValue;
    _textContainer.lineFragmentPadding = [self contentInsets].left;
    [self setNeedsDisplay];
}

-(void)setGradientColors:(NSArray *)gradientColors
{
    _gradientColors = gradientColors;
    [self setNeedsDisplay];
}

-(void)setGradientStartPoint:(CGPoint)gradientStartPoint
{
    _gradientStartPoint = gradientStartPoint;
    [self setNeedsDisplay];
}

-(void)setGradientEndPoint:(CGPoint)gradientEndPoint
{
    _gradientEndPoint = gradientEndPoint;
    [self setNeedsDisplay];
}

-(void)setInnerShadows:(NSArray *)innerShadows
{
    _innerShadows = innerShadows;
    [self setNeedsDisplay];
}

-(void)setInnerShadowBlendModes:(NSArray *)innerShadowBlendModes
{
    _innerShadowBlendModes = innerShadowBlendModes;
    [self setNeedsDisplay];
}

- (void)setMinimumScaleFactor:(CGFloat)minimumScaleFactor
{
    _minimumScaleFactor = minimumScaleFactor;
    [self stringDidChange];
    [self setNeedsDisplay];
}

- (void)setMaxSize:(CGSize)maxSize
{
    _maxSize = maxSize;
    [self stringDidChange];
    [self setNeedsDisplay];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [self setAttributedText:attributedText withNeedsDisplay:YES];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
         withNeedsDisplay:(BOOL)needsDisplay
{
    if(attributedText)
    {
        _textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedText];
        [_textStorage addLayoutManager:_layoutManager];
    }
    else
    {
        _textStorage = nil;
        [_layoutManager setTextStorage:nil];
    }
    [self stringDidChange];
    
    if(needsDisplay)
    {
        [self setNeedsDisplay];
    }
}

-(NSAttributedString *)attributedText
{
    return [_textStorage copy];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    if(!self.attributedText)
    {
        return;
    }
    
    [_textContainer setSize:self.bounds.size];
    _layoutManager.strokeWidths = self.strokeWidths;
    _layoutManager.strokeColors = self.strokeColors;
    _layoutManager.gradientColors = self.gradientColors;
    _layoutManager.gradientStartPoint = self.gradientStartPoint;
    _layoutManager.gradientEndPoint = self.gradientEndPoint;
    _layoutManager.innerShadows = self.innerShadows;
    _layoutManager.innerShadowBlendModes = self.innerShadowBlendModes;
    
    CGRect textRect = [_layoutManager usedRectForTextContainer:_textContainer];
    
    CGPoint startDrawingPoint = self.bounds.origin;
    if(textRect.size.height < self.bounds.size.height)
    {
        startDrawingPoint.y = roundf((self.bounds.size.height - textRect.size.height) / 2);
    }
    
    NSRange glyphRange = [_layoutManager glyphRangeForTextContainer:_textContainer];
    [_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:startDrawingPoint inRect:self.bounds];
}

- (CGRect)textRectForWidth:(CGFloat)width
{
    CGSize oldSize = _textContainer.size;
    _textContainer.size = CGSizeMake(width, INFINITY);
    CGRect rect = [_layoutManager usedRectForTextContainer:_textContainer];
    _textContainer.size = oldSize;
    return rect;
}

#pragma mark - Private helper

- (UIEdgeInsets)contentInsets
{
    CGFloat halfWidth = _maxStrokeWidth / 2;
    return UIEdgeInsetsMake(halfWidth, halfWidth, halfWidth, halfWidth);
}

- (CGRect)contentRect
{
    return UIEdgeInsetsInsetRect(self.bounds, [self contentInsets]);
}

- (NSRange)textRange
{
    return NSMakeRange(0, self.attributedText.length);
}

- (NSAttributedString *)attributedStringWithScale:(CGFloat)scale
{
    NSMutableAttributedString *as = [self.attributedText mutableCopy];
    NSRange range = NSMakeRange(0, as.length);
    
    //replace all font with fonts in pointsize * scale
    [as enumerateAttribute:NSFontAttributeName
                   inRange:range
                   options:0
                usingBlock:^(UIFont *font, NSRange range, BOOL *stop) {
                    UIFont* newFont = [UIFont fontWithName:font.fontName size:font.pointSize * scale];
                    [as addAttribute:NSFontAttributeName value:newFont range:range];
                }];
    
    return [as copy];
}

- (void)stringDidChange
{
    //no text set then return
    if (!self.attributedText)
    {
        return;
    }
    
    //max size is set so grow bounds
    if (CGSizeEqualToSize(self.bounds.size, self.maxSize) == NO)
    {
        [self changeFrameToFitMaxSize];
    }
    
    //min scale factor is set so change attributed string font scale
    if (self.minimumScaleFactor < 1)
    {
        [self changeScaleFactor];
    }
}

#pragma mark Scaling

- (void)changeScaleFactor
{
    //create new as without paragraph style, because text align center disables scaling
    CGRect contentRect = [self contentRect];
    NSMutableAttributedString *leftAlignedAs = [self.attributedText mutableCopy];
    [leftAlignedAs removeAttribute:NSParagraphStyleAttributeName
                             range:NSMakeRange(0, leftAlignedAs.length)];
    
    CGRect originalRect = [self textRectForWidth:contentRect.size.width]; //rect incl lineSpacing
    CGRect withoutParagraphRect = [leftAlignedAs boundingRectWithSize:contentRect.size
                                                              options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                              context:nil];
    CGFloat lineSpacingDifference = originalRect.size.height - withoutParagraphRect.size.height;
    contentRect.size.height -= lineSpacingDifference;
    
    //TODO: fix when paragraph style changes text bounds by kerning or line height
    
    NSStringDrawingContext *stringCtx = [[NSStringDrawingContext alloc] init];
    stringCtx.minimumScaleFactor = self.minimumScaleFactor;
    [leftAlignedAs boundingRectWithSize:contentRect.size
                                options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                context:stringCtx];
    
    if (stringCtx.actualScaleFactor < 1)
    {
        self.attributedText = [self attributedStringWithScale:stringCtx.actualScaleFactor];
    }
}

#pragma mark Frame change

- (void)changeFrameToFitMaxSize
{
    //meassure text with max size minus text insets
    UIEdgeInsets contentInsets = [self contentInsets];
    CGRect contentRect = [self contentRect];
    CGFloat maxWidth = self.maxSize.width - contentInsets.left - contentInsets.right;
    CGRect textRect = [self textRectForWidth:maxWidth];
    
    BOOL growInWidth = textRect.size.width > contentRect.size.width;
    BOOL growInHeight = textRect.size.height > contentRect.size.height;
    
    if (growInWidth)
    {
        [self growToWidth:textRect.size.width];
    }
    
    if (growInHeight)
    {
        CGFloat maxHeight = self.maxSize.height - contentInsets.top - contentInsets.bottom;
        [self growToHeight:MIN(textRect.size.height, maxHeight)];
    }
}

- (void)growToWidth:(CGFloat)newWidth
{
    newWidth += self.contentInsets.left + self.contentInsets.right;
    NSTextAlignment alignment = [self labelTextAlignment];
    
    if (alignment == NSTextAlignmentCenter)
    {
        CGRect bounds = self.bounds;
        bounds.size.width = newWidth;
        self.bounds = bounds;
    }
    else if (alignment == NSTextAlignmentLeft)
    {
        CGRect bounds = self.bounds;
        bounds.size.width = newWidth + self.contentInsets.left;
        CGPoint origin = self.frame.origin;
        self.bounds = bounds;
        CGRect frame = self.frame;
        frame.origin = origin;
        self.frame = frame;
    }
    else if (alignment == NSTextAlignmentRight)
    {
        //TODO: fix to don't alter frame
        self.frame = CGRectMake(floor(CGRectGetMaxX(self.frame) - newWidth), self.frame.origin.y, ceil(newWidth), self.frame.size.height);
    }
}

- (void)growToHeight:(CGFloat)newHeight
{
    newHeight += self.contentInsets.top + self.contentInsets.bottom;
    
    CGRect frame = self.frame;
    frame.size.height = ceil(newHeight);
    self.frame = frame;
}

#pragma mark Read text attributes

- (id)textAttribute:(NSString *)textAttribute
{
    __block id att;
    [self.attributedText enumerateAttribute:textAttribute
                                    inRange:[self textRange]
                                    options:(NSAttributedStringEnumerationOptions)0
                                 usingBlock:^(id attr, NSRange range, BOOL *stop) {
                                     att = attr;
                                     *stop = YES;
                                 }];
    return att;
}

- (NSTextAlignment)labelTextAlignment
{
    NSTextAlignment alignment = NSTextAlignmentLeft;
    NSParagraphStyle *ps = [self textAttribute:NSParagraphStyleAttributeName];
    if (ps)
    {
        alignment = ps.alignment;
    }
    return alignment;
}

#pragma mark - Coding

-(void)encodeWithCoder:(nonnull NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.attributedText forKey:NSStringFromSelector(@selector(attributedText))];
    [aCoder encodeObject:self.strokeWidths forKey:NSStringFromSelector(@selector(strokeWidths))];
    [aCoder encodeObject:self.strokeColors forKey:NSStringFromSelector(@selector(strokeColors))];
    [aCoder encodeFloat:self.minimumScaleFactor forKey:NSStringFromSelector(@selector(minimumScaleFactor))];
    [aCoder encodeCGSize:self.maxSize forKey:NSStringFromSelector(@selector(maxSize))];
    [aCoder encodeObject:self.gradientColors forKey:NSStringFromSelector(@selector(gradientColors))];
    [aCoder encodeCGPoint:self.gradientStartPoint forKey:NSStringFromSelector(@selector(gradientStartPoint))];
    [aCoder encodeCGPoint:self.gradientEndPoint forKey:NSStringFromSelector(@selector(gradientEndPoint))];
    [aCoder encodeObject:self.innerShadows forKey:NSStringFromSelector(@selector(innerShadows))];
    [aCoder encodeObject:self.innerShadowBlendModes forKey:NSStringFromSelector(@selector(innerShadowBlendModes))];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self initialize];
        NSAttributedString* as = [aDecoder decodeObjectOfClass:NSAttributedString.class forKey:NSStringFromSelector(@selector(attributedText))];
        NSArray* strokeWidths = [aDecoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(strokeWidths))];
        NSArray* strokeColors = [aDecoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(strokeColors))];
        CGFloat minScale = [aDecoder decodeFloatForKey:NSStringFromSelector(@selector(minimumScaleFactor))];
        CGSize maxSize = [aDecoder decodeCGSizeForKey:NSStringFromSelector(@selector(maxSize))];
        NSArray* gradientColors = [aDecoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(gradientColors))];
        NSArray* innerShadows = [aDecoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(innerShadows))];
        NSArray* innerShadowBlendModes = [aDecoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(innerShadowBlendModes))];
        CGPoint gradientStart = [aDecoder decodeCGPointForKey:NSStringFromSelector(@selector(gradientStartPoint))];
        CGPoint gradientEnd = [aDecoder decodeCGPointForKey:NSStringFromSelector(@selector(gradientEndPoint))];
        self.maxSize = maxSize;
        self.minimumScaleFactor = minScale;
        self.strokeWidths = strokeWidths;
        self.strokeColors = strokeColors;
        self.gradientColors = gradientColors;
        self.gradientStartPoint = gradientStart;
        self.gradientEndPoint = gradientEnd;
        self.innerShadows = innerShadows;
        self.innerShadowBlendModes = innerShadowBlendModes;
        self.attributedText = as;
    }
    
    return self;
}

#pragma mark - Copy

- (id)copyWithZone:(NSZone *)zone
{
    LTMLabel *copyLabel = [[LTMLabel alloc] initWithFrame:self.bounds];
    //view attributes
    copyLabel.alpha = self.alpha;
    copyLabel.transform = self.transform;
    copyLabel.userInteractionEnabled = self.userInteractionEnabled;
    copyLabel.hidden = self.hidden;
    //layer attributes
    copyLabel.layer.shadowColor = self.layer.shadowColor;
    copyLabel.layer.shadowOffset = self.layer.shadowOffset;
    copyLabel.layer.shadowRadius = self.layer.shadowRadius;
    copyLabel.layer.shadowOpacity = self.layer.shadowOpacity;
    copyLabel.layer.shouldRasterize = self.layer.shouldRasterize;
    copyLabel.layer.zPosition = self.layer.zPosition;
    copyLabel.layer.anchorPoint = self.layer.anchorPoint;
    //label attributes
    copyLabel.frame = self.frame;
    copyLabel.strokeColor = self.strokeColor;
    copyLabel.strokeWidth = self.strokeWidth;
    copyLabel.minimumScaleFactor = self.minimumScaleFactor;
    copyLabel.attributedText = self.attributedText;
    return copyLabel;
}

@end

@implementation LTMLabel (Convenient)

-(void)setStrokeWidth:(CGFloat)strokeWidth
{
    if(strokeWidth == 0)
    {
        self.strokeWidths = nil;
    }
    else
    {
        self.strokeWidths = @[@(strokeWidth)];
    }
}

-(CGFloat)strokeWidth
{
    return ((NSNumber *)[self.strokeWidths firstObject]).floatValue;
}

-(void)setStrokeColor:(UIColor *)strokeColor
{
    if(!strokeColor)
    {
        self.strokeColors = nil;
    }
    else
    {
        self.strokeColors = @[strokeColor];
    }
}

-(UIColor *)strokeColor
{
    return [self.strokeColors firstObject];
}

-(UIColor *)gradientStartColor
{
    return [self.gradientColors firstObject];
}

-(void)setGradientStartColor:(UIColor *)gradientStartColor
{
    if(gradientStartColor)
    {
        NSMutableArray* c = [NSMutableArray arrayWithArray:self.gradientColors];
        if(c.count > 0)
        {
            [c insertObject:gradientStartColor atIndex:0];
        }
        else
        {
            [c addObject:gradientStartColor];
        }
        self.gradientColors = [c copy];
    }
    else
    {
        self.gradientColors = nil;
    }
}

-(UIColor *)gradientEndColor
{
    return [self.gradientColors lastObject];
}

-(void)setGradientEndColor:(UIColor *)gradientEndColor
{
    if(gradientEndColor)
    {
        NSMutableArray* c = [NSMutableArray arrayWithArray:self.gradientColors];
        if(c.count > 0)
        {
            [c insertObject:gradientEndColor atIndex:c.count];
        }
        else
        {
            [c addObject:gradientEndColor];
        }
        self.gradientColors = [c copy];
    }
    else
    {
        self.gradientColors = nil;
    }
}

-(NSShadow *)innerShadow
{
    return [self.innerShadows firstObject];
}

-(void)setInnerShadow:(NSShadow *)innerShadow
{
    if(innerShadow)
    {
        self.innerShadows = @[innerShadow];
    }
    else
    {
        self.innerShadows = nil;
    }
}

-(CGBlendMode)innerShadowBlendMode
{
    return (CGBlendMode)((NSNumber *)[self.innerShadowBlendModes firstObject]).integerValue;
}

-(void)setInnerShadowBlendMode:(CGBlendMode)innerShadowBlendMode
{
    self.innerShadowBlendModes = @[@(innerShadowBlendMode)];
}

@end

@implementation LTMLabel (UILabelCompatibility)

-(NSString *)text
{
    return _text;
}

-(void)setText:(NSString *)text
{
    _text = text;
    [self checkCompatibility];
}

-(UIFont *)font
{
    return _font;
}

-(void)setFont:(UIFont *)font
{
    _font = font;
    [self checkCompatibility];
}

-(NSTextAlignment)textAlignment
{
    return _textAlignment;
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment
{
    _textAlignment = textAlignment;
    [self checkCompatibility];
}

-(UIColor *)textColor
{
    return _textColor;
}

-(void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    [self checkCompatibility];
}

-(void)checkCompatibility
{
    if(self.text)
    {
        self.attributedText = [NSAttributedString ltm_attributedString:self.text
                                                              textFont:self.font
                                                             textColor:self.textColor
                                                             alignment:self.textAlignment];
    }
}

@end

@implementation NSAttributedString (LTMFactory)

+ (instancetype)ltm_attributedString:(NSString *)string
                            textFont:(UIFont *)font
                           textColor:(UIColor *)textColor
                           alignment:(NSTextAlignment)alignment
{
    if(!string)
    {
        return nil;
    }
    
    NSMutableParagraphStyle *ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    ps.alignment = alignment;
    
    if (!font)
    {
        font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    if (!textColor)
    {
        textColor = [UIColor blackColor];
    }
    
    return [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName : font,
                                                                          NSForegroundColorAttributeName : textColor,
                                                                          NSParagraphStyleAttributeName : ps}];
}

+ (instancetype)ltm_attributedString:(NSString *)string
                            textFont:(UIFont *)font
                           textColor:(UIColor *)textColor
{
    return [self ltm_attributedString:string textFont:font textColor:textColor alignment:NSTextAlignmentLeft];
}

+ (instancetype)ltm_attributedString:(NSString *)string
                            textFont:(UIFont *)font
{
    return [self ltm_attributedString:string textFont:font textColor:nil alignment:NSTextAlignmentLeft];
}

+ (instancetype)ltm_attributedString:(NSString *)string
{
    return [self ltm_attributedString:string textFont:nil textColor:nil alignment:NSTextAlignmentLeft];
}

@end

@implementation NSAttributedString (LTMHelper)

-(instancetype)ltm_attributedStringWithForegroundColor:(UIColor *)color
{
    if(!color) return self;
    
    NSMutableAttributedString* mas = [self mutableCopy];
    [mas addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, mas.length)];
    return mas;
}

@end
