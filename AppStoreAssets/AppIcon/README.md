# Kutyajó matek – App icons

Source design: Figma › Kutyajo matek › "App Store Icon" page (`AppIcon-1024` component).

## For App Store Connect

Upload **`AppIcon-1024.png`**.

- 1024×1024 px, PNG, sRGB, no transparency (alpha channel)
- Square corners; Apple applies the rounded mask itself

The same file is already in Xcode at `KutyajoMatek/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
Xcode builds the on-device sizes from it, so the icon is included automatically when you archive.

## legacy-sizes/

180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29 and 20 px PNGs, scaled down from the 1024 icon.
You don't need them for a current Xcode build or App Store upload. They're here for older
Xcode projects, websites, or marketing material.
