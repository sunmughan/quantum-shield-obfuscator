package main

import (
	"crypto/aes"
	"crypto/cipher"
	cryptorand "crypto/rand"
	"encoding/base64"
	"fmt"
	"io"
	"math/rand"
	"os"
	"regexp"
	"strings"
	"time"
)

// GolangProcessor handles Go code obfuscation
type GolangProcessor struct {
	Options         map[string]string
	IdentifierMap   map[string]string
	StringMap       map[string]string
	EncryptedStrings []string
	Random          *rand.Rand
}

// Reserved Go keywords
var reservedKeywords = map[string]bool{
	"break": true, "case": true, "chan": true, "const": true, "continue": true,
	"default": true, "defer": true, "else": true, "fallthrough": true, "for": true,
	"func": true, "go": true, "goto": true, "if": true, "import": true,
	"interface": true, "map": true, "package": true, "range": true, "return": true,
	"select": true, "struct": true, "switch": true, "type": true, "var": true,
	"true": true, "false": true, "nil": true, "iota": true,
}

// Standard library packages to preserve
var stdPackages = map[string]bool{
	"fmt": true, "os": true, "io": true, "strings": true, "strconv": true,
	"time": true, "math": true, "crypto": true, "encoding": true, "net": true,
	"http": true, "json": true, "xml": true, "regexp": true, "sort": true,
	"sync": true, "context": true, "errors": true, "log": true, "runtime": true,
	"reflect": true, "unsafe": true, "bytes": true, "bufio": true, "path": true,
	"filepath": true, "url": true, "template": true, "html": true, "unicode": true,
}

// NewGolangProcessor creates a new Go processor
func NewGolangProcessor(options map[string]string) *GolangProcessor {
	if options == nil {
		options = make(map[string]string)
	}
	
	if _, exists := options["encryptionKey"]; !exists {
		options["encryptionKey"] = "default_encryption_key_32_chars_"
	}
	
	return &GolangProcessor{
		Options:         options,
		IdentifierMap:   make(map[string]string),
		StringMap:       make(map[string]string),
		EncryptedStrings: make([]string, 0),
		Random:          rand.New(rand.NewSource(time.Now().UnixNano())),
	}
}

// EncryptString encrypts a string using AES-256-CBC
func (gp *GolangProcessor) EncryptString(plaintext, key string) string {
	// Ensure key is 32 bytes
	keyBytes := make([]byte, 32)
	copy(keyBytes, []byte(key))
	
	// Create cipher block
	block, err := aes.NewCipher(keyBytes)
	if err != nil {
		return ""
	}
	
	// Generate random IV
	iv := make([]byte, aes.BlockSize)
	if _, err := io.ReadFull(cryptorand.Reader, iv); err != nil {
		return ""
	}
	
	// Pad plaintext
	plaintextBytes := []byte(plaintext)
	padding := aes.BlockSize - len(plaintextBytes)%aes.BlockSize
	for i := 0; i < padding; i++ {
		plaintextBytes = append(plaintextBytes, byte(padding))
	}
	
	// Encrypt
	mode := cipher.NewCBCEncrypter(block, iv)
	ciphertext := make([]byte, len(plaintextBytes))
	mode.CryptBlocks(ciphertext, plaintextBytes)
	
	// Combine IV and ciphertext
	result := append(iv, ciphertext...)
	return base64.StdEncoding.EncodeToString(result)
}

// GenerateObfuscatedName generates a random identifier name
func (gp *GolangProcessor) GenerateObfuscatedName() string {
	charset := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	length := 8 + gp.Random.Intn(8) // 8-15 characters
	
	result := make([]byte, length)
	
	// First character must be a letter
	result[0] = charset[gp.Random.Intn(len(charset))]
	
	// Remaining characters can be letters or numbers
	fullCharset := charset + "0123456789"
	for i := 1; i < length; i++ {
		result[i] = fullCharset[gp.Random.Intn(len(fullCharset))]
	}
	
	return string(result)
}

// IsReservedIdentifier checks if an identifier is reserved
func (gp *GolangProcessor) IsReservedIdentifier(identifier string) bool {
	return reservedKeywords[identifier] || stdPackages[identifier]
}

// EncryptStrings encrypts string literals in Go code
func (gp *GolangProcessor) EncryptStrings(code, key string) string {
	var result strings.Builder
	
	// Add decryption function
	decryptFunc := `
import (
	"crypto/aes"
	"crypto/cipher"
	"encoding/base64"
)

// String decryption utility
func decryptString(encrypted, key string) string {
	// Ensure key is 32 bytes
	keyBytes := make([]byte, 32)
	copy(keyBytes, []byte(key))
	
	// Decode base64
	data, err := base64.StdEncoding.DecodeString(encrypted)
	if err != nil {
		return ""
	}
	
	// Extract IV and ciphertext
	if len(data) < aes.BlockSize {
		return ""
	}
	
	iv := data[:aes.BlockSize]
	ciphertext := data[aes.BlockSize:]
	
	// Create cipher block
	block, err := aes.NewCipher(keyBytes)
	if err != nil {
		return ""
	}
	
	// Decrypt
	mode := cipher.NewCBCDecrypter(block, iv)
	plaintext := make([]byte, len(ciphertext))
	mode.CryptBlocks(plaintext, ciphertext)
	
	// Remove padding
	if len(plaintext) > 0 {
		padding := int(plaintext[len(plaintext)-1])
		if padding <= aes.BlockSize && padding <= len(plaintext) {
			plaintext = plaintext[:len(plaintext)-padding]
		}
	}
	
	return string(plaintext)
}

`
	
	result.WriteString(decryptFunc)
	
	// Find and encrypt string literals
	stringPattern := regexp.MustCompile(`"([^"\\]|\\.)*"`)
	matches := stringPattern.FindAllStringIndex(code, -1)
	
	stringIndex := 0
	lastEnd := 0
	
	for _, match := range matches {
		// Add code before the string
		result.WriteString(code[lastEnd:match[0]])
		
		originalString := code[match[0]:match[1]]
		content := originalString[1 : len(originalString)-1] // Remove quotes
		
		encrypted := gp.EncryptString(content, key)
		if encrypted != "" {
			varName := fmt.Sprintf("_str_%d", stringIndex)
			stringIndex++
			
			gp.EncryptedStrings = append(gp.EncryptedStrings,
				fmt.Sprintf("var %s = decryptString(\"%s\", \"%s\")", varName, encrypted, key))
			
			result.WriteString(varName)
		} else {
			result.WriteString(originalString)
		}
		
		lastEnd = match[1]
	}
	
	// Add remaining code
	result.WriteString(code[lastEnd:])
	
	// Add string declarations at the beginning
	finalResult := strings.Builder{}
	for _, str := range gp.EncryptedStrings {
		finalResult.WriteString(str + "\n")
	}
	finalResult.WriteString(result.String())
	
	return finalResult.String()
}

// ObfuscateIdentifiers obfuscates variable and function names
func (gp *GolangProcessor) ObfuscateIdentifiers(code string) string {
	// Find all identifiers
	identifierPattern := regexp.MustCompile(`\b[a-zA-Z_][a-zA-Z0-9_]*\b`)
	matches := identifierPattern.FindAllString(code, -1)
	
	identifiersToObfuscate := make(map[string]bool)
	
	for _, identifier := range matches {
		if !gp.IsReservedIdentifier(identifier) && len(identifier) > 1 {
			identifiersToObfuscate[identifier] = true
		}
	}
	
	// Generate obfuscated names
	for identifier := range identifiersToObfuscate {
		if _, exists := gp.IdentifierMap[identifier]; !exists {
			gp.IdentifierMap[identifier] = gp.GenerateObfuscatedName()
		}
	}
	
	// Replace identifiers
	result := code
	for original, obfuscated := range gp.IdentifierMap {
		pattern := regexp.MustCompile(`\b` + regexp.QuoteMeta(original) + `\b`)
		result = pattern.ReplaceAllString(result, obfuscated)
	}
	
	return result
}

// AddControlFlowObfuscation adds control flow obfuscation
func (gp *GolangProcessor) AddControlFlowObfuscation(code string) string {
	// Convert if-else to switch statements
	ifPattern := regexp.MustCompile(`if\s+([^{]+)\s*{([^}]+)}(?:\s*else\s*{([^}]+)})?`)
	matches := ifPattern.FindAllStringSubmatch(code, -1)
	
	result := code
	
	for _, match := range matches {
		condition := strings.TrimSpace(match[1])
		ifBlock := strings.TrimSpace(match[2])
		elseBlock := ""
		if len(match) > 3 {
			elseBlock = strings.TrimSpace(match[3])
		}
		
		switchVar := fmt.Sprintf("_sw%d", gp.Random.Intn(10000))
		replacement := fmt.Sprintf(`%s := 0
		if %s {
			%s = 1
		}
		switch %s {
		case 1:
			%s
		default:
			%s
		}`, switchVar, condition, switchVar, switchVar, ifBlock, elseBlock)
		
		result = strings.Replace(result, match[0], replacement, 1)
	}
	
	return result
}

// AddDeadCode adds dead code to confuse analysis
func (gp *GolangProcessor) AddDeadCode(code string) string {
	deadCodeSnippets := []string{
		"var _dummy1 = 42\n",
		"var _dummy2 = int64(1234567890)\n",
		"if _dummy1 > 200 { _ = _dummy1 }\n",
		"for _i := 0; _i < 0; _i++ { _dummy2++ }\n",
		"var _dummy_slice = make([]int, 0)\n_ = _dummy_slice\n",
	}
	
	result := code
	
	// Find function bodies and insert dead code
	funcPattern := regexp.MustCompile(`func\s+[^{]*{`)
	matches := funcPattern.FindAllStringIndex(code, -1)
	
	insertions := 0
	offset := 0
	
	for _, match := range matches {
		if insertions >= 3 {
			break
		}
		
		pos := match[1] + offset
		deadCode := deadCodeSnippets[gp.Random.Intn(len(deadCodeSnippets))]
		result = result[:pos] + "\n" + deadCode + result[pos:]
		offset += len(deadCode) + 1
		insertions++
	}
	
	return result
}

// AddAntiDebugging adds anti-debugging measures
func (gp *GolangProcessor) AddAntiDebugging(code string) string {
	antiDebugCode := `
import (
	"os"
	"strings"
	"time"
	"runtime"
)

// Anti-debugging measures
func antiDebugCheck() {
	// Check for debugger environment variables
	if os.Getenv("DELVE_DEBUGGER") != "" || os.Getenv("GODEBUG") != "" {
		os.Exit(1)
	}
	
	// Check for common debugging tools in command line
	for _, arg := range os.Args {
		if strings.Contains(arg, "dlv") || strings.Contains(arg, "debug") {
			os.Exit(1)
		}
	}
	
	// Timing check
	start := time.Now()
	dummy := 0
	for i := 0; i < 1000; i++ {
		dummy += i
	}
	_ = dummy // Use dummy to avoid unused variable error
	end := time.Now()
	
	if end.Sub(start) > 10*time.Millisecond {
		os.Exit(1)
	}
	
	// Check for goroutine count (debuggers often create additional goroutines)
	if runtime.NumGoroutine() > 10 {
		os.Exit(1)
	}
	
	// Check for race detector
	if os.Getenv("GORACE") != "" {
		os.Exit(1)
	}
}

`
	
	result := antiDebugCode + code
	
	// Insert anti-debug call at the beginning of main function
	mainPattern := regexp.MustCompile(`(func\s+main\s*\(\s*\)\s*{)`)
	result = mainPattern.ReplaceAllString(result, "${1}\n\tantiDebugCheck()")
	
	return result
}

// AddPackageObfuscation obfuscates package and import names
func (gp *GolangProcessor) AddPackageObfuscation(code string) string {
	// Obfuscate custom package names (not standard library)
	packagePattern := regexp.MustCompile(`package\s+([a-zA-Z_][a-zA-Z0-9_]*)`)
	matches := packagePattern.FindAllStringSubmatch(code, -1)
	
	packageMap := make(map[string]string)
	
	for _, match := range matches {
		packageName := match[1]
		if !stdPackages[packageName] && packageName != "main" {
			if _, exists := packageMap[packageName]; !exists {
				packageMap[packageName] = "_pkg" + gp.GenerateObfuscatedName()[:8]
			}
		}
	}
	
	// Replace package names
	result := code
	for original, obfuscated := range packageMap {
		pattern := regexp.MustCompile(`\b` + regexp.QuoteMeta(original) + `\b`)
		result = pattern.ReplaceAllString(result, obfuscated)
	}
	
	return result
}

// AddStructObfuscation obfuscates struct field names
func (gp *GolangProcessor) AddStructObfuscation(code string) string {
	// Find struct definitions
	structPattern := regexp.MustCompile(`type\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+struct\s*{([^}]+)}`)
	matches := structPattern.FindAllStringSubmatch(code, -1)
	
	fieldMap := make(map[string]string)
	
	for _, match := range matches {
		fields := match[2]
		
		// Find field names
		fieldPattern := regexp.MustCompile(`\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+[^\n]+`)
		fieldMatches := fieldPattern.FindAllStringSubmatch(fields, -1)
		
		for _, fieldMatch := range fieldMatches {
			fieldName := fieldMatch[1]
			if len(fieldName) > 1 && !gp.IsReservedIdentifier(fieldName) {
				if _, exists := fieldMap[fieldName]; !exists {
					fieldMap[fieldName] = "_f" + gp.GenerateObfuscatedName()[:8]
				}
			}
		}
	}
	
	// Replace field names
	result := code
	for original, obfuscated := range fieldMap {
		pattern := regexp.MustCompile(`\b` + regexp.QuoteMeta(original) + `\b`)
		result = pattern.ReplaceAllString(result, obfuscated)
	}
	
	return result
}

// Process applies all obfuscation techniques to Go code
func (gp *GolangProcessor) Process(code string, processingOptions map[string]string) string {
	if processingOptions == nil {
		processingOptions = make(map[string]string)
	}
	
	key := processingOptions["key"]
	if key == "" {
		key = gp.Options["encryptionKey"]
	}
	
	result := code
	
	// Apply Go-specific obfuscations
	result = gp.EncryptStrings(result, key)
	result = gp.AddPackageObfuscation(result)
	result = gp.AddStructObfuscation(result)
	result = gp.ObfuscateIdentifiers(result)
	result = gp.AddControlFlowObfuscation(result)
	result = gp.AddDeadCode(result)
	result = gp.AddAntiDebugging(result)
	
	return result
}

// Main function for command-line usage
func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run GolangProcessor.go <input_file> [options]")
		os.Exit(1)
	}
	
	// Read input file
	content, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		os.Exit(1)
	}
	
	// Initialize processor with options
	options := map[string]string{
		"encryptionKey": "default_encryption_key_32_chars_",
	}
	
	processor := NewGolangProcessor(options)
	
	// Process the code
	obfuscated := processor.Process(string(content), nil)
	
	// Output result
	fmt.Print(obfuscated)
}