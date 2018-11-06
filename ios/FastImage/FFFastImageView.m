#import "FFFastImageView.h"

@implementation FFFastImageView {
    BOOL hasSentOnLoadStart;
    BOOL hasCompleted;
    BOOL hasErrored;
    NSDictionary* onLoadEvent;
}

- (id) init {
    self = [super init];
    self.resizeMode = RCTResizeModeCover;
    self.clipsToBounds = YES;
    self.layer.masksToBounds = YES;
    return self;
}

- (void)setResizeMode:(RCTResizeMode)resizeMode
{
    if (_resizeMode != resizeMode) {
        _resizeMode = resizeMode;
        self.contentMode = (UIViewContentMode)resizeMode;
    }
}

- (void)setOnFastImageLoadEnd:(RCTBubblingEventBlock)onFastImageLoadEnd {
    _onFastImageLoadEnd = onFastImageLoadEnd;
    if (hasCompleted) {
        _onFastImageLoadEnd(@{});
    }
}

- (void)setOnFastImageLoad:(RCTBubblingEventBlock)onFastImageLoad {
    _onFastImageLoad = onFastImageLoad;
    if (hasCompleted) {
        _onFastImageLoad(onLoadEvent);
    }
}

- (void)setOnFastImageError:(RCTDirectEventBlock)onFastImageError {
    _onFastImageError = onFastImageError;
    if (hasErrored) {
        _onFastImageError(@{});
    }
}

- (void)setOnFastImageLoadStart:(RCTBubblingEventBlock)onFastImageLoadStart {
    if (_source && !hasSentOnLoadStart) {
        _onFastImageLoadStart = onFastImageLoadStart;
        onFastImageLoadStart(@{});
        hasSentOnLoadStart = YES;
    } else {
        _onFastImageLoadStart = onFastImageLoadStart;
        hasSentOnLoadStart = NO;
    }
}

- (void)sendOnLoad:(UIImage *)image {
    onLoadEvent = @{
                    @"width":[NSNumber numberWithDouble:image.size.width],
                    @"height":[NSNumber numberWithDouble:image.size.height]
                    };
    if (_onFastImageLoad) {
        _onFastImageLoad(onLoadEvent);
    }
}

- (void)setSource:(FFFastImageSource *)source {
    if (_source != source) {
        _source = source;
        
        // Load base64 images.
        NSString* url = [_source.url absoluteString];
        if (url && [url hasPrefix:@"data:image"]) {
            if (_onFastImageLoadStart) {
                _onFastImageLoadStart(@{});
                hasSentOnLoadStart = YES;
            } {
                hasSentOnLoadStart = NO;
            }
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:_source.url]];
            [self setImage:image];
            if (_onFastImageProgress) {
                _onFastImageProgress(@{
                                       @"loaded": @(1),
                                       @"total": @(1)
                                       });
            }
            hasCompleted = YES;
            [self sendOnLoad:image];
            
            if (_onFastImageLoadEnd) {
                _onFastImageLoadEnd(@{});
            }
            return;
        }

        // Set cache. - Currently not supported
        // switch (_source.cacheControl) {
        //     case FFFCacheControlWeb:
        //         options |= SDWebImageRefreshCached;
        //         break;
        //     case FFFCacheControlCacheOnly:
        //         options |= SDWebImageCacheMemoryOnly;
        //         break;
        //     case FFFCacheControlImmutable:
        //         break;
        // }
        
        // Set headers.
        [_source.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString* header, BOOL *stop) {
            [[PINRemoteImageManager sharedImageManager] setValue:header forHTTPHeaderField:key];
        }];
        
        if (_onFastImageLoadStart) {
            _onFastImageLoadStart(@{});
            hasSentOnLoadStart = YES;
        } {
            hasSentOnLoadStart = NO;
        }
        hasCompleted = NO;
        hasErrored = NO;
        
        // Load the new source.
        // This will work for:
        //   - https://
        //   - file:///var/containers/Bundle/Application/50953EA3-CDA8-4367-A595-DE863A012336/ReactNativeFastImageExample.app/assets/src/images/fields.jpg
        //   - file:///var/containers/Bundle/Application/545685CB-777E-4B07-A956-2D25043BC6EE/ReactNativeFastImageExample.app/assets/src/images/plankton.gif
        //   - file:///Users/dylan/Library/Developer/CoreSimulator/Devices/61DC182B-3E72-4A18-8908-8A947A63A67F/data/Containers/Data/Application/AFC2A0D2-A1E5-48C1-8447-C42DA9E5299D/Documents/images/E1F1D5FC-88DB-492F-AD33-B35A045D626A.jpg"
        [self pin_setImageFromURL: _source.url completion:^(PINRemoteImageManagerResult * _Nonnull result) {
            if (result.error) {
                hasErrored = YES;
                if (_onFastImageError) {
                    _onFastImageError(@{});
                }
                if (_onFastImageLoadEnd) {
                    _onFastImageLoadEnd(@{});
                }
            } else {
                hasCompleted = YES;
                self.image = result.image;
                [self sendOnLoad:result.image];
                if (_onFastImageLoadEnd) {
                    _onFastImageLoadEnd(@{});
                }
            }
        }];
    }
}

@end

