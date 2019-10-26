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
@end

@implementation RTColumnViewController

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
    
    [self.currentViewController beginAppearanceTransition:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.currentViewController endAppearanceTransition];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.currentViewController beginAppearanceTransition:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
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
    }
}

- (UIViewController<RTScrollableContent> *)currentViewController
{
    return self.viewControllers[self.currentIndex];
}

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    self.columnView.selectedColumn = currentIndex;
}

- (NSInteger)currentIndex
{
    return self.columnView.selectedColumn;
}

- (void)setWillAppearIndex:(NSInteger)willAppearIndex
{
    if (_willAppearIndex != willAppearIndex) {
        if (_willAppearIndex >= 0) {
            [self.viewControllers[_willAppearIndex] endAppearanceTransition];
        }
        
        _willAppearIndex = willAppearIndex;
        
        if (willAppearIndex >= 0) {
            [self.viewControllers[willAppearIndex] beginAppearanceTransition:YES animated:YES];
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
            [self.viewControllers[willDisappearIndex] beginAppearanceTransition:NO animated:YES];
        }
    }
}

- (void)contentDidDisplayColumn:(NSInteger)columnIndex
{
    
}

- (void)contentDidScrollToOffset:(UIOffset)offset
{
    
}

#pragma mark - RTHeadedColumnViewDelegate

- (void)columnView:(RTHeadedColumnView *)columnView didDisplayColumn:(NSInteger)columnIndex
{
    if (_willAppearIndex >= 0 && _willAppearIndex != columnIndex) {
        [self.viewControllers[self.willAppearIndex] beginAppearanceTransition:NO animated:NO];
    }
    if (_willDisappearIndex >= 0 && _willDisappearIndex == columnIndex) {
        [self.viewControllers[self.willDisappearIndex] beginAppearanceTransition:YES animated:NO];
    }
    
    if (_willAppearIndex >= 0) {
        [self.viewControllers[self.willAppearIndex] endAppearanceTransition];
    }
    if (_willDisappearIndex >= 0) {
        [self.viewControllers[self.willDisappearIndex] endAppearanceTransition];
    }
    
    _willAppearIndex = _willDisappearIndex = -1;
}

- (void)columnView:(RTHeadedColumnView *)columnView didScrollToOffset:(UIOffset)offset
{
    const CGFloat width = columnView.scrollView.bounds.size.width;
    const CGFloat currentOffset = width * self.currentIndex;
    
    CGFloat rem = remainder(offset.horizontal, width);
    if (rem == 0) {
        NSInteger newCurrentIndex = (NSInteger)floor(offset.horizontal / width);
        // 滚动一下，然后松手回到原位置
        if (newCurrentIndex == self.currentIndex) {
            if (_willAppearIndex >= 0) {
                [self.viewControllers[self.willAppearIndex] beginAppearanceTransition:NO animated:NO];
            }
            if (_willDisappearIndex >= 0) {
                [self.viewControllers[self.willDisappearIndex] beginAppearanceTransition:YES animated:NO];
            }
            
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
    else if (offset.horizontal > currentOffset) {
        self.willAppearIndex = (NSInteger)ceil(offset.horizontal / width);
        self.willDisappearIndex = (NSInteger)floor(offset.horizontal / width);
    }
    else if (offset.horizontal < currentOffset) {
        self.willAppearIndex = (NSInteger)floor(offset.horizontal / width);
        self.willDisappearIndex = (NSInteger)ceil(offset.horizontal / width);
    }
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
