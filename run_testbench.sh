#!/bin/sh
set -eux

iverilog -Wall -tvvp -ok12a_tb.vvp -g2005-sv -I. -Ik12a -s k12a_tb k12a/*.sv memory/*.sv
vvp ./k12a_tb.vvp
