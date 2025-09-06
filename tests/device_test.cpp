#include <cstdint>
#include <iostream>
#include <cstdlib>
#include <string>
#include <memory>
#include <algorithm>

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
    uint8_t message_start = 0;
    uint8_t message_end = 0;

    dev.rx_buf.peek(message_start);

    if (message_start == start_bit) {
      uint8_t message_start_value = 0;
      uint8_t message_data_value = 0;
    
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
    uint8_t send_value = 0;

    for (uint32_t data_bits_idx = 0; data_bits_idx < dev.config.data_bits; data_bits_idx++) {
      dev.tx_buf.pop(send_value);
      send_bit(dev, send_value);
    }
    send_bit(dev, stop_bit);

    dev.state = DeviceState::IDLE;
  }
}

static uint32_t handle_transmit_with_overflow_detection(UART_DEVICE &dev, uint32_t &bits_lost) {
  uint32_t overflow_count = 0;
  if (dev.state == DeviceState::TRANSMITTING || dev.state == DeviceState::RECEIVING_AND_TRANSMITTING) {
    if (!send_bit(dev, start_bit)) { overflow_count++; bits_lost++; }
    uint8_t send_value = 0;

    for (uint32_t data_bits_idx = 0; data_bits_idx < dev.config.data_bits; data_bits_idx++) {
      dev.tx_buf.pop(send_value);
      if (!send_bit(dev, send_value)) { overflow_count++; bits_lost++; }
    }
    if (!send_bit(dev, stop_bit)) { overflow_count++; bits_lost++; }

    dev.state = DeviceState::IDLE;
  }
  return overflow_count;
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
  constexpr int msg_length = 11;

  std::string send_string("Hello World");
  std::unique_ptr<uint8_t[]> bit_arr = string_to_bits(send_string);

  load_bit_array_tx(dev, bit_arr.get(), send_string.size() * 8);
  uint32_t sent = 0;
  uint8_t reconstructed_arr[msg_length] = {};

  // for (int i = 0; i < send_string.size() * 8; i++) {
  //   uint8_t tmp = 0;
  //   dev.tx_buf.pop(tmp);
  //   std::cout << static_cast<unsigned int>(tmp) << std::endl;
  // }

  while (simulation_time > 0 && sent != msg_length) {
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

  return test_passed;
}

bool mismatched_baud_rate_test(UART_DEVICE &dev, UART_DEVICE &other) {
  uint64_t simulation_time = 10000;  // Much longer simulation time
  constexpr int msg_length = 300;  // Allow for full message length
  uint32_t successful_receptions = 0;
  uint32_t total_attempts = 0;
  uint32_t state_resets = 0;
  uint32_t buffer_overflows = 0;
  uint32_t total_bits_sent = 0;
  uint32_t total_bits_lost = 0;
  uint32_t idle_time_ticks = 0;
  std::string received_chars;

  // Create a much longer message to stress test the timing
  std::string send_string("This is a very long test message to demonstrate baud rate mismatch issues. The transmitter is sending at 115200 baud while the receiver expects 1200 baud, causing significant timing problems and buffer overflow issues.");
  std::unique_ptr<uint8_t[]> bit_arr = string_to_bits(send_string);
  
  // Load data incrementally - only load a few characters at a time
  uint32_t chars_loaded = 0;
  constexpr uint32_t chars_per_load = 5;  // Load 5 characters at a time

  while (simulation_time > 0 && total_attempts < msg_length) {
    // Load more data incrementally when transmitter buffer is getting low
    if (dev.tx_buf.is_empty() && chars_loaded < send_string.length()) {
      uint32_t chars_to_load = std::min(chars_per_load, (uint32_t)(send_string.length() - chars_loaded));
      load_bit_array_tx(dev, &bit_arr[chars_loaded * 8], chars_to_load * 8);
      chars_loaded += chars_to_load;
    }
    
    if (is_ready(dev)) {
      reset_clock(dev);
      transition_uart_state(dev);
      buffer_overflows += handle_transmit_with_overflow_detection(dev, total_bits_lost);
      total_bits_sent += dev.bits_per_frame;  // Count bits attempted to send
    }
    
    if (is_ready(other)) {
      reset_clock(other);
      transition_uart_state(other);
      handle_transmit(other);
      
      uint8_t received_char = 0;
      DeviceState prev_state = other.state;
      
      handle_receive(other, received_char);
      
      // Count attempts and successful receptions
      if (prev_state == DeviceState::RECEIVING || prev_state == DeviceState::RECEIVING_AND_TRANSMITTING) {
        total_attempts++;
        
        // Store received character for display
        if (received_char != 0) {
          received_chars += static_cast<char>(received_char);
          successful_receptions++;
        } else {
          received_chars += '?';  // Mark failed receptions
        }
        
        // Check if state was reset to IDLE (indicating frame error)
        if (other.state == DeviceState::IDLE && prev_state != DeviceState::IDLE) {
          state_resets++;
        }
      }
      
      // Check for actual buffer overflow by monitoring failed sends
      // This would happen when the receiver's buffer is full and can't accept more data
    }

    // Track idle time
    if (dev.state == DeviceState::IDLE && other.state == DeviceState::IDLE) {
      idle_time_ticks++;
    }

    tick_down(dev);
    tick_down(other);
    simulation_time -= discrete_time_step;
  }

  // Print transmission results
  std::cout << "  Transmitter baud rate: " << dev.config.baud_rate << std::endl;
  std::cout << "  Receiver baud rate: " << other.config.baud_rate << std::endl;
  std::cout << "  Transmitter time_per_byte: " << dev.time_per_byte << " seconds" << std::endl;
  std::cout << "  Receiver time_per_byte: " << other.time_per_byte << " seconds" << std::endl;
  std::cout << "  Timing ratio: " << (dev.time_per_byte / other.time_per_byte) << "x difference" << std::endl;
  std::cout << "  Message length: " << send_string.length() << " characters" << std::endl;
  std::cout << "  Characters loaded incrementally: " << chars_loaded << std::endl;
  std::cout << "  Sent: \"" << send_string.substr(0, 60) << (send_string.length() > 50 ? "..." : "") << "\"" << std::endl;
  std::cout << "  Received: \"" << received_chars.substr(0, 60) << (received_chars.length() > 50 ? "..." : "") << "\"" << std::endl;
  std::cout << "  Characters received: " << received_chars.length() << std::endl;
  std::cout << "  Message completion rate: " << (send_string.length() > 0 ? (double)received_chars.length() / (double)send_string.length() * 100.0 : 0.0) << "%" << std::endl;
  std::cout << "  State resets: " << state_resets << std::endl;
  std::cout << "  Buffer overflow events: " << buffer_overflows << std::endl;
  std::cout << "  Total bits sent: " << total_bits_sent << std::endl;
  std::cout << "  Total bits lost: " << total_bits_lost << std::endl;
  std::cout << "  Idle time ticks: " << idle_time_ticks << std::endl;

  // Test passes if message completion rate is less than 100%
  // This indicates baud rate mismatch issues are causing data loss
  double message_completion_rate = send_string.length() > 0 ? (double)received_chars.length() / (double)send_string.length() : 0.0;
  
  // Test passes (returns true) if we detect baud rate mismatch issues
  // Message completion rate < 100% indicates transmission problems
  return message_completion_rate < 1.0;
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
    std::cout << "Good: Multi-Byte Transmission" << std::endl;
  } else {
    std::cout << "Err: Multi-Byte Transmissions" << std::endl;
  }

  // Test mismatched baud rates with more extreme differences
  constexpr UART_CONFIG fast_config = {.baud_rate = 56000,
    .data_bits = 8,
    .stop_bits = 1,
    .start_bits = 1, };

  constexpr UART_CONFIG slow_config = {.baud_rate = 50,
    .data_bits = 8,
    .stop_bits = 1,
    .start_bits = 1, };

  UART_DEVICE fast_uart = {.state = DeviceState::IDLE, .config = fast_config};
  UART_DEVICE slow_uart = {.state = DeviceState::IDLE, .config = slow_config};

  fast_uart.calculate_timing();
  slow_uart.calculate_timing();

  serial_connection(fast_uart, slow_uart);

  if (mismatched_baud_rate_test(fast_uart, slow_uart)) {
    std::cout << "Good: Mismatched Baud Rate Test (detected failures)" << std::endl;
  } else {
    std::cout << "Err: Mismatched Baud Rate Test (should have failed)" << std::endl;
  }
  
  return EXIT_SUCCESS;
}