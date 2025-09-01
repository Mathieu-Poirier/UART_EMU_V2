/**
 * UART Emulator Demo with ImGui
 * Fixed layout: scrollable log region + bottom input bar.
 * TX loads full message on Enter, RX reconstructs character-by-character per frame.
 */

 #include <cstdint>
 #include <iostream>
 #include <cstdlib>
 #include <vector>
 #include <string>
 #include <memory>
 #include "../src/device.hpp"
 
 #include "../imgui/imgui.h"
 #include "../imgui/backends/imgui_impl_glfw.h"
 #include "../imgui/backends/imgui_impl_opengl3.h"
 
 #include <GLFW/glfw3.h>
 
 // UART bit definitions
 constexpr uint8_t start_bit = 0x00; // low line
 constexpr uint8_t stop_bit  = 0x01; // high line
 
 // Convert string to bit array
 static std::unique_ptr<uint8_t[]> string_to_bits(const std::string& str_in) {
     uint32_t bit_arr_size = str_in.size() * 8;
     std::unique_ptr<uint8_t[]> bit_arr_ptr = std::make_unique<uint8_t[]>(bit_arr_size);
 
     uint32_t arr_idx = 0;
     for (uint8_t character : str_in) {
         for (int i = 7; i >= 0; --i) {
             uint8_t bit = (character >> i) & 0x01;
             bit_arr_ptr[arr_idx++] = bit;
         }
     }
     return bit_arr_ptr;
 }
 
 // Push bit array into UART TX buffer
 static void load_bit_array_tx(UART_DEVICE &dev, const uint8_t *bit_arr, uint32_t size) {
     for (uint32_t i = 0; i < size; i++) {
         dev.tx_buf.push(bit_arr[i]);
     }
 }
 
 // Update device state based on buffer activity
 static void transition_uart_state(UART_DEVICE &dev) {
     if (!dev.rx_buf.is_empty()) {
         if (dev.state == DeviceState::TRANSMITTING)
             dev.state = DeviceState::RECEIVING_AND_TRANSMITTING;
         else
             dev.state = DeviceState::RECEIVING;
     }
     if (!dev.tx_buf.is_empty()) {
         if (dev.state == DeviceState::RECEIVING)
             dev.state = DeviceState::RECEIVING_AND_TRANSMITTING;
         else
             dev.state = DeviceState::TRANSMITTING;
     }
 }
 
 // Reconstruct one byte from RX buffer
 static bool handle_receive(UART_DEVICE &dev, uint8_t &reconstructed_character) {
     if (dev.state == DeviceState::RECEIVING || dev.state == DeviceState::RECEIVING_AND_TRANSMITTING) {
         reconstructed_character = 0x00;
 
         uint8_t message_start;
         if (!dev.rx_buf.peek(message_start)) return false;
 
         if (message_start == start_bit) {
             uint8_t dummy;
             dev.rx_buf.pop(dummy); // consume start bit
 
             for (uint32_t i = 0; i < dev.config.data_bits; i++) {
                 uint8_t bit;
                 if (dev.rx_buf.pop(bit)) {
                     reconstructed_character = (reconstructed_character << 1) | bit;
                 } else {
                     // Buffer underrun - invalid frame
                     dev.rx_buf.reset();
                     dev.state = DeviceState::IDLE;
                     return false;
                 }
             }
 
             uint8_t message_end;
             if (dev.rx_buf.peek(message_end) && message_end == stop_bit) {
                 dev.rx_buf.pop(message_end);
                 dev.state = DeviceState::IDLE;
                 return true;
             } else {
                 dev.rx_buf.reset();
                 dev.state = DeviceState::IDLE;
                 return false;
             }
         } else {
             dev.rx_buf.reset();
             dev.state = DeviceState::IDLE;
             return false;
         }
     }
     return false;
 }
 
 // Transmit one frame of bits
 static void handle_transmit(UART_DEVICE &dev) {
     if (dev.state == DeviceState::TRANSMITTING || dev.state == DeviceState::RECEIVING_AND_TRANSMITTING) {
         send_bit(dev, start_bit);
 
         for (uint32_t i = 0; i < dev.config.data_bits; i++) {
             uint8_t send_value;
             if (dev.tx_buf.pop(send_value)) {
                 send_bit(dev, send_value);
             } else {
                 // Buffer underrun - invalid frame
                 dev.state = DeviceState::IDLE;
                 return;
             }
         }
 
         send_bit(dev, stop_bit);
         dev.state = DeviceState::IDLE;
     }
 }
 
 // GLFW error callback
 static void glfw_error_callback(int error, const char* description) {
     std::cerr << "GLFW Error " << error << ": " << description << std::endl;
 }
 
 int main() {
     constexpr UART_CONFIG default_config = {
         .baud_rate = 57600,
         .data_bits = 8,
         .stop_bits = 1,
         .start_bits = 1,
     };
 
     UART_DEVICE uart_one = {.state = DeviceState::IDLE, .config = default_config};
     UART_DEVICE uart_two = {.state = DeviceState::IDLE, .config = default_config};
 
     uart_one.calculate_timing();
     uart_two.calculate_timing();
     serial_connection(uart_one, uart_two);
 
     // Setup GLFW
     glfwSetErrorCallback(glfw_error_callback);
     if (!glfwInit()) {
         std::cerr << "Failed to initialize GLFW!" << std::endl;
         return EXIT_FAILURE;
     }

     glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
     glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
     glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
     glfwWindowHint(GLFW_DECORATED, GLFW_TRUE);
 
     GLFWwindow* window = glfwCreateWindow(800, 600, "UART Emulator Demo", nullptr, nullptr);
     if (!window) {
         std::cerr << "Failed to create GLFW window!" << std::endl;
         glfwTerminate();
         return EXIT_FAILURE;
     }
     glfwMakeContextCurrent(window);
     glfwSwapInterval(1);
 
     // Setup Dear ImGui
     IMGUI_CHECKVERSION();
     ImGui::CreateContext();
     ImGuiIO& io = ImGui::GetIO(); (void)io;
     io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
     ImGui::StyleColorsDark();
     ImGui_ImplGlfw_InitForOpenGL(window, true);
     ImGui_ImplOpenGL3_Init("#version 130");
 
     // Persistent state
     static char uart_input[128] = "";
     static std::vector<uint8_t> reconstructed_string;
     static std::vector<std::string> uart_log;
     static bool scroll_to_bottom = false;
     static bool want_focus = true;
     static size_t sent = 0;
 
     // Main loop
     while (!glfwWindowShouldClose(window)) {
         glfwPollEvents();
         if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
             glfwSetWindowShouldClose(window, GLFW_TRUE);
 
         ImGui_ImplOpenGL3_NewFrame();
         ImGui_ImplGlfw_NewFrame();
         ImGui::NewFrame();
 
         // Fullscreen console window
         ImGui::SetNextWindowPos(ImVec2(0, 0));
         ImGui::SetNextWindowSize(io.DisplaySize);
         ImGui::Begin("UART Console", nullptr,
                      ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize |
                          ImGuiWindowFlags_NoMove |
                          ImGuiWindowFlags_NoCollapse);
                        
 
         // Log region
         ImGui::BeginChild("LogRegion", ImVec2(0, -ImGui::GetFrameHeightWithSpacing()), true);
         for (const auto& line : uart_log) {
             ImGui::TextWrapped("%s", line.c_str());
         }
         if (scroll_to_bottom) ImGui::SetScrollHereY(1.0f);
         scroll_to_bottom = false;
         ImGui::EndChild();
 
         // Input line
         ImGui::SetNextItemWidth(-FLT_MIN);
         if (ImGui::InputText("##UARTInput", uart_input, IM_ARRAYSIZE(uart_input),
                              ImGuiInputTextFlags_EnterReturnsTrue)) {
             if (uart_input[0] != '\0') {
                 std::string send_string(uart_input);
 
                 reconstructed_string.clear();
                 reconstructed_string.resize(send_string.size(), 0);
 
                 std::size_t send_size = send_string.size() * 8;
                 auto uart_in_ptr = string_to_bits(send_string);
 
                 load_bit_array_tx(uart_one, uart_in_ptr.get(), send_size);
 
                 std::cout << "UART Input: " << uart_input << std::endl;
                 uart_input[0] = '\0';
                 scroll_to_bottom = true;
                 want_focus = true;
                 sent = 0;
             }
         }
 
         if (want_focus) {
             ImGui::SetKeyboardFocusHere(-1);
             want_focus = false;
         }
 
         // ---- FRAME-LEVEL UART SIMULATION ----
         if (is_ready(uart_one)) {
             reset_clock(uart_one);
             transition_uart_state(uart_one);
             handle_transmit(uart_one);
         }
 
         if (is_ready(uart_two)) {
             reset_clock(uart_two);
             transition_uart_state(uart_two);
             handle_transmit(uart_two);
 
             uint8_t rx_char;
             if (handle_receive(uart_two, rx_char)) {
                 if (sent < reconstructed_string.size()) {
                     reconstructed_string[sent] = rx_char;
                     sent++;
                 }
                 // If complete, log it
                 if (sent == reconstructed_string.size()) {
                     std::string printable(reconstructed_string.begin(), reconstructed_string.end());
                     std::string log_entry = "UART TWO RECEIVED: " + printable;
                     uart_log.push_back(log_entry);
                     sent = 0;
                 }
             }
         }
 
         tick_down(uart_one);
         tick_down(uart_two);
 
         ImGui::End();
 
         // Rendering
         int display_w, display_h;
         glfwGetFramebufferSize(window, &display_w, &display_h);
         ImGui::Render();
         glViewport(0, 0, display_w, display_h);
         glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
         glClear(GL_COLOR_BUFFER_BIT);
         ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
         glfwSwapBuffers(window);
     }
 
    // Cleanup
    if (window) {
        ImGui_ImplOpenGL3_Shutdown();
        ImGui_ImplGlfw_Shutdown();
        ImGui::DestroyContext();

        glfwDestroyWindow(window);
    }
    glfwTerminate();
 
     return EXIT_SUCCESS;
 }
 