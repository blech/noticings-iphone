//
//  StreamViewController.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamViewController.h"
#import "StreamPhotoViewCell.h"
#import "StreamPhoto.h"
#import "CacheManager.h"
#import "PhotoUploadCell.h"
#import "ContactsStreamManager.h"
#import "StreamPhotoViewController.h"

@interface StreamViewController (Private)
- (void)setQueueButtonState;
- (void)queueButtonPressed;
@end

@implementation StreamViewController

@synthesize streamManager;

-(id)initWithPhotoStreamManager:(PhotoStreamManager*)manager;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.streamManager = manager;
        self.streamManager.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    isRoot = NO;
    if (!self.streamManager) {
        // we were initialized from the nib, without going through the custom init above,
        // so we must be the root controller.
        self.streamManager = [ContactsStreamManager sharedContactsStreamManager];
        self.streamManager.delegate = self;
        isRoot = YES;
    }
    
    // hack the internals of the pull-to-refresh controller so I can display a second line.
    // TODO - ideally, I'd display the second line in a fainter colour / not bold / something.
    self.refreshLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.refreshLabel.numberOfLines = 2;
    
    if (isRoot) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(uploadQueueDidChange) 
                                                     name:@"queueCount" 
                                                   object:nil];
    }

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
}

- (void)viewDidUnload
{
    // we need to unsubscribe, in case they fire and it no longer exists
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

-(void)updatePullText;
{
    self.textPull = [NSString stringWithFormat:@"Pull to refresh..\nLast refreshed %@", streamManager.lastRefreshDisplay];
    self.textRelease = [NSString stringWithFormat:@"Release to refresh..\nLast refreshed %@", streamManager.lastRefreshDisplay];
    self.textLoading = [NSString stringWithFormat:@"Loading..\nLast refreshed %@", streamManager.lastRefreshDisplay];
}

-(void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    [self updatePullText];
}

-(void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    [self.streamManager maybeRefresh];
	[self.tableView reloadData]; // reload here to update the "no photos" message to be "loading"
}

-(void)viewWillDisappear:(BOOL)animated;
{
    [[CacheManager sharedCacheManager] flushQueue]; // we don't need any of the pending photos any more.
    [super viewWillDisappear:animated];
}


// delegate callback method from PhotoStreamManager
- (void)newPhotos;
{
    NSLog(@"new photos loaded for %@", self.class);
    [self stopLoading]; // for the pull-to-refresh thing
    [self updatePullText];

    // are we the currently-active view controller? Precache if so.
    if (self.isViewLoaded && self.view.window) {
        NSLog(@"View is visible. Pre-caching.");
        [self.streamManager precache];
    }

	[self.tableView reloadData];
}


- (void)uploadQueueDidChange
{
    [self.tableView reloadData];
}

- (void)refresh;
{
    [streamManager refresh];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[CacheManager sharedCacheManager] flushMemoryCache];
}

- (StreamPhoto *)streamPhotoAtIndexPath:(NSIndexPath*)indexPath {
    NSMutableArray *photos = streamManager.photos;
    if ([photos count] == 0) {
        return nil;
    }
    
    if (!isRoot) {
        // for the non-root controller, just index into Photos.
        NSInteger photoIndex = indexPath.section;
        return [photos objectAtIndex:photoIndex];
    }

    UploadQueueManager *uploadQueueManager = [UploadQueueManager sharedUploadQueueManager];
    NSMutableArray *photoUploads = uploadQueueManager.photoUploads;
    if (indexPath.section < [photoUploads count]) {
        // upload cell
        return nil;
    }

    NSInteger photoIndex = indexPath.section - [photoUploads count];
    return [photos objectAtIndex:photoIndex];
}

- (PhotoUpload*)photoUploadAtIndexPath:(NSIndexPath*)indexPath;
{
    // only the root controller has upload cells
    if (!isRoot) {
        return nil;
    }

    UploadQueueManager *uploadQueueManager = [UploadQueueManager sharedUploadQueueManager];
    NSMutableArray *photoUploads = uploadQueueManager.photoUploads;
    if ([photoUploads count] == 0) {
        return nil;
    }
    if (indexPath.section < [photoUploads count]) {
        return [uploadQueueManager.photoUploads objectAtIndex:indexPath.section];
    }
    return nil;
}

// return a table cell for a photo without firing off a background "fetch the URL from flickr"
// call. this is a nasty fudge so that I can get the cell height without causing network activity,
// but it's a lot of overhead.
-(StreamPhotoViewCell*)passiveTableCellForPhoto:(StreamPhoto*)photo;
{
    static NSString *MyIdentifier = @"StreamPhotoViewCell";
    StreamPhotoViewCell *cell = (StreamPhotoViewCell *)[self.tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"StreamPhotoViewCell" owner:self options:nil];
        cell = photoViewCell;
        photoViewCell = nil;
    }
    [cell populateFromPhoto:photo];
    return cell;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSMutableArray *photos = self.streamManager.photos;
	NSInteger photosCount = photos.count == 0 ? 1 : photos.count;
    if (isRoot) {
        UploadQueueManager *uploadQueueManager = [UploadQueueManager sharedUploadQueueManager];
        return photosCount + [uploadQueueManager.photoUploads count];
    } else {
        return photosCount;
    }
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PhotoUpload *upload = [self photoUploadAtIndexPath:indexPath];
    if (upload) {
        static NSString *MyIdentifier = @"StreamPhotoUploadCell";
        PhotoUploadCell *cell = (PhotoUploadCell *)[self.tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"PhotoUploadCell" owner:self options:nil];
            cell = photoUploadCell;
            photoUploadCell = nil;
        }
        [cell displayPhotoUpload:upload];
        return cell;
    }
    
    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (photo) {
        StreamPhotoViewCell *cell = [self passiveTableCellForPhoto:photo];
        [cell loadImages];
        return cell;
    }
    
    // no photos to display. Placeholder.
    // TODO - if this is the first run, this might be because we haven't loaded any
    // photos yet.
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    if (self.streamManager.inProgress) {
        cell.textLabel.text = @"Loading photos...";
    } else {
        cell.textLabel.text = @"No photos to display.";
    }
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return [cell autorelease];
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (photo) {
        return [StreamPhotoViewCell cellHeightForPhoto:photo];
    }
    return 100; // upload cells.
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    PhotoUpload *upload = [self photoUploadAtIndexPath:indexPath];
    if (upload) {
        // just flash the cell.
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (!photo) return;
    
    StreamPhotoViewController *vc = [[StreamPhotoViewController alloc] initWithPhoto:photo streamManager:self.streamManager];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];

}

# pragma mark memory management

- (void)dealloc {
    NSLog(@"deallocing %@", self.class);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.streamManager.delegate = nil;
    self.streamManager = nil;
    [super dealloc];
}


@end

