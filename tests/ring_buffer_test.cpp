#include <cstdint>
#include <iostream>
#include <cassert>
#include <cstdlib>

#include "../src/ring_buffer.hpp"

bool test_ring_buffer_operations() {
    ring_buffer<uint8_t, 4> buf;
    
    assert(buf.is_empty());
    assert(!buf.is_full());
    
    assert(buf.push(1));
    assert(buf.push(2));
    assert(buf.push(3));
    assert(buf.push(4));
    
    assert(buf.is_full());
    assert(!buf.push(5));
    
    uint8_t value;
    (void)value;
    assert(buf.pop(value) && value == 1);
    assert(buf.pop(value) && value == 2);
    assert(buf.pop(value) && value == 3);
    assert(buf.pop(value) && value == 4);
    
    assert(buf.is_empty());
    assert(!buf.pop(value));
    
    buf.push(10);
    uint8_t peek_value;
    (void)peek_value;
    assert(buf.peek(peek_value) && peek_value == 10);
    assert(buf.pop(value) && value == 10);
    
    buf.push(20);
    buf.push(30);
    buf.reset();
    assert(buf.is_empty());
    
    return true;
}

bool test_ring_buffer_wraparound() {
    ring_buffer<uint8_t, 4> buf;
    
    assert(buf.push(1));
    assert(buf.push(2));
    assert(buf.push(3));
    assert(buf.push(4));
    
    uint8_t value;
    (void)value;
    assert(buf.pop(value) && value == 1);
    
    assert(buf.push(5));
    
    assert(buf.pop(value) && value == 2);
    assert(buf.pop(value) && value == 3);
    assert(buf.pop(value) && value == 4);
    assert(buf.pop(value) && value == 5);
    assert(buf.is_empty());
    
    return true;
}

bool test_ring_buffer_different_types() {
    ring_buffer<int, 4> int_buf;
    assert(int_buf.push(100));
    assert(int_buf.push(200));
    assert(int_buf.push(300));
    
    int int_value;
    (void)int_value;
    assert(int_buf.pop(int_value) && int_value == 100);
    assert(int_buf.pop(int_value) && int_value == 200);
    assert(int_buf.pop(int_value) && int_value == 300);
    
    ring_buffer<char, 2> char_buf;
    assert(char_buf.push('A'));
    assert(char_buf.push('B'));
    
    char char_value;
    (void)char_value;
    assert(char_buf.pop(char_value) && char_value == 'A');
    assert(char_buf.pop(char_value) && char_value == 'B');

    return true;
}

bool test_ring_buffer_edge_cases() {
    ring_buffer<uint8_t, 1> single_buf;
    
    assert(single_buf.is_empty());
    assert(!single_buf.is_full());
    
    assert(single_buf.push(42));
    assert(single_buf.is_full());
    assert(!single_buf.is_empty());
    
    uint8_t value;
    (void)value;
    assert(single_buf.pop(value) && value == 42);
    assert(single_buf.is_empty());
    assert(!single_buf.is_full());
    
    return true;
}

int main() {
    if (test_ring_buffer_operations()) {
        std::cout << "Good: Ring Buffer Operations" << std::endl;
    }
    
    if (test_ring_buffer_wraparound()) {
        std::cout << "Good: Ring Buffer Wraparound" << std::endl;
    }
    
    if (test_ring_buffer_different_types()) {
        std::cout << "Good: Ring Buffer Different Types" << std::endl;
    }
    
    if (test_ring_buffer_edge_cases()) {
        std::cout << "Good: Ring Buffer Edge Cases" << std::endl;
    }

    return EXIT_SUCCESS;
}