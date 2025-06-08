// Simple test application
function greetUser(name) {
    console.log('Hello, ' + name + '!');
    return 'Greeting sent to ' + name;
}

function calculateSum(a, b) {
    const result = a + b;
    console.log('Sum of ' + a + ' and ' + b + ' is: ' + result);
    return result;
}

function main() {
    const userName = 'TestUser';
    greetUser(userName);
    
    const num1 = 10;
    const num2 = 25;
    const sum = calculateSum(num1, num2);
    
    console.log('Application completed successfully!');
    console.log('Final result: ' + sum);
}

// Execute main function
main();