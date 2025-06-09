class TestClass {
  constructor() {
    this.message = "Hello JavaScript";
  }
  
  displayMessage() {
    console.log(this.message);
  }
}

const test = new TestClass();
test.displayMessage();