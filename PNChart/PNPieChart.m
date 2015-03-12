//
//  PNPieChart.m
//  PNChartDemo
//
//  Created by Hang Zhang on 14-5-5.
//  Copyright (c) 2014年 kevinzhow. All rights reserved.
//

#import "PNPieChart.h"

#define SELECTION_OFFSET 10

@interface PNPieChart ()

@property (nonatomic) CGFloat total;
@property (nonatomic) CGFloat currentTotal;

@property (nonatomic) CGFloat outerCircleRadius;
@property (nonatomic) CGFloat innerCircleRadius;

@property (nonatomic) UIView* contentView;
@property (nonatomic) CAShapeLayer* pieLayer;
@property (nonatomic) NSMutableArray* descriptionLabels;

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

        _descriptionTextColor = [UIColor blackColor];
        _descriptionTextFont = [UIFont fontWithName:@"Helvetica" size:14];
        _descriptionTextShadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        _descriptionTextShadowOffset = CGSizeMake(0, 1);
        _duration = 1.0;
        self.selectedIndex = -1;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame items:(NSArray*)items
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _items = [NSArray arrayWithArray:items];

        _descriptionTextColor = [UIColor whiteColor];
        _descriptionTextFont = [UIFont fontWithName:@"Helvetica" size:14];
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
    if (_chartType == PNPieChartTypeDonut)
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
    
    if (_total == 0)
    {
        return;
    }

    switch (_labelPosition)
    {
        case PNPieChartLabelPositionOuter:
            _outerCircleRadius -= [_descriptionTextFont pointSize];
            break;

        default:
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

        float radius = _innerCircleRadius + (_outerCircleRadius - _innerCircleRadius) / 2;
        float barderWidth = abs(_outerCircleRadius - _innerCircleRadius);

        CAShapeLayer* currentPieLayer = [self newCircleLayerWithRadius:radius
                                                           borderWidth:barderWidth
                                                             fillColor:[UIColor clearColor]
                                                           borderColor:currentItem.color
                                                       startPercentage:startPercnetage
                                                         endPercentage:endPercentage
                                                                 index:i];
        [_pieLayer addSublayer:currentPieLayer];

        _currentTotal += currentItem.value;
        [_pieLayer addSublayer:currentPieLayer];

        currentValue += currentItem.value;
    }

    if (self.labelPosition != PNPieChartLabelPositionNone)
    {
        currentValue = 0;
        _currentTotal = 0;
        for (int i = 0; i < _items.count; i++)
        {
            currentItem = [self dataItemForIndex:i];
            UILabel* descriptionLabel = [self descriptionLabelForItemAtIndex:i];
            [_contentView addSubview:descriptionLabel];
            currentValue += currentItem.value;
            [_descriptionLabels addObject:descriptionLabel];
            // descriptionLabel.backgroundColor = [UIColor purpleColor];
        }
    }

    if (animated)
        [self maskChart];
}

- (UILabel*)descriptionLabelForItemAtIndex:(NSUInteger)index
{
    PNPieChartDataItem* currentDataItem = [self dataItemForIndex:index];

    NSString* titleText = currentDataItem.textDescription;

    CGFloat distance = 0.0f;
    CGFloat centerPercentage = (_currentTotal + currentDataItem.value / 2) / _total;
    CGFloat rad = centerPercentage * 2 * M_PI;
    CGPoint chartCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    int (^signum)(CGFloat n) = ^(CGFloat n) {
        return (n < 0) ? -1 : (n > 0) ? +1 : 0;
    };

    _currentTotal += currentDataItem.value;

    CGSize labelSize = [titleText sizeWithAttributes:@{ NSFontAttributeName : _descriptionTextFont }];

    CGFloat offset = MIN((index == self.selectedIndex ? SELECTION_OFFSET : 0), MAX((_outerCircleRadius / 10), 1));
    CGPoint center = CGPointZero;

    switch (_labelPosition)
    {
        case PNPieChartLabelPositionOuter:
            distance = _outerCircleRadius;
            center = CGPointMake(
                chartCenter.x + (distance + offset) * sin(rad), chartCenter.y - (distance + offset) * cos(rad));
            center.x += (labelSize.width / 2) * signum(sin(rad));
            center.y -= (labelSize.height / 2) * signum(cos(rad));
            break;

        default:
            if (_chartType == PNPieChartTypeDonut)
            {
                distance = _innerCircleRadius + (_outerCircleRadius - _innerCircleRadius) / 2;
            }
            else
            {
                distance = _outerCircleRadius - (_outerCircleRadius / 3);
            }
            center = CGPointMake(
                chartCenter.x + (distance + offset) * sin(rad), chartCenter.y - (distance + offset) * cos(rad));
            break;
    }

    UILabel* descriptionLabel = [[UILabel alloc]
        initWithFrame:CGRectIntegral(CGRectMake(center.x, center.y, labelSize.width, labelSize.height))];
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.textColor = _descriptionTextColor;
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    descriptionLabel.alpha = 1;
    descriptionLabel.backgroundColor = [UIColor clearColor];
    descriptionLabel.text = titleText;
    descriptionLabel.font = _descriptionTextFont;
    descriptionLabel.center = center;
    descriptionLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    [descriptionLabel sizeToFit];

    descriptionLabel.frame = CGRectIntegral(descriptionLabel.frame);

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
        distance += MIN(SELECTION_OFFSET, MAX((_outerCircleRadius / 10), 1));
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

- (void)maskChart
{

    [_pieLayer.sublayers enumerateObjectsUsingBlock:^(CAShapeLayer* obj, NSUInteger idx, BOOL* stop) {

        CGFloat end = obj.strokeEnd;

        obj.strokeEnd = 0;

        [self createArcAnimationForLayer:obj
                                  ForKey:@"strokeEnd"
                               fromValue:@(obj.strokeStart)
                                 toValue:@(end)
                                Delegate:self];

    }];

    [_descriptionLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        [obj setAlpha:0];
    }];
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
    [arcAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [arcAnimation setDuration:0.3];
    [layer addAnimation:arcAnimation forKey:key];
    [layer setValue:to forKey:key];
}

- (void)animationDidStop:(CAAnimation*)anim finished:(BOOL)flag
{
    NSNumber* tappedIndex = [anim valueForKey:@"tappedIndex"];
    if (tappedIndex)
    {
        [self.delegate userClickedOnPieSliceAtIndex:[tappedIndex intValue]];
    }
    else
    {
        [_descriptionLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
            [UIView animateWithDuration:0.3
                             animations:^() {
                                 [obj setAlpha:1];
                             }];
        }];
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    if (event.type != UIEventTypeTouches && [self.delegate respondsToSelector:@selector(userClickedOnPieSliceAtIndex:)])
        return;

    CGPoint location = [[touches anyObject] locationInView:_contentView];
    CGPoint chartCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat pointRad = (2 * M_PI) - (atan2f(location.x - chartCenter.x, location.y - chartCenter.y) + M_PI);

    bool insideCircle = powf(location.x - chartCenter.x, 2) + powf(location.y - chartCenter.y, 2)
        <= powf(_outerCircleRadius, 2);

    if (!insideCircle)
        return;

    __block float currentValue = 0;
    __block NSUInteger clickeIndex = -1;

    [self.items enumerateObjectsUsingBlock:^(PNPieChartDataItem* obj, NSUInteger idx, BOOL* stop) {
        CGFloat startRad = ((currentValue / _total) * 2 * M_PI);
        CGFloat endRad = (((currentValue + obj.value) / _total) * 2 * M_PI);

        if (pointRad >= startRad && pointRad <= endRad)
        {
            *stop = true;
            clickeIndex = idx;
        }

        currentValue += obj.value;

    }];

    if (clickeIndex != -1)
    {
        [self animateTappedLayer:clickeIndex];
    }
}

- (void)animateTappedLayer:(NSUInteger)index
{
    CAShapeLayer* tappedLayer = [[_pieLayer sublayers] objectAtIndex:index];
    UIColor* newColor = [UIColor colorWithCGColor:tappedLayer.strokeColor];

    float hue, sat, brigth, alpha;

    [newColor getHue:&hue saturation:&sat brightness:&brigth alpha:&alpha];
    newColor = [UIColor colorWithHue:hue saturation:sat brightness:fminf(brigth + 0.10, 0.95) alpha:alpha];

    CABasicAnimation* fillColorAnimation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
    fillColorAnimation.duration = 0.08f;
    fillColorAnimation.fromValue = (id)tappedLayer.strokeColor;
    fillColorAnimation.toValue = (id)[newColor CGColor];
    fillColorAnimation.repeatCount = 1;
    fillColorAnimation.autoreverses = YES;
    fillColorAnimation.delegate = self;
    fillColorAnimation.removedOnCompletion = YES;
    [fillColorAnimation setValue:@(index) forKey:@"tappedIndex"];

    [tappedLayer addAnimation:fillColorAnimation forKey:@"strokeColor"];
}

@end
