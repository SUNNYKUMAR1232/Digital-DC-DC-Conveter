# Digital DC-DC Converter Using 8051 Microcontroller

## Overview

This project implements a digital DC-DC converter using the AT89C52 (8051 family) microcontroller. The system converts a 5V input to a regulated 3.3V output using PWM (Pulse Width Modulation) control, with real-time adjustment of the duty cycle via external interrupts. The project features an LCD display for live feedback of duty cycle and output voltage.

---

## Features

- **Input Voltage:** 5V
- **Output Voltage:** 3.3V (adjustable via duty cycle)
- **PWM Frequency:** 971 Hz
- **Microcontroller:** AT89C52 (8051 family)
- **LCD Display:** Shows duty cycle and output voltage
- **User Controls:**
      - Increase/decrease duty cycle via external interrupts (buttons)
- **Compiler:** ASEM-51 (Proteus compatible)

---

## Hardware Connections

| Signal    | 8051 Pin  | Description         |
| --------- | --------- | ------------------- |
| SIG       | P3.7      | PWM Output          |
| DATA_LINE | P2        | LCD Data (DB0-DB7)  |
| RS        | P1.0      | LCD Register Select |
| RW        | P1.1      | LCD Read/Write      |
| EN        | P1.2      | LCD Enable          |
| INT0/INT1 | P3.2/P3.3 | External Interrupts |

---
<img width="1347" height="934" alt="Screenshot 2025-07-19 213151" src="https://github.com/user-attachments/assets/23e5a61a-73ed-4798-ac09-1a49f134fbec" />
## Code Structure

- **Interrupt Vectors:**
      - Reset, Timer0, Timer1, External Interrupt 0/1
- **Main Loop:**
      - Initializes timers, LCD, and variables
      - Enters infinite loop (PWM handled by interrupts)
- **Timer Interrupts:**
      - `T0_ISR`: Sets PWM high, starts Timer1
      - `T1_ISR`: Sets PWM low, restarts Timer0
- **External Interrupts:**
      - `EX0_ISR`: Increases duty cycle (shortens low period, lengthens high period)
      - `EX1_ISR`: Decreases duty cycle (lengthens low period, shortens high period)
- **LCD Functions:**
      - Initialization, command/data send, busy check, string display, cursor control
- **Utility Functions:**
      - Delay routines, timer reload, duty cycle math

---

## How It Works

1. **Startup:**
       - LCD displays welcome and project title.
       - Timers are configured for PWM generation.
2. **PWM Generation:**
       - Timer0 and Timer1 alternate to create a PWM signal on P3.7.
       - Duty cycle is controlled by adjusting timer reload values.
3. **User Interaction:**
       - Pressing buttons connected to INT0/INT1 increases or decreases the duty cycle.
       - LCD updates to show the new duty cycle and output voltage.

---

## LCD Display Example

```plain
DUTY_CYCLE : 70%
VOLTAGE    : 3.5V
```

---

## File List

- `Digital DC-DC Converter.pdsprj` — Proteus project file
- `readme.md` — Project documentation (this file)
- **Assembly Source File:** (not included here, see Proteus project)

---

## Usage Instructions

1. Open the project in Proteus or your preferred 8051 simulator.
2. Assemble the code using ASEM-51.
3. Load the hex file into the AT89C52 microcontroller in the simulation.
4. Connect buttons to INT0 and INT1 for duty cycle adjustment.
5. Observe the PWM output and LCD display.

---

## Notes

- Adjust `CHANGE_H` and `CHANGE_L` in code to modify the step size for duty cycle changes.
- The LCD messages and voltage display can be customized in the code.
- Ensure correct wiring of LCD and buttons as per the pin mapping above.

---

## Author & Credits

- **Created:** Thu Nov 14, 2024
- **Processor:** AT89C52
- **Compiler:** ASEM-51
- **Simulation:** Proteus

---

## License

This project is for educational and personal use. Please credit the author if you use or modify this design.
