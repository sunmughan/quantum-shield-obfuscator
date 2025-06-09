import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';

interface ProcessingOptions {
  key?: string;
  [key: string]: any;
}

class IonicProcessor {
  private options: { [key: string]: string };
  private identifierMap: Map<string, string>;
  private stringMap: Map<string, string>;
  private encryptedStrings: string[];
  private reservedKeywords: Set<string>;
  private stdClasses: Set<string>;
  private ionicComponents: Set<string>;
  private angularDecorators: Set<string>;

  constructor(options: { [key: string]: string } = {}) {
    this.options = { ...options };
    this.identifierMap = new Map();
    this.stringMap = new Map();
    this.encryptedStrings = [];

    if (!this.options.encryptionKey) {
      this.options.encryptionKey = 'default_encryption_key_32_chars_';
    }

    // TypeScript/JavaScript reserved keywords
    this.reservedKeywords = new Set([
      'abstract', 'any', 'as', 'async', 'await', 'boolean', 'break', 'case',
      'catch', 'class', 'const', 'constructor', 'continue', 'debugger',
      'declare', 'default', 'delete', 'do', 'else', 'enum', 'export',
      'extends', 'false', 'finally', 'for', 'from', 'function', 'get',
      'if', 'implements', 'import', 'in', 'instanceof', 'interface',
      'is', 'keyof', 'let', 'module', 'namespace', 'never', 'new', 'null',
      'number', 'object', 'of', 'package', 'private', 'protected', 'public',
      'readonly', 'require', 'return', 'set', 'static', 'string', 'super',
      'switch', 'symbol', 'this', 'throw', 'true', 'try', 'type', 'typeof',
      'undefined', 'union', 'unique', 'unknown', 'var', 'void', 'while',
      'with', 'yield'
    ]);

    // Standard classes and global objects
    this.stdClasses = new Set([
      'Array', 'Object', 'String', 'Number', 'Boolean', 'Date', 'RegExp',
      'Error', 'Function', 'Promise', 'Map', 'Set', 'WeakMap', 'WeakSet',
      'Symbol', 'Proxy', 'Reflect', 'JSON', 'Math', 'console', 'window',
      'document', 'localStorage', 'sessionStorage', 'setTimeout', 'setInterval',
      'clearTimeout', 'clearInterval', 'fetch', 'XMLHttpRequest', 'FormData',
      'Blob', 'File', 'FileReader', 'URL', 'URLSearchParams', 'Headers',
      'Request', 'Response', 'WebSocket', 'EventSource', 'Worker',
      'ServiceWorker', 'Notification', 'Geolocation', 'Camera', 'Device'
    ]);

    // Ionic components and services
    this.ionicComponents = new Set([
      'IonApp', 'IonHeader', 'IonToolbar', 'IonTitle', 'IonContent', 'IonButton',
      'IonIcon', 'IonItem', 'IonLabel', 'IonList', 'IonCard', 'IonCardHeader',
      'IonCardTitle', 'IonCardContent', 'IonInput', 'IonTextarea', 'IonSelect',
      'IonSelectOption', 'IonCheckbox', 'IonRadio', 'IonRadioGroup', 'IonToggle',
      'IonRange', 'IonSearchbar', 'IonSegment', 'IonSegmentButton', 'IonTabs',
      'IonTabBar', 'IonTabButton', 'IonTab', 'IonMenu', 'IonMenuButton',
      'IonMenuToggle', 'IonSplitPane', 'IonNav', 'IonNavLink', 'IonPage',
      'IonRouterOutlet', 'IonBackButton', 'IonButtons', 'IonFab', 'IonFabButton',
      'IonFabList', 'IonGrid', 'IonRow', 'IonCol', 'IonInfiniteScroll',
      'IonInfiniteScrollContent', 'IonRefresher', 'IonRefresherContent',
      'IonReorder', 'IonReorderGroup', 'IonSlides', 'IonSlide', 'IonVirtualScroll',
      'IonActionSheet', 'IonAlert', 'IonLoading', 'IonModal', 'IonPopover',
      'IonToast', 'IonPicker', 'IonDatetime', 'IonAvatar', 'IonBadge',
      'IonChip', 'IonNote', 'IonRippleEffect', 'IonSkeletonText', 'IonSpinner',
      'IonThumbnail', 'Platform', 'NavController', 'AlertController',
      'ActionSheetController', 'LoadingController', 'ModalController',
      'PopoverController', 'ToastController', 'PickerController', 'MenuController',
      'Config', 'Events', 'Storage', 'Camera', 'Device', 'Geolocation',
      'Network', 'StatusBar', 'SplashScreen', 'Keyboard', 'File', 'FileTransfer',
      'InAppBrowser', 'SocialSharing', 'NativeStorage', 'SQLite', 'HTTP'
    ]);

    // Angular decorators and lifecycle hooks
    this.angularDecorators = new Set([
      'Component', 'Injectable', 'Directive', 'Pipe', 'NgModule', 'Input',
      'Output', 'ViewChild', 'ViewChildren', 'ContentChild', 'ContentChildren',
      'HostBinding', 'HostListener', 'Inject', 'Optional', 'Self', 'SkipSelf',
      'Host', 'OnInit', 'OnDestroy', 'OnChanges', 'DoCheck', 'AfterContentInit',
      'AfterContentChecked', 'AfterViewInit', 'AfterViewChecked', 'ngOnInit',
      'ngOnDestroy', 'ngOnChanges', 'ngDoCheck', 'ngAfterContentInit',
      'ngAfterContentChecked', 'ngAfterViewInit', 'ngAfterViewChecked',
      'ionViewDidLoad', 'ionViewWillEnter', 'ionViewDidEnter', 'ionViewWillLeave',
      'ionViewDidLeave', 'ionViewWillUnload', 'ionViewCanEnter', 'ionViewCanLeave'
    ]);
  }

  private encryptString(plaintext: string, key: string): string {
    try {
      // Ensure key is 32 bytes
      const keyBuffer = Buffer.alloc(32);
      keyBuffer.write(key, 0, Math.min(key.length, 32), 'utf8');

      // Generate random IV
      const iv = crypto.randomBytes(16);

      // Create cipher with IV
      const cipher = crypto.createCipheriv('aes-256-cbc', keyBuffer, iv);
      cipher.setAutoPadding(true);

      // Encrypt
      let encrypted = cipher.update(plaintext, 'utf8', 'base64');
      encrypted += cipher.final('base64');

      // Combine IV and encrypted data
      const combined = Buffer.concat([iv, Buffer.from(encrypted, 'base64')]);

      return combined.toString('base64');
    } catch (error) {
      console.error('Encryption error:', error);
      return '';
    }
  }

  private generateObfuscatedName(): string {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const length = 8 + Math.floor(Math.random() * 8); // 8-15 characters

    let result = '';

    // First character must be a letter
    result += charset[Math.floor(Math.random() * charset.length)];

    // Remaining characters can be letters or numbers
    const fullCharset = charset + '0123456789';
    for (let i = 1; i < length; i++) {
      result += fullCharset[Math.floor(Math.random() * fullCharset.length)];
    }

    return result;
  }

  private isReservedIdentifier(identifier: string): boolean {
    return this.reservedKeywords.has(identifier) ||
           this.stdClasses.has(identifier) ||
           this.ionicComponents.has(identifier) ||
           this.angularDecorators.has(identifier);
  }

  private encryptStrings(code: string, key: string): string {
    let result = '';

    // Add decryption utility
    const decryptUtility = `
// String decryption utility
import * as crypto from 'crypto';

class StringDecryptor {
  static decrypt(encrypted: string, key: string): string {
    try {
      const keyBuffer = Buffer.alloc(32);
      keyBuffer.write(key, 0, Math.min(key.length, 32), 'utf8');
      
      const combined = Buffer.from(encrypted, 'base64');
      if (combined.length < 16) return '';
      
      const iv = combined.slice(0, 16);
      const encryptedData = combined.slice(16);
      
      const decipher = crypto.createDecipheriv('aes-256-cbc', keyBuffer, iv);
      let decrypted = decipher.update(encryptedData, null, 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      return '';
    }
  }
}

`;

    result += decryptUtility;

    // Find and encrypt string literals (both single and double quotes)
    const stringPattern = /(['"`])(?:(?!\1)[^\\\r\n]|\\.|\r?\n)*?\1/g;
    let match;
    let lastIndex = 0;
    let stringIndex = 0;

    while ((match = stringPattern.exec(code)) !== null) {
      // Add code before the string
      result += code.substring(lastIndex, match.index);

      const originalString = match[0];
      const quote = match[1];
      const content = originalString.slice(1, -1); // Remove quotes

      // Skip template literals for now (complex to handle)
      if (quote === '`') {
        result += originalString;
      } else {
        const encrypted = this.encryptString(content, key);
        if (encrypted) {
          const varName = `_str_${stringIndex++}`;

          this.encryptedStrings.push(
            `const ${varName} = StringDecryptor.decrypt('${encrypted}', '${key}');`
          );

          result += varName;
        } else {
          result += originalString;
        }
      }

      lastIndex = stringPattern.lastIndex;
    }

    // Add remaining code
    result += code.substring(lastIndex);

    // Add string declarations at the beginning
    const finalResult = this.encryptedStrings.join('\n') + '\n' + result;
    return finalResult;
  }

  private obfuscateIdentifiers(code: string): string {
    // Find all identifiers
    const identifierPattern = /\b[a-zA-Z_$][a-zA-Z0-9_$]*\b/g;
    const identifiersToObfuscate = new Set<string>();

    let match;
    while ((match = identifierPattern.exec(code)) !== null) {
      const identifier = match[0];
      if (!this.isReservedIdentifier(identifier) && identifier.length > 1) {
        identifiersToObfuscate.add(identifier);
      }
    }

    // Generate obfuscated names
    Array.from(identifiersToObfuscate).forEach(identifier => {
      if (!this.identifierMap.has(identifier)) {
        this.identifierMap.set(identifier, this.generateObfuscatedName());
      }
    });

    // Replace identifiers
    let result = code;
    Array.from(this.identifierMap.entries()).forEach(([original, obfuscated]) => {
      const regex = new RegExp(`\\b${original.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'g');
      result = result.replace(regex, obfuscated);
    });

    return result;
  }

  private addControlFlowObfuscation(code: string): string {
    // Convert if-else to switch statements
    const ifPattern = /if\s*\(([^)]+)\)\s*\{([^}]+)\}(?:\s*else\s*\{([^}]+)\})?/g;
    
    return code.replace(ifPattern, (match, condition, ifBlock, elseBlock) => {
      const switchVar = `_sw${Math.floor(Math.random() * 10000)}`;
      let replacement = `let ${switchVar} = (${condition}) ? 1 : 0;\n`;
      replacement += `switch (${switchVar}) {\n`;
      replacement += `  case 1:\n    ${ifBlock}\n    break;\n`;
      
      if (elseBlock) {
        replacement += `  default:\n    ${elseBlock}\n    break;\n`;
      }
      
      replacement += '}';
      return replacement;
    });
  }

  private addDeadCode(code: string): string {
    const deadCodeSnippets = [
      'let _dummy1 = Math.floor(Math.random() * 100);\n',
      'let _dummy2 = Date.now() & 0xFF;\n',
      'if (_dummy1 > 200) { console.log("Never executed"); }\n',
      'for (let _i = 0; _i < 0; _i++) { _dummy2++; }\n',
      'let _dummy_array: any[] = [];\n',
      'const _dummy_obj = { prop: Math.random() };\n'
    ];

    let result = code;

    // Find function/method bodies and insert dead code
    const functionPattern = /(function\s+[^{]*\{|\([^)]*\)\s*=>\s*\{|\{)/g;
    const matches: RegExpExecArray[] = [];
    let match: RegExpExecArray | null;

    while ((match = functionPattern.exec(code)) !== null) {
      matches.push(match);
    }

    let insertions = 0;
    let offset = 0;

    for (const m of matches.slice(0, 3)) { // Limit to 3 insertions
      const pos = m.index + m[0].length + offset;
      const deadCode = deadCodeSnippets[Math.floor(Math.random() * deadCodeSnippets.length)];
      result = result.slice(0, pos) + '\n' + deadCode + result.slice(pos);
      offset += deadCode.length + 1;
      insertions++;
    }

    return result;
  }

  private addAntiDebugging(code: string): string {
    const antiDebugCode = `
// Anti-debugging measures for Ionic/Cordova apps
class AntiDebug {
  static check(): void {
    // Check for developer tools
    const devtools = {
      open: false,
      orientation: null as any
    };
    
    const threshold = 160;
    
    setInterval(() => {
      if (window.outerHeight - window.innerHeight > threshold || 
          window.outerWidth - window.innerWidth > threshold) {
        if (!devtools.open) {
          devtools.open = true;
          // Exit or redirect
          if (typeof navigator !== 'undefined' && (navigator as any).app) {
            (navigator as any).app.exitApp();
          } else {
            window.location.href = 'about:blank';
          }
        }
      } else {
        devtools.open = false;
      }
    }, 500);
    
    // Check for common debugging variables
    if (typeof window !== 'undefined') {
      if ((window as any).__CORDOVA_DEBUG__ || 
          (window as any).__IONIC_DEBUG__ ||
          (window as any).cordova?.platformId === 'browser') {
        if (typeof navigator !== 'undefined' && (navigator as any).app) {
          (navigator as any).app.exitApp();
        }
      }
    }
    
    // Timing check
    const start = performance.now();
    let dummy = 0;
    for (let i = 0; i < 1000; i++) {
      dummy += i;
    }
    const end = performance.now();
    
    if (end - start > 10) { // 10ms
      if (typeof navigator !== 'undefined' && (navigator as any).app) {
        (navigator as any).app.exitApp();
      }
    }
    
    // Check for emulator/simulator
    if (typeof device !== 'undefined') {
      if (device.isVirtual || 
          device.model.includes('Simulator') ||
          device.model.includes('Emulator') ||
          device.manufacturer === 'Genymotion') {
        if (typeof navigator !== 'undefined' && (navigator as any).app) {
          (navigator as any).app.exitApp();
        }
      }
    }
    
    // Check for root/jailbreak
    if (typeof window !== 'undefined' && (window as any).plugins) {
      const plugins = (window as any).plugins;
      if (plugins.jailbreakDetection) {
        plugins.jailbreakDetection.isJailbroken(
          () => {
            // Device is jailbroken/rooted
            if (typeof navigator !== 'undefined' && (navigator as any).app) {
              (navigator as any).app.exitApp();
            }
          },
          () => {
            // Device is not jailbroken/rooted
          }
        );
      }
    }
  }
}

`;

    let result = antiDebugCode + code;

    // Insert anti-debug call in platform ready or app initialization
    const platformReadyPattern = /(platform\.ready\(\)\s*\.then\s*\([^{]*\{)/;
    result = result.replace(platformReadyPattern, '$1\n    AntiDebug.check();');

    // Also insert in constructor or ngOnInit
    const constructorPattern = /(constructor\s*\([^)]*\)\s*\{)/;
    result = result.replace(constructorPattern, '$1\n    AntiDebug.check();');

    const ngOnInitPattern = /(ngOnInit\s*\(\s*\)\s*\{)/;
    result = result.replace(ngOnInitPattern, '$1\n    AntiDebug.check();');

    return result;
  }

  private addComponentObfuscation(code: string): string {
    // Obfuscate component selectors and template references
    const componentPattern = /@Component\s*\(\s*\{([^}]+)\}/g;
    
    return code.replace(componentPattern, (match: string, content: string) => {
      // Obfuscate selector
      const selectorPattern = /selector:\s*['"` ]([^'"` ]+)['"` ]/;
      content = content.replace(selectorPattern, (sMatch: string, selector: string) => {
        const obfuscatedSelector = `app-${this.generateObfuscatedName().toLowerCase()}`;
        return sMatch.replace(selector, obfuscatedSelector);
      });
      
      return `@Component({${content}})`;
    });
  }

  private addServiceObfuscation(code: string): string {
    // Obfuscate service names and injectable providers
    const servicePattern = /@Injectable\s*\(\s*\{([^}]*)\}\s*\)\s*export\s+class\s+([a-zA-Z_$][a-zA-Z0-9_$]*)/g;
    
    return code.replace(servicePattern, (match: string, config: string, className: string) => {
      if (!this.isReservedIdentifier(className)) {
        const obfuscatedName = `_S${this.generateObfuscatedName().substring(0, 8)}`;
        this.identifierMap.set(className, obfuscatedName);
        return match.replace(className, obfuscatedName);
      }
      return match;
    });
  }

  private addRouteObfuscation(code: string): string {
    // Obfuscate route paths
    const routePattern = /path:\s*['"`]([^'"` ]+)['"`]/g;
    
    return code.replace(routePattern, (match, path) => {
      if (path !== '' && path !== '**' && !path.startsWith(':')) {
        const obfuscatedPath = this.generateObfuscatedName().toLowerCase();
        return match.replace(path, obfuscatedPath);
      }
      return match;
    });
  }

  public process(code: string, processingOptions: ProcessingOptions = {}): string {
    const key = processingOptions.key || this.options.encryptionKey;
    
    let result = code;
    
    // Apply Ionic/Angular specific obfuscations
    result = this.encryptStrings(result, key);
    result = this.addComponentObfuscation(result);
    result = this.addServiceObfuscation(result);
    result = this.addRouteObfuscation(result);
    result = this.obfuscateIdentifiers(result);
    result = this.addControlFlowObfuscation(result);
    result = this.addDeadCode(result);
    result = this.addAntiDebugging(result);
    
    return result;
  }
}

// Export for use as module
export default IonicProcessor;

// Main function for command-line usage
if (typeof require !== 'undefined' && require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length < 1) {
    console.log('Usage: ts-node IonicProcessor.ts <input_file> [options]');
    process.exit(1);
  }
  
  try {
    // Read input file
    const inputPath = args[0];
    const code = fs.readFileSync(inputPath, 'utf8');
    
    // Initialize processor with options
    const options = {
      encryptionKey: 'default_encryption_key_32_chars_'
    };
    
    const processor = new IonicProcessor(options);
    
    // Process the code
    const obfuscated = processor.process(code);
    
    // Output result
    console.log(obfuscated);
    
  } catch (error) {
    console.error('Error processing file:', error);
    process.exit(1);
  }
}