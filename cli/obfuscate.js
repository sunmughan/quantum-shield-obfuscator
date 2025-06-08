#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { program } = require('commander');
const AdvancedObfuscator = require('../core/obfuscator');

class UltimateObfuscatorCLI {
    constructor() {
        this.setupCommander();
    }

    setupCommander() {
        program
            .version('2.0.0')
            .description('🔐 Ultimate Multi-Language Code Obfuscation Engine - Unbreakable Protection')
            .option('-i, --input <file>', 'Input file to obfuscate')
            .option('-o, --output <file>', 'Output file for obfuscated code')
            .option('-l, --language <lang>', 'Programming language (auto-detected if not specified)')
            .option('-e, --encryption-level <level>', 'Encryption level: basic|advanced|maximum|military', 'military')
            .option('-k, --key <key>', 'Custom encryption key (auto-generated if not specified)')
            .option('--iterations <num>', 'PBKDF2 iterations (default: 200000)', '200000')
            .option('--anti-debug', 'Enable advanced anti-debugging (default: true)', true)
            .option('--control-flow', 'Enable control flow obfuscation (default: true)', true)
            .option('--dead-code', 'Enable dead code injection (default: true)', true)
            .option('--string-encrypt', 'Enable string encryption (default: true)', true)
            .option('--domain-lock <domains>', 'Comma-separated allowed domains')
            .option('--expiration <date>', 'Expiration date (YYYY-MM-DD)')
            .option('--self-destruct', 'Enable self-destruct on tampering')
            .option('--vm-detection', 'Enable VM/sandbox detection')
            .option('--integrity-check', 'Enable runtime integrity checking')
            .option('--batch <dir>', 'Batch process directory')
            .option('--config <file>', 'Configuration file path')
            .option('--verbose', 'Verbose output')
            .parse();
    }

    async run() {
        const options = program.opts();
        
        try {
            if (options.batch) {
                await this.batchObfuscate(options);
            } else if (options.input) {
                await this.obfuscateFile(options);
            } else {
                this.showAdvancedHelp();
            }
        } catch (error) {
            console.error('❌ Fatal Error:', error.message);
            if (options.verbose) {
                console.error(error.stack);
            }
            process.exit(1);
        }
    }

    async obfuscateFile(options) {
        const config = await this.loadConfig(options);
        const obfuscator = new AdvancedObfuscator(config);
        
        if (!fs.existsSync(options.input)) {
            throw new Error(`Input file not found: ${options.input}`);
        }

        const code = fs.readFileSync(options.input, 'utf8');
        const language = options.language || this.detectLanguage(options.input);
        const outputFile = options.output || this.generateOutputPath(options.input);
        
        console.log(`🔐 Obfuscating ${options.input} (${language}) with ${config.encryptionLevel} protection...`);
        
        const startTime = Date.now();
        const result = obfuscator.obfuscate(code, language, {
            militaryGrade: config.encryptionLevel === 'military',
            antiVM: options.vmDetection,
            selfDestruct: options.selfDestruct,
            integrityCheck: options.integrityCheck
        });
        const duration = Date.now() - startTime;
        
        // Write obfuscated code
        fs.writeFileSync(outputFile, result.obfuscatedCode);
        
        // Write metadata with enhanced security info
        const metaFile = outputFile + '.meta';
        fs.writeFileSync(metaFile, JSON.stringify({
            ...result.metadata,
            processingTime: duration,
            securityLevel: config.encryptionLevel,
            protectionFeatures: this.getEnabledFeatures(config),
            timestamp: new Date().toISOString()
        }, null, 2));
        
        // Write encrypted key file
        const keyFile = outputFile + '.key';
        const encryptedKeyData = this.encryptKeyData(result.decryptionInfo, config.masterKey);
        fs.writeFileSync(keyFile, JSON.stringify(encryptedKeyData, null, 2));
        
        // Generate integrity hash
        const integrityFile = outputFile + '.integrity';
        const integrityHash = this.generateIntegrityHash(result.obfuscatedCode, result.decryptionInfo.key);
        fs.writeFileSync(integrityFile, integrityHash);
        
        this.displayResults({
            input: options.input,
            output: outputFile,
            language,
            duration,
            originalSize: code.length,
            obfuscatedSize: result.obfuscatedCode.length,
            compressionRatio: (result.obfuscatedCode.length / code.length * 100).toFixed(2),
            securityLevel: config.encryptionLevel,
            features: this.getEnabledFeatures(config)
        });
    }

    async batchObfuscate(options) {
        const inputDir = options.batch;
        const outputDir = options.output || inputDir + '_obfuscated';
        
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }

        const files = this.getAllFiles(inputDir).filter(file => this.isSupportedFile(file));
        console.log(`🔄 Processing ${files.length} files in batch mode...`);
        
        let processed = 0;
        let failed = 0;
        
        for (const file of files) {
            try {
                const relativePath = path.relative(inputDir, file);
                const outputPath = path.join(outputDir, relativePath);
                const outputDirPath = path.dirname(outputPath);

                if (!fs.existsSync(outputDirPath)) {
                    fs.mkdirSync(outputDirPath, { recursive: true });
                }

                await this.obfuscateFile({
                    ...options,
                    input: file,
                    output: outputPath
                });
                
                processed++;
                console.log(`✅ [${processed}/${files.length}] ${relativePath}`);
            } catch (error) {
                failed++;
                console.error(`❌ Failed to process ${file}: ${error.message}`);
            }
        }
        
        console.log(`\n📊 Batch processing complete: ${processed} successful, ${failed} failed`);
    }

    async loadConfig(options) {
        let config = {
            encryptionLevel: options.encryptionLevel,
            encryptionKey: options.key || crypto.randomBytes(32).toString('hex'),
            masterKey: crypto.randomBytes(32).toString('hex'),
            iterations: parseInt(options.iterations),
            algorithm: 'aes-256-gcm',
            antiDebug: options.antiDebug,
            controlFlow: options.controlFlow,
            deadCode: options.deadCode,
            stringEncrypt: options.stringEncrypt,
            domainLock: options.domainLock ? options.domainLock.split(',') : null,
            expiration: options.expiration,
            vmDetection: options.vmDetection,
            selfDestruct: options.selfDestruct,
            integrityCheck: options.integrityCheck
        };
        
        if (options.config && fs.existsSync(options.config)) {
            const fileConfig = JSON.parse(fs.readFileSync(options.config, 'utf8'));
            config = { ...config, ...fileConfig };
        }
        
        // Apply encryption level presets
        switch (config.encryptionLevel) {
            case 'military':
                config.iterations = Math.max(config.iterations, 500000);
                config.antiDebug = true;
                config.controlFlow = true;
                config.deadCode = true;
                config.stringEncrypt = true;
                config.vmDetection = true;
                config.integrityCheck = true;
                break;
            case 'maximum':
                config.iterations = Math.max(config.iterations, 300000);
                break;
            case 'advanced':
                config.iterations = Math.max(config.iterations, 150000);
                break;
        }
        
        return config;
    }

    detectLanguage(filePath) {
        const ext = path.extname(filePath).toLowerCase();
        const languageMap = {
            '.js': 'javascript',
            '.jsx': 'javascript',
            '.ts': 'javascript',
            '.tsx': 'javascript',
            '.mjs': 'javascript',
            '.php': 'php',
            '.php5': 'php',
            '.php7': 'php',
            '.dart': 'dart',
            '.kt': 'kotlin',
            '.kts': 'kotlin'
        };
        return languageMap[ext] || 'javascript';
    }

    isSupportedFile(filePath) {
        const supportedExtensions = ['.js', '.jsx', '.ts', '.tsx', '.mjs', '.php', '.php5', '.php7', '.dart', '.kt', '.kts'];
        return supportedExtensions.includes(path.extname(filePath).toLowerCase());
    }

    getAllFiles(dir) {
        let files = [];
        const items = fs.readdirSync(dir);
        
        for (const item of items) {
            const fullPath = path.join(dir, item);
            const stat = fs.statSync(fullPath);
            
            if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
                files = files.concat(this.getAllFiles(fullPath));
            } else if (stat.isFile()) {
                files.push(fullPath);
            }
        }
        
        return files;
    }

    generateOutputPath(inputPath) {
        const ext = path.extname(inputPath);
        const base = path.basename(inputPath, ext);
        const dir = path.dirname(inputPath);
        return path.join(dir, `${base}.obfuscated${ext}`);
    }

    encryptKeyData(keyData, masterKey) {
        const iv = crypto.randomBytes(16);
        const keyBuffer = Buffer.isBuffer(masterKey) ? masterKey.slice(0, 32) : Buffer.from(String(masterKey).substring(0, 32));
        const cipher = crypto.createCipheriv('aes-256-cbc', keyBuffer, iv);
        let encrypted = cipher.update(JSON.stringify(keyData), 'utf8', 'hex');
        encrypted += cipher.final('hex');
        return {
            encrypted,
            algorithm: 'aes-256-cbc',
            timestamp: Date.now()
        };
    }

    generateIntegrityHash(code, key) {
        return crypto.createHmac('sha256', key).update(code).digest('hex');
    }

    getEnabledFeatures(config) {
        const features = [];
        if (config.antiDebug) features.push('Anti-Debug');
        if (config.controlFlow) features.push('Control Flow Obfuscation');
        if (config.deadCode) features.push('Dead Code Injection');
        if (config.stringEncrypt) features.push('String Encryption');
        if (config.vmDetection) features.push('VM Detection');
        if (config.selfDestruct) features.push('Self-Destruct');
        if (config.integrityCheck) features.push('Integrity Check');
        if (config.domainLock) features.push('Domain Locking');
        if (config.expiration) features.push('Time Expiration');
        return features;
    }

    displayResults(results) {
        console.log('\n🎉 Obfuscation Complete!');
        console.log('═'.repeat(50));
        console.log(`📁 Input:           ${results.input}`);
        console.log(`📁 Output:          ${results.output}`);
        console.log(`🔤 Language:        ${results.language}`);
        console.log(`⏱️  Processing Time: ${results.duration}ms`);
        console.log(`📊 Original Size:   ${results.originalSize} bytes`);
        console.log(`📊 Obfuscated Size: ${results.obfuscatedSize} bytes`);
        console.log(`📈 Size Ratio:      ${results.compressionRatio}%`);
        console.log(`🛡️  Security Level:  ${results.securityLevel.toUpperCase()}`);
        console.log(`🔧 Features:        ${results.features.join(', ')}`);
        console.log('═'.repeat(50));
        console.log('🔑 Files generated:');
        console.log(`   • ${results.output} (obfuscated code)`);
        console.log(`   • ${results.output}.meta (metadata)`);
        console.log(`   • ${results.output}.key (encryption keys - KEEP SECURE!)`);
        console.log(`   • ${results.output}.integrity (integrity hash)`);
        console.log('\n⚠️  IMPORTANT: Store key files securely and separately from obfuscated code!');
    }

    showAdvancedHelp() {
        console.log(`
🔐 Ultimate Multi-Language Code Obfuscation Engine v2.0
`);
        console.log('🚀 UNBREAKABLE PROTECTION FOR YOUR CODE\n');
        
        console.log('📋 USAGE:');
        console.log('  Single file:  obfuscate -i input.js -o output.js');
        console.log('  Batch mode:   obfuscate --batch ./src -o ./dist');
        console.log('  Auto-detect:  obfuscate -i app.php  (auto-detects language & output)');
        console.log('');
        
        console.log('🛡️  SECURITY LEVELS:');
        console.log('  • basic     - Fast obfuscation, minimal protection');
        console.log('  • advanced  - Balanced protection and performance');
        console.log('  • maximum   - High protection, slower execution');
        console.log('  • military  - UNBREAKABLE protection (recommended)');
        console.log('');
        
        console.log('🔧 ADVANCED OPTIONS:');
        console.log('  --anti-debug        Advanced anti-debugging protection');
        console.log('  --vm-detection      Detect and prevent VM/sandbox execution');
        console.log('  --self-destruct     Self-destruct on tampering attempts');
        console.log('  --integrity-check   Runtime integrity verification');
        console.log('  --domain-lock       Restrict execution to specific domains');
        console.log('  --expiration        Set code expiration date');
        console.log('');
        
        console.log('🎯 EXAMPLES:');
        console.log('  # Military-grade protection');
        console.log('  obfuscate -i app.js -e military --vm-detection --self-destruct');
        console.log('');
        console.log('  # Domain-locked web app');
        console.log('  obfuscate -i script.js --domain-lock "mysite.com,app.mysite.com"');
        console.log('');
        console.log('  # Time-limited trial');
        console.log('  obfuscate -i trial.js --expiration "2024-12-31"');
        console.log('');
        
        console.log('🌐 SUPPORTED LANGUAGES:');
        console.log('  ✅ JavaScript (.js, .jsx, .ts, .tsx, .mjs)');
        console.log('  ✅ PHP (.php, .php5, .php7)');
        console.log('  ✅ Dart (.dart)');
        console.log('  ✅ Kotlin (.kt, .kts)');
        console.log('');
        
        console.log('⚡ This tool provides MILITARY-GRADE protection that is virtually unbreakable!');
    }
}

if (require.main === module) {
    const cli = new UltimateObfuscatorCLI();
    cli.run().catch(console.error);
}

module.exports = UltimateObfuscatorCLI;