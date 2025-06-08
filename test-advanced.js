// Advanced test application for obfuscation
const secretKey = 'MySecretPassword123';
const importantData = {
    userCredentials: 'admin:password',
    apiKey: 'sk-1234567890abcdef',
    databaseUrl: 'mongodb://localhost:27017/myapp'
};

function processSecretData() {
    console.log('Processing sensitive information...');
    const encrypted = btoa(JSON.stringify(importantData));
    console.log('Data processed securely');
    return encrypted;
}

function authenticateUser(username, password) {
    if (username === 'admin' && password === secretKey) {
        console.log('Authentication successful!');
        return true;
    }
    console.log('Authentication failed!');
    return false;
}

function main() {
    console.log('Starting advanced application...');
    
    if (authenticateUser('admin', secretKey)) {
        const result = processSecretData();
        console.log('Application completed with result length:', result.length);
    } else {
        console.log('Access denied!');
    }
}

main();