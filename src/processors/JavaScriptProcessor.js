const crypto = require('crypto');
const { parse } = require('@babel/parser');
const traverse = require('@babel/traverse').default;
const generate = require('@babel/generator').default;
const t = require('@babel/types');

class JavaScriptProcessor {
    constructor(options) {
        this.options = options;
        this.identifierMap = new Map();
        this.stringMap = new Map();
    }

    encryptStrings(code, key) {
        const ast = parse(code, {
            sourceType: 'module',
            plugins: ['jsx', 'typescript']
        });

        const encryptedStrings = [];
        let stringIndex = 0;

        traverse(ast, {
            StringLiteral(path) {
                const originalString = path.node.value;
                const encrypted = this.encryptString(originalString, key);
                const varName = `_s${stringIndex++}`;
                
                encryptedStrings.push(`const ${varName} = _decrypt('${encrypted}', '${key}');`);
                path.replaceWith(t.identifier(varName));
            }
        });

        const decryptFunction = `
        function _decrypt(encrypted, key) {
            const decipher = require('crypto').createDecipher('aes-256-cbc', key);
            let decrypted = decipher.update(encrypted, 'hex', 'utf8');
            decrypted += decipher.final('utf8');
            return decrypted;
        }
        `;

        const result = generate(ast).code;
        return decryptFunction + '\n' + encryptedStrings.join('\n') + '\n' + result;
    }

    encryptString(str, key) {
        const iv = crypto.randomBytes(16);
        const keyBuffer = Buffer.isBuffer(key) ? key.slice(0, 32) : Buffer.from(String(key).substring(0, 32));
        const cipher = crypto.createCipheriv('aes-256-cbc', keyBuffer, iv);
        let encrypted = cipher.update(str, 'utf8', 'hex');
        encrypted += cipher.final('hex');
        return encrypted;
    }

    // Add AST-based advanced obfuscation
    advancedASTObfuscation(code) {
        const ast = parse(code, {
            sourceType: 'module',
            plugins: ['jsx', 'typescript', 'decorators-legacy']
        });
        
        // Advanced transformations
        traverse(ast, {
            // Convert arrow functions to regular functions
            ArrowFunctionExpression(path) {
                const func = t.functionExpression(
                    null,
                    path.node.params,
                    t.blockStatement([t.returnStatement(path.node.body)])
                );
                path.replaceWith(func);
            },
            
            // Obfuscate object properties
            ObjectProperty(path) {
                if (t.isIdentifier(path.node.key)) {
                    const obfuscatedKey = this.obfuscateIdentifier(path.node.key.name);
                    path.node.key = t.stringLiteral(obfuscatedKey);
                    path.node.computed = true;
                }
            },
            
            // Add control flow flattening
            BlockStatement(path) {
                if (path.node.body.length > 3) {
                    this.flattenControlFlow(path);
                }
            }
        });
        
        return generate(ast, {
            compact: true,
            minified: true
        }).code;
    }
    
    flattenControlFlow(path) {
        const statements = path.node.body;
        const switchCases = [];
        let caseIndex = 0;
        
        // Convert linear statements to switch cases
        for (const stmt of statements) {
            switchCases.push(
                t.switchCase(
                    t.numericLiteral(caseIndex),
                    [stmt, t.breakStatement()]
                )
            );
            caseIndex++;
        }
        
        // Create control flow variable
        const controlVar = t.identifier('_cf');
        const switchStmt = t.switchStatement(
            controlVar,
            switchCases
        );
        
        // Replace block with flattened version
        path.node.body = [
            t.variableDeclaration('let', [
                t.variableDeclarator(controlVar, t.numericLiteral(0))
            ]),
            t.whileStatement(
                t.binaryExpression('<', controlVar, t.numericLiteral(caseIndex)),
                t.blockStatement([switchStmt])
            )
        ];
    }
}

module.exports = JavaScriptProcessor;