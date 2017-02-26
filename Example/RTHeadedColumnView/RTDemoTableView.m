//
//  RTDemoTableView.m
//  RTHeadedColumnView
//
//  Created by ricky on 16/10/19.
//  Copyright © 2016年 rickytan. All rights reserved.
//

#import "RTDemoTableView.h"

@implementation RTDemoTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
    }
    return self;
}

#pragma mark - UITableView Delegate & Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 6;
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Header-%ld", section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 88.f;
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 12;
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

@implementation RTDemoCollectionView

- (instancetype)initWithFrame:(CGRect)frame
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 10.f;
    layout.minimumInteritemSpacing = 10.f;
    layout.itemSize = CGSizeMake(64, 64);
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self = [super initWithFrame:frame
           collectionViewLayout:layout];
    if (self) {
        self.delegate = self;
        self.dataSource = self;

        self.backgroundColor = [UIColor yellowColor];
        [self registerClass:[UICollectionViewCell class]
 forCellWithReuseIdentifier:@"Cell"];
    }
    return self;
}

#pragma mark - UICollectionView Datasource & Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 40;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell"
                                                                           forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor lightGrayColor];
    return cell;
}

@end
