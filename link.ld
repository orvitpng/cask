OUTPUT_FORMAT(binary)

SECTIONS {
    .blob :
    {
        *head.o(.text*);

        *(.text*);
        *(.rodata*);
        *(.data*);
    }
}
