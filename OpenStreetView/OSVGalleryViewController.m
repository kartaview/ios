//
//  OSVGalleryViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVGalleryViewController.h"
#import "OSVPhoto.h"
#import "OSVSyncController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIBarButtonItem+Aditions.h"
#import "OSVFullScreenImageViewController.h"

#import "OSVGalleryCell.h"
#import "OSVLogger.h"

#define kSpacing 2

@interface OSVGalleryViewController () <UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) OSVSyncController *syncController;
@property (nonatomic, assign) NSInteger         deleteIndex;
@property (nonatomic, strong) UIButton          *editButton;
@property (nonatomic, strong) IBOutlet UIButton *deleteSelectedButton;
@property (nonatomic, strong) UIButton          *cancelButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;


@property (nonatomic, strong) NSArray<UIBarButtonItem *>    *cachedRight;
@property (nonatomic, assign) BOOL                          isInEditMode;
@property (nonatomic, strong) NSArray<UIBarButtonItem *>    *editModeRightNavigationBarView;

@property (nonatomic, strong) NSMutableArray                *selectedPhotos;

@end

@implementation OSVGalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.syncController = [OSVSyncController sharedInstance];
    self.editModeRightNavigationBarView = @[[[UIBarButtonItem alloc] initWithCustomView:self.cancelButton]];
    
    self.isInEditMode = NO;
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:self.editButton];
    [self.navigationItem setRightBarButtonItems:@[buttonItem]];
    [self.navigationItem setLeftBarButtonItem:[UIBarButtonItem barButtonItemWithImageName:@"icon_back" target:self action:@selector(dissmissViewController)]];
    
    [self.deleteSelectedButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.selectedPhotos = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSInteger min = self.datasource.count, max = 0;
    
    for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        if (min > indexPath.row) {
            min = indexPath.row;
        }
        
        if (max < indexPath.row) {
            max = indexPath.row;
        }
    }
    
    for (int i = 0; i < self.datasource.count; i++) {
        if (max + 5 < i  ||  i < min - 5) {
            id<OSVPhoto> photo = self.datasource[i];
            photo.image = nil;
            photo.imageData = nil;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.collectionView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"presentFullScreenImage"]) {
        id<OSVPhoto> photo = sender;
        OSVFullScreenImageViewController *vc = segue.destinationViewController;
        vc.selectedPhoto = photo;
        vc.datasource = self.datasource;
    }
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    OSVGalleryCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"collectionViewCell" forIndexPath:indexPath];
    
    id<OSVPhoto> photo = self.datasource[indexPath.row];
    
    if (self.isInEditMode) {
        cell.isInEditMode = [self.selectedPhotos containsObject:photo];
    }
    
    [self.syncController.tracksController loadThumbnailForPhoto:photo intoImageView:cell.imageView withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
        photo.thumbnail = nil;
        photo.imageData = nil;
    }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id<OSVPhoto> photo = self.datasource[indexPath.row];

    if (self.isInEditMode) {
        if ([self.selectedPhotos containsObject:photo]) {
            [self.selectedPhotos removeObject:photo];
        } else {
            [self.selectedPhotos addObject:photo];
        }
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        [self performSegueWithIdentifier:@"presentFullScreenImage" sender:photo];
    }
}

#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((collectionView.frame.size.width - 3*kSpacing)/4.0, (collectionView.frame.size.width - 3*kSpacing)/4.0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return kSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return kSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(kSpacing,0,0,0);
}

#pragma mark - ui

- (UIButton *)editButton {
    if (!_editButton) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 30.0)];
        [button setTitle:NSLocalizedString(@"Select", nil) forState:UIControlStateNormal];
        [button addTarget:self action:@selector(didTapEditBarButton:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

        _editButton = button;
    }
    
    return _editButton;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 30.0)];
        [button setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [button addTarget:self action:@selector(didTapCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        [button.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:16]];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        _cancelButton = button;
    }
    
    return _cancelButton;
}

#pragma mark - Tap Gesture Recognizer

- (void)didTapEditBarButton:(id)sender {
    self.cachedRight = self.navigationItem.rightBarButtonItems;
    [self.navigationItem setRightBarButtonItems:self.editModeRightNavigationBarView];
    self.isInEditMode = YES;
    self.deleteSelectedButton.hidden = NO;
    [self.collectionView reloadData];
}

- (IBAction)didTapDeleteButton:(id)sender {
    for (id<OSVPhoto> photo in self.selectedPhotos) {
        [self.syncController.tracksController deletePhoto:photo withCompletionBlock:^(NSError *error) {
            if (!error) {
                [self.datasource removeObject:photo];
                [self.collectionView reloadData];
                self.didChanges = YES;
            } else {
                NSLog(@"error while deleting photo");
            }
        }];
    }
    self.selectedPhotos = [NSMutableArray array];
}

- (void)didTapCancelButton:(id)sender {
    [self.navigationItem setRightBarButtonItems:self.cachedRight];
    self.isInEditMode = NO;
    self.deleteSelectedButton.hidden = YES;
    [self.collectionView reloadData];
}

- (void)dissmissViewController {
    if (self.isPresented) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
        }];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
