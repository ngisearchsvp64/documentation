# `strchr` Function Breakdown

* [Setting up glibc environment](glibc-svp64-setup.md)
* [Guide to adding new SVP64 implementation](guide_new_func.md)
* [Debugging implemented SVP64 function](debugging_function_test.md)
* [LibreSOC sv.bc issue found during development](libresoc_issues_during_dev.md)
* [Breakdown of memchr](breakdown_memchr.md)
* [Breakdown of memrchr](breakdown_memrchr.md)

## What is `strchr`?

    char *strchr(const char *s, int c);

The function `strchr` is part of the standard C library, and can be used
after adding an `#include <string.h>`.

The strchr function locates the first occurrence of c (converted to a char)
in the string pointed to by s. The terminating null character is considered
to be part of the string.

The strchr function returns a pointer to the located character, or
a null pointer if the character does not occur in the string.

Very similar to `memchr`, except the length of the array `n` is not provided,
so the function must determine this manually. A Horizontal-First version of
the inner loop from `memrchr` is used (without reversing the memory pointer).

With SVP64's Data-Dependent Fail-First, this function can be terminated
automatically without calculating the length of the string beforehand.
See the `strncpy` example in the LibreSOC
[repo](https://git.libre-soc.org/?p=openpower-isa.git;a=blob;f=src/openpower/decoder/isa/test_caller_svp64_ldst.py;h=4ecf534777a5e8a0178b29dbcd69a1a5e2dd14d6;hb=HEAD#l32)

## `strchr_wrapper.c` - C wrapper to interface glibc test with SVP64 code

* [Source code](https://git.vantosh.com/ngisearch/glibc-svp64/src/branch/master/svp64-port/strchr_wrapper.c)

Works similarly to the `memchr` version. Please see
[breakdown of memchr](breakdown_memchr.md)
for more details.

One difference is the lack of `n` parameter.

## `test-strchr.c` - Test regressions for `memchr`

* [Source code](https://git.vantosh.com/ngisearch/glibc-svp64/src/branch/master/svp64-port/test-strchr.c)

This file is copied from glibc, and requires several modifications to support
the SVP64 implementation. See the
[guide to adding new SVP64 implementation](guide_new_func.md)
for more details.

## `strchr_svp64.s` - SVP64 assembler implementation of `memchr`

* [Source code](https://git.vantosh.com/ngisearch/glibc-svp64/src/branch/master/svp64-port/svp64/strchr_svp64.s)

### Setup

Lines `#7-#17`, setup variables macros corresponding to used
General Purpose Registers (GPRs).

Lines `#21-#45, #57-#62`, defines multiple macros.
The first macro is the same as in `memchr` and `memrchr`. Please see
[breakdown of memchr](breakdown_memchr.md)
for more details.

The other macro determines the length of the string. With Data-Dependent
Fail-First, this could comprise the entire `strchr` implementation by itself
(with similar instruction listing as first half of `strncpy`, see
[here](https://git.libre-soc.org/?p=openpower-isa.git;a=blob;f=src/openpower/decoder/isa/test_caller_svp64_ldst.py;h=4ecf534777a5e8a0178b29dbcd69a1a5e2dd14d6;hb=HEAD#l32)).

### Outer loop

Lines `#64-#103` comprise the `.outer` loop of the algorithm.

Checks for the string length `n` is similar to `memchr`. Please see
[breakdown of memchr](breakdown_memchr.md)
for more details.

### Inner loop

Lines `#76-#101` comprise the `.inner` loop (SVP64 Horizontal-First routine)
of the algorithm.

Similar to `memrchr`. Please see
[breakdown of memrchr](breakdown_memrchr.md)
for more details.

### Determine matched char location

Lines `#107-#119`.

Also similar to `memrchr`, except the string pointer is incremented.

### Found loop

Lines `#121-#128`. Same to `memchr`. Please see
[breakdown of memchr](breakdown_memchr.md)
for more details.

### Tail

Lines `#130-135`. If this portion of code is reached (or jumped to), then no
match has been found. Null is returned.

### Post-analysis issues discovered

- Initial strlen calculation requires going over entire string,
very inefficient.
- Similar issues as with `memrchr` (can be optimised).
