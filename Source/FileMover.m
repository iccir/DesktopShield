// Copyright (c) 2021-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "FileMover.h"

@interface FileMover () <NSFileManagerDelegate>

@end


@implementation FileMover {
    NSFileManager *_fileManager;
    NSOperationQueue *_workQueue;
    NSURL *_temporaryURL;
}


+ (instancetype) sharedInstance
{
    static FileMover *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sSharedInstance = [[FileMover alloc] init];
    });
    
    return sSharedInstance;
}


- (instancetype) init
{
    if ((self = [super init])) {
        _fileManager = [[NSFileManager alloc] init];
        [_fileManager setDelegate:self];
    }
    
    return self;
}


#pragma mark - Private Methods

- (NSOperationQueue *) _workQueue
{
    if (!_workQueue) {
        _workQueue = [[NSOperationQueue alloc] init];
        [_workQueue setQualityOfService:NSQualityOfServiceUserInitiated];
    }

    return _workQueue;
}


- (NSURL *) _temporaryURL
{
    if (!_temporaryURL) {
        _temporaryURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"Promises"];
        
        NSError *error = nil;
        [_fileManager createDirectoryAtURL:_temporaryURL withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return _temporaryURL;
}


- (BOOL) fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
    return YES;
}


- (BOOL) fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
    return YES;
}


- (void) _handleFileURL:(NSURL *)fileURL destination:(NSURL *)destination shouldCopy:(BOOL)shouldCopy
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *filename = [fileURL lastPathComponent];

        NSString *basename  = [filename stringByDeletingPathExtension];
        NSString *extension = [filename pathExtension];
        
        NSString *basenameToTry = basename;
        
        NSString *pathToTry = [destination path];
        pathToTry = [pathToTry stringByAppendingPathComponent:basenameToTry];
        pathToTry = [pathToTry stringByAppendingPathExtension:extension];
        
        NSInteger i = 2;
        while ([_fileManager fileExistsAtPath:pathToTry] && (i < 1000)) {
            basenameToTry = [basename stringByAppendingFormat:@" %ld", i++];
            
            pathToTry = [destination path];
            pathToTry = [pathToTry stringByAppendingPathComponent:basenameToTry];
            pathToTry = [pathToTry stringByAppendingPathExtension:extension];
        }
        
        NSURL *destination = [NSURL fileURLWithPath:pathToTry];
    
        if (shouldCopy) {
            [_fileManager copyItemAtURL:fileURL toURL:destination error:nil];
        } else {
            [_fileManager moveItemAtURL:fileURL toURL:destination error:nil];
        }
    }];
}


#pragma mark - Public Methods

- (NSDragOperation) dragOperationWithInfo:(id <NSDraggingInfo>)sender destination:(NSURL *)destination
{
    NSString *destinationVolume = nil;
    [destination getResourceValue:&destinationVolume forKey:NSURLVolumeIdentifierKey error:nil];

    if (!destinationVolume) return YES;

    NSArray *classes = @[
        [NSURL class],
        [NSFilePromiseReceiver class]
    ];
    
    NSDictionary *options = @{
        NSPasteboardURLReadingFileURLsOnlyKey: @YES
    };

    __block BOOL hasPromise = NO;
    __block BOOL hasDifferentVolume = NO;

    [sender enumerateDraggingItemsWithOptions:0 forView:nil classes:classes searchOptions:options usingBlock:^(NSDraggingItem *draggingItem, NSInteger i, BOOL *stop) {
        id item = [draggingItem item];
        
        if ([item isKindOfClass:[NSFilePromiseReceiver class]]) {
            hasPromise = YES;
            *stop = YES;

        } else if ([item isKindOfClass:[NSURL class]]) {
            NSString *sourceVolume = nil;
            [(NSURL *)item getResourceValue:&sourceVolume forKey:NSURLVolumeIdentifierKey error:nil];

            if (![sourceVolume isEqual:destinationVolume]) {
                hasDifferentVolume = YES;
                *stop = YES;
            }
        }
    }];

    if (hasPromise) {
        return NSDragOperationCopy;
    } else {
        BOOL hasOptionKey = ([NSEvent modifierFlags] & NSEventModifierFlagOption) > 0;

        if (hasDifferentVolume) {
            return hasOptionKey ? NSDragOperationMove : NSDragOperationCopy;
        } else {
            return hasOptionKey ? NSDragOperationCopy : NSDragOperationMove;
        }
    }
}


- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender destination:(NSURL *)destination
{
    BOOL shouldCopy = [self dragOperationWithInfo:sender destination:destination] == NSDragOperationCopy;

    NSArray *classes = @[
        [NSURL class],
        [NSFilePromiseReceiver class]
    ];
    
    NSDictionary *options = @{
        NSPasteboardURLReadingFileURLsOnlyKey: @YES
    };

    [sender enumerateDraggingItemsWithOptions:0 forView:nil classes:classes searchOptions:options usingBlock:^(NSDraggingItem *draggingItem, NSInteger i, BOOL *stop) {
        id item = [draggingItem item];

        if ([item isKindOfClass:[NSFilePromiseReceiver class]]) {
            NSFilePromiseReceiver *promiseReceiver = (NSFilePromiseReceiver *)item;
            
            [promiseReceiver receivePromisedFilesAtDestination: [self _temporaryURL]
                                                       options: @{ }
                                                operationQueue: [self _workQueue]
                                                        reader:^(NSURL *fileURL, NSError *errorOrNil)
            {
                [self _handleFileURL:fileURL destination:destination shouldCopy:shouldCopy];

            }];
        
        } else if ([item isKindOfClass:[NSURL class]]) {
            [self _handleFileURL:(NSURL *)item destination:destination shouldCopy:shouldCopy];
        }
    }];
    
    return YES;
}


@end
