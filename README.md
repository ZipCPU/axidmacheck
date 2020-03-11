## AXI DMA Check

This is a basic [AutoFPGA](https://github.com/ZipCPU/autofpga) connected
design for the purpose of testing various open source data mover solutions.

The data movers, together with the AXI interconnect and the various AXI bus
bridges and helpers, can be found in the
[wb2axip](http://github.com/ZipCPU/wb2axip) project.  (Expect this to become
a submodule to this project, since it needs to be downloaded into the main
directory.)

## Reconfigure

To reconfigure the project, adjust the AutoFPGA scripts listed in
[autodata/Makefile](autodata/Makefile), and run `make autodata`.

## Simulation

To build the design, run `make rtl; make sim`.  You will need to have
Verilator installed.  Running the simulation is as easy as `cd sim/; ./main_tb`.
There's not much to see, however, unless you run `./main_tb -d` instead to
produce a VCD file.  There's also a [GTKWave file](sim/axisim.gtkw) which
you can use when viewing the VCD file to help get some clarity to what's going
on early on.

## License

This design is licensed under the GPL.  It is not intended to be an end
user design--the RAM core consists of a large block RAM, the streams are quite
void of any useful information, etc.  Indeed, this design makes a better example
of what can be done using Verilator rather than an end design in itself, and
so the GPL license (a primarily software license) seems to fit a simulation
only project the best.

The core and guts of this project come from the [WB2AXIP](https://github.com/ZipCPU/wb2axip) project which is (currently) available under an Apache license.
AutoFPGA is licensed under GPL, although the designs created with it are free
for licensing as you see fit.
