#!/usr/bin/swift
/*
 updatecopyright.swift
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of Draw nor the names of its contributors may be
   used to endorse or promote products derived from this software without
   specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL AJ RAFTIS BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

let processName = URL(fileURLWithPath: CommandLine.arguments[0]).deletingPathExtension().lastPathComponent
func Usage(error: String? = nil) -> Never {
    if let error {
        print("Error: \(error)")
    }
    print("Usage: \(CommandLine.arguments[0]) [options]")
    print("Options:")
    print("  --help                   This message.")
    print("  --license [license_file] The license to include in the top header.")
    print("  --base [base_path]       The base path to start the search for files to modify.")
    print("  --owner [owner]          The copyright owner.")
    print("  --skip [lines_to_skip]   The number of lines to skip on the license. The default is two.")
    print("  --extension [extension]  The file extension of files to include.")
    print("  --test                   Don't actually write changes.")
    exit(1)
}

var licensePath = "LICENSE.md"
var license = ""
var extensionsFirst = true
var extensions : Set<String> = ["c", "m", "h", "cpp", "hpp", "swift", "strings"]
var basePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var package = basePath.lastPathComponent
var skip = 2
var copyrightOwner = ""
var copyright = ""
var testing = false

var replacedCount = 0
var skippedCount = 0
var externalCount = 0
var lineCount = 0

if true {
    let args = CommandLine.arguments
    var index = 1
    while index < args.count {
        switch args[index] {
        case "-l": fallthrough
        case "--license":
            if index < args.count - 1 && !args[index + 1].starts(with: "-") {
                index += 1
                licensePath = args[index]
            } else {
                Usage(error: "\(args[index]) must include a license path.")
            }
        case "-b": fallthrough
        case "--base":
            if index < args.count - 1 && !args[index + 1].starts(with: "-") {
                index += 1
                basePath = URL(fileURLWithPath: args[index]).standardizedFileURL
            } else {
                Usage(error: "\(args[index]) must include a base path.")
            }
        case "-o": fallthrough
        case "--owner":
            if index < args.count - 1 && !args[index + 1].starts(with: "-") {
                index += 1
                copyrightOwner = args[index]
            } else {
                Usage(error: "\(args[index]) must include an owner.")
            }
        case "-s": fallthrough
        case "--skip":
            if index < args.count - 1 && !args[index + 1].starts(with: "-") {
                index += 1
                if let value = Int(args[index]) {
                    skip = value
                } else {
                    Usage(error: "\(args[index]) isn't a valid integer.")
                }
            } else {
                Usage(error: "\(args[index]) must include a number of lines to skip.")
            }
        case "-e": fallthrough
        case "--extension":
            if index < args.count - 1 && !args[index + 1].starts(with: "-") {
                index += 1
                if extensionsFirst {
                    extensions.removeAll()
                    extensionsFirst = false
                }
                extensions.insert(args[index])
            } else {
                Usage(error: "\(args[index]) must include a base path.")
            }
        case "-t": fallthrough
        case "--test":
            testing = true
        case "-h": fallthrough
        case "--help":
            Usage()
        default:
            if args[index].starts(with: "-") {
                Usage(error: "Unknown argument: \(args[index])");
            }
        }
        index += 1
    }

    if !copyrightOwner.isEmpty {
        copyright = "Copyright © \(Calendar.current.component(.year, from: Date())), \(copyrightOwner)"
    }

    // Attempt to read the license.
    do {
        license = try String(contentsOf: URL(fileURLWithPath: licensePath))
    } catch {
        Usage(error: "Unable to read \(licensePath): \(error.localizedDescription)")
    }

    if let enumerator = FileManager.default.enumerator(at: basePath, includingPropertiesForKeys: [], options: [.skipsHiddenFiles]) {
        while let url = enumerator.nextObject() as? URL {
            if extensions.contains(url.pathExtension) {
                do {
                    try ProcessFile(url: url)
                } catch {
                    print("Error: \(url.path): \(error.localizedDescription)")
                }
            }
        }
    }

    print("\(skippedCount + externalCount + replacedCount) processed, \(skippedCount) skipped, \(replacedCount) replaced, \(externalCount) external, \(lineCount) lines of code.")
}

func BuildLicense(from url: URL) -> String {
    var outputFile = ""

    outputFile += "/*\n"
    outputFile += " \(url.lastPathComponent)\n"
    outputFile += " \(package)\n"
    outputFile += "\n"
    if !copyrightOwner.isEmpty {
        outputFile += " \(copyright) \n"
        outputFile += " All rights reserved.\n"
        outputFile += "\n"
    }
    var lineNumber = 1
    license.enumerateLines { line, stop in
        if lineNumber > skip {
            if line.isEmpty {
                outputFile += "\n"
            } else {
                outputFile += " \(line)\n"
            }
        }
        lineNumber += 1
    }
    outputFile += " */\n"

    return outputFile
}

func ProcessFile(url: URL) throws {
    try autoreleasepool {
        print("Processing: \(url.lastPathComponent)...", terminator: "")

        // First, read in the file contents.
        let inputFile = try String(contentsOf: url)

        var outputFile = ""

        enum HeaderStyle {
            case unknown
            case c
            case cpp
            case external
            case shellScript
        }

        var strippedPrevious = false
        var inHeader = false
        var style = HeaderStyle.unknown
        var skipEmptyInHeader = true
        inputFile.enumerateLines { line, stop in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !strippedPrevious {
                if !inHeader {
                    // We haven't found how our header works yet.
                    if trimmed.hasPrefix("#!") {
                        outputFile += "\(trimmed)\n"
                        skipEmptyInHeader = false
                    } else if trimmed == "/*-" {
                        // We use this to indicate when we don't own the copyright, so when we encounter this, we're done.
                        style = .external
                        stop = true
                    } else if trimmed == "/*" {
                        // OK, we're looking for /* and */ bracketed comments.
                        inHeader = true
                        style = .c
                    } else if trimmed.starts(with: "//") {
                        // OK, we're looking for C++ style comments
                        inHeader = true
                        style = .cpp
                    } else if trimmed.isEmpty && skipEmptyInHeader {
                        // Just skip this line.
                    } else {
                        // We didn't find anything to strip, so just start copying.
                        inHeader = false
                        strippedPrevious = true
                        // Make sure to write this line out.
                        outputFile += BuildLicense(from: url)
                        outputFile += "\(line)\n"
                    }
                } else {
                    // OK, we're in the header
                    if style == .c {
                        if trimmed == "*/" {
                            inHeader = false
                            strippedPrevious = true
                            outputFile += BuildLicense(from: url)
                        }
                    } else if style == .cpp {
                        if !trimmed.hasPrefix("//") {
                            inHeader = false
                            strippedPrevious = true
                            outputFile += BuildLicense(from: url)
                            outputFile += "\(line)\n"
                        }
                    }
                }
            } else {
                // Once we've stripped the previous, we can pretty much just copy the lines.
                // Althouhg I'm going to do a little clean up.
                outputFile += "\(line)\n"
                lineCount += 1
            }
        }

        if style == .external {
            print("external copyright...", terminator: "")
            externalCount += 1
        } else if outputFile != inputFile {
            if !testing {
                print("replacing...", terminator: "")
                try outputFile.write(to: url, atomically: true, encoding: .utf8)
            } else {
                print("would replace...", terminator: "")
            }
            replacedCount += 1
        } else {
            print("skipping...", terminator: "")
            skippedCount += 1
        }

        print("done")

//        if url.lastPathComponent == "updatecopyright.swift" {
//            print("output:\n\(outputFile)")
//        }

//        try? outputFile.write(to: URL(fileURLWithPath: "t1"), atomically: true, encoding: .utf8)
//        try? inputFile.write(to: URL(fileURLWithPath: "t2"), atomically: true, encoding: .utf8)
//        print(outputFile)

//        exit(1)
    }
}
