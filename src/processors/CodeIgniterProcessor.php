<?php

class CodeIgniterProcessor {
    private $options;
    private $identifierMap;
    private $stringMap;
    
    public function __construct($options) {
        $this->options = $options;
        $this->identifierMap = [];
        $this->stringMap = [];
    }
    
    public function encryptStrings($code, $key) {
        // Handle CodeIgniter specific patterns
        $patterns = [
            '/(["\'])([^"\']*)\1/' => 'strings',
            '/\$this->load->([a-zA-Z_][a-zA-Z0-9_]*)/' => 'ci_loads',
            '/\$this->([a-zA-Z_][a-zA-Z0-9_]*)/' => 'ci_properties'
        ];
        
        $encryptedStrings = [];
        $stringIndex = 0;
        
        foreach ($patterns as $pattern => $type) {
            $code = preg_replace_callback($pattern, function($matches) use ($key, &$encryptedStrings, &$stringIndex, $type) {
                if ($type === 'strings') {
                    $originalString = $matches[2];
                    $encrypted = $this->encryptString($originalString, $key);
                    $varName = "\$_ci_s{$stringIndex}";
                    $stringIndex++;
                    
                    $encryptedStrings[] = "\$_ci_s" . ($stringIndex - 1) . " = _ci_decrypt('{$encrypted}', '{$key}');";
                    return $varName;
                }
                return $matches[0]; // Keep CI-specific patterns for now
            }, $code);
        }
        
        $decryptFunction = '
function _ci_decrypt($encrypted, $key) {
    $CI =& get_instance();
    $CI->load->library("encryption");
    return $CI->encryption->decrypt(base64_decode($encrypted));
}
';
        
        return "<?php\n" . $decryptFunction . "\n" . implode("\n", $encryptedStrings) . "\n" . $code;
    }
    
    private function encryptString($str, $key) {
        $iv = substr($key, 0, 16);
        $encrypted = openssl_encrypt($str, 'AES-256-CBC', $key, 0, $iv);
        return base64_encode($encrypted);
    }
    
    public function obfuscateControllers($code) {
        // Obfuscate CodeIgniter controller methods
        $pattern = '/public\s+function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(([^)]*)\)\s*\{/';
        
        return preg_replace_callback($pattern, function($matches) {
            $methodName = $matches[1];
            $params = $matches[2];
            
            // Don't obfuscate CI magic methods
            if (in_array($methodName, ['__construct', 'index'])) {
                return $matches[0];
            }
            
            $obfuscatedName = '_m' . substr(md5($methodName), 0, 8);
            return "public function {$obfuscatedName}({$params}) {";
        }, $code);
    }
    
    public function obfuscateModels($code) {
        // Obfuscate CodeIgniter model methods and properties
        $patterns = [
            '/\$this->db->([a-zA-Z_][a-zA-Z0-9_]*)/' => function($matches) {
                return '$this->db->' . $matches[1]; // Keep DB methods readable
            },
            '/function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(/' => function($matches) {
                $methodName = $matches[1];
                if (in_array($methodName, ['__construct'])) {
                    return $matches[0];
                }
                $obfuscated = '_mdl' . substr(md5($methodName), 0, 6);
                return "function {$obfuscated}(";
            }
        ];
        
        foreach ($patterns as $pattern => $callback) {
            $code = preg_replace_callback($pattern, $callback, $code);
        }
        
        return $code;
    }
    
    public function obfuscateViews($code) {
        // Obfuscate CodeIgniter view variables
        $pattern = '/\$([a-zA-Z_][a-zA-Z0-9_]*)/'; 
        
        return preg_replace_callback($pattern, function($matches) {
            $varName = $matches[1];
            
            // Don't obfuscate common CI variables
            if (in_array($varName, ['this', 'CI', 'data'])) {
                return $matches[0];
            }
            
            $obfuscated = '_v' . substr(md5($varName), 0, 8);
            return "\${$obfuscated}";
        }, $code);
    }
    
    public function addAntiTampering($code) {
        $antiTamper = '
// CodeIgniter Anti-Tampering Protection
if (!defined("BASEPATH")) exit("No direct script access allowed");

class CI_Security_Check {
    public static function verify() {
        $hash = md5_file(__FILE__);
        $expected = "' . md5($code) . '";
        if ($hash !== $expected) {
            show_error("Security violation detected", 403);
        }
    }
}

CI_Security_Check::verify();
';
        
        return $antiTamper . $code;
    }
    
    public function process($code, $options = []) {
        $key = $options['key'] ?? $this->options['encryptionKey'] ?? 'default_key';
        
        // Apply CodeIgniter-specific obfuscations
        $code = $this->encryptStrings($code, $key);
        $code = $this->obfuscateControllers($code);
        $code = $this->obfuscateModels($code);
        $code = $this->obfuscateViews($code);
        $code = $this->addAntiTampering($code);
        
        return $code;
    }
}

?>