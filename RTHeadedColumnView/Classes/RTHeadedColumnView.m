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

#define SELSTR(sel)     ((NO && NSStringFromSelector(@selector(sel))), @#sel)
#define RT_CONTENT_INSET(view)      ({ UIEdgeInsets insets = (view).contentInset; if (@available(iOS 11.0, *)) { insets = (view).adjustedContentInset; } else { } insets; })


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

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        view = nil;
    }
    return view;
}

@end

@interface RTHeadedColumnView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIPanGestureRecognizer * panGestureToFailScrollViewPanGesture;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) CGFloat currentOffset;
@property (nonatomic, readonly) CGFloat _innerHeaderViewHeight;
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
    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIView<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.contentScrollView removeObserver:self forKeyPath:SELSTR(contentOffset) context:observerContext];
        [obj.contentScrollView removeObserver:self forKeyPath:SELSTR(safeAreaInsets) context:observerContext];
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
        if (0 <= _selectedColumn && _selectedColumn < _contentColumns.count) {
            if (_contentColumns[_selectedColumn].contentScrollView != object) {
                return;
            }
        }
        if ([keyPath isEqualToString:SELSTR(safeAreaInsets)]) {
            const UIEdgeInsets newInsets = [change[NSKeyValueChangeNewKey] UIEdgeInsetsValue];
            const UIEdgeInsets oldInsets = [change[NSKeyValueChangeOldKey] UIEdgeInsetsValue];
            if (newInsets.top == oldInsets.top) {
                return;
            }
            
            if (self.ignoreSafeAreaTopInset) {
                self.headerPinHeight = _headerPinHeight;
            }
            return;
        }
        const CGPoint newOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
//        const CGPoint oldOffset = [change[NSKeyValueChangeOldKey] CGPointValue];
//        if (CGPointEqualToPoint(newOffset, oldOffset)) {
//            return;
//        }
        
        const CGFloat top = RT_CONTENT_INSET((UIScrollView *)object).top;
        const CGFloat offset = newOffset.y;
        self.currentOffset = offset + top;
        
        if (self.currentOffset > self.headerViewHeight - self.headerPinHeight) {
            if (self.headerView.superview != self) {
                self.headerView.frame = CGRectMake(0, offset - (self.headerViewHeight - self.headerPinHeight), self.bounds.size.width, self.headerViewHeight);
            }
            else {
                self.headerView.frame = CGRectMake(0, - (self.headerViewHeight - self.headerPinHeight), self.bounds.size.width, self.headerViewHeight);
            }
        }
        else {
            if (self.headerView.superview != self) {
                if (self.headerViewBounce) {
                    if ([object isKindOfClass:[UITableView class]]) {
                        self.headerView.frame = CGRectMake(0, -(self.headerPinHeight + ((UIScrollView *)object).rt_originalContentInset.top), self.bounds.size.width, self.headerViewHeight);
                    }
                    else {
                        self.headerView.frame = CGRectMake(0, -(self.headerViewHeight + ((UIScrollView *)object).rt_originalContentInset.top), self.bounds.size.width, self.headerViewHeight);
                    }
                }
                else {
                    self.headerView.frame = CGRectMake(0, MIN(-top, offset), self.bounds.size.width, self.headerViewHeight);
                }
            }
            else {
                if (self.headerViewBounce) {
                    if (self.headerViewEmbeded) {
                        if ([object isKindOfClass:[UITableView class]]) {
                            self.headerView.frame = CGRectMake(0, MIN(self.headerViewHeight, - offset - (self.headerPinHeight + ((UIScrollView *)object).rt_originalContentInset.top)), self.bounds.size.width, self.headerViewHeight);
                        }
                        else {
                            self.headerView.frame = CGRectMake(0, MIN(self.headerViewHeight, - offset - (self.headerViewHeight + ((UIScrollView *)object).rt_originalContentInset.top)), self.bounds.size.width, self.headerViewHeight);
                        }
                    }
                    else {
                        self.headerView.frame = CGRectMake(0, MIN(self.headerViewHeight, - offset - top), self.bounds.size.width, self.headerViewHeight);
                    }
                }
                else {
                    self.headerView.frame = CGRectMake(0, MIN(0, - offset - top), self.bounds.size.width, self.headerViewHeight);
                }
            }
        }
        //        [self.headerView.superview bringSubviewToFront:self.headerView];
    }
}

- (UIPanGestureRecognizer *)panGestureToFailScrollViewPanGesture
{
    if (!_panGestureToFailScrollViewPanGesture) {
        _panGestureToFailScrollViewPanGesture = [[UIPanGestureRecognizer alloc] init];
        _panGestureToFailScrollViewPanGesture.delegate = self;
        [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:_panGestureToFailScrollViewPanGesture];
    }
    return _panGestureToFailScrollViewPanGesture;
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
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
#endif
        [self addSubview:_scrollView];
    }
    return _scrollView;
}

- (void)setHeaderView:(UIView *)headerView
{
    if (headerView) {
        [_headerView removeGestureRecognizer:_panGestureToFailScrollViewPanGesture];
        [_headerView removeFromSuperview];
        _headerView = headerView;
        [_headerView addGestureRecognizer:self.panGestureToFailScrollViewPanGesture];
        _headerViewHeight = headerView.bounds.size.height;
        
        if (self.headerViewEmbeded) {
            [self.contentColumns[self.selectedColumn].contentScrollView addSubview:_headerView];
        }
        else {
            [self addSubview:_headerView];
        }
        self.headerPinHeight = _headerPinHeight;
    }
    else {
        [_headerView removeGestureRecognizer:_panGestureToFailScrollViewPanGesture];
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
        [self _detachHeaderView];
        [self _syncContentOffset];
        
        
        if (animated) {
            self->_flags.ignoreLayoutSetContentOffset = YES;
        }
        [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.bounds) * selectedColumn, 0)
                                 animated:animated];

        _selectedColumn = selectedColumn;
        
        if (!animated && !self.scrollView.isDragging) {
            [self _attachHeaderView];
        }
        
        [self _updateScrollsToTop];
        
        [self.contentColumns[self.selectedColumn] willChangeValueForKey:NSStringFromSelector(@selector(contentOffset))];
        [self.contentColumns[self.selectedColumn] didChangeValueForKey:NSStringFromSelector(@selector(contentOffset))];
    }
}

- (void)setHeaderViewEmbeded:(BOOL)headerViewEmbeded
{
    if (_headerViewEmbeded != headerViewEmbeded) {
        _headerViewEmbeded = headerViewEmbeded;
        
        if (self.headerView) {
            if (_headerViewEmbeded) {
                [self.contentColumns[self.selectedColumn].contentScrollView addSubview:self.headerView];
            }
            else {
                [self addSubview:_headerView];
            }
            self.headerPinHeight = _headerPinHeight;
        }
    }
}

- (void)setAllowsScrollHorizontallyOnHeaderViewWhenEmbeded:(BOOL)allowsScrollHorizontallyOnHeaderViewWhenEmbeded
{
    _allowsScrollHorizontallyOnHeaderViewWhenEmbeded = allowsScrollHorizontallyOnHeaderViewWhenEmbeded;
    self.panGestureToFailScrollViewPanGesture.enabled = !allowsScrollHorizontallyOnHeaderViewWhenEmbeded;
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

- (CGFloat)_innerHeaderViewHeight
{
    if (self.headerView) {
        if (self.ignoreSafeAreaTopInset) {
            UIEdgeInsets inset = {0};
            if (@available(iOS 11, *)) {
                inset = self.safeAreaInsets;
            }
            return MAX(_headerViewHeight - inset.top, 0);
        }
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
    
    [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIView<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.headerViewEmbeded) {
            if ([obj.contentScrollView isKindOfClass:[UITableView class]]) {
                UITableView *tableView = (UITableView *)obj;
                if (![tableView.tableHeaderView isKindOfClass:[__RTTableHeaderPlaceholderView class]]) {
                    UIView *tableHeader = tableView.tableHeaderView;
                    self->_flags.ignoreOffsetChangeObserve = YES;
                    tableView.tableHeaderView = nil;    // !IMPORTANT, don't remove
                    self->_flags.ignoreOffsetChangeObserve = NO;
                    
                    tableView.rt_originalTableHeaderView = tableHeader;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableHeader];
                }
                else {
                    self->_flags.ignoreOffsetChangeObserve = YES;
                    tableView.tableHeaderView = nil;
                    self->_flags.ignoreOffsetChangeObserve = NO;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableView.rt_originalTableHeaderView];
                }
                
                UIEdgeInsets inset = RT_CONTENT_INSET(obj.contentScrollView);
                const UIEdgeInsets originalInset = obj.contentScrollView.rt_originalContentInset;
                
                const CGFloat delta = inset.top - self.headerPinHeight;
                inset.top = self.headerPinHeight + originalInset.top;
                
                CGPoint offset = obj.contentScrollView.contentOffset;
                offset.y = MAX(offset.y + delta, - self.headerPinHeight) - originalInset.top;
                
                // Must change offset first!
                self->_flags.ignoreOffsetChangeNotify = YES;
                obj.contentScrollView.contentOffset = offset;
                self->_flags.ignoreOffsetChangeNotify = NO;
                obj.contentScrollView.contentInset = inset;
            }
            else {
                UIEdgeInsets inset = RT_CONTENT_INSET(obj.contentScrollView);
                const UIEdgeInsets originalInset = obj.contentScrollView.rt_originalContentInset;
                
                const CGFloat delta = inset.top - self.headerViewHeight;
                inset.top = self._innerHeaderViewHeight + originalInset.top;
                
                CGPoint offset = obj.contentScrollView.contentOffset;
                offset.y = MAX(offset.y + delta, - self.headerViewHeight) - originalInset.top;
                
                // Must change inset first!
                obj.contentScrollView.contentInset = inset;
                self->_flags.ignoreOffsetChangeNotify = YES;
                obj.contentScrollView.contentOffset = offset;
                self->_flags.ignoreOffsetChangeNotify = NO;
            }
            
            if (self.automaticallyAdjustsScrollIndicatorInsets) {
                obj.contentScrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
            }
        }
        else {
            if ([obj.contentScrollView isKindOfClass:[UITableView class]]) {
                UITableView *tableView = (UITableView *)obj;
                if (![tableView.tableHeaderView isKindOfClass:[__RTTableHeaderPlaceholderView class]]) {
                    UIView *tableHeader = tableView.tableHeaderView;
                    self->_flags.ignoreOffsetChangeObserve = YES;
                    tableView.tableHeaderView = nil;    // !IMPORTANT, don't remove
                    self->_flags.ignoreOffsetChangeObserve = NO;
                    
                    tableView.rt_originalTableHeaderView = tableHeader;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableHeader];
                }
                else {
                    self->_flags.ignoreOffsetChangeObserve = YES;
                    tableView.tableHeaderView = nil;
                    self->_flags.ignoreOffsetChangeObserve = NO;
                    tableView.tableHeaderView = [self _createPlaceholderHeaderViewWithHeight:self.headerViewHeight - self.headerPinHeight
                                                                     originalTableHeaderView:tableView.rt_originalTableHeaderView];
                }
                
                UIEdgeInsets inset = RT_CONTENT_INSET(obj.contentScrollView);
                CGFloat delta = inset.top;
                inset.top = obj.contentScrollView.rt_originalContentInset.top;
                
                CGPoint offset = obj.contentScrollView.contentOffset;
                offset.y = MAX(offset.y + delta, 0) - obj.contentScrollView.rt_originalContentInset.top;
                
                // Must change offset first!
                self->_flags.ignoreOffsetChangeNotify = YES;
                obj.contentScrollView.contentOffset = offset;
                self->_flags.ignoreOffsetChangeNotify = NO;
                obj.contentScrollView.contentInset = inset;
            }
            else {
                UIEdgeInsets inset = RT_CONTENT_INSET(obj.contentScrollView);
                CGFloat delta = inset.top - (self.headerViewHeight - self.headerPinHeight);
                inset.top = self.headerViewHeight - self.headerPinHeight + obj.contentScrollView.rt_originalContentInset.top;
                
                CGPoint offset = obj.contentScrollView.contentOffset;
                offset.y = MAX(offset.y + delta, - (self.headerViewHeight - self.headerPinHeight)) - obj.contentScrollView.rt_originalContentInset.top;
                
                // Must change offset first!
                self->_flags.ignoreOffsetChangeNotify = YES;
                obj.contentScrollView.contentOffset = offset;
                self->_flags.ignoreOffsetChangeNotify = NO;
                obj.contentScrollView.contentInset = inset;
            }
            
            if (self.automaticallyAdjustsScrollIndicatorInsets) {
                UIEdgeInsets inset = obj.contentScrollView.scrollIndicatorInsets;
                inset.top = self.headerViewHeight - self.headerPinHeight;
                obj.contentScrollView.scrollIndicatorInsets = inset;
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

- (void)setContentColumns:(NSArray<__kindof UIView<RTScrollableContent> *> *)contentColumns
{
    if (![_contentColumns isEqualToArray:contentColumns]) {
        [self _detachHeaderView];
        
        [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIView<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
            [obj.contentScrollView removeObserver:self
                                       forKeyPath:SELSTR(contentOffset)
                                          context:observerContext];
            [obj.contentScrollView removeObserver:self
                                       forKeyPath:SELSTR(safeAreaInsets)
                                          context:observerContext];
            obj.contentScrollView.contentInset = obj.contentScrollView.rt_originalContentInset;
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
        
        [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIView<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.contentScrollView.rt_originalContentInset = RT_CONTENT_INSET(obj.contentScrollView);
            
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
                    UIEdgeInsets inset = RT_CONTENT_INSET(obj.contentScrollView);
                    inset.top = self.headerPinHeight + obj.contentScrollView.rt_originalContentInset.top;
                    obj.contentScrollView.contentInset = inset;
                    obj.contentScrollView.contentOffset = CGPointMake(0, self.currentOffset - inset.top);
                }
                else {
                    UIEdgeInsets inset = RT_CONTENT_INSET(obj.contentScrollView);
                    inset.top = obj.contentScrollView.rt_originalContentInset.top;
                    obj.contentScrollView.contentInset = inset;
                    obj.contentScrollView.contentOffset = CGPointMake(0, self.currentOffset - inset.top);
                }
            }
            else {
                if (self.headerViewEmbeded) {
                    UIEdgeInsets inset = RT_CONTENT_INSET(obj.contentScrollView);
                    inset.top = self._innerHeaderViewHeight + obj.contentScrollView.rt_originalContentInset.top;
                    obj.contentScrollView.contentInset = inset;
                    obj.contentScrollView.contentOffset = CGPointMake(0, self.currentOffset - inset.top);
                }
                else {
                    UIEdgeInsets inset = RT_CONTENT_INSET(obj.contentScrollView);
                    inset.top = self._innerHeaderViewHeight - self.headerPinHeight + obj.contentScrollView.rt_originalContentInset.top;
                    obj.contentScrollView.contentInset = inset;
                    obj.contentScrollView.contentOffset = CGPointMake(0, self.currentOffset - inset.top);
                }
            }
            
            if (self.automaticallyAdjustsScrollIndicatorInsets) {
                if (self.headerViewEmbeded) {
                    obj.contentScrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
                }
                else {
                    UIEdgeInsets inset = obj.contentScrollView.scrollIndicatorInsets;
                    inset.top = self._innerHeaderViewHeight - self.headerPinHeight;
                    obj.contentScrollView.scrollIndicatorInsets = inset;
                }
            }
            
            obj.frame = CGRectMake(width * idx, 0, width, height);
            obj.contentScrollView.scrollsToTop = idx == self->_selectedColumn;
            [self.scrollView addSubview:obj];
            
            
            [obj.contentScrollView addObserver:self
                                    forKeyPath:SELSTR(contentOffset)
                                       options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                       context:observerContext];
            [obj.contentScrollView addObserver:self
                                    forKeyPath:SELSTR(safeAreaInsets)
                                       options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                       context:observerContext];
        }];
        
        [self setNeedsLayout];
        [self layoutIfNeeded];  // _notifySelectionChanged depends on contentSize, so layout first!
        
        [self _notifySelectionChanged];
        [self _attachHeaderView];
    }
}

- (NSArray<UIView<RTScrollableContent> *> *)contentColumns
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
        if (self.selectedColumn != NSNotFound) {
            _scrollView.contentOffset = CGPointMake(width * self.selectedColumn, 0);
        }
    }
    [_contentColumns enumerateObjectsUsingBlock:^(__kindof UIView<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect rect = CGRectMake(width * idx, 0, width, self->_scrollView.bounds.size.height);
        if (!CGRectEqualToRect(obj.frame, rect)) {
            obj.frame = rect;
        }
    }];
    
    if (_headerView)
        [_headerView.superview bringSubviewToFront:_headerView];
}

- (void)didMoveToSuperview
{
    if (self.superview && self.ignoreSafeAreaTopInset) {
        self.headerPinHeight = _headerPinHeight;
    }
}

- (void)safeAreaInsetsDidChange
{
    [super safeAreaInsetsDidChange];
    if (self.ignoreSafeAreaTopInset) {
        self.headerPinHeight = _headerPinHeight;
    }
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
    [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIView<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.contentScrollView.scrollsToTop = idx == self->_selectedColumn;
    }];
}

- (void)_syncContentOffset
{
    if (self.currentOffset >= self.headerViewHeight - self.headerPinHeight) {
        self->_flags.ignoreOffsetChangeObserve = YES;
        [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIView<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx != self.selectedColumn) {
                obj.contentScrollView.contentOffset = CGPointMake(obj.contentScrollView.contentOffset.x, MAX(obj.contentScrollView.contentOffset.y, self.headerViewHeight - self.headerPinHeight - RT_CONTENT_INSET(obj.contentScrollView).top));
            }
        }];
        self->_flags.ignoreOffsetChangeObserve = NO;
    }
    else {
        self->_flags.ignoreOffsetChangeObserve = YES;
        [self.contentColumns enumerateObjectsUsingBlock:^(__kindof UIView<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx != self.selectedColumn) {
                obj.contentScrollView.contentOffset = CGPointMake(obj.contentScrollView.contentOffset.x, self.currentOffset - RT_CONTENT_INSET(obj.contentScrollView).top);
            }
        }];
        self->_flags.ignoreOffsetChangeObserve = NO;
    }
}

- (void)_detachHeaderView
{
    if (_headerViewEmbeded) {
        CGRect rect = [self.headerView convertRect:self.headerView.bounds
                                            toView:self];
        self.headerView.frame = rect;
        [self addSubview:self.headerView];
    }
}

- (void)_attachHeaderView
{
    if (_headerViewEmbeded) {
        UIView <RTScrollableContent> *contentView = _contentColumns[self.selectedColumn];
        CGRect rect = [self.headerView convertRect:self.headerView.bounds
                                            toView:contentView.contentScrollView];
        self.headerView.frame = rect;
        [contentView.contentScrollView addSubview:self.headerView];
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
        
        [self.contentColumns[self.selectedColumn] willChangeValueForKey:NSStringFromSelector(@selector(contentOffset))];
        [self.contentColumns[self.selectedColumn] didChangeValueForKey:NSStringFromSelector(@selector(contentOffset))];
    }
}

- (void)onWillRotate:(NSNotification *)notification
{
    [self _attachHeaderView];
    self.currentOffset = RT_CONTENT_INSET(self.contentColumns[self.selectedColumn].contentScrollView).top + self.contentColumns[self.selectedColumn].contentScrollView.contentOffset.y;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self->_flags.ignoreLayoutSetContentOffset = YES;
    [self _detachHeaderView];
    
    [self _syncContentOffset];
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
    if (self->_flags.ignoreLayoutSetContentOffset) {
        self->_flags.ignoreLayoutSetContentOffset = NO;
    } else {
        [self _attachHeaderView];
    }
    self.currentOffset = RT_CONTENT_INSET(self.contentColumns[self.selectedColumn].contentScrollView).top + self.contentColumns[self.selectedColumn].contentScrollView.contentOffset.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(columnView:didScrollToOffset:)]) {
        [self.delegate columnView:self
                didScrollToOffset:UIOffsetMake(self.scrollView.contentOffset.x, _currentOffset)];
    }
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.panGestureToFailScrollViewPanGesture == gestureRecognizer) {
        CGPoint velocity = [self.panGestureToFailScrollViewPanGesture velocityInView:self.headerView];
        return fabs(velocity.x) > fabs(velocity.y);
    }
    return YES;
}

@end


@implementation UIScrollView (RTScrollableContent)

- (UIScrollView *)contentScrollView
{
    return self;
}

@end
