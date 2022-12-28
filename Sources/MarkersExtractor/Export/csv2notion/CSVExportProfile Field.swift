extension CSVExportProfile {
    /// Markers CSV fields (header column names).
    public enum Field: String, CaseIterable {
        case id
        case name
        case type
        case checked
        case status
        case notes
        case position
        case clipName
        case clipDuration
        case role
        case eventName
        case projectName
        case libraryName
        case iconImage
        case imageFileName
    }
}

extension CSVExportProfile.Field: ExportField {
    public var name: String {
        switch self {
        case .id: return "Marker ID"
        case .name: return "Marker Name"
        case .type: return "Type"
        case .checked: return "Checked"
        case .status: return "Status"
        case .notes: return "Notes"
        case .position: return "Marker Position"
        case .clipName: return "Clip Name"
        case .clipDuration: return "Clip Duration"
        case .role: return "Role & Subrole"
        case .eventName: return "Event Name"
        case .projectName: return "Project Name"
        case .libraryName: return "Library Name"
        case .iconImage: return "Icon Image"
        case .imageFileName: return "Image Filename"
        }
    }
}
