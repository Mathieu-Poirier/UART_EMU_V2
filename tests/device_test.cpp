#include <cstdint>
#include <iostream>
#include <cstdlib>
#include <string>
#include <memory>
#include <bitset>

#include "../src/device.hpp"

constexpr uint8_t start_bit = 0x00; // low line
constexpr uint8_t stop_bit = 0x01; // high line

constexpr uint32_t discrete_time_step = 1;

static void load_bit_array_tx(UART_DEVICE &dev, const uint8_t *bit_arr, uint32_t size) {
  for (uint32_t binary_iterator = 0; binary_iterator < size; binary_iterator++) {
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

static std::unique_ptr<uint8_t[]> string_to_bits(std::string str_in) { // Allocates memory
  uint32_t bit_arr_size = str_in.size() * 8;
  std::unique_ptr<uint8_t[]> bit_arr_ptr =
      std::make_unique<uint8_t[]>(bit_arr_size);
  uint32_t arr_idx = 0;

  for (uint8_t character : str_in) {
    for (int i = 7; i >= 0; --i) {
        uint8_t bit = (character >> i) & 0b00000001;
        bit_arr_ptr[arr_idx] = bit;
        arr_idx++;
    }
  }
  // Caller must remember size
  return bit_arr_ptr;
}

bool multi_byte_transmission(UART_DEVICE &dev, UART_DEVICE &other) {
  int simulation_time = 100000;
  bool test_passed = true;

  std::string send_string("Hello World");
  std::unique_ptr<uint8_t[]> bit_arr = string_to_bits(send_string);

  load_bit_array_tx(dev, bit_arr.get(), send_string.size() * 8);
  uint32_t sent = 0;
  uint8_t reconstructed_arr[11] = {};
  uint8_t reconstructed_arr_two[11] = {};

  // for (int i = 0; i < send_string.size() * 8; i++) {
  //   uint8_t tmp = 0;
  //   dev.tx_buf.pop(tmp);
  //   std::cout << static_cast<unsigned int>(tmp) << std::endl;
  // }

  while (simulation_time > 0 && sent != 11) {
    // Main loop here
    if (is_ready(dev)) {
      reset_clock(dev);
      transition_uart_state(dev);

      //
      handle_transmit(dev);

    }
    if (is_ready(other)) {
      reset_clock(other);
      transition_uart_state(other);

      handle_transmit(other);
      handle_receive(other, reconstructed_arr[sent]);
      sent++;
    }


    tick_down(dev);
    tick_down(other);
    simulation_time -= discrete_time_step;
  }

  for (int i = 0; i < 11; i++) {
    // std::cout << static_cast<unsigned int>(reconstructed_arr[i]) << std::endl;
    std::cout << static_cast<unsigned char>(reconstructed_arr[i]) << std::endl;
    std::cout << send_string.at(i) << std::endl;

    if (static_cast<unsigned char>(reconstructed_arr[i]) != send_string.at(i))
      test_passed = false;
  }

  return test_passed;
}

int main() {

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

  if (multi_byte_transmission(uart_one, uart_two)) {
    std::cout << "OK: Multi-Byte Transmission." << std::endl;
  } else {
    std::cout << "Err: Multi-Byte Transmission." << std::endl;
  }
  
  return EXIT_SUCCESS;
}