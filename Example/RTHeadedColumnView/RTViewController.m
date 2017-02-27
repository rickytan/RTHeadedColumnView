//
//  RTViewController.m
//  RTHeadedColumnView
//
//  Created by rickytan on 10/19/2016.
//  Copyright (c) 2016 rickytan. All rights reserved.
//

#import "RTViewController.h"

#import "RTDemoTableView.h"

#import <RTHeadedColumnView/RTHeadedColumnView.h>

@interface RTViewController () <RTHeadedColumnViewDelegate>
@property (nonatomic, strong) RTHeadedColumnView *columnView;
@end

@implementation RTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 200)];
    headerView.backgroundColor = [UIColor colorWithWhite:1.f * 0x99 / 0xff
                                                   alpha:1.f];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"github"]];

    UILabel *bottomView = [[UILabel alloc] init];
    bottomView.font = [UIFont systemFontOfSize:30];
    bottomView.textColor = [UIColor whiteColor];
    bottomView.text = @"A Common Title";
    bottomView.backgroundColor = [UIColor orangeColor];

    CGRect slice, remainder;
    CGRectDivide(headerView.bounds, &slice, &remainder, 44.f, CGRectMaxYEdge);
    bottomView.frame = slice;
    imageView.frame = remainder;

    [headerView addSubview:bottomView];
    [headerView addSubview:imageView];


    self.columnView = [[RTHeadedColumnView alloc] initWithFrame:self.view.bounds];
    self.columnView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.columnView];

    self.columnView.headerView = headerView;
    self.columnView.headerPinHeight = 44.f;
    self.columnView.contentColumns = @[[RTDemoTableView new], [RTHeaderDemoTableView new], [RTDemoTableView new]];
}

@end

@interface RTCollectionsViewController ()
@property (nonatomic, strong) RTHeadedColumnView *columnView;
@end

@implementation RTCollectionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 200)];
    headerView.backgroundColor = [UIColor colorWithWhite:1.f * 0x99 / 0xff
                                                   alpha:1.f];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"github"]];

    UILabel *bottomView = [[UILabel alloc] init];
    bottomView.font = [UIFont systemFontOfSize:30];
    bottomView.textColor = [UIColor whiteColor];
    bottomView.text = @"A Common Title";
    bottomView.backgroundColor = [UIColor orangeColor];

    CGRect slice, remainder;
    CGRectDivide(headerView.bounds, &slice, &remainder, 44.f, CGRectMaxYEdge);
    bottomView.frame = slice;
    imageView.frame = remainder;

    [headerView addSubview:bottomView];
    [headerView addSubview:imageView];


    self.columnView = [[RTHeadedColumnView alloc] initWithFrame:self.view.bounds];
    self.columnView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.columnView];

    self.columnView.headerView = headerView;
    self.columnView.headerPinHeight = 44.f;
    self.columnView.contentColumns = @[[RTDemoCollectionView new], [RTHeaderDemoTableView new], [RTDemoTableView new]];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.columnView.headerPinHeight = 80.f;
    });
}

@end

@interface RTChangeHeaderHeightViewController () <RTHeadedColumnViewDelegate>
@property (nonatomic, strong) RTHeadedColumnView *columnView;
@end

@implementation RTChangeHeaderHeightViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.navigationController setToolbarHidden:NO animated:YES];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 200)];
    headerView.backgroundColor = [UIColor colorWithWhite:1.f * 0x99 / 0xff
                                                   alpha:1.f];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"github"]];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *bottomView = [[UILabel alloc] init];
    bottomView.userInteractionEnabled = YES;
    bottomView.font = [UIFont systemFontOfSize:30];
    bottomView.textColor = [UIColor whiteColor];
    bottomView.textAlignment = NSTextAlignmentCenter;
    bottomView.text = @"A Common Title";
    bottomView.backgroundColor = [UIColor orangeColor];
    bottomView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

    CGRect slice, remainder;
    CGRectDivide(headerView.bounds, &slice, &remainder, 40.f, CGRectMaxYEdge);
    bottomView.frame = slice;
    imageView.frame = remainder;

    [headerView addSubview:bottomView];
    [headerView addSubview:imageView];

    self.toolbarItems = @[
                          ({
                              UIStepper *stepper = [[UIStepper alloc] init];
                              stepper.minimumValue = 80;
                              stepper.maximumValue = 320;
                              stepper.stepValue = 20;
                              stepper.value = headerView.bounds.size.height;
                              [stepper addTarget:self
                                          action:@selector(onHeaderHeight:)
                                forControlEvents:UIControlEventValueChanged];
                              [[UIBarButtonItem alloc] initWithCustomView:stepper];
                          }),
                          ({
                              UIStepper *stepper = [[UIStepper alloc] init];
                              stepper.minimumValue = 0;
                              stepper.maximumValue = 320;
                              stepper.stepValue = 10;
                              stepper.value = 40.f;
                              [stepper addTarget:self
                                          action:@selector(onDockingHeight:)
                                forControlEvents:UIControlEventValueChanged];
                              [[UIBarButtonItem alloc] initWithCustomView:stepper];
                          }),
                          ({
                              UISwitch *toggle = [[UISwitch alloc] init];
                              [toggle addTarget:self action:@selector(onEmbed:)
                               forControlEvents:UIControlEventValueChanged];
                              toggle.on = NO;
                              [[UIBarButtonItem alloc] initWithCustomView:toggle];
                          }),
                          ({
                              UISwitch *toggle = [[UISwitch alloc] init];
                              [toggle addTarget:self action:@selector(onBounce:)
                               forControlEvents:UIControlEventValueChanged];
                              toggle.on = NO;
                              [[UIBarButtonItem alloc] initWithCustomView:toggle];
                          })
                          ];

    self.columnView = [[RTHeadedColumnView alloc] initWithFrame:self.view.bounds];
    self.columnView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.columnView.delegate = self;
    [self.view addSubview:self.columnView];

    self.columnView.contentColumns = @[[RTDemoCollectionView new], [RTHeaderDemoTableView new], [RTDemoTableView new]];
    self.columnView.headerView = headerView;
    self.columnView.headerPinHeight = 40.f;
}

- (void)onHeaderHeight:(UIStepper *)stepper
{
    self.columnView.headerViewHeight = stepper.value;
}

- (void)onDockingHeight:(UIStepper *)stepper
{
    self.columnView.headerPinHeight = stepper.value;
}

- (void)onEmbed:(UISwitch *)toggle
{
    self.columnView.headerViewEmbeded = toggle.isOn;
}

- (void)onBounce:(UISwitch *)toggle
{
    self.columnView.headerViewBounce = toggle.isOn;
}

#pragma mark - Delegate

- (void)columnView:(RTHeadedColumnView *)columnView didDisplayColumn:(NSInteger)columnIndex
{
    NSLog(@"Did display column: %zd", columnIndex);
}

- (void)columnView:(RTHeadedColumnView *)columnView didScrollToOffset:(UIOffset)offset
{
    NSLog(@"Offset %@", NSStringFromUIOffset(offset));
}

@end
