#pragma once
#include <stdint.h>
#include "ring_buffer.hpp"

constexpr uint32_t buf_capacity = 64;

enum class DeviceState : uint8_t {
  IDLE,
  TRANSMITTING,
  RECEIVING,
  RECEIVING_AND_TRANSMITTING,
};

// enum class Endianness : uint8_t {
//   BIG,
//   LITTLE,
// };
// // Need to think about size of registers
// enum class Registers : uint32_t {
//   D0,
//   D1,
//   D2,
//   D3,
//   D4,
//   D5,
//   D6,
//   D7,
// };

struct UART_CONFIG {
    uint32_t baud_rate;
    uint32_t data_bits;
    uint32_t stop_bits;
    uint32_t start_bits;
    double time_step = 0.001;
};

// Maybe let's treat each byte as a single bit of info? Send only

struct UART_DEVICE {
  DeviceState state = DeviceState::IDLE;

  ring_buffer<uint8_t,64> tx_buf = {};
  ring_buffer<uint8_t,64> rx_buf = {};
  ring_buffer<uint8_t,64>* tx_serial_connection = nullptr;
  uint32_t registers[8] = {};
  UART_CONFIG config;
  uint32_t bits_per_frame = 0;  // Initialize to 0
  double time_per_byte = 0.0;   // Initialize to 0
  double clock = 0.0;           // Initialize to 0

  // Add a function to calculate these values
  void calculate_timing() {
    bits_per_frame = config.start_bits + config.data_bits+ config.stop_bits;
    time_per_byte = (double)bits_per_frame / (double)config.baud_rate;
    clock = time_per_byte;
  }
};

uint8_t read_rx_buf(UART_DEVICE &dev); // when it receives a 0 we start counting
                                       // then back to IDLE , if the line isn't
                                       // high after count the invalid frame
// If frame invalid discard and reset
bool push_tx_buf(UART_DEVICE &dev, const uint8_t value);
bool send_bit(UART_DEVICE &dev, const uint8_t value);
void serial_connection(UART_DEVICE &dev, UART_DEVICE &other);
void tick_down(UART_DEVICE &dev);
void reset_clock(UART_DEVICE &dev);
bool is_ready(UART_DEVICE &dev);