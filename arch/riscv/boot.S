#include <asm.h>

.extern		start

.global		_boot

.section	.text

_boot:		la		sp,		_stack
			j		start
