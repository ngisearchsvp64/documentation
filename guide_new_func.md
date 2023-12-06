# Guide to New SVP64 Implementation of GLIBC Function

# Glibc Repo

    (glibc-svp64)$: cd ~/src/glibc-svp64/glibc
    (glibc-svp64)$:

## Steps - strchr as an example

From glibc, copy the test C file for the respective function
into svp64-port directory.

It should be under the function category, for example, strchr is
under `string/test-strchr.c`

    (glibc-svp64)$: cp ~/src/glibc-svp64/glibc/string/test-strchr.c \\
                    ~/src/glibc-svp64/svp64-port/

### Making adjustments to `test-[function].c`

Add the following `#define`s:

    #define STRCHR_SVP64 strchr_svp64
    #define MAX_SIZE    256
    CHAR *SIMPLE_STRCHR (const CHAR *, int, size_t);
    CHAR *STRCHR_SVP64 (const CHAR *, int, size_t);
    IMPL (STRCHR_SVP64, 1)
    IMPL (SIMPLE_STRCHR, 2)

`MAX_SIZE` is set to 256 to reduce the time taken to run the regression tests.


Create a new `strchr_wrapper.c` C file which will interface with the glibc
tests and access the ISACaller PowerISA+SVP64 simulator. An existing
`[function]_wrapper.c` file can be used (in this example, `memchr`):

    (glibc-svp64)$: cp ~/src/glibc-svp64/svp64-port/memchr_wrapper.c \\
                    ~/src/glibc-svp64/svp64-port/

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
use of `n`.

- Copy `[function]_wrapper.c` and make adjustments as needed.
- 
