# `memchr` Function Breakdown

* [Setting up glibc environment](glibc-svp64-setup.md)
* [Guide to adding new SVP64 implementation](guide_new_func.md)
* [Debugging implemented SVP64 function](debugging_function_test.md)
* [LibreSOC sv.bc issue found during development](libresoc_issues_during_dev.md)
* [Breakdown of memrchr](breakdown_memchr.md)
* [Breakdown of strchr](breakdown_strchr.md)

## What is `memchr`?

    void *memchr(const void *s, int c, size_t n);

The function `memchr` is part of the standard C library, and can be used
after adding an `#include <string.h>`.

The memchr function locates the first occurrence of `c`
(converted to an unsigned char) in the initial `n` characters
(each interpreted as unsigned char) of the object pointed to by `s`.
The implementation shall behave as if it reads the characters sequentially
and stops as soon as a matching character is found.

The memchr function returns a pointer to the located character,
or a null pointer if the character does not occur in the object.

To summarise: find the first occurance of unsigned char `c` in the array of
chars pointed to by `s`. No match returns a null.

## `memchr_wrapper.c` - C wrapper to interface glibc test with SVP64 code

* [Source code](https://git.vantosh.com/ngisearch/glibc-svp64/src/branch/master/svp64-port/memchr_wrapper.c)

This wrapper file defines a wrapper function `MEMCHR_SVP64()` with the same
input arguments as standard `memchr()`, but also includes register setup
and call to `pypowersim` which will run LibreSOC's `ISACaller` simulator only
for the SVP64 `memchr` implementation.

The string to be tested is copied from the native C address space, to the
simulator's memory area (this is why during the execution of `memchr`,
a different string address will be seen, although the offsets within the
string are the same).

## `test-memchr.c` - Test regressions for `memchr`

* [Source code](https://git.vantosh.com/ngisearch/glibc-svp64/src/branch/master/svp64-port/test-memchr.c)

This file is copied from glibc, and requires several modifications to support
the SVP64 implementation. See the
[guide to adding new SVP64 implementation](guide_new_func.md)
for more details.

## `memchr_svp64.s` - SVP64 assembler implementation of `memchr`

* [Source code](https://git.vantosh.com/ngisearch/glibc-svp64/src/branch/master/svp64-port/svp64/memchr_svp64.s)

### Setup

Lines `#7-#18`, setup variables macros corresponding to used
General Purpose Registers (GPRs).

Lines `#22-#30, #46-#48`, macro which takes the character to match, `c`,
and produces an 8-byte mask with 8 copies of `c`.
This allows to compare 8 bytes of the input string at a time
(when loading 8-bytes from memory).

- Example: `c=0x17`, macro will produce the mask `0x1717171717171717`.

### Outer loop

Lines `#50-#75` comprise the `.outer` loop of the algorithm.

- Must determine if number of remaining chars, `n` of string is zero.
If so, return null (no match found).
- If `n` is less than 32, proceed to the byte search part of the algorithm
(`.found`).
- If `n` is 32 or greater, can use the SVP64 Vertical-First routine, `.inner`.
If this is the case, do the preamble before `.inner`:
  - First use `ctr` (uses `GPR[7]`) to store value of Count Register (CTR)
  to use. Configure the CTR. CTR is used to keep track of loop iterations
  (this is standard PowerISA use, not specific to SVP64). CTR is also used for
  certain conditional branch modes.
  - Setup SVSTATE register using `setvl`. Vector Length (VL) is 4
  (value in `ctr`), Vertical-First mode is used (step over instructions before
  incrementing register `srcstep`/`dststep` index).
  For more info on Vertical-First,
  [see](https://libre-soc.org/openpower/sv/svstep/).

### Inner loop

Lines `#63-#73` comprise the `.inner` loop (SVP64 Vertical-First routine)
of the algorithm.

- Load doubleword (8 bytes) of the string from memory and store in 
register starting at `GPR[16]` (actual register used is `16+dststep`).
- Compare byte by byte the loaded 8 bytes of the string with the matching
char mask. If any of the 8 bytes match, the instruction will set
the corresponding byte to `0xff` in `t` (starts at GPR[32]).
  - Example:

```
call cmpb cmpb
read reg 16/0: 0x9715a432c157d17
read reg 8/0: 0x1717171717171717
read reg 32/0: 0x0
write reg r(32, 32, 0) 0xff ew 64
```

- Compare immediate value 0 with `t`. Set the Condition Register (CR) Field
(starting at CR Field 0). If a matching char is present in the 8-byte
segment of the string, `t` will have a non-zero value, thus the CR Field
EQ bit will be cleared. This bit will be used to determine whether to branch
to the end of the algorithm, or to continue.
- Vectorised branch conditional.
Has a `BO=0` mode which means "Decrement the CTR, then branch if the
decremented CTRM:63≠0 and CRBI=0". (See Figure 40, Section 2.4 Branch
Instructions of PowerISA v3.0c spec for the full list of `BO` modes.).
In the event of a matching byte, EQ bit of CR Field will be zero, and thus
a branch to `.found` will occur if CTR is also non-zero.
- If no matches have occurred, continue by incrementing `srcstep` and
`dststep` using the `svstep` instruction. More info on `svstep`
[here](https://libre-soc.org/openpower/sv/svstep/).
- Increment address stored in `in_ptr` by 8, as the code checked 8 bytes
of string, and now can continue on to the next portion of the string.
Decrement `n` by 8 as there are now 8 fewer bytes to check.
- Branch back to the start of `.inner` if CTR is non-zero (haven't checked all
32 bytes yet). Otherwise branch back to `.outer` to determine how to continue.

### Found loop

Lines `#78-#85`. This code is reached if:

- There are fewer than 32 bytes to process, or,
- A match has been found in `.inner` and need to determine the exact
byte address

The algorithm is similar to the one used in `.inner`, except that code tests
one byte at a time. If there's an exact match, then the code returns from
`memchr` function call.

### Tail

Lines `#87-93`. If this portion of code is reached (or jumped to), then no
match has been found. Null is returned.

### Post-analysis issues discovered

- CTR register is decremented twice in the `inner` loop, once by `sv.bc`, and
again by `bdnz`. This means the number of iterations is only 2 (as opposed
to 4).
- `svstep` third argument needs to be set to 1 to enable incrementing
`srcstep`/`dststep`. Enabling this however, caused a strange issue where the
Effective Address (EA) used in `sv.ld` was not being changed even after
the value stored in `in_ptr` was incremented by 8 (EA was effectively frozen
for the duration of Vertical-First).

