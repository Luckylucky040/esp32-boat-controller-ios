#!/usr/bin/env python3
"""Pick the UDID of an available iPhone simulator from `simctl list devices -j`.

Usage: pick_simulator.py <path-to-simctl-json>

Prints the UDID of the first iPhone found in the newest iOS runtime.
Exits non-zero if no iPhone simulator is available.
"""

import json
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: pick_simulator.py <devices.json>", file=sys.stderr)
        return 2

    with open(sys.argv[1], encoding="utf-8") as handle:
        data = json.load(handle)

    runtimes = data.get("devices", {})

    # Sort runtimes newest-first (runtime keys look like
    # "com.apple.CoreSimulator.SimRuntime.iOS-18-2").
    for runtime in sorted(runtimes.keys(), reverse=True):
        if "iOS" not in runtime:
            continue
        for device in runtimes[runtime]:
            if "iPhone" in device.get("name", ""):
                print(device["udid"])
                return 0

    print("no available iPhone simulator found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
