.extern		_boot

.global		_start

.section	.text

_start:		la			t0,			first
			amoswap.w	t0,			t0,		0(t0)
			bnez		t0,			idle

			la			t0,			_boot
			csrw		stvec,		t0
			csrw		mepc,		t0

			li			t0,			(1 << 11)
			csrw		mstatus,	t0

			li			t0,			0b1111
			li			t1,			-1
			csrw		pmpcfg0,	t0
			csrw		pmpaddr0,	t1

			mret

idle:		wfi
			j			idle

.section	.data

			.align	2
first:		.word	0
