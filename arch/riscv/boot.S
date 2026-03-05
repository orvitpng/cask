#include <asm.h>

.extern		init

.global		_boot

.section	.text

_boot:		la		sp,		_stack
			j		init
