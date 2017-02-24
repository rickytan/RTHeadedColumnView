//
//  RTDemoTableView.h
//  RTHeadedColumnView
//
//  Created by ricky on 16/10/19.
//  Copyright © 2016年 rickytan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RTDemoTableView : UITableView <UITableViewDelegate, UITableViewDataSource>

@end

@interface RTHeaderDemoTableView : UITableView <UITableViewDelegate, UITableViewDataSource>

@end

@interface RTDemoCollectionView : UICollectionView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end
