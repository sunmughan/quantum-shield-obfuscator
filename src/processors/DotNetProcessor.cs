using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace QuantumShieldObfuscator.Processors
{
    public class DotNetProcessor
    {
        private readonly Dictionary<string, object> _options;
        private readonly Dictionary<string, string> _identifierMap;
        private readonly Dictionary<string, string> _stringMap;
        private readonly Random _random;

        public DotNetProcessor(Dictionary<string, object> options)
        {
            _options = options ?? new Dictionary<string, object>();
            _identifierMap = new Dictionary<string, string>();
            _stringMap = new Dictionary<string, string>();
            _random = new Random();
        }

        public string EncryptStrings(string code, string key)
        {
            var tree = CSharpSyntaxTree.ParseText(code);
            var root = tree.GetCompilationUnitRoot();
            var encryptedStrings = new List<string>();
            var stringIndex = 0;

            var rewriter = new StringLiteralRewriter(key, encryptedStrings, ref stringIndex);
            var newRoot = rewriter.Visit(root);

            var decryptMethod = @"
using System;
using System.Security.Cryptography;
using System.Text;

public static class StringDecryptor
{
    public static string Decrypt(string encrypted, string key)
    {
        byte[] keyBytes = Encoding.UTF8.GetBytes(key.PadRight(32).Substring(0, 32));
        byte[] encryptedBytes = Convert.FromBase64String(encrypted);
        
        using (var aes = Aes.Create())
        {
            aes.Key = keyBytes;
            aes.IV = keyBytes.Take(16).ToArray();
            
            using (var decryptor = aes.CreateDecryptor())
            using (var ms = new MemoryStream(encryptedBytes))
            using (var cs = new CryptoStream(ms, decryptor, CryptoStreamMode.Read))
            using (var reader = new StreamReader(cs))
            {
                return reader.ReadToEnd();
            }
        }
    }
}
";

            var stringDeclarations = string.Join("\n", encryptedStrings);
            return decryptMethod + "\n" + stringDeclarations + "\n" + newRoot.ToFullString();
        }

        private string EncryptString(string input, string key)
        {
            byte[] keyBytes = Encoding.UTF8.GetBytes(key.PadRight(32).Substring(0, 32));
            byte[] inputBytes = Encoding.UTF8.GetBytes(input);
            
            using (var aes = Aes.Create())
            {
                aes.Key = keyBytes;
                aes.IV = keyBytes.Take(16).ToArray();
                
                using (var encryptor = aes.CreateEncryptor())
                using (var ms = new MemoryStream())
                using (var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write))
                {
                    cs.Write(inputBytes, 0, inputBytes.Length);
                    cs.FlushFinalBlock();
                    return Convert.ToBase64String(ms.ToArray());
                }
            }
        }

        public string ObfuscateIdentifiers(string code)
        {
            var tree = CSharpSyntaxTree.ParseText(code);
            var root = tree.GetCompilationUnitRoot();
            
            var rewriter = new IdentifierObfuscationRewriter(_identifierMap, _random);
            var newRoot = rewriter.Visit(root);
            
            return newRoot.ToFullString();
        }

        public string AddControlFlowObfuscation(string code)
        {
            // Convert simple if-else to switch statements
            var pattern = @"if\s*\(([^)]+)\)\s*\{([^}]+)\}(?:\s*else\s*\{([^}]+)\})?";
            
            return Regex.Replace(code, pattern, match =>
            {
                var condition = match.Groups[1].Value;
                var ifBlock = match.Groups[2].Value;
                var elseBlock = match.Groups[3].Value;
                
                var switchVar = $"_sw{_random.Next(1000, 9999)}";
                var result = $"int {switchVar} = ({condition}) ? 1 : 0;\n";
                result += $"switch ({switchVar})\n{{\n";
                result += $"    case 1:\n        {ifBlock}\n        break;\n";
                
                if (!string.IsNullOrEmpty(elseBlock))
                {
                    result += $"    default:\n        {elseBlock}\n        break;\n";
                }
                
                result += "}";
                return result;
            });
        }

        public string AddAntiDebugging(string code)
        {
            var antiDebugCode = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public static class AntiDebug
{
    [DllImport(""kernel32.dll"", SetLastError = true, ExactSpelling = true)]
    static extern bool CheckRemoteDebuggerPresent(IntPtr hProcess, ref bool isDebuggerPresent);
    
    [DllImport(""kernel32.dll"")]
    static extern IntPtr GetCurrentProcess();
    
    public static void Check()
    {
        if (Debugger.IsAttached)
        {
            Environment.Exit(1);
        }
        
        bool isDebuggerPresent = false;
        CheckRemoteDebuggerPresent(GetCurrentProcess(), ref isDebuggerPresent);
        
        if (isDebuggerPresent)
        {
            Environment.Exit(1);
        }
        
        // Timing check
        var sw = Stopwatch.StartNew();
        System.Threading.Thread.Sleep(1);
        sw.Stop();
        
        if (sw.ElapsedMilliseconds > 10)
        {
            Environment.Exit(1);
        }
    }
}
";
            
            // Insert anti-debug check at the beginning of Main method
            var mainPattern = @"(static\s+void\s+Main\s*\([^)]*\)\s*\{)";
            return Regex.Replace(antiDebugCode + code, mainPattern, "$1\nAntiDebug.Check();");
        }

        public string Process(string code, Dictionary<string, object> options = null)
        {
            var key = options?.GetValueOrDefault("key")?.ToString() ?? 
                     _options.GetValueOrDefault("encryptionKey")?.ToString() ?? 
                     "default_key";
            
            // Apply .NET-specific obfuscations
            code = EncryptStrings(code, key);
            code = ObfuscateIdentifiers(code);
            code = AddControlFlowObfuscation(code);
            code = AddAntiDebugging(code);
            
            return code;
        }
    }

    public class StringLiteralRewriter : CSharpSyntaxRewriter
    {
        private readonly string _key;
        private readonly List<string> _encryptedStrings;
        private int _stringIndex;

        public StringLiteralRewriter(string key, List<string> encryptedStrings, ref int stringIndex)
        {
            _key = key;
            _encryptedStrings = encryptedStrings;
            _stringIndex = stringIndex;
        }

        public override SyntaxNode VisitLiteralExpression(LiteralExpressionSyntax node)
        {
            if (node.Kind() == SyntaxKind.StringLiteralExpression)
            {
                var originalString = node.Token.ValueText;
                var encrypted = EncryptString(originalString, _key);
                var varName = $"_s{_stringIndex++}";
                
                _encryptedStrings.Add($"private static readonly string {varName} = StringDecryptor.Decrypt(\"{encrypted}\", \"{_key}\");");
                
                return SyntaxFactory.IdentifierName(varName);
            }
            
            return base.VisitLiteralExpression(node);
        }
        
        private string EncryptString(string input, string key)
        {
            byte[] keyBytes = Encoding.UTF8.GetBytes(key.PadRight(32).Substring(0, 32));
            byte[] inputBytes = Encoding.UTF8.GetBytes(input);
            
            using (var aes = Aes.Create())
            {
                aes.Key = keyBytes;
                aes.IV = keyBytes.Take(16).ToArray();
                
                using (var encryptor = aes.CreateEncryptor())
                using (var ms = new MemoryStream())
                using (var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write))
                {
                    cs.Write(inputBytes, 0, inputBytes.Length);
                    cs.FlushFinalBlock();
                    return Convert.ToBase64String(ms.ToArray());
                }
            }
        }
    }

    public class IdentifierObfuscationRewriter : CSharpSyntaxRewriter
    {
        private readonly Dictionary<string, string> _identifierMap;
        private readonly Random _random;
        private readonly HashSet<string> _reservedNames = new HashSet<string>
        {
            "Main", "ToString", "GetHashCode", "Equals", "GetType"
        };

        public IdentifierObfuscationRewriter(Dictionary<string, string> identifierMap, Random random)
        {
            _identifierMap = identifierMap;
            _random = random;
        }

        public override SyntaxNode VisitIdentifierName(IdentifierNameSyntax node)
        {
            var identifier = node.Identifier.ValueText;
            
            if (!_reservedNames.Contains(identifier) && !_identifierMap.ContainsKey(identifier))
            {
                _identifierMap[identifier] = GenerateObfuscatedName();
            }
            
            if (_identifierMap.ContainsKey(identifier))
            {
                return node.WithIdentifier(SyntaxFactory.Identifier(_identifierMap[identifier]));
            }
            
            return base.VisitIdentifierName(node);
        }
        
        private string GenerateObfuscatedName()
        {
            const string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
            var length = _random.Next(8, 16);
            var result = new char[length];
            
            for (int i = 0; i < length; i++)
            {
                result[i] = chars[_random.Next(chars.Length)];
            }
            
            return new string(result);
        }
    }
}