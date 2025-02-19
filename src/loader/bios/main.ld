SECTIONS
{
    . = 0x7b00;
    .text :
    {
        *(.text)
    }
    .data :
    {
        *(.data)
    }
}
