//
//  OSVFullScreenImageViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVFullScreenImageViewController.h"
#import "OSVImageCollectionViewCell.h"
#import "OSVSyncController.h"
#import "OSVFullScreenImageCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define kSpacing 2

@interface  OSVFullScreenImageViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) OSVSyncController         *syncController;
@property (weak, nonatomic) IBOutlet UICollectionView   *collectionViewFullscreen;

@end

@implementation OSVFullScreenImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.syncController = [OSVSyncController sharedInstance];
    UINib *cellNib = [UINib nibWithNibName:@"OSVFullScreenImageCell" bundle:nil];
    
    [self.collectionViewFullscreen registerNib:cellNib forCellWithReuseIdentifier:@"fullScreenID"];
    [self.collectionViewFullscreen setPagingEnabled:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    NSInteger index = [self.datasource indexOfObject:self.selectedPhoto];
//    if (index != NSNotFound) {
//        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
//        [self displayItemAtIndex:indexPath];
//    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Actions

- (IBAction)didTapDissmissButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(willDissmissViewController:)]) {
        [self.delegate willDissmissViewController:self];
    }

    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(didDissmissViewController:)]) {
            [self.delegate didDissmissViewController:self];
        }
    }];
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id<OSVPhoto> photo = self.datasource[indexPath.row];

    OSVFullScreenImageCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"fullScreenID" forIndexPath:indexPath];
    [cell prepareForReuse];
    
    [self.collectionViewFullscreen addGestureRecognizer:cell.scrollView.pinchGestureRecognizer];
    [self.collectionViewFullscreen addGestureRecognizer:cell.scrollView.panGestureRecognizer];
    
    self.imageView = cell.image;
    
    [self.syncController.tracksController loadThumbnailForPhoto:photo intoImageView:cell.image withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
        photo.imageData = nil;
    }];
    [self.syncController.tracksController loadImageDataForPhoto:photo intoImageView:cell.image withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
        photo.thumbnail = nil;
        photo.imageData = nil;
        photo.image = nil;
    }];
    
    return cell;
}



#pragma mark - UICollectionViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self setSelectedCellUsingCollectionView:self.collectionViewFullscreen overindingIndex:YES];

}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionViewFullscreen.frame.size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(OSVFullScreenImageCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionViewFullscreen removeGestureRecognizer:cell.scrollView.pinchGestureRecognizer];
    [self.collectionViewFullscreen removeGestureRecognizer:cell.scrollView.panGestureRecognizer];
}

#pragma mark - Private

- (void)displayItemAtIndex:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
    [self.collectionViewFullscreen scrollToItemAtIndexPath:self.selectedIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)setSelectedCellUsingCollectionView:(UICollectionView *)collectionView overindingIndex:(BOOL)overide {
    BOOL found = NO;
    
    NSIndexPath *indexpath = nil;
    NSArray *array = collectionView.visibleCells;
    
    for (OSVImageCollectionViewCell *cell in array) {
        CGRect frame = cell.frame;
        frame.origin.x = frame.origin.x - collectionView.contentOffset.x;
        frame.size.width = frame.size.width + kSpacing;
        if (!found && CGRectContainsPoint(frame, collectionView.center)) {
            found = YES;
            
            indexpath = [collectionView indexPathForCell:cell];
        }
    }
    
    self.selectedIndexPath = indexpath;
}


#pragma mark - Overide 

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath {
    _selectedIndexPath = selectedIndexPath;
    if (self.datasource.count > selectedIndexPath.item) {
        _selectedPhoto = self.datasource[selectedIndexPath.item];
    }
}

@end
