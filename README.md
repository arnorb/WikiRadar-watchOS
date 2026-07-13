# WikiRadar for watchOS

A standalone Apple Watch app that shows you nearby Wikipedia entries based
on your location — a port of [WikiRadar for
PebbleOS](https://github.com/danieleldjarn/WikiRadar).

The watch's own GPS, networking, and compass do everything the Pebble
version needed a phone companion for: a list of up to 20 nearby articles
with live distances, article intro summaries (cached for offline
re-reading), and a radar-style compass view that points an arrow at the
article as you walk.

## Requirements

- watchOS 10.0 or later
- Xcode 15+ to build; the project file is generated with
  [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`
- The compass view needs heading hardware (Apple Watch Series 5 or later,
  SE, Ultra); on other models it falls back to a status message while the
  list and article views work normally

## Building & running

```sh
xcodegen generate                 # regenerate WikiRadar.xcodeproj after editing project.yml
open WikiRadar.xcodeproj          # build & run from Xcode
```

Or from the command line:

```sh
xcodebuild -scheme WikiRadar \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' \
  build test
```

In the simulator, set a location via Features → Location → Custom
Location… (the compass heading cannot be simulated; test that on
hardware). To install on your watch, select it as the run destination in
Xcode — a free personal team works (7-day provisioning profiles).

## Project layout

```
WikiRadar/Models/      Article model
WikiRadar/Services/    Wikipedia API client, location/heading, app state,
                       settings, distance/bearing math, caching
WikiRadar/Views/       List, article, compass, and settings views
WikiRadarTests/        Unit tests (formatting, bearing, decoding, caching rules)
scripts/make_icon.py   Regenerates the app icon (needs Pillow)
```

## License

[MIT](LICENSE), same as the original Pebble app.
