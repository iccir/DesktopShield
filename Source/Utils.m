// Copyright (c) 2021-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "Utils.h"

struct CPSProcess {
    uint32_t high;
    uint32_t low;
};
typedef struct CPSProcess CPSProcess;

extern CGError CPSSetFrontProcessWithOptions(const CPSProcess *serialPtr, uint32_t unknown, unsigned long options);
extern CGError CPSPostHideReq(const CPSProcess *process);
extern CGError CPSPostHideMostReq(const CPSProcess *process);


void ActivateApplication(NSRunningApplication *target, ActivationType activationType)
{
    CPSProcess targetProcess = { 0x1, [target processIdentifier] };

    if (activationType == ActivationTypeHidePrevious) {
        NSRunningApplication *previous = [[NSWorkspace sharedWorkspace] menuBarOwningApplication];

        if (![previous isEqual:target]) {
            CPSProcess previousProcess = { 0x1, [previous processIdentifier] };
            CPSPostHideReq(&previousProcess);
        }

    } else if (activationType == ActivationTypeHideOthers) {
        CPSPostHideMostReq(&targetProcess);
    }

    CPSSetFrontProcessWithOptions(&targetProcess, 0, 0x100);
}
