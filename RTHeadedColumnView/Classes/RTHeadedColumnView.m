//
//  MZMultiColumnView.m
//  meizhuang
//
//  Created by Ricky on 16/8/6.
//  Copyright © 2016年 netease. All rights reserved.
//

#import <objc/runtime.h>

#import "RTHeadedColumnView.h"

@interface UITableView (MultiColumnView)
@property (nonatomic, strong) UIView *mc_originalTableHeaderView;
@end

@implementation UITableView (MultiColumnView)
@dynamic mc_originalTableHeaderView;

- (void)setMc_originalTableHeaderView:(UIView *)mc_originalTableHeaderView
{
    objc_setAssociatedObject(self, @selector(mc_originalTableHeaderView), mc_originalTableHeaderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)mc_originalTableHeaderView
{
    return (UIView *)objc_getAssociatedObject(self, @selector(mc_originalTableHeaderView));
}

@end


@interface MZMultiColumnTableHeaderPlaceholderView : UIView
@end

@implementation MZMultiColumnTableHeaderPlaceholderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
    }
    return self;
}

@end

@interface RTHeadedColumnView () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) CGFloat currentOffset;
@end

static void *observerContext = &observerContext;

@implementation RTHeadedColumnView
@synthesize dockingHeight = _dockingHeight;
@synthesize headerViewHeight = _headerViewHeight;

- (void)dealloc
{
    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        [obj removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))];
    }];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if (context == observerContext) {
        if (self.contentColumns[self.selectedColumn] != object) {
            return;
        }
        CGFloat top = ((UIScrollView *)object).contentInset.top;
        CGFloat offset = [change[NSKeyValueChangeNewKey] CGPointValue].y;
        self.currentOffset = offset + top;

        if (offset + top > self.headerViewHeight - self.dockingHeight) {
            self.headerView.frame = CGRectMake(0, -(self.headerViewHeight - self.dockingHeight), self.bounds.size.width, self.headerViewHeight);
            [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
                if (obj != object) {
                    obj.contentOffset = CGPointMake(0, MAX(obj.contentOffset.y, self.headerViewHeight - self.dockingHeight - obj.contentInset.top));
                }
            }];
        }
        else {
            if (self.headerBounce) {
                self.headerView.frame = CGRectMake(0, MIN(self.headerViewHeight - self.dockingHeight, - offset - top), self.bounds.size.width, self.headerViewHeight);
            }
            else {
                self.headerView.frame = CGRectMake(0, MIN(0, - offset - top), self.bounds.size.width, self.headerViewHeight);
            }
            [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
                if (obj != object) {
                    obj.contentOffset = CGPointMake(0, offset + top - obj.contentInset.top);
                }
            }];
        }
    }
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _scrollView.pagingEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.bounces = NO;
        [self addSubview:_scrollView];
    }
    return _scrollView;
}

- (void)setHeaderView:(UIView *)headerView
{
    if (headerView) {
        [_headerView removeFromSuperview];
        _headerView = headerView;
        [self addSubview:_headerView];
        self.headerViewHeight = headerView.bounds.size.height;
    }
    else {
        [_headerView removeFromSuperview];
        _headerView = nil;
        self.headerViewHeight = 0;
        self.dockingHeight = 0;
    }
}

- (void)setSelectedColumn:(NSInteger)selectedColumn
{
    [self setSelectedColumn:selectedColumn
                   animated:NO];
}

- (void)setSelectedColumn:(NSInteger)selectedColumn
                 animated:(BOOL)animated
{
    if (_selectedColumn != selectedColumn) {
        _selectedColumn = selectedColumn;
        [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
            obj.scrollsToTop = idx == _selectedColumn;
        }];

        [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.bounds) * _selectedColumn, 0)
                                 animated:animated];
    }
}

- (void)setHeaderViewHeight:(CGFloat)headerViewHeight
{
    if (_headerViewHeight != headerViewHeight) {
        _headerViewHeight = headerViewHeight;

        CGRect rect = self.headerView.frame;
        rect.size.height = headerViewHeight;
        self.headerView.frame = rect;
        self.dockingHeight = _dockingHeight;
    }
}

- (CGFloat)headerViewHeight
{
    if (self.headerView) {
        return _headerViewHeight;
    }
    return 0.f;
}

- (void)setHeaderViewHeight:(CGFloat)headerViewHeight animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? 0.25 : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.headerViewHeight = headerViewHeight;
                     }
                     completion:^(BOOL finished) {

                     }];
}

- (void)setDockingHeight:(CGFloat)dockingHeight
{
    _dockingHeight = dockingHeight;

    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        if ([obj isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)obj;
            if (![tableView.tableHeaderView isKindOfClass:[MZMultiColumnTableHeaderPlaceholderView class]]) {
                UIView *tableHeader = tableView.tableHeaderView;
                tableView.tableHeaderView = nil;    // !IMPORTANT, don't remove

                tableView.mc_originalTableHeaderView = tableHeader;
                tableView.tableHeaderView = [self createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.dockingHeight
                                                                originalTableHeaderView:tableHeader];
            }
            else {
                tableView.tableHeaderView = nil;
                tableView.tableHeaderView = [self createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.dockingHeight
                                                                originalTableHeaderView:tableView.mc_originalTableHeaderView];
            }
        }
        else {
            UIEdgeInsets inset = obj.contentInset;
            CGFloat delta = inset.top - (self.headerViewHeight - self.dockingHeight);
            inset.top = self.headerViewHeight - self.dockingHeight;

            CGPoint offset = obj.contentOffset;
            offset.y = MAX(offset.y + delta, - (self.headerViewHeight - self.dockingHeight));

            // Must change offset first!
            obj.contentOffset = offset;
            obj.contentInset = inset;
        }

        if (self.automaticallyAdjustsScrollViewInsets) {
            UIEdgeInsets inset = obj.scrollIndicatorInsets;
            inset.top = self.headerViewHeight - self.dockingHeight;
            obj.scrollIndicatorInsets = inset;
        }
    }];
    [self setNeedsLayout];
}

- (CGFloat)dockingHeight
{
    if (self.headerView) {
        return MIN(_dockingHeight, _headerViewHeight);
    }
    return 0.f;
}

- (UIView *)createPlaceholderHeaderViewWithHeight:(CGFloat)height
                          originalTableHeaderView:(UIView *)tableHeader
{
    UIView *view = [[MZMultiColumnTableHeaderPlaceholderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), height + CGRectGetHeight(tableHeader.bounds))];
    if (tableHeader) {
        tableHeader.frame = CGRectMake(0,
                                       CGRectGetHeight(view.bounds) - CGRectGetHeight(tableHeader.bounds),
                                       CGRectGetWidth(view.bounds),
                                       CGRectGetHeight(tableHeader.bounds));
        tableHeader.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [view addSubview:tableHeader];
    }
    return view;
}

- (void)setContentColumns:(NSArray<__kindof UIScrollView *> *)contentColumns
{
    if (![_contentColumns isEqualToArray:contentColumns]) {
        [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
            [obj removeFromSuperview];
            [obj removeObserver:self
                     forKeyPath:NSStringFromSelector(@selector(contentOffset))
                        context:observerContext];
        }];

        _contentColumns = contentColumns;

        CGFloat width = self.bounds.size.width;
        CGFloat height = self.bounds.size.height;

        [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
            if ([obj isKindOfClass:[UITableView class]]) {
                UITableView *tableView = (UITableView *)obj;
                if (![tableView.tableHeaderView isKindOfClass:[MZMultiColumnTableHeaderPlaceholderView class]]) {
                    UIView *tableHeader = tableView.tableHeaderView;
                    tableView.tableHeaderView = nil;    // !IMPORTANT, don't remove

                    tableView.mc_originalTableHeaderView = tableHeader;
                    tableView.tableHeaderView = [self createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.dockingHeight
                                                                    originalTableHeaderView:tableHeader];
                }
                else {
                    tableView.tableHeaderView = nil;
                    tableView.tableHeaderView = [self createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.dockingHeight
                                                                    originalTableHeaderView:tableView.mc_originalTableHeaderView];
                }
            }
            else {
                UIEdgeInsets inset = obj.contentInset;
                inset.top = self.headerViewHeight - self.dockingHeight;
                obj.contentInset = inset;

                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y, -(self.headerViewHeight - self.dockingHeight));
                obj.contentOffset = offset;
            }

            if (self.automaticallyAdjustsScrollViewInsets) {
                UIEdgeInsets inset = obj.scrollIndicatorInsets;
                inset.top = self.headerViewHeight - self.dockingHeight;
                obj.scrollIndicatorInsets = inset;
            }

            obj.frame = CGRectMake(width * idx, 0, width, height);
            obj.scrollsToTop = idx == _selectedColumn;
            [self.scrollView addSubview:obj];

            [obj addObserver:self
                  forKeyPath:NSStringFromSelector(@selector(contentOffset))
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:observerContext];
        }];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat width = self.bounds.size.width;

    CGRect slice, remainder;
    CGRectDivide(self.bounds, &slice, &remainder, self.dockingHeight, CGRectMinYEdge);

    _scrollView.frame = remainder;

    _scrollView.contentSize = CGSizeMake(width * self.contentColumns.count, 0);
    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        obj.frame = CGRectMake(width * idx, 0, width, _scrollView.bounds.size.height);
    }];

    if (_headerView)
        [self bringSubviewToFront:_headerView];
}

- (void)updateContents
{

}

#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        CGFloat width = self.bounds.size.width;
        _selectedColumn = (NSInteger)floorf((scrollView.contentOffset.x + width / 2) / width);
        [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
            obj.scrollsToTop = idx == _selectedColumn;
        }];

        if ([self.delegate respondsToSelector:@selector(columnView:didDisplayColumn:)]) {
            [self.delegate columnView:self didDisplayColumn:_selectedColumn];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat width = self.bounds.size.width;
    _selectedColumn = (NSInteger)floorf((scrollView.contentOffset.x + width / 2) / width);
    [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        obj.scrollsToTop = idx == _selectedColumn;
    }];

    if ([self.delegate respondsToSelector:@selector(columnView:didDisplayColumn:)]) {
        [self.delegate columnView:self didDisplayColumn:_selectedColumn];
    }
}

- (void)setCurrentOffset:(CGFloat)currentOffset
{
    _currentOffset = currentOffset;
    if ([self.delegate respondsToSelector:@selector(columnView:didScrollToOffset:)]) {
        [self.delegate columnView:self
                didScrollToOffset:UIOffsetMake(self.scrollView.contentOffset.x, _currentOffset)];
    }
}

@end
