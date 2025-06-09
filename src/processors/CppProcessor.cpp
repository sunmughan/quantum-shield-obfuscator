#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <regex>
#include <random>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <chrono>
#include <openssl/aes.h>
#include <openssl/rand.h>
#include <openssl/evp.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>

class CppProcessor {
private:
    std::map<std::string, std::string> options;
    std::map<std::string, std::string> identifierMap;
    std::map<std::string, std::string> stringMap;
    std::vector<std::string> encryptedStrings;
    std::mt19937 rng;
    
    // Reserved C++ keywords
    std::vector<std::string> reservedKeywords = {
        "alignas", "alignof", "and", "and_eq", "asm", "atomic_cancel", "atomic_commit",
        "atomic_noexcept", "auto", "bitand", "bitor", "bool", "break", "case",
        "catch", "char", "char8_t", "char16_t", "char32_t", "class", "compl",
        "concept", "const", "consteval", "constexpr", "constinit", "const_cast",
        "continue", "co_await", "co_return", "co_yield", "decltype", "default",
        "delete", "do", "double", "dynamic_cast", "else", "enum", "explicit",
        "export", "extern", "false", "float", "for", "friend", "goto", "if",
        "inline", "int", "long", "mutable", "namespace", "new", "noexcept",
        "not", "not_eq", "nullptr", "operator", "or", "or_eq", "private",
        "protected", "public", "reflexpr", "register", "reinterpret_cast",
        "requires", "return", "short", "signed", "sizeof", "static",
        "static_assert", "static_cast", "struct", "switch", "synchronized",
        "template", "this", "thread_local", "throw", "true", "try", "typedef",
        "typeid", "typename", "union", "unsigned", "using", "virtual", "void",
        "volatile", "wchar_t", "while", "xor", "xor_eq"
    };
    
    // Standard library identifiers to preserve
    std::vector<std::string> stdIdentifiers = {
        "std", "cout", "cin", "endl", "string", "vector", "map", "set", "list",
        "iostream", "fstream", "sstream", "algorithm", "iterator", "memory",
        "shared_ptr", "unique_ptr", "make_shared", "make_unique"
    };

public:
    CppProcessor(const std::map<std::string, std::string>& opts = {}) 
        : options(opts), rng(std::chrono::steady_clock::now().time_since_epoch().count()) {
        if (options.find("encryptionKey") == options.end()) {
            options["encryptionKey"] = "default_encryption_key_32_chars_";
        }
    }
    
    std::string encryptString(const std::string& plaintext, const std::string& key) {
        EVP_CIPHER_CTX *ctx;
        int len;
        int ciphertext_len;
        unsigned char *ciphertext;
        unsigned char iv[AES_BLOCK_SIZE];
        
        // Generate random IV
        if (RAND_bytes(iv, AES_BLOCK_SIZE) != 1) {
            return "";
        }
        
        // Create and initialize the context
        if (!(ctx = EVP_CIPHER_CTX_new())) {
            return "";
        }
        
        // Initialize the encryption operation
        std::string keyPadded = key;
        keyPadded.resize(32, '\0');
        
        if (EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, 
                              reinterpret_cast<const unsigned char*>(keyPadded.c_str()), iv) != 1) {
            EVP_CIPHER_CTX_free(ctx);
            return "";
        }
        
        // Allocate memory for ciphertext
        ciphertext = new unsigned char[plaintext.length() + AES_BLOCK_SIZE + AES_BLOCK_SIZE];
        
        // Copy IV to beginning of ciphertext
        memcpy(ciphertext, iv, AES_BLOCK_SIZE);
        
        // Encrypt the plaintext
        if (EVP_EncryptUpdate(ctx, ciphertext + AES_BLOCK_SIZE, &len, 
                             reinterpret_cast<const unsigned char*>(plaintext.c_str()), 
                             plaintext.length()) != 1) {
            delete[] ciphertext;
            EVP_CIPHER_CTX_free(ctx);
            return "";
        }
        ciphertext_len = len;
        
        // Finalize the encryption
        if (EVP_EncryptFinal_ex(ctx, ciphertext + AES_BLOCK_SIZE + len, &len) != 1) {
            delete[] ciphertext;
            EVP_CIPHER_CTX_free(ctx);
            return "";
        }
        ciphertext_len += len;
        
        // Clean up
        EVP_CIPHER_CTX_free(ctx);
        
        // Convert to base64
        BIO *bio, *b64;
        BUF_MEM *bufferPtr;
        
        b64 = BIO_new(BIO_f_base64());
        bio = BIO_new(BIO_s_mem());
        bio = BIO_push(b64, bio);
        
        BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
        BIO_write(bio, ciphertext, ciphertext_len + AES_BLOCK_SIZE);
        BIO_flush(bio);
        BIO_get_mem_ptr(bio, &bufferPtr);
        
        std::string result(bufferPtr->data, bufferPtr->length);
        
        BIO_free_all(bio);
        delete[] ciphertext;
        
        return result;
    }
    
    std::string generateObfuscatedName() {
        const std::string charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        std::uniform_int_distribution<> lengthDist(8, 16);
        std::uniform_int_distribution<> charDist(0, charset.length() - 1);
        
        int length = lengthDist(rng);
        std::string result;
        result.reserve(length);
        
        // First character must be a letter
        result += charset[charDist(rng)];
        
        // Remaining characters can be letters or numbers
        const std::string fullCharset = charset + "0123456789";
        std::uniform_int_distribution<> fullCharDist(0, fullCharset.length() - 1);
        
        for (int i = 1; i < length; ++i) {
            result += fullCharset[fullCharDist(rng)];
        }
        
        return result;
    }
    
    bool isReservedIdentifier(const std::string& identifier) {
        return std::find(reservedKeywords.begin(), reservedKeywords.end(), identifier) != reservedKeywords.end() ||
               std::find(stdIdentifiers.begin(), stdIdentifiers.end(), identifier) != stdIdentifiers.end();
    }
    
    std::string encryptStrings(const std::string& code, const std::string& key) {
        std::string result = code;
        std::regex stringPattern(R"("([^"\\]|\\.)*")");
        std::sregex_iterator iter(code.begin(), code.end(), stringPattern);
        std::sregex_iterator end;
        
        std::vector<std::pair<std::string, std::string>> replacements;
        int stringIndex = 0;
        
        for (; iter != end; ++iter) {
            std::string originalString = iter->str();
            std::string content = originalString.substr(1, originalString.length() - 2); // Remove quotes
            
            std::string encrypted = encryptString(content, key);
            if (!encrypted.empty()) {
                std::string varName = "_str_" + std::to_string(stringIndex++);
                
                encryptedStrings.push_back(
                    "static std::string " + varName + " = _decrypt_str(\"" + encrypted + "\", \"" + key + "\");"
                );
                
                replacements.push_back({originalString, varName});
            }
        }
        
        // Replace strings with variable references
        for (const auto& replacement : replacements) {
            size_t pos = 0;
            while ((pos = result.find(replacement.first, pos)) != std::string::npos) {
                result.replace(pos, replacement.first.length(), replacement.second);
                pos += replacement.second.length();
            }
        }
        
        // Add decryption function
        std::string decryptFunction = R"(
// String decryption function
#include <openssl/evp.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>

std::string _decrypt_str(const std::string& encrypted, const std::string& key) {
    // Base64 decode
    BIO *bio, *b64;
    int decodeLen = encrypted.length();
    unsigned char *buffer = new unsigned char[decodeLen];
    
    bio = BIO_new_mem_buf(encrypted.c_str(), -1);
    b64 = BIO_new(BIO_f_base64());
    bio = BIO_push(b64, bio);
    
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
    int length = BIO_read(bio, buffer, encrypted.length());
    BIO_free_all(bio);
    
    // Extract IV
    unsigned char iv[16];
    memcpy(iv, buffer, 16);
    
    // Decrypt
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    std::string keyPadded = key;
    keyPadded.resize(32, '\0');
    
    EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, 
                      reinterpret_cast<const unsigned char*>(keyPadded.c_str()), iv);
    
    unsigned char *plaintext = new unsigned char[length];
    int len, plaintext_len;
    
    EVP_DecryptUpdate(ctx, plaintext, &len, buffer + 16, length - 16);
    plaintext_len = len;
    EVP_DecryptFinal_ex(ctx, plaintext + len, &len);
    plaintext_len += len;
    
    std::string result(reinterpret_cast<char*>(plaintext), plaintext_len);
    
    EVP_CIPHER_CTX_free(ctx);
    delete[] buffer;
    delete[] plaintext;
    
    return result;
}

)";
        
        // Add string declarations
        std::string stringDeclarations;
        for (const auto& str : encryptedStrings) {
            stringDeclarations += str + "\n";
        }
        
        return decryptFunction + stringDeclarations + result;
    }
    
    std::string obfuscateIdentifiers(const std::string& code) {
        std::string result = code;
        std::regex identifierPattern(R"(\b[a-zA-Z_][a-zA-Z0-9_]*\b)");
        std::sregex_iterator iter(code.begin(), code.end(), identifierPattern);
        std::sregex_iterator end;
        
        std::set<std::string> identifiersToObfuscate;
        
        // Collect identifiers
        for (; iter != end; ++iter) {
            std::string identifier = iter->str();
            if (!isReservedIdentifier(identifier) && identifier.length() > 1) {
                identifiersToObfuscate.insert(identifier);
            }
        }
        
        // Generate obfuscated names
        for (const auto& identifier : identifiersToObfuscate) {
            if (identifierMap.find(identifier) == identifierMap.end()) {
                identifierMap[identifier] = generateObfuscatedName();
            }
        }
        
        // Replace identifiers
        for (const auto& mapping : identifierMap) {
            std::regex replacePattern("\\b" + mapping.first + "\\b");
            result = std::regex_replace(result, replacePattern, mapping.second);
        }
        
        return result;
    }
    
    std::string addControlFlowObfuscation(const std::string& code) {
        std::string result = code;
        
        // Convert if-else to switch statements
        std::regex ifPattern(R"(if\s*\(([^)]+)\)\s*\{([^}]+)\}(?:\s*else\s*\{([^}]+)\})?)");
        
        result = std::regex_replace(result, ifPattern, [this](const std::smatch& match) {
            std::string condition = match[1].str();
            std::string ifBlock = match[2].str();
            std::string elseBlock = match[3].str();
            
            std::string switchVar = "_sw" + std::to_string(rng() % 10000);
            std::string replacement = "int " + switchVar + " = (" + condition + ") ? 1 : 0;\n";
            replacement += "switch (" + switchVar + ") {\n";
            replacement += "    case 1:\n        " + ifBlock + "\n        break;\n";
            
            if (!elseBlock.empty()) {
                replacement += "    default:\n        " + elseBlock + "\n        break;\n";
            }
            
            replacement += "}";
            return replacement;
        });
        
        return result;
    }
    
    std::string addDeadCode(const std::string& code) {
        std::vector<std::string> deadCodeSnippets = {
            "volatile int _dummy1 = std::rand() % 100;\n",
            "volatile auto _dummy2 = std::chrono::steady_clock::now().time_since_epoch().count() & 0xFF;\n",
            "if (_dummy1 > 200) { std::cout << \"Never executed\"; }\n",
            "for (int _i = 0; _i < 0; ++_i) { _dummy2++; }\n",
            "std::vector<int> _dummy_vec; _dummy_vec.reserve(0);\n"
        };
        
        std::string result = code;
        std::uniform_int_distribution<> snippetDist(0, deadCodeSnippets.size() - 1);
        
        // Find function bodies and insert dead code
        std::regex functionPattern(R"(\{)");
        std::sregex_iterator iter(code.begin(), code.end(), functionPattern);
        std::sregex_iterator end;
        
        int insertions = 0;
        for (; iter != end && insertions < 3; ++iter, ++insertions) {
            size_t pos = iter->position() + 1;
            std::string deadCode = deadCodeSnippets[snippetDist(rng)];
            result.insert(pos + insertions * deadCode.length(), deadCode);
        }
        
        return result;
    }
    
    std::string addAntiDebugging(const std::string& code) {
        std::string antiDebugCode = R"(
// Anti-debugging measures
#include <chrono>
#include <thread>
#ifdef _WIN32
#include <windows.h>
#include <debugapi.h>
#else
#include <sys/ptrace.h>
#include <unistd.h>
#endif

class AntiDebug {
public:
    static void check() {
#ifdef _WIN32
        if (IsDebuggerPresent()) {
            std::exit(1);
        }
        
        BOOL debuggerPresent = FALSE;
        CheckRemoteDebuggerPresent(GetCurrentProcess(), &debuggerPresent);
        if (debuggerPresent) {
            std::exit(1);
        }
#else
        if (ptrace(PTRACE_TRACEME, 0, 1, 0) == -1) {
            std::exit(1);
        }
#endif
        
        // Timing check
        auto start = std::chrono::high_resolution_clock::now();
        volatile int dummy = 0;
        for (int i = 0; i < 1000; ++i) {
            dummy += i;
        }
        auto end = std::chrono::high_resolution_clock::now();
        
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
        if (duration.count() > 10000) {
            std::exit(1);
        }
    }
};

)";
        
        std::string result = antiDebugCode + code;
        
        // Insert anti-debug call at the beginning of main
        std::regex mainPattern(R"(int\s+main\s*\([^)]*\)\s*\{)");
        result = std::regex_replace(result, mainPattern, "$&\n    AntiDebug::check();");
        
        return result;
    }
    
    std::string addClassObfuscation(const std::string& code) {
        std::string result = code;
        
        // Obfuscate class names
        std::regex classPattern(R"(class\s+([a-zA-Z_][a-zA-Z0-9_]*))");
        std::sregex_iterator iter(code.begin(), code.end(), classPattern);
        std::sregex_iterator end;
        
        std::map<std::string, std::string> classMap;
        
        for (; iter != end; ++iter) {
            std::string className = iter->str(1);
            if (classMap.find(className) == classMap.end()) {
                classMap[className] = "_C" + generateObfuscatedName().substr(0, 8);
            }
        }
        
        // Replace class names
        for (const auto& mapping : classMap) {
            std::regex replacePattern("\\b" + mapping.first + "\\b");
            result = std::regex_replace(result, replacePattern, mapping.second);
        }
        
        return result;
    }
    
    std::string addTemplateObfuscation(const std::string& code) {
        std::string result = code;
        
        // Obfuscate template parameters
        std::regex templatePattern(R"(template\s*<([^>]+)>)");
        
        result = std::regex_replace(result, templatePattern, [this](const std::smatch& match) {
            std::string params = match[1].str();
            
            // Simple obfuscation of template parameter names
            std::regex paramPattern(R"(\b([a-zA-Z_][a-zA-Z0-9_]*)\b)");
            params = std::regex_replace(params, paramPattern, [this](const std::smatch& paramMatch) {
                std::string param = paramMatch[1].str();
                if (param != "typename" && param != "class" && param != "int" && param != "bool") {
                    return "_T" + std::to_string(rng() % 1000);
                }
                return param;
            });
            
            return "template<" + params + ">";
        });
        
        return result;
    }
    
    std::string process(const std::string& code, const std::map<std::string, std::string>& processingOptions = {}) {
        std::string key = processingOptions.count("key") ? 
                         processingOptions.at("key") : 
                         options["encryptionKey"];
        
        std::string result = code;
        
        // Apply C++-specific obfuscations
        result = encryptStrings(result, key);
        result = addClassObfuscation(result);
        result = addTemplateObfuscation(result);
        result = obfuscateIdentifiers(result);
        result = addControlFlowObfuscation(result);
        result = addDeadCode(result);
        result = addAntiDebugging(result);
        
        return result;
    }
};

// Main processor interface
int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cout << "Usage: " << argv[0] << " <input_file> [options]" << std::endl;
        return 1;
    }
    
    // Read input file
    std::ifstream file(argv[1]);
    if (!file.is_open()) {
        std::cerr << "Error: Cannot open file " << argv[1] << std::endl;
        return 1;
    }
    
    std::stringstream buffer;
    buffer << file.rdbuf();
    std::string code = buffer.str();
    file.close();
    
    // Initialize processor with options
    std::map<std::string, std::string> options;
    options["encryptionKey"] = "default_encryption_key_32_chars_";
    
    CppProcessor processor(options);
    
    // Process the code
    std::string obfuscated = processor.process(code);
    
    // Output result
    std::cout << obfuscated << std::endl;
    
    return 0;
}