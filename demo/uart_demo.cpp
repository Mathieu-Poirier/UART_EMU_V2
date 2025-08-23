/**
 * UART Emulator Demo
 * A demonstration of the UART emulator functionality
 */

#include <iostream>
#include <cstdlib>
#include "../src/device.hpp"

int main(){

  constexpr UART_CONFIG default_config = {
      .baud_rate = 9600,
      .data_bits = 8,
      .stop_bits = 1,
      .start_bits = 1,
  };
  
  return EXIT_SUCCESS;
}

