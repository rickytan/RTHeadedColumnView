//
//  RTColumnViewController.m
//  RTHeadedColumnView
//
//  Created by Ricky on 2019/10/25.
//

#import "RTHeadedColumnView.h"

@interface RTColumnViewController () <RTHeadedColumnViewDelegate>
@property (nonatomic, strong) RTHeadedColumnView *columnView;
@property (nonatomic) NSInteger willAppearIndex;
@property (nonatomic) NSInteger willDisappearIndex;

@property (nonatomic) NSMapTable<__kindof UIViewController<RTScrollableContent> *, NSNumber *> *showsVerticalScrollIndicatorMapTable;
@end

@implementation RTColumnViewController
{
    struct {
        BOOL    _currentVCNeedsAppear:1;
        BOOL    _isAppeared:1;
    } _flags;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _willAppearIndex = _willDisappearIndex = -1;
    }
    return self;
}

- (void)dealloc
{
    self.columnView.contentColumns = nil;
}

- (void)loadView
{
    [super loadView];
    
    self.columnView = [[RTHeadedColumnView alloc] initWithFrame:self.view.bounds];
    self.columnView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.columnView.delegate = self;
    self.columnView.headerViewEmbeded = YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    self.columnView.ignoreSafeAreaTopInset = self.automaticallyAdjustsScrollViewInsets && (self.edgesForExtendedLayout & UIRectEdgeTop);
#pragma clang diagnostic pop
    [self.view addSubview:self.columnView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSMutableArray <UIView <RTScrollableContent> *> *arr = [NSMutableArray arrayWithCapacity:self.viewControllers.count];
    [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [arr addObject:obj.view];
    }];
    self.columnView.contentColumns = [arr copy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.currentViewController) {
        [self rt_beginAppearanceTransition:self.currentViewController isAppearing:YES animated:animated];
    } else {
        _flags._currentVCNeedsAppear = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _flags._isAppeared = YES;
    [self.currentViewController endAppearanceTransition];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self rt_beginAppearanceTransition:self.currentViewController isAppearing:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _flags._isAppeared = NO;
    [self.currentViewController endAppearanceTransition];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    }
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    }];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

- (void)setEdgesForExtendedLayout:(UIRectEdge)edgesForExtendedLayout
{
    [super setEdgesForExtendedLayout:edgesForExtendedLayout];
    if (self.isViewLoaded) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        self.columnView.ignoreSafeAreaTopInset = self.automaticallyAdjustsScrollViewInsets && (edgesForExtendedLayout & UIRectEdgeTop);
#pragma clang diagnostic pop
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)setAutomaticallyAdjustsScrollViewInsets:(BOOL)automaticallyAdjustsScrollViewInsets
#pragma clang diagnostic pop
{
    [super setAutomaticallyAdjustsScrollViewInsets:automaticallyAdjustsScrollViewInsets];
    if (self.isViewLoaded) {
        self.columnView.ignoreSafeAreaTopInset = automaticallyAdjustsScrollViewInsets && (self.edgesForExtendedLayout & UIRectEdgeTop);
    }
}

- (void)setViewControllers:(NSArray<__kindof UIViewController<RTScrollableContent> *> *)viewControllers
{
    NSMutableSet <UIViewController *> *set = [NSMutableSet setWithArray:_viewControllers];
    [set minusSet:[NSSet setWithArray:viewControllers]];
    
    _viewControllers = viewControllers;
    
    [[set allObjects] enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj willMoveToParentViewController:nil];
        [obj removeFromParentViewController];
    }];
    
    [_viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.parentViewController != self) {
            [self addChildViewController:obj];
            [obj didMoveToParentViewController:self];
        }
    }];
    
    if (self.isViewLoaded) {
        NSMutableArray <UIView <RTScrollableContent> *> *arr = [NSMutableArray arrayWithCapacity:viewControllers.count];
        [viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [arr addObject:obj.view];
        }];
        self.columnView.contentColumns = [arr copy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->_flags._currentVCNeedsAppear) {
                self->_flags._currentVCNeedsAppear = NO;
                [self rt_beginAppearanceTransition:self.currentViewController isAppearing:YES animated:NO];
                
                if (self->_flags._isAppeared) {
                    [self.currentViewController endAppearanceTransition];
                }
            }
        });
    }
}

- (UIViewController<RTScrollableContent> *)currentViewController
{
    if (0 <= self.currentIndex && self.currentIndex < self.viewControllers.count) {
        return self.viewControllers[self.currentIndex];
    }
    return nil;
}

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    [self setCurrentIndex:currentIndex animated:NO];
}

- (NSInteger)currentIndex
{
    return self.columnView.selectedColumn;
}

- (void)setCurrentIndex:(NSInteger)currentIndex animated:(BOOL)animated
{
    if (self.currentIndex == currentIndex) {
        return;
    }
    
    NSInteger oldIndex = self.currentIndex;
    NSInteger newIndex = currentIndex;
    
    if (_willAppearIndex >= 0 && _willAppearIndex != newIndex) {
        [self.viewControllers[self.willAppearIndex] endAppearanceTransition];
    }
    if (_willDisappearIndex >= 0 && _willDisappearIndex != oldIndex) {
        [self.viewControllers[self.willDisappearIndex] endAppearanceTransition];
    }
    
    [self rt_beginAppearanceTransition:self.viewControllers[oldIndex] isAppearing:NO animated:animated];
    [self rt_beginAppearanceTransition:self.viewControllers[newIndex] isAppearing:YES animated:animated];
    
    [self.columnView setSelectedColumn:currentIndex animated:animated];
    
    if (!animated) {
        [self.viewControllers[oldIndex] endAppearanceTransition];
        [self.viewControllers[newIndex] endAppearanceTransition];
    }
    else {
        _willAppearIndex = newIndex;
        _willDisappearIndex = oldIndex;
    }
}

- (void)setWillAppearIndex:(NSInteger)willAppearIndex
{
    if (_willAppearIndex != willAppearIndex) {
        if (_willAppearIndex >= 0) {
            if ((willAppearIndex < _willDisappearIndex && _willAppearIndex > _willDisappearIndex) ||
                (willAppearIndex > _willDisappearIndex && _willAppearIndex < _willDisappearIndex)) {
                [self rt_beginAppearanceTransition:self.viewControllers[_willAppearIndex] isAppearing:NO animated:NO];
            }
            [self.viewControllers[_willAppearIndex] endAppearanceTransition];
        }
        
        _willAppearIndex = willAppearIndex;
        
        if (willAppearIndex >= 0) {
            [self rt_beginAppearanceTransition:self.viewControllers[willAppearIndex] isAppearing:YES animated:YES];
        }
    }
}

- (void)setWillDisappearIndex:(NSInteger)willDisappearIndex
{
    if (_willDisappearIndex != willDisappearIndex) {
        if (_willDisappearIndex >= 0) {
            [self.viewControllers[_willDisappearIndex] endAppearanceTransition];
        }
        
        _willDisappearIndex = willDisappearIndex;
        
        if (willDisappearIndex >= 0) {
            [self rt_beginAppearanceTransition:self.viewControllers[willDisappearIndex] isAppearing:NO animated:YES];
        }
    }
}

- (void)rt_beginAppearanceTransition:(UIViewController <RTScrollableContent> *)vc isAppearing:(BOOL)isAppearing animated:(BOOL)animated {
    [vc beginAppearanceTransition:isAppearing animated:animated];
    [self autoShowHideVerticalScrollIndicatorIfNeeded:vc bShow:isAppearing];
}

- (void)autoShowHideVerticalScrollIndicatorIfNeeded:(UIViewController <RTScrollableContent> *)vc bShow:(BOOL)bShow {
    if (!self.autoHideVerticalScrollIndicator) {
        return;
    }
    if (self.showsVerticalScrollIndicatorMapTable.count == 0) {
        [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController<RTScrollableContent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSNumber *value = @(obj.contentScrollView.showsVerticalScrollIndicator);
            [self.showsVerticalScrollIndicatorMapTable setObject:value forKey:obj];
        }];
    }
    BOOL showsVerticalScrollIndicator = [[self.showsVerticalScrollIndicatorMapTable objectForKey:vc] boolValue];
    if (!showsVerticalScrollIndicator) {
        return;
    }
    vc.contentScrollView.showsVerticalScrollIndicator = bShow;
}

- (NSMapTable *)showsVerticalScrollIndicatorMapTable {
    if (!_showsVerticalScrollIndicatorMapTable) {
        _showsVerticalScrollIndicatorMapTable = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
    }
    return _showsVerticalScrollIndicatorMapTable;
}

- (void)contentDidDisplayColumn:(NSInteger)columnIndex
{
    if (self.autoHideVerticalScrollIndicator) {
        for (__kindof UIViewController<RTScrollableContent> * _Nonnull obj in self.showsVerticalScrollIndicatorMapTable.keyEnumerator) {
            obj.contentScrollView.showsVerticalScrollIndicator = [[self.showsVerticalScrollIndicatorMapTable objectForKey:obj] boolValue];
        }
        [self.showsVerticalScrollIndicatorMapTable removeAllObjects];
    }
}

- (void)contentDidScrollToOffset:(UIOffset)offset
{
    
}

#pragma mark - RTHeadedColumnViewDelegate

- (void)columnView:(RTHeadedColumnView *)columnView didDisplayColumn:(NSInteger)columnIndex
{
    if (_willAppearIndex >= 0 && _willAppearIndex != columnIndex) {
        [self rt_beginAppearanceTransition:self.viewControllers[self.willAppearIndex] isAppearing:NO animated:NO];
    }
    if (_willDisappearIndex >= 0 && _willDisappearIndex == columnIndex) {
        [self rt_beginAppearanceTransition:self.viewControllers[self.willDisappearIndex] isAppearing:YES animated:NO];
    }
    
    if (_willAppearIndex >= 0) {
        [self.viewControllers[self.willAppearIndex] endAppearanceTransition];
    }
    if (_willDisappearIndex >= 0) {
        [self.viewControllers[self.willDisappearIndex] endAppearanceTransition];
    }
    
    _willAppearIndex = _willDisappearIndex = -1;
    
    [self contentDidDisplayColumn:columnIndex];
}

- (void)columnView:(RTHeadedColumnView *)columnView didScrollToOffset:(UIOffset)offset
{
    const CGFloat width = columnView.scrollView.bounds.size.width;
    const CGFloat currentOffset = width * self.currentIndex;
    const BOOL isDragging = columnView.scrollView.isDragging;
    const BOOL isDecelerating = columnView.scrollView.isDecelerating;
    
    CGFloat rem = remainder(offset.horizontal, width);
    if (rem == 0) {
        NSInteger newCurrentIndex = (NSInteger)floor(offset.horizontal / width);
        // 滚动一下，然后松手回到原位置
        if ((isDragging || isDecelerating) && newCurrentIndex == self.currentIndex) {
            if (_willAppearIndex >= 0) {
                [self rt_beginAppearanceTransition:self.viewControllers[self.willAppearIndex] isAppearing:NO animated:NO];
            }
            if (_willDisappearIndex >= 0) {
                [self rt_beginAppearanceTransition:self.viewControllers[self.willDisappearIndex] isAppearing:YES animated:NO];
            }
            
            if (_willAppearIndex >= 0) {
                [self.viewControllers[self.willAppearIndex] endAppearanceTransition];
            }
            if (_willDisappearIndex >= 0) {
                [self.viewControllers[self.willDisappearIndex] endAppearanceTransition];
            }
            
            _willAppearIndex = _willDisappearIndex = -1;
        }
        else if (!isDragging && newCurrentIndex != self.currentIndex) {
            
//            [self.viewControllers[self.currentIndex] endAppearanceTransition];
//            [self.viewControllers[newCurrentIndex] endAppearanceTransition];
        }
        else if (!isDragging) {
            if (_willAppearIndex >= 0) {
                [self.viewControllers[self.willAppearIndex] endAppearanceTransition];
            }
            if (_willDisappearIndex >= 0) {
                [self.viewControllers[self.willDisappearIndex] endAppearanceTransition];
            }
            
            _willAppearIndex = _willDisappearIndex = -1;
        }
        // else 不处理，会走 didDisplayColumn 的逻辑
        else {
            
        }
    }
    else if (isDragging && offset.horizontal > currentOffset) {
        self.willAppearIndex = (NSInteger)ceil(offset.horizontal / width);
        self.willDisappearIndex = (NSInteger)floor(offset.horizontal / width);
    }
    else if (isDragging && offset.horizontal < currentOffset) {
        self.willAppearIndex = (NSInteger)floor(offset.horizontal / width);
        self.willDisappearIndex = (NSInteger)ceil(offset.horizontal / width);
    }
    
    [self contentDidScrollToOffset:offset];
}

@end



@implementation UIView (RTScrollableContent)

- (UIScrollView *)contentScrollView
{
    UIViewController *vc = (UIViewController *)self.nextResponder;
    if ([vc isKindOfClass:[UIViewController class]]) {
        return [vc contentScrollView];
    }
    NSAssert(false, @"Protocol RTScrollableContent's method not implemented!");
    return nil;
}

@end


@implementation UITableViewController (RTScrollableContent)

- (UIScrollView *)contentScrollView
{
    return self.tableView;
}

@end

@implementation UICollectionViewController (RTScrollableContent)

- (UIScrollView *)contentScrollView
{
    return self.collectionView;
}

@end
