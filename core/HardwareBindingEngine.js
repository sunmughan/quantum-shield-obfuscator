const crypto = require('crypto');
const os = require('os');
const fs = require('fs');
const { execSync } = require('child_process');

class HardwareBindingEngine {
    constructor(options = {}) {
        this.options = {
            bindingStrength: options.bindingStrength || 'maximum',
            allowedDeviation: options.allowedDeviation || 0.1,
            hardwareComponents: options.hardwareComponents || ['cpu', 'memory', 'disk', 'network', 'gpu'],
            fingerprintComplexity: options.fingerprintComplexity || 'high',
            ...options
        };
        this.hardwareFingerprint = null;
        this.bindingKey = null;
    }

    async generateHardwareFingerprint() {
        const fingerprint = {
            cpu: await this.getCPUFingerprint(),
            memory: await this.getMemoryFingerprint(),
            disk: await this.getDiskFingerprint(),
            network: await this.getNetworkFingerprint(),
            gpu: await this.getGPUFingerprint(),
            motherboard: await this.getMotherboardFingerprint(),
            bios: await this.getBIOSFingerprint(),
            system: await this.getSystemFingerprint(),
            performance: await this.getPerformanceFingerprint(),
            timestamp: Date.now()
        };

        this.hardwareFingerprint = this.hashFingerprint(fingerprint);
        return this.hardwareFingerprint;
    }

    async getCPUFingerprint() {
        try {
            const cpus = os.cpus();
            const cpuInfo = {
                model: cpus[0].model,
                speed: cpus[0].speed,
                cores: cpus.length,
                architecture: os.arch(),
                features: await this.getCPUFeatures(),
                cacheSize: await this.getCPUCacheSize(),
                microcode: await this.getCPUMicrocode()
            };
            
            return crypto.createHash('sha256').update(JSON.stringify(cpuInfo)).digest('hex');
        } catch (error) {
            return crypto.createHash('sha256').update('cpu_fallback').digest('hex');
        }
    }

    async getCPUFeatures() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic cpu get Name,Characteristics /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            } else if (process.platform === 'linux') {
                const output = execSync('cat /proc/cpuinfo | grep flags', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_features';
        }
    }

    async getCPUCacheSize() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic cpu get L2CacheSize,L3CacheSize /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            } else if (process.platform === 'linux') {
                const output = execSync('lscpu | grep cache', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_cache';
        }
    }

    async getCPUMicrocode() {
        try {
            if (process.platform === 'linux') {
                const output = execSync('cat /proc/cpuinfo | grep microcode', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_microcode';
        }
    }

    async getMemoryFingerprint() {
        try {
            const memInfo = {
                total: os.totalmem(),
                free: os.freemem(),
                modules: await this.getMemoryModules(),
                timing: await this.getMemoryTiming(),
                manufacturer: await this.getMemoryManufacturer()
            };
            
            return crypto.createHash('sha256').update(JSON.stringify(memInfo)).digest('hex');
        } catch (error) {
            return crypto.createHash('sha256').update('memory_fallback').digest('hex');
        }
    }

    async getMemoryModules() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic memorychip get Capacity,Speed,Manufacturer /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            } else if (process.platform === 'linux') {
                const output = execSync('dmidecode -t memory 2>/dev/null | grep -E "Size|Speed|Manufacturer" || echo "unknown"', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_modules';
        }
    }

    async getMemoryTiming() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic memorychip get ConfiguredClockSpeed /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_timing';
        }
    }

    async getMemoryManufacturer() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic memorychip get Manufacturer /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_manufacturer';
        }
    }

    async getDiskFingerprint() {
        try {
            const diskInfo = {
                drives: await this.getDriveInfo(),
                serial: await this.getDiskSerial(),
                model: await this.getDiskModel(),
                firmware: await this.getDiskFirmware(),
                smart: await this.getSMARTData()
            };
            
            return crypto.createHash('sha256').update(JSON.stringify(diskInfo)).digest('hex');
        } catch (error) {
            return crypto.createHash('sha256').update('disk_fallback').digest('hex');
        }
    }

    async getDriveInfo() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic diskdrive get Size,Model,SerialNumber /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            } else if (process.platform === 'linux') {
                const output = execSync('lsblk -o NAME,SIZE,MODEL,SERIAL 2>/dev/null || echo "unknown"', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_drives';
        }
    }

    async getDiskSerial() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic diskdrive get SerialNumber /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_serial';
        }
    }

    async getDiskModel() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic diskdrive get Model /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_model';
        }
    }

    async getDiskFirmware() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic diskdrive get FirmwareRevision /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_firmware';
        }
    }

    async getSMARTData() {
        try {
            if (process.platform === 'win32') {
                // SMART data requires specialized tools, using basic disk info as fallback
                const output = execSync('wmic diskdrive get Status /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_smart';
        }
    }

    async getNetworkFingerprint() {
        try {
            const networkInfo = {
                interfaces: os.networkInterfaces(),
                hostname: os.hostname(),
                mac: await this.getMACAddresses(),
                adapters: await this.getNetworkAdapters()
            };
            
            return crypto.createHash('sha256').update(JSON.stringify(networkInfo)).digest('hex');
        } catch (error) {
            return crypto.createHash('sha256').update('network_fallback').digest('hex');
        }
    }

    async getMACAddresses() {
        try {
            const interfaces = os.networkInterfaces();
            const macs = [];
            
            Object.values(interfaces).forEach(iface => {
                iface.forEach(addr => {
                    if (addr.mac && addr.mac !== '00:00:00:00:00:00') {
                        macs.push(addr.mac);
                    }
                });
            });
            
            return macs.sort().join(',');
        } catch (error) {
            return 'unknown_mac';
        }
    }

    async getNetworkAdapters() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic path win32_networkadapter get Name,MACAddress /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_adapters';
        }
    }

    async getGPUFingerprint() {
        try {
            const gpuInfo = await this.getGPUInfo();
            return crypto.createHash('sha256').update(JSON.stringify(gpuInfo)).digest('hex');
        } catch (error) {
            return crypto.createHash('sha256').update('gpu_fallback').digest('hex');
        }
    }

    async getGPUInfo() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic path win32_videocontroller get Name,DriverVersion,AdapterRAM /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            } else if (process.platform === 'linux') {
                const output = execSync('lspci | grep VGA || echo "unknown"', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_gpu';
        }
    }

    async getMotherboardFingerprint() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic baseboard get Manufacturer,Product,SerialNumber /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            } else if (process.platform === 'linux') {
                const output = execSync('dmidecode -t baseboard 2>/dev/null | grep -E "Manufacturer|Product|Serial" || echo "unknown"', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_motherboard';
        }
    }

    async getBIOSFingerprint() {
        try {
            if (process.platform === 'win32') {
                const output = execSync('wmic bios get Manufacturer,SMBIOSBIOSVersion,ReleaseDate /format:list', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            } else if (process.platform === 'linux') {
                const output = execSync('dmidecode -t bios 2>/dev/null | grep -E "Vendor|Version|Release" || echo "unknown"', { encoding: 'utf8' });
                return crypto.createHash('md5').update(output).digest('hex');
            }
        } catch (error) {
            return 'unknown_bios';
        }
    }

    async getSystemFingerprint() {
        try {
            const systemInfo = {
                platform: os.platform(),
                release: os.release(),
                version: os.version(),
                arch: os.arch(),
                uptime: os.uptime(),
                loadavg: os.loadavg(),
                endianness: os.endianness()
            };
            
            return crypto.createHash('sha256').update(JSON.stringify(systemInfo)).digest('hex');
        } catch (error) {
            return crypto.createHash('sha256').update('system_fallback').digest('hex');
        }
    }

    async getPerformanceFingerprint() {
        try {
            const start = process.hrtime.bigint();
            
            // CPU performance test
            let sum = 0;
            for (let i = 0; i < 100000; i++) {
                sum += Math.sqrt(i);
            }
            
            const cpuTime = process.hrtime.bigint() - start;
            
            // Memory performance test
            const memStart = process.hrtime.bigint();
            const largeArray = new Array(10000).fill(0).map(() => Math.random());
            largeArray.sort();
            const memTime = process.hrtime.bigint() - memStart;
            
            const performanceInfo = {
                cpuTime: cpuTime.toString(),
                memTime: memTime.toString(),
                nodeVersion: process.version,
                v8Version: process.versions.v8
            };
            
            return crypto.createHash('sha256').update(JSON.stringify(performanceInfo)).digest('hex');
        } catch (error) {
            return crypto.createHash('sha256').update('performance_fallback').digest('hex');
        }
    }

    hashFingerprint(fingerprint) {
        const fingerprintString = JSON.stringify(fingerprint, Object.keys(fingerprint).sort());
        return crypto.createHash('sha512').update(fingerprintString).digest('hex');
    }

    generateBindingKey() {
        if (!this.hardwareFingerprint) {
            throw new Error('Hardware fingerprint must be generated first');
        }
        
        const keyMaterial = this.hardwareFingerprint + Date.now().toString();
        this.bindingKey = crypto.createHash('sha256').update(keyMaterial).digest('hex');
        
        return this.bindingKey;
    }

    bindCodeToHardware(code, language) {
        if (!this.bindingKey) {
            this.generateBindingKey();
        }
        
        const bindingCode = this.generateBindingCode(language);
        const verificationCode = this.generateVerificationCode(language);
        
        return this.injectBindingCode(code, bindingCode, verificationCode, language);
    }

    generateBindingCode(language) {
        const bindingTemplates = {
            javascript: `
// Hardware binding verification
const _hwBinding = {
    verify: async function() {
        const hwFingerprint = await this.getHardwareFingerprint();
        const expectedFingerprint = '${this.hardwareFingerprint}';
        
        if (hwFingerprint !== expectedFingerprint) {
            throw new Error('Hardware binding verification failed');
        }
        
        return true;
    },
    
    getHardwareFingerprint: async function() {
        const os = require('os');
        const crypto = require('crypto');
        
        const fingerprint = {
            cpu: os.cpus()[0].model + os.cpus().length,
            memory: os.totalmem().toString(),
            platform: os.platform(),
            arch: os.arch(),
            hostname: os.hostname()
        };
        
        return crypto.createHash('sha512').update(JSON.stringify(fingerprint)).digest('hex');
    }
};

// Verify hardware binding before execution
_hwBinding.verify().catch(() => {
    process.exit(1);
});
`,
            php: `
<?php
// Hardware binding verification
class HardwareBinding {
    private static $expectedFingerprint = '${this.hardwareFingerprint}';
    
    public static function verify() {
        $hwFingerprint = self::getHardwareFingerprint();
        
        if ($hwFingerprint !== self::$expectedFingerprint) {
            die('Hardware binding verification failed');
        }
        
        return true;
    }
    
    private static function getHardwareFingerprint() {
        $fingerprint = array(
            'cpu' => php_uname('m'),
            'system' => php_uname('s'),
            'release' => php_uname('r'),
            'hostname' => gethostname()
        );
        
        return hash('sha512', json_encode($fingerprint));
    }
}

// Verify hardware binding
HardwareBinding::verify();
?>
`,
            dart: `
// Hardware binding verification
class HardwareBinding {
  static const String expectedFingerprint = '${this.hardwareFingerprint}';
  
  static Future<bool> verify() async {
    final hwFingerprint = await getHardwareFingerprint();
    
    if (hwFingerprint != expectedFingerprint) {
      throw Exception('Hardware binding verification failed');
    }
    
    return true;
  }
  
  static Future<String> getHardwareFingerprint() async {
    // Platform-specific hardware fingerprinting would go here
    return 'dart_hardware_fingerprint';
  }
}

// Verify hardware binding
HardwareBinding.verify();
`,
            kotlin: `
// Hardware binding verification
object HardwareBinding {
    private const val expectedFingerprint = "${this.hardwareFingerprint}"
    
    fun verify(): Boolean {
        val hwFingerprint = getHardwareFingerprint()
        
        if (hwFingerprint != expectedFingerprint) {
            throw RuntimeException("Hardware binding verification failed")
        }
        
        return true
    }
    
    private fun getHardwareFingerprint(): String {
        // Platform-specific hardware fingerprinting would go here
        return "kotlin_hardware_fingerprint"
    }
}

// Verify hardware binding
HardwareBinding.verify()
`
        };
        
        return bindingTemplates[language] || bindingTemplates.javascript;
    }

    generateVerificationCode(language) {
        const verificationTemplates = {
            javascript: `
// Continuous hardware verification
setInterval(() => {
    _hwBinding.verify().catch(() => {
        process.exit(1);
    });
}, 30000); // Check every 30 seconds
`,
            php: `
// Continuous hardware verification
register_tick_function(function() {
    static $lastCheck = 0;
    if (time() - $lastCheck > 30) {
        HardwareBinding::verify();
        $lastCheck = time();
    }
});
`,
            dart: `
// Continuous hardware verification
Timer.periodic(Duration(seconds: 30), (timer) {
  HardwareBinding.verify();
});
`,
            kotlin: `
// Continuous hardware verification
Timer().scheduleAtFixedRate(object : TimerTask() {
    override fun run() {
        HardwareBinding.verify()
    }
}, 0, 30000)
`
        };
        
        return verificationTemplates[language] || verificationTemplates.javascript;
    }

    injectBindingCode(code, bindingCode, verificationCode, language) {
        const lines = code.split('\n');
        
        // Inject binding code at the beginning
        lines.splice(1, 0, bindingCode);
        
        // Inject verification code at random positions
        const verificationPoints = this.calculateVerificationPoints(lines.length);
        verificationPoints.forEach((point, index) => {
            lines.splice(point + index, 0, verificationCode);
        });
        
        return lines.join('\n');
    }

    calculateVerificationPoints(totalLines) {
        const points = [];
        const verificationCount = Math.min(5, Math.floor(totalLines / 20));
        
        for (let i = 0; i < verificationCount; i++) {
            const point = Math.floor((totalLines / verificationCount) * i) + Math.floor(totalLines * 0.1);
            points.push(point);
        }
        
        return points;
    }

    addAntiVMDetection(code, language) {
        const antiVMCode = this.generateAntiVMCode(language);
        return this.injectAntiVMCode(code, antiVMCode, language);
    }

    generateAntiVMCode(language) {
        const antiVMTemplates = {
            javascript: `
// Anti-VM detection
const _antiVM = {
    detect: function() {
        // Check for VM indicators
        const vmIndicators = [
            'VMware', 'VirtualBox', 'QEMU', 'Xen', 'Hyper-V',
            'Parallels', 'Virtual', 'vbox', 'vmware'
        ];
        
        const userAgent = typeof navigator !== 'undefined' ? navigator.userAgent : '';
        const platform = typeof navigator !== 'undefined' ? navigator.platform : '';
        
        for (const indicator of vmIndicators) {
            if (userAgent.includes(indicator) || platform.includes(indicator)) {
                return true;
            }
        }
        
        // Check for VM-specific hardware
        if (typeof navigator !== 'undefined' && navigator.hardwareConcurrency < 2) {
            return true;
        }
        
        return false;
    }
};

if (_antiVM.detect()) {
    throw new Error('Virtual machine detected');
}
`,
            php: `
<?php
// Anti-VM detection
class AntiVM {
    public static function detect() {
        $vmIndicators = array(
            'VMware', 'VirtualBox', 'QEMU', 'Xen', 'Hyper-V',
            'Parallels', 'Virtual', 'vbox', 'vmware'
        );
        
        $userAgent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';
        
        foreach ($vmIndicators as $indicator) {
            if (stripos($userAgent, $indicator) !== false) {
                return true;
            }
        }
        
        // Check system information
        $systemInfo = php_uname('a');
        foreach ($vmIndicators as $indicator) {
            if (stripos($systemInfo, $indicator) !== false) {
                return true;
            }
        }
        
        return false;
    }
}

if (AntiVM::detect()) {
    die('Virtual machine detected');
}
?>
`
        };
        
        return antiVMTemplates[language] || antiVMTemplates.javascript;
    }

    injectAntiVMCode(code, antiVMCode, language) {
        const lines = code.split('\n');
        
        // Inject anti-VM code at the beginning
        lines.splice(2, 0, antiVMCode);
        
        return lines.join('\n');
    }

    addTimingChecks(code, language) {
        const timingCode = this.generateTimingCode(language);
        return this.injectTimingCode(code, timingCode, language);
    }

    generateTimingCode(language) {
        const timingTemplates = {
            javascript: `
// Timing-based anti-debugging
const _timingCheck = {
    start: Date.now(),
    check: function() {
        const now = Date.now();
        const elapsed = now - this.start;
        
        // If execution is too slow, likely being debugged
        if (elapsed > 1000) {
            throw new Error('Debugging detected');
        }
        
        this.start = now;
    }
};

setInterval(() => _timingCheck.check(), 100);
`,
            php: `
<?php
// Timing-based anti-debugging
class TimingCheck {
    private static $start;
    
    public static function init() {
        self::$start = microtime(true);
    }
    
    public static function check() {
        $now = microtime(true);
        $elapsed = ($now - self::$start) * 1000;
        
        if ($elapsed > 1000) {
            die('Debugging detected');
        }
        
        self::$start = $now;
    }
}

TimingCheck::init();
?>
`
        };
        
        return timingTemplates[language] || timingTemplates.javascript;
    }

    injectTimingCode(code, timingCode, language) {
        const lines = code.split('\n');
        
        // Inject timing code at the beginning
        lines.splice(3, 0, timingCode);
        
        // Add timing checks at random positions
        const checkPoints = this.calculateTimingCheckPoints(lines.length);
        checkPoints.forEach((point, index) => {
            const checkCall = language === 'javascript' ? '_timingCheck.check();' : 'TimingCheck::check();';
            lines.splice(point + index, 0, checkCall);
        });
        
        return lines.join('\n');
    }

    calculateTimingCheckPoints(totalLines) {
        const points = [];
        const checkCount = Math.min(10, Math.floor(totalLines / 10));
        
        for (let i = 0; i < checkCount; i++) {
            const point = Math.floor((totalLines / checkCount) * i) + Math.floor(totalLines * 0.05);
            points.push(point);
        }
        
        return points;
    }

    verifyHardwareBinding(currentFingerprint) {
        if (!this.hardwareFingerprint) {
            return false;
        }
        
        // Allow for small deviations in hardware fingerprint
        const similarity = this.calculateSimilarity(this.hardwareFingerprint, currentFingerprint);
        return similarity >= (1 - this.options.allowedDeviation);
    }

    calculateSimilarity(fingerprint1, fingerprint2) {
        if (fingerprint1 === fingerprint2) {
            return 1.0;
        }
        
        // Calculate Hamming distance for similarity
        let matches = 0;
        const length = Math.min(fingerprint1.length, fingerprint2.length);
        
        for (let i = 0; i < length; i++) {
            if (fingerprint1[i] === fingerprint2[i]) {
                matches++;
            }
        }
        
        return matches / length;
    }
}

module.exports = HardwareBindingEngine;