import java.io.*;
import java.nio.file.*;
import java.security.SecureRandom;
import java.util.*;
import java.util.regex.*;
import javax.crypto.*;
import javax.crypto.spec.*;
import java.util.Base64;


public class JavaProcessor {
    private Map<String, String> options;
    private Map<String, String> identifierMap;
    private Map<String, String> stringMap;
    private List<String> encryptedStrings;
    private Random random;
    
    // Reserved Java keywords
    private static final Set<String> RESERVED_KEYWORDS = new HashSet<>(Arrays.asList(
        "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char",
        "class", "const", "continue", "default", "do", "double", "else", "enum",
        "extends", "final", "finally", "float", "for", "goto", "if", "implements",
        "import", "instanceof", "int", "interface", "long", "native", "new",
        "package", "private", "protected", "public", "return", "short", "static",
        "strictfp", "super", "switch", "synchronized", "this", "throw", "throws",
        "transient", "try", "void", "volatile", "while", "true", "false", "null"
    ));
    
    // Standard library classes to preserve
    private static final Set<String> STD_CLASSES = new HashSet<>(Arrays.asList(
        "String", "Object", "Class", "System", "Math", "Integer", "Double", "Float",
        "Long", "Boolean", "Character", "Byte", "Short", "ArrayList", "HashMap",
        "HashSet", "LinkedList", "TreeMap", "TreeSet", "Vector", "Hashtable",
        "StringBuilder", "StringBuffer", "Exception", "RuntimeException",
        "IOException", "FileInputStream", "FileOutputStream", "BufferedReader",
        "BufferedWriter", "PrintWriter", "Scanner"
    ));
    
    public JavaProcessor() {
        this(new HashMap<>());
    }
    
    public JavaProcessor(Map<String, String> options) {
        this.options = new HashMap<>(options);
        this.identifierMap = new HashMap<>();
        this.stringMap = new HashMap<>();
        this.encryptedStrings = new ArrayList<>();
        this.random = new SecureRandom();
        
        if (!this.options.containsKey("encryptionKey")) {
            this.options.put("encryptionKey", "default_encryption_key_32_chars_");
        }
    }
    
    public String encryptString(String plaintext, String key) {
        try {
            // Ensure key is 32 bytes
            byte[] keyBytes = Arrays.copyOf(key.getBytes("UTF-8"), 32);
            
            // Generate random IV
            byte[] iv = new byte[16];
            new SecureRandom().nextBytes(iv);
            
            // Create cipher
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            SecretKeySpec secretKey = new SecretKeySpec(keyBytes, "AES");
            IvParameterSpec ivSpec = new IvParameterSpec(iv);
            
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, ivSpec);
            
            // Encrypt
            byte[] encrypted = cipher.doFinal(plaintext.getBytes("UTF-8"));
            
            // Combine IV and encrypted data
            byte[] combined = new byte[iv.length + encrypted.length];
            System.arraycopy(iv, 0, combined, 0, iv.length);
            System.arraycopy(encrypted, 0, combined, iv.length, encrypted.length);
            
            // Encode to Base64
            return Base64.getEncoder().encodeToString(combined);
            
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
    }
    
    public String generateObfuscatedName() {
        String charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        int length = 8 + random.nextInt(8); // 8-15 characters
        
        StringBuilder result = new StringBuilder();
        
        // First character must be a letter
        result.append(charset.charAt(random.nextInt(charset.length())));
        
        // Remaining characters can be letters or numbers
        String fullCharset = charset + "0123456789";
        for (int i = 1; i < length; i++) {
            result.append(fullCharset.charAt(random.nextInt(fullCharset.length())));
        }
        
        return result.toString();
    }
    
    public boolean isReservedIdentifier(String identifier) {
        return RESERVED_KEYWORDS.contains(identifier) || STD_CLASSES.contains(identifier);
    }
    
    public String encryptStrings(String code, String key) {
        StringBuilder result = new StringBuilder();
        
        // Add decryption method
        String decryptMethod = """
            // String decryption utility
            import javax.crypto.*;
            import javax.crypto.spec.*;
            import java.util.Base64;
            
            public static class StringDecryptor {
                public static String decrypt(String encrypted, String key) {
                    try {
                        byte[] keyBytes = java.util.Arrays.copyOf(key.getBytes("UTF-8"), 32);
                        byte[] combined = Base64.getDecoder().decode(encrypted);
                        
                        // Extract IV
                        byte[] iv = new byte[16];
                        System.arraycopy(combined, 0, iv, 0, 16);
                        
                        // Extract encrypted data
                        byte[] encryptedData = new byte[combined.length - 16];
                        System.arraycopy(combined, 16, encryptedData, 0, encryptedData.length);
                        
                        // Decrypt
                        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
                        SecretKeySpec secretKey = new SecretKeySpec(keyBytes, "AES");
                        IvParameterSpec ivSpec = new IvParameterSpec(iv);
                        
                        cipher.init(Cipher.DECRYPT_MODE, secretKey, ivSpec);
                        byte[] decrypted = cipher.doFinal(encryptedData);
                        
                        return new String(decrypted, "UTF-8");
                    } catch (Exception e) {
                        return "";
                    }
                }
            }
            
            """;
        
        result.append(decryptMethod);
        
        // Find and encrypt string literals
        Pattern stringPattern = Pattern.compile("\"([^\"\\\\]|\\\\.)*\"");
        Matcher matcher = stringPattern.matcher(code);
        
        StringBuffer sb = new StringBuffer();
        int stringIndex = 0;
        
        while (matcher.find()) {
            String originalString = matcher.group();
            String content = originalString.substring(1, originalString.length() - 1); // Remove quotes
            
            String encrypted = encryptString(content, key);
            if (!encrypted.isEmpty()) {
                String varName = "_str_" + stringIndex++;
                
                // Store mapping in stringMap
                stringMap.put(originalString, varName);
                
                encryptedStrings.add(
                    "private static final String " + varName + 
                    " = StringDecryptor.decrypt(\"" + encrypted + "\", \"" + key + "\");"
                );
                
                matcher.appendReplacement(sb, varName);
            }
        }
        matcher.appendTail(sb);
        
        // Add string declarations
        for (String str : encryptedStrings) {
            result.append(str).append("\n");
        }
        
        result.append(sb.toString());
        return result.toString();
    }
    
    public String obfuscateIdentifiers(String code) {
        // Find all identifiers
        Pattern identifierPattern = Pattern.compile("\\b[a-zA-Z_][a-zA-Z0-9_]*\\b");
        Matcher matcher = identifierPattern.matcher(code);
        
        Set<String> identifiersToObfuscate = new HashSet<>();
        
        while (matcher.find()) {
            String identifier = matcher.group();
            if (!isReservedIdentifier(identifier) && identifier.length() > 1) {
                identifiersToObfuscate.add(identifier);
            }
        }
        
        // Generate obfuscated names
        for (String identifier : identifiersToObfuscate) {
            if (!identifierMap.containsKey(identifier)) {
                identifierMap.put(identifier, generateObfuscatedName());
            }
        }
        
        // Replace identifiers
        String result = code;
        for (Map.Entry<String, String> entry : identifierMap.entrySet()) {
            result = result.replaceAll("\\b" + Pattern.quote(entry.getKey()) + "\\b", entry.getValue());
        }
        
        return result;
    }
    
    public String addControlFlowObfuscation(String code) {
        // Convert if-else to switch statements
        Pattern ifPattern = Pattern.compile("if\\s*\\(([^)]+)\\)\\s*\\{([^}]+)\\}(?:\\s*else\\s*\\{([^}]+)\\})?");
        Matcher matcher = ifPattern.matcher(code);
        
        StringBuffer result = new StringBuffer();
        
        while (matcher.find()) {
            String condition = matcher.group(1);
            String ifBlock = matcher.group(2);
            String elseBlock = matcher.group(3);
            
            String switchVar = "_sw" + random.nextInt(10000);
            StringBuilder replacement = new StringBuilder();
            
            replacement.append("int ").append(switchVar).append(" = (").append(condition).append(") ? 1 : 0;\n");
            replacement.append("switch (").append(switchVar).append(") {\n");
            replacement.append("    case 1:\n        ").append(ifBlock).append("\n        break;\n");
            
            if (elseBlock != null && !elseBlock.trim().isEmpty()) {
                replacement.append("    default:\n        ").append(elseBlock).append("\n        break;\n");
            }
            
            replacement.append("}");
            matcher.appendReplacement(result, replacement.toString());
        }
        matcher.appendTail(result);
        
        return result.toString();
    }
    
    public String addDeadCode(String code) {
        String[] deadCodeSnippets = {
            "volatile int _dummy1 = new java.util.Random().nextInt(100);\n",
            "volatile long _dummy2 = System.currentTimeMillis() & 0xFF;\n",
            "if (_dummy1 > 200) { System.out.println(\"Never executed\"); }\n",
            "for (int _i = 0; _i < 0; _i++) { _dummy2++; }\n",
            "java.util.List<Integer> _dummy_list = new java.util.ArrayList<>();\n"
        };
        
        StringBuilder result = new StringBuilder(code);
        
        // Find method bodies and insert dead code
        Pattern methodPattern = Pattern.compile("\\{\n");
        Matcher matcher = methodPattern.matcher(code);
        
        int insertions = 0;
        int offset = 0;
        
        while (matcher.find() && insertions < 3) {
            int pos = matcher.end() + offset;
            String deadCode = deadCodeSnippets[random.nextInt(deadCodeSnippets.length)];
            result.insert(pos, deadCode);
            offset += deadCode.length();
            insertions++;
        }
        
        return result.toString();
    }
    
    public String addAntiDebugging(String code) {
        String antiDebugCode = """
            // Anti-debugging measures
            import java.lang.management.ManagementFactory;
            import java.util.List;
            
            public static class AntiDebug {
                public static void check() {
                    // Check for debugger
                    List<String> arguments = ManagementFactory.getRuntimeMXBean().getInputArguments();
                    for (String arg : arguments) {
                        if (arg.contains("-agentlib:jdwp") || arg.contains("-Xdebug") || arg.contains("-Xrunjdwp")) {
                            System.exit(1);
                        }
                    }
                    
                    // Check for common debugging tools
                    String[] debuggerProcesses = {"jdb", "eclipse", "idea", "netbeans", "jvisualvm"};
                    try {
                        Process proc = Runtime.getRuntime().exec("tasklist");
                        java.io.BufferedReader reader = new java.io.BufferedReader(
                            new java.io.InputStreamReader(proc.getInputStream()));
                        String line;
                        while ((line = reader.readLine()) != null) {
                            for (String debugger : debuggerProcesses) {
                                if (line.toLowerCase().contains(debugger)) {
                                    System.exit(1);
                                }
                            }
                        }
                    } catch (Exception e) {
                        // Ignore
                    }
                    
                    // Timing check
                    long start = System.nanoTime();
                    volatile int dummy = 0;
                    for (int i = 0; i < 1000; i++) {
                        dummy += i;
                    }
                    long end = System.nanoTime();
                    
                    if ((end - start) > 10_000_000) { // 10ms
                        System.exit(1);
                    }
                    
                    // Check for reflection usage (common in debugging)
                    try {
                        Class.forName("sun.jvm.hotspot.tools.jstack.JStack");
                        System.exit(1);
                    } catch (ClassNotFoundException e) {
                        // Good, debugging tools not present
                    }
                }
            }
            
            """;
        
        String result = antiDebugCode + code;
        
        // Insert anti-debug call at the beginning of main method
        Pattern mainPattern = Pattern.compile("(public\\s+static\\s+void\\s+main\\s*\\([^)]*\\)\\s*\\{)");
        result = mainPattern.matcher(result).replaceFirst("$1\n        AntiDebug.check();");
        
        return result;
    }
    
    public String addClassObfuscation(String code) {
        // Obfuscate class names
        Pattern classPattern = Pattern.compile("(class|interface)\\s+([a-zA-Z_][a-zA-Z0-9_]*)");
        Matcher matcher = classPattern.matcher(code);
        
        Map<String, String> classMap = new HashMap<>();
        
        while (matcher.find()) {
            String className = matcher.group(2);
            if (!STD_CLASSES.contains(className) && !classMap.containsKey(className)) {
                classMap.put(className, "_C" + generateObfuscatedName().substring(0, 8));
            }
        }
        
        // Replace class names
        String result = code;
        for (Map.Entry<String, String> entry : classMap.entrySet()) {
            result = result.replaceAll("\\b" + Pattern.quote(entry.getKey()) + "\\b", entry.getValue());
        }
        
        return result;
    }
    
    public String addReflectionObfuscation(String code) {
        // Obfuscate reflection calls
        String result = code;
        
        // Replace Class.forName calls
        Pattern forNamePattern = Pattern.compile("Class\\.forName\\(\"([^\"]+)\"\\)");
        Matcher matcher = forNamePattern.matcher(result);
        
        StringBuffer sb = new StringBuffer();
        while (matcher.find()) {
            String className = matcher.group(1);
            String encrypted = encryptString(className, options.get("encryptionKey"));
            String replacement = "Class.forName(StringDecryptor.decrypt(\"" + encrypted + "\", \"" + 
                               options.get("encryptionKey") + "\"))";
            matcher.appendReplacement(sb, replacement);
        }
        matcher.appendTail(sb);
        
        return sb.toString();
    }
    
    public String process(String code, Map<String, String> processingOptions) {
        if (processingOptions == null) {
            processingOptions = new HashMap<>();
        }
        
        String key = processingOptions.getOrDefault("key", options.get("encryptionKey"));
        
        String result = code;
        
        // Apply Java-specific obfuscations
        result = encryptStrings(result, key);
        result = addClassObfuscation(result);
        result = addReflectionObfuscation(result);
        result = obfuscateIdentifiers(result);
        result = addControlFlowObfuscation(result);
        result = addDeadCode(result);
        result = addAntiDebugging(result);
        
        return result;
    }
    
    public String process(String code) {
        return process(code, new HashMap<>());
    }
    
    // Main method for command-line usage
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Usage: java JavaProcessor <input_file> [options]");
            System.exit(1);
        }
        
        try {
            // Read input file
            String code = new String(Files.readAllBytes(Paths.get(args[0])));
            
            // Initialize processor with options
            Map<String, String> options = new HashMap<>();
            options.put("encryptionKey", "default_encryption_key_32_chars_");
            
            JavaProcessor processor = new JavaProcessor(options);
            
            // Process the code
            String obfuscated = processor.process(code);
            
            // Output result
            System.out.println(obfuscated);
            
        } catch (IOException e) {
            System.err.println("Error reading file: " + e.getMessage());
            System.exit(1);
        }
    }
}