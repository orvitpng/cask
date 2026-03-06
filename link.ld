SECTIONS {
    .blob :
    {
        *head.o(.text*)

        *(.text*)
        *(.rodata*)
        *(.data*)
    }

    .bss : {
        __bss = .;
        *(.bss*)
        __bss_top = .;
    }

    . = ALIGN(16);
    . += 4096;
    _stack = .;
}
