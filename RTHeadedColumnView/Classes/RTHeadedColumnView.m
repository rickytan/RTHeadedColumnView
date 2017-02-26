// RTHeadedColumnView.m
//
// Copyright (c) 2017 rickytan
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <objc/runtime.h>

#import "RTHeadedColumnView.h"

@interface UITableView (MultiColumnView)
@property (nonatomic, strong) UIView *rt_originalTableHeaderView;
@end

@implementation UITableView (MultiColumnView)
@dynamic rt_originalTableHeaderView;

- (void)setRt_originalTableHeaderView:(UIView *)rt_originalTableHeaderView
{
    objc_setAssociatedObject(self, @selector(rt_originalTableHeaderView), rt_originalTableHeaderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)rt_originalTableHeaderView
{
    return (UIView *)objc_getAssociatedObject(self, @selector(rt_originalTableHeaderView));
}

@end


@interface __RTTableHeaderPlaceholderView : UIView
@end

@implementation __RTTableHeaderPlaceholderView

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
@synthesize headerPinHeight = _headerPinHeight;
@synthesize headerViewHeight = _headerViewHeight;

- (void)dealloc
{
    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        [obj removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:observerContext];
    }];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.automaticallyAdjustsScrollIndicatorInsets = YES;
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

        if (offset + top > self.headerViewHeight - self.headerPinHeight) {
            if (self.headerViewEmbeded) {
                self.headerView.frame = CGRectMake(0, offset - (self.headerViewHeight - self.headerPinHeight), self.bounds.size.width, self.headerViewHeight);
            }
            else {
                self.headerView.frame = CGRectMake(0, - (self.headerViewHeight - self.headerPinHeight), self.bounds.size.width, self.headerViewHeight);
            }
            [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
                if (obj != object) {
                    obj.contentOffset = CGPointMake(0, MAX(obj.contentOffset.y, self.headerViewHeight - self.headerPinHeight - obj.contentInset.top));
                }
            }];
        }
        else {
            if (self.headerViewBounce) {
                if (self.headerViewEmbeded) {
                    self.headerView.frame = CGRectMake(0, -top, self.bounds.size.width, self.headerViewHeight);
                }
                else {
                    self.headerView.frame = CGRectMake(0, MIN(self.headerViewHeight - self.headerPinHeight, - offset - top), self.bounds.size.width, self.headerViewHeight);
                }
            }
            else {
                if (self.headerViewEmbeded) {
                    self.headerView.frame = CGRectMake(0, -top, self.bounds.size.width, self.headerViewHeight);
                }
                else {
                    self.headerView.frame = CGRectMake(0, MIN(0, - offset - top), self.bounds.size.width, self.headerViewHeight);
                }
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
        if (self.headerViewEmbeded) {
            [self.contentColumns[self.selectedColumn] addSubview:_headerView];
        }
        else {
            [self addSubview:_headerView];
        }
        self.headerViewHeight = headerView.bounds.size.height;
    }
    else {
        [_headerView removeFromSuperview];
        _headerView = nil;
        self.headerViewHeight = 0;
        self.headerPinHeight = 0;
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

- (void)setHeaderViewEmbeded:(BOOL)headerViewEmbeded
{
    if (_headerViewEmbeded != headerViewEmbeded) {
        _headerViewEmbeded = headerViewEmbeded;

        if (self.headerView) {
            if (_headerViewEmbeded) {
                [self.contentColumns[self.selectedColumn] addSubview:self.headerView];
            }
            else {
                [self addSubview:_headerView];
            }
            self.headerPinHeight = _headerPinHeight;
        }
    }
}

- (void)setHeaderViewHeight:(CGFloat)headerViewHeight
{
    if (_headerViewHeight != headerViewHeight) {
        _headerViewHeight = headerViewHeight;

        CGRect rect = self.headerView.frame;
        rect.size.height = headerViewHeight;
        self.headerView.frame = rect;
        self.headerPinHeight = _headerPinHeight;
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

- (void)setHeaderPinHeight:(CGFloat)headerPinHeight
{
    _headerPinHeight = headerPinHeight;

    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        if (self.headerViewEmbeded) {
            if ([obj isKindOfClass:[UITableView class]]) {
                UITableView *tableView = (UITableView *)obj;
                if (![tableView.tableHeaderView isKindOfClass:[__RTTableHeaderPlaceholderView class]]) {
                    UIView *tableHeader = tableView.tableHeaderView;
                    tableView.tableHeaderView = nil;    // !IMPORTANT, don't remove

                    tableView.rt_originalTableHeaderView = tableHeader;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableHeader];
                }
                else {
                    tableView.tableHeaderView = nil;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableView.rt_originalTableHeaderView];
                }

                UIEdgeInsets inset = obj.contentInset;
                CGFloat delta = inset.top - self.headerPinHeight;
                inset.top = self.headerPinHeight;

                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y + delta, - self.headerPinHeight);

                // Must change offset first!
                obj.contentOffset = offset;
                obj.contentInset = inset;
            }
            else {
                UIEdgeInsets inset = obj.contentInset;
                CGFloat delta = inset.top - self.headerViewHeight;
                inset.top = self.headerViewHeight;

                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y + delta, - self.headerViewHeight);

                // Must change offset first!
                obj.contentOffset = offset;
                obj.contentInset = inset;
            }

            if (self.automaticallyAdjustsScrollIndicatorInsets) {
                obj.scrollIndicatorInsets = UIEdgeInsetsZero;
            }
        }
        else {
            if ([obj isKindOfClass:[UITableView class]]) {
                UITableView *tableView = (UITableView *)obj;
                if (![tableView.tableHeaderView isKindOfClass:[__RTTableHeaderPlaceholderView class]]) {
                    UIView *tableHeader = tableView.tableHeaderView;
                    tableView.tableHeaderView = nil;    // !IMPORTANT, don't remove

                    tableView.rt_originalTableHeaderView = tableHeader;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableHeader];
                }
                else {
                    tableView.tableHeaderView = nil;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableView.rt_originalTableHeaderView];
                }

                UIEdgeInsets inset = obj.contentInset;
                CGFloat delta = inset.top;
                inset.top = 0.f;

                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y + delta, 0);

                // Must change offset first!
                obj.contentOffset = offset;
                obj.contentInset = inset;
            }
            else {
                UIEdgeInsets inset = obj.contentInset;
                CGFloat delta = inset.top - (self.headerViewHeight - self.headerPinHeight);
                inset.top = self.headerViewHeight - self.headerPinHeight;

                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y + delta, - (self.headerViewHeight - self.headerPinHeight));

                // Must change offset first!
                obj.contentOffset = offset;
                obj.contentInset = inset;
            }

            if (self.automaticallyAdjustsScrollIndicatorInsets) {
                UIEdgeInsets inset = obj.scrollIndicatorInsets;
                inset.top = self.headerViewHeight - self.headerPinHeight;
                obj.scrollIndicatorInsets = inset;
            }
        }
    }];
    [self setNeedsLayout];
}

- (CGFloat)headerPinHeight
{
    if (self.headerView) {
        return MIN(_headerPinHeight, _headerViewHeight);
    }
    return 0.f;
}

- (UIView *)_createPlaceholderHeaderViewWithHeight:(CGFloat)height
                           originalTableHeaderView:(UIView *)tableHeader
{
    UIView *view = [[__RTTableHeaderPlaceholderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), height + CGRectGetHeight(tableHeader.bounds))];
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
                if (![tableView.tableHeaderView isKindOfClass:[__RTTableHeaderPlaceholderView class]]) {
                    UIView *tableHeader = tableView.tableHeaderView;
                    tableView.tableHeaderView = nil;    // !IMPORTANT, don't remove

                    tableView.rt_originalTableHeaderView = tableHeader;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableHeader];
                }
                else {
                    tableView.tableHeaderView = nil;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableView.rt_originalTableHeaderView];
                }
            }
            else {
                UIEdgeInsets inset = obj.contentInset;
                inset.top = self.headerViewHeight - self.headerPinHeight;
                obj.contentInset = inset;

                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y, -(self.headerViewHeight - self.headerPinHeight));
                obj.contentOffset = offset;
            }

            if (self.automaticallyAdjustsScrollIndicatorInsets) {
                UIEdgeInsets inset = obj.scrollIndicatorInsets;
                inset.top = self.headerViewHeight - self.headerPinHeight;
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
    if (self.headerViewEmbeded) {
        _scrollView.frame = self.bounds;
    }
    else {
        CGRect slice, remainder;
        CGRectDivide(self.bounds, &slice, &remainder, self.headerPinHeight, CGRectMinYEdge);

        _scrollView.frame = remainder;
    }

    _scrollView.contentSize = CGSizeMake(width * self.contentColumns.count, 0);
    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        obj.frame = CGRectMake(width * idx, 0, width, _scrollView.bounds.size.height);
    }];

    if (_headerView)
        [_headerView.superview bringSubviewToFront:_headerView];
}

- (void)_notifySelectionChanged
{
    CGFloat width = self.bounds.size.width;
    _selectedColumn = (NSInteger)floorf((_scrollView.contentOffset.x + width / 2) / width);
    [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        obj.scrollsToTop = idx == _selectedColumn;
    }];

    if ([self.delegate respondsToSelector:@selector(columnView:didDisplayColumn:)]) {
        [self.delegate columnView:self didDisplayColumn:_selectedColumn];
    }

    if (self.headerViewEmbeded) {
        CGRect rect = [self.headerView convertRect:self.headerView.bounds
                                            toView:self.contentColumns[self.selectedColumn]];
        self.headerView.frame = rect;
        [self.contentColumns[self.selectedColumn] addSubview:self.headerView];
    }
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.headerViewEmbeded) {
        CGRect rect = [self.headerView convertRect:self.headerView.bounds
                                            toView:self];
        self.headerView.frame = rect;
        [self addSubview:self.headerView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self _notifySelectionChanged];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self _notifySelectionChanged];
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
