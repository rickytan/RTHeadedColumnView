//
//  RTColumnViewController.h
//  RTHeadedColumnView
//
//  Created by Ricky on 2019/10/25.
//

#import <UIKit/UIKit.h>

@protocol RTScrollableContent;

@class RTHeadedColumnView;

NS_ASSUME_NONNULL_BEGIN


@interface RTColumnViewController : UIViewController
@property (nonatomic, readonly, strong) RTHeadedColumnView *columnView;

@property (nonatomic, strong) NSArray <__kindof UIViewController <RTScrollableContent> *> *viewControllers;
@property (nonatomic, readonly) __kindof UIViewController <RTScrollableContent> *currentViewController;

@property (nonatomic) BOOL autoHideVerticalScrollIndicator;

@property (nonatomic) NSInteger currentIndex;
- (void)setCurrentIndex:(NSInteger)currentIndex animated:(BOOL)animated;

- (void)contentDidScrollToOffset:(UIOffset)offset;
- (void)contentDidDisplayColumn:(NSInteger)columnIndex;

@end


@interface UIView (RTScrollableContent) <RTScrollableContent>
@end

@interface UIViewController (RTScrollableContent) <RTScrollableContent>
@property (nonatomic, strong) UIView <RTScrollableContent> *view;
@end

@interface UITableViewController (RTScrollableContent)
@end

@interface UICollectionViewController (RTScrollableContent)
@end


NS_ASSUME_NONNULL_END
