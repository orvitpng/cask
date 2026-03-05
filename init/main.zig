const uart: *volatile u8 = @ptrFromInt(0x10000000);

const str = "Hello, world!\n";

export fn init() noreturn {
    for (str) |char|
        uart.* = char;
    idle();
}

fn idle() noreturn {
    while (true)
        asm volatile ("wfi");
}
