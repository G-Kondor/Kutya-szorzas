import Foundation
import UIKit

enum ProfileAvatarStore {
    private static let folderName = "ProfileAvatars"
    private static let maxDimension: CGFloat = 512
    private static let jpegQuality: CGFloat = 0.82

    static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let url = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static func fileURL(for fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName)
    }

    static func loadImage(fileName: String?) -> UIImage? {
        guard let fileName, !fileName.isEmpty else { return nil }
        let url = fileURL(for: fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Copies a resized JPEG into app support and returns the stored file name.
    static func saveImage(_ image: UIImage, forProfileID profileID: String) throws -> String {
        let prepared = resized(image, maxDimension: maxDimension)
        guard let data = prepared.jpegData(compressionQuality: jpegQuality) else {
            throw AvatarStoreError.encodingFailed
        }

        let fileName = "\(profileID)-\(UUID().uuidString).jpg"
        let url = fileURL(for: fileName)
        try data.write(to: url, options: .atomic)
        return fileName
    }

    static func deleteImage(fileName: String?) {
        guard let fileName, !fileName.isEmpty else { return }
        let url = fileURL(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    enum AvatarStoreError: Error {
        case encodingFailed
    }
}
