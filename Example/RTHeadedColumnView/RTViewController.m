//
//  RTViewController.m
//  RTHeadedColumnView
//
//  Created by rickytan on 10/19/2016.
//  Copyright (c) 2016 rickytan. All rights reserved.
//

#import "RTViewController.h"

#import "RTDemoTableView.h"
#import "RTHeaderDemoTableView.h"

@import RTHeadedColumnView;

@interface RTViewController () <RTHeadedColumnViewDelegate>
@property (nonatomic, strong) RTHeadedColumnView *columnView;
@end

@implementation RTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 180)];
    headerView.backgroundColor = [UIColor colorWithWhite:1.f * 0x99 / 0xff
                                                   alpha:1.f];

    self.columnView = [[RTHeadedColumnView alloc] initWithFrame:self.view.bounds];
    self.columnView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.columnView];

    self.columnView.headerView = headerView;
    self.columnView.dockingHeight = 44.f;
    self.columnView.contentColumns = @[[RTDemoTableView new], [RTHeaderDemoTableView new], [RTDemoTableView new]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
