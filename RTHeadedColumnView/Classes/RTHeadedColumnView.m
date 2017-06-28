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

@interface UIScrollView (MultiColumnView)
@property (nonatomic, assign) UIEdgeInsets rt_originalContentInset;
@end

@implementation UIScrollView (MultiColumnView)

- (void)setRt_originalContentInset:(UIEdgeInsets)rt_originalContentInset
{
    objc_setAssociatedObject(self, @selector(rt_originalContentInset), [NSValue valueWithUIEdgeInsets:rt_originalContentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)rt_originalContentInset
{
    return [objc_getAssociatedObject(self, @selector(rt_originalContentInset)) UIEdgeInsetsValue];
}

@end

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
{
    struct {
        BOOL ignoreOffsetChangeNotify:1;
        BOOL ignoreOffsetChangeObserve:1;
        BOOL ignoreLayoutSetContentOffset:1;
    } _flags;
}
@synthesize headerPinHeight = _headerPinHeight;
@synthesize headerViewHeight = _headerViewHeight;
@synthesize contentColumns = _contentColumns;

- (void)dealloc
{
    _scrollView.delegate = nil;
    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        [obj removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:observerContext];
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillChangeStatusBarOrientationNotification
                                                  object:nil];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.automaticallyAdjustsScrollIndicatorInsets = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillRotate:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillRotate:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if (context == observerContext && !self->_flags.ignoreOffsetChangeObserve) {
        if (self.contentColumns[self.selectedColumn] != object) {
            return;
        }
        CGFloat top = ((UIScrollView *)object).contentInset.top;
        CGFloat offset = [change[NSKeyValueChangeNewKey] CGPointValue].y;
        self.currentOffset = offset + top;
        
        if (self.currentOffset > self.headerViewHeight - self.headerPinHeight) {
            if (self.headerView.superview != self) {
                self.headerView.frame = CGRectMake(0, offset - (self.headerViewHeight - self.headerPinHeight), self.bounds.size.width, self.headerViewHeight);
            }
            else {
                self.headerView.frame = CGRectMake(0, - (self.headerViewHeight - self.headerPinHeight), self.bounds.size.width, self.headerViewHeight);
            }
            
            self->_flags.ignoreOffsetChangeObserve = YES;
            [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
                if (obj != object) {
                    obj.contentOffset = CGPointMake(0, MAX(obj.contentOffset.y, self.headerViewHeight - self.headerPinHeight - obj.contentInset.top));
                }
            }];
            self->_flags.ignoreOffsetChangeObserve = NO;
        }
        else {
            if (self.headerView.superview != self) {
                if (self.headerViewBounce) {
                    self.headerView.frame = CGRectMake(0, -top, self.bounds.size.width, self.headerViewHeight);
                }
                else {
                    self.headerView.frame = CGRectMake(0, MIN(-top, offset), self.bounds.size.width, self.headerViewHeight);
                }
            }
            else {
                if (self.headerViewBounce) {
                    self.headerView.frame = CGRectMake(0, MIN(self.headerViewHeight, - offset - top), self.bounds.size.width, self.headerViewHeight);
                }
                else {
                    self.headerView.frame = CGRectMake(0, MIN(0, - offset - top), self.bounds.size.width, self.headerViewHeight);
                }
            }
            
            self->_flags.ignoreOffsetChangeObserve = YES;
            [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
                if (obj != object) {
                    obj.contentOffset = CGPointMake(0, offset + top - obj.contentInset.top);
                }
            }];
            self->_flags.ignoreOffsetChangeObserve = NO;
        }
        //        [self.headerView.superview bringSubviewToFront:self.headerView];
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
#if __IPHONE_11_0 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
        if ([_scrollView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
#endif
        [self addSubview:_scrollView];
    }
    return _scrollView;
}

- (void)setHeaderView:(UIView *)headerView
{
    if (headerView) {
        [_headerView removeFromSuperview];
        _headerView = headerView;
        //        _headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
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
        [self _detachHeaderView];
        
        if (animated) {
            self->_flags.ignoreLayoutSetContentOffset = YES;
        }
        [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.bounds) * _selectedColumn, 0)
                                 animated:animated];
        if (!animated) {
            [self _attachHeaderView];
        }
        
        [self _updateScrollsToTop];
        
        self.currentOffset = self.contentColumns[self.selectedColumn].contentInset.top + self.contentColumns[self.selectedColumn].contentOffset.y;
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
    
    [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
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
                inset.top = self.headerPinHeight + obj.rt_originalContentInset.top;
                
                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y + delta, - self.headerPinHeight) - obj.rt_originalContentInset.top;
                
                // Must change offset first!
                self->_flags.ignoreOffsetChangeNotify = YES;
                obj.contentOffset = offset;
                self->_flags.ignoreOffsetChangeNotify = NO;
                obj.contentInset = inset;
            }
            else {
                UIEdgeInsets inset = obj.contentInset;
                CGFloat delta = inset.top - self.headerViewHeight;
                inset.top = self.headerViewHeight + obj.rt_originalContentInset.top;
                
                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y + delta, - self.headerViewHeight) - obj.rt_originalContentInset.top;
                
                // Must change offset first!
                self->_flags.ignoreOffsetChangeNotify = YES;
                obj.contentOffset = offset;
                self->_flags.ignoreOffsetChangeNotify = NO;
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
                inset.top = obj.rt_originalContentInset.top;
                
                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y + delta, 0) - obj.rt_originalContentInset.top;
                
                // Must change offset first!
                self->_flags.ignoreOffsetChangeNotify = YES;
                obj.contentOffset = offset;
                self->_flags.ignoreOffsetChangeNotify = NO;
                obj.contentInset = inset;
            }
            else {
                UIEdgeInsets inset = obj.contentInset;
                CGFloat delta = inset.top - (self.headerViewHeight - self.headerPinHeight);
                inset.top = self.headerViewHeight - self.headerPinHeight + obj.rt_originalContentInset.top;
                
                CGPoint offset = obj.contentOffset;
                offset.y = MAX(offset.y + delta, - (self.headerViewHeight - self.headerPinHeight)) - obj.rt_originalContentInset.top;
                
                // Must change offset first!
                self->_flags.ignoreOffsetChangeNotify = YES;
                obj.contentOffset = offset;
                self->_flags.ignoreOffsetChangeNotify = NO;
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

- (void)setCurrentOffset:(CGFloat)currentOffset
{
    if (_currentOffset != currentOffset) {
        _currentOffset = currentOffset;
        if (!self->_flags.ignoreOffsetChangeNotify && [self.delegate respondsToSelector:@selector(columnView:didScrollToOffset:)]) {
            [self.delegate columnView:self
                    didScrollToOffset:UIOffsetMake(self.scrollView.contentOffset.x, self.currentOffset)];
        }
    }
}

- (void)setContentColumns:(NSArray<__kindof UIScrollView *> *)contentColumns
{
    if (![_contentColumns isEqualToArray:contentColumns]) {
        [self _detachHeaderView];
        
        [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
            [obj removeFromSuperview];
            [obj removeObserver:self
                     forKeyPath:NSStringFromSelector(@selector(contentOffset))
                        context:observerContext];
            obj.contentInset = obj.rt_originalContentInset;
        }];
        
        _contentColumns = contentColumns;
        
        if (contentColumns.count) {
            _selectedColumn = MIN(_selectedColumn, contentColumns.count - 1);
        }
        else {
            _contentColumns = nil;
            _selectedColumn = NSNotFound;
        }
        
        CGFloat width = self.scrollView.bounds.size.width;
        CGFloat height = self.scrollView.bounds.size.height;
        
        [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
            obj.rt_originalContentInset = obj.contentInset;
            
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
                
                if (self.headerViewEmbeded) {
                    UIEdgeInsets inset = obj.contentInset;
                    inset.top = self.headerPinHeight + obj.rt_originalContentInset.top;
                    obj.contentInset = inset;
                    obj.contentOffset = CGPointMake(0, self.currentOffset - inset.top);
                }
                else {
                    UIEdgeInsets inset = obj.contentInset;
                    inset.top = obj.rt_originalContentInset.top;
                    obj.contentInset = inset;
                    obj.contentOffset = CGPointMake(0, self.currentOffset - inset.top);
                }
            }
            else {
                if (self.headerViewEmbeded) {
                    UIEdgeInsets inset = obj.contentInset;
                    inset.top = self.headerViewHeight + obj.rt_originalContentInset.top;
                    obj.contentInset = inset;
                    obj.contentOffset = CGPointMake(0, self.currentOffset - inset.top);
                }
                else {
                    UIEdgeInsets inset = obj.contentInset;
                    inset.top = self.headerViewHeight - self.headerPinHeight + obj.rt_originalContentInset.top;
                    obj.contentInset = inset;
                    obj.contentOffset = CGPointMake(0, self.currentOffset - inset.top);
                }
            }
            
            if (self.automaticallyAdjustsScrollIndicatorInsets) {
                if (self.headerViewEmbeded) {
                    obj.scrollIndicatorInsets = UIEdgeInsetsZero;
                }
                else {
                    UIEdgeInsets inset = obj.scrollIndicatorInsets;
                    inset.top = self.headerViewHeight - self.headerPinHeight;
                    obj.scrollIndicatorInsets = inset;
                }
            }
            
            obj.frame = CGRectMake(width * idx, 0, width, height);
            obj.scrollsToTop = idx == _selectedColumn;
            [self.scrollView addSubview:obj];
            
            
            [obj addObserver:self
                  forKeyPath:NSStringFromSelector(@selector(contentOffset))
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:observerContext];
        }];
        
        [self _attachHeaderView];
        [self setNeedsLayout];
    }
}

- (NSArray<UIScrollView *> *)contentColumns
{
    if (_contentColumns.count == 0) {
        self.contentColumns = @[[[UIScrollView alloc] init]];
    }
    return _contentColumns;
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
    
    _scrollView.contentSize = CGSizeMake(width * _contentColumns.count, 0);
    if (!self->_flags.ignoreLayoutSetContentOffset) {
        _scrollView.contentOffset = CGPointMake(width * self.selectedColumn, 0);
    }
    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        CGRect rect = CGRectMake(width * idx, 0, width, _scrollView.bounds.size.height);
        if (!CGRectEqualToRect(obj.frame, rect)) {
            obj.frame = rect;
        }
    }];
    
    if (_headerView)
        [_headerView.superview bringSubviewToFront:_headerView];
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
        tableHeader.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [view addSubview:tableHeader];
    }
    return view;
}

- (void)_updateScrollsToTop
{
    [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIScrollView * obj, NSUInteger idx, BOOL * stop) {
        obj.scrollsToTop = idx == _selectedColumn;
    }];
}

- (void)_detachHeaderView
{
    if (self.headerViewEmbeded) {
        CGRect rect = [self.headerView convertRect:self.headerView.bounds
                                            toView:self];
        self.headerView.frame = rect;
        [self addSubview:self.headerView];
    }
}

- (void)_attachHeaderView
{
    if (self.headerViewEmbeded) {
        UIScrollView *contentView = self.contentColumns[self.selectedColumn];
        CGRect rect = [self.headerView convertRect:self.headerView.bounds
                                            toView:contentView];
        self.headerView.frame = rect;
        [contentView addSubview:self.headerView];
        [self.scrollView bringSubviewToFront:contentView];
    }
}

- (void)_notifySelectionChanged
{
    CGFloat width = self.bounds.size.width;
    NSInteger newSelection = (NSInteger)floorf((_scrollView.contentOffset.x + width / 2) / width);
    if (newSelection != _selectedColumn) {
        _selectedColumn = newSelection;
        
        [self _updateScrollsToTop];
        
        if ([self.delegate respondsToSelector:@selector(columnView:didDisplayColumn:)]) {
            [self.delegate columnView:self didDisplayColumn:_selectedColumn];
        }
        
        self.currentOffset = self.contentColumns[self.selectedColumn].contentInset.top + self.contentColumns[self.selectedColumn].contentOffset.y;
    }
}

- (void)onWillRotate:(NSNotification *)notification
{
    [self _attachHeaderView];
    self.currentOffset = self.contentColumns[self.selectedColumn].contentInset.top + self.contentColumns[self.selectedColumn].contentOffset.y;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self _detachHeaderView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        self->_flags.ignoreLayoutSetContentOffset = NO;
        [self _notifySelectionChanged];
        [self _attachHeaderView];
    }
    else {
        self->_flags.ignoreLayoutSetContentOffset = YES;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self->_flags.ignoreLayoutSetContentOffset = NO;
    [self _notifySelectionChanged];
    [self _attachHeaderView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self->_flags.ignoreLayoutSetContentOffset = NO;
    [self _attachHeaderView];
    self.currentOffset = self.contentColumns[self.selectedColumn].contentInset.top + self.contentColumns[self.selectedColumn].contentOffset.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(columnView:didScrollToOffset:)]) {
        [self.delegate columnView:self
                didScrollToOffset:UIOffsetMake(self.scrollView.contentOffset.x, _currentOffset)];
    }
}

@end
