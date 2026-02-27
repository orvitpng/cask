SECTIONS {
    .blob :
    {
        *head.o(.text*)

        *(.text*)
        *(.rodata*)
        *(.data*)
    }


    . = ALIGN(16);
    . += 4096;
    _stack = .;
}
