//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import PackagePlugin
import Foundation

enum PluginUtils {
    private static var supportedConfigFiles: Set<String> {
        Set(["yaml", "yml"].map { "openapi-generator-config." + $0 })
    }
    private static var supportedDocFiles: Set<String> { Set(["yaml", "yml", "json"].map { "openapi." + $0 }) }
    private static var supportedComponentsFiles: Set<String> { Set(["yaml", "yml", "json"].map { "components." + $0 }) }


    /// Validated values to run a plugin with.
    struct ValidatedInputs {
        let doc: Path
        let config: Path
        let genSourcesDir: Path
        let arguments: [String]
        let tool: PluginContext.Tool
    }

    /// Validates the inputs and returns the necessary values to run a plugin.
    static func validateInputs(
        workingDirectory: Path,
        tool: (String) throws -> PluginContext.Tool,
        sourceFiles: FileList,
        targetName: String,
        pluginSource: PluginSource
    ) throws -> ValidatedInputs {
        let (config, components, doc) = try findFiles(inputFiles: sourceFiles, targetName: targetName)
        let genSourcesDir = workingDirectory.appending("GeneratedSources")

        let arguments = [
            "generate", "\(doc)", components != nil ? "--components" : nil, components != nil ? "\(components!)" : nil, "--config", "\(config)", "--output-directory", "\(genSourcesDir)", "--plugin-source",
            "\(pluginSource.rawValue)",
        ].compactMap(\.self)

        let tool = try tool("swift-openapi-generator")

        return ValidatedInputs(doc: doc, config: config, genSourcesDir: genSourcesDir, arguments: arguments, tool: tool)
    }

    /// Finds the OpenAPI config and document files or throws an error including both possible
    /// previous errors from the process of finding the config and document files.
    private static func findFiles(inputFiles: FileList, targetName: String) throws -> (config: Path, components: Path?, doc: Path) {
        do {
            let config = try findConfig(inputFiles: inputFiles, targetName: targetName).get()
            let components = try findComponents(inputFiles: inputFiles, targetName: targetName).get()
            let doc = try findDocument(inputFiles: inputFiles, targetName: targetName).get()
            return (config, components, doc)
        } catch {
            throw PluginError.fileErrors([error])
        }
    }

    /// Find the config file.
    private static func findConfig(inputFiles: FileList, targetName: String) -> Result<Path, FileError> {
        let matchedConfigs = inputFiles.filter { supportedConfigFiles.contains($0.path.lastComponent) }.map(\.path)
        guard matchedConfigs.count > 0 else {
            return .failure(FileError(targetName: targetName, fileKind: .config, issue: .noFilesFound))
        }
        guard matchedConfigs.count == 1 else {
            return .failure(
                FileError(targetName: targetName, fileKind: .config, issue: .multipleFilesFound(files: matchedConfigs))
            )
        }
        return .success(matchedConfigs[0])
    }

    /// Find the document file.
    private static func findDocument(inputFiles: FileList, targetName: String) -> Result<Path, FileError> {
        let matchedDocs = inputFiles.filter { supportedDocFiles.contains($0.path.lastComponent) }.map(\.path)
        guard matchedDocs.count > 0 else {
            return .failure(FileError(targetName: targetName, fileKind: .document, issue: .noFilesFound))
        }
        guard matchedDocs.count == 1 else {
            return .failure(
                FileError(targetName: targetName, fileKind: .document, issue: .multipleFilesFound(files: matchedDocs))
            )
        }
        return .success(matchedDocs[0])
    }
    
    /// Find the document file.
    private static func findComponents(inputFiles: FileList, targetName: String) -> Result<Path?, FileError> {
        let matchedDocs = inputFiles.filter { supportedComponentsFiles.contains($0.path.lastComponent) }.map(\.path)
        guard matchedDocs.count > 0 else {
            return .failure(FileError(targetName: targetName, fileKind: .document, issue: .noFilesFound))
        }
        guard matchedDocs.count == 1 else {
            return .failure(
                FileError(targetName: targetName, fileKind: .document, issue: .multipleFilesFound(files: matchedDocs))
            )
        }
        return .success(matchedDocs[0])
    }
}

extension Array where Element == String {
    func joined(separator: String, lastSeparator: String) -> String {
        guard count > 1 else { return self.joined(separator: separator) }
        return "\(self.dropLast().joined(separator: separator))\(lastSeparator)\(self.last!)"
    }
}
