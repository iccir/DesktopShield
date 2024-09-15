// Copyright (c) 2021-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

typedef NS_ENUM(NSInteger, ActivationType) {
    ActivationTypeDefault,
    ActivationTypeHidePrevious,
    ActivationTypeHideOthers
};

extern void ActivateApplication(NSRunningApplication *application, ActivationType activationType);
