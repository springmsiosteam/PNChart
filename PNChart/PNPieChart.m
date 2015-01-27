//
//  PNPieChart.m
//  PNChartDemo
//
//  Created by Hang Zhang on 14-5-5.
//  Copyright (c) 2014年 kevinzhow. All rights reserved.
//

#import "PNPieChart.h"

@interface PNPieChart ()

@property (nonatomic) CGFloat total;
@property (nonatomic) CGFloat currentTotal;

@property (nonatomic) CGFloat outerCircleRadius;
@property (nonatomic) CGFloat innerCircleRadius;

@property (nonatomic) UIView* contentView;
@property (nonatomic) CAShapeLayer* pieLayer;
@property (nonatomic) NSMutableArray* descriptionLabels;

- (void)loadDefault;

- (UILabel*)descriptionLabelForItemAtIndex:(NSUInteger)index;
- (PNPieChartDataItem*)dataItemForIndex:(NSUInteger)index;

- (CAShapeLayer*)newCircleLayerWithRadius:(CGFloat)radius
                              borderWidth:(CGFloat)borderWidth
                                fillColor:(UIColor*)fillColor
                              borderColor:(UIColor*)borderColor
                          startPercentage:(CGFloat)startPercentage
                            endPercentage:(CGFloat)endPercentage
                                    index:(NSUInteger)index;

@end

@implementation PNPieChart

- (id)init
{
    self = [super init];
    if (self)
    {
        _items = [NSArray array];

        _descriptionTextColor = [UIColor whiteColor];
        _descriptionTextFont = [UIFont fontWithName:@"Avenir-Medium" size:18.0];
        _descriptionTextShadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        _descriptionTextShadowOffset = CGSizeMake(0, 1);
        _duration = 1.0;
        self.selectedIndex = -1;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame items:(NSArray*)items
{
    self = [self initWithFrame:frame];
    if (self)
    {
        _items = [NSArray arrayWithArray:items];

        _descriptionTextColor = [UIColor whiteColor];
        _descriptionTextFont = [UIFont fontWithName:@"Avenir-Medium" size:18.0];
        _descriptionTextShadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        _descriptionTextShadowOffset = CGSizeMake(0, 1);
        _duration = 1.0;
    }

    return self;
}

- (void)loadDefault
{
    _currentTotal = 0;
    _total = 0;

    _outerCircleRadius = MIN(self.bounds.size.height, self.bounds.size.width) / 2;

    _innerCircleRadius = 0;
    if (_chartType)
    {
        _innerCircleRadius = (_outerCircleRadius / 2);
    }

    [_contentView removeFromSuperview];
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:_contentView];
    [_descriptionLabels removeAllObjects];
    _descriptionLabels = [NSMutableArray new];

    _pieLayer = [CAShapeLayer layer];
    [_contentView.layer addSublayer:_pieLayer];
}

#pragma mark -

- (void)strokeChart:(BOOL)animated
{
    [self loadDefault];

    [self.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        _total += ((PNPieChartDataItem*)obj).value;
    }];

    switch (_labelPosition)
    {
        case PNPieChartLabelPositionOuter:
            _outerCircleRadius -= [_descriptionTextFont pointSize] + 20;
            break;

        default:
            // _outerCircleRadius = _outerCircleRadius;
            break;
    }

    PNPieChartDataItem* currentItem;
    CGFloat currentValue = 0;
    _currentTotal = 0;

    for (int i = 0; i < _items.count; i++)
    {
        currentItem = [self dataItemForIndex:i];

        CGFloat startPercnetage = currentValue / _total;
        CGFloat endPercentage = (currentValue + currentItem.value) / _total;

        CAShapeLayer* currentPieLayer =
            [self newCircleLayerWithRadius:_innerCircleRadius + (_outerCircleRadius - _innerCircleRadius) / 2
                               borderWidth:_outerCircleRadius - _innerCircleRadius
                                 fillColor:[UIColor clearColor]
                               borderColor:currentItem.color
                           startPercentage:startPercnetage
                             endPercentage:endPercentage
                                     index:i];
        [_pieLayer addSublayer:currentPieLayer];

        if (i == self.selectedIndex)
        {
            CAShapeLayer* shadown =
                [self shadowCircleLayerWithRadius:_innerCircleRadius + (_outerCircleRadius - _innerCircleRadius) / 2
                                      borderWidth:_outerCircleRadius - _innerCircleRadius
                                        fillColor:[UIColor clearColor]
                                      borderColor:currentItem.color
                                  startPercentage:startPercnetage
                                    endPercentage:endPercentage
                                            index:i];
            [_pieLayer addSublayer:shadown];
        }

        _currentTotal += currentItem.value;
        [_pieLayer addSublayer:currentPieLayer];

        currentValue += currentItem.value;
    }

    currentValue = 0;
    _currentTotal = 0;
    for (int i = 0; i < _items.count; i++)
    {
        currentItem = [self dataItemForIndex:i];
        UILabel* descriptionLabel = [self descriptionLabelForItemAtIndex:i];
        [_contentView addSubview:descriptionLabel];
        currentValue += currentItem.value;
        [_descriptionLabels addObject:descriptionLabel];
    }
}

- (UILabel*)descriptionLabelForItemAtIndex:(NSUInteger)index
{
    PNPieChartDataItem* currentDataItem = [self dataItemForIndex:index];

    NSString* titleText = currentDataItem.textDescription;

    CGFloat distance = 0.0f;
    CGFloat centerPercentage = (_currentTotal + currentDataItem.value / 2) / _total;
    CGFloat rad = centerPercentage * 2 * M_PI;
    CGPoint chartCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    _currentTotal += currentDataItem.value;

    if (!titleText)
    {
        titleText = [NSString stringWithFormat:@"%.0f%%", currentDataItem.value / _total * 100];
    }

    CGSize labelSize = [titleText sizeWithAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:14] }];

    switch (_labelPosition)
    {
        case PNPieChartLabelPositionOuter:
            distance = _outerCircleRadius + (labelSize.width / 2) + 5 + (index == self.selectedIndex ? 15 : 0);
            break;

        default:
            if (_chartType == PNPieChartTypeDonut)
            {
                distance = (index == self.selectedIndex ? 15 : 0) + _innerCircleRadius
                           + (_outerCircleRadius - _innerCircleRadius) / 2;
            }
            else
            {
                distance = (index == self.selectedIndex ? 15 : 0) + _outerCircleRadius - (_outerCircleRadius / 5);
            }

            break;
    }

    CGPoint center = CGPointMake(chartCenter.x + distance * sin(rad), chartCenter.y - distance * cos(rad));
    UILabel* descriptionLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(center.x, center.y, labelSize.width, labelSize.height)];
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.textColor = _descriptionTextColor;
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    descriptionLabel.alpha = 1;
    descriptionLabel.backgroundColor = [UIColor clearColor];
    descriptionLabel.text = titleText;
    descriptionLabel.font = [UIFont systemFontOfSize:14];
    descriptionLabel.center = center;
    return descriptionLabel;
}

- (PNPieChartDataItem*)dataItemForIndex:(NSUInteger)index
{
    return self.items[index];
}

#pragma mark private methods

- (CAShapeLayer*)newCircleLayerWithRadius:(CGFloat)radius
                              borderWidth:(CGFloat)borderWidth
                                fillColor:(UIColor*)fillColor
                              borderColor:(UIColor*)borderColor
                          startPercentage:(CGFloat)startPercentage
                            endPercentage:(CGFloat)endPercentage
                                    index:(NSUInteger)index
{
    CAShapeLayer* circle = [CAShapeLayer layer];

    PNPieChartDataItem* currentDataItem = [self dataItemForIndex:index];

    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    CGFloat distance = 0;
    if (index == self.selectedIndex)
    {
        distance += 10.0f;
    }

    CGFloat centerPercentage = (_currentTotal + currentDataItem.value / 2) / _total;
    CGFloat rad = centerPercentage * 2 * M_PI;
    CGPoint newCenter = CGPointMake(center.x + distance * sin(rad), center.y - distance * cos(rad));

    UIBezierPath* path = [UIBezierPath bezierPathWithArcCenter:newCenter
                                                        radius:radius
                                                    startAngle:-M_PI_2
                                                      endAngle:M_PI_2 * 3
                                                     clockwise:YES];

    circle.fillColor = fillColor.CGColor;
    circle.strokeColor = borderColor.CGColor;
    circle.strokeStart = startPercentage;
    circle.strokeEnd = endPercentage;
    circle.lineWidth = borderWidth;
    circle.path = path.CGPath;
    return circle;
}

- (CAShapeLayer*)shadowCircleLayerWithRadius:(CGFloat)radius
                                 borderWidth:(CGFloat)borderWidth
                                   fillColor:(UIColor*)fillColor
                                 borderColor:(UIColor*)borderColor
                             startPercentage:(CGFloat)startPercentage
                               endPercentage:(CGFloat)endPercentage
                                       index:(NSUInteger)index
{
    CAShapeLayer* circle = [CAShapeLayer layer];

    PNPieChartDataItem* currentDataItem = [self dataItemForIndex:index];

    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    CGFloat distance = 15.0f;
    CGFloat centerPercentage = (_currentTotal + currentDataItem.value / 2) / _total;
    CGFloat rad = centerPercentage * 2 * M_PI;
    CGPoint newCenter = CGPointMake(center.x + distance * sin(rad), center.y - distance * cos(rad));

    UIBezierPath* path = [UIBezierPath bezierPathWithArcCenter:newCenter
                                                        radius:radius
                                                    startAngle:-M_PI_2
                                                      endAngle:M_PI_2 * 3
                                                     clockwise:YES];

    circle.fillColor = fillColor.CGColor;
    circle.strokeColor = [UIColor darkGrayColor].CGColor;
    circle.strokeStart = startPercentage;
    circle.strokeEnd = endPercentage;
    circle.lineWidth = borderWidth + 3;
    circle.opacity = 0.1;

    circle.path = path.CGPath;

    CIFilter* blur = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blur setDefaults];
    [blur setValue:[NSNumber numberWithFloat:10.0] forKey:@"inputRadius"];
    circle.backgroundFilters = [NSArray arrayWithObject:blur];

    return circle;
}

- (void)maskChart
{
    CAShapeLayer* maskLayer =
        [self newCircleLayerWithRadius:_innerCircleRadius + (_outerCircleRadius - _innerCircleRadius) / 2
                           borderWidth:_outerCircleRadius - _innerCircleRadius
                             fillColor:[UIColor clearColor]
                           borderColor:[UIColor blackColor]
                       startPercentage:0
                         endPercentage:1
                                 index:0];

    _pieLayer.mask = maskLayer;
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = _duration;
    animation.fromValue = @0;
    animation.toValue = @1;
    animation.delegate = self;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.removedOnCompletion = YES;
    [maskLayer addAnimation:animation forKey:@"circleAnimation"];
}

- (void)createArcAnimationForLayer:(CAShapeLayer*)layer
                            ForKey:(NSString*)key
                         fromValue:(NSNumber*)from
                           toValue:(NSNumber*)to
                          Delegate:(id)delegate
{
    CABasicAnimation* arcAnimation = [CABasicAnimation animationWithKeyPath:key];
    arcAnimation.fromValue = @0;
    [arcAnimation setToValue:to];
    [arcAnimation setDelegate:delegate];
    [arcAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
    [layer addAnimation:arcAnimation forKey:key];
    [layer setValue:to forKey:key];
}

- (void)animationDidStop:(CAAnimation*)anim finished:(BOOL)flag
{
    [_descriptionLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        [UIView animateWithDuration:0.2 animations:^() { [obj setAlpha:1]; }];
    }];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    if (event.type != UIEventTypeTouches)
        return;

    CGPoint location = [[touches anyObject] locationInView:_contentView];
    self.selectedIndex++;
    if (self.selectedIndex > _items.count)
        self.selectedIndex = 0;

    [self strokeChart:NO];

    [_pieLayer.sublayers enumerateObjectsUsingBlock:^(CAShapeLayer* obj, NSUInteger idx, BOOL* stop) {

        CGPoint pl = [_contentView.layer convertPoint:location toLayer:obj];

        if (CGPathContainsPoint(obj.path, 0, pl, YES))
        {
        }

    }];
}

@end
