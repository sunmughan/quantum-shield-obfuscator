import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class DartProcessor {
  final Map<String, dynamic> options;
  final Map<String, String> identifierMap = {};
  final Map<String, String> stringMap = {};
  
  DartProcessor(this.options);
  
  String encryptStrings(String code, String key) {
    final RegExp stringPattern = RegExp(r'["\']([^"\'][^"\']*)["\'']');
    final List<String> encryptedStrings = [];
    int stringIndex = 0;
    
    code = code.replaceAllMapped(stringPattern, (Match match) {
      final String originalString = match.group(1) ?? '';
      final String encrypted = _encryptString(originalString, key);
      final String varName = '_s$stringIndex';
      stringIndex++;
      
      encryptedStrings.add('final $_s${stringIndex - 1} = _decrypt("$encrypted", "$key");');
      return varName;
    });
    
    const String decryptFunction = '''
String _decrypt(String encrypted, String key) {
  // Simplified decryption for demo - implement proper AES decryption
  final bytes = base64.decode(encrypted);
  return utf8.decode(bytes);
}
''';
    
    return decryptFunction + '\n' + encryptedStrings.join('\n') + '\n' + code;
  }
  
  String _encryptString(String str, String key) {
    // Simplified encryption for demo - implement proper AES encryption
    final bytes = utf8.encode(str);
    return base64.encode(bytes);
  }
  
  String flattenControlFlow(String code) {
    final RegExp ifPattern = RegExp(r'if\s*\(([^)]+)\)\s*\{([^}]+)\}(?:\s*else\s*\{([^}]+)\})?');
    
    return code.replaceAllMapped(ifPattern, (Match match) {
      final String condition = match.group(1) ?? '';
      final String ifBlock = match.group(2) ?? '';
      final String elseBlock = match.group(3) ?? '';
      
      final int randomCase1 = Random().nextInt(9000) + 1000;
      final int randomCase2 = Random().nextInt(9000) + 1000;
      final String switchVar = '_cf${_generateRandomString(8)}';
      
      String switchCode = 'final $switchVar = ($condition) ? $randomCase1 : $randomCase2;\n';
      switchCode += 'switch($switchVar) {\n';
      switchCode += '  case $randomCase1:\n    $ifBlock\n    break;\n';
      if (elseBlock.isNotEmpty) {
        switchCode += '  case $randomCase2:\n    $elseBlock\n    break;\n';
      }
      switchCode += '}';
      
      return switchCode;
    });
  }
  
  Map<String, dynamic> obfuscateIdentifiers(String code) {
    final RegExp identifierPattern = RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\b');
    final Map<String, String> identifierMap = {};
    int identifierIndex = 0;
    
    code = code.replaceAllMapped(identifierPattern, (Match match) {
      final String originalName = match.group(1) ?? '';
      
      // Skip Dart keywords and built-in types
      if (_isDartKeyword(originalName)) {
        return originalName;
      }
      
      if (!identifierMap.containsKey(originalName)) {
        final String obfuscatedName = '_${_generateRandomString(8)}_$identifierIndex';
        identifierMap[originalName] = obfuscatedName;
        identifierIndex++;
      }
      
      return identifierMap[originalName] ?? originalName;
    });
    
    return {
      'code': code,
      'map': identifierMap
    };
  }
  
  String injectDeadCode(String code) {
    final List<String> deadCodeSnippets = [
      'final _dummy1 = Random().nextBool() ? "fake" : "data";',
      'if (false) { print("This will never execute"); }',
      'final _dummy2 = DateTime.now().millisecondsSinceEpoch;',
      'final _dummy3 = jsonEncode({"fake": "object"});'
    ];
    
    for (final String snippet in deadCodeSnippets) {
      final int insertPos = Random().nextInt(code.split(';').length);
      code = _insertAtPosition(code, snippet + '\n', insertPos);
    }
    
    return code;
  }
  
  String addAntiDebugProtection(String code) {
    const String antiDebugCode = '''
// Anti-debug protection
void _checkDebugMode() {
  assert(() {
    throw Exception("Debug mode detected");
  }());
}

void _antiDebugTimer() {
  Timer.periodic(Duration(seconds: 1), (timer) {
    final stopwatch = Stopwatch()..start();
    // Debugger detection logic
    stopwatch.stop();
    if (stopwatch.elapsedMilliseconds > 100) {
      exit(1);
    }
  });
}
''';
    
    return antiDebugCode + '\n' + code;
  }
  
  String addRuntimeProtection(String code) {
    const String protectionCode = '''
// Runtime protection
void _setupRuntimeProtection() {
  FlutterError.onError = (FlutterErrorDetails details) {
    // Handle errors securely
    exit(1);
  };
  
  // Check for tampering
  Timer.periodic(Duration(seconds: 5), (timer) {
    _performIntegrityCheck();
  });
}

void _performIntegrityCheck() {
  // Implement integrity checking logic
  final expectedHash = "your_expected_hash";
  // Compare with current state
}
''';
    
    return protectionCode + '\n' + code;
  }
  
  String addDomainLocking(String code, List<String> allowedDomains) {
    final String domainCheck = '''
// Domain locking (for web apps)
void _checkDomain() {
  if (kIsWeb) {
    final allowedDomains = ${allowedDomains.toString()};
    final currentDomain = html.window.location.hostname;
    
    if (!allowedDomains.contains(currentDomain)) {
      throw Exception("Unauthorized domain");
    }
  }
}
''';
    
    return domainCheck + '\n' + code;
  }
  
  String addExpirationCheck(String code, String expirationDate) {
    final String expirationCheck = '''
// License expiration check
void _checkExpiration() {
  final expirationDate = DateTime.parse("$expirationDate");
  final currentDate = DateTime.now();
  
  if (currentDate.isAfter(expirationDate)) {
    throw Exception("License expired");
  }
}
''';
    
    return expirationCheck + '\n' + code;
  }
  
  String _generateRandomString(int length) {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final Random random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
  
  bool _isDartKeyword(String word) {
    const Set<String> keywords = {
      'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
      'class', 'const', 'continue', 'default', 'do', 'else', 'enum', 'export',
      'extends', 'external', 'factory', 'false', 'final', 'finally', 'for',
      'if', 'implements', 'import', 'in', 'is', 'library', 'new', 'null',
      'operator', 'part', 'return', 'static', 'super', 'switch', 'this',
      'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with',
      'String', 'int', 'double', 'bool', 'List', 'Map', 'Set'
    };
    return keywords.contains(word);
  }
  
  String _insertAtPosition(String string, String insert, int position) {
    final List<String> parts = string.split(';');
    if (position < parts.length) {
      parts.insert(position, insert);
    } else {
      parts.add(insert);
    }
    return parts.join(';');
  }
}