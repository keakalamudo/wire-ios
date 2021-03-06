// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import <PureLayout/PureLayout.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "MediaPreviewViewController.h"
#import "MediaPreviewView.h"
#import <WireExtensionComponents/WireExtensionComponents.h>
#import "BrowserViewController.h"
#import "MediaPreviewData.h"
#import "MediaThumbnail.h"
#import "WireStyleKit.h"
#import "LinkAttachment.h"
#import "LinkAttachmentCache.h"
#import "YoutubeService.h"
#import "VimeoService.h"



@interface MediaPreviewViewController ()

@property (nonatomic, readonly) MediaPreviewView *mediaPreviewView;

@end

@implementation MediaPreviewViewController

@synthesize linkAttachment = _linkAttachment;

- (void)loadView
{
    self.view = [[MediaPreviewView alloc] initForAutoLayout];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.mediaPreviewView.playButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.view withMultiplier:(9.f / 16.f)];
}

- (void)tearDown;
{
    //NO-OP
}

- (MediaPreviewView *)mediaPreviewView
{
    return (MediaPreviewView *)self.view;
}

- (void)setMediaPreviewData:(MediaPreviewData *)mediaPreviewData
{
    _mediaPreviewData = mediaPreviewData;
    
    self.mediaPreviewView.titleLabel.text = self.mediaPreviewData.title;
    
    switch (self.mediaPreviewData.provider) {
        case MediaPreviewDataProviderYoutube:
            self.mediaPreviewView.providerImageView.image = [WireStyleKit imageOfYoutubeWithColor:[UIColor whiteColor]];
            break;
            
        case MediaPreviewDataProviderVimeo:
            self.mediaPreviewView.providerImageView.image = [WireStyleKit imageOfVimeoWithColor:[UIColor whiteColor]];
            break;
            
        default:
            self.mediaPreviewView.providerImageView.image = nil;
            break;
    }
    
    MediaThumbnail *bestThumbnail = [self.mediaPreviewData bestThumbnailForSize:[UIScreen mainScreen].bounds.size];
    
    if (bestThumbnail.URL) {
        [self.mediaPreviewView.previewImageView setImageWithURL:bestThumbnail.URL];
    }
}

- (void)fetchAttachment
{
    LinkAttachmentCache *cache = [LinkAttachmentCache sharedInstance];
    
    id cachedResource = [cache objectForKey:self.linkAttachment.URL];
    
    if (cachedResource != nil) {
        self.mediaPreviewData = cachedResource;
    } else {
        
        void (^mediaPreviewResponseHandler)(MediaPreviewData *mediaPreviewData, NSError *error) = ^(MediaPreviewData *mediaPreviewData, NSError *error) {
            if (error == nil && mediaPreviewData != nil) {
                self.mediaPreviewData = mediaPreviewData;
                [cache setObject:mediaPreviewData forKey:self.linkAttachment.URL];
            }
        };
        
        if (self.linkAttachment.type == LinkAttachmentTypeYoutubeVideo) {
            [[YoutubeService sharedInstance] mediaPreviewDataForYoutubeVideoURL:self.linkAttachment.URL completion:mediaPreviewResponseHandler];
        }
        else if (self.linkAttachment.type == LinkAttachmentTypeVimeoVideo) {
            [[VimeoService sharedInstance] mediaPreviewDataForVimeoVideoURL:self.linkAttachment.URL completion:mediaPreviewResponseHandler];
        }
    }
}

#pragma mark - Actions

- (IBAction)playVideo:(id)sender
{
    if (! self.linkAttachment.URL) {
        return;
    }
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self.linkAttachment.URL resolvingAgainstBaseURL:YES];
    NSArray *queryItems = components.queryItems == nil ? @[] : components.queryItems;
    components.queryItems = [queryItems arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"autoplay" value:@"1"]];

    BrowserViewController *browserViewController = [[BrowserViewController alloc] initWithURL:components.URL];
    [self.view.window.rootViewController presentViewController:browserViewController animated:YES completion:nil];
}

@end
