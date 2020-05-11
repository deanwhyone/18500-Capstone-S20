# 18500-Capstone-S20
Multiplayer Tetris on FPGAs

Hello and welcome to our repository for our capstone project.
This is an FPGA implementation of multiplayer tetris, designed for
"pure" fabric FPGAs which do not have an SoC. The design is mostly
done in SystemVerilog and is intended to be run on an Altera-board,
though nothing here is Intel-specific with the exception of the
assets files which are coded as Intel-style .mif files.

The game is run on SVGA 800x600 @ 72hz. This limit is chosen due to
clock speed limitations.

# Usage
Top level files are in testbenches/
The full game is implemented in TetrisTop.sv. To use this, include all
files in the src/ including those in the networking/ subfolder, but not
including VGA.sv and StateUpdateValid.sv. Those are older and deprecated.
You also should include all files in packages.
