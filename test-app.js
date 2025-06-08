// Test Application - Simple Calculator with Sensitive Data
class SecureCalculator {
    constructor() {
        this.apiKey = 'sk-1234567890abcdef-secret-key';
        this.dbPassword = 'super_secret_database_password_123';
        this.encryptionKey = 'aes-256-encryption-key-here';
        this.adminCredentials = {
            username: 'admin',
            password: 'admin_secret_pass_2024'
        };
        this.history = [];
    }

    authenticate(username, password) {
        if (username === this.adminCredentials.username && 
            password === this.adminCredentials.password) {
            console.log('🔓 Authentication successful!');
            return {
                success: true,
                token: this.generateToken(),
                apiKey: this.apiKey
            };
        }
        console.log('❌ Authentication failed!');
        return { success: false };
    }

    generateToken() {
        const timestamp = Date.now();
        const random = Math.random().toString(36).substr(2, 9);
        return `token_${timestamp}_${random}`;
    }

    add(a, b) {
        const result = a + b;
        this.history.push(`${a} + ${b} = ${result}`);
        console.log(`➕ ${a} + ${b} = ${result}`);
        return result;
    }

    multiply(a, b) {
        const result = a * b;
        this.history.push(`${a} × ${b} = ${result}`);
        console.log(`✖️ ${a} × ${b} = ${result}`);
        return result;
    }

    divide(a, b) {
        if (b === 0) {
            console.log('❌ Cannot divide by zero!');
            return null;
        }
        const result = a / b;
        this.history.push(`${a} ÷ ${b} = ${result}`);
        console.log(`➗ ${a} ÷ ${b} = ${result}`);
        return result;
    }

    getSecretData() {
        return {
            apiKey: this.apiKey,
            dbPassword: this.dbPassword,
            encryptionKey: this.encryptionKey
        };
    }

    processPayment(amount, cardNumber) {
        console.log(`💳 Processing payment of $${amount}`);
        const maskedCard = this.maskCardNumber(cardNumber);
        console.log(`Card: ${maskedCard}`);
        
        // Simulate payment processing with secret key
        const transactionId = this.encryptionKey.substr(0, 8) + Math.random().toString(36).substr(2, 8);
        
        return {
            success: true,
            transactionId: transactionId,
            amount: amount,
            timestamp: new Date().toISOString()
        };
    }

    maskCardNumber(cardNumber) {
        return cardNumber.replace(/.(?=.{4})/g, '*');
    }

    getHistory() {
        return this.history;
    }

    connectToDatabase() {
        console.log('🔗 Connecting to database...');
        console.log(`Using password: ${this.dbPassword}`);
        return 'Connected successfully';
    }
}

// Demo usage
console.log('🚀 Starting Secure Calculator Demo');
console.log('=====================================');

const calc = new SecureCalculator();

// Test authentication
console.log('\n🔐 Testing Authentication:');
const auth1 = calc.authenticate('admin', 'admin_secret_pass_2024');
if (auth1.success) {
    console.log('✅ Login successful!');
    console.log('🔑 Received API Key:', auth1.apiKey);
} else {
    console.log('❌ Login failed!');
}

// Test wrong credentials
const auth2 = calc.authenticate('hacker', 'wrong_password');

// Perform calculations
console.log('\n🧮 Testing Calculations:');
calc.add(15, 25);
calc.multiply(7, 8);
calc.divide(100, 4);
calc.divide(10, 0); // Test error handling

// Show calculation history
console.log('\n📊 Calculation History:');
const history = calc.getHistory();
history.forEach((entry, index) => {
    console.log(`${index + 1}. ${entry}`);
});

// Test payment processing
console.log('\n💰 Testing Payment Processing:');
const payment = calc.processPayment(99.99, '1234-5678-9012-3456');
console.log('Payment Result:', payment);

// Show sensitive data (this should be hidden after obfuscation)
console.log('\n🔒 Sensitive Data (should be hidden after obfuscation):');
const secrets = calc.getSecretData();
console.log('API Key:', secrets.apiKey);
console.log('DB Password:', secrets.dbPassword);
console.log('Encryption Key:', secrets.encryptionKey);

// Test database connection
console.log('\n🗄️ Testing Database Connection:');
const dbResult = calc.connectToDatabase();
console.log('Result:', dbResult);

console.log('\n✅ Demo completed successfully!');

// Export for testing
module.exports = SecureCalculator;