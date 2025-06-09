# 🚀 Advanced Code Obfuscator - Usage Guide

## 📋 Table of Contents

1. [Quick Start](#-quick-start)
2. [Installation](#-installation)
3. [Basic Usage](#-basic-usage)
4. [Configuration Options](#-configuration-options)
5. [Implementation Examples](#-implementation-examples)
6. [Integration Guide](#-integration-guide)
7. [Security Levels](#-security-levels)
8. [Best Practices](#-best-practices)
9. [Troubleshooting](#-troubleshooting)
10. [Advanced Features](#-advanced-features)

## 🚀 Quick Start

### Basic Command Line Usage

```bash
# Obfuscate a single file
node cli/obfuscate.js --input src/app.js --output dist/app.obfuscated.js

# Batch process multiple files
node cli/obfuscate.js --batch src/ --output dist/ --encryption-level advanced

# Maximum security for sensitive code
node cli/obfuscate.js --input sensitive.js --encryption-level military --anti-debug --vm-detection
```

### Node.js API Usage

```javascript
const AdvancedObfuscator = require('./core/obfuscator.js');

const obfuscator = new AdvancedObfuscator({
    encryptionLevel: 'advanced',
    antiDebug: true,
    vmDetection: true
});

const sourceCode = `
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + item.price, 0);
}
`;

const protectedCode = obfuscator.obfuscate(sourceCode, 'javascript');
console.log('Code protected successfully!');
```

## 📦 Installation

### Prerequisites

- **Node.js**: Version 14.0 or higher
- **npm**: Version 6.0 or higher
- **Operating System**: Windows, macOS, or Linux

### Setup Steps

1. **Clone or Download the Repository**
   ```bash
   git clone <repository-url>
   cd advanced-code-obfuscator
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Verify Installation**
   ```bash
   node cli/obfuscate.js --help
   ```

4. **Run Demo (Optional)**
   ```bash
   node examples/demo.js
   ```

## 🔧 Basic Usage

### Command Line Interface

#### Single File Processing

```bash
# Basic obfuscation
node cli/obfuscate.js --input myfile.js --output protected.js

# Specify language explicitly
node cli/obfuscate.js --input script.php --language php --output protected.php

# Custom encryption level
node cli/obfuscate.js --input app.js --encryption-level maximum --output app.protected.js
```

#### Batch Processing

```bash
# Process entire directory
node cli/obfuscate.js --batch src/ --output dist/

# Process with file pattern
node cli/obfuscate.js --batch "src/**/*.js" --output dist/

# Exclude specific files
node cli/obfuscate.js --batch src/ --output dist/ --exclude "test/**,*.min.js"
```

#### Available CLI Options

| Option | Short | Description | Example |
|--------|-------|-------------|----------|
| `--input` | `-i` | Input file path | `--input src/app.js` |
| `--output` | `-o` | Output file path | `--output dist/app.js` |
| `--batch` | `-b` | Batch process directory | `--batch src/` |
| `--language` | `-l` | Target language | `--language javascript` |
| `--encryption-level` | `-e` | Security level | `--encryption-level military` |
| `--anti-debug` | `-ad` | Enable anti-debugging | `--anti-debug` |
| `--vm-detection` | `-vm` | Enable VM detection | `--vm-detection` |
| `--domain-lock` | `-dl` | Lock to domains | `--domain-lock "example.com,app.com"` |
| `--time-lock` | `-tl` | Set expiration | `--time-lock "2024-12-31"` |
| `--hardware-bind` | `-hb` | Enable hardware binding | `--hardware-bind` |
| `--help` | `-h` | Show help | `--help` |

### Node.js API

#### Basic API Usage

```javascript
const AdvancedObfuscator = require('./core/obfuscator.js');

// Create obfuscator instance
const obfuscator = new AdvancedObfuscator({
    encryptionLevel: 'advanced',
    antiDebug: true,
    vmDetection: true,
    integrityCheck: true
});

// Obfuscate code
const sourceCode = 'function hello() { console.log("Hello World!"); }';
const protectedCode = obfuscator.obfuscate(sourceCode, 'javascript');

// Save to file
const fs = require('fs');
fs.writeFileSync('protected.js', protectedCode);
```

#### Async Processing

```javascript
const { promisify } = require('util');
const fs = require('fs');
const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);

async function protectFile(inputPath, outputPath) {
    try {
        const sourceCode = await readFile(inputPath, 'utf8');
        const obfuscator = new AdvancedObfuscator({
            encryptionLevel: 'maximum',
            antiDebug: true,
            vmDetection: true
        });
        
        const protectedCode = obfuscator.obfuscate(sourceCode, 'javascript');
        await writeFile(outputPath, protectedCode);
        
        console.log(`File protected: ${inputPath} -> ${outputPath}`);
    } catch (error) {
        console.error('Protection failed:', error.message);
    }
}

// Usage
protectFile('src/app.js', 'dist/app.protected.js');
```

## ⚙️ Configuration Options

### Security Levels

| Level | Description | Use Case | Performance Impact |
|-------|-------------|----------|--------------------|
| **basic** | Standard obfuscation | Development/Testing | Minimal (5%) |
| **high** | Enhanced protection | Web Applications | Low (10%) |
| **advanced** | Military-grade security | Enterprise Software | Medium (15%) |
| **maximum** | Full AI-resistant suite | Defense/Financial | High (20%) |
| **military** | Quantum-resistant | Classified Systems | Maximum (25%) |

### Complete Configuration Object

```javascript
const config = {
    // Core Security Settings
    encryptionLevel: 'advanced',        // basic, high, advanced, maximum, military
    antiDebug: true,                    // Enable anti-debugging protection
    vmDetection: true,                  // Enable VM/sandbox detection
    integrityCheck: true,               // Enable code integrity monitoring
    selfDestruct: true,                 // Enable self-destruct on tamper
    
    // Access Control
    domainLock: ['example.com'],        // Allowed domains (array)
    timeLock: '2024-12-31',            // Expiration date (YYYY-MM-DD)
    hardwareBind: true,                 // Enable hardware binding
    
    // Obfuscation Techniques
    stringEncryption: true,             // Encrypt string literals
    variableRenaming: true,             // Rename variables/functions
    controlFlowFlattening: true,        // Flatten control flow
    deadCodeInjection: true,            // Inject decoy code
    functionSplitting: true,            // Split functions
    arrayScrambling: true,              // Scramble arrays
    expressionComplexity: true,         // Add expression complexity
    
    // Advanced Features
    quantumResistant: true,             // Enable quantum-resistant encryption
    aiResistant: true,                  // Enable AI-resistant obfuscation
    blockchainVerification: false,      // Enable blockchain verification
    steganographicHiding: false,        // Enable steganographic hiding
    
    // Performance Options
    optimizeForSize: false,             // Optimize for smaller output
    optimizeForSpeed: true,             // Optimize for faster execution
    parallelProcessing: true,           // Enable parallel processing
    
    // Output Options
    generateMetadata: true,             // Generate .meta file
    generateKeys: true,                 // Generate .key file
    generateIntegrity: true,            // Generate .integrity file
    preserveComments: false,            // Preserve original comments
    
    // Debug Options (for development only)
    verbose: false,                     // Enable verbose logging
    debugMode: false,                   // Enable debug mode
    skipValidation: false               // Skip input validation
};
```

### Language-Specific Options

#### JavaScript/TypeScript
```javascript
const jsConfig = {
    encryptionLevel: 'advanced',
    antiDebug: true,
    vmDetection: true,
    browserCompatibility: true,         // Ensure browser compatibility
    nodeCompatibility: true,            // Ensure Node.js compatibility
    es6Support: true,                   // Support ES6+ features
    preserveAsync: true                 // Preserve async/await patterns
};
```

#### PHP
```javascript
const phpConfig = {
    encryptionLevel: 'maximum',
    antiDebug: true,
    vmDetection: true,
    phpVersion: '7.4',                  // Target PHP version
    preserveNamespaces: true,           // Preserve namespace declarations
    obfuscateIncludes: true,            // Obfuscate include/require statements
    encryptStrings: true                // Encrypt string literals
};
```

## 💡 Implementation Examples

### 1. Web Application Protection

#### Frontend JavaScript
```javascript
// protect-frontend.js
const AdvancedObfuscator = require('./core/obfuscator.js');
const fs = require('fs');
const path = require('path');

function protectWebApp() {
    const obfuscator = new AdvancedObfuscator({
        encryptionLevel: 'high',
        antiDebug: true,
        vmDetection: true,
        domainLock: ['mywebsite.com', 'www.mywebsite.com'],
        browserCompatibility: true
    });
    
    // Protect main application file
    const appJs = fs.readFileSync('src/app.js', 'utf8');
    const protectedApp = obfuscator.obfuscate(appJs, 'javascript');
    fs.writeFileSync('dist/app.js', protectedApp);
    
    // Protect utility files
    const utilsJs = fs.readFileSync('src/utils.js', 'utf8');
    const protectedUtils = obfuscator.obfuscate(utilsJs, 'javascript');
    fs.writeFileSync('dist/utils.js', protectedUtils);
    
    console.log('Web application protected successfully!');
}

protectWebApp();
```

#### Backend PHP
```javascript
// protect-backend.js
const AdvancedObfuscator = require('./core/obfuscator.js');
const fs = require('fs');

function protectPHPBackend() {
    const obfuscator = new AdvancedObfuscator({
        encryptionLevel: 'advanced',
        antiDebug: true,
        vmDetection: true,
        integrityCheck: true,
        domainLock: ['api.mywebsite.com']
    });
    
    // Protect API endpoints
    const apiFiles = ['api/auth.php', 'api/users.php', 'api/payments.php'];
    
    apiFiles.forEach(file => {
        const sourceCode = fs.readFileSync(file, 'utf8');
        const protectedCode = obfuscator.obfuscate(sourceCode, 'php');
        const outputFile = file.replace('api/', 'protected-api/');
        fs.writeFileSync(outputFile, protectedCode);
        console.log(`Protected: ${file} -> ${outputFile}`);
    });
}

protectPHPBackend();
```

### 2. Mobile Application Protection

#### React Native
```javascript
// protect-mobile.js
const AdvancedObfuscator = require('./core/obfuscator.js');
const fs = require('fs');
const glob = require('glob');

function protectMobileApp() {
    const obfuscator = new AdvancedObfuscator({
        encryptionLevel: 'maximum',
        antiDebug: true,
        vmDetection: true,
        hardwareBind: true,
        optimizeForSize: true,          // Important for mobile
        preserveAsync: true             // Preserve React Native patterns
    });
    
    // Find all JavaScript files in the project
    const jsFiles = glob.sync('src/**/*.{js,jsx}', {
        ignore: ['src/**/*.test.js', 'src/**/*.spec.js']
    });
    
    jsFiles.forEach(file => {
        const sourceCode = fs.readFileSync(file, 'utf8');
        const protectedCode = obfuscator.obfuscate(sourceCode, 'javascript');
        const outputFile = file.replace('src/', 'protected-src/');
        
        // Ensure output directory exists
        const outputDir = path.dirname(outputFile);
        fs.mkdirSync(outputDir, { recursive: true });
        
        fs.writeFileSync(outputFile, protectedCode);
        console.log(`Protected: ${file}`);
    });
    
    console.log(`Protected ${jsFiles.length} mobile app files`);
}

protectMobileApp();
```

### 3. Enterprise Software Protection

#### Multi-Language Enterprise App
```javascript
// protect-enterprise.js
const AdvancedObfuscator = require('./core/obfuscator.js');
const fs = require('fs');
const path = require('path');

class EnterpriseProtector {
    constructor() {
        this.obfuscator = new AdvancedObfuscator({
            encryptionLevel: 'military',
            antiDebug: true,
            vmDetection: true,
            integrityCheck: true,
            selfDestruct: true,
            hardwareBind: true,
            timeLock: '2025-12-31',
            quantumResistant: true,
            aiResistant: true
        });
    }
    
    protectJavaScript(inputDir, outputDir) {
        const files = this.findFiles(inputDir, '**/*.js');
        return this.processFiles(files, 'javascript', inputDir, outputDir);
    }
    
    protectPHP(inputDir, outputDir) {
        const files = this.findFiles(inputDir, '**/*.php');
        return this.processFiles(files, 'php', inputDir, outputDir);
    }
    
    protectJava(inputDir, outputDir) {
        const files = this.findFiles(inputDir, '**/*.java');
        return this.processFiles(files, 'java', inputDir, outputDir);
    }
    
    findFiles(dir, pattern) {
        const glob = require('glob');
        return glob.sync(path.join(dir, pattern));
    }
    
    processFiles(files, language, inputDir, outputDir) {
        const results = [];
        
        files.forEach(file => {
            try {
                const sourceCode = fs.readFileSync(file, 'utf8');
                const protectedCode = this.obfuscator.obfuscate(sourceCode, language);
                
                const relativePath = path.relative(inputDir, file);
                const outputFile = path.join(outputDir, relativePath);
                const outputDirPath = path.dirname(outputFile);
                
                fs.mkdirSync(outputDirPath, { recursive: true });
                fs.writeFileSync(outputFile, protectedCode);
                
                results.push({ input: file, output: outputFile, status: 'success' });
            } catch (error) {
                results.push({ input: file, status: 'error', error: error.message });
            }
        });
        
        return results;
    }
    
    generateReport(results) {
        const successful = results.filter(r => r.status === 'success').length;
        const failed = results.filter(r => r.status === 'error').length;
        
        console.log(`\n=== Protection Report ===`);
        console.log(`Successful: ${successful}`);
        console.log(`Failed: ${failed}`);
        console.log(`Total: ${results.length}`);
        
        if (failed > 0) {
            console.log(`\nFailed files:`);
            results.filter(r => r.status === 'error').forEach(r => {
                console.log(`  ${r.input}: ${r.error}`);
            });
        }
    }
}

// Usage
const protector = new EnterpriseProtector();

// Protect different components
const jsResults = protector.protectJavaScript('src/frontend', 'dist/frontend');
const phpResults = protector.protectPHP('src/backend', 'dist/backend');
const javaResults = protector.protectJava('src/services', 'dist/services');

// Generate comprehensive report
const allResults = [...jsResults, ...phpResults, ...javaResults];
protector.generateReport(allResults);
```

## 🔗 Integration Guide

### Build System Integration

#### Webpack Plugin
```javascript
// webpack-obfuscation-plugin.js
const AdvancedObfuscator = require('./core/obfuscator.js');

class ObfuscationPlugin {
    constructor(options = {}) {
        this.options = {
            encryptionLevel: 'advanced',
            antiDebug: true,
            vmDetection: true,
            ...options
        };
        this.obfuscator = new AdvancedObfuscator(this.options);
    }
    
    apply(compiler) {
        compiler.hooks.emit.tapAsync('ObfuscationPlugin', (compilation, callback) => {
            Object.keys(compilation.assets).forEach(filename => {
                if (filename.endsWith('.js')) {
                    const source = compilation.assets[filename].source();
                    const protected = this.obfuscator.obfuscate(source, 'javascript');
                    
                    compilation.assets[filename] = {
                        source: () => protected,
                        size: () => protected.length
                    };
                }
            });
            callback();
        });
    }
}

module.exports = ObfuscationPlugin;

// webpack.config.js
const ObfuscationPlugin = require('./webpack-obfuscation-plugin');

module.exports = {
    // ... other webpack config
    plugins: [
        new ObfuscationPlugin({
            encryptionLevel: 'maximum',
            antiDebug: true,
            vmDetection: true,
            domainLock: ['myapp.com']
        })
    ]
};
```

#### Gulp Task
```javascript
// gulpfile.js
const gulp = require('gulp');
const through2 = require('through2');
const AdvancedObfuscator = require('./core/obfuscator.js');

function createObfuscationTask(options = {}) {
    const obfuscator = new AdvancedObfuscator({
        encryptionLevel: 'advanced',
        antiDebug: true,
        vmDetection: true,
        ...options
    });
    
    return through2.obj(function(file, _, cb) {
        if (file.isBuffer()) {
            const content = file.contents.toString();
            const language = file.extname === '.php' ? 'php' : 'javascript';
            const protected = obfuscator.obfuscate(content, language);
            file.contents = Buffer.from(protected);
        }
        cb(null, file);
    });
}

gulp.task('obfuscate-js', () => {
    return gulp.src('src/**/*.js')
        .pipe(createObfuscationTask({ encryptionLevel: 'high' }))
        .pipe(gulp.dest('dist/'));
});

gulp.task('obfuscate-php', () => {
    return gulp.src('src/**/*.php')
        .pipe(createObfuscationTask({ encryptionLevel: 'maximum' }))
        .pipe(gulp.dest('dist/'));
});

gulp.task('obfuscate', gulp.parallel('obfuscate-js', 'obfuscate-php'));
```

### CI/CD Pipeline Integration

#### GitHub Actions
```yaml
# .github/workflows/obfuscate-and-deploy.yml
name: Obfuscate and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  obfuscate:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
    
    - name: Obfuscate source code
      run: |
        mkdir -p dist
        node cli/obfuscate.js --batch src --output dist --encryption-level advanced
    
    - name: Verify obfuscated files
      run: |
        echo "Checking obfuscated files..."
        find dist -name "*.js" -exec echo "File: {}" \; -exec head -5 {} \;
    
    - name: Upload obfuscated artifacts
      uses: actions/upload-artifact@v3
      with:
        name: obfuscated-code
        path: dist/
        retention-days: 30
    
    - name: Deploy to staging
      if: github.ref == 'refs/heads/main'
      run: |
        echo "Deploying obfuscated code to staging..."
        # Add your deployment commands here
```

#### Jenkins Pipeline
```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        NODE_VERSION = '18'
        ENCRYPTION_LEVEL = 'advanced'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                sh 'npm ci'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Obfuscate') {
            steps {
                script {
                    sh '''
                        mkdir -p dist
                        node cli/obfuscate.js \
                            --batch src \
                            --output dist \
                            --encryption-level ${ENCRYPTION_LEVEL} \
                            --anti-debug \
                            --vm-detection
                    '''
                }
            }
        }
        
        stage('Package') {
            steps {
                archiveArtifacts artifacts: 'dist/**/*', fingerprint: true
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    // Add deployment logic here
                    echo 'Deploying obfuscated code...'
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Obfuscation and deployment completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
```

## 🛡️ Security Levels

### Level Comparison

| Feature | Basic | High | Advanced | Maximum | Military |
|---------|-------|------|----------|---------|----------|
| **String Encryption** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Variable Renaming** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Control Flow** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Dead Code Injection** | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Anti-Debugging** | ❌ | ❌ | ✅ | ✅ | ✅ |
| **VM Detection** | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Domain Locking** | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Hardware Binding** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Quantum Resistance** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **AI Resistance** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Self-Destruct** | ❌ | ❌ | ❌ | ✅ | ✅ |

### Recommended Use Cases

#### Basic Level
- **Use Case**: Development and testing
- **Performance Impact**: Minimal (5%)
- **Protection**: Standard obfuscation only
- **Example**:
  ```javascript
  const obfuscator = new AdvancedObfuscator({
      encryptionLevel: 'basic'
  });
  ```

#### High Level
- **Use Case**: Web applications, mobile apps
- **Performance Impact**: Low (10%)
- **Protection**: Enhanced obfuscation + string encryption
- **Example**:
  ```javascript
  const obfuscator = new AdvancedObfuscator({
      encryptionLevel: 'high',
      stringEncryption: true,
      controlFlowFlattening: true
  });
  ```

#### Advanced Level
- **Use Case**: Enterprise software, SaaS platforms
- **Performance Impact**: Medium (15%)
- **Protection**: Military-grade + runtime protection
- **Example**:
  ```javascript
  const obfuscator = new AdvancedObfuscator({
      encryptionLevel: 'advanced',
      antiDebug: true,
      vmDetection: true,
      integrityCheck: true,
      domainLock: ['mycompany.com']
  });
  ```

#### Maximum Level
- **Use Case**: Financial systems, healthcare applications
- **Performance Impact**: High (20%)
- **Protection**: Full AI-resistant suite
- **Example**:
  ```javascript
  const obfuscator = new AdvancedObfuscator({
      encryptionLevel: 'maximum',
      antiDebug: true,
      vmDetection: true,
      integrityCheck: true,
      selfDestruct: true,
      hardwareBind: true,
      aiResistant: true
  });
  ```

#### Military Level
- **Use Case**: Defense systems, classified applications
- **Performance Impact**: Maximum (25%)
- **Protection**: Quantum-resistant + all features
- **Example**:
  ```javascript
  const obfuscator = new AdvancedObfuscator({
      encryptionLevel: 'military',
      antiDebug: true,
      vmDetection: true,
      integrityCheck: true,
      selfDestruct: true,
      hardwareBind: true,
      quantumResistant: true,
      aiResistant: true,
      blockchainVerification: true
  });
  ```

## 📚 Best Practices

### Security Best Practices

#### 1. Key Management
```javascript
// ❌ BAD: Hardcoded keys
const obfuscator = new AdvancedObfuscator({
    encryptionKey: 'hardcoded-key-123'
});

// ✅ GOOD: Environment-based keys
const obfuscator = new AdvancedObfuscator({
    encryptionKey: process.env.OBFUSCATION_KEY,
    keyRotation: true
});
```

#### 2. Domain Locking
```javascript
// ✅ GOOD: Proper domain configuration
const obfuscator = new AdvancedObfuscator({
    domainLock: [
        'myapp.com',
        'www.myapp.com',
        'api.myapp.com'
    ],
    subdomainSupport: true,
    httpsOnly: true
});
```

#### 3. Error Handling
```javascript
// ✅ GOOD: Comprehensive error handling
function protectCode(sourceCode, language) {
    try {
        const obfuscator = new AdvancedObfuscator({
            encryptionLevel: 'advanced',
            antiDebug: true
        });
        
        return obfuscator.obfuscate(sourceCode, language);
    } catch (error) {
        console.error('Obfuscation failed:', error.message);
        
        // Log error details for debugging
        if (process.env.NODE_ENV === 'development') {
            console.error('Stack trace:', error.stack);
        }
        
        // Return original code in development, throw in production
        if (process.env.NODE_ENV === 'development') {
            console.warn('Returning original code due to obfuscation failure');
            return sourceCode;
        } else {
            throw new Error('Code protection failed');
        }
    }
}
```

### Performance Best Practices

#### 1. Batch Processing
```javascript
// ✅ GOOD: Process multiple files efficiently
const obfuscator = new AdvancedObfuscator({
    encryptionLevel: 'advanced',
    parallelProcessing: true,
    cacheResults: true
});

const files = ['app.js', 'utils.js', 'config.js'];
const results = obfuscator.obfuscateBatch(files, 'javascript');
```

#### 2. Selective Protection
```javascript
// ✅ GOOD: Only protect sensitive files
const sensitiveFiles = [
    'src/auth.js',
    'src/payment.js',
    'src/encryption.js'
];

const regularFiles = [
    'src/ui.js',
    'src/helpers.js'
];

// High protection for sensitive files
sensitiveFiles.forEach(file => {
    const obfuscator = new AdvancedObfuscator({ encryptionLevel: 'military' });
    // Process with maximum security
});

// Basic protection for regular files
regularFiles.forEach(file => {
    const obfuscator = new AdvancedObfuscator({ encryptionLevel: 'basic' });
    // Process with minimal overhead
});
```

### Development Best Practices

#### 1. Environment-Specific Configuration
```javascript
// config/obfuscation.js
module.exports = {
    development: {
        encryptionLevel: 'basic',
        antiDebug: false,
        vmDetection: false,
        verbose: true
    },
    staging: {
        encryptionLevel: 'high',
        antiDebug: true,
        vmDetection: true,
        domainLock: ['staging.myapp.com']
    },
    production: {
        encryptionLevel: 'advanced',
        antiDebug: true,
        vmDetection: true,
        integrityCheck: true,
        domainLock: ['myapp.com', 'www.myapp.com']
    }
};

// Usage
const config = require('./config/obfuscation')[process.env.NODE_ENV];
const obfuscator = new AdvancedObfuscator(config);
```

#### 2. Testing Protected Code
```javascript
// test/obfuscation.test.js
const AdvancedObfuscator = require('../core/obfuscator.js');
const fs = require('fs');

describe('Code Obfuscation', () => {
    let obfuscator;
    
    beforeEach(() => {
        obfuscator = new AdvancedObfuscator({
            encryptionLevel: 'basic',  // Use basic level for testing
            antiDebug: false,          // Disable for testing
            vmDetection: false
        });
    });
    
    test('should obfuscate JavaScript code', () => {
        const sourceCode = 'function test() { return "hello"; }';
        const obfuscated = obfuscator.obfuscate(sourceCode, 'javascript');
        
        expect(obfuscated).toBeDefined();
        expect(obfuscated).not.toBe(sourceCode);
        expect(obfuscated.length).toBeGreaterThan(sourceCode.length);
    });
    
    test('should preserve functionality', () => {
        const sourceCode = `
            function add(a, b) {
                return a + b;
            }
            module.exports = add;
        `;
        
        const obfuscated = obfuscator.obfuscate(sourceCode, 'javascript');
        
        // Write to temporary file and test
        const tempFile = 'temp-test.js';
        fs.writeFileSync(tempFile, obfuscated);
        
        const addFunction = require('./' + tempFile);
        expect(addFunction(2, 3)).toBe(5);
        
        // Cleanup
        fs.unlinkSync(tempFile);
    });
});
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. "Module not found" Error
```bash
Error: Cannot find module './core/obfuscator.js'
```

**Solution:**
```bash
# Ensure you're in the correct directory
cd /path/to/advanced-code-obfuscator

# Check if the file exists
ls -la core/obfuscator.js

# Install dependencies if missing
npm install
```

#### 2. "Permission denied" Error
```bash
Error: EACCES: permission denied, open 'output.js'
```

**Solution:**
```bash
# Check file permissions
ls -la output.js

# Fix permissions
chmod 644 output.js

# Or run with appropriate permissions
sudo node cli/obfuscate.js --input input.js --output output.js
```

#### 3. "Out of memory" Error
```bash
FATAL ERROR: Ineffective mark-compacts near heap limit
```

**Solution:**
```bash
# Increase Node.js memory limit
node --max-old-space-size=4096 cli/obfuscate.js --input large-file.js

# Or process files in smaller batches
node cli/obfuscate.js --batch src/ --output dist/ --batch-size 10
```

#### 4. Obfuscated Code Not Working

**Common Causes:**
- Syntax errors in original code
- Unsupported language features
- Missing dependencies

**Solution:**
```javascript
// Enable debug mode to see detailed logs
const obfuscator = new AdvancedObfuscator({
    encryptionLevel: 'basic',
    debugMode: true,
    verbose: true
});

// Test with minimal configuration first
const obfuscator = new AdvancedObfuscator({
    encryptionLevel: 'basic',
    antiDebug: false,
    vmDetection: false
});
```

#### 5. Performance Issues

**Symptoms:**
- Slow processing
- High memory usage
- Large output files

**Solutions:**
```javascript
// Optimize for performance
const obfuscator = new AdvancedObfuscator({
    encryptionLevel: 'high',        // Reduce from 'maximum' or 'military'
    optimizeForSpeed: true,
    parallelProcessing: true,
    deadCodeInjection: false,       // Disable if not needed
    expressionComplexity: false     // Disable if not needed
});
```

### Debug Mode

```javascript
// Enable comprehensive debugging
const obfuscator = new AdvancedObfuscator({
    encryptionLevel: 'basic',
    debugMode: true,
    verbose: true,
    generateMetadata: true
});

const result = obfuscator.obfuscate(sourceCode, 'javascript');

// Check metadata for processing details
const metadata = obfuscator.getLastMetadata();
console.log('Processing time:', metadata.processingTime);
console.log('Original size:', metadata.originalSize);
console.log('Obfuscated size:', metadata.obfuscatedSize);
console.log('Compression ratio:', metadata.compressionRatio);
```

### Validation

```javascript
// Validate configuration before processing
function validateConfig(config) {
    const errors = [];
    
    if (!['basic', 'high', 'advanced', 'maximum', 'military'].includes(config.encryptionLevel)) {
        errors.push('Invalid encryption level');
    }
    
    if (config.domainLock && !Array.isArray(config.domainLock)) {
        errors.push('domainLock must be an array');
    }
    
    if (config.timeLock && !/^\d{4}-\d{2}-\d{2}$/.test(config.timeLock)) {
        errors.push('timeLock must be in YYYY-MM-DD format');
    }
    
    return errors;
}

// Usage
const config = { encryptionLevel: 'advanced' };
const errors = validateConfig(config);

if (errors.length > 0) {
    console.error('Configuration errors:', errors);
    process.exit(1);
}

const obfuscator = new AdvancedObfuscator(config);
```

## 🚀 Advanced Features

### Custom Processors

```javascript
// Create custom processor for new language
class CustomProcessor {
    constructor(options = {}) {
        this.options = options;
    }
    
    process(sourceCode) {
        // Implement custom obfuscation logic
        let processed = sourceCode;
        
        // Example: Simple string replacement
        processed = processed.replace(/function/g, 'func');
        processed = processed.replace(/return/g, 'ret');
        
        return processed;
    }
    
    validate(sourceCode) {
        // Implement validation logic
        return sourceCode.length > 0;
    }
}

// Register custom processor
const obfuscator = new AdvancedObfuscator();
obfuscator.registerProcessor('custom', CustomProcessor);

// Use custom processor
const result = obfuscator.obfuscate(sourceCode, 'custom');
```

### Plugin System

```javascript
// Create custom plugin
class AntiTamperPlugin {
    constructor(options = {}) {
        this.options = options;
    }
    
    beforeObfuscation(sourceCode, language) {
        console.log(`Processing ${language} code...`);
        return sourceCode;
    }
    
    afterObfuscation(obfuscatedCode, language) {
        // Add anti-tamper checks
        const antiTamperCode = `
            (function() {
                var originalCode = ${JSON.stringify(obfuscatedCode)};
                setInterval(function() {
                    if (document.body.innerHTML !== originalCode) {
                        window.location.href = 'about:blank';
                    }
                }, 1000);
            })();
        `;
        
        return antiTamperCode + obfuscatedCode;
    }
}

// Use plugin
const obfuscator = new AdvancedObfuscator();
obfuscator.use(new AntiTamperPlugin());
```

### Batch Processing with Progress

```javascript
// Advanced batch processing
const AdvancedObfuscator = require('./core/obfuscator.js');
const fs = require('fs');
const path = require('path');
const glob = require('glob');

class BatchProcessor {
    constructor(options = {}) {
        this.obfuscator = new AdvancedObfuscator(options);
        this.progress = 0;
        this.total = 0;
    }
    
    async processDirectory(inputDir, outputDir, pattern = '**/*.{js,php,java}') {
        const files = glob.sync(path.join(inputDir, pattern));
        this.total = files.length;
        this.progress = 0;
        
        console.log(`Found ${this.total} files to process`);
        
        const results = [];
        
        for (const file of files) {
            try {
                const result = await this.processFile(file, inputDir, outputDir);
                results.push(result);
                this.progress++;
                this.showProgress();
            } catch (error) {
                console.error(`Failed to process ${file}:`, error.message);
                results.push({ file, status: 'error', error: error.message });
            }
        }
        
        return results;
    }
    
    async processFile(filePath, inputDir, outputDir) {
        const sourceCode = fs.readFileSync(filePath, 'utf8');
        const language = this.detectLanguage(filePath);
        
        const obfuscated = this.obfuscator.obfuscate(sourceCode, language);
        
        const relativePath = path.relative(inputDir, filePath);
        const outputPath = path.join(outputDir, relativePath);
        const outputDirPath = path.dirname(outputPath);
        
        fs.mkdirSync(outputDirPath, { recursive: true });
        fs.writeFileSync(outputPath, obfuscated);
        
        return {
            file: filePath,
            output: outputPath,
            status: 'success',
            originalSize: sourceCode.length,
            obfuscatedSize: obfuscated.length
        };
    }
    
    detectLanguage(filePath) {
        const ext = path.extname(filePath).toLowerCase();
        const languageMap = {
            '.js': 'javascript',
            '.jsx': 'javascript',
            '.ts': 'typescript',
            '.tsx': 'typescript',
            '.php': 'php',
            '.java': 'java',
            '.kt': 'kotlin',
            '.cs': 'csharp',
            '.go': 'go',
            '.swift': 'swift',
            '.dart': 'dart'
        };
        
        return languageMap[ext] || 'javascript';
    }
    
    showProgress() {
        const percentage = Math.round((this.progress / this.total) * 100);
        const bar = '█'.repeat(Math.round(percentage / 2)) + '░'.repeat(50 - Math.round(percentage / 2));
        process.stdout.write(`\r[${bar}] ${percentage}% (${this.progress}/${this.total})`);
        
        if (this.progress === this.total) {
            console.log('\nProcessing complete!');
        }
    }
}

// Usage
async function main() {
    const processor = new BatchProcessor({
        encryptionLevel: 'advanced',
        antiDebug: true,
        vmDetection: true
    });
    
    const results = await processor.processDirectory('src', 'dist');
    
    // Generate report
    const successful = results.filter(r => r.status === 'success');
    const failed = results.filter(r => r.status === 'error');
    
    console.log(`\n=== Batch Processing Report ===`);
    console.log(`Successful: ${successful.length}`);
    console.log(`Failed: ${failed.length}`);
    
    if (successful.length > 0) {
        const totalOriginalSize = successful.reduce((sum, r) => sum + r.originalSize, 0);
        const totalObfuscatedSize = successful.reduce((sum, r) => sum + r.obfuscatedSize, 0);
        const compressionRatio = ((totalObfuscatedSize / totalOriginalSize) * 100).toFixed(1);
        
        console.log(`Total original size: ${(totalOriginalSize / 1024).toFixed(1)} KB`);
        console.log(`Total obfuscated size: ${(totalObfuscatedSize / 1024).toFixed(1)} KB`);
        console.log(`Size ratio: ${compressionRatio}%`);
    }
}

main().catch(console.error);
```

---

## 📞 Support and Resources

### Getting Help

1. **Documentation**: Check this usage guide and the features documentation
2. **Examples**: Review the `examples/` directory for practical implementations
3. **Issues**: Report bugs or request features on GitHub
4. **Testing**: Run `node examples/demo.js` to verify installation

### Additional Resources

- **GitHub Repository**: [Link to repository]
- **API Documentation**: See `notes/FEATURES.md`
- **Change Log**: See `notes/CHANGELOG.md`
- **Release Notes**: See `notes/RELEASE_NOTES_v3.0.0.md`

### Community

- **Discussions**: GitHub Discussions for questions and ideas
- **Issues**: GitHub Issues for bug reports and feature requests
- **Contributing**: See CONTRIBUTING.md for development guidelines

---

> 🛡️ **Security Notice**: This tool provides military-grade protection for your intellectual property. Always test thoroughly in your specific environment and follow security best practices.

> ⚡ **Performance Tip**: Start with lower security levels during development and increase protection for production deployments.

> 🌟 **Future-Proof**: Built with post-quantum cryptography and AI-resistant architecture to protect against emerging threats.