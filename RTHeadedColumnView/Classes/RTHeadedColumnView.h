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

#import <UIKit/UIKit.h>

@class RTHeadedColumnView;

NS_ASSUME_NONNULL_BEGIN

@protocol RTHeadedColumnViewDelegate <NSObject>
@optional
- (void)columnView:(RTHeadedColumnView *)columnView didDisplayColumn:(NSInteger)columnIndex;
- (void)columnView:(RTHeadedColumnView *)columnView didScrollToOffset:(UIOffset)offset;

@end

IB_DESIGNABLE
@interface RTHeadedColumnView : UIView

@property (nonatomic, weak, nullable) IBOutlet id<RTHeadedColumnViewDelegate> delegate;
// DO NOT change its delegate, it is used internally!
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, nullable) __kindof UIView *headerView;
@property (nonatomic) IBInspectable BOOL headerViewBounce;

/*!
 @brief      A boolean value indicate that whether embed @c headerView in content view or not.
             If set to @b YES, the header view will be added to the scroll content
             view, otherwise it's added to @b self. Default is @b NO.
 @discussion When set to @b NO, the header view is actually floating on all
             content views, and its frame is changing accordingly to the current
             selected content view's @c contentOffset.
             When set to @b YES, the header view is scrolling with the current selected content
             view just as all other contents does.
 */
@property (nonatomic) IBInspectable BOOL headerViewEmbeded;

/*!
 @brief      A boolean value tells if the content view's @c scrollIndicatorInsets should be adjusted.
             When set to @b NO, it does nothing, and if set to @b YES, the behavior is according to
             @c headerViewEmbeded.
 
             If @c headerViewEmbeded is @b NO, the content view's scroll indicator's top is equal to
             @c headerView 's bottom, because the @c headerView is floating on content view.
             If @c headerViewEmbeded is @b YES, the scroll indicator's top inset is 0.
 
             Default value is @b YES.
 @warning    Set this property before set @c contentColumns, or it won't work.
 */
@property (nonatomic, assign) IBInspectable BOOL automaticallyAdjustsScrollIndicatorInsets;

// Used to change the height of @c headerView after @c headerView has set. When @c headerView has changes,
// this property will also changed to @c headerView.frame.size.height
@property (nonatomic, assign) IBInspectable CGFloat headerViewHeight;
- (void)setHeaderViewHeight:(CGFloat)height animated:(BOOL)animated;

// The height of the @c headerView 's area which will always be visible despite content view scrolls
@property (nonatomic, assign) IBInspectable CGFloat headerPinHeight;

@property (nonatomic, strong, nullable) IBOutletCollection(UIScrollView) NSArray <__kindof UIScrollView *> *contentColumns;

@property (nonatomic, assign) NSInteger selectedColumn;
- (void)setSelectedColumn:(NSInteger)selectedColumn animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
