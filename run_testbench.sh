#!/bin/sh
set -eux

iverilog -tvvp -ok12a_tb.vvp -g2005-sv -I. -Ik12a -s k12a_tb k12a/*.sv ic/*.sv
vvp ./k12a_tb.vvp
