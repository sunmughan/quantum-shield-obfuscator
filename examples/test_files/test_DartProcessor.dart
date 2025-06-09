class TestClass {
  String message = "Hello Dart";
  
  void displayMessage() {
    print(message);
  }
}

void main() {
  TestClass test = TestClass();
  test.displayMessage();
}