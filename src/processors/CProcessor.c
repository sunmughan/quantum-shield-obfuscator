#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include <openssl/aes.h>
#include <openssl/rand.h>
#include <openssl/evp.h>

#define MAX_CODE_SIZE 1048576
#define MAX_IDENTIFIERS 10000
#define MAX_STRINGS 5000
#define AES_BLOCK_SIZE 16

typedef struct {
    char original[256];
    char obfuscated[256];
} IdentifierMap;

typedef struct {
    char original[1024];
    char encrypted[2048];
    char varName[64];
} StringMap;

typedef struct {
    char encryptionKey[65];
    int antiDebug;
    int controlFlow;
    int deadCode;
    int stringEncrypt;
    IdentifierMap identifiers[MAX_IDENTIFIERS];
    StringMap strings[MAX_STRINGS];
    int identifierCount;
    int stringCount;
} CProcessorOptions;

// Function prototypes
char* encryptString(const char* plaintext, const char* key);
char* decryptString(const char* ciphertext, const char* key);
char* obfuscateIdentifiers(const char* code, CProcessorOptions* options);
char* encryptStrings(const char* code, const char* key, CProcessorOptions* options);
char* addControlFlowObfuscation(const char* code);
char* addDeadCode(const char* code);
char* addAntiDebugging(const char* code);
char* generateObfuscatedName();
int isReservedKeyword(const char* word);
char* processCode(const char* code, CProcessorOptions* options);

// Reserved C keywords
const char* reservedKeywords[] = {
    "auto", "break", "case", "char", "const", "continue", "default", "do",
    "double", "else", "enum", "extern", "float", "for", "goto", "if",
    "int", "long", "register", "return", "short", "signed", "sizeof", "static",
    "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while",
    "inline", "restrict", "_Bool", "_Complex", "_Imaginary", NULL
};

char* encryptString(const char* plaintext, const char* key) {
    EVP_CIPHER_CTX *ctx;
    int len;
    int ciphertext_len;
    unsigned char *ciphertext;
    unsigned char iv[AES_BLOCK_SIZE];
    
    // Generate random IV
    if (RAND_bytes(iv, AES_BLOCK_SIZE) != 1) {
        return NULL;
    }
    
    // Create and initialize the context
    if (!(ctx = EVP_CIPHER_CTX_new())) {
        return NULL;
    }
    
    // Initialize the encryption operation
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, (unsigned char*)key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    
    // Allocate memory for ciphertext
    ciphertext = malloc(strlen(plaintext) + AES_BLOCK_SIZE + AES_BLOCK_SIZE);
    if (!ciphertext) {
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    
    // Copy IV to beginning of ciphertext
    memcpy(ciphertext, iv, AES_BLOCK_SIZE);
    
    // Encrypt the plaintext
    if (EVP_EncryptUpdate(ctx, ciphertext + AES_BLOCK_SIZE, &len, (unsigned char*)plaintext, strlen(plaintext)) != 1) {
        free(ciphertext);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    ciphertext_len = len;
    
    // Finalize the encryption
    if (EVP_EncryptFinal_ex(ctx, ciphertext + AES_BLOCK_SIZE + len, &len) != 1) {
        free(ciphertext);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    ciphertext_len += len;
    
    // Clean up
    EVP_CIPHER_CTX_free(ctx);
    
    // Convert to base64
    char* base64 = malloc((ciphertext_len + AES_BLOCK_SIZE) * 2);
    EVP_EncodeBlock((unsigned char*)base64, ciphertext, ciphertext_len + AES_BLOCK_SIZE);
    
    free(ciphertext);
    return base64;
}

char* decryptString(const char* ciphertext, const char* key) {
    // Decrypt function implementation
    // This would be included in the obfuscated output
    return NULL; // Placeholder
}

char* generateObfuscatedName() {
    static int counter = 0;
    char* name = malloc(32);
    const char charset[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    srand(time(NULL) + counter++);
    
    // Generate random name starting with letter
    name[0] = charset[rand() % 52];
    
    int length = 8 + (rand() % 8); // 8-15 characters
    for (int i = 1; i < length; i++) {
        if (rand() % 3 == 0) {
            name[i] = '0' + (rand() % 10); // Add numbers
        } else {
            name[i] = charset[rand() % 52];
        }
    }
    
    name[length] = '\0';
    return name;
}

int isReservedKeyword(const char* word) {
    for (int i = 0; reservedKeywords[i] != NULL; i++) {
        if (strcmp(word, reservedKeywords[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

char* obfuscateIdentifiers(const char* code, CProcessorOptions* options) {
    char* result = malloc(strlen(code) * 2);
    strcpy(result, code);
    
    // Simple identifier obfuscation using regex-like pattern matching
    char* pos = result;
    while (*pos) {
        if (isalpha(*pos) || *pos == '_') {
            char identifier[256];
            int len = 0;
            
            // Extract identifier
            while ((isalnum(*pos) || *pos == '_') && len < 255) {
                identifier[len++] = *pos++;
            }
            identifier[len] = '\0';
            
            // Check if it's a reserved keyword
            if (!isReservedKeyword(identifier) && len > 1) {
                // Check if we already have a mapping
                int found = -1;
                for (int i = 0; i < options->identifierCount; i++) {
                    if (strcmp(options->identifiers[i].original, identifier) == 0) {
                        found = i;
                        break;
                    }
                }
                
                if (found == -1 && options->identifierCount < MAX_IDENTIFIERS) {
                    // Create new mapping
                    strcpy(options->identifiers[options->identifierCount].original, identifier);
                    char* obfuscated = generateObfuscatedName();
                    strcpy(options->identifiers[options->identifierCount].obfuscated, obfuscated);
                    free(obfuscated);
                    options->identifierCount++;
                }
            }
        } else {
            pos++;
        }
    }
    
    // Replace identifiers in the code
    for (int i = 0; i < options->identifierCount; i++) {
        char* temp = malloc(strlen(result) * 2);
        char* src = result;
        char* dst = temp;
        
        while (*src) {
            if (strncmp(src, options->identifiers[i].original, strlen(options->identifiers[i].original)) == 0) {
                // Check if it's a whole word
                char prev = (src > result) ? *(src - 1) : ' ';
                char next = *(src + strlen(options->identifiers[i].original));
                
                if (!isalnum(prev) && prev != '_' && !isalnum(next) && next != '_') {
                    strcpy(dst, options->identifiers[i].obfuscated);
                    dst += strlen(options->identifiers[i].obfuscated);
                    src += strlen(options->identifiers[i].original);
                } else {
                    *dst++ = *src++;
                }
            } else {
                *dst++ = *src++;
            }
        }
        *dst = '\0';
        
        free(result);
        result = temp;
    }
    
    return result;
}

char* encryptStrings(const char* code, const char* key, CProcessorOptions* options) {
    char* result = malloc(strlen(code) * 3);
    char* decryptFunction = 
        "\n// String decryption function\n"
        "char* _decrypt_str(const char* encrypted, const char* key) {\n"
        "    // Decryption implementation\n"
        "    EVP_CIPHER_CTX *ctx;\n"
        "    int len, plaintext_len;\n"
        "    unsigned char *plaintext;\n"
        "    unsigned char iv[16];\n"
        "    \n"
        "    // Decode base64\n"
        "    int ciphertext_len = strlen(encrypted);\n"
        "    unsigned char *ciphertext = malloc(ciphertext_len);\n"
        "    EVP_DecodeBlock(ciphertext, (unsigned char*)encrypted, ciphertext_len);\n"
        "    \n"
        "    // Extract IV\n"
        "    memcpy(iv, ciphertext, 16);\n"
        "    \n"
        "    // Decrypt\n"
        "    ctx = EVP_CIPHER_CTX_new();\n"
        "    EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, (unsigned char*)key, iv);\n"
        "    \n"
        "    plaintext = malloc(ciphertext_len);\n"
        "    EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext + 16, ciphertext_len - 16);\n"
        "    plaintext_len = len;\n"
        "    EVP_DecryptFinal_ex(ctx, plaintext + len, &len);\n"
        "    plaintext_len += len;\n"
        "    plaintext[plaintext_len] = '\\0';\n"
        "    \n"
        "    EVP_CIPHER_CTX_free(ctx);\n"
        "    free(ciphertext);\n"
        "    return (char*)plaintext;\n"
        "}\n\n";
    
    strcpy(result, decryptFunction);
    
    // Find and encrypt string literals
    char* pos = (char*)code;
    char* output = result + strlen(result);
    
    while (*pos) {
        if (*pos == '"') {
            // Found string literal
            pos++; // Skip opening quote
            char string_literal[1024];
            int len = 0;
            
            // Extract string content
            while (*pos && *pos != '"' && len < 1023) {
                if (*pos == '\\' && *(pos + 1)) {
                    string_literal[len++] = *pos++; // Copy escape character
                    string_literal[len++] = *pos++; // Copy escaped character
                } else {
                    string_literal[len++] = *pos++;
                }
            }
            string_literal[len] = '\0';
            
            if (*pos == '"') {
                pos++; // Skip closing quote
                
                // Encrypt the string
                char* encrypted = encryptString(string_literal, key);
                if (encrypted) {
                    sprintf(options->strings[options->stringCount].varName, "_str_%d", options->stringCount);
                    strcpy(options->strings[options->stringCount].original, string_literal);
                    strcpy(options->strings[options->stringCount].encrypted, encrypted);
                    
                    // Add variable declaration
                    sprintf(output, "static char* %s = NULL;\n", options->strings[options->stringCount].varName);
                    output += strlen(output);
                    
                    sprintf(output, "if (!%s) %s = _decrypt_str(\"%s\", \"%s\");\n", 
                           options->strings[options->stringCount].varName,
                           options->strings[options->stringCount].varName,
                           encrypted, key);
                    output += strlen(output);
                    
                    // Replace in code with variable reference
                    sprintf(output, "%s", options->strings[options->stringCount].varName);
                    output += strlen(options->strings[options->stringCount].varName);
                    
                    options->stringCount++;
                    free(encrypted);
                }
            }
        } else {
            *output++ = *pos++;
        }
    }
    *output = '\0';
    
    return result;
}

char* addControlFlowObfuscation(const char* code) {
    char* result = malloc(strlen(code) * 2);
    strcpy(result, code);
    
    // Simple control flow obfuscation - convert if statements to switch
    // This is a simplified implementation
    char* pos = strstr(result, "if (");
    while (pos) {
        // Find the condition and blocks
        char* condition_start = pos + 4;
        char* condition_end = strchr(condition_start, ')');
        
        if (condition_end) {
            char condition[256];
            int cond_len = condition_end - condition_start;
            strncpy(condition, condition_start, cond_len);
            condition[cond_len] = '\0';
            
            // Replace with switch statement
            char replacement[1024];
            sprintf(replacement, "switch((%s) ? 1 : 0) { case 1:", condition);
            
            // This is a simplified replacement - full implementation would be more complex
            // For now, just mark the location
            strncpy(pos, replacement, strlen(replacement));
        }
        
        pos = strstr(pos + 1, "if (");
    }
    
    return result;
}

char* addDeadCode(const char* code) {
    char* result = malloc(strlen(code) * 2);
    
    char* deadCodeSnippets[] = {
        "int _dummy1 = rand() % 100;\n",
        "volatile int _dummy2 = time(NULL) & 0xFF;\n",
        "if (_dummy1 > 200) { printf(\"Never executed\"); }\n",
        "for (int _i = 0; _i < 0; _i++) { _dummy2++; }\n"
    };
    
    strcpy(result, code);
    
    // Insert dead code at random positions
    srand(time(NULL));
    for (int i = 0; i < 4; i++) {
        char* insertion_point = strchr(result, '{');
        if (insertion_point) {
            insertion_point++; // Move past the '{'
            
            // Insert dead code
            memmove(insertion_point + strlen(deadCodeSnippets[i]), 
                   insertion_point, 
                   strlen(insertion_point) + 1);
            memcpy(insertion_point, deadCodeSnippets[i], strlen(deadCodeSnippets[i]));
        }
    }
    
    return result;
}

char* addAntiDebugging(const char* code) {
    char* result = malloc(strlen(code) * 2);
    
    char* antiDebugCode = 
        "\n// Anti-debugging measures\n"
        "#include <sys/ptrace.h>\n"
        "#include <signal.h>\n"
        "\nvoid anti_debug_check() {\n"
        "    if (ptrace(PTRACE_TRACEME, 0, 1, 0) == -1) {\n"
        "        exit(1);\n"
        "    }\n"
        "    \n"
        "    // Timing check\n"
        "    clock_t start = clock();\n"
        "    volatile int dummy = 0;\n"
        "    for (int i = 0; i < 1000; i++) dummy++;\n"
        "    clock_t end = clock();\n"
        "    \n"
        "    if ((end - start) > 10000) {\n"
        "        exit(1);\n"
        "    }\n"
        "}\n\n";
    
    strcpy(result, antiDebugCode);
    strcat(result, code);
    
    // Insert anti-debug call at the beginning of main
    char* main_pos = strstr(result, "int main(");
    if (main_pos) {
        char* brace_pos = strchr(main_pos, '{');
        if (brace_pos) {
            brace_pos++; // Move past the '{'
            
            char* call = "\n    anti_debug_check();\n";
            memmove(brace_pos + strlen(call), brace_pos, strlen(brace_pos) + 1);
            memcpy(brace_pos, call, strlen(call));
        }
    }
    
    return result;
}

char* processCode(const char* code, CProcessorOptions* options) {
    char* result = malloc(strlen(code) * 4);
    strcpy(result, code);
    
    // Apply obfuscations based on options
    if (options->stringEncrypt) {
        char* temp = encryptStrings(result, options->encryptionKey, options);
        free(result);
        result = temp;
    }
    
    if (options->controlFlow) {
        char* temp = addControlFlowObfuscation(result);
        free(result);
        result = temp;
    }
    
    if (options->deadCode) {
        char* temp = addDeadCode(result);
        free(result);
        result = temp;
    }
    
    if (options->antiDebug) {
        char* temp = addAntiDebugging(result);
        free(result);
        result = temp;
    }
    
    // Always obfuscate identifiers last
    char* temp = obfuscateIdentifiers(result, options);
    free(result);
    result = temp;
    
    return result;
}

// Main processor interface
int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("Usage: %s <input_file> [options]\n", argv[0]);
        return 1;
    }
    
    // Initialize options
    CProcessorOptions options = {0};
    strcpy(options.encryptionKey, "default_encryption_key_32_chars_");
    options.antiDebug = 1;
    options.controlFlow = 1;
    options.deadCode = 1;
    options.stringEncrypt = 1;
    
    // Read input file
    FILE* file = fopen(argv[1], "r");
    if (!file) {
        printf("Error: Cannot open file %s\n", argv[1]);
        return 1;
    }
    
    char* code = malloc(MAX_CODE_SIZE);
    size_t bytes_read = fread(code, 1, MAX_CODE_SIZE - 1, file);
    code[bytes_read] = '\0';
    fclose(file);
    
    // Process the code
    char* obfuscated = processCode(code, &options);
    
    // Output result
    printf("%s\n", obfuscated);
    
    // Cleanup
    free(code);
    free(obfuscated);
    
    return 0;
}