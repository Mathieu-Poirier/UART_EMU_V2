#include "device.hpp"

constexpr double time_step = 0.0001;

uint8_t read_rx_buf(UART_DEVICE &dev) {
  uint8_t read_value = 0x00;
  if (dev.rx_buf.pop(read_value)) {
    return read_value;
  } else {
    return 1;
  }
}

bool push_tx_buf(UART_DEVICE &dev, uint8_t value) {
  if (dev.tx_buf.push(value)) {
    return 0;
  } else {
    return 1;
  }
}

bool send_bit(UART_DEVICE &dev, const uint8_t value) {
  if (dev.tx_serial_connection != nullptr && dev.tx_serial_connection->push(value)) {
    return true;
  } else {
    return false;
  }
}

void serial_connection(UART_DEVICE &dev, UART_DEVICE &other) {
  dev.tx_serial_connection = &other.rx_buf;
  other.tx_serial_connection = &dev.rx_buf;
  // Simulate direct wiring
}

void tick_down(UART_DEVICE &dev) { dev.clock -= time_step; }

void reset_clock(UART_DEVICE &dev) { dev.clock = dev.time_per_byte; }

bool is_ready(UART_DEVICE &dev) {
  if (dev.clock <= 0.0) {
    return true;
  }
  else {
    return false;
  }
}