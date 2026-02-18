.global		_start

.section	.text.head

_start:		la			t0,			first
			li			t1,			1
			amoswap.w	t1,			t1,		0(t0)
			bnez		t1,			idle

			la			t0,			_init
			csrw		stvec,		t0
			csrw		mepc,		t0

			li			t0,			(1 << 11)
			csrw		mstatus,	t0

			li			t0,			0b1111
			li			t1,			-1
			csrw		pmpcfg0,	t0
			csrw		pmpaddr0,	t1

			mret

_init:		li			t0,			0x10000000
			li			t1,			'A'
			sb			t1,			0(t0)

idle:		wfi
			j			idle

.section	.data

			.align	2
first:		.word	0
