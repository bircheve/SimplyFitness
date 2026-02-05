import Foundation

extension Bundle {
    /// Load and decode JSON data from a file in the bundle
    func decode<T: Decodable>(_ type: T.Type, from file: String) throws -> T {
        guard let url = self.url(forResource: file, withExtension: "json") else {
            throw BundleError.fileNotFound(file)
        }

        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Failed to decode \(file).json: \(error)")
            throw BundleError.decodingFailed(file, error)
        }
    }

    /// Load and decode JSON data array from a file in the bundle
    func decodeArray<T: Decodable>(_ type: T.Type, from file: String) throws -> [T] {
        return try decode([T].self, from: file)
    }

    /// Check if a JSON file exists in the bundle
    func jsonFileExists(_ fileName: String) -> Bool {
        return self.url(forResource: fileName, withExtension: "json") != nil
    }

    /// Get all JSON files in the bundle
    func allJSONFiles() -> [String] {
        guard let resourcePath = self.resourcePath else { return [] }

        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: resourcePath)
            return contents.compactMap { fileName in
                if fileName.hasSuffix(".json") {
                    return String(fileName.dropLast(5)) // Remove .json extension
                }
                return nil
            }
        } catch {
            print("Error reading bundle contents: \(error)")
            return []
        }
    }
}

// MARK: - Bundle Errors

enum BundleError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, Error)
    case encodingFailed(String, Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName):
            return "Could not find file '\(fileName).json' in bundle"
        case .decodingFailed(let fileName, let error):
            return "Failed to decode '\(fileName).json': \(error.localizedDescription)"
        case .encodingFailed(let fileName, let error):
            return "Failed to encode '\(fileName).json': \(error.localizedDescription)"
        }
    }
}

// MARK: - JSON Encoding Extensions

extension Encodable {
    /// Convert to pretty-printed JSON string
    func prettyPrintedJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw BundleError.encodingFailed("unknown", NSError(domain: "EncodingError", code: -1))
        }

        return jsonString
    }

    /// Convert to compact JSON string
    func compactJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw BundleError.encodingFailed("unknown", NSError(domain: "EncodingError", code: -1))
        }

        return jsonString
    }
}