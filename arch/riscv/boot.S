#include <asm.h>

.global		_boot

.section	.text

_boot:		li			t0,			0x10000000
			la			t1,			hello
			lb			t2,			0(t1)
	0:		sb			t2,			0(t0)
			addi		t1,			t1,				1
			lb			t2,			0(t1)
			bnez		t2,			0b

	0:		wfi
			j			0b

.section	.rodata

hello:		.asciz	"Hello, world!"
