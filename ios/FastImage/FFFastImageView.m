#import "FFFastImageView.h"


@interface FFFastImageView()

@property (nonatomic, assign) BOOL hasSentOnLoadStart;
@property (nonatomic, assign) BOOL hasCompleted;
@property (nonatomic, assign) BOOL hasErrored;

@property (nonatomic, strong) NSDictionary* onLoadEvent;

@end

@implementation FFFastImageView

- (id) init {
    self = [super init];
    self.resizeMode = RCTResizeModeCover;
    self.clipsToBounds = YES;
    self.layer.masksToBounds = YES;
    return self;
}

- (void)setResizeMode:(RCTResizeMode)resizeMode {
    if (_resizeMode != resizeMode) {
        _resizeMode = resizeMode;
        self.contentMode = (UIViewContentMode)resizeMode;
    }
}

- (void)setOnFastImageLoadEnd:(RCTDirectEventBlock)onFastImageLoadEnd {
    _onFastImageLoadEnd = onFastImageLoadEnd;
    if (self.hasCompleted) {
        _onFastImageLoadEnd(@{});
    }
}

- (void)setOnFastImageLoad:(RCTDirectEventBlock)onFastImageLoad {
    _onFastImageLoad = onFastImageLoad;
    if (self.hasCompleted) {
        _onFastImageLoad(self.onLoadEvent);
    }
}

- (void)setOnFastImageError:(RCTDirectEventBlock)onFastImageError {
    _onFastImageError = onFastImageError;
    if (self.hasErrored) {
        _onFastImageError(@{});
    }
}

- (void)setOnFastImageLoadStart:(RCTDirectEventBlock)onFastImageLoadStart {
    if (_source && !self.hasSentOnLoadStart) {
        _onFastImageLoadStart = onFastImageLoadStart;
        onFastImageLoadStart(@{});
        self.hasSentOnLoadStart = YES;
    } else {
        _onFastImageLoadStart = onFastImageLoadStart;
        self.hasSentOnLoadStart = NO;
    }
}

- (void)setImageColor:(UIColor *)imageColor {
    if (imageColor != nil) {
        _imageColor = imageColor;
        super.image = [self makeImage:super.image withTint:self.imageColor];
    }
}

- (UIImage*)makeImage:(UIImage *)image withTint:(UIColor *)color {
    UIImage *newImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(image.size, NO, newImage.scale);
    [color set];
    [newImage drawInRect:CGRectMake(0, 0, image.size.width, newImage.size.height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)setImage:(UIImage *)image {
    if (self.imageColor != nil) {
        super.image = [self makeImage:image withTint:self.imageColor];
    } else {
        super.image = image;
    }
}

- (void)sendOnLoad:(UIImage *)image {
    self.onLoadEvent = @{
                         @"width":[NSNumber numberWithDouble:image.size.width],
                         @"height":[NSNumber numberWithDouble:image.size.height]
                         };
    if (self.onFastImageLoad) {
        self.onFastImageLoad(self.onLoadEvent);
    }
}

- (void)setSource:(FFFastImageSource *)source {
    if (_source != source) {
        _source = source;
        
        // Load base64 images.
        NSString* url = [_source.url absoluteString];
        if (url && [url hasPrefix:@"data:image"]) {
            if (self.onFastImageLoadStart) {
                self.onFastImageLoadStart(@{});
                self.hasSentOnLoadStart = YES;
            } {
                self.hasSentOnLoadStart = NO;
            }
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:_source.url]];
            [self setImage:image];
            if (self.onFastImageProgress) {
                self.onFastImageProgress(@{
                                           @"loaded": @(1),
                                           @"total": @(1)
                                           });
            }
            self.hasCompleted = YES;
            [self sendOnLoad:image];
            
            if (self.onFastImageLoadEnd) {
                self.onFastImageLoadEnd(@{});
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
            self.hasSentOnLoadStart = YES;
        } {
            self.hasSentOnLoadStart = NO;
        }
        self.hasCompleted = NO;
        self.hasErrored = NO;
        
        // Load the new source.
        // This will work for:
        //   - https://
        //   - file:///var/containers/Bundle/Application/50953EA3-CDA8-4367-A595-DE863A012336/ReactNativeFastImageExample.app/assets/src/images/fields.jpg
        //   - file:///var/containers/Bundle/Application/545685CB-777E-4B07-A956-2D25043BC6EE/ReactNativeFastImageExample.app/assets/src/images/plankton.gif
        //   - file:///Users/dylan/Library/Developer/CoreSimulator/Devices/61DC182B-3E72-4A18-8908-8A947A63A67F/data/Containers/Data/Application/AFC2A0D2-A1E5-48C1-8447-C42DA9E5299D/Documents/images/E1F1D5FC-88DB-492F-AD33-B35A045D626A.jpg"
        [self pin_setImageFromURL: _source.url completion:^(PINRemoteImageManagerResult * _Nonnull result) {
            if (result.error) {
                self.hasErrored = YES;
                if (_onFastImageError) {
                    _onFastImageError(@{});
                }
                if (_onFastImageLoadEnd) {
                    _onFastImageLoadEnd(@{});
                }
            } else {
                self.hasCompleted = YES;
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

