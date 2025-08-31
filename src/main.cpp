#include "device.hpp"
#include <array>
#include <cstdint>
#include <stdint.h>

// Since it's async each device needs a clock object when rx sees low it means
// it starts reiceiving data then checks if there is a stop bit then waits for
// low
constexpr uint8_t start_bit = 0x00; // low line
constexpr uint8_t stop_bit = 0x01; // high line

constexpr uint32_t discrete_time_step = 1;

static void load_bit_array_tx(UART_DEVICE &dev, uint8_t *bit_arr) {
  uint32_t data_size = dev.config.data_bits;
  for (uint32_t binary_iterator = 0; binary_iterator < data_size; binary_iterator++) {
   dev.tx_buf.push(bit_arr[binary_iterator]);
  }
}

static void transition_uart_state(UART_DEVICE &dev) {
    // This function updates the UART device state based on its buffer status.
    if (!dev.rx_buf.is_empty()) { // Receiving
        if (dev.state == DeviceState::TRANSMITTING) {
            dev.state = DeviceState::RECEIVING_AND_TRANSMITTING;
        } else {
            dev.state = DeviceState::RECEIVING;
        }
    }

    if (!dev.tx_buf.is_empty()) { // Transmitting
        if (dev.state == DeviceState::RECEIVING) {
            dev.state = DeviceState::RECEIVING_AND_TRANSMITTING;
        } else {
            dev.state = DeviceState::TRANSMITTING;
        }
    }
}

static void handle_receive(UART_DEVICE &dev, uint8_t &reconstructed_character) {
  if (dev.state == DeviceState::RECEIVING || dev.state == DeviceState::RECEIVING_AND_TRANSMITTING) {
    // Reset for new frame
    reconstructed_character = 0x00;
    
    // Need to parse one message from rx_buf
    uint8_t message_start;
    uint8_t message_end;

    dev.rx_buf.peek(message_start);

    if (message_start == start_bit) {
      uint8_t message_start_value;
      uint8_t message_data_value;
    
      dev.rx_buf.pop(message_start_value);
    
      for (uint32_t data_bits_idx = 0; data_bits_idx < dev.config.data_bits; data_bits_idx++) {
        dev.rx_buf.pop(message_data_value);
    
        reconstructed_character = reconstructed_character << 1;
        reconstructed_character |= message_data_value;
      }
      
      // Move stop bit logic inside the start bit check
      dev.rx_buf.peek(message_end);
      if (message_end == stop_bit) {
        dev.rx_buf.pop(message_end);
        dev.state = DeviceState::IDLE;
      } else {
        // Bad frame
        dev.rx_buf.reset();
        dev.state = DeviceState::IDLE;
      }
    } else {
      // Invalid start bit - skip this frame
      dev.rx_buf.reset();
      dev.state = DeviceState::IDLE;
    }
  }
}

static void handle_transmit(UART_DEVICE &dev) {
  if (dev.state == DeviceState::TRANSMITTING || dev.state == DeviceState::RECEIVING_AND_TRANSMITTING) {
    send_bit(dev, start_bit);
    uint8_t send_value;

    for (uint32_t data_bits_idx = 0; data_bits_idx < dev.config.data_bits; data_bits_idx++) {
      dev.tx_buf.pop(send_value);
      send_bit(dev, send_value);
    }
    send_bit(dev, stop_bit);

    dev.state = DeviceState::IDLE;
  }
}

extern "C" int main() {
  constexpr UART_CONFIG default_config = {.baud_rate = 9600,
                        .data_bits = 8,
                        .stop_bits = 1,
                        .start_bits = 1, };

  UART_DEVICE uart_one = {.state = DeviceState::IDLE, .config = default_config};
  UART_DEVICE uart_two = {.state = DeviceState::IDLE, .config = default_config};
  
  // Calculate timing after config is set
  uart_one.calculate_timing();
  uart_two.calculate_timing();
  
  serial_connection(uart_one, uart_two);

  uint32_t simulation_time = 100000;

  // This should be a data register
  uint8_t reconstructed_character = 0x00;
  uint8_t reconstructed_character_two = 0x00;

  // Need to make helper functions for readability
  while (simulation_time > 0) {
    // Main loop here
    if (is_ready(uart_one)) {
      reset_clock(uart_one);
      transition_uart_state(uart_one);

      handle_transmit(uart_one);
      handle_receive(uart_one, reconstructed_character);
    }
    if (is_ready(uart_two)) {
      reset_clock(uart_two);
      transition_uart_state(uart_two);

      handle_transmit(uart_two);
      handle_receive(uart_two, reconstructed_character_two);
    }

    tick_down(uart_one);
    tick_down(uart_two);
    simulation_time -= discrete_time_step;
  }
    return 0;
}
    