#include <iostream>
#include <string>

class TestClass {
public:
    void displayMessage() {
        std::string msg = "Hello C++";
        std::cout << msg << std::endl;
    }
};

int main() {
    TestClass test;
    test.displayMessage();
    return 0;
}