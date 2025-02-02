#!/usr/bin/env python3

# This program processes an address trace generated by fastslim-with-offset.py
# to create an enhanced trace for use in the virtual memory simulator.
# The modifications made to the trace are:
#   - The offset part of a vaddr is scaled down to the simulated page frame size
#   - The value for a store is a random value in the range 0-255 (1 byte)
#   - The value for a load is the previous store to the same address, or 0 if
#     the address has not been written to.

import argparse
import fileinput
import operator
import sys
import random

# Parse command line arguments
parser = argparse.ArgumentParser(description="Transform reference trace from fastslim to memory simulator input format")
parser.add_argument("-k", "--keepcode", action="store_true", help="include code pages in trace")
parser.add_argument("-s", "--simpagesize", type=int, default=16, help="simulated physical page size (smaller than real 4k pagesize)")
parser.add_argument("tracefile", nargs='?', default='-')
args = parser.parse_args()

vals = {}

# Process input trace
for line in fileinput.input(args.tracefile):
        if line[0] == '=':
                continue
        tokens = line.strip().split()
        reftype = tokens[0]
        vaddr = int(tokens[1], 16)
        val = int(tokens[2])

        pg = vaddr // 4096
        # Discard some of the offset bits to stay in range of simulated frames
        offset = vaddr % args.simpagesize
        vaddr = pg * 4096 + offset

        # Get or Set value for this vaddr
        if reftype == 'S' or reftype == 'M':
                val = random.randint(1, 255)
                vals[vaddr] = val
        elif reftype == 'I' or reftype == 'L':
                # First reference?
                if vaddr in vals:
                        val = vals[vaddr]
                else:
                        val = 0
                        vals[vaddr] = val
        else:
                print("Unexpected reftype " + reftype)

        print("{} {:x} {}".format(reftype, vaddr, val))

