// Copyright (c) 2021-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "AppDelegate.h"
#import "ShieldController.h"

@interface AppDelegate ()
@end


@implementation AppDelegate {
   
    NSDictionary *_screenToShieldMap;
}


- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(_handleApplicationDidChangeScreenParameters:)
                                                 name: NSApplicationDidChangeScreenParametersNotification
                                               object: nil];

    [self _updateScreens];
}


- (void) _updateScreens
{
    NSMutableDictionary *screenToShieldMap = [NSMutableDictionary dictionary];
            
    for (NSScreen *screen in [NSScreen screens]) {
        NSValue *screenValue = [NSValue valueWithNonretainedObject:screen];
        
        ShieldController *shieldController = [_screenToShieldMap objectForKey:screenValue];
        
        if (!shieldController) {
            shieldController = [[ShieldController alloc] initWithScreen:screen];
        }
        
        [screenToShieldMap setObject:shieldController forKey:screenValue];
    }

    NSArray *previousShieldControllers = _screenToShieldMap ? [_screenToShieldMap allValues] : @[ ];
    NSArray *currentShieldControllers  =  screenToShieldMap ? [ screenToShieldMap allValues] : @[ ];
    
    // Tell old screens to go away
    for (ShieldController *shieldController in previousShieldControllers) {
        if (![currentShieldControllers containsObject:shieldController]) {
            [shieldController close];
        }     
    }

    // Tell existing and new screens to update
    for (ShieldController *shieldController in currentShieldControllers) {
        [shieldController update];
    }

    _screenToShieldMap = screenToShieldMap;
}


- (void) _handleApplicationDidChangeScreenParameters:(NSNotification *)notification
{
    [self _updateScreens];
}


@end
