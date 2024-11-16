import Foundation

struct ComponentsUtils {
    static func insertComponents(docURL: URL, componentsURL: URL?) throws -> Data {
        guard let componentsURL else {
            return try Data(contentsOf: docURL)
        }
        
        let componentsContent = try getComponents(componentsURL: componentsURL)
        let docContent = try String(contentsOf: docURL, encoding: .utf8)
        
        var result = insertString(componentsContent, to: docContent)
        result = removeReferences(docContent: result)
        
        if let data = result.data(using: .utf8) {
            return data
        } else {
            throw NSError.init(domain: "Data from string error", code: 0)
        }
    }
    
    static func getComponents(componentsURL: URL) throws -> String {
        let fileContents = try String(contentsOf: componentsURL, encoding: .utf8)
        //remove first 2 lines
        let lines = fileContents.components(separatedBy: "\n").dropFirst(2)
        return lines.joined(separator: "\n")
    }

    static func insertString(_ components: String, to docContent: String) -> String {
        var docLines = docContent.components(separatedBy: "\n")
        
        var index = docLines.reversed().firstIndex(where: { $0.starts(with: "  security")})?.base
        index? -= 1
        
        let componentsLines = components.components(separatedBy: "\n")
        
        if let index {
            docLines.insert(contentsOf: componentsLines, at: index)
        } else {
            docLines.append(contentsOf: componentsLines)
        }
        
        let result = docLines.joined(separator: "\n")
        return result
    }
    
    static func removeReferences(docContent: String) -> String {
        var lines = docContent.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            if #available(iOS 16.0, macOS 13, *) {
                lines[index] = line.replacing("./components.yaml", with: "")
            }
        }
        
        return lines.joined(separator: "\n")
    }
}
