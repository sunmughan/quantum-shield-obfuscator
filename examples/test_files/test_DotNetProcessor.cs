using System;

class TestClass {
    private string message = "Hello C#";
    
    public void DisplayMessage() {
        Console.WriteLine(message);
    }
    
    static void Main() {
        TestClass test = new TestClass();
        test.DisplayMessage();
    }
}