# Debugging Function Tests

## Running tests and checking if errors present

Figuring out the issue with a function is an iterative process, and may require
looking at many different files.

For this guide, `strchr` will be used (as it produced errors at the time).

To start with, run compile and run the test cases:

    (glibc-svp64)$: cd ~/src/glibc-svp64/svp64-port/
    (glibc-svp64)$: make clean
    (glibc-svp64)$: make all
    (glibc-svp64)$: SILENCELOG='!instr_in_outs' ./test-strchr-svp64 --direct >& /tmp/f

(The `'!instr_in_outs'` setting for the `SILENCELOG` environment variable
reduces the logging coming out of ISACaller, which usually isn't required for
day-to-day testing. Full logging however is useful when trying to determine if
the instruction behaviour is correct.)

The test results can be found in the temporary file `f` under `/tmp/`. The file
can be opened and inspected while the test regression is running (although it's
best to use a lightweight text editor like `vim` as the file will grow quickly).

To check if there were any failures without opening the test result file:

    (glibc-svp64)$: echo $?

The value of the `?` variable will be non-zero if there are errors. Test
regression failures are caused by a mismatch between the reference C
implementation of `strchr` and the SimpleV implementation.

Inside the result tests file for the occurance of `Wrong result in function`.
The version of `strchr_svp64` used for this example is in git commit
`#9378006a84bdef6af85eb0f810fb62fedc62c588`. SimpleV implementation
[strchr_svp64.s](https://git.vantosh.com/ngisearch/glibc-svp64/src/commit/9378006a84bdef6af85eb0f810fb62fedc62c588/svp64-port/svp64/strchr_svp64.s).
Three errors were found in the first group of tests,
[test-strchr.c#267](https://git.vantosh.com/ngisearch/glibc-svp64/src/commit/9378006a84bdef6af85eb0f810fb62fedc62c588/svp64-port/test-strchr.c#L267)

## Determining causes of errors

First test discrepancy

/test-strchr-svp64: Wrong result in function strchr_svp64 0x17 (nil) 0x7f3631b30020
strchr_svp64 called: s: 0x7f3631b30000, c: 17(^W)
bytes: 256, bytes_rem: 0
