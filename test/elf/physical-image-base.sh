#!/bin/bash
. $(dirname $0)/common.inc

[ $MACHINE = ppc64 ] && skip

cat <<EOF | $CC -o $t/a.o -c -xc -
#include <stdio.h>

__attribute__((section("foo"))) int bar;

int main() {
  printf("Hello world\n");
  return 0;
}
EOF

$CC -B. -no-pie -o $t/exe1 $t/a.o -Wl,--image-base=0x200000 \
   -Wl,--physical-image-base=0x800000

$QEMU $t/exe1 | grep -q 'Hello world'

readelf -W --segments $t/exe1 | grep -Eq 'LOAD\s+0x000000 0x0*200000 0x0*800000'
readelf -Ws $t/exe1 | grep -q __phys_start_foo


$CC -B. -no-pie -o $t/exe2 $t/a.o -Wl,--physical-image-base=0x800000 \
  -Wl,--section-order='#text=0x800000 #rodata #data=0x900000'

readelf -W --segments $t/exe2 | grep -Eq 'LOAD\s+\S+\s+(\S+)\s\1.*R E 0'
readelf -W --segments $t/exe2 | grep -Eq 'LOAD\s+\S+\s+(\S+)\s\1.*R   0'