#!/bin/sh
set -eux

iverilog -o k12a_tb.vvp -g2005-sv -I. -Ik12a -s k12a_tb k12a/*.sv ic/*.sv
./k12a_tb.vvp
