//
//  RTRootTableViewController.m
//  RTHeadedColumnView
//
//  Created by ricky on 2017/2/22.
//  Copyright © 2017年 rickytan. All rights reserved.
//

#import "RTRootTableViewController.h"
#import "RTViewController.h"

@interface RTRootTableViewController ()
@property (nonatomic, strong) NSArray <NSString *> *rows;
@end

@implementation RTRootTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Demo";

    self.rows = @[@"Static Header",
                  @"Static Header with Collection View",
                  @"Change Header height"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"Cell"];
    }
    
    // Configure the cell...
    cell.textLabel.text = self.rows[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [self.navigationController pushViewController:[[RTViewController alloc] init]
                                                 animated:YES];
            break;
        case 1:
            [self.navigationController pushViewController:[[RTCollectionsViewController alloc] init]
                                                 animated:YES];
            break;
        default:

            break;
    }
}

@end
