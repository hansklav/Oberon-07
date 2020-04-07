### Hennessy benchmarks
The Hennessy or Stanford Benchmark Suite is a collection of small programs that were used in the '80s by John Hennessy & al. to compare the first (MIPS) RISC processors with CISC processors.

Originally written in Pascal they were ported to various other programming languages. Here I give two Oberon-07 implementations and a C program for easy comparison. 

Both Oberon-07 programs are essentially the same, with some minor differences: the OBNC folder has a version that is a direct translation of the C code, without nested procedures; the V5 version has nested procedures to show their relations more clearly, and a few changes specific for Oberon System V5.

Other implementations in C can be found here:
https://classes.engineering.wustl.edu/cse465/docs/BCCExamples/stanford.c
https://github.com/microsoft/test-suite/tree/master/SingleSource/Benchmarks/Stanford

The second site (part of the LLVM test-suite) also provides reference output values to ensure the right semantics of an implementation.
