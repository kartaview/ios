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

#import "OSVUtils.h"

#import "OSVFullScreenImageCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <AVFoundation/AVFoundation.h>
#import "OSVServerPhoto.h"

#define kSpacing 2

@interface  OSVFullScreenImageViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) OSVSyncController         *syncController;
@property (weak, nonatomic) IBOutlet UICollectionView   *collectionViewFullscreen;
@property (strong, nonatomic) AVAssetImageGenerator     *imageGenerator;

@end

@implementation OSVFullScreenImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.syncController = [OSVSyncController sharedInstance];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setMinimumInteritemSpacing:0.0f];
    [flowLayout setMinimumLineSpacing:0.0f];
    [self.collectionViewFullscreen setPagingEnabled:YES];
    [self.collectionViewFullscreen setCollectionViewLayout:flowLayout];
    
    UINib *cellNib = [UINib nibWithNibName:@"OSVFullScreenImageCell" bundle:nil];
    [self.collectionViewFullscreen registerNib:cellNib forCellWithReuseIdentifier:@"fullScreenID"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.selectedIndexPath) {
        NSIndexPath *indexPath = self.selectedIndexPath;
        [self displayItemAtIndex:indexPath];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionViewFullscreen reloadData];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
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
    return self.sequenceDatasource.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id<OSVPhoto> photo = self.sequenceDatasource.photos[indexPath.row];

    OSVFullScreenImageCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"fullScreenID" forIndexPath:indexPath];
    [cell prepareForReuse];
    
    [self.collectionViewFullscreen addGestureRecognizer:cell.scrollView.pinchGestureRecognizer];
    [self.collectionViewFullscreen addGestureRecognizer:cell.scrollView.panGestureRecognizer];
    
    self.imageView = cell.image;
    if ([photo isKindOfClass:[OSVServerPhoto class]]) {
        [self.syncController.tracksController loadThumbnailForPhoto:photo intoImageView:cell.image withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
            photo.imageData = nil;
        }];
        [self.syncController.tracksController loadImageDataForPhoto:photo intoImageView:cell.image withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
            photo.thumbnail = nil;
            photo.imageData = nil;
            photo.image = nil;
        }];
    } else {
        if (self.imageGenerator) {
            CMTime time = CMTimeMake(1 * indexPath.item, 5);
            CGImageRef imageRef = [self.imageGenerator copyCGImageAtTime:time actualTime:nil error:nil];
            cell.image.image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self setSelectedCellUsingCollectionView:self.collectionViewFullscreen overindingIndex:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionViewFullscreen.frame.size;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(OSVFullScreenImageCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionViewFullscreen removeGestureRecognizer:cell.scrollView.pinchGestureRecognizer];
    [self.collectionViewFullscreen removeGestureRecognizer:cell.scrollView.panGestureRecognizer];
}

#pragma mark - Private

- (void)displayItemAtIndex:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
    
    [self.view layoutIfNeeded];
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
    if (found) {
        self.selectedIndexPath = indexpath;
    }
}

#pragma mark - Overide 

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath {
    _selectedIndexPath = selectedIndexPath;
    if (self.sequenceDatasource.photos.count > selectedIndexPath.item) {
        _selectedPhoto = self.sequenceDatasource.photos[selectedIndexPath.item];
    }
}

- (void)setSequenceDatasource:(id<OSVSequence>)sequenceDatasource {
    _sequenceDatasource = sequenceDatasource;
    if (sequenceDatasource.photos.count && ![sequenceDatasource.photos[0] isKindOfClass:[OSVServerPhoto class]]) {
        
        NSArray<NSURL *> *videoPaths = [self videoPathsFromFolder:[OSVUtils fileNameForTrackID:self.sequenceDatasource.uid]];
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        CMTime insertTime = kCMTimeZero;

        for (NSURL *object in videoPaths) {

            AVAsset *asset = [AVAsset assetWithURL:object];
            NSArray *videos = [asset tracksWithMediaType:AVMediaTypeVideo];
            AVAssetTrack *track = [videos firstObject];
            if (track) {
                CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);

                [videoTrack insertTimeRange:timeRange
                                    ofTrack:track
                                     atTime:insertTime
                                      error:nil];

                insertTime = CMTimeAdd(insertTime, asset.duration);
            } else {
                NSLog(@"bad asset");
            }
        }

        self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:mixComposition];
    } else {
        self.imageGenerator = nil;
    }
}

- (NSArray<NSURL *> *)videoPathsFromFolder:(NSURL *)basePath {
    NSMutableArray *videoFiles = [NSMutableArray array];
    
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey, NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:basePath includingPropertiesForKeys:properties options:(NSDirectoryEnumerationSkipsHiddenFiles) error:nil];
    
    for (NSURL *fileSystemItem in array) {
        BOOL directory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[fileSystemItem path] isDirectory:&directory];
        if (!directory && [fileSystemItem pathExtension] && [[fileSystemItem pathExtension] isEqualToString:@"mp4"]) {
            [videoFiles addObject:fileSystemItem];
        }
    }
    
    [videoFiles sortUsingComparator:^NSComparisonResult(NSURL *obj1, NSURL *obj2) {

        return [[[obj1 lastPathComponent] stringByDeletingPathExtension] integerValue] > [[[obj2 lastPathComponent] stringByDeletingPathExtension] integerValue];
    }];
    
    return videoFiles;
}

@end
