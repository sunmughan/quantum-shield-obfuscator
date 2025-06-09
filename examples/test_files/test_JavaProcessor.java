public class test_JavaProcessor {
    private String message = "Hello Java";
    
    public void displayMessage() {
        System.out.println(message);
    }
    
    public static void main(String[] args) {
        test_JavaProcessor test = new test_JavaProcessor();
        test.displayMessage();
    }
}