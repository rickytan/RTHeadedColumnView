//
//  RTHeaderDemoTableView.m
//  RTHeadedColumnView
//
//  Created by ricky on 16/10/19.
//  Copyright © 2016年 rickytan. All rights reserved.
//

#import "RTHeaderDemoTableView.h"

@implementation RTHeaderDemoTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.delegate = self;
        self.dataSource = self;

        UIButton *header = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 88)];
        header.titleLabel.font = [UIFont systemFontOfSize:24];
        [header setTitle:@"Top Button" forState:UIControlStateNormal];
        [header setTitleColor:[UIColor colorWithWhite:1.f * 0x99 / 0xff
                                                alpha:1.f]
                     forState:UIControlStateNormal];
        self.tableHeaderView = header;
    }
    return self;
}

#pragma mark - UITableView Delegate & Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 8;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Header-%ld", section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 108.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"Cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UIView *view = [[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(cell.contentView.bounds, UIEdgeInsetsMake(10, 10, 10, 10))];
        view.backgroundColor = [UIColor colorWithWhite:1.f * 0xcc / 0xff
                                                 alpha:1.f];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:view];
    }
    return cell;
}

@end
