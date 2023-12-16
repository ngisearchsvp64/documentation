# Issues Discovered During Development

## Incorrect Next Instruction Address (NIA) in `sv.bc` branch instruction

* LibreSOC [bug 1210](https://bugs.libre-soc.org/show_bug.cgi?id=1210)
* LibreSOC commit which
[fixed this issue](https://git.libre-soc.org/?p=openpower-isa.git;a=commitdiff;h=d9544764b1710f3807a9c0685d150a665f70b9a2)
* LibreSOC unit test which
[demonstrated this issue](https://git.libre-soc.org/?p=openpower-isa.git;a=blob;f=src/openpower/decoder/isa/test_caller_svp64_bc.py;h=93689ded619f8fa67b455f18b122fa60220ddea1;hb=089e6d352ec57be4ab645d18ad9e95df3af0d365#l310)

The SVP64 implementation of `memchr` uses the vectorised branch conditional
instruction, `sv.bc` on
[line #67](https://git.vantosh.com/ngisearch/glibc-svp64/src/commit/1afb94889b8ea2f85844e410f87e5a9b8e2e959f/svp64-port/svp64/memchr_svp64.s#L67).

The instruction below is the SimpleV form of the normal `bc` instruction.
It works by checking a single bit in the Condition Register (CR)
(see Section 2.3.1 of Book I, PowerISA v3.0C spec for more information on CR).
The branch is taken depending on the set `BO` mode (which may also involve the
Count Register (CTR, Section 2.3.3) and the CR bit specified.

    sv.bc               0, *2, .found


Has a `BO=0` mode which means "Decrement the CTR, then branch if the
decremented CTRM:63≠0 and CRBI=0". (See Figure 40, Section 2.4 Branch
Instructions for the full list of
`BO` modes.).

CR is split into 8 4-bit CR Fields 0-7, where every 4-bits correspond to
(copied from Section 2.3.1 of PowerISA spec):

- 0: Negative (LT), The result is negative.
- 1: Positive (GT), The result is positive.
- 2: Zero (EQ), The result is zero.
- 3: Summary Overflow (SO), This is a copy of the contents of XERSO at the
completion of the instruction.

So this instruction is supposed to branch only *if*:

- CTR value after decrementing is greater than zero
- EQ bit of CR Field 0 (bit 2+32 of CR) is zero.
At every consecutive iteration of the SimpleV loop (in this case,
the SimpleV index is going up from 0 to (VL-1)), the CR Field will move up
by 1 (i.e. CR Field 0, CR bit 2+32; CR Field 1, CR bit 6+32;
CR Field 2, CR bit 10+32; CR Field 3, CR bit 14+32).

In the context of `memchr`, the branch must occur if one of the 8 bytes in
registers `s` (starts at `GPR[16]` increases up to `GPR[19]`) contains the
matching byte `c` (in `GPR[4]`).

Before LibreSOC's ISACaller simulator was fixed, the following would occur:
the CR bit will be set correctly by the compare immediate instruction `sv.cmpi`,
but during the `sv.bc` instruction, the simulator will proceed to the next
instruction address (`svstep`) instead of branching to `.found`.

### Replicating this issue

It is assumed the chroot environment has already been setup.

(Using the
[this commit](https://git.libre-soc.org/?p=openpower-isa.git;a=commitdiff;h=089e6d352ec57be4ab645d18ad9e95df3af0d365)
in `openpower-isa` repo.)

    (glibc-svp64)$: cd ~/src/openpower-isa
    (glibc-svp64)$: git checkout 089e6d352ec57be4ab645d18ad9e95df3af0d365
    (glibc-svp64)$: make

Running `make` will regenerate the necessary files for the simulator.

To run the standalone unit test written to demonstrate the issue:

    (glibc-svp64)$: cd ~/src/openpower-isa/src/openpower/decoder/isa
    (glibc-svp64)$: python3 test_caller_svp64_bc.py >& /tmp/f

The test is called `test_sv_branch_vertical_first()`. Other tests inside
`test_caller_svp64_bc.py` could be disabled by changing the `test_` prefix to
something else, and they will be ignored.

In the results file, the following message will be present:

    FAIL: test_sv_branch_vertical_first (__main__.DecoderTestCase)
    this is a branch-vertical-first-loop demo which shows an early
    ----------------------------------------------------------------------
    Traceback (most recent call last):
      File "test_caller_svp64_bc.py", line 341, in test_sv_branch_vertical_first
        self.assertEqual(sim.spr('CTR'), SelectableInt(1, 64))
    AssertionError: SelectableInt(value=0x0, bits=64) != SelectableInt(value=0x1, bits=64)

And the reason for the incorrect CTR value, is because instead of the expected
branch, another iteration of the SimpleV loop occurs, thus decrementing CTR to 0.

To run the memchr tests:

    (glibc-svp64)$: cd ~/src/glibc-svp64/svp64-port/
    (glibc-svp64)$: make clean
    (glibc-svp64)$: make all
    (glibc-svp64)$: SILENCELOG='!instr_in_outs' ./test-memchr-svp64 --direct >& /tmp/f

Searching for the first occurance of "Wrong", the following is found on
`line #31233`:

    return val        : 0000000000000000
    ./test-memchr-svp64: Wrong result in function memchr_svp64 (nil) 0x7f2abc182020

The returned value from the SVP64 implementation was 0, while the reference C
gave 0x7f2abc182020 (the correct result).

Jump to the occurance of `Memory:` which occurred before the error message
(`line #461`). The memory printout (only first 48 bytes shown):

    Memory:
    0x00100000:  01 18 2F 46 5D 74 0C 23  3A 51 68 7F 18 2E 45 5C
    0x00100010:  73 0B 22 39 50 67 7E 16  2D 44 5B 72 0A 21 38 4F
    0x00100020:  17 7D 15 2C 43 5A 71 09  20 37 4E 65 7C 14 2B 42
    0x00100030:  ...

(The simulator's memory address space is different from the native C,
but the `memchr_wrapper.c` code takes care of the conversion.)

To find where the incorrect branch occurred, search for `9715a432c157d17`
(in reverse order compared to memory print because of
Big/Little-Endian conversion). The first occurance of this value is when
the doubleword load `ld` is called. This corresponds to
[line #64](https://git.vantosh.com/ngisearch/glibc-svp64/src/commit/1afb94889b8ea2f85844e410f87e5a9b8e2e959f/svp64-port/svp64/memchr_svp64.s#L64)
of the `memchr` SVP64 assembler.

The instructions called after `ld` are:

- Compare bytes `sv.cmpb` (generates the mask 0xff because 0x17 is
the character to match for)
- Compare immediate `sv.cmpi` (sets bit 1 (GT), and clears bit 2 (EQ),
of CR Field 0)
- Branch conditional (decrements CTR, tests for bit2=0, but doesn't branch)
- SimpleV step `svstep` (branch was not taken, *this shouldn't have happened*)

### Debugging with Python debugger

Add the following lines to `caller.py` in the
`~/src/openpower-isa/src/openpower/decoder/isa/` directory.

    import pdb; pdb.set_trace() # Add at line #15
    breakpoint()                # Add at line #2361 inside the call() method

The breakpoint in `caller.py` is not necessary at first, as it will stop every
time an instruction is called (it will take a while until the above scenario
occurs).

The main place where breakpoint should be set is at
`~/src/openpower-isa/src/openpower/decoder/isa/generated/`,
in the `svbranch.py`, after line #18. This breakpoint will stop at every call
of `sv.bc`.

To run:

    (glibc-svp64)$: cd ~/src/glibc-svp64/svp64-port/
    (glibc-svp64)$: SILENCELOG='!instr_in_outs' ./test-memchr-svp64 --direct

The Python intepreter will stop at the very beginning of `caller.py`.
Enter `c` (continue). The intepreter will stop at the first instance
of `sv.bc`. Continue until the memory address in register `GPR[3]`
is equal to `00100020`.
After entering `c` another 4 times, the intepreter will stop at the call where
the branch doesn't occur. Path:
`src/openpower-isa/src/openpower/decoder/isa/generated/svbranch.py(20)op_sv_bc()`

Now the python code can be single-stepped using `n` (next) and `s` (step,
steps into functions instead of just running and returning result).
The pseudo-code for `sv.bc` can be stepped through, confirming that all the
necessary conditions for the branch occur. Compare with the pseudo-code
found in `~/src/openpower-isa/openpower/isa/svbranch.mdwn`,
[repo](https://git.libre-soc.org/?p=openpower-isa.git;a=blob;f=openpower/isa/svbranch.mdwn;h=e8b46e7700b44c6112ee2d873cc2e04b3c732370;hb=089e6d352ec57be4ab645d18ad9e95df3af0d365),
also mirrored in
[LibreSOC wiki](https://libre-soc.org/openpower/isa/svbranch/).

The generated pseudo-code function correctly updates the Next Instruction
Address (NIA), but it is later overwritten by the call to 

    yield from self.do_nia(asmop, ins_name, rc_en, ffirst_hit)

On `line #2362` of `caller.py`. For more details of the fix, please see the
LibreSOC [bug 1210](https://bugs.libre-soc.org/show_bug.cgi?id=1210).