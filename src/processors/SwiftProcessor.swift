import Foundation
import CryptoKit
import CommonCrypto

struct ProcessingOptions {
    var key: String?
    var additionalOptions: [String: Any] = [:]
}

class SwiftProcessor {
    private var options: [String: String]
    private var identifierMap: [String: String] = [:]
    private var stringMap: [String: String] = [:]
    private var encryptedStrings: [String] = []
    private let reservedKeywords: Set<String>
    private let stdClasses: Set<String>
    private let iosFrameworks: Set<String>
    private let swiftKeywords: Set<String>
    
    init(options: [String: String] = [:]) {
        self.options = options
        
        if self.options["encryptionKey"] == nil {
            self.options["encryptionKey"] = "default_encryption_key_32_chars_"
        }
        
        // Swift reserved keywords
        self.swiftKeywords = Set([
            "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
            "func", "import", "init", "inout", "internal", "let", "open",
            "operator", "private", "protocol", "public", "rethrows", "static",
            "struct", "subscript", "typealias", "var", "break", "case",
            "continue", "default", "defer", "do", "else", "fallthrough",
            "for", "guard", "if", "in", "repeat", "return", "switch",
            "where", "while", "as", "Any", "catch", "false", "is", "nil",
            "super", "self", "Self", "throw", "throws", "true", "try",
            "_", "#available", "#colorLiteral", "#column", "#else", "#elseif",
            "#endif", "#error", "#file", "#fileLiteral", "#function", "#if",
            "#imageLiteral", "#line", "#selector", "#sourceLocation", "#warning"
        ])
        
        // Standard Swift types and classes
        self.stdClasses = Set([
            "String", "Int", "Double", "Float", "Bool", "Array", "Dictionary",
            "Set", "Optional", "Result", "Error", "Data", "Date", "URL",
            "UUID", "NSString", "NSArray", "NSDictionary", "NSSet", "NSData",
            "NSDate", "NSURL", "NSUUID", "NSError", "NSObject", "AnyObject",
            "AnyClass", "Protocol", "Selector", "UnsafePointer", "UnsafeMutablePointer",
            "UnsafeBufferPointer", "UnsafeMutableBufferPointer", "UnsafeRawPointer",
            "UnsafeMutableRawPointer", "UnsafeRawBufferPointer", "UnsafeMutableRawBufferPointer",
            "AutoreleasingUnsafeMutablePointer", "OpaquePointer", "CVaListPointer",
            "StaticString", "UnicodeScalar", "Character", "Substring", "Range",
            "ClosedRange", "PartialRangeFrom", "PartialRangeThrough", "PartialRangeUpTo"
        ])
        
        // iOS/macOS frameworks and classes
        self.iosFrameworks = Set([
            "UIKit", "Foundation", "CoreData", "CoreGraphics", "CoreAnimation",
            "CoreLocation", "MapKit", "AVFoundation", "Photos", "Contacts",
            "EventKit", "HealthKit", "HomeKit", "CloudKit", "GameKit",
            "StoreKit", "AdSupport", "iAd", "Social", "Accounts", "Twitter",
            "Facebook", "MessageUI", "MultipeerConnectivity", "NetworkExtension",
            "NotificationCenter", "UserNotifications", "CallKit", "Intents",
            "IntentsUI", "SiriKit", "Speech", "Vision", "ARKit", "CoreML",
            "CreateML", "NaturalLanguage", "PencilKit", "RealityKit", "SwiftUI",
            "Combine", "CryptoKit", "OSLog", "MetricKit", "BackgroundTasks",
            "WidgetKit", "AppClip", "UIViewController", "UIView", "UILabel",
            "UIButton", "UITextField", "UITextView", "UIImageView", "UITableView",
            "UICollectionView", "UIScrollView", "UIStackView", "UINavigationController",
            "UITabBarController", "UIAlertController", "UIActivityViewController",
            "UIApplication", "UIWindow", "UIScene", "UISceneDelegate", "AppDelegate",
            "SceneDelegate", "NSManagedObject", "NSManagedObjectContext",
            "NSPersistentContainer", "NSFetchRequest", "NSPredicate", "NSSortDescriptor",
            "CLLocationManager", "MKMapView", "AVPlayer", "AVPlayerViewController",
            "PHPhotoLibrary", "CNContactStore", "EKEventStore", "HKHealthStore"
        ])
        
        self.reservedKeywords = swiftKeywords.union(stdClasses).union(iosFrameworks)
    }
    
    private func encryptString(_ plaintext: String, key: String) -> String {
        guard let data = plaintext.data(using: .utf8) else { return "" }
        
        // Ensure key is 32 bytes
        var keyData = Data(key.utf8)
        if keyData.count < 32 {
            keyData.append(Data(repeating: 0, count: 32 - keyData.count))
        } else if keyData.count > 32 {
            keyData = keyData.prefix(32)
        }
        
        // Generate random IV
        var iv = Data(count: 16)
        let result = iv.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
        }
        
        guard result == errSecSuccess else { return "" }
        
        // Encrypt using AES-256-CBC
        let cryptLength = data.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLength)
        
        let keyLength = keyData.count
        let operation: CCOperation = UInt32(kCCEncrypt)
        let algoritm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options: CCOptions = UInt32(kCCOptionPKCS7Padding)
        
        var numBytesEncrypted: size_t = 0
        
        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    keyData.withUnsafeBytes { keyBytes in
                        CCCrypt(operation,
                               algoritm,
                               options,
                               keyBytes.baseAddress, keyLength,
                               ivBytes.baseAddress,
                               dataBytes.baseAddress, data.count,
                               cryptBytes.baseAddress, cryptLength,
                               &numBytesEncrypted)
                    }
                }
            }
        }
        
        guard UInt32(cryptStatus) == UInt32(kCCSuccess) else { return "" }
        
        cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
        
        // Combine IV and encrypted data
        let combined = iv + cryptData
        return combined.base64EncodedString()
    }
    
    private func generateObfuscatedName() -> String {
        let charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let length = Int.random(in: 8...15)
        
        var result = ""
        
        // First character must be a letter
        result += String(charset.randomElement()!)
        
        // Remaining characters can be letters or numbers
        let fullCharset = charset + "0123456789"
        for _ in 1..<length {
            result += String(fullCharset.randomElement()!)
        }
        
        return result
    }
    
    private func isReservedIdentifier(_ identifier: String) -> Bool {
        return reservedKeywords.contains(identifier)
    }
    
    private func encryptStrings(_ code: String, key: String) -> String {
        var result = ""
        
        // Add decryption utility
        let decryptUtility = """
// String decryption utility
import Foundation
import CommonCrypto

class StringDecryptor {
    static func decrypt(_ encrypted: String, key: String) -> String {
        guard let data = Data(base64Encoded: encrypted) else { return "" }
        guard data.count > 16 else { return "" }
        
        let iv = data.prefix(16)
        let encryptedData = data.dropFirst(16)
        
        var keyData = Data(key.utf8)
        if keyData.count < 32 {
            keyData.append(Data(repeating: 0, count: 32 - keyData.count))
        } else if keyData.count > 32 {
            keyData = keyData.prefix(32)
        }
        
        let cryptLength = encryptedData.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLength)
        
        let keyLength = keyData.count
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algoritm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options: CCOptions = UInt32(kCCOptionPKCS7Padding)
        
        var numBytesDecrypted: size_t = 0
        
        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            encryptedData.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    keyData.withUnsafeBytes { keyBytes in
                        CCCrypt(operation,
                               algoritm,
                               options,
                               keyBytes.baseAddress, keyLength,
                               ivBytes.baseAddress,
                               dataBytes.baseAddress, encryptedData.count,
                               cryptBytes.baseAddress, cryptLength,
                               &numBytesDecrypted)
                    }
                }
            }
        }
        
        guard UInt32(cryptStatus) == UInt32(kCCSuccess) else { return "" }
        
        cryptData.removeSubrange(numBytesDecrypted..<cryptData.count)
        
        return String(data: cryptData, encoding: .utf8) ?? ""
    }
}

"""
        
        result += decryptUtility
        
        // Find and encrypt string literals
        let stringPattern = #""([^"\\]|\\.)*"|'([^'\\]|\\.)*'"#
        let regex = try! NSRegularExpression(pattern: stringPattern, options: [])
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.count))
        
        var lastIndex = 0
        var stringIndex = 0
        
        for match in matches {
            let range = match.range
            let startIndex = code.index(code.startIndex, offsetBy: lastIndex)
            let matchStartIndex = code.index(code.startIndex, offsetBy: range.location)
            
            // Add code before the string
            result += String(code[startIndex..<matchStartIndex])
            
            let originalString = String(code[matchStartIndex..<code.index(matchStartIndex, offsetBy: range.length)])
            let content = String(originalString.dropFirst().dropLast()) // Remove quotes
            
            let encrypted = encryptString(content, key: key)
            if !encrypted.isEmpty {
                let varName = "_str_\(stringIndex)"
                stringIndex += 1
                
                encryptedStrings.append("let \(varName) = StringDecryptor.decrypt(\"\(encrypted)\", key: \"\(key)\")")
                result += varName
            } else {
                result += originalString
            }
            
            lastIndex = range.location + range.length
        }
        
        // Add remaining code
        let remainingStartIndex = code.index(code.startIndex, offsetBy: lastIndex)
        result += String(code[remainingStartIndex...])
        
        // Add string declarations at the beginning
        let finalResult = encryptedStrings.joined(separator: "\n") + "\n" + result
        return finalResult
    }
    
    private func obfuscateIdentifiers(_ code: String) -> String {
        // Find all identifiers
        let identifierPattern = #"\b[a-zA-Z_][a-zA-Z0-9_]*\b"#
        let regex = try! NSRegularExpression(pattern: identifierPattern, options: [])
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.count))
        
        var identifiersToObfuscate = Set<String>()
        
        for match in matches {
            let range = match.range
            let startIndex = code.index(code.startIndex, offsetBy: range.location)
            let endIndex = code.index(startIndex, offsetBy: range.length)
            let identifier = String(code[startIndex..<endIndex])
            
            if !isReservedIdentifier(identifier) && identifier.count > 1 {
                identifiersToObfuscate.insert(identifier)
            }
        }
        
        // Generate obfuscated names
        for identifier in identifiersToObfuscate {
            if identifierMap[identifier] == nil {
                identifierMap[identifier] = generateObfuscatedName()
            }
        }
        
        // Replace identifiers
        var result = code
        for (original, obfuscated) in identifierMap {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: original) + "\\b"
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(location: 0, length: result.count), withTemplate: obfuscated)
        }
        
        return result
    }
    
    private func addControlFlowObfuscation(_ code: String) -> String {
        // Convert if-else to switch statements
        let ifPattern = #"if\s+([^{]+)\s*\{([^}]+)\}(?:\s*else\s*\{([^}]+)\})?"#
        let regex = try! NSRegularExpression(pattern: ifPattern, options: [.dotMatchesLineSeparators])
        
        return regex.stringByReplacingMatches(in: code, options: [], range: NSRange(location: 0, length: code.count)) { (match, _, _) in
            let fullMatch = String(code[Range(match.range, in: code)!])
            let conditionRange = match.range(at: 1)
            let ifBlockRange = match.range(at: 2)
            let elseBlockRange = match.range(at: 3)
            
            let condition = String(code[Range(conditionRange, in: code)!])
            let ifBlock = String(code[Range(ifBlockRange, in: code)!])
            
            let switchVar = "_sw\(Int.random(in: 1000...9999))"
            var replacement = "let \(switchVar) = (\(condition)) ? 1 : 0\n"
            replacement += "switch \(switchVar) {\n"
            replacement += "case 1:\n    \(ifBlock)\n"
            
            if elseBlockRange.location != NSNotFound {
                let elseBlock = String(code[Range(elseBlockRange, in: code)!])
                replacement += "default:\n    \(elseBlock)\n"
            }
            
            replacement += "}"
            return replacement
        }
    }
    
    private func addDeadCode(_ code: String) -> String {
        let deadCodeSnippets = [
            "let _dummy1 = Int.random(in: 0...100)\n",
            "let _dummy2 = Date().timeIntervalSince1970\n",
            "if _dummy1 > 200 { print(\"Never executed\") }\n",
            "for _i in 0..<0 { _dummy2 += 1 }\n",
            "let _dummy_array: [Any] = []\n",
            "let _dummy_dict = [\"key\": Double.random(in: 0...1)]\n"
        ]
        
        var result = code
        
        // Find function/method bodies and insert dead code
        let functionPattern = #"(func\s+[^{]*\{|\{)"#
        let regex = try! NSRegularExpression(pattern: functionPattern, options: [])
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.count))
        
        var insertions = 0
        var offset = 0
        
        for match in matches.prefix(3) { // Limit to 3 insertions
            let pos = match.range.location + match.range.length + offset
            let deadCode = deadCodeSnippets.randomElement()!
            let insertIndex = result.index(result.startIndex, offsetBy: pos)
            result.insert(contentsOf: "\n" + deadCode, at: insertIndex)
            offset += deadCode.count + 1
            insertions += 1
        }
        
        return result
    }
    
    private func addAntiDebugging(_ code: String) -> String {
        let antiDebugCode = """
// Anti-debugging measures for iOS apps
import UIKit
import Foundation

class AntiDebug {
    static func check() {
        // Check for debugger attachment
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        
        if (info.kp_proc.p_flag & P_TRACED) != 0 {
            // Debugger detected - exit
            exit(0)
        }
        
        // Check for simulator
        #if targetEnvironment(simulator)
        exit(0)
        #endif
        
        // Check for jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/private/var/tmp/cydia.log",
            "/private/var/lib/apt",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/usr/bin/sshd",
            "/usr/sbin/frida-server",
            "/usr/bin/cycript",
            "/usr/local/bin/cycript",
            "/usr/lib/libcycript.dylib"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                exit(0)
            }
        }
        
        // Check for common jailbreak apps
        let jailbreakSchemes = [
            "cydia://",
            "undecimus://",
            "sileo://",
            "zbra://"
        ]
        
        for scheme in jailbreakSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                exit(0)
            }
        }
        
        // Timing check
        let start = CFAbsoluteTimeGetCurrent()
        var dummy = 0
        for i in 0..<1000 {
            dummy += i
        }
        let end = CFAbsoluteTimeGetCurrent()
        
        if (end - start) > 0.01 { // 10ms
            exit(0)
        }
        
        // Check for Frida
        let frida_ports = [27042, 27043, 27044, 27045, 27046]
        for port in frida_ports {
            let sock = socket(AF_INET, SOCK_STREAM, 0)
            if sock >= 0 {
                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = in_port_t(port).bigEndian
                addr.sin_addr.s_addr = inet_addr("127.0.0.1")
                
                let result = withUnsafePointer(to: &addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
                
                close(sock)
                
                if result == 0 {
                    exit(0)
                }
            }
        }
        
        // Check for common reverse engineering tools
        let suspiciousLibraries = [
            "FridaGadget",
            "frida",
            "cycript",
            "libcycript",
            "cynject",
            "SSLKillSwitch",
            "SSLKillSwitch2",
            "MobileSubstrate",
            "LiveClock",
            "xCon",
            "SBSettings"
        ]
        
        for library in suspiciousLibraries {
            if dlopen(library, RTLD_NOW) != nil {
                exit(0)
            }
        }
    }
}

"""
        
        var result = antiDebugCode + code
        
        // Insert anti-debug call in viewDidLoad or application launch
        let viewDidLoadPattern = #"(viewDidLoad\(\)\s*\{)"#
        let viewDidLoadRegex = try! NSRegularExpression(pattern: viewDidLoadPattern, options: [])
        result = viewDidLoadRegex.stringByReplacingMatches(in: result, options: [], range: NSRange(location: 0, length: result.count), withTemplate: "$1\n        AntiDebug.check()")
        
        // Also insert in application didFinishLaunching
        let appLaunchPattern = #"(application\([^)]+didFinishLaunchingWithOptions[^{]*\{)"#
        let appLaunchRegex = try! NSRegularExpression(pattern: appLaunchPattern, options: [])
        result = appLaunchRegex.stringByReplacingMatches(in: result, options: [], range: NSRange(location: 0, length: result.count), withTemplate: "$1\n        AntiDebug.check()")
        
        return result
    }
    
    private func addClassObfuscation(_ code: String) -> String {
        // Obfuscate class names
        let classPattern = #"class\s+([a-zA-Z_][a-zA-Z0-9_]*)"#
        let regex = try! NSRegularExpression(pattern: classPattern, options: [])
        
        return regex.stringByReplacingMatches(in: code, options: [], range: NSRange(location: 0, length: code.count)) { (match, _, _) in
            let fullMatch = String(code[Range(match.range, in: code)!])
            let classNameRange = match.range(at: 1)
            let className = String(code[Range(classNameRange, in: code)!])
            
            if !isReservedIdentifier(className) {
                let obfuscatedName = "_C" + generateObfuscatedName().prefix(8)
                identifierMap[className] = String(obfuscatedName)
                return fullMatch.replacingOccurrences(of: className, with: String(obfuscatedName))
            }
            return fullMatch
        }
    }
    
    private func addProtocolObfuscation(_ code: String) -> String {
        // Obfuscate protocol names
        let protocolPattern = #"protocol\s+([a-zA-Z_][a-zA-Z0-9_]*)"#
        let regex = try! NSRegularExpression(pattern: protocolPattern, options: [])
        
        return regex.stringByReplacingMatches(in: code, options: [], range: NSRange(location: 0, length: code.count)) { (match, _, _) in
            let fullMatch = String(code[Range(match.range, in: code)!])
            let protocolNameRange = match.range(at: 1)
            let protocolName = String(code[Range(protocolNameRange, in: code)!])
            
            if !isReservedIdentifier(protocolName) {
                let obfuscatedName = "_P" + generateObfuscatedName().prefix(8)
                identifierMap[protocolName] = String(obfuscatedName)
                return fullMatch.replacingOccurrences(of: protocolName, with: String(obfuscatedName))
            }
            return fullMatch
        }
    }
    
    func process(_ code: String, processingOptions: ProcessingOptions = ProcessingOptions()) -> String {
        let key = processingOptions.key ?? options["encryptionKey"] ?? "default_encryption_key_32_chars_"
        
        var result = code
        
        // Apply Swift-specific obfuscations
        result = encryptStrings(result, key: key)
        result = addClassObfuscation(result)
        result = addProtocolObfuscation(result)
        result = obfuscateIdentifiers(result)
        result = addControlFlowObfuscation(result)
        result = addDeadCode(result)
        result = addAntiDebugging(result)
        
        return result
    }
}

// Main function for command-line usage
if CommandLine.argc > 1 {
    let args = Array(CommandLine.arguments.dropFirst())
    
    if args.count < 1 {
        print("Usage: swift SwiftProcessor.swift <input_file> [options]")
        exit(1)
    }
    
    do {
        // Read input file
        let inputPath = args[0]
        let code = try String(contentsOfFile: inputPath, encoding: .utf8)
        
        // Initialize processor with options
        let options = [
            "encryptionKey": "default_encryption_key_32_chars_"
        ]
        
        let processor = SwiftProcessor(options: options)
        
        // Process the code
        let obfuscated = processor.process(code)
        
        // Output result
        print(obfuscated)
        
    } catch {
        print("Error processing file: \(error)")
        exit(1)
    }
}