#ifndef ASM_H
#define ASM_H

#if __riscv_xlen == 32
#define SEL(a, b) a
#elif __riscv_xlen == 64
#define SEL(a, b) b
#endif

#define L SEL(lw, ld)
#define S SEL(sw, sd)

#define SIZE SEL(4, 8)

#endif
