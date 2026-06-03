# Tapered Precision Floating-Point Hardware Generators & ASIC Macros

This repository contains parameterizable VHDL RTL implementations for various **Tapered Precision Floating-Point Number Formats** (such as Posits and Takum variants). Additionally, it provides hardware synthesis and physical design scripts for turning the RTL into ASIC macros using the open-source **IHP SG13G2 130 nm BiCMOS technology node**.

The toolflow leverages an open-source EDA infrastructure driven by **Yosys** for logic synthesis and **OpenROAD** for automated floorplanning, placement, routing, and timing closure.

---

## Examples 
- <32,2> posit adder gds:
- <img width="1280" height="1200" alt="image" src="https://github.com/user-attachments/assets/329777ed-0b11-48cd-9d2f-4a43c56978db" />
