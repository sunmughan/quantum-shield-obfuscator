class TestClass {
    private val message = "Hello Kotlin"
    
    fun displayMessage() {
        println(message)
    }
}

fun main() {
    val test = TestClass()
    test.displayMessage()
}