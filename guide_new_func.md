# Guide to New SVP64 Implementation of GLIBC Function

# Glibc Repo

    (glibc-svp64)$: cd ~/src/glibc-svp64/glibc
    (glibc-svp64)$:

## Steps - strchr as an example

### Copy `test-[function].c` from glibc

From glibc, copy the test C file for the respective function
into svp64-port directory.

It should be under the function category, for example, strchr is
under `string/test-strchr.c`

    (glibc-svp64)$: cp ~/src/glibc-svp64/glibc/string/test-strchr.c \\
                    ~/src/glibc-svp64/svp64-port/

### Making adjustments to `test-[function].c`

Add the following `#define`s after the
`typedef CHAR *(*proto_t) (const CHAR *, int);` line:

    #define STRCHR_SVP64 strchr_svp64
    #define MAX_SIZE    256
    CHAR *SIMPLE_STRCHR (const CHAR *, int, size_t);
    CHAR *STRCHR_SVP64 (const CHAR *, int, size_t);

`MAX_SIZE` is set to 256 to reduce the time taken to run the regression tests.

The `IMPL` calls will need to be modified.
*(Do these define the functions used during the test?)*
*(Why is there inconsistency with the upper/lower case `simple_`?)*

Comment out:

    IMPL (stupid_STRCHR, 0)
    IMPL (simple_STRCHR, 0)
    IMPL (STRCHR, 1)

And add:

    IMPL (STRCHR_SVP64, 1)
    IMPL (simple_STRCHR, 2)

For debugging purposes, add a printf statement as first line inside
`SIMPLE_[FUNCTION]` function code. For `strchr` the statement is added inside
`SIMPLE_STRCHR`:

    printf("strchr called: s: %p, c: %02x(%c)\n", s, (uint8_t)c, c);

For initial testing, it's worthwhile to disable most tests,
and only turn a few. The C function `test_main` at the bottom of the file
contains the tests being run.

`do_test` is the function used for running a single test case, and
has five arguments:

- align (used for checking alignment to page size)
- pos - position **(?)**
- len - length of char array
- seek_char - **(?)**
- max_char - **(?)** Largest permitted character (buffer char is limited
by performing modulo `max_char`).

*TODO: Helpful to add arguments of `do_test`*

In the test cases done for `memchr`, `memrchr`, `strchr`, the length argument
is limited to 256 for reducing the time take to run tests.

The `max_char` parameter is used to specify the character to match.**(?)**

Inside the `SIMPLE_[FUNCTION]` function, add the printf statement for debug
and/or logging:

      printf("strchr called: s: %p, c: %02x(%c)\n", s, (uint8_t)c, c);

### `[function]_wrapper.c`

Create a new `strchr_wrapper.c` C file which will interface with the glibc
tests and access the ISACaller PowerISA+SVP64 simulator. An existing
`[function]_wrapper.c` file can be used (in this example, `memchr`):

    (glibc-svp64)$: cp ~/src/glibc-svp64/svp64-port/memchr_wrapper.c \\
                    ~/src/glibc-svp64/svp64-port/strchr_wrapper.c

### Making adjustments to `[function]_wrapper.c`

Sadly this is difficult to automate (at least for now), because other than
substituting the function name, the logic of the code may need to change.
The general structure will however remain the same.

- The easiest change to make is to replace every instance of previous function
name to the new one being implemented. With the current example,
replace `memchr` with `strchr`, and `MEMCHR` with `STRCHR`.
- Change the input arguments of `[FUNCTION]_SVP64`. In this case, only `s`
and `c` are necessary (as string function continues until a null byte
is encountered.
- Update the code and comments of the `[FUNCTION]_SVP64`. In this case, remove
use of `n`. `size_t bytes` need to be calculated using `strlen(s)` because
the length of the string is not provided.
- **(?)** - Copyright notice at the top needs updating...

### Adjusting Makefile

The Makefile in `svp64-port` needs to be updated to include the new function
test code (in this example, `strchr`).

Add a new target:

    strchr_TARGET	= test-strchr-svp64

Below `BINDIR` variable add:

    strchr_CFILES	:= support_test_main.c test-strchr.c strchr_wrapper.c
    strchr_ASFILES := $(SVP64)/strchr_svp64.s $(SVP64)/strchr_orig_ppc64.s
    strchr_SVP64OBJECTS := $(strchr_ASFILES:$(SVP64)/%.s=$(SVP64)/%.o)
    strchr_OBJECTS := $(strchr_CFILES:%.c=%.o)
    strchr_BINFILES := $(BINDIR)/strchr_svp64.bin
    strchr_ELFFILES := $(BINDIR)/strchr_svp64.elf

Add target for the `test-[function].o` object:

    test-strchr.o: test-strchr.c
    	$(CC) -c $(CFLAGS) -DMODULE_NAME=testsuite -o $@ $^

Add target for generating assembly implementation of using standard PowerISA:

    $(SVP64)/strchr_orig_ppc64.s: $(GLIBCDIR)/string/strchr.c
    	$(CROSSCC) $(CROSSCFLAGS) -S -g0 -Os -DMODULE_NAME=libc -o $@ $^

Append `$(strchr_TARGET)` to the `all` make rule.

Add a target for the final `test-[function]-svp64` binary:

    $(strchr_TARGET): $(strchr_OBJECTS) $(strchr_SVP64OBJECTS) $(strchr_ELFFILES) $(strchr_BINFILES)
    	$(CC) -o $@ $(strchr_OBJECTS) $(LDFLAGS)

Add a line to the `clean` make rule:

    $ rm -f $(strchr_OBJECTS) $(strchr_SVP64OBJECTS) $(strchr_BINFILES) $(strchr_ELFFILES) $(strchr_TARGET)

Append `$(strchr_TARGET)` to the line under the `remove` make rule.

### `[function]_svp64.s` assembler file

This file can be started by copying from existing SVP64 function, or by using
the generated assembler using the reference implementation
(`[function]_orig_ppc64.s`), although the generated assembler is probably more
difficult to follow than simply writing from scratch.

If copying from the `memchr` SVP64 assembler:

    (glibc-svp64)$: cp ~/src/glibc-svp64/svp64-port/svp64/memchr_svp64.s \\
                    ~/src/glibc-svp64/svp64-port/svp64/strchr_svp64.s

Modifications needed to be made:

- Change `memchr` string to `strchr`.