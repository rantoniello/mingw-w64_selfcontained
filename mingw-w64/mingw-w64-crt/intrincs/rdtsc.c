/**
 * This file has no copyright assigned and is placed in the Public Domain.
 * This file is part of the mingw-w64 runtime package.
 * No warranty is given; refer to the file DISCLAIMER.PD within this package.
 */

#ifdef __clang__
#define __IA32INTRIN_H
#endif
#include <intrin.h>

unsigned __int64 __rdtsc(void)
{
#ifdef _WIN64
      unsigned __int64 val1, val2;
#else
      unsigned int val1, val2;
#endif
      __asm__ __volatile__ (
          "rdtsc" 
          : "=a" (val1), "=d" (val2));
      return ((unsigned __int64)val1) | (((unsigned __int64)val2) << 32);
}

