# mingw-w64_selfcontained
Selfcontained repository for building mingw-w64 (GCC for Windows 64 &amp; 32 bits) on Linux

Reference:
http://mingw-w64.org

Compiled on <TODO>.
Dependencies:
  
  build-essential
  po4a
  texinfo

Library versions used in this repository:

bison 3.0.5
flex 2.6.3
gmp 6.1.0
mpc 1.0.3
mpfr 3.1.4
binutils 2.30 (used to compile GCC for mingw-w64)
gcc 8.1.0 (compiled for mingw-w64)
mingw-w64 v5.0.3

Please read the document in the folder mingw-w64-doc/howto-build/.

To build mingw-w64 from source, we follow the steps recommended:

*) build and install binutils for target x86_64-w64-mingw32
*) build and install mingw-w64-headers for target x86_64-w64-mingw32
*) build (all-gcc) and install (install-gcc) for target x86_64-w64-mingw32 (dependencies are gmp, mpfr, mpc, bison, flex)
*) build and install mingw-w64-crt for target x86_64-w64-mingw32
*) build and install gcc for target x86_64-w64-mingw32


