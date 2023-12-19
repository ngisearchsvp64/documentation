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

### Incorrect value for character **c** loaded into GPR[4]

Looking at the intial debug printout, one can see that the give byte/character
c is supposed to be `0xfe`, however the value being printed is `ffffffff`,
while the value being stored in register GPR[4] is `0xfffffffffffffffe`.

    strchr called: s: 0x7ffd93fd8ad0, c: fe(þ)
    strchr_svp64 called: s: 0x7ffd93fd8ad0, c: fe(þ)
    homeIsaDir: /home/am/src/openpower-isa/src/openpower/decoder/isa/
    bytes: 0, bytes_rem: 1
    ffffffff
    binary <_io.BytesIO object at 0x7f74e7e3f0a0>

    Memory:
    0x00100000:  FF 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|

    call ori ori
    read reg 4/0: 0xfffffffffffffffe
    read reg 8/0: 0x0
    write reg r(8, 8, 0) 0xfffffffffffffffe ew 64
    reg  0 00000000 00000000 00000000 00100000 fffffffffffffffe 00000000 00000000 00000000
    reg  8 fffffffffffffffe 00000000 00000000 00000000 00000000 00000000 00000000 00000000

Both wrapper and test C files were fixed to pass in a single byte, see
[commit](https://git.vantosh.com/ngisearch/glibc-svp64/commit/8f1b25340ee2f108027a6f50e365d42aeb7cc939).

### Wrong return value

The failed test in question is the second one in the test regression. Can be
found by searching for the second occurance of the term `Memory` (shows the
full string to be tested loaded in memory, line `#48602`), and by searching for
the first occurance of `Wrong` term (the end of the test, line `#48510`).

*(Given line numbers based on `SILENCELOG='!instr_in_outs'` value)*

Start of test:

    strchr_svp64 called: s: 0x7ff622cbd000, c: 17(^W)
    bytes: 256, bytes_rem: 0

String loaded into memory (only first 48 bytes shown):

    Memory:
    0x00100000:  20 37 4E 65 7C 93 2B 42  59 70 87 9E 36 4D 64 7B  | 7Ne|.+BYp..6Md{|
    0x00100010:  92 2A 41 58 6F 86 9D 35  4C 63 7A 91 29 40 57 6E  |.*AXo..5Lcz.)@Wn|
    0x00100020:  17 9C 34 4B 62 79 90 28  3F 56 6D 84 9B 33 4A 61  |..4Kby.(?Vm..3Ja|
    0x00100030:  ...

End of test:

    return val        : 0000000000000000
    ./test-strchr-svp64: Wrong result in function strchr_svp64 0x17 (nil) 0x7ff622cbd020

The return value should be `100020`, because that's where
the char `0x17` occurs.

After looking through the instruction listings and register values in the
results file, it was discovered that the `sv.bc` branch address was incorrect.

Place of interest starts at line `#26887`, most empty register lines ommitted).

    call mtspr mtspr
    read reg 6/0: 0x5
    reg  0 00000000 00000000 00000000 00100020 00000017 000000e0 00000005 00000004
    reg  8 1717171717171717 00000000 00000000 00000000 00100020 00100028 00100030 00100038
    reg 16 289079624b349c17 614a339b846d563f 9a836c553e278f78 543d268e77604932 00000000 00000000 00000000 00000000
    ... skip reg values ...
    call bc bc
    write reg CTR 0x4
    reg  0 00000000 00000000 00000000 00100020 00000017 000000e0 00000005 00000004
    reg  8 1717171717171717 00000000 00000000 00000000 00100020 00100028 00100030 00100038
    reg 16 289079624b349c17 614a339b846d563f 9a836c553e278f78 543d268e77604932 00000000 00000000 00000000 00000000
    ... skip reg values ...
    call subf subf
    read reg 7/0: 0x4
    read reg 6/0: 0x5
    read reg 6/0: 0x5
    write reg r(6, 6, 0) 0x1 ew 64
    reg  0 00000000 00000000 00000000 00100020 00000017 000000e0 00000001 00000004
    reg  8 1717171717171717 00000000 00000000 00000000 00100020 00100028 00100030 00100038
    reg 16 289079624b349c17 614a339b846d563f 9a836c553e278f78 543d268e77604932 00000000 00000000 00000000 00000000
    ... skip reg values ...

The `mtspr` instruction corresponds to `mfspr` (an extended mnemonic) listing,
[line #108](https://git.vantosh.com/ngisearch/glibc-svp64/src/commit/9378006a84bdef6af85eb0f810fb62fedc62c588/svp64-port/svp64/strchr_svp64.s#L108),
of the assembly code.

The correct behaviour is on a successful byte match (in this case
matches `0x17` as expected) there should be a branch to line #108, however the
simulator jumps to the `subf` (assembly using `sub` extended mnemonic), line
[line #112](https://git.vantosh.com/ngisearch/glibc-svp64/src/commit/9378006a84bdef6af85eb0f810fb62fedc62c588/svp64-port/svp64/strchr_svp64.s#L112).

Turns out I've (Andrey) forgotten to update the manual sv.bc branch address.
Due to binutils not fully supporting `sv.bc`, an incorrect branch address
is generated when a label is given in the assembly file.

For now, the branch address must be calculated manually.
The method for doing this:

1. Run the makefile to generate `strchr_svp64.o`.
2. Generate an assembly listing.

Command to do so:

    (glibc-svp64)$: powerpc64le-linux-gnu-objdump -D svp64/strchr_svp64.o > svp64/dump_strchr.txt

3. Open the file and look at where the `sv.bc` instruction starts.

The dump section in question:

    0000000000000054 <.inner>:
      54:   78 1b 6c 7c     mr      r12,r3
      ... skip instructions ...
      84:   00 20 40 05     .long 0x5402000
      88:   1c 00 02 40     bdnzf   eq,a4 <.determine_loc+0xc>
      ... skip instructions ...

    0000000000000098 <.determine_loc>:
      98:   a6 02 e9 7c     mfctr   r7
      9c:   04 00 c0 38     li      r6,4
      a0:   50 30 c7 7c     subf    r6,r7,r6
      a4:   00 00 26 2c     cmpdi   r6,0
      ... skip instructions ...

The `sv.bc` instruction starts at address `0x84`, because the prefix is
included as part of the instruction for the purpose of the relative branch
calculation.

The branch address shown by the object dump (`0xa4`) is actually 4 bytes higher
than the actual branch address taken (during simulation, the branch jumps to
where the `subf` instruction occurs, address `0xa0`.

4. Find the desired address to jump to. Looking at the object dump, this will
correspond to address `0x98`, or where the `.determine_loc` label is.

5. Calculate the offset to use by subtracting the start of `sv.bc` from the
desired address.

Calculation:

    addr_target - addr_sv.bc = 0x98 - 0x84 = 0x14

Thus the `target_address` parameter in sv.bc (last argument) needs to be
changed to `0x14`.

The code has been fixed in this
[commit](https://git.vantosh.com/ngisearch/glibc-svp64/commit/2d2c0f70dc5cca10a1c5d92d726406903f9e5b23).

The test result is now correct.