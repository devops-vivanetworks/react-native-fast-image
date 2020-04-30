#import "FFFastImageViewManager.h"
#import "FFFastImageView.h"

#import <PINRemoteImage/PINRemoteImageManager.h>

@implementation FFFastImageViewManager

RCT_EXPORT_MODULE(FastImageView)

- (FFFastImageView*)view {
  return [[FFFastImageView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(source, FFFastImageSource)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, RCTResizeMode)
RCT_EXPORT_VIEW_PROPERTY(onFastImageLoadStart, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageProgress, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageLoadEnd, RCTDirectEventBlock)
RCT_REMAP_VIEW_PROPERTY(tintColor, imageColor, UIColor)

RCT_EXPORT_METHOD(preload:(nonnull NSArray<FFFastImageSource *> *)sources)
{
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:sources.count];

    [sources enumerateObjectsUsingBlock:^(FFFastImageSource * _Nonnull source, NSUInteger idx, BOOL * _Nonnull stop) {
        [source.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString* header, BOOL *stop) {
            [[PINRemoteImageManager sharedImageManager] setValue:header forHTTPHeaderField:key];
        }];
        [urls setObject:source.url atIndexedSubscript:idx];
    }];

    [[PINRemoteImageManager sharedImageManager] prefetchImagesWithURLs: urls];
}

RCT_EXPORT_METHOD(getSize:(NSURL *) url resolver:(RCTResponseSenderBlock)resolve rejecter:(RCTResponseSenderBlock)reject)
{
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView pin_setImageFromURL: url completion:^(PINRemoteImageManagerResult * _Nonnull result) {
        if (result.error) {
            reject(result.error);
        } else {
            UIImage *image = imageView.image;
            NSNumber *width = @(image.size.width * image.scale);
            NSNumber *height = @(image.size.height * image.scale);
            resolve(@[width, height]);
        }
    }];
}

@end

