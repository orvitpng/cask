.section .text

.include "macros.s"

.include "boot.s"
_jump    main__magic__done

.org     510
.byte    0x55 
.byte    0xaa
main__magic__done:

.include "entry.s"
