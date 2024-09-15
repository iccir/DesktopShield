/*
    DockKiller
    A hack to run Dock with ReduceTransparency=0
    
    Copyright (c) 2021-2024 Ricci Adams
    MIT License (or) 1-clause BSD License
*/

#import "DockKiller.h"

@import AppKit;

@implementation DockKiller {
    BOOL _restartingDock;
    pid_t _dockPid;
}


+ (instancetype) sharedInstance
{
    static DockKiller *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sSharedInstance = [[DockKiller alloc] init];
    });
    
    return sSharedInstance;
}


- (instancetype) init
{
    if ((self = [super init])) {
        [[NSWorkspace sharedWorkspace] addObserver:self forKeyPath:@"runningApplications" options:0 context:NULL];
        [self _updateRunningApplications];
    }
    
    return self;
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"runningApplications"]) {
        [self _updateRunningApplications];
    }
}


- (void) _updateRunningApplications
{
    if (_restartingDock) return;

    NSRunningApplication *dock = [self _dockRunningApplication];
    if (!dock) return;

    pid_t dockPid = [dock processIdentifier];
    
    if (dockPid != _dockPid) {
        _restartingDock = YES;
        [self _restartDock];
    }
}


- (NSRunningApplication *) _dockRunningApplication
{
    NSArray *docks = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dock"];
    return  [docks firstObject];
}


- (void) _restartDock
{
    __block CFAbsoluteTime startTime;
    
    BOOL (^timeout)(void) = ^{
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate distantPast]];

        BOOL yn = (CFAbsoluteTimeGetCurrent() - startTime) > 10.0;
        return yn;
    };

    void (^setReduceTransparency)(BOOL) = ^(BOOL yn) {
        CFPreferencesSetAppValue(CFSTR("reduceTransparency"), yn ? kCFBooleanTrue : kCFBooleanFalse, CFSTR("com.apple.universalaccess"));
        CFPreferencesSynchronize(CFSTR("com.apple.universalaccess"), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
    };

    dispatch_async(dispatch_get_main_queue(), ^{
        startTime = CFAbsoluteTimeGetCurrent();
    
        NSMutableSet *startApps = [NSMutableSet setWithArray:[[NSWorkspace sharedWorkspace] runningApplications]];
        NSRunningApplication *oldDock = [self _dockRunningApplication];

        setReduceTransparency(NO);

        if (oldDock) {
            kill([oldDock processIdentifier], 9);
        }

        BOOL foundDock = NO;
        while (!foundDock && !timeout()) {
            if ([self _dockRunningApplication]) {
                foundDock = YES;
            }
        }
        
        BOOL foundDockWindow = NO;

        while (!foundDockWindow && !timeout()) {
            CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, 0);

            for (NSDictionary *dictionary in (__bridge  NSArray *)windowList) {
//                NSNumber *windowLevel = [dictionary objectForKey:(id)kCGWindowLayer];
                NSString *processName = [dictionary objectForKey:(id)kCGWindowOwnerName];

                if ([processName isEqualToString:@"Dock"]) {
//                    if ([windowLevel integerValue] == kCGDockWindowLevel) {
                        foundDockWindow = YES;
                        break;
 //                   }
                }
            }

            if (windowList) CFRelease(windowList);
        }

        setReduceTransparency(YES);

        NSRunningApplication *newDock = [self _dockRunningApplication];

        // Cleanup any apps launched while we were changing "reduceTransparency"
        {
            NSMutableSet *appsToTerminate = [NSMutableSet setWithArray:[[NSWorkspace sharedWorkspace] runningApplications]];
            NSMutableSet *appsToLaunch    = [NSMutableSet set];

            [appsToTerminate minusSet:startApps];
            if (newDock) [appsToTerminate removeObject:newDock];

            for (NSRunningApplication *app in appsToTerminate) {
                if ([app activationPolicy] != NSApplicationActivationPolicyProhibited) {
                    if ([app forceTerminate]) {
                        [appsToLaunch addObject:app];
                    }
                }
            }

            for (NSRunningApplication *app in appsToLaunch) {
                while (![app isTerminated] && !timeout()) {
                    // Wait for app to terminate
                }
                
                [[NSWorkspace sharedWorkspace] openApplicationAtURL: [app bundleURL]
                                                      configuration: [NSWorkspaceOpenConfiguration configuration]
                                                  completionHandler: nil];
            }
        }

        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        NSLog(@"Dock restart took %lf seconds", endTime - startTime);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _restartingDock = NO;
            _dockPid = [newDock processIdentifier];
        });
    });
}
    
    
@end
