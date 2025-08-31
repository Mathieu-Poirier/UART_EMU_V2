# UART_EMU_V2

## UART Simulation (C++ / Dear ImGUI Demo)

My UART device simulation project including a freestanding build and an ImGui demo simulating two UART devices. Developed on Linux with C++ and Make. Packaged in an AppImage for Linux with Windows build instructions and WSL support.

## Project Story

Initially I wanted to take an OOP focused approach to build this device simulation but I ended up abusing abstraction principles and I couldn't keep the scope of the design contained. I focused on the procedural aspect of the code and the hard problems to solve such as: baud and clock timing, easily converting strings to bits, the connection of devices and visualizing it all in a demo. I ended up landing on a combination of structs and procedures that worked well, utilizing no standard library. 

## Project Features

- UART deterministic and discrete timing simulation
- Configurable UART Settings
- Frame validation from stop/start bit
- Bit-level transmission 
- ImGui demo with live logs of received text (fixed 63 character message sizes)
- Serial connection simulation
- Public kanban using [Trello](https://trello.com/b/4MSv9Ytv/uartemuv2)
- Freestanding build and hosted build for testing

## Messaging Through UART Demo

![Messaging Demo Gif](repo_assets/demo.gif)

## Project Structure



## How To Build: Linux

## How To Build: Windows




