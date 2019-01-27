# Smart-Card-RSA

In this report the design of a digital platform is explained. The goal is to design a smart
card IC. These cards are used for identification and financial purposes, so security is key. For
this reason, smart cards contain an embedded processor and a cryptographic co-processor to
prevent abuse. To design such a digital platform, a good cooperation between integrated cir-
cuit designers and application designers is necessary. Hardware/software co-design is crucial
since there are different trade-offs to be made: 
flexibility versus performance for instance.
The different design decisions, architecture, HW/SW boundaries and interfaces are discussed
here as well as the area and speed of the platform.

# Working

The hardware and software part are clearly separated. The smart card has to be able to perform a cryptographic algorithm. This consists of multiplications of large numbers. In order to do these calculations in a small period of time,
a Montgomery multiplier is designed. The Montgomery multiplication is completely implemented in hardware. The goal is to do this with minimal area. The RSA algorithm is written in software to increase flexibility. To increase the flexibility, the modulus
is provided by the Wrapper and not hard coded in the Montgomery multiplication.
The data is transferred between both sides with a shared memory. The ARM processor
provides the numbers it wants to multiply and stores it in the shared memory i.e. BRAM.
The multiplier computes the result and sends it back to the processor using the same shared
memory. Two separate lines (P1 and P2) are used to let the other side know when a com-
putation is finished or a number is written. The multiplier needs numbers A, B and M to
perform a multiplication. Whenever the ARM processor has written a number in the BRAM,
it send the corresponding command through P1 to the multiplier. The multiplier responds
through P2 if it has read it successfully. Therefore the commands that are needed are: Read
A, Read B, Read M, Compute and Write.
