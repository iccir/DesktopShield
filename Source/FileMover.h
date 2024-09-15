// Copyright (c) 2021-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

@import AppKit;


@interface FileMover : NSObject

+ (instancetype) sharedInstance;

- (NSDragOperation) dragOperationWithInfo:(id <NSDraggingInfo>)sender destination:(NSURL *)destination;
- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender destination:(NSURL *)destination;

@end
