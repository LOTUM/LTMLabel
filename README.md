# LTMLabel
----
A label which is capable to draw attributed strings and add outer strokes, inner shadows and gradients to it. All attributed string properties are supported - like NSTextAttachments, NSParagraphStyles, ...

## Usage
You are encouraged to set the `attributedString`property of the label. But there are also convenient setter for the UILabel default properties like `text`, `textColor`, `textAlignment`and `font`.

```objective-c
LTMLabel* label = [[LTMLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
label.attributedString = [[NSAttributedString alloc] initWithString:@"Test text to draw"];
```

###Add stroke

To add a single stroke:
```objective-c
label.strokeColor = [UIColor blackColor];
label.strokeWidth = 4;
```

To add multiple strokes:
```objective-c
label.strokeColors = @[[UIColor whiteColor], [UIColor blackColor]];
label.strokeWidths = @[@3, @6];
```
Notice that stroke width is the overall width and not added. So the white stroke will have a width of 3 and the black a width of 6 but 3 of this 6 will be overlaid by the white one.

###Add inner shadow
To add a single inner shadow you set a NSShadow object to the `innerShadow` property:
```objective-c
NSShadow* shadow = [[NSShadow alloc] init];
shadow.shadowColor = [UIColor whiteColor];
shadow.shadowOffset = CGSizeMake(0, 2);
shadow.shadowBlurRadius = 0;
label.innerShadow = shadow;
```

To add multiple inner shadows add multiple shadow objects to the `innerShadows`array.

#####Inner shadow blend modes
You have the possibility to alter the inner shadow blend mode with the property `innerShadowBlendMode` or `innerShadowBlendModes`

```objective-c
label.innerShadowBlendMode = kCGBlendModeDarken;
```
```objective-c
label.innerShadowBlendModes = @[@(kCGBlendModeDarken), @(kCGBlendModeOverlay)];
```

###Add gradient

You can set the gradient start and end point and the different colors. Default is a linear gradient from top to bottom:
```objective-c
label.gradientStartColor = [UIColor yellowColor];
label.gradientEndColor = [UIColor orangeColor];
```
Or set multiple colors:
```objective-c
label.gradientColors = @[[UIColor yellowColor], [UIColor orangeColor], [UIColor redColor]];
```
To change the start or end point set `gradientStartPoint` and `gradientEndPoint`. The values are in range 0-1. To set a gradient from left to right do the following:
```objective-c
label.gradientStartPoint = CGPointMake(0, 0.5);
label.gradientEndPoint = CGPointMake(1, 0.5);
```

###Font scaling
With setting the `minimumScaleFactor` property to a value smaller than 1 you achieve a font scaling in case the label's text doesn't fit in its frame.

###Frame resizing
In case you want your label to grow in height or width depended on its content text length you set the `maxSize` property. This defines the maximum size to which the label is allowed to grow. With setting the attributed string the new label size is calculated so that you can access its new size immediately and perform further positioning with the label in its new size.

To create a label which grows in height and scales down its text:
```objective-c
LTMLabel* growAndScaleLabel = [[LTMLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
growAndScaleLabel.minimumScaleFactor = 0.75;
growAndScaleLabel.maxSize = CGSizeMake(CGRectGetWidth(growAndScaleLabel.bounds), 150);
```

##Credits
Original source and inspiration from:

* [THLabel by Tobias Hagemann](https://github.com/MuscleRumble/THLabel)

##Contact

* [http://www.lotum.de](http://www.lotum.de)
* [github@lotum.de](github [at] lotum.de)