import SwiftUI
import UniformTypeIdentifiers

struct FitSphereJSONBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        if let wrapped = configuration.file.regularFileContents {
            data = wrapped
        } else {
            data = Data()
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct FitSpherePDFReportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        if let wrapped = configuration.file.regularFileContents {
            data = wrapped
        } else {
            data = Data()
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct FitSphereTextReportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var data: Data

    init(text: String) {
        data = Data(text.utf8)
    }

    init(configuration: ReadConfiguration) throws {
        if let wrapped = configuration.file.regularFileContents {
            data = wrapped
        } else {
            data = Data()
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
