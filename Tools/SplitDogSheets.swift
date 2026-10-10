import AppKit
import Foundation

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let sheetsDirectory = root.appendingPathComponent("ArtworkSource/DogSheets")
let outputDirectory = root.appendingPathComponent("KutyajoMatek/Resources/Dogs")

try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for sheetIndex in 1...4 {
    let sheetURL = sheetsDirectory.appendingPathComponent("dog_sheet_\(sheetIndex).png")
    guard
        let image = NSImage(contentsOf: sheetURL),
        let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
        fatalError("Could not open \(sheetURL.path)")
    }

    let cellWidth = source.width / 5
    let cellHeight = source.height / 2

    for row in 0..<2 {
        for column in 0..<5 {
            let isLastColumn = column == 4
            let width = isLastColumn ? source.width - (column * cellWidth) : cellWidth
            let height = row == 0 ? min(600, cellHeight) : cellHeight
            let rect = CGRect(
                x: column * cellWidth,
                y: row * cellHeight,
                width: width,
                height: height
            )

            guard let crop = source.cropping(to: rect) else {
                fatalError("Could not crop sheet \(sheetIndex), row \(row), column \(column)")
            }

            let bitmap = NSBitmapImageRep(cgImage: crop)
            guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
                fatalError("Could not encode crop")
            }

            let dogIndex = ((sheetIndex - 1) * 10) + (row * 5) + column + 1
            let filename = String(format: "dog_%02d.png", dogIndex)
            try pngData.write(to: outputDirectory.appendingPathComponent(filename))
        }
    }
}

print("Created 40 dog portraits in \(outputDirectory.path)")
