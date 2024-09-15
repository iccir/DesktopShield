// Copyright (c) 2021-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

@import AppKit;

@interface ShieldController : NSWindowController

- (instancetype) initWithScreen:(NSScreen *)screen;

- (void) update;

@property (nonatomic, readonly) NSScreen *screen;

@end
