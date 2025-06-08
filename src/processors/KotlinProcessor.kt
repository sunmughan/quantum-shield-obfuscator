import java.security.MessageDigest
import java.util.*
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec
import kotlin.random.Random

class KotlinProcessor(private val options: Map<String, Any>) {
    private val identifierMap = mutableMapOf<String, String>()
    private val stringMap = mutableMapOf<String, String>()
    
    fun encryptStrings(code: String, key: String): String {
        val stringPattern = Regex("\"([^\"]*)\"|'([^']*)'") 
        val encryptedStrings = mutableListOf<String>()
        var stringIndex = 0
        
        val processedCode = stringPattern.replace(code) { matchResult ->
            val originalString = matchResult.groupValues[1].ifEmpty { matchResult.groupValues[2] }
            val encrypted = encryptString(originalString, key)
            val varName = "_s$stringIndex"
            stringIndex++
            
            encryptedStrings.add("val $_s${stringIndex - 1} = _decrypt(\"$encrypted\", \"$key\")")
            varName
        }
        
        val decryptFunction = """
fun _decrypt(encrypted: String, key: String): String {
    val cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
    val secretKey = SecretKeySpec(key.toByteArray().sliceArray(0..15), "AES")
    cipher.init(Cipher.DECRYPT_MODE, secretKey)
    val decryptedBytes = cipher.doFinal(Base64.getDecoder().decode(encrypted))
    return String(decryptedBytes)
}
"""
        
        return decryptFunction + "\n" + encryptedStrings.joinToString("\n") + "\n" + processedCode
    }
    
    private fun encryptString(str: String, key: String): String {
        val cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
        val secretKey = SecretKeySpec(key.toByteArray().sliceArray(0..15), "AES")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        val encryptedBytes = cipher.doFinal(str.toByteArray())
        return Base64.getEncoder().encodeToString(encryptedBytes)
    }
    
    fun flattenControlFlow(code: String): String {
        val ifPattern = Regex("if\\s*\\(([^)]+)\\)\\s*\\{([^}]+)\\}(?:\\s*else\\s*\\{([^}]+)\\})?")
        
        return ifPattern.replace(code) { matchResult ->
            val condition = matchResult.groupValues[1]
            val ifBlock = matchResult.groupValues[2]
            val elseBlock = matchResult.groupValues.getOrNull(3) ?: ""
            
            val randomCase1 = Random.nextInt(1000, 9999)
            val randomCase2 = Random.nextInt(1000, 9999)
            val switchVar = "_cf${generateRandomString(8)}"
            
            buildString {
                append("val $switchVar = if ($condition) $randomCase1 else $randomCase2\n")
                append("when($switchVar) {\n")
                append("    $randomCase1 -> {\n        $ifBlock\n    }\n")
                if (elseBlock.isNotEmpty()) {
                    append("    $randomCase2 -> {\n        $elseBlock\n    }\n")
                }
                append("}")
            }
        }
    }
    
    fun obfuscateIdentifiers(code: String): Map<String, Any> {
        val identifierPattern = Regex("\\b([a-zA-Z_][a-zA-Z0-9_]*)\\b")
        val identifierMap = mutableMapOf<String, String>()
        var identifierIndex = 0
        
        val processedCode = identifierPattern.replace(code) { matchResult ->
            val originalName = matchResult.groupValues[1]
            
            // Skip Kotlin keywords and built-in types
            if (isKotlinKeyword(originalName)) {
                return@replace originalName
            }
            
            if (!identifierMap.containsKey(originalName)) {
                val obfuscatedName = "_${generateRandomString(8)}_$identifierIndex"
                identifierMap[originalName] = obfuscatedName
                identifierIndex++
            }
            
            identifierMap[originalName] ?: originalName
        }
        
        return mapOf(
            "code" to processedCode,
            "map" to identifierMap
        )
    }
    
    fun injectDeadCode(code: String): String {
        val deadCodeSnippets = listOf(
            "val _dummy1 = if (Random.nextBoolean()) \"fake\" else \"data\"",
            "if (false) { println(\"This will never execute\") }",
            "val _dummy2 = System.currentTimeMillis()",
            "val _dummy3 = mapOf(\"fake\" to \"object\")"
        )
        
        var processedCode = code
        deadCodeSnippets.forEach { snippet ->
            val insertPos = Random.nextInt(0, code.split(";").size)
            processedCode = insertAtPosition(processedCode, snippet + "\n", insertPos)
        }
        
        return processedCode
    }
    
    fun addAntiDebugProtection(code: String): String {
        val antiDebugCode = """
// Anti-debug protection
fun checkDebugMode() {
    val isDebuggable = try {
        Class.forName("android.os.Debug").getMethod("isDebuggerConnected").invoke(null) as Boolean
    } catch (e: Exception) {
        false
    }
    
    if (isDebuggable) {
        throw SecurityException("Debug mode detected")
    }
}

fun antiDebugTimer() {
    Timer().scheduleAtFixedRate(object : TimerTask() {
        override fun run() {
            val start = System.currentTimeMillis()
            // Debugger detection logic
            val end = System.currentTimeMillis()
            if (end - start > 100) {
                System.exit(1)
            }
        }
    }, 0, 1000)
}
"""
        
        return antiDebugCode + "\n" + code
    }
    
    fun addRuntimeProtection(code: String): String {
        val protectionCode = """
// Runtime protection
fun setupRuntimeProtection() {
    Thread.setDefaultUncaughtExceptionHandler { _, _ ->
        // Handle exceptions securely
        System.exit(1)
    }
    
    // Integrity checking
    Timer().scheduleAtFixedRate(object : TimerTask() {
        override fun run() {
            performIntegrityCheck()
        }
    }, 0, 5000)
}

fun performIntegrityCheck() {
    // Implement integrity checking logic
    val expectedHash = "your_expected_hash"
    // Compare with current state
}
"""
        
        return protectionCode + "\n" + code
    }
    
    fun addDomainLocking(code: String, allowedDomains: List<String>): String {
        val domainCheck = """
// Domain locking (for Android WebView)
fun checkDomain(webView: WebView) {
    val allowedDomains = listOf(${allowedDomains.joinToString(", ") { "\"$it\"" }})
    val currentUrl = webView.url ?: ""
    val currentDomain = try {
        URL(currentUrl).host
    } catch (e: Exception) {
        ""
    }
    
    if (!allowedDomains.contains(currentDomain)) {
        throw SecurityException("Unauthorized domain")
    }
}
"""
        
        return domainCheck + "\n" + code
    }
    
    fun addExpirationCheck(code: String, expirationDate: String): String {
        val expirationCheck = """
// License expiration check
fun checkExpiration() {
    val expirationDate = SimpleDateFormat("yyyy-MM-dd").parse("$expirationDate")
    val currentDate = Date()
    
    if (currentDate.after(expirationDate)) {
        throw SecurityException("License expired")
    }
}
"""
        
        return expirationCheck + "\n" + code
    }
    
    private fun generateRandomString(length: Int): String {
        val chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return (1..length)
            .map { chars.random() }
            .joinToString("")
    }
    
    private fun isKotlinKeyword(word: String): Boolean {
        val keywords = setOf(
            "as", "break", "class", "continue", "do", "else", "false", "for",
            "fun", "if", "in", "interface", "is", "null", "object", "package",
            "return", "super", "this", "throw", "true", "try", "typealias",
            "val", "var", "when", "while", "String", "Int", "Double", "Boolean",
            "List", "Map", "Set", "Array"
        )
        return keywords.contains(word)
    }
    
    private fun insertAtPosition(string: String, insert: String, position: Int): String {
        val parts = string.split(";")
        return if (position < parts.size) {
            parts.toMutableList().apply { add(position, insert) }.joinToString(";")
        } else {
            string + "\n" + insert
        }
    }
}