SECTIONS {
    .text : {
        */boot.o(.text*)
        *(.text*)
    }

    .data : { *(.data*) }
}
