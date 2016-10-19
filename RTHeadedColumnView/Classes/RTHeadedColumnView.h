//
//  MZMultiColumnView.h
//  meizhuang
//
//  Created by Ricky on 16/8/6.
//  Copyright © 2016年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTHeadedColumnView;

NS_ASSUME_NONNULL_BEGIN

@protocol RTHeadedColumnViewDelegate <NSObject>
@optional
- (void)columnView:(RTHeadedColumnView *)columnView willDisplayColumn:(NSInteger)columnIndex;
- (void)columnView:(RTHeadedColumnView *)columnView didDisplayColumn:(NSInteger)columnIndex;
- (void)columnView:(RTHeadedColumnView *)columnView didScrollToOffset:(UIOffset)offset;

@end

@interface RTHeadedColumnView : UIView

@property (nonatomic, weak, nullable) IBOutlet id<RTHeadedColumnViewDelegate> delegate;

@property (nonatomic, strong, nullable) UIView *headerView;
@property (nonatomic, assign) BOOL headerBounce;

@property (nonatomic, assign) CGFloat headerViewHeight;

- (void)setHeaderViewHeight:(CGFloat)height animated:(BOOL)animated;


@property (nonatomic, assign) CGFloat dockingHeight;

@property (nonatomic, strong, nullable) NSArray <__kindof UIScrollView *> *contentColumns;

@property (nonatomic, assign) NSInteger selectedColumn;

- (void)setSelectedColumn:(NSInteger)selectedColumn animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
