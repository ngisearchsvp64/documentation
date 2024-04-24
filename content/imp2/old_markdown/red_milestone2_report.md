# NGI Search Milestone 2 Report: Red Semiconductor

# Red's goals

## Improving SimpleV spec

To check and improve LibreSOC's current SimpleV spec by finding/implementing
new features relevant to processing strings and search algorithms in general
(as part of NGI Search grant goals).

An example feature which came out of this research is
Data-Dependent Fail-First, which allows to iterate over data (in
this context, an array of byte characters) and terminate early when
a condition is met (hence "fail-first"), and shorten the specified
vector length based on this early termination. This feature is very useful
for string search and copy functions, with strncpy being an example available
in the LibreSOC [repo]() **TODO: ADD LINK**.

## SimpleV assistance to VectorCamp and VanTosh

- Provide assistance to VectorCamp and VanTosh with currently implemented
features of SimpleV.
- To find causes and/or workarounds with code bugs due to the ISACaller
simulator (the simulator supporting PowerISA 3.0 and implements current SimpleV
specification).
  - If a bug related to the simulator is found, to create a test
  case and submit a bug report to LibreSOC (see the `sv.bc` branching address
  bug in [bug #1210](https://bugs.libre-soc.org/show_bug.cgi?id=1210)
  as an example).
  - Current workarounds required due to binutils support lagging behind
  current SimpleV (due to time and effort constraints in LibreSOC):
    - Use original assembler instruction instead of extended mnemonics when
    using SimpleV `sv.` prefix. Examples of extended mnemonics are `nop`,
    `bdnz`, `subi`, etc.). Instead have to use `ori 0,0,0`, `bc 16,0,target`,
    `addi Rx,Ry,-value`.
  - sv.bc with `BO=0` (other `BO` modes weren't tested, see
  Figure 40. BO field encodings in section 2.4 of PowerISA 3.0 Book I
  for the full list), has to be given a manually computed address.

## String glibc function utilising subset of SimpleV feature set

- To write implementations of several glibc string functions utilising a subset
of the available SimpleV feature set

## Integration into the glibc test environment

and integrate them with the glibc test
cases.

VectorCamp has done the initial work of studying glibc,
creating wrapper code, and writing up an example function, `memchr()`,
for VanTosh and Red to use as a template (from which the other functions were
written up).

## Documentation

### Environment setup

### Running existing test regressions

### Creating new function implementations

### Debugging function when failures occur
