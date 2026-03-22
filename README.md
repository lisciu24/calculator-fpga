# FPGA Fixed-Point Hardware Calculator 

## Project Overview
This repository contains a fully functional, hardware calculator implemented on an FPGA using **SystemVerilog**. The system performs 32-bit arithmetic operations, featuring a custom-built SPI OLED controller and matrix keypad interface.

## Key Features
* **32-bit Execution Unit (ALU):** Supports Addition, Subtraction, Multiplication, and Division.
* **Dynamic Decimal Alignment:** Implements an `AlignComma` logic that automatically scales operands to match decimal positions before computation.
* **Custom SPI OLED Driver (SSD1306):** A low-level SPI implementation that manages display initialization, memory buffering, and ASCII character rendering.
* **Matrix Keypad Decoder:** 4x4 keypad interface with integrated debouncing and key-code translation.
* **Fixed-Point Precision:** Configurable fractional digits support, ensuring high precision for division and multiplication.

## System Architecture
The design follows a modular approach to ensure scalability and ease of verification.

| Module | Responsibility |
| :--- | :--- |
| `top.sv` | **Master FSM.** Orchestrates data flow between peripherals and the core. |
| `execution_unit.sv` | **Core ALU.** Handles arithmetic operations. |
| `bin_to_bcd.sv` | **Binary-to-BCD Converter.** Uses the *Double Dabble* algorithm for human-readable output. |
| `oled.sv` | **OLED controller.** FSM controles oled initialization and communication over SPI. |
| `oled_renderer.sv` | **Graphics engine.** Maps ASCII codes to font bitmaps and manages the display RAM. |
| `key_decoder.sv` | **Input controller.** Scans rows/columns and handles asynchronous key presses. |

## Tech Stack
* **HDL:** SystemVerilog
* **Tools:** Xilinx Vivado / [EDA Playground](https://www.edaplayground.com) online simulator
* **Target Hardware:** ZedBoard Zynq-7000

## Demo

https://github.com/user-attachments/assets/1b02fa8b-63a3-480e-9f82-a8095d5e1b94

