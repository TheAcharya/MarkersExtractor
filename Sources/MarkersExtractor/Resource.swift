import Foundation

/// Package resource files.
enum Resource: CaseIterable {
    // Images
    case marker_png
    case marker_chapter_png
    case marker_to_do_png
    case marker_completed_png
    // Videos
    case marker_video_placeholder_mov
}

extension Resource {
    var fileName: String {
        fileNameComponents.name + "." + fileNameComponents.ext
    }
    
    var fileNameComponents: (name: String, ext: String) {
        switch self {
        case .marker_png:
            return ("marker", "png")
        case .marker_chapter_png:
            return ("marker-chapter", "png")
        case .marker_to_do_png:
            return ("marker-to-do", "png")
        case .marker_completed_png:
            return ("marker-completed", "png")
        case .marker_video_placeholder_mov:
            return ("marker-video-placeholder", "mov")
        }
    }
    
    var url: URL? {
        URL(
            moduleResource: fileNameComponents.name,
            withExtension: fileNameComponents.ext,
            subFolder: "Resources"
        )
    }
    
    var data: Data? {
        guard let url = url else { return nil }
        return try? Data(contentsOf: url)
    }
    
    /// Check that all module resources are locatable.
    static func validateAll() -> Bool {
        allCases.allSatisfy {
            $0.url?.exists == true
        }
    }
}
