// Copyright (c) 2021-2026 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "ShieldController.h"
#import "FileMover.h"
#import "Utils.h"

@interface ShieldController () <NSWindowDelegate, NSDraggingDestination>
@end

@implementation ShieldController {
    NSImageView *_imageView;
}


- (instancetype) initWithScreen:(NSScreen *)screen
{
    NSRect contentRect = [screen frame];
    NSWindow *window = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];

    [window setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:1/255.0]];
    [window setLevel:kCGDesktopIconWindowLevel + 20];
    [window setExcludedFromWindowsMenu:YES];
    [window setCollectionBehavior:NSWindowCollectionBehaviorStationary];
    
    if ((self = [super initWithWindow:window])) {
        _screen = screen;

        _imageView = [[NSImageView alloc] initWithFrame:[[window contentView] bounds]];
        [_imageView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [_imageView setEditable:NO];
        [_imageView setAllowsCutCopyPaste:NO];
        [_imageView unregisterDraggedTypes];

        [[window contentView] addSubview:_imageView];
        
        [window setCanHide:NO];

        [window setDelegate:self];
        [window registerForDraggedTypes:@[ NSPasteboardTypeFileURL ]];
        [window registerForDraggedTypes:[NSFilePromiseReceiver readableDraggedTypes]];
    }

    return self;
}


- (void) update
{
    if (!_screen) return;

    NSWindow *window = [self window];

    [window setFrame:[_screen frame] display:NO];
    
    [window orderFront:nil];
}


- (void) mouseDown:(NSEvent *)event
{
    NSEventModifierFlags modifierFlags = [event modifierFlags];

    NSRunningApplication *finder = [[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.finder"] firstObject];

    if ([finder ownsMenuBar]) return;

    ActivationType activationType = ActivationTypeDefault;

    if (modifierFlags & NSEventModifierFlagOption) {
        if (modifierFlags & NSEventModifierFlagCommand) {
            activationType = ActivationTypeHideOthers;
        } else {
            activationType = ActivationTypeHidePrevious;
        }
    }

    ActivateApplication(finder, activationType);
}


- (NSURL *) _desktopURL
{
    NSString *desktopPath = [NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
    NSURL    *desktopURL  = [NSURL fileURLWithPath:desktopPath];

    return desktopURL;
}


#pragma mark - Drag & Drop

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}


- (BOOL) wantsPeriodicDraggingUpdates
{
    return YES;
}


- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
    return [[FileMover sharedInstance] dragOperationWithInfo:sender destination:[self _desktopURL]];
}


- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender
{
    return [[FileMover sharedInstance] dragOperationWithInfo:sender destination:[self _desktopURL]];
}


- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
    return [[FileMover sharedInstance] performDragOperation:sender destination:[self _desktopURL]];
}


@end
