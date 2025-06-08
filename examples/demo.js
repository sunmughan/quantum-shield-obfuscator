const AdvancedObfuscator = require('../core/obfuscator');
const fs = require('fs');

// Demo script showing obfuscation capabilities
const obfuscator = new AdvancedObfuscator({
    encryptionKey: 'your-secret-key-here',
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
fs.writeFileSync('./examples/output/demo.obf.js', jsResult.obfuscatedCode);
fs.writeFileSync('./examples/output/demo.js.meta', JSON.stringify(jsResult.metadata, null, 2));
console.log('✅ JavaScript obfuscated');

// Obfuscate PHP
console.log('📝 Obfuscating PHP...');
const phpResult = obfuscator.obfuscate(phpCode, 'php');
fs.writeFileSync('./examples/output/demo.obf.php', phpResult.obfuscatedCode);
fs.writeFileSync('./examples/output/demo.php.meta', JSON.stringify(phpResult.metadata, null, 2));
console.log('✅ PHP obfuscated');

// Obfuscate Dart
console.log('📝 Obfuscating Dart...');
const dartResult = obfuscator.obfuscate(dartCode, 'dart');
fs.writeFileSync('./examples/output/demo.obf.dart', dartResult.obfuscatedCode);
fs.writeFileSync('./examples/output/demo.dart.meta', JSON.stringify(dartResult.metadata, null, 2));
console.log('✅ Dart obfuscated');

console.log('\n🎉 Demo complete! Check the ./examples/output/ directory for results.');
console.log('\n📊 Obfuscation Statistics:');
console.log(`JavaScript: ${jsResult.metadata.steps.length} transformation steps`);
console.log(`PHP: ${phpResult.metadata.steps.length} transformation steps`);
console.log(`Dart: ${dartResult.metadata.steps.length} transformation steps`);