#include <asm.h>

.extern		init

.global		_boot

.section	.text

_boot:		la		t0,		__bss
			la		t1,		__bss_top
			beq		t0,		t1,			1f

0:			S		zero,	SIZE(t0)
			addi	t0,		t0,			SIZE
			bne		t0,		t1,			0b

1:			la		sp,		_stack
			j		init
