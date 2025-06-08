<?php

class PHPProcessor {
    private $options;
    private $identifierMap;
    private $stringMap;
    
    public function __construct($options) {
        $this->options = $options;
        $this->identifierMap = [];
        $this->stringMap = [];
    }
    
    public function encryptStrings($code, $key) {
        $pattern = '/(["\'])([^"\']*)\1/';
        $encryptedStrings = [];
        $stringIndex = 0;
        
        $code = preg_replace_callback($pattern, function($matches) use ($key, &$encryptedStrings, &$stringIndex) {
            $originalString = $matches[2];
            $encrypted = $this->encryptString($originalString, $key);
            $varName = "\$_s{$stringIndex}";
            $stringIndex++;
            
            $encryptedStrings[] = "\$_s" . ($stringIndex - 1) . " = _decrypt('{$encrypted}', '{$key}');";
            return $varName;
        }, $code);
        
        $decryptFunction = '
function _decrypt($encrypted, $key) {
    return openssl_decrypt(base64_decode($encrypted), "AES-256-CBC", $key, 0, substr($key, 0, 16));
}
';
        
        return "<?php\n" . $decryptFunction . "\n" . implode("\n", $encryptedStrings) . "\n" . $code;
    }
    
    private function encryptString($str, $key) {
        $iv = substr($key, 0, 16);
        $encrypted = openssl_encrypt($str, 'AES-256-CBC', $key, 0, $iv);
        return base64_encode($encrypted);
    }
    
    public function flattenControlFlow($code) {
        // Convert if-else statements to switch statements
        $pattern = '/if\s*\(([^)]+)\)\s*\{([^}]+)\}(?:\s*else\s*\{([^}]+)\})?/';
        
        return preg_replace_callback($pattern, function($matches) {
            $condition = $matches[1];
            $ifBlock = $matches[2];
            $elseBlock = isset($matches[3]) ? $matches[3] : '';
            
            $randomCase1 = rand(1000, 9999);
            $randomCase2 = rand(1000, 9999);
            $switchVar = '_cf' . uniqid();
            
            $switch = "\${$switchVar} = ({$condition}) ? {$randomCase1} : {$randomCase2};\n";
            $switch .= "switch(\${$switchVar}) {\n";
            $switch .= "    case {$randomCase1}:\n        {$ifBlock}\n        break;\n";
            if ($elseBlock) {
                $switch .= "    case {$randomCase2}:\n        {$elseBlock}\n        break;\n";
            }
            $switch .= "}";
            
            return $switch;
        }, $code);
    }
    
    public function obfuscateIdentifiers($code) {
        $pattern = '/\$([a-zA-Z_][a-zA-Z0-9_]*)/'; 
        $identifierMap = [];
        $identifierIndex = 0;
        
        $code = preg_replace_callback($pattern, function($matches) use (&$identifierMap, &$identifierIndex) {
            $originalName = $matches[1];
            if (!isset($identifierMap[$originalName])) {
                $obfuscatedName = '_' . $this->generateRandomString(8) . '_' . $identifierIndex++;
                $identifierMap[$originalName] = $obfuscatedName;
            }
            return '$' . $identifierMap[$originalName];
        }, $code);
        
        return [
            'code' => $code,
            'map' => $identifierMap
        ];
    }
    
    public function injectDeadCode($code) {
        $deadCodeSnippets = [
            '$_dummy1 = rand() > 0.5 ? "fake" : "data";',
            'if (false) { echo "This will never execute"; }',
            '$_dummy2 = time();',
            '$_dummy3 = json_encode(["fake" => "object"]);'
        ];
        
        foreach ($deadCodeSnippets as $snippet) {
            $insertPos = rand(0, substr_count($code, ';'));
            $code = $this->insertAtPosition($code, $snippet . "\n", $insertPos);
        }
        
        return $code;
    }
    
    public function addAntiDebugProtection($code) {
        $antiDebugCode = '
// Anti-debug protection
if (function_exists("xdebug_is_enabled") && xdebug_is_enabled()) {
    die("Debugging not allowed");
}

if (in_array("-d", $_SERVER["argv"] ?? [])) {
    die("Debug mode not allowed");
}

// Check for common debugging extensions
$debugExtensions = ["xdebug", "zend_debugger"];
foreach ($debugExtensions as $ext) {
    if (extension_loaded($ext)) {
        die("Debug extension detected");
    }
}
';
        
        return $antiDebugCode . "\n" . $code;
    }
    
    public function addRuntimeProtection($code) {
        $protectionCode = '
// Runtime protection
register_shutdown_function(function() {
    if (error_get_last()) {
        die("Runtime error detected");
    }
});

// Check execution environment
if (php_sapi_name() === "cli" && !defined("ALLOW_CLI")) {
    die("CLI execution not allowed");
}
';
        
        return $protectionCode . "\n" . $code;
    }
    
    public function addDomainLocking($code, $allowedDomains) {
        $domainCheck = '
// Domain locking
$allowedDomains = ' . var_export($allowedDomains, true) . ';
$currentDomain = $_SERVER["HTTP_HOST"] ?? "";

if (!in_array($currentDomain, $allowedDomains)) {
    die("Unauthorized domain");
}
';
        
        return $domainCheck . "\n" . $code;
    }
    
    public function addExpirationCheck($code, $expirationDate) {
        $expirationCheck = '
// License expiration check
$expirationDate = strtotime("' . $expirationDate . '");
$currentDate = time();

if ($currentDate > $expirationDate) {
    die("License expired");
}
';
        
        return $expirationCheck . "\n" . $code;
    }
    
    private function generateRandomString($length) {
        $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        $result = '';
        for ($i = 0; $i < $length; $i++) {
            $result .= $chars[rand(0, strlen($chars) - 1)];
        }
        return $result;
    }
    
    private function insertAtPosition($string, $insert, $position) {
        $semicolonCount = 0;
        for ($i = 0; $i < strlen($string); $i++) {
            if ($string[$i] === ';') {
                $semicolonCount++;
                if ($semicolonCount === $position) {
                    return substr($string, 0, $i + 1) . "\n" . $insert . substr($string, $i + 1);
                }
            }
        }
        return $string . "\n" . $insert;
    }
}
?>