# `memrchr` Function Breakdown

* [Setting up glibc environment](glibc-svp64-setup.md)
* [Guide to adding new SVP64 implementation](guide_new_func.md)
* [Debugging implemented SVP64 function](debugging_function_test.md)
* [LibreSOC sv.bc issue found during development](libresoc_issues_during_dev.md)
* [Breakdown of memchr](breakdown_memchr.md)
* [Breakdown of strchr](breakdown_strchr.md)

## What is `memrchr`?

    void *memrchr(const void *s, int c, size_t n);

The function `memrchr` is part of the standard C library, and can be used
after adding an `#include <string.h>`.

The memrchr function locates the last occurrence of `c`
(converted to an unsigned char) in the initial `n` characters
(each interpreted as unsigned char) of the object pointed to by `s`.
The implementation shall behave as if it reads the characters sequentially
in reverse order and stops as soon as a matching character is found.

The memrchr function returns a pointer to the located character,
or a null pointer if the character does not occur in the object.

This function behaves similarly to `memchr`, but searches in reverse.
In terms of the implementation, this requires a bit of additional arithmetic
to start looking in reverse.
It is expected the reader will look at the 'memchr'
breakdown first for more context (link at the top of the page).

As demonstration of SVP64, a *Horizontal-First implementation is used instead
of Vertical-First*.

## `memrchr_wrapper.c` - C wrapper to interface glibc test with SVP64 code

* [Source code](https://git.vantosh.com/ngisearch/glibc-svp64/src/branch/master/svp64-port/memrchr_wrapper.c)

Works similarly to the `memchr` version. Please see
[breakdown of memchr](breakdown_memchr.md)
for more details.

## `test-memrchr.c` - Test regressions for `memrchr`

* [Source code](https://git.vantosh.com/ngisearch/glibc-svp64/src/branch/master/svp64-port/test-memrchr.c)

This file is copied from glibc, and requires several modifications to support
the SVP64 implementation. See the
[guide to adding new SVP64 implementation](guide_new_func.md)
for more details.

## `memrchr_svp64.s` - SVP64 assembler implementation of `memrchr`

* [Source code](https://git.vantosh.com/ngisearch/glibc-svp64/src/branch/master/svp64-port/svp64/memrchr_svp64.s)

### Setup

Lines `#7-#23`, setup variables macros corresponding to used
General Purpose Registers (GPRs).

Lines `#27-#35, #51-#53`, same macro as used in `memchr`. Please see
[breakdown of memchr](breakdown_memchr.md)
for more details.

Lines `#54-#59`, adjust `in_ptr` (current string pointer) to start at N-1
(the last char of the string).

### Outer loop

Lines `#61-#131` comprise the `.outer` loop of the algorithm.

- Must determine if number of remaining chars, `n` of string is zero.
If so, return null (no match found).
- If `n` is less than 32, proceed to the byte search part of the algorithm
(`.found`).
- If `n` is 32 or greater, can use the SVP64 Horizontal-First routine,
`.inner`. If this is the case, do the preamble before `.inner`:
  - Check if `n` is a multiple of 8. If not, need to check several (`n%8`)
  tail characters of the string before the SVP64 routine can be used.
  The check routine is the one as was used in `.found` (for both `memchr`
  and `memrchr`).
  - Another adjustment to `in_ptr` is needed (decrement pointer by 7)
  at the start of the function, because 8 bytes are being read at a time
  in the SVP64 routine.
  - First use `ctr` (uses `GPR[7]`) to store value of Count Register (CTR)
  to use. CTR is used to keep track of loop iterations for SVP64.
  Additional `tmp` register stores `ctr+1` (needed to make sure the vectorised
  branch will loop `ctr` times).

### Inner loop

Lines `#99-#129` comprise the `.inner` loop (SVP64 Horizontal-First routine)
of the algorithm.

- Use 4 consecutive registers (starting at `addr0` or `GPR[12]`) to store
`(in_ptr)`, `(in_ptr)-8`, `(in_ptr)-16`, `(in_ptr)-24` which will be used
for the Horizontal-First routine.
- The instructions `sv.ld`, `sv.cmpb`, `sv.cmpi`, `sv.bc` function similarly
to the `memchr` implementation, but due the Horizontal-First mode, are done
as separate batches. On a match, branch to `.determine_loc`.

- If no matches have occurred, move string pointer back by 32 (as the coded
processed 32 bytes) and decrease `n` by 32.
- Branch if `n` is now less than 32. This is required because `in_ptr` needs
to be incremented by 7 (as the code will now be loading bytes,
not an 8-byte word.
Otherwise branch back to `.outer` to determine how to continue.

### Determine location

Lines `#135-#145`, use the current value of CTR to calculate which 8-byte
block of chars contains the matching character.
`in_ptr` is adjusted accordingly.

### Move forward by 7

Lines `#150-#151`. At the start of `memrchr` function call, `in_ptr` was
moved back by 7 (to correctly read 8 bytes). Now `in_ptr` has to be moved
forward by 7 (because the code will now search by byte starting at the later
byte).

### Found loop

Lines `#152-#159`. Almost identical to the `memchr` version, except `in_ptr` is
decremented (since `memrchr` searches from the end).

### Tail

Lines `#161-167`. If this portion of code is reached (or jumped to), then no
match has been found. Null is returned.

### Post-analysis issues discovered

- With more time (and better understanding of the SVP64), plenty of
improvements can be made. That said, limited support for advanced SVP64
features in binutils puts a limitation on which features can be used.
- The branch conditional target address is manually calculated, requiring to
look at the objdump of the assembler to determine the correct offset. This is
due to binutils calculating the wrong address. The procedure for this can be
found [here](debugging_function_test.md).

