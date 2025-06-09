<?php
class TestClass {
    private $message = "Hello PHP";
    
    public function displayMessage() {
        echo $this->message;
    }
}

$test = new TestClass();
$test->displayMessage();