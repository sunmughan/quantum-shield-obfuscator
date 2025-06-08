const AdvancedObfuscator = require('../core/obfuscator');

// Demo script showing obfuscation capabilities
// This example demonstrates how to use the Advanced Code Obfuscator
const obfuscator = new AdvancedObfuscator({
    encryptionKey: 'demo-encryption-key-change-in-production',
    iterations: 150000
});

// JavaScript example
const jsCode = `
function calculateTotal(items) {
    let total = 0;
    for (let item of items) {
        total += item.price * item.quantity;
    }
    return total;
}

const cart = [
    { name: "Product A", price: 29.99, quantity: 2 },
    { name: "Product B", price: 15.50, quantity: 1 }
];

console.log("Total:", calculateTotal(cart));
`;

// PHP example
const phpCode = `
<?php
function calculateTotal($items) {
    $total = 0;
    foreach ($items as $item) {
        $total += $item['price'] * $item['quantity'];
    }
    return $total;
}

$cart = [
    ['name' => 'Product A', 'price' => 29.99, 'quantity' => 2],
    ['name' => 'Product B', 'price' => 15.50, 'quantity' => 1]
];

echo "Total: " . calculateTotal($cart);
?>
`;

// Dart example
const dartCode = `
class Product {
  String name;
  double price;
  int quantity;
  
  Product(this.name, this.price, this.quantity);
}

double calculateTotal(List<Product> items) {
  double total = 0;
  for (var item in items) {
    total += item.price * item.quantity;
  }
  return total;
}

void main() {
  var cart = [
    Product('Product A', 29.99, 2),
    Product('Product B', 15.50, 1)
  ];
  
  print('Total: ${calculateTotal(cart)}');
}
`;

console.log('🔐 Advanced Code Obfuscator Demo\n');

// Obfuscate JavaScript
console.log('📝 Obfuscating JavaScript...');
const jsResult = obfuscator.obfuscate(jsCode, 'javascript');
console.log('✅ JavaScript obfuscated');
console.log(`Original size: ${jsCode.length} characters`);
console.log(`Obfuscated size: ${jsResult.obfuscatedCode.length} characters`);
console.log(`Size increase: ${((jsResult.obfuscatedCode.length / jsCode.length) * 100).toFixed(1)}%\n`);

// Obfuscate PHP
console.log('📝 Obfuscating PHP...');
const phpResult = obfuscator.obfuscate(phpCode, 'php');
console.log('✅ PHP obfuscated');
console.log(`Original size: ${phpCode.length} characters`);
console.log(`Obfuscated size: ${phpResult.obfuscatedCode.length} characters`);
console.log(`Size increase: ${((phpResult.obfuscatedCode.length / phpCode.length) * 100).toFixed(1)}%\n`);

// Obfuscate Dart
console.log('📝 Obfuscating Dart...');
const dartResult = obfuscator.obfuscate(dartCode, 'dart');
console.log('✅ Dart obfuscated');
console.log(`Original size: ${dartCode.length} characters`);
console.log(`Obfuscated size: ${dartResult.obfuscatedCode.length} characters`);
console.log(`Size increase: ${((dartResult.obfuscatedCode.length / dartCode.length) * 100).toFixed(1)}%\n`);

console.log('🎉 Demo complete!');
console.log('\n📊 Obfuscation Statistics:');
console.log(`JavaScript: ${jsResult.metadata.steps.length} transformation steps`);
console.log(`PHP: ${phpResult.metadata.steps.length} transformation steps`);
console.log(`Dart: ${dartResult.metadata.steps.length} transformation steps`);

console.log('\n💡 Tip: Use the CLI tool for production obfuscation:');
console.log('node cli/obfuscate.js <input-file> [options]');