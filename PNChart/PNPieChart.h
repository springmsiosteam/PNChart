//
//  PNPieChart.h
//  PNChartDemo
//
//  Created by Hang Zhang on 14-5-5.
//  Copyright (c) 2014年 kevinzhow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PNPieChartDataItem.h"
#import "PNChartDelegate.h"

typedef enum
{
    PNPieChartLabelPositionNone = 0,
    PNPieChartLabelPositionOuter = 1,
    PNPieChartLabelPositionInner = 2
} PNPieChartLabelPosition;

typedef enum
{
    PNPieChartTypePie = 0,
    PNPieChartTypeDonut = 1
} PNPieChartType;

@interface PNPieChart : UIControl

- (id)initWithFrame:(CGRect)frame items:(NSArray*)items;

@property (nonatomic, strong) NSArray* items;

/** Default is 18-point Avenir Medium. */
@property (nonatomic) UIFont* descriptionTextFont;

/** Default is white. */
@property (nonatomic) UIColor* descriptionTextColor;

/** Default is black, with an alpha of 0.4. */
@property (nonatomic) UIColor* descriptionTextShadowColor;

/** Default is CGSizeMake(0, 1). */
@property (nonatomic) CGSize descriptionTextShadowOffset;

/** Default is 1.0. */
@property (nonatomic) NSTimeInterval duration;

/** Default is PNPieChartLabelPositionInner */
@property (nonatomic) PNPieChartLabelPosition labelPosition;

/** Default is PNPieChartTypePie */
@property (nonatomic) PNPieChartType chartType;

- (void)strokeChart:(BOOL)animated;

@property (nonatomic, assign) NSUInteger selectedIndex;

@property (nonatomic, retain) id<PNChartDelegate> delegate;

@end
