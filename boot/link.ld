SECTIONS {
    .text : {
        *(.text.head)
        *(.text*)
    }

    .data : { *(.data*) }
}
