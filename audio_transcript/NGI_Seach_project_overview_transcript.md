# Audio Transcript - SVP64 Power ISA Vector Optimisation for Search

## Introduction

Hello,

My name is Andrey, and I'm an employee of Red Semiconductor, and today I will be giving you an introduction to the project titled:
"SVP64 Power ISA Vector Optimisation for Search",
generously funded by Next Generation Internet (NGI) Search.

This project consists of a consortium of three companies represented by:

 - Red Semiconductor - Andrey Miroshnikov
 - VectorCamp - Konstantinos Margaritis
 - VanTosh - Toshaan Bharvani

## What is SVP64 and why is SVP64 relevant to NGI Search?

Simple-Vector Prefix 64-bit (SVP64) is a Cray-style vectorisation system which
turns scalar register files and scalar instructions into vector operations,
without changing their scalar behaviour. Being an orthogonal extension to the
scalar Power ISA subset, it is much smaller and easier to implement in
hardware (simplest implentation being a literal "for-loop"). SVP64 is
designed to provide the programmer with powerful mathematical operations
without requiring to add dedicated hard-IP blocks (crypto, vector unit, A/V
codecs, etc.).

As for relevance to NGI Search, it may seem like the Internet is a
Software-only enviroment, in actuality this software must run on hardware.
As a consortium, we are addressing the fundamental performance and
power-effieciency of this hardware, by verifying that low-level memory,
string, regular-expression, and Machine Learning algorithms run optimally
on SVP64.

The biggest difference between other vector extensions provided by Intel,
ARM, etc., is that if we find SVP64 to be sub-optimal, an opportunity is
provided to us by NGI Search to investigate how to actually improve the
SVP64 extension to Power ISA.

By doing this research, not only SVP64 benefits, but *everyone's* algorithms
benefit from increased performance, and reduced energy requirements.

## Who are the individual consortium members, and what are their specialisations?

  - Red Semiconductor is a fabless semiconductor company which will implement
  working Silicon deploying the SVP64 Enhancements to the Power ISA, making
  developer kits available to prospective IoT/EDGE customers, the Free and
  Open Source Software and Hardware (FOSSHW) and NGI hardware communities
  alike. SVP64 itself is a Power ISA version of the general Simple-V
  extension, initially developed by the LibreSOC project with NLnet funding.
  - VectorCamp is a provider of SIMD Vectorization and Software optimization
  and Training Services.
  - VanTosh is an Independent Software Vendor (ISV) with expertise in porting
  to the POWER platform, and a Managed Service Provider (MSP) for running
  your private cloud based multi-architecture like POWER machines, and is
  also very active in open source communities for software and hardware.

## About this project

With prior kind funding from NLnet and NGI POINTER we have established
and implemented the principles of the SVP64 Extension to the Power ISA.
This Extension is optimised to greatly simplify mathematical calculations,
providing benefits in the fields of Cryptography, Machine Learning,
Autonomous systems, Audio/Video, DSP and many other general-purpose areas.
 
The building-blocks of SVP64 are designed to provide by combination these
solutions and we are now working, with the support of NGI Search, to
establish new building-blocks to include Advanced Search capabilities,
which are also applicable to all of the above.

## What milestones have you set and how are you going about achieving them?

The three key milestones are: analysis, review and enhancement,
and recently we have completed Milestone 2. Milestone 3 is now underway.

Across the three participating organisations we have a multi-skilled
team and there will be cross-organisational cooperation on all Milestones.

## What are your goals for the middle/long-term future?

The ultimate goal is to create a progressive family of micro-processors
and this grant allows us to validate the critical elements of this
project, ensuring that the processor family is efficient at string,
data, and machine learning, as wel as provides support for standard open
source software libraries.

## How is the NGI Search money helping you?

At a fundamental level it is buying us "thinking time".
A considerable amount of time is spent to analyse and understand,
to a purpose. This purpose is the consequences for Search as
opposed to previously funded developments such as NGI POINTER,
which addressed different goals.

## How has being part of NGI Search helped you?

We have been part of the NGI Ecosystem now for five years:
NLnet (NGI Trust and Ensure), NGI POINTER and now NGI Search.
Whilst NGI Search is new and developing we expect it to be as
useful and productive as our previous interactions.

In particular we really appreciate the additional support that
comes with the NGI Family: the "added-value" activities, such
as training, sharing of ideas, and Mentoring on strategies for
Business Development.

Now I will make a brief introduction on the work done by our consortium
partners, VectorCamp and VanTosh.

## VectorCamp

VectorCamp is the official maintainer of Vectorscan, a Portable Massively
parallel Regular-Expression Matcher library. It is used extensively in
Intrusion Detection Systems software (like Snort, Suricata and others)
and Network Security Analysis in general. Originally the project was forked
from Intel’s Hyperscan but attempts to port it to ARM (originally) were not
accepted upstream. So a fork of Hyperscan was created in the form of
Vectorscan, where portability is the main focus of the project.
Now a few years later, and Vectorscan has become a popular project,
with many external contributions. It is currently heavily developed and
continuously optimized and improved.

At the time of writing it is ported
to ARM and POWER architectures. Particularly for ARM, Neon/ASIMD support
is 100% while there is ongoing work to port the code to SVE2 and
the same Fat Runtime functionality as on x86 is implemented,
so that the same binary can run and take advantage of SVE2 if available.
Furthermore, Loongson LSX support is under review and we are in progress of
porting it to even more architectures.
Now, as part of this NGI Search project, the goal is to port it to LibreSOC
and SVP64 in particular. Due to SVP64 being a Vector architecture,
and not a SIMD one, and with Vectorscan’s whole codebase designed around SIMD,
this is not such a straightforward task.

The whole codebase is tailored around SIMD intrinsics and SIMD data types to
the point that it is currently impossible to run it on an architecture that
lacks a supported SIMD unit. So, before actual SVP64 development on Vectorscan
can even begin, we have to ensure two things:

1. Vectorscan can run on a SIMD-less architecture, without rewriting
   the whole code base.
2. Vectorscan has to be adapted -at least partially at first- to make it easy
   for a single algorithm to be ported to SVP64.

Milestone 3 will continue these efforts.

## Vantosh

Vantosh had the task of researching available C libraries to be used with
custom SVP64 routines.

While several C libraries were explored, the idea of the project was and is
to be as general as possible. Several options were explored by VanTosh in an
effort to find the best available standard C library possible
for usage within the scope of this project.

In this effort and in combination with other work that is relevant to
the project, we ended up chosing “glibc”. We provide an insight to several
standard C libraries we explored and tested with some feedback. Full details
can be found in our Milestone 2 report.

As for Milestone 3, the goal is to continue working on several string and
memory routines to leverage the capabilities of SVP64, and demonstrate intergration with glibc test framework.

Again, we would to thank NGI Search for their generous support for
this project, and we hope that the final research will be useful to individuals
and projects in the future.
