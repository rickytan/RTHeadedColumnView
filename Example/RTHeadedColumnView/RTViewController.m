//
//  RTViewController.m
//  RTHeadedColumnView
//
//  Created by rickytan on 10/19/2016.
//  Copyright (c) 2016 rickytan. All rights reserved.
//

#import "RTViewController.h"

#import "RTDemoTableView.h"

@import RTHeadedColumnView;

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
    self.columnView.dockingHeight = 44.f;
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
    self.columnView.dockingHeight = 44.f;
    self.columnView.contentColumns = @[[RTDemoCollectionView new], [RTHeaderDemoTableView new], [RTDemoTableView new]];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.columnView.dockingHeight = 80.f;
    });
}

@end

@interface RTChangeHeaderHeightViewController ()
@property (nonatomic, strong) RTHeadedColumnView *columnView;
@end

@implementation RTChangeHeaderHeightViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 200)];
    headerView.backgroundColor = [UIColor colorWithWhite:1.f * 0x99 / 0xff
                                                   alpha:1.f];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"github"]];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UILabel *bottomView = [[UILabel alloc] init];
    bottomView.font = [UIFont systemFontOfSize:30];
    bottomView.textColor = [UIColor whiteColor];
    bottomView.text = @"A Common Title";
    bottomView.backgroundColor = [UIColor orangeColor];
    bottomView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

    CGRect slice, remainder;
    CGRectDivide(headerView.bounds, &slice, &remainder, 44.f, CGRectMaxYEdge);
    bottomView.frame = slice;
    imageView.frame = remainder;

    [headerView addSubview:bottomView];
    [headerView addSubview:imageView];

    UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectMake(0, 0, 64, 44)];
    stepper.minimumValue = 80;
    stepper.maximumValue = 320;
    stepper.stepValue = 20;
    stepper.value = headerView.bounds.size.height;
    [stepper addTarget:self
                action:@selector(onStepper:)
      forControlEvents:UIControlEventValueChanged];
    [headerView addSubview:stepper];

    self.columnView = [[RTHeadedColumnView alloc] initWithFrame:self.view.bounds];
    self.columnView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.columnView];

    self.columnView.headerView = headerView;
    self.columnView.dockingHeight = 44.f;
    self.columnView.contentColumns = @[[RTDemoCollectionView new], [RTHeaderDemoTableView new], [RTDemoTableView new]];
}

- (void)onStepper:(UIStepper *)stepper
{
//    self.columnView.headerViewHeight = stepper.value;
    [self.columnView setHeaderViewHeight:stepper.value
                                animated:YES];
}

@end
