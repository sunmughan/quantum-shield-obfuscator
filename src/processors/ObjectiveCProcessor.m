#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <mach/mach.h>

@interface ObjectiveCProcessor : NSObject

@property (nonatomic, strong) NSMutableDictionary *options;
@property (nonatomic, strong) NSMutableDictionary *identifierMap;
@property (nonatomic, strong) NSMutableDictionary *stringMap;
@property (nonatomic, strong) NSMutableArray *encryptedStrings;
@property (nonatomic, strong) NSMutableSet *reservedKeywords;
@property (nonatomic, strong) NSMutableSet *stdClasses;

- (instancetype)initWithOptions:(NSDictionary *)options;
- (NSString *)encryptString:(NSString *)plaintext withKey:(NSString *)key;
- (NSString *)generateObfuscatedName;
- (BOOL)isReservedIdentifier:(NSString *)identifier;
- (NSString *)encryptStrings:(NSString *)code withKey:(NSString *)key;
- (NSString *)obfuscateIdentifiers:(NSString *)code;
- (NSString *)addControlFlowObfuscation:(NSString *)code;
- (NSString *)addDeadCode:(NSString *)code;
- (NSString *)addAntiDebugging:(NSString *)code;
- (NSString *)addClassObfuscation:(NSString *)code;
- (NSString *)addMethodObfuscation:(NSString *)code;
- (NSString *)addPropertyObfuscation:(NSString *)code;
- (NSString *)processCode:(NSString *)code withOptions:(NSDictionary *)processingOptions;

@end

@implementation ObjectiveCProcessor

- (instancetype)initWithOptions:(NSDictionary *)options {
    self = [super init];
    if (self) {
        self.options = [NSMutableDictionary dictionaryWithDictionary:options ?: @{}];
        self.identifierMap = [NSMutableDictionary dictionary];
        self.stringMap = [NSMutableDictionary dictionary];
        self.encryptedStrings = [NSMutableArray array];
        
        if (!self.options[@"encryptionKey"]) {
            self.options[@"encryptionKey"] = @"default_encryption_key_32_chars_";
        }
        
        // Initialize reserved keywords
        self.reservedKeywords = [NSMutableSet setWithArray:@[
            @"auto", @"break", @"case", @"char", @"const", @"continue", @"default", @"do",
            @"double", @"else", @"enum", @"extern", @"float", @"for", @"goto", @"if",
            @"int", @"long", @"register", @"return", @"short", @"signed", @"sizeof", @"static",
            @"struct", @"switch", @"typedef", @"union", @"unsigned", @"void", @"volatile", @"while",
            @"@interface", @"@implementation", @"@protocol", @"@property", @"@synthesize",
            @"@dynamic", @"@class", @"@selector", @"@encode", @"@synchronized", @"@try",
            @"@catch", @"@finally", @"@throw", @"@autoreleasepool", @"@import", @"@end",
            @"id", @"Class", @"SEL", @"IMP", @"BOOL", @"YES", @"NO", @"nil", @"Nil", @"NULL",
            @"self", @"super", @"_cmd", @"instancetype", @"typeof", @"__typeof", @"__typeof__"
        ]];
        
        // Initialize standard classes
        self.stdClasses = [NSMutableSet setWithArray:@[
            @"NSObject", @"NSString", @"NSArray", @"NSMutableArray", @"NSDictionary",
            @"NSMutableDictionary", @"NSSet", @"NSMutableSet", @"NSNumber", @"NSData",
            @"NSMutableData", @"NSDate", @"NSDateFormatter", @"NSURL", @"NSURLRequest",
            @"NSURLSession", @"NSURLSessionTask", @"NSError", @"NSException",
            @"NSNotification", @"NSNotificationCenter", @"NSUserDefaults", @"NSBundle",
            @"NSFileManager", @"NSThread", @"NSOperationQueue", @"NSOperation",
            @"NSTimer", @"NSRunLoop", @"NSAutoreleasePool", @"NSLock", @"NSCondition",
            @"UIView", @"UIViewController", @"UIWindow", @"UIApplication", @"UILabel",
            @"UIButton", @"UIImageView", @"UITableView", @"UICollectionView",
            @"UINavigationController", @"UITabBarController", @"UIAlertController",
            @"NSLayoutConstraint", @"UIColor", @"UIFont", @"UIImage", @"UIScreen"
        ]];
    }
    return self;
}

- (NSString *)encryptString:(NSString *)plaintext withKey:(NSString *)key {
    // Ensure key is 32 bytes
    NSMutableData *keyData = [NSMutableData dataWithLength:kCCKeySizeAES256];
    NSData *keyBytes = [key dataUsingEncoding:NSUTF8StringEncoding];
    [keyData replaceBytesInRange:NSMakeRange(0, MIN(keyBytes.length, kCCKeySizeAES256))
                       withBytes:keyBytes.bytes];
    
    // Generate random IV
    NSMutableData *iv = [NSMutableData dataWithLength:kCCBlockSizeAES128];
    SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, iv.mutableBytes);
    
    // Convert plaintext to data
    NSData *plaintextData = [plaintext dataUsingEncoding:NSUTF8StringEncoding];
    
    // Create output buffer
    size_t bufferSize = plaintextData.length + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                         kCCAlgorithmAES,
                                         kCCOptionPKCS7Padding,
                                         keyData.bytes,
                                         kCCKeySizeAES256,
                                         iv.bytes,
                                         plaintextData.bytes,
                                         plaintextData.length,
                                         buffer,
                                         bufferSize,
                                         &numBytesEncrypted);
    
    if (cryptStatus != kCCSuccess) {
        free(buffer);
        return @"";
    }
    
    // Combine IV and encrypted data
    NSMutableData *combined = [NSMutableData dataWithData:iv];
    [combined appendBytes:buffer length:numBytesEncrypted];
    
    free(buffer);
    
    // Encode to Base64
    return [combined base64EncodedStringWithOptions:0];
}

- (NSString *)generateObfuscatedName {
    NSString *charset = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSInteger length = 8 + arc4random_uniform(8); // 8-15 characters
    
    NSMutableString *result = [NSMutableString string];
    
    // First character must be a letter
    [result appendFormat:@"%C", [charset characterAtIndex:arc4random_uniform((uint32_t)charset.length)]];
    
    // Remaining characters can be letters or numbers
    NSString *fullCharset = [charset stringByAppendingString:@"0123456789"];
    for (NSInteger i = 1; i < length; i++) {
        [result appendFormat:@"%C", [fullCharset characterAtIndex:arc4random_uniform((uint32_t)fullCharset.length)]];
    }
    
    return [result copy];
}

- (BOOL)isReservedIdentifier:(NSString *)identifier {
    return [self.reservedKeywords containsObject:identifier] || [self.stdClasses containsObject:identifier];
}

- (NSString *)encryptStrings:(NSString *)code withKey:(NSString *)key {
    NSMutableString *result = [NSMutableString string];
    
    // Add decryption method
    NSString *decryptMethod = @"""
// String decryption utility
#import <CommonCrypto/CommonCrypto.h>

+ (NSString *)decryptString:(NSString *)encrypted withKey:(NSString *)key {
    // Ensure key is 32 bytes
    NSMutableData *keyData = [NSMutableData dataWithLength:kCCKeySizeAES256];
    NSData *keyBytes = [key dataUsingEncoding:NSUTF8StringEncoding];
    [keyData replaceBytesInRange:NSMakeRange(0, MIN(keyBytes.length, kCCKeySizeAES256))
                       withBytes:keyBytes.bytes];
    
    // Decode Base64
    NSData *combined = [[NSData alloc] initWithBase64EncodedString:encrypted options:0];
    if (combined.length < kCCBlockSizeAES128) {
        return @"";
    }
    
    // Extract IV and encrypted data
    NSData *iv = [combined subdataWithRange:NSMakeRange(0, kCCBlockSizeAES128)];
    NSData *encryptedData = [combined subdataWithRange:NSMakeRange(kCCBlockSizeAES128, combined.length - kCCBlockSizeAES128)];
    
    // Create output buffer
    size_t bufferSize = encryptedData.length + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                         kCCAlgorithmAES,
                                         kCCOptionPKCS7Padding,
                                         keyData.bytes,
                                         kCCKeySizeAES256,
                                         iv.bytes,
                                         encryptedData.bytes,
                                         encryptedData.length,
                                         buffer,
                                         bufferSize,
                                         &numBytesDecrypted);
    
    if (cryptStatus != kCCSuccess) {
        free(buffer);
        return @"";
    }
    
    NSString *decrypted = [[NSString alloc] initWithBytes:buffer
                                                   length:numBytesDecrypted
                                                 encoding:NSUTF8StringEncoding];
    free(buffer);
    
    return decrypted ?: @"";
}

""";
    
    [result appendString:decryptMethod];
    
    // Find and encrypt string literals
    NSRegularExpression *stringRegex = [NSRegularExpression regularExpressionWithPattern:@"@\"([^\"\\\\]|\\\\.)*\""
                                                                                 options:0
                                                                                   error:nil];
    
    NSArray *matches = [stringRegex matchesInString:code options:0 range:NSMakeRange(0, code.length)];
    
    NSInteger stringIndex = 0;
    NSInteger lastEnd = 0;
    
    for (NSTextCheckingResult *match in matches) {
        // Add code before the string
        [result appendString:[code substringWithRange:NSMakeRange(lastEnd, match.range.location - lastEnd)]];
        
        NSString *originalString = [code substringWithRange:match.range];
        NSString *content = [originalString substringWithRange:NSMakeRange(2, originalString.length - 3)]; // Remove @" and "
        
        NSString *encrypted = [self encryptString:content withKey:key];
        if (encrypted.length > 0) {
            NSString *varName = [NSString stringWithFormat:@"_str_%ld", (long)stringIndex++];
            
            [self.encryptedStrings addObject:[NSString stringWithFormat:@"static NSString *%@ = nil;\nstatic dispatch_once_t %@_token;\ndispatch_once(&%@_token, ^{\n    %@ = [self decryptString:@\"%@\" withKey:@\"%@\"];\n});",
                                             varName, varName, varName, varName, encrypted, key]];
            
            [result appendString:varName];
        } else {
            [result appendString:originalString];
        }
        
        lastEnd = NSMaxRange(match.range);
    }
    
    // Add remaining code
    [result appendString:[code substringFromIndex:lastEnd]];
    
    // Add string declarations
    NSMutableString *finalResult = [NSMutableString string];
    for (NSString *str in self.encryptedStrings) {
        [finalResult appendFormat:@"%@\n", str];
    }
    [finalResult appendString:result];
    
    return [finalResult copy];
}

- (NSString *)obfuscateIdentifiers:(NSString *)code {
    // Find all identifiers
    NSRegularExpression *identifierRegex = [NSRegularExpression regularExpressionWithPattern:@"\\b[a-zA-Z_][a-zA-Z0-9_]*\\b"
                                                                                     options:0
                                                                                       error:nil];
    
    NSArray *matches = [identifierRegex matchesInString:code options:0 range:NSMakeRange(0, code.length)];
    NSMutableSet *identifiersToObfuscate = [NSMutableSet set];
    
    for (NSTextCheckingResult *match in matches) {
        NSString *identifier = [code substringWithRange:match.range];
        if (![self isReservedIdentifier:identifier] && identifier.length > 1) {
            [identifiersToObfuscate addObject:identifier];
        }
    }
    
    // Generate obfuscated names
    for (NSString *identifier in identifiersToObfuscate) {
        if (!self.identifierMap[identifier]) {
            self.identifierMap[identifier] = [self generateObfuscatedName];
        }
    }
    
    // Replace identifiers
    NSString *result = code;
    for (NSString *original in self.identifierMap) {
        NSString *obfuscated = self.identifierMap[original];
        NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", [NSRegularExpression escapedPatternForString:original]];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        result = [regex stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:obfuscated];
    }
    
    return result;
}

- (NSString *)addControlFlowObfuscation:(NSString *)code {
    // Convert if-else to switch statements
    NSRegularExpression *ifRegex = [NSRegularExpression regularExpressionWithPattern:@"if\\s*\\(([^)]+)\\)\\s*\\{([^}]+)\\}(?:\\s*else\\s*\\{([^}]+)\\})?"
                                                                            options:0
                                                                              error:nil];
    
    NSArray *matches = [ifRegex matchesInString:code options:0 range:NSMakeRange(0, code.length)];
    NSMutableString *result = [NSMutableString stringWithString:code];
    
    // Process matches in reverse order to maintain string indices
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSString *condition = [code substringWithRange:[match rangeAtIndex:1]];
        NSString *ifBlock = [code substringWithRange:[match rangeAtIndex:2]];
        NSString *elseBlock = @"";
        if ([match rangeAtIndex:3].location != NSNotFound) {
            elseBlock = [code substringWithRange:[match rangeAtIndex:3]];
        }
        
        NSString *switchVar = [NSString stringWithFormat:@"_sw%u", arc4random_uniform(10000)];
        NSString *replacement = [NSString stringWithFormat:@"int %@ = (%@) ? 1 : 0;\nswitch (%@) {\n    case 1:\n        %@\n        break;\n    default:\n        %@\n        break;\n}",
                                switchVar, condition, switchVar, ifBlock, elseBlock];
        
        [result replaceCharactersInRange:match.range withString:replacement];
    }
    
    return [result copy];
}

- (NSString *)addDeadCode:(NSString *)code {
    NSArray *deadCodeSnippets = @[
        @"volatile int _dummy1 = arc4random_uniform(100);\n",
        @"volatile long _dummy2 = (long)CFAbsoluteTimeGetCurrent() & 0xFF;\n",
        @"if (_dummy1 > 200) { NSLog(@\"Never executed\"); }\n",
        @"for (int _i = 0; _i < 0; _i++) { _dummy2++; }\n",
        @"NSMutableArray *_dummy_array = [NSMutableArray array];\n"
    ];
    
    NSMutableString *result = [NSMutableString stringWithString:code];
    
    // Find method implementations and insert dead code
    NSRegularExpression *methodRegex = [NSRegularExpression regularExpressionWithPattern:@"[-+]\\s*\\([^)]+\\)[^{]*\\{"
                                                                                 options:0
                                                                                   error:nil];
    
    NSArray *matches = [methodRegex matchesInString:code options:0 range:NSMakeRange(0, code.length)];
    
    NSInteger insertions = 0;
    NSInteger offset = 0;
    
    for (NSTextCheckingResult *match in matches) {
        if (insertions >= 3) break;
        
        NSInteger pos = NSMaxRange(match.range) + offset;
        NSString *deadCode = deadCodeSnippets[arc4random_uniform((uint32_t)deadCodeSnippets.count)];
        [result insertString:[NSString stringWithFormat:@"\n%@", deadCode] atIndex:pos];
        offset += deadCode.length + 1;
        insertions++;
    }
    
    return [result copy];
}

- (NSString *)addAntiDebugging:(NSString *)code {
    NSString *antiDebugCode = @"""
// Anti-debugging measures
#import <sys/sysctl.h>
#import <mach/mach.h>

+ (void)antiDebugCheck {
    // Check for debugger using sysctl
    int mib[4];
    struct kinfo_proc info;
    size_t size = sizeof(info);
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    if (sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0) == 0) {
        if (info.kp_proc.p_flag & P_TRACED) {
            exit(1);
        }
    }
    
    // Check for Xcode debugger
    if (getenv(\"XCODE_VERSION_ACTUAL\") || getenv(\"__XCODE_BUILT_PRODUCTS_DIR_PATHS\")) {
        exit(1);
    }
    
    // Timing check
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    volatile int dummy = 0;
    for (int i = 0; i < 1000; i++) {
        dummy += i;
    }
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    
    if ((end - start) > 0.01) { // 10ms
        exit(1);
    }
    
    // Check for common debugging tools
    NSArray *debuggerProcesses = @[@\"lldb\", @\"gdb\", @\"Xcode\", @\"Instruments\"];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @\"/bin/ps\";
    task.arguments = @[@\"-ax\"];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    for (NSString *debugger in debuggerProcesses) {
        if ([output containsString:debugger]) {
            exit(1);
        }
    }
    
    // Check for jailbreak (iOS specific)
    #if TARGET_OS_IPHONE
    NSArray *jailbreakPaths = @[
        @\"/Applications/Cydia.app\",
        @\"/usr/sbin/sshd\",
        @\"/etc/apt\",
        @\"/private/var/lib/apt/\",
        @\"/private/var/lib/cydia\",
        @\"/private/var/mobile/Library/SBSettings/Themes\",
        @\"/Library/MobileSubstrate/MobileSubstrate.dylib\",
        @\"/bin/bash\",
        @\"/usr/libexec/sftp-server\",
        @\"/usr/bin/ssh\"
    ];
    
    for (NSString *path in jailbreakPaths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            exit(1);
        }
    }
    #endif
}

""";
    
    NSString *result = [antiDebugCode stringByAppendingString:code];
    
    // Insert anti-debug call at the beginning of application:didFinishLaunchingWithOptions: or main
    NSRegularExpression *appDelegateRegex = [NSRegularExpression regularExpressionWithPattern:@"(application:didFinishLaunchingWithOptions:[^{]*\\{)"
                                                                                      options:0
                                                                                        error:nil];
    result = [appDelegateRegex stringByReplacingMatchesInString:result
                                                        options:0
                                                          range:NSMakeRange(0, result.length)
                                                   withTemplate:@"$1\n    [self antiDebugCheck];"];
    
    return result;
}

- (NSString *)addClassObfuscation:(NSString *)code {
    // Obfuscate class names
    NSRegularExpression *classRegex = [NSRegularExpression regularExpressionWithPattern:@"@interface\\s+([a-zA-Z_][a-zA-Z0-9_]*)"
                                                                                options:0
                                                                                  error:nil];
    
    NSArray *matches = [classRegex matchesInString:code options:0 range:NSMakeRange(0, code.length)];
    NSMutableDictionary *classMap = [NSMutableDictionary dictionary];
    
    for (NSTextCheckingResult *match in matches) {
        NSString *className = [code substringWithRange:[match rangeAtIndex:1]];
        if (![self.stdClasses containsObject:className] && !classMap[className]) {
            classMap[className] = [NSString stringWithFormat:@"_C%@", [[self generateObfuscatedName] substringToIndex:8]];
        }
    }
    
    // Replace class names
    NSString *result = code;
    for (NSString *original in classMap) {
        NSString *obfuscated = classMap[original];
        NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", [NSRegularExpression escapedPatternForString:original]];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        result = [regex stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:obfuscated];
    }
    
    return result;
}

- (NSString *)addMethodObfuscation:(NSString *)code {
    // Obfuscate method names
    NSRegularExpression *methodRegex = [NSRegularExpression regularExpressionWithPattern:@"[-+]\\s*\\([^)]+\\)\\s*([a-zA-Z_][a-zA-Z0-9_]*)"
                                                                                 options:0
                                                                                   error:nil];
    
    NSArray *matches = [methodRegex matchesInString:code options:0 range:NSMakeRange(0, code.length)];
    NSMutableDictionary *methodMap = [NSMutableDictionary dictionary];
    
    for (NSTextCheckingResult *match in matches) {
        NSString *methodName = [code substringWithRange:[match rangeAtIndex:1]];
        if (![self isReservedIdentifier:methodName] && methodName.length > 1 && !methodMap[methodName]) {
            methodMap[methodName] = [NSString stringWithFormat:@"_m%@", [[self generateObfuscatedName] substringToIndex:8]];
        }
    }
    
    // Replace method names
    NSString *result = code;
    for (NSString *original in methodMap) {
        NSString *obfuscated = methodMap[original];
        NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", [NSRegularExpression escapedPatternForString:original]];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        result = [regex stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:obfuscated];
    }
    
    return result;
}

- (NSString *)addPropertyObfuscation:(NSString *)code {
    // Obfuscate property names
    NSRegularExpression *propertyRegex = [NSRegularExpression regularExpressionWithPattern:@"@property\\s*\\([^)]*\\)\\s*[^\\s]+\\s+([a-zA-Z_][a-zA-Z0-9_]*)"
                                                                                   options:0
                                                                                     error:nil];
    
    NSArray *matches = [propertyRegex matchesInString:code options:0 range:NSMakeRange(0, code.length)];
    NSMutableDictionary *propertyMap = [NSMutableDictionary dictionary];
    
    for (NSTextCheckingResult *match in matches) {
        NSString *propertyName = [code substringWithRange:[match rangeAtIndex:1]];
        if (![self isReservedIdentifier:propertyName] && propertyName.length > 1 && !propertyMap[propertyName]) {
            propertyMap[propertyName] = [NSString stringWithFormat:@"_p%@", [[self generateObfuscatedName] substringToIndex:8]];
        }
    }
    
    // Replace property names
    NSString *result = code;
    for (NSString *original in propertyMap) {
        NSString *obfuscated = propertyMap[original];
        NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", [NSRegularExpression escapedPatternForString:original]];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        result = [regex stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:obfuscated];
    }
    
    return result;
}

- (NSString *)processCode:(NSString *)code withOptions:(NSDictionary *)processingOptions {
    if (!processingOptions) {
        processingOptions = @{};
    }
    
    NSString *key = processingOptions[@"key"] ?: self.options[@"encryptionKey"];
    
    NSString *result = code;
    
    // Apply Objective-C specific obfuscations
    result = [self encryptStrings:result withKey:key];
    result = [self addClassObfuscation:result];
    result = [self addMethodObfuscation:result];
    result = [self addPropertyObfuscation:result];
    result = [self obfuscateIdentifiers:result];
    result = [self addControlFlowObfuscation:result];
    result = [self addDeadCode:result];
    result = [self addAntiDebugging:result];
    
    return result;
}

@end

// Main function for command-line usage
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            NSLog(@"Usage: %s <input_file> [options]", argv[0]);
            return 1;
        }
        
        // Read input file
        NSString *inputPath = [NSString stringWithUTF8String:argv[1]];
        NSError *error;
        NSString *code = [NSString stringWithContentsOfFile:inputPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:&error];
        
        if (error) {
            NSLog(@"Error reading file: %@", error.localizedDescription);
            return 1;
        }
        
        // Initialize processor with options
        NSDictionary *options = @{
            @"encryptionKey": @"default_encryption_key_32_chars_"
        };
        
        ObjectiveCProcessor *processor = [[ObjectiveCProcessor alloc] initWithOptions:options];
        
        // Process the code
        NSString *obfuscated = [processor processCode:code withOptions:nil];
        
        // Output result
        printf("%s", [obfuscated UTF8String]);
    }
    
    return 0;
}