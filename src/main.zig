export fn _start() noreturn {
    idle();
}

fn idle() noreturn {
    while (true)
        asm volatile ("wfi");
}
