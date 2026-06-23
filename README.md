# Tapered Precision Floating-Point Hardware for ASIC Macros

This repository contains parameterizable VHDL RTL implementations (in their respective branches) for various **Tapered Precision Floating-Point Number Formats** (such as Posits and Takum variants). Additionally, it provides hardware synthesis and physical design scripts for turning the RTL into ASIC macros using the open-source **IHP SG13G2 130 nm BiCMOS technology node**.

The toolflow uses an open-source EDA infrastructure like by **Yosys** for logic synthesis and **OpenROAD** for automated floorplanning, placement, routing, and timing closure.

**still under Development (mainly takum adder)**

---

## Examples 
- <32,2> posit adder gds with utilisation of 70%:
- <img width="1280" height="1200" alt="image" src="https://github.com/user-attachments/assets/329777ed-0b11-48cd-9d2f-4a43c56978db" />

## Sources
### Posits
```bibtex
@article{10.14529/jsfi170206,
author = {Gustafson and Yonemoto},
title = {Beating Floating Point at its Own Game: Posit Arithmetic},
year = {2017},
issue_date = {June 2017},
publisher = {South Ural State University},
address = {Chelyabinsk, RUS},
volume = {4},
number = {2},
issn = {2409-6008},
url = {https://doi.org/10.14529/jsfi170206},
doi = {10.14529/jsfi170206}
```
### Takums
```bibtex
@inbook{Hunhold_2024,
   title={Beating Posits at Their Own Game: Takum Arithmetic},
   ISBN={9783031727092},
   ISSN={1611-3349},
   url={http://dx.doi.org/10.1007/978-3-031-72709-2_1},
   DOI={10.1007/978-3-031-72709-2_1},
   booktitle={Next Generation Arithmetic},
   publisher={Springer Nature Switzerland},
   author={Hunhold, Laslo},
   year={2024},
   pages={1–51} }
```
```bibtex
@misc{hunhold2025designimplementationtakumarithmetic,
      title={Design and Implementation of a Takum Arithmetic Hardware Codec}, 
      author={Laslo Hunhold},
      year={2025},
      eprint={2408.10594},
      archivePrefix={arXiv},
      primaryClass={cs.AR},
      url={https://arxiv.org/abs/2408.10594}, 
}
```
