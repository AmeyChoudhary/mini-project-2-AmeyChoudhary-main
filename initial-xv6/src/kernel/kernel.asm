
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	addi	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	89e70713          	addi	a4,a4,-1890 # 800088f0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	24c78793          	addi	a5,a5,588 # 800062b0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbc9f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	488080e7          	jalr	1160(ra) # 800025b4 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	8a450513          	addi	a0,a0,-1884 # 80010a30 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	89448493          	addi	s1,s1,-1900 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	92290913          	addi	s2,s2,-1758 # 80010ac8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	232080e7          	jalr	562(ra) # 800023fe <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	f40080e7          	jalr	-192(ra) # 8000211a <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	348080e7          	jalr	840(ra) # 8000255e <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	80650513          	addi	a0,a0,-2042 # 80010a30 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00010517          	auipc	a0,0x10
    80000244:	7f050513          	addi	a0,a0,2032 # 80010a30 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	84f72823          	sw	a5,-1968(a4) # 80010ac8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	75e50513          	addi	a0,a0,1886 # 80010a30 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	312080e7          	jalr	786(ra) # 8000260a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	73050513          	addi	a0,a0,1840 # 80010a30 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	70c70713          	addi	a4,a4,1804 # 80010a30 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	6e278793          	addi	a5,a5,1762 # 80010a30 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	74c7a783          	lw	a5,1868(a5) # 80010ac8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	6a070713          	addi	a4,a4,1696 # 80010a30 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	69048493          	addi	s1,s1,1680 # 80010a30 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	65470713          	addi	a4,a4,1620 # 80010a30 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	6cf72f23          	sw	a5,1758(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	61878793          	addi	a5,a5,1560 # 80010a30 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	68c7a823          	sw	a2,1680(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	68450513          	addi	a0,a0,1668 # 80010ac8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	d32080e7          	jalr	-718(ra) # 8000217e <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	5ca50513          	addi	a0,a0,1482 # 80010a30 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	54a78793          	addi	a5,a5,1354 # 800219c8 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5a07a023          	sw	zero,1440(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	32f72623          	sw	a5,812(a4) # 800088b0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	530dad83          	lw	s11,1328(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	4da50513          	addi	a0,a0,1242 # 80010ad8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	37650513          	addi	a0,a0,886 # 80010ad8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	35a48493          	addi	s1,s1,858 # 80010ad8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	31a50513          	addi	a0,a0,794 # 80010af8 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0a67a783          	lw	a5,166(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	07273703          	ld	a4,114(a4) # 800088b8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0727b783          	ld	a5,114(a5) # 800088c0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	288a0a13          	addi	s4,s4,648 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	04048493          	addi	s1,s1,64 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	04098993          	addi	s3,s3,64 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	8d8080e7          	jalr	-1832(ra) # 8000217e <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	21650513          	addi	a0,a0,534 # 80010af8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fbe7a783          	lw	a5,-66(a5) # 800088b0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	fc47b783          	ld	a5,-60(a5) # 800088c0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	fb473703          	ld	a4,-76(a4) # 800088b8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	1e8a0a13          	addi	s4,s4,488 # 80010af8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	fa048493          	addi	s1,s1,-96 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	fa090913          	addi	s2,s2,-96 # 800088c0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	7ea080e7          	jalr	2026(ra) # 8000211a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	1b248493          	addi	s1,s1,434 # 80010af8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f6f73323          	sd	a5,-154(a4) # 800088c0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	12848493          	addi	s1,s1,296 # 80010af8 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00022797          	auipc	a5,0x22
    80000a16:	14e78793          	addi	a5,a5,334 # 80022b60 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	0fe90913          	addi	s2,s2,254 # 80010b30 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	06250513          	addi	a0,a0,98 # 80010b30 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00022517          	auipc	a0,0x22
    80000ae6:	07e50513          	addi	a0,a0,126 # 80022b60 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	02c48493          	addi	s1,s1,44 # 80010b30 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	01450513          	addi	a0,a0,20 # 80010b30 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	fe850513          	addi	a0,a0,-24 # 80010b30 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	a2470713          	addi	a4,a4,-1500 # 800088c8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	a1a080e7          	jalr	-1510(ra) # 800028f4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	40e080e7          	jalr	1038(ra) # 800062f0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	010080e7          	jalr	16(ra) # 80001efa <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	97a080e7          	jalr	-1670(ra) # 800028cc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	99a080e7          	jalr	-1638(ra) # 800028f4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	378080e7          	jalr	888(ra) # 800062da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	386080e7          	jalr	902(ra) # 800062f0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	518080e7          	jalr	1304(ra) # 8000348a <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	bbc080e7          	jalr	-1092(ra) # 80003b36 <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	b5a080e7          	jalr	-1190(ra) # 80004adc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	46e080e7          	jalr	1134(ra) # 800063f8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d4e080e7          	jalr	-690(ra) # 80001ce0 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	92f72423          	sw	a5,-1752(a4) # 800088c8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	91c7b783          	ld	a5,-1764(a5) # 800088d0 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00007797          	auipc	a5,0x7
    80001274:	66a7b023          	sd	a0,1632(a5) # 800088d0 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	0000f497          	auipc	s1,0xf
    8000186a:	71a48493          	addi	s1,s1,1818 # 80010f80 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001880:	00016a17          	auipc	s4,0x16
    80001884:	f00a0a13          	addi	s4,s4,-256 # 80017780 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if (pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	8595                	srai	a1,a1,0x5
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018ba:	1a048493          	addi	s1,s1,416
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	24e50513          	addi	a0,a0,590 # 80010b50 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	24e50513          	addi	a0,a0,590 # 80010b68 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000192a:	0000f497          	auipc	s1,0xf
    8000192e:	65648493          	addi	s1,s1,1622 # 80010f80 <proc>
  {
    initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000194c:	00016997          	auipc	s3,0x16
    80001950:	e3498993          	addi	s3,s3,-460 # 80017780 <tickslock>
    initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
    p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	8795                	srai	a5,a5,0x5
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000197e:	1a048493          	addi	s1,s1,416
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	1ca50513          	addi	a0,a0,458 # 80010b80 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	17270713          	addi	a4,a4,370 # 80010b50 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first)
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e4a7a783          	lw	a5,-438(a5) # 80008860 <first.1699>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	eec080e7          	jalr	-276(ra) # 8000290c <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e207a823          	sw	zero,-464(a5) # 80008860 <first.1699>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	07c080e7          	jalr	124(ra) # 80003ab6 <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	10090913          	addi	s2,s2,256 # 80010b50 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	e0278793          	addi	a5,a5,-510 # 80008864 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b94:	68a8                	ld	a0,80(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	64ac                	ld	a1,72(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	3a448493          	addi	s1,s1,932 # 80010f80 <proc>
    80001be4:	00016917          	auipc	s2,0x16
    80001be8:	b9c90913          	addi	s2,s2,-1124 # 80017780 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if (p->state == UNUSED)
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c04:	1a048493          	addi	s1,s1,416
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a851                	j	80001ca2 <allocproc+0xd2>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  p->is_sigalarm = 0;
    80001c1e:	1604aa23          	sw	zero,372(s1)
  p->ticks = 0;
    80001c22:	1604ae23          	sw	zero,380(s1)
  p->alarm_handler = 0;
    80001c26:	1804b023          	sd	zero,384(s1)
  p->time_called_at = 0;
    80001c2a:	1604ac23          	sw	zero,376(s1)
  p->ctime = ticks;
    80001c2e:	00007797          	auipc	a5,0x7
    80001c32:	cb27a783          	lw	a5,-846(a5) # 800088e0 <ticks>
    80001c36:	16f4a623          	sw	a5,364(s1)
  p->current_queue = 0;
    80001c3a:	1804a823          	sw	zero,400(s1)
  p->entry_time_in_queue = ticks;
    80001c3e:	2781                	sext.w	a5,a5
    80001c40:	18f4aa23          	sw	a5,404(s1)
  p->last_time_run_in_queue = ticks;
    80001c44:	18f4ac23          	sw	a5,408(s1)
  p->run_time_in_queue = 0;
    80001c48:	1804ae23          	sw	zero,412(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	eae080e7          	jalr	-338(ra) # 80000afa <kalloc>
    80001c54:	892a                	mv	s2,a0
    80001c56:	eca8                	sd	a0,88(s1)
    80001c58:	cd21                	beqz	a0,80001cb0 <allocproc+0xe0>
  p->pagetable = proc_pagetable(p);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	e2e080e7          	jalr	-466(ra) # 80001a8a <proc_pagetable>
    80001c64:	892a                	mv	s2,a0
    80001c66:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c68:	c125                	beqz	a0,80001cc8 <allocproc+0xf8>
  memset(&p->context, 0, sizeof(p->context));
    80001c6a:	07000613          	li	a2,112
    80001c6e:	4581                	li	a1,0
    80001c70:	06048513          	addi	a0,s1,96
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	072080e7          	jalr	114(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c7c:	00000797          	auipc	a5,0x0
    80001c80:	d8278793          	addi	a5,a5,-638 # 800019fe <forkret>
    80001c84:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c86:	60bc                	ld	a5,64(s1)
    80001c88:	6705                	lui	a4,0x1
    80001c8a:	97ba                	add	a5,a5,a4
    80001c8c:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c8e:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c92:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c96:	00007797          	auipc	a5,0x7
    80001c9a:	c4a7a783          	lw	a5,-950(a5) # 800088e0 <ticks>
    80001c9e:	16f4a623          	sw	a5,364(s1)
}
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	60e2                	ld	ra,24(sp)
    80001ca6:	6442                	ld	s0,16(sp)
    80001ca8:	64a2                	ld	s1,8(sp)
    80001caa:	6902                	ld	s2,0(sp)
    80001cac:	6105                	addi	sp,sp,32
    80001cae:	8082                	ret
    freeproc(p);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	ec6080e7          	jalr	-314(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	fe2080e7          	jalr	-30(ra) # 80000c9e <release>
    return 0;
    80001cc4:	84ca                	mv	s1,s2
    80001cc6:	bff1                	j	80001ca2 <allocproc+0xd2>
    freeproc(p);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	eae080e7          	jalr	-338(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	fca080e7          	jalr	-54(ra) # 80000c9e <release>
    return 0;
    80001cdc:	84ca                	mv	s1,s2
    80001cde:	b7d1                	j	80001ca2 <allocproc+0xd2>

0000000080001ce0 <userinit>:
{
    80001ce0:	1101                	addi	sp,sp,-32
    80001ce2:	ec06                	sd	ra,24(sp)
    80001ce4:	e822                	sd	s0,16(sp)
    80001ce6:	e426                	sd	s1,8(sp)
    80001ce8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cea:	00000097          	auipc	ra,0x0
    80001cee:	ee6080e7          	jalr	-282(ra) # 80001bd0 <allocproc>
    80001cf2:	84aa                	mv	s1,a0
  initproc = p;
    80001cf4:	00007797          	auipc	a5,0x7
    80001cf8:	bea7b223          	sd	a0,-1052(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cfc:	03400613          	li	a2,52
    80001d00:	00007597          	auipc	a1,0x7
    80001d04:	b7058593          	addi	a1,a1,-1168 # 80008870 <initcode>
    80001d08:	6928                	ld	a0,80(a0)
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	668080e7          	jalr	1640(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001d12:	6785                	lui	a5,0x1
    80001d14:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d16:	6cb8                	ld	a4,88(s1)
    80001d18:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d1c:	6cb8                	ld	a4,88(s1)
    80001d1e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d20:	4641                	li	a2,16
    80001d22:	00006597          	auipc	a1,0x6
    80001d26:	4de58593          	addi	a1,a1,1246 # 80008200 <digits+0x1c0>
    80001d2a:	15848513          	addi	a0,s1,344
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	10a080e7          	jalr	266(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d36:	00006517          	auipc	a0,0x6
    80001d3a:	4da50513          	addi	a0,a0,1242 # 80008210 <digits+0x1d0>
    80001d3e:	00002097          	auipc	ra,0x2
    80001d42:	79a080e7          	jalr	1946(ra) # 800044d8 <namei>
    80001d46:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d4a:	478d                	li	a5,3
    80001d4c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d4e:	8526                	mv	a0,s1
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	f4e080e7          	jalr	-178(ra) # 80000c9e <release>
}
    80001d58:	60e2                	ld	ra,24(sp)
    80001d5a:	6442                	ld	s0,16(sp)
    80001d5c:	64a2                	ld	s1,8(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret

0000000080001d62 <growproc>:
{
    80001d62:	1101                	addi	sp,sp,-32
    80001d64:	ec06                	sd	ra,24(sp)
    80001d66:	e822                	sd	s0,16(sp)
    80001d68:	e426                	sd	s1,8(sp)
    80001d6a:	e04a                	sd	s2,0(sp)
    80001d6c:	1000                	addi	s0,sp,32
    80001d6e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d70:	00000097          	auipc	ra,0x0
    80001d74:	c56080e7          	jalr	-938(ra) # 800019c6 <myproc>
    80001d78:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d7a:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d7c:	01204c63          	bgtz	s2,80001d94 <growproc+0x32>
  else if (n < 0)
    80001d80:	02094663          	bltz	s2,80001dac <growproc+0x4a>
  p->sz = sz;
    80001d84:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d86:	4501                	li	a0,0
}
    80001d88:	60e2                	ld	ra,24(sp)
    80001d8a:	6442                	ld	s0,16(sp)
    80001d8c:	64a2                	ld	s1,8(sp)
    80001d8e:	6902                	ld	s2,0(sp)
    80001d90:	6105                	addi	sp,sp,32
    80001d92:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d94:	4691                	li	a3,4
    80001d96:	00b90633          	add	a2,s2,a1
    80001d9a:	6928                	ld	a0,80(a0)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	690080e7          	jalr	1680(ra) # 8000142c <uvmalloc>
    80001da4:	85aa                	mv	a1,a0
    80001da6:	fd79                	bnez	a0,80001d84 <growproc+0x22>
      return -1;
    80001da8:	557d                	li	a0,-1
    80001daa:	bff9                	j	80001d88 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dac:	00b90633          	add	a2,s2,a1
    80001db0:	6928                	ld	a0,80(a0)
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	632080e7          	jalr	1586(ra) # 800013e4 <uvmdealloc>
    80001dba:	85aa                	mv	a1,a0
    80001dbc:	b7e1                	j	80001d84 <growproc+0x22>

0000000080001dbe <fork>:
{
    80001dbe:	7179                	addi	sp,sp,-48
    80001dc0:	f406                	sd	ra,40(sp)
    80001dc2:	f022                	sd	s0,32(sp)
    80001dc4:	ec26                	sd	s1,24(sp)
    80001dc6:	e84a                	sd	s2,16(sp)
    80001dc8:	e44e                	sd	s3,8(sp)
    80001dca:	e052                	sd	s4,0(sp)
    80001dcc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	bf8080e7          	jalr	-1032(ra) # 800019c6 <myproc>
    80001dd6:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	df8080e7          	jalr	-520(ra) # 80001bd0 <allocproc>
    80001de0:	10050b63          	beqz	a0,80001ef6 <fork+0x138>
    80001de4:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001de6:	04893603          	ld	a2,72(s2)
    80001dea:	692c                	ld	a1,80(a0)
    80001dec:	05093503          	ld	a0,80(s2)
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	790080e7          	jalr	1936(ra) # 80001580 <uvmcopy>
    80001df8:	04054663          	bltz	a0,80001e44 <fork+0x86>
  np->sz = p->sz;
    80001dfc:	04893783          	ld	a5,72(s2)
    80001e00:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e04:	05893683          	ld	a3,88(s2)
    80001e08:	87b6                	mv	a5,a3
    80001e0a:	0589b703          	ld	a4,88(s3)
    80001e0e:	12068693          	addi	a3,a3,288
    80001e12:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e16:	6788                	ld	a0,8(a5)
    80001e18:	6b8c                	ld	a1,16(a5)
    80001e1a:	6f90                	ld	a2,24(a5)
    80001e1c:	01073023          	sd	a6,0(a4)
    80001e20:	e708                	sd	a0,8(a4)
    80001e22:	eb0c                	sd	a1,16(a4)
    80001e24:	ef10                	sd	a2,24(a4)
    80001e26:	02078793          	addi	a5,a5,32
    80001e2a:	02070713          	addi	a4,a4,32
    80001e2e:	fed792e3          	bne	a5,a3,80001e12 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e32:	0589b783          	ld	a5,88(s3)
    80001e36:	0607b823          	sd	zero,112(a5)
    80001e3a:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001e3e:	15000a13          	li	s4,336
    80001e42:	a03d                	j	80001e70 <fork+0xb2>
    freeproc(np);
    80001e44:	854e                	mv	a0,s3
    80001e46:	00000097          	auipc	ra,0x0
    80001e4a:	d32080e7          	jalr	-718(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e4e:	854e                	mv	a0,s3
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	e4e080e7          	jalr	-434(ra) # 80000c9e <release>
    return -1;
    80001e58:	5a7d                	li	s4,-1
    80001e5a:	a069                	j	80001ee4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5c:	00003097          	auipc	ra,0x3
    80001e60:	d12080e7          	jalr	-750(ra) # 80004b6e <filedup>
    80001e64:	009987b3          	add	a5,s3,s1
    80001e68:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e6a:	04a1                	addi	s1,s1,8
    80001e6c:	01448763          	beq	s1,s4,80001e7a <fork+0xbc>
    if (p->ofile[i])
    80001e70:	009907b3          	add	a5,s2,s1
    80001e74:	6388                	ld	a0,0(a5)
    80001e76:	f17d                	bnez	a0,80001e5c <fork+0x9e>
    80001e78:	bfcd                	j	80001e6a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e7a:	15093503          	ld	a0,336(s2)
    80001e7e:	00002097          	auipc	ra,0x2
    80001e82:	e76080e7          	jalr	-394(ra) # 80003cf4 <idup>
    80001e86:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e8a:	4641                	li	a2,16
    80001e8c:	15890593          	addi	a1,s2,344
    80001e90:	15898513          	addi	a0,s3,344
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	fa4080e7          	jalr	-92(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e9c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ea0:	854e                	mv	a0,s3
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	dfc080e7          	jalr	-516(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001eaa:	0000f497          	auipc	s1,0xf
    80001eae:	cbe48493          	addi	s1,s1,-834 # 80010b68 <wait_lock>
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	d36080e7          	jalr	-714(ra) # 80000bea <acquire>
  np->parent = p;
    80001ebc:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	ddc080e7          	jalr	-548(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001eca:	854e                	mv	a0,s3
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	d1e080e7          	jalr	-738(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001ed4:	478d                	li	a5,3
    80001ed6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eda:	854e                	mv	a0,s3
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	dc2080e7          	jalr	-574(ra) # 80000c9e <release>
}
    80001ee4:	8552                	mv	a0,s4
    80001ee6:	70a2                	ld	ra,40(sp)
    80001ee8:	7402                	ld	s0,32(sp)
    80001eea:	64e2                	ld	s1,24(sp)
    80001eec:	6942                	ld	s2,16(sp)
    80001eee:	69a2                	ld	s3,8(sp)
    80001ef0:	6a02                	ld	s4,0(sp)
    80001ef2:	6145                	addi	sp,sp,48
    80001ef4:	8082                	ret
    return -1;
    80001ef6:	5a7d                	li	s4,-1
    80001ef8:	b7f5                	j	80001ee4 <fork+0x126>

0000000080001efa <scheduler>:
{
    80001efa:	715d                	addi	sp,sp,-80
    80001efc:	e486                	sd	ra,72(sp)
    80001efe:	e0a2                	sd	s0,64(sp)
    80001f00:	fc26                	sd	s1,56(sp)
    80001f02:	f84a                	sd	s2,48(sp)
    80001f04:	f44e                	sd	s3,40(sp)
    80001f06:	f052                	sd	s4,32(sp)
    80001f08:	ec56                	sd	s5,24(sp)
    80001f0a:	e85a                	sd	s6,16(sp)
    80001f0c:	e45e                	sd	s7,8(sp)
    80001f0e:	e062                	sd	s8,0(sp)
    80001f10:	0880                	addi	s0,sp,80
    80001f12:	8792                	mv	a5,tp
  int id = r_tp();
    80001f14:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f16:	00779693          	slli	a3,a5,0x7
    80001f1a:	0000f717          	auipc	a4,0xf
    80001f1e:	c3670713          	addi	a4,a4,-970 # 80010b50 <pid_lock>
    80001f22:	9736                	add	a4,a4,a3
    80001f24:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &min_proc->context);
    80001f28:	0000f717          	auipc	a4,0xf
    80001f2c:	c6070713          	addi	a4,a4,-928 # 80010b88 <cpus+0x8>
    80001f30:	00e68c33          	add	s8,a3,a4
      if (p->state == RUNNABLE)
    80001f34:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    80001f36:	00016a17          	auipc	s4,0x16
    80001f3a:	84aa0a13          	addi	s4,s4,-1974 # 80017780 <tickslock>
    struct proc *min_proc = 0;
    80001f3e:	4b01                	li	s6,0
        c->proc = min_proc;
    80001f40:	0000fb97          	auipc	s7,0xf
    80001f44:	c10b8b93          	addi	s7,s7,-1008 # 80010b50 <pid_lock>
    80001f48:	9bb6                	add	s7,s7,a3
    80001f4a:	a05d                	j	80001ff0 <scheduler+0xf6>
        if (min_proc == 0)
    80001f4c:	060a8063          	beqz	s5,80001fac <scheduler+0xb2>
        else if (p->current_queue < min_proc->current_queue)
    80001f50:	1904a703          	lw	a4,400(s1)
    80001f54:	190aa783          	lw	a5,400(s5)
    80001f58:	04f74c63          	blt	a4,a5,80001fb0 <scheduler+0xb6>
        else if (p->current_queue == min_proc->current_queue)
    80001f5c:	04f71b63          	bne	a4,a5,80001fb2 <scheduler+0xb8>
          if (p->entry_time_in_queue < min_proc->entry_time_in_queue)
    80001f60:	1944a703          	lw	a4,404(s1)
    80001f64:	194aa783          	lw	a5,404(s5)
    80001f68:	04f75563          	bge	a4,a5,80001fb2 <scheduler+0xb8>
    80001f6c:	8aa6                	mv	s5,s1
    80001f6e:	a091                	j	80001fb2 <scheduler+0xb8>
      acquire(&min_proc->lock);
    80001f70:	84d6                	mv	s1,s5
    80001f72:	8556                	mv	a0,s5
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	c76080e7          	jalr	-906(ra) # 80000bea <acquire>
      if (min_proc->state == RUNNABLE)
    80001f7c:	018aa783          	lw	a5,24(s5)
    80001f80:	03379063          	bne	a5,s3,80001fa0 <scheduler+0xa6>
        min_proc->state = RUNNING;
    80001f84:	4791                	li	a5,4
    80001f86:	00faac23          	sw	a5,24(s5)
        c->proc = min_proc;
    80001f8a:	035bb823          	sd	s5,48(s7)
        swtch(&c->context, &min_proc->context);
    80001f8e:	060a8593          	addi	a1,s5,96
    80001f92:	8562                	mv	a0,s8
    80001f94:	00001097          	auipc	ra,0x1
    80001f98:	8ce080e7          	jalr	-1842(ra) # 80002862 <swtch>
        c->proc = 0;
    80001f9c:	020bb823          	sd	zero,48(s7)
      release(&min_proc->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	cfc080e7          	jalr	-772(ra) # 80000c9e <release>
    80001faa:	a099                	j	80001ff0 <scheduler+0xf6>
    80001fac:	8aa6                	mv	s5,s1
    80001fae:	a011                	j	80001fb2 <scheduler+0xb8>
    80001fb0:	8aa6                	mv	s5,s1
      release(&p->lock);
    80001fb2:	854a                	mv	a0,s2
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	cea080e7          	jalr	-790(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fbc:	1a048793          	addi	a5,s1,416
    80001fc0:	fb47f8e3          	bgeu	a5,s4,80001f70 <scheduler+0x76>
    80001fc4:	1a048493          	addi	s1,s1,416
    80001fc8:	8926                	mv	s2,s1
      acquire(&p->lock);
    80001fca:	8526                	mv	a0,s1
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	c1e080e7          	jalr	-994(ra) # 80000bea <acquire>
      if (p->state == RUNNABLE)
    80001fd4:	4c9c                	lw	a5,24(s1)
    80001fd6:	f7378be3          	beq	a5,s3,80001f4c <scheduler+0x52>
      release(&p->lock);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	cc2080e7          	jalr	-830(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fe4:	1a048793          	addi	a5,s1,416
    80001fe8:	fd47eee3          	bltu	a5,s4,80001fc4 <scheduler+0xca>
    if (min_proc != 0)
    80001fec:	f80a92e3          	bnez	s5,80001f70 <scheduler+0x76>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff8:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001ffc:	0000f497          	auipc	s1,0xf
    80002000:	f8448493          	addi	s1,s1,-124 # 80010f80 <proc>
    struct proc *min_proc = 0;
    80002004:	8ada                	mv	s5,s6
    80002006:	b7c9                	j	80001fc8 <scheduler+0xce>

0000000080002008 <sched>:
{
    80002008:	7179                	addi	sp,sp,-48
    8000200a:	f406                	sd	ra,40(sp)
    8000200c:	f022                	sd	s0,32(sp)
    8000200e:	ec26                	sd	s1,24(sp)
    80002010:	e84a                	sd	s2,16(sp)
    80002012:	e44e                	sd	s3,8(sp)
    80002014:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	9b0080e7          	jalr	-1616(ra) # 800019c6 <myproc>
    8000201e:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	b50080e7          	jalr	-1200(ra) # 80000b70 <holding>
    80002028:	c93d                	beqz	a0,8000209e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000202a:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000202c:	2781                	sext.w	a5,a5
    8000202e:	079e                	slli	a5,a5,0x7
    80002030:	0000f717          	auipc	a4,0xf
    80002034:	b2070713          	addi	a4,a4,-1248 # 80010b50 <pid_lock>
    80002038:	97ba                	add	a5,a5,a4
    8000203a:	0a87a703          	lw	a4,168(a5)
    8000203e:	4785                	li	a5,1
    80002040:	06f71763          	bne	a4,a5,800020ae <sched+0xa6>
  if (p->state == RUNNING)
    80002044:	4c98                	lw	a4,24(s1)
    80002046:	4791                	li	a5,4
    80002048:	06f70b63          	beq	a4,a5,800020be <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000204c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002050:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002052:	efb5                	bnez	a5,800020ce <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002054:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002056:	0000f917          	auipc	s2,0xf
    8000205a:	afa90913          	addi	s2,s2,-1286 # 80010b50 <pid_lock>
    8000205e:	2781                	sext.w	a5,a5
    80002060:	079e                	slli	a5,a5,0x7
    80002062:	97ca                	add	a5,a5,s2
    80002064:	0ac7a983          	lw	s3,172(a5)
    80002068:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000206a:	2781                	sext.w	a5,a5
    8000206c:	079e                	slli	a5,a5,0x7
    8000206e:	0000f597          	auipc	a1,0xf
    80002072:	b1a58593          	addi	a1,a1,-1254 # 80010b88 <cpus+0x8>
    80002076:	95be                	add	a1,a1,a5
    80002078:	06048513          	addi	a0,s1,96
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	7e6080e7          	jalr	2022(ra) # 80002862 <swtch>
    80002084:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002086:	2781                	sext.w	a5,a5
    80002088:	079e                	slli	a5,a5,0x7
    8000208a:	97ca                	add	a5,a5,s2
    8000208c:	0b37a623          	sw	s3,172(a5)
}
    80002090:	70a2                	ld	ra,40(sp)
    80002092:	7402                	ld	s0,32(sp)
    80002094:	64e2                	ld	s1,24(sp)
    80002096:	6942                	ld	s2,16(sp)
    80002098:	69a2                	ld	s3,8(sp)
    8000209a:	6145                	addi	sp,sp,48
    8000209c:	8082                	ret
    panic("sched p->lock");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	17a50513          	addi	a0,a0,378 # 80008218 <digits+0x1d8>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	49e080e7          	jalr	1182(ra) # 80000544 <panic>
    panic("sched locks");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	17a50513          	addi	a0,a0,378 # 80008228 <digits+0x1e8>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48e080e7          	jalr	1166(ra) # 80000544 <panic>
    panic("sched running");
    800020be:	00006517          	auipc	a0,0x6
    800020c2:	17a50513          	addi	a0,a0,378 # 80008238 <digits+0x1f8>
    800020c6:	ffffe097          	auipc	ra,0xffffe
    800020ca:	47e080e7          	jalr	1150(ra) # 80000544 <panic>
    panic("sched interruptible");
    800020ce:	00006517          	auipc	a0,0x6
    800020d2:	17a50513          	addi	a0,a0,378 # 80008248 <digits+0x208>
    800020d6:	ffffe097          	auipc	ra,0xffffe
    800020da:	46e080e7          	jalr	1134(ra) # 80000544 <panic>

00000000800020de <yield>:
{
    800020de:	1101                	addi	sp,sp,-32
    800020e0:	ec06                	sd	ra,24(sp)
    800020e2:	e822                	sd	s0,16(sp)
    800020e4:	e426                	sd	s1,8(sp)
    800020e6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020e8:	00000097          	auipc	ra,0x0
    800020ec:	8de080e7          	jalr	-1826(ra) # 800019c6 <myproc>
    800020f0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	af8080e7          	jalr	-1288(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800020fa:	478d                	li	a5,3
    800020fc:	cc9c                	sw	a5,24(s1)
  sched();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	f0a080e7          	jalr	-246(ra) # 80002008 <sched>
  release(&p->lock);
    80002106:	8526                	mv	a0,s1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	b96080e7          	jalr	-1130(ra) # 80000c9e <release>
}
    80002110:	60e2                	ld	ra,24(sp)
    80002112:	6442                	ld	s0,16(sp)
    80002114:	64a2                	ld	s1,8(sp)
    80002116:	6105                	addi	sp,sp,32
    80002118:	8082                	ret

000000008000211a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000211a:	7179                	addi	sp,sp,-48
    8000211c:	f406                	sd	ra,40(sp)
    8000211e:	f022                	sd	s0,32(sp)
    80002120:	ec26                	sd	s1,24(sp)
    80002122:	e84a                	sd	s2,16(sp)
    80002124:	e44e                	sd	s3,8(sp)
    80002126:	1800                	addi	s0,sp,48
    80002128:	89aa                	mv	s3,a0
    8000212a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000212c:	00000097          	auipc	ra,0x0
    80002130:	89a080e7          	jalr	-1894(ra) # 800019c6 <myproc>
    80002134:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	ab4080e7          	jalr	-1356(ra) # 80000bea <acquire>
  release(lk);
    8000213e:	854a                	mv	a0,s2
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b5e080e7          	jalr	-1186(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002148:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000214c:	4789                	li	a5,2
    8000214e:	cc9c                	sw	a5,24(s1)

  sched();
    80002150:	00000097          	auipc	ra,0x0
    80002154:	eb8080e7          	jalr	-328(ra) # 80002008 <sched>

  // Tidy up.
  p->chan = 0;
    80002158:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000215c:	8526                	mv	a0,s1
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	b40080e7          	jalr	-1216(ra) # 80000c9e <release>
  acquire(lk);
    80002166:	854a                	mv	a0,s2
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	a82080e7          	jalr	-1406(ra) # 80000bea <acquire>
}
    80002170:	70a2                	ld	ra,40(sp)
    80002172:	7402                	ld	s0,32(sp)
    80002174:	64e2                	ld	s1,24(sp)
    80002176:	6942                	ld	s2,16(sp)
    80002178:	69a2                	ld	s3,8(sp)
    8000217a:	6145                	addi	sp,sp,48
    8000217c:	8082                	ret

000000008000217e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000217e:	7139                	addi	sp,sp,-64
    80002180:	fc06                	sd	ra,56(sp)
    80002182:	f822                	sd	s0,48(sp)
    80002184:	f426                	sd	s1,40(sp)
    80002186:	f04a                	sd	s2,32(sp)
    80002188:	ec4e                	sd	s3,24(sp)
    8000218a:	e852                	sd	s4,16(sp)
    8000218c:	e456                	sd	s5,8(sp)
    8000218e:	e05a                	sd	s6,0(sp)
    80002190:	0080                	addi	s0,sp,64
    80002192:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002194:	0000f497          	auipc	s1,0xf
    80002198:	dec48493          	addi	s1,s1,-532 # 80010f80 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000219c:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000219e:	4b0d                	li	s6,3
#ifdef MLFQ
        p->run_time_in_queue = 0;
        p->entry_time_in_queue = ticks;
    800021a0:	00006a97          	auipc	s5,0x6
    800021a4:	740a8a93          	addi	s5,s5,1856 # 800088e0 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    800021a8:	00015917          	auipc	s2,0x15
    800021ac:	5d890913          	addi	s2,s2,1496 # 80017780 <tickslock>
    800021b0:	a025                	j	800021d8 <wakeup+0x5a>
        p->state = RUNNABLE;
    800021b2:	0164ac23          	sw	s6,24(s1)
        p->run_time_in_queue = 0;
    800021b6:	1804ae23          	sw	zero,412(s1)
        p->entry_time_in_queue = ticks;
    800021ba:	000aa783          	lw	a5,0(s5)
    800021be:	18f4aa23          	sw	a5,404(s1)
        p->last_time_run_in_queue = ticks;
    800021c2:	18f4ac23          	sw	a5,408(s1)
#endif
      }
      release(&p->lock);
    800021c6:	8526                	mv	a0,s1
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	ad6080e7          	jalr	-1322(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800021d0:	1a048493          	addi	s1,s1,416
    800021d4:	03248463          	beq	s1,s2,800021fc <wakeup+0x7e>
    if (p != myproc())
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	7ee080e7          	jalr	2030(ra) # 800019c6 <myproc>
    800021e0:	fea488e3          	beq	s1,a0,800021d0 <wakeup+0x52>
      acquire(&p->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	a04080e7          	jalr	-1532(ra) # 80000bea <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800021ee:	4c9c                	lw	a5,24(s1)
    800021f0:	fd379be3          	bne	a5,s3,800021c6 <wakeup+0x48>
    800021f4:	709c                	ld	a5,32(s1)
    800021f6:	fd4798e3          	bne	a5,s4,800021c6 <wakeup+0x48>
    800021fa:	bf65                	j	800021b2 <wakeup+0x34>
    }
  }
}
    800021fc:	70e2                	ld	ra,56(sp)
    800021fe:	7442                	ld	s0,48(sp)
    80002200:	74a2                	ld	s1,40(sp)
    80002202:	7902                	ld	s2,32(sp)
    80002204:	69e2                	ld	s3,24(sp)
    80002206:	6a42                	ld	s4,16(sp)
    80002208:	6aa2                	ld	s5,8(sp)
    8000220a:	6b02                	ld	s6,0(sp)
    8000220c:	6121                	addi	sp,sp,64
    8000220e:	8082                	ret

0000000080002210 <reparent>:
{
    80002210:	7179                	addi	sp,sp,-48
    80002212:	f406                	sd	ra,40(sp)
    80002214:	f022                	sd	s0,32(sp)
    80002216:	ec26                	sd	s1,24(sp)
    80002218:	e84a                	sd	s2,16(sp)
    8000221a:	e44e                	sd	s3,8(sp)
    8000221c:	e052                	sd	s4,0(sp)
    8000221e:	1800                	addi	s0,sp,48
    80002220:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002222:	0000f497          	auipc	s1,0xf
    80002226:	d5e48493          	addi	s1,s1,-674 # 80010f80 <proc>
      pp->parent = initproc;
    8000222a:	00006a17          	auipc	s4,0x6
    8000222e:	6aea0a13          	addi	s4,s4,1710 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002232:	00015997          	auipc	s3,0x15
    80002236:	54e98993          	addi	s3,s3,1358 # 80017780 <tickslock>
    8000223a:	a029                	j	80002244 <reparent+0x34>
    8000223c:	1a048493          	addi	s1,s1,416
    80002240:	01348d63          	beq	s1,s3,8000225a <reparent+0x4a>
    if (pp->parent == p)
    80002244:	7c9c                	ld	a5,56(s1)
    80002246:	ff279be3          	bne	a5,s2,8000223c <reparent+0x2c>
      pp->parent = initproc;
    8000224a:	000a3503          	ld	a0,0(s4)
    8000224e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002250:	00000097          	auipc	ra,0x0
    80002254:	f2e080e7          	jalr	-210(ra) # 8000217e <wakeup>
    80002258:	b7d5                	j	8000223c <reparent+0x2c>
}
    8000225a:	70a2                	ld	ra,40(sp)
    8000225c:	7402                	ld	s0,32(sp)
    8000225e:	64e2                	ld	s1,24(sp)
    80002260:	6942                	ld	s2,16(sp)
    80002262:	69a2                	ld	s3,8(sp)
    80002264:	6a02                	ld	s4,0(sp)
    80002266:	6145                	addi	sp,sp,48
    80002268:	8082                	ret

000000008000226a <exit>:
{
    8000226a:	7179                	addi	sp,sp,-48
    8000226c:	f406                	sd	ra,40(sp)
    8000226e:	f022                	sd	s0,32(sp)
    80002270:	ec26                	sd	s1,24(sp)
    80002272:	e84a                	sd	s2,16(sp)
    80002274:	e44e                	sd	s3,8(sp)
    80002276:	e052                	sd	s4,0(sp)
    80002278:	1800                	addi	s0,sp,48
    8000227a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	74a080e7          	jalr	1866(ra) # 800019c6 <myproc>
    80002284:	89aa                	mv	s3,a0
  if (p == initproc)
    80002286:	00006797          	auipc	a5,0x6
    8000228a:	6527b783          	ld	a5,1618(a5) # 800088d8 <initproc>
    8000228e:	0d050493          	addi	s1,a0,208
    80002292:	15050913          	addi	s2,a0,336
    80002296:	02a79363          	bne	a5,a0,800022bc <exit+0x52>
    panic("init exiting");
    8000229a:	00006517          	auipc	a0,0x6
    8000229e:	fc650513          	addi	a0,a0,-58 # 80008260 <digits+0x220>
    800022a2:	ffffe097          	auipc	ra,0xffffe
    800022a6:	2a2080e7          	jalr	674(ra) # 80000544 <panic>
      fileclose(f);
    800022aa:	00003097          	auipc	ra,0x3
    800022ae:	916080e7          	jalr	-1770(ra) # 80004bc0 <fileclose>
      p->ofile[fd] = 0;
    800022b2:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800022b6:	04a1                	addi	s1,s1,8
    800022b8:	01248563          	beq	s1,s2,800022c2 <exit+0x58>
    if (p->ofile[fd])
    800022bc:	6088                	ld	a0,0(s1)
    800022be:	f575                	bnez	a0,800022aa <exit+0x40>
    800022c0:	bfdd                	j	800022b6 <exit+0x4c>
  begin_op();
    800022c2:	00002097          	auipc	ra,0x2
    800022c6:	432080e7          	jalr	1074(ra) # 800046f4 <begin_op>
  iput(p->cwd);
    800022ca:	1509b503          	ld	a0,336(s3)
    800022ce:	00002097          	auipc	ra,0x2
    800022d2:	c1e080e7          	jalr	-994(ra) # 80003eec <iput>
  end_op();
    800022d6:	00002097          	auipc	ra,0x2
    800022da:	49e080e7          	jalr	1182(ra) # 80004774 <end_op>
  p->cwd = 0;
    800022de:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022e2:	0000f497          	auipc	s1,0xf
    800022e6:	88648493          	addi	s1,s1,-1914 # 80010b68 <wait_lock>
    800022ea:	8526                	mv	a0,s1
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	8fe080e7          	jalr	-1794(ra) # 80000bea <acquire>
  reparent(p);
    800022f4:	854e                	mv	a0,s3
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	f1a080e7          	jalr	-230(ra) # 80002210 <reparent>
  wakeup(p->parent);
    800022fe:	0389b503          	ld	a0,56(s3)
    80002302:	00000097          	auipc	ra,0x0
    80002306:	e7c080e7          	jalr	-388(ra) # 8000217e <wakeup>
  acquire(&p->lock);
    8000230a:	854e                	mv	a0,s3
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	8de080e7          	jalr	-1826(ra) # 80000bea <acquire>
  p->xstate = status;
    80002314:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002318:	4795                	li	a5,5
    8000231a:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000231e:	00006797          	auipc	a5,0x6
    80002322:	5c27a783          	lw	a5,1474(a5) # 800088e0 <ticks>
    80002326:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	972080e7          	jalr	-1678(ra) # 80000c9e <release>
  sched();
    80002334:	00000097          	auipc	ra,0x0
    80002338:	cd4080e7          	jalr	-812(ra) # 80002008 <sched>
  panic("zombie exit");
    8000233c:	00006517          	auipc	a0,0x6
    80002340:	f3450513          	addi	a0,a0,-204 # 80008270 <digits+0x230>
    80002344:	ffffe097          	auipc	ra,0xffffe
    80002348:	200080e7          	jalr	512(ra) # 80000544 <panic>

000000008000234c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000234c:	7179                	addi	sp,sp,-48
    8000234e:	f406                	sd	ra,40(sp)
    80002350:	f022                	sd	s0,32(sp)
    80002352:	ec26                	sd	s1,24(sp)
    80002354:	e84a                	sd	s2,16(sp)
    80002356:	e44e                	sd	s3,8(sp)
    80002358:	1800                	addi	s0,sp,48
    8000235a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000235c:	0000f497          	auipc	s1,0xf
    80002360:	c2448493          	addi	s1,s1,-988 # 80010f80 <proc>
    80002364:	00015997          	auipc	s3,0x15
    80002368:	41c98993          	addi	s3,s3,1052 # 80017780 <tickslock>
  {
    acquire(&p->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	87c080e7          	jalr	-1924(ra) # 80000bea <acquire>
    if (p->pid == pid)
    80002376:	589c                	lw	a5,48(s1)
    80002378:	01278d63          	beq	a5,s2,80002392 <kill+0x46>
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	920080e7          	jalr	-1760(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002386:	1a048493          	addi	s1,s1,416
    8000238a:	ff3491e3          	bne	s1,s3,8000236c <kill+0x20>
  }
  return -1;
    8000238e:	557d                	li	a0,-1
    80002390:	a829                	j	800023aa <kill+0x5e>
      p->killed = 1;
    80002392:	4785                	li	a5,1
    80002394:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002396:	4c98                	lw	a4,24(s1)
    80002398:	4789                	li	a5,2
    8000239a:	00f70f63          	beq	a4,a5,800023b8 <kill+0x6c>
      release(&p->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8fe080e7          	jalr	-1794(ra) # 80000c9e <release>
      return 0;
    800023a8:	4501                	li	a0,0
}
    800023aa:	70a2                	ld	ra,40(sp)
    800023ac:	7402                	ld	s0,32(sp)
    800023ae:	64e2                	ld	s1,24(sp)
    800023b0:	6942                	ld	s2,16(sp)
    800023b2:	69a2                	ld	s3,8(sp)
    800023b4:	6145                	addi	sp,sp,48
    800023b6:	8082                	ret
        p->state = RUNNABLE;
    800023b8:	478d                	li	a5,3
    800023ba:	cc9c                	sw	a5,24(s1)
        p->run_time_in_queue = 0;
    800023bc:	1804ae23          	sw	zero,412(s1)
        p->entry_time_in_queue = ticks;
    800023c0:	00006797          	auipc	a5,0x6
    800023c4:	5207a783          	lw	a5,1312(a5) # 800088e0 <ticks>
    800023c8:	18f4aa23          	sw	a5,404(s1)
        p->last_time_run_in_queue = ticks;
    800023cc:	18f4ac23          	sw	a5,408(s1)
    800023d0:	b7f9                	j	8000239e <kill+0x52>

00000000800023d2 <setkilled>:

void setkilled(struct proc *p)
{
    800023d2:	1101                	addi	sp,sp,-32
    800023d4:	ec06                	sd	ra,24(sp)
    800023d6:	e822                	sd	s0,16(sp)
    800023d8:	e426                	sd	s1,8(sp)
    800023da:	1000                	addi	s0,sp,32
    800023dc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	80c080e7          	jalr	-2036(ra) # 80000bea <acquire>
  p->killed = 1;
    800023e6:	4785                	li	a5,1
    800023e8:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	8b2080e7          	jalr	-1870(ra) # 80000c9e <release>
}
    800023f4:	60e2                	ld	ra,24(sp)
    800023f6:	6442                	ld	s0,16(sp)
    800023f8:	64a2                	ld	s1,8(sp)
    800023fa:	6105                	addi	sp,sp,32
    800023fc:	8082                	ret

00000000800023fe <killed>:

int killed(struct proc *p)
{
    800023fe:	1101                	addi	sp,sp,-32
    80002400:	ec06                	sd	ra,24(sp)
    80002402:	e822                	sd	s0,16(sp)
    80002404:	e426                	sd	s1,8(sp)
    80002406:	e04a                	sd	s2,0(sp)
    80002408:	1000                	addi	s0,sp,32
    8000240a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000240c:	ffffe097          	auipc	ra,0xffffe
    80002410:	7de080e7          	jalr	2014(ra) # 80000bea <acquire>
  k = p->killed;
    80002414:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	884080e7          	jalr	-1916(ra) # 80000c9e <release>
  return k;
}
    80002422:	854a                	mv	a0,s2
    80002424:	60e2                	ld	ra,24(sp)
    80002426:	6442                	ld	s0,16(sp)
    80002428:	64a2                	ld	s1,8(sp)
    8000242a:	6902                	ld	s2,0(sp)
    8000242c:	6105                	addi	sp,sp,32
    8000242e:	8082                	ret

0000000080002430 <wait>:
{
    80002430:	715d                	addi	sp,sp,-80
    80002432:	e486                	sd	ra,72(sp)
    80002434:	e0a2                	sd	s0,64(sp)
    80002436:	fc26                	sd	s1,56(sp)
    80002438:	f84a                	sd	s2,48(sp)
    8000243a:	f44e                	sd	s3,40(sp)
    8000243c:	f052                	sd	s4,32(sp)
    8000243e:	ec56                	sd	s5,24(sp)
    80002440:	e85a                	sd	s6,16(sp)
    80002442:	e45e                	sd	s7,8(sp)
    80002444:	e062                	sd	s8,0(sp)
    80002446:	0880                	addi	s0,sp,80
    80002448:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	57c080e7          	jalr	1404(ra) # 800019c6 <myproc>
    80002452:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002454:	0000e517          	auipc	a0,0xe
    80002458:	71450513          	addi	a0,a0,1812 # 80010b68 <wait_lock>
    8000245c:	ffffe097          	auipc	ra,0xffffe
    80002460:	78e080e7          	jalr	1934(ra) # 80000bea <acquire>
    havekids = 0;
    80002464:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002466:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002468:	00015997          	auipc	s3,0x15
    8000246c:	31898993          	addi	s3,s3,792 # 80017780 <tickslock>
        havekids = 1;
    80002470:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002472:	0000ec17          	auipc	s8,0xe
    80002476:	6f6c0c13          	addi	s8,s8,1782 # 80010b68 <wait_lock>
    havekids = 0;
    8000247a:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000247c:	0000f497          	auipc	s1,0xf
    80002480:	b0448493          	addi	s1,s1,-1276 # 80010f80 <proc>
    80002484:	a0bd                	j	800024f2 <wait+0xc2>
          pid = pp->pid;
    80002486:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000248a:	000b0e63          	beqz	s6,800024a6 <wait+0x76>
    8000248e:	4691                	li	a3,4
    80002490:	02c48613          	addi	a2,s1,44
    80002494:	85da                	mv	a1,s6
    80002496:	05093503          	ld	a0,80(s2)
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	1ea080e7          	jalr	490(ra) # 80001684 <copyout>
    800024a2:	02054563          	bltz	a0,800024cc <wait+0x9c>
          freeproc(pp);
    800024a6:	8526                	mv	a0,s1
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	6d0080e7          	jalr	1744(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7ec080e7          	jalr	2028(ra) # 80000c9e <release>
          release(&wait_lock);
    800024ba:	0000e517          	auipc	a0,0xe
    800024be:	6ae50513          	addi	a0,a0,1710 # 80010b68 <wait_lock>
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7dc080e7          	jalr	2012(ra) # 80000c9e <release>
          return pid;
    800024ca:	a0b5                	j	80002536 <wait+0x106>
            release(&pp->lock);
    800024cc:	8526                	mv	a0,s1
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	7d0080e7          	jalr	2000(ra) # 80000c9e <release>
            release(&wait_lock);
    800024d6:	0000e517          	auipc	a0,0xe
    800024da:	69250513          	addi	a0,a0,1682 # 80010b68 <wait_lock>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7c0080e7          	jalr	1984(ra) # 80000c9e <release>
            return -1;
    800024e6:	59fd                	li	s3,-1
    800024e8:	a0b9                	j	80002536 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024ea:	1a048493          	addi	s1,s1,416
    800024ee:	03348463          	beq	s1,s3,80002516 <wait+0xe6>
      if (pp->parent == p)
    800024f2:	7c9c                	ld	a5,56(s1)
    800024f4:	ff279be3          	bne	a5,s2,800024ea <wait+0xba>
        acquire(&pp->lock);
    800024f8:	8526                	mv	a0,s1
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6f0080e7          	jalr	1776(ra) # 80000bea <acquire>
        if (pp->state == ZOMBIE)
    80002502:	4c9c                	lw	a5,24(s1)
    80002504:	f94781e3          	beq	a5,s4,80002486 <wait+0x56>
        release(&pp->lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	794080e7          	jalr	1940(ra) # 80000c9e <release>
        havekids = 1;
    80002512:	8756                	mv	a4,s5
    80002514:	bfd9                	j	800024ea <wait+0xba>
    if (!havekids || killed(p))
    80002516:	c719                	beqz	a4,80002524 <wait+0xf4>
    80002518:	854a                	mv	a0,s2
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	ee4080e7          	jalr	-284(ra) # 800023fe <killed>
    80002522:	c51d                	beqz	a0,80002550 <wait+0x120>
      release(&wait_lock);
    80002524:	0000e517          	auipc	a0,0xe
    80002528:	64450513          	addi	a0,a0,1604 # 80010b68 <wait_lock>
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	772080e7          	jalr	1906(ra) # 80000c9e <release>
      return -1;
    80002534:	59fd                	li	s3,-1
}
    80002536:	854e                	mv	a0,s3
    80002538:	60a6                	ld	ra,72(sp)
    8000253a:	6406                	ld	s0,64(sp)
    8000253c:	74e2                	ld	s1,56(sp)
    8000253e:	7942                	ld	s2,48(sp)
    80002540:	79a2                	ld	s3,40(sp)
    80002542:	7a02                	ld	s4,32(sp)
    80002544:	6ae2                	ld	s5,24(sp)
    80002546:	6b42                	ld	s6,16(sp)
    80002548:	6ba2                	ld	s7,8(sp)
    8000254a:	6c02                	ld	s8,0(sp)
    8000254c:	6161                	addi	sp,sp,80
    8000254e:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002550:	85e2                	mv	a1,s8
    80002552:	854a                	mv	a0,s2
    80002554:	00000097          	auipc	ra,0x0
    80002558:	bc6080e7          	jalr	-1082(ra) # 8000211a <sleep>
    havekids = 0;
    8000255c:	bf39                	j	8000247a <wait+0x4a>

000000008000255e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000255e:	7179                	addi	sp,sp,-48
    80002560:	f406                	sd	ra,40(sp)
    80002562:	f022                	sd	s0,32(sp)
    80002564:	ec26                	sd	s1,24(sp)
    80002566:	e84a                	sd	s2,16(sp)
    80002568:	e44e                	sd	s3,8(sp)
    8000256a:	e052                	sd	s4,0(sp)
    8000256c:	1800                	addi	s0,sp,48
    8000256e:	84aa                	mv	s1,a0
    80002570:	892e                	mv	s2,a1
    80002572:	89b2                	mv	s3,a2
    80002574:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	450080e7          	jalr	1104(ra) # 800019c6 <myproc>
  if (user_dst)
    8000257e:	c08d                	beqz	s1,800025a0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002580:	86d2                	mv	a3,s4
    80002582:	864e                	mv	a2,s3
    80002584:	85ca                	mv	a1,s2
    80002586:	6928                	ld	a0,80(a0)
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	0fc080e7          	jalr	252(ra) # 80001684 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002590:	70a2                	ld	ra,40(sp)
    80002592:	7402                	ld	s0,32(sp)
    80002594:	64e2                	ld	s1,24(sp)
    80002596:	6942                	ld	s2,16(sp)
    80002598:	69a2                	ld	s3,8(sp)
    8000259a:	6a02                	ld	s4,0(sp)
    8000259c:	6145                	addi	sp,sp,48
    8000259e:	8082                	ret
    memmove((char *)dst, src, len);
    800025a0:	000a061b          	sext.w	a2,s4
    800025a4:	85ce                	mv	a1,s3
    800025a6:	854a                	mv	a0,s2
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	79e080e7          	jalr	1950(ra) # 80000d46 <memmove>
    return 0;
    800025b0:	8526                	mv	a0,s1
    800025b2:	bff9                	j	80002590 <either_copyout+0x32>

00000000800025b4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025b4:	7179                	addi	sp,sp,-48
    800025b6:	f406                	sd	ra,40(sp)
    800025b8:	f022                	sd	s0,32(sp)
    800025ba:	ec26                	sd	s1,24(sp)
    800025bc:	e84a                	sd	s2,16(sp)
    800025be:	e44e                	sd	s3,8(sp)
    800025c0:	e052                	sd	s4,0(sp)
    800025c2:	1800                	addi	s0,sp,48
    800025c4:	892a                	mv	s2,a0
    800025c6:	84ae                	mv	s1,a1
    800025c8:	89b2                	mv	s3,a2
    800025ca:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	3fa080e7          	jalr	1018(ra) # 800019c6 <myproc>
  if (user_src)
    800025d4:	c08d                	beqz	s1,800025f6 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800025d6:	86d2                	mv	a3,s4
    800025d8:	864e                	mv	a2,s3
    800025da:	85ca                	mv	a1,s2
    800025dc:	6928                	ld	a0,80(a0)
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	132080e7          	jalr	306(ra) # 80001710 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800025e6:	70a2                	ld	ra,40(sp)
    800025e8:	7402                	ld	s0,32(sp)
    800025ea:	64e2                	ld	s1,24(sp)
    800025ec:	6942                	ld	s2,16(sp)
    800025ee:	69a2                	ld	s3,8(sp)
    800025f0:	6a02                	ld	s4,0(sp)
    800025f2:	6145                	addi	sp,sp,48
    800025f4:	8082                	ret
    memmove(dst, (char *)src, len);
    800025f6:	000a061b          	sext.w	a2,s4
    800025fa:	85ce                	mv	a1,s3
    800025fc:	854a                	mv	a0,s2
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	748080e7          	jalr	1864(ra) # 80000d46 <memmove>
    return 0;
    80002606:	8526                	mv	a0,s1
    80002608:	bff9                	j	800025e6 <either_copyin+0x32>

000000008000260a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000260a:	715d                	addi	sp,sp,-80
    8000260c:	e486                	sd	ra,72(sp)
    8000260e:	e0a2                	sd	s0,64(sp)
    80002610:	fc26                	sd	s1,56(sp)
    80002612:	f84a                	sd	s2,48(sp)
    80002614:	f44e                	sd	s3,40(sp)
    80002616:	f052                	sd	s4,32(sp)
    80002618:	ec56                	sd	s5,24(sp)
    8000261a:	e85a                	sd	s6,16(sp)
    8000261c:	e45e                	sd	s7,8(sp)
    8000261e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002620:	00006517          	auipc	a0,0x6
    80002624:	aa850513          	addi	a0,a0,-1368 # 800080c8 <digits+0x88>
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	f66080e7          	jalr	-154(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002630:	0000f497          	auipc	s1,0xf
    80002634:	aa848493          	addi	s1,s1,-1368 # 800110d8 <proc+0x158>
    80002638:	00015917          	auipc	s2,0x15
    8000263c:	2a090913          	addi	s2,s2,672 # 800178d8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002640:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002642:	00006997          	auipc	s3,0x6
    80002646:	c3e98993          	addi	s3,s3,-962 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000264a:	00006a97          	auipc	s5,0x6
    8000264e:	c3ea8a93          	addi	s5,s5,-962 # 80008288 <digits+0x248>
    printf("\n");
    80002652:	00006a17          	auipc	s4,0x6
    80002656:	a76a0a13          	addi	s4,s4,-1418 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000265a:	00006b97          	auipc	s7,0x6
    8000265e:	c6eb8b93          	addi	s7,s7,-914 # 800082c8 <states.1743>
    80002662:	a00d                	j	80002684 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002664:	ed86a583          	lw	a1,-296(a3)
    80002668:	8556                	mv	a0,s5
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	f24080e7          	jalr	-220(ra) # 8000058e <printf>
    printf("\n");
    80002672:	8552                	mv	a0,s4
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	f1a080e7          	jalr	-230(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000267c:	1a048493          	addi	s1,s1,416
    80002680:	03248163          	beq	s1,s2,800026a2 <procdump+0x98>
    if (p->state == UNUSED)
    80002684:	86a6                	mv	a3,s1
    80002686:	ec04a783          	lw	a5,-320(s1)
    8000268a:	dbed                	beqz	a5,8000267c <procdump+0x72>
      state = "???";
    8000268c:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000268e:	fcfb6be3          	bltu	s6,a5,80002664 <procdump+0x5a>
    80002692:	1782                	slli	a5,a5,0x20
    80002694:	9381                	srli	a5,a5,0x20
    80002696:	078e                	slli	a5,a5,0x3
    80002698:	97de                	add	a5,a5,s7
    8000269a:	6390                	ld	a2,0(a5)
    8000269c:	f661                	bnez	a2,80002664 <procdump+0x5a>
      state = "???";
    8000269e:	864e                	mv	a2,s3
    800026a0:	b7d1                	j	80002664 <procdump+0x5a>
  }
}
    800026a2:	60a6                	ld	ra,72(sp)
    800026a4:	6406                	ld	s0,64(sp)
    800026a6:	74e2                	ld	s1,56(sp)
    800026a8:	7942                	ld	s2,48(sp)
    800026aa:	79a2                	ld	s3,40(sp)
    800026ac:	7a02                	ld	s4,32(sp)
    800026ae:	6ae2                	ld	s5,24(sp)
    800026b0:	6b42                	ld	s6,16(sp)
    800026b2:	6ba2                	ld	s7,8(sp)
    800026b4:	6161                	addi	sp,sp,80
    800026b6:	8082                	ret

00000000800026b8 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800026b8:	711d                	addi	sp,sp,-96
    800026ba:	ec86                	sd	ra,88(sp)
    800026bc:	e8a2                	sd	s0,80(sp)
    800026be:	e4a6                	sd	s1,72(sp)
    800026c0:	e0ca                	sd	s2,64(sp)
    800026c2:	fc4e                	sd	s3,56(sp)
    800026c4:	f852                	sd	s4,48(sp)
    800026c6:	f456                	sd	s5,40(sp)
    800026c8:	f05a                	sd	s6,32(sp)
    800026ca:	ec5e                	sd	s7,24(sp)
    800026cc:	e862                	sd	s8,16(sp)
    800026ce:	e466                	sd	s9,8(sp)
    800026d0:	e06a                	sd	s10,0(sp)
    800026d2:	1080                	addi	s0,sp,96
    800026d4:	8b2a                	mv	s6,a0
    800026d6:	8bae                	mv	s7,a1
    800026d8:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800026da:	fffff097          	auipc	ra,0xfffff
    800026de:	2ec080e7          	jalr	748(ra) # 800019c6 <myproc>
    800026e2:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800026e4:	0000e517          	auipc	a0,0xe
    800026e8:	48450513          	addi	a0,a0,1156 # 80010b68 <wait_lock>
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	4fe080e7          	jalr	1278(ra) # 80000bea <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800026f4:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800026f6:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800026f8:	00015997          	auipc	s3,0x15
    800026fc:	08898993          	addi	s3,s3,136 # 80017780 <tickslock>
        havekids = 1;
    80002700:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002702:	0000ed17          	auipc	s10,0xe
    80002706:	466d0d13          	addi	s10,s10,1126 # 80010b68 <wait_lock>
    havekids = 0;
    8000270a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000270c:	0000f497          	auipc	s1,0xf
    80002710:	87448493          	addi	s1,s1,-1932 # 80010f80 <proc>
    80002714:	a059                	j	8000279a <waitx+0xe2>
          pid = np->pid;
    80002716:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000271a:	1684a703          	lw	a4,360(s1)
    8000271e:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002722:	16c4a783          	lw	a5,364(s1)
    80002726:	9f3d                	addw	a4,a4,a5
    80002728:	1704a783          	lw	a5,368(s1)
    8000272c:	9f99                	subw	a5,a5,a4
    8000272e:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002732:	000b0e63          	beqz	s6,8000274e <waitx+0x96>
    80002736:	4691                	li	a3,4
    80002738:	02c48613          	addi	a2,s1,44
    8000273c:	85da                	mv	a1,s6
    8000273e:	05093503          	ld	a0,80(s2)
    80002742:	fffff097          	auipc	ra,0xfffff
    80002746:	f42080e7          	jalr	-190(ra) # 80001684 <copyout>
    8000274a:	02054563          	bltz	a0,80002774 <waitx+0xbc>
          freeproc(np);
    8000274e:	8526                	mv	a0,s1
    80002750:	fffff097          	auipc	ra,0xfffff
    80002754:	428080e7          	jalr	1064(ra) # 80001b78 <freeproc>
          release(&np->lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	544080e7          	jalr	1348(ra) # 80000c9e <release>
          release(&wait_lock);
    80002762:	0000e517          	auipc	a0,0xe
    80002766:	40650513          	addi	a0,a0,1030 # 80010b68 <wait_lock>
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
          return pid;
    80002772:	a09d                	j	800027d8 <waitx+0x120>
            release(&np->lock);
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	528080e7          	jalr	1320(ra) # 80000c9e <release>
            release(&wait_lock);
    8000277e:	0000e517          	auipc	a0,0xe
    80002782:	3ea50513          	addi	a0,a0,1002 # 80010b68 <wait_lock>
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	518080e7          	jalr	1304(ra) # 80000c9e <release>
            return -1;
    8000278e:	59fd                	li	s3,-1
    80002790:	a0a1                	j	800027d8 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002792:	1a048493          	addi	s1,s1,416
    80002796:	03348463          	beq	s1,s3,800027be <waitx+0x106>
      if (np->parent == p)
    8000279a:	7c9c                	ld	a5,56(s1)
    8000279c:	ff279be3          	bne	a5,s2,80002792 <waitx+0xda>
        acquire(&np->lock);
    800027a0:	8526                	mv	a0,s1
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	448080e7          	jalr	1096(ra) # 80000bea <acquire>
        if (np->state == ZOMBIE)
    800027aa:	4c9c                	lw	a5,24(s1)
    800027ac:	f74785e3          	beq	a5,s4,80002716 <waitx+0x5e>
        release(&np->lock);
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	4ec080e7          	jalr	1260(ra) # 80000c9e <release>
        havekids = 1;
    800027ba:	8756                	mv	a4,s5
    800027bc:	bfd9                	j	80002792 <waitx+0xda>
    if (!havekids || p->killed)
    800027be:	c701                	beqz	a4,800027c6 <waitx+0x10e>
    800027c0:	02892783          	lw	a5,40(s2)
    800027c4:	cb8d                	beqz	a5,800027f6 <waitx+0x13e>
      release(&wait_lock);
    800027c6:	0000e517          	auipc	a0,0xe
    800027ca:	3a250513          	addi	a0,a0,930 # 80010b68 <wait_lock>
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	4d0080e7          	jalr	1232(ra) # 80000c9e <release>
      return -1;
    800027d6:	59fd                	li	s3,-1
  }
}
    800027d8:	854e                	mv	a0,s3
    800027da:	60e6                	ld	ra,88(sp)
    800027dc:	6446                	ld	s0,80(sp)
    800027de:	64a6                	ld	s1,72(sp)
    800027e0:	6906                	ld	s2,64(sp)
    800027e2:	79e2                	ld	s3,56(sp)
    800027e4:	7a42                	ld	s4,48(sp)
    800027e6:	7aa2                	ld	s5,40(sp)
    800027e8:	7b02                	ld	s6,32(sp)
    800027ea:	6be2                	ld	s7,24(sp)
    800027ec:	6c42                	ld	s8,16(sp)
    800027ee:	6ca2                	ld	s9,8(sp)
    800027f0:	6d02                	ld	s10,0(sp)
    800027f2:	6125                	addi	sp,sp,96
    800027f4:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027f6:	85ea                	mv	a1,s10
    800027f8:	854a                	mv	a0,s2
    800027fa:	00000097          	auipc	ra,0x0
    800027fe:	920080e7          	jalr	-1760(ra) # 8000211a <sleep>
    havekids = 0;
    80002802:	b721                	j	8000270a <waitx+0x52>

0000000080002804 <update_time>:

void update_time()
{
    80002804:	7179                	addi	sp,sp,-48
    80002806:	f406                	sd	ra,40(sp)
    80002808:	f022                	sd	s0,32(sp)
    8000280a:	ec26                	sd	s1,24(sp)
    8000280c:	e84a                	sd	s2,16(sp)
    8000280e:	e44e                	sd	s3,8(sp)
    80002810:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002812:	0000e497          	auipc	s1,0xe
    80002816:	76e48493          	addi	s1,s1,1902 # 80010f80 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000281a:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000281c:	00015917          	auipc	s2,0x15
    80002820:	f6490913          	addi	s2,s2,-156 # 80017780 <tickslock>
    80002824:	a811                	j	80002838 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002826:	8526                	mv	a0,s1
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	476080e7          	jalr	1142(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002830:	1a048493          	addi	s1,s1,416
    80002834:	03248063          	beq	s1,s2,80002854 <update_time+0x50>
    acquire(&p->lock);
    80002838:	8526                	mv	a0,s1
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	3b0080e7          	jalr	944(ra) # 80000bea <acquire>
    if (p->state == RUNNING)
    80002842:	4c9c                	lw	a5,24(s1)
    80002844:	ff3791e3          	bne	a5,s3,80002826 <update_time+0x22>
      p->rtime++;
    80002848:	1684a783          	lw	a5,360(s1)
    8000284c:	2785                	addiw	a5,a5,1
    8000284e:	16f4a423          	sw	a5,360(s1)
    80002852:	bfd1                	j	80002826 <update_time+0x22>
  }
    80002854:	70a2                	ld	ra,40(sp)
    80002856:	7402                	ld	s0,32(sp)
    80002858:	64e2                	ld	s1,24(sp)
    8000285a:	6942                	ld	s2,16(sp)
    8000285c:	69a2                	ld	s3,8(sp)
    8000285e:	6145                	addi	sp,sp,48
    80002860:	8082                	ret

0000000080002862 <swtch>:
    80002862:	00153023          	sd	ra,0(a0)
    80002866:	00253423          	sd	sp,8(a0)
    8000286a:	e900                	sd	s0,16(a0)
    8000286c:	ed04                	sd	s1,24(a0)
    8000286e:	03253023          	sd	s2,32(a0)
    80002872:	03353423          	sd	s3,40(a0)
    80002876:	03453823          	sd	s4,48(a0)
    8000287a:	03553c23          	sd	s5,56(a0)
    8000287e:	05653023          	sd	s6,64(a0)
    80002882:	05753423          	sd	s7,72(a0)
    80002886:	05853823          	sd	s8,80(a0)
    8000288a:	05953c23          	sd	s9,88(a0)
    8000288e:	07a53023          	sd	s10,96(a0)
    80002892:	07b53423          	sd	s11,104(a0)
    80002896:	0005b083          	ld	ra,0(a1)
    8000289a:	0085b103          	ld	sp,8(a1)
    8000289e:	6980                	ld	s0,16(a1)
    800028a0:	6d84                	ld	s1,24(a1)
    800028a2:	0205b903          	ld	s2,32(a1)
    800028a6:	0285b983          	ld	s3,40(a1)
    800028aa:	0305ba03          	ld	s4,48(a1)
    800028ae:	0385ba83          	ld	s5,56(a1)
    800028b2:	0405bb03          	ld	s6,64(a1)
    800028b6:	0485bb83          	ld	s7,72(a1)
    800028ba:	0505bc03          	ld	s8,80(a1)
    800028be:	0585bc83          	ld	s9,88(a1)
    800028c2:	0605bd03          	ld	s10,96(a1)
    800028c6:	0685bd83          	ld	s11,104(a1)
    800028ca:	8082                	ret

00000000800028cc <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800028cc:	1141                	addi	sp,sp,-16
    800028ce:	e406                	sd	ra,8(sp)
    800028d0:	e022                	sd	s0,0(sp)
    800028d2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028d4:	00006597          	auipc	a1,0x6
    800028d8:	a2458593          	addi	a1,a1,-1500 # 800082f8 <states.1743+0x30>
    800028dc:	00015517          	auipc	a0,0x15
    800028e0:	ea450513          	addi	a0,a0,-348 # 80017780 <tickslock>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	276080e7          	jalr	630(ra) # 80000b5a <initlock>
}
    800028ec:	60a2                	ld	ra,8(sp)
    800028ee:	6402                	ld	s0,0(sp)
    800028f0:	0141                	addi	sp,sp,16
    800028f2:	8082                	ret

00000000800028f4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800028f4:	1141                	addi	sp,sp,-16
    800028f6:	e422                	sd	s0,8(sp)
    800028f8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028fa:	00004797          	auipc	a5,0x4
    800028fe:	92678793          	addi	a5,a5,-1754 # 80006220 <kernelvec>
    80002902:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002906:	6422                	ld	s0,8(sp)
    80002908:	0141                	addi	sp,sp,16
    8000290a:	8082                	ret

000000008000290c <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000290c:	1141                	addi	sp,sp,-16
    8000290e:	e406                	sd	ra,8(sp)
    80002910:	e022                	sd	s0,0(sp)
    80002912:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002914:	fffff097          	auipc	ra,0xfffff
    80002918:	0b2080e7          	jalr	178(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002920:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002922:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002926:	00004617          	auipc	a2,0x4
    8000292a:	6da60613          	addi	a2,a2,1754 # 80007000 <_trampoline>
    8000292e:	00004697          	auipc	a3,0x4
    80002932:	6d268693          	addi	a3,a3,1746 # 80007000 <_trampoline>
    80002936:	8e91                	sub	a3,a3,a2
    80002938:	040007b7          	lui	a5,0x4000
    8000293c:	17fd                	addi	a5,a5,-1
    8000293e:	07b2                	slli	a5,a5,0xc
    80002940:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002942:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002946:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002948:	180026f3          	csrr	a3,satp
    8000294c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000294e:	6d38                	ld	a4,88(a0)
    80002950:	6134                	ld	a3,64(a0)
    80002952:	6585                	lui	a1,0x1
    80002954:	96ae                	add	a3,a3,a1
    80002956:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002958:	6d38                	ld	a4,88(a0)
    8000295a:	00000697          	auipc	a3,0x0
    8000295e:	13e68693          	addi	a3,a3,318 # 80002a98 <usertrap>
    80002962:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002964:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002966:	8692                	mv	a3,tp
    80002968:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000296a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000296e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002972:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002976:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000297a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000297c:	6f18                	ld	a4,24(a4)
    8000297e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002982:	6928                	ld	a0,80(a0)
    80002984:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002986:	00004717          	auipc	a4,0x4
    8000298a:	71670713          	addi	a4,a4,1814 # 8000709c <userret>
    8000298e:	8f11                	sub	a4,a4,a2
    80002990:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002992:	577d                	li	a4,-1
    80002994:	177e                	slli	a4,a4,0x3f
    80002996:	8d59                	or	a0,a0,a4
    80002998:	9782                	jalr	a5
}
    8000299a:	60a2                	ld	ra,8(sp)
    8000299c:	6402                	ld	s0,0(sp)
    8000299e:	0141                	addi	sp,sp,16
    800029a0:	8082                	ret

00000000800029a2 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800029a2:	1101                	addi	sp,sp,-32
    800029a4:	ec06                	sd	ra,24(sp)
    800029a6:	e822                	sd	s0,16(sp)
    800029a8:	e426                	sd	s1,8(sp)
    800029aa:	e04a                	sd	s2,0(sp)
    800029ac:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029ae:	00015917          	auipc	s2,0x15
    800029b2:	dd290913          	addi	s2,s2,-558 # 80017780 <tickslock>
    800029b6:	854a                	mv	a0,s2
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	232080e7          	jalr	562(ra) # 80000bea <acquire>
  ticks++;
    800029c0:	00006497          	auipc	s1,0x6
    800029c4:	f2048493          	addi	s1,s1,-224 # 800088e0 <ticks>
    800029c8:	409c                	lw	a5,0(s1)
    800029ca:	2785                	addiw	a5,a5,1
    800029cc:	c09c                	sw	a5,0(s1)
  update_time();
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	e36080e7          	jalr	-458(ra) # 80002804 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    800029d6:	8526                	mv	a0,s1
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	7a6080e7          	jalr	1958(ra) # 8000217e <wakeup>
  release(&tickslock);
    800029e0:	854a                	mv	a0,s2
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	2bc080e7          	jalr	700(ra) # 80000c9e <release>
}
    800029ea:	60e2                	ld	ra,24(sp)
    800029ec:	6442                	ld	s0,16(sp)
    800029ee:	64a2                	ld	s1,8(sp)
    800029f0:	6902                	ld	s2,0(sp)
    800029f2:	6105                	addi	sp,sp,32
    800029f4:	8082                	ret

00000000800029f6 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    800029f6:	1101                	addi	sp,sp,-32
    800029f8:	ec06                	sd	ra,24(sp)
    800029fa:	e822                	sd	s0,16(sp)
    800029fc:	e426                	sd	s1,8(sp)
    800029fe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a00:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002a04:	00074d63          	bltz	a4,80002a1e <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002a08:	57fd                	li	a5,-1
    80002a0a:	17fe                	slli	a5,a5,0x3f
    80002a0c:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002a0e:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002a10:	06f70363          	beq	a4,a5,80002a76 <devintr+0x80>
  }
}
    80002a14:	60e2                	ld	ra,24(sp)
    80002a16:	6442                	ld	s0,16(sp)
    80002a18:	64a2                	ld	s1,8(sp)
    80002a1a:	6105                	addi	sp,sp,32
    80002a1c:	8082                	ret
      (scause & 0xff) == 9)
    80002a1e:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002a22:	46a5                	li	a3,9
    80002a24:	fed792e3          	bne	a5,a3,80002a08 <devintr+0x12>
    int irq = plic_claim();
    80002a28:	00004097          	auipc	ra,0x4
    80002a2c:	900080e7          	jalr	-1792(ra) # 80006328 <plic_claim>
    80002a30:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002a32:	47a9                	li	a5,10
    80002a34:	02f50763          	beq	a0,a5,80002a62 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002a38:	4785                	li	a5,1
    80002a3a:	02f50963          	beq	a0,a5,80002a6c <devintr+0x76>
    return 1;
    80002a3e:	4505                	li	a0,1
    else if (irq)
    80002a40:	d8f1                	beqz	s1,80002a14 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a42:	85a6                	mv	a1,s1
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	8bc50513          	addi	a0,a0,-1860 # 80008300 <states.1743+0x38>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	b42080e7          	jalr	-1214(ra) # 8000058e <printf>
      plic_complete(irq);
    80002a54:	8526                	mv	a0,s1
    80002a56:	00004097          	auipc	ra,0x4
    80002a5a:	8f6080e7          	jalr	-1802(ra) # 8000634c <plic_complete>
    return 1;
    80002a5e:	4505                	li	a0,1
    80002a60:	bf55                	j	80002a14 <devintr+0x1e>
      uartintr();
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	f4c080e7          	jalr	-180(ra) # 800009ae <uartintr>
    80002a6a:	b7ed                	j	80002a54 <devintr+0x5e>
      virtio_disk_intr();
    80002a6c:	00004097          	auipc	ra,0x4
    80002a70:	e0a080e7          	jalr	-502(ra) # 80006876 <virtio_disk_intr>
    80002a74:	b7c5                	j	80002a54 <devintr+0x5e>
    if (cpuid() == 0)
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	f24080e7          	jalr	-220(ra) # 8000199a <cpuid>
    80002a7e:	c901                	beqz	a0,80002a8e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a80:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a84:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a86:	14479073          	csrw	sip,a5
    return 2;
    80002a8a:	4509                	li	a0,2
    80002a8c:	b761                	j	80002a14 <devintr+0x1e>
      clockintr();
    80002a8e:	00000097          	auipc	ra,0x0
    80002a92:	f14080e7          	jalr	-236(ra) # 800029a2 <clockintr>
    80002a96:	b7ed                	j	80002a80 <devintr+0x8a>

0000000080002a98 <usertrap>:
{
    80002a98:	7159                	addi	sp,sp,-112
    80002a9a:	f486                	sd	ra,104(sp)
    80002a9c:	f0a2                	sd	s0,96(sp)
    80002a9e:	eca6                	sd	s1,88(sp)
    80002aa0:	e8ca                	sd	s2,80(sp)
    80002aa2:	e4ce                	sd	s3,72(sp)
    80002aa4:	e0d2                	sd	s4,64(sp)
    80002aa6:	fc56                	sd	s5,56(sp)
    80002aa8:	f85a                	sd	s6,48(sp)
    80002aaa:	f45e                	sd	s7,40(sp)
    80002aac:	f062                	sd	s8,32(sp)
    80002aae:	ec66                	sd	s9,24(sp)
    80002ab0:	1880                	addi	s0,sp,112
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002ab6:	1007f793          	andi	a5,a5,256
    80002aba:	e3b1                	bnez	a5,80002afe <usertrap+0x66>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002abc:	00003797          	auipc	a5,0x3
    80002ac0:	76478793          	addi	a5,a5,1892 # 80006220 <kernelvec>
    80002ac4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	efe080e7          	jalr	-258(ra) # 800019c6 <myproc>
    80002ad0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ad2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad4:	14102773          	csrr	a4,sepc
    80002ad8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ada:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002ade:	47a1                	li	a5,8
    80002ae0:	02f70763          	beq	a4,a5,80002b0e <usertrap+0x76>
  else if ((which_dev = devintr()) != 0)
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	f12080e7          	jalr	-238(ra) # 800029f6 <devintr>
    80002aec:	892a                	mv	s2,a0
    80002aee:	c141                	beqz	a0,80002b6e <usertrap+0xd6>
  if (killed(p))
    80002af0:	8526                	mv	a0,s1
    80002af2:	00000097          	auipc	ra,0x0
    80002af6:	90c080e7          	jalr	-1780(ra) # 800023fe <killed>
    80002afa:	cd4d                	beqz	a0,80002bb4 <usertrap+0x11c>
    80002afc:	a07d                	j	80002baa <usertrap+0x112>
    panic("usertrap: not from user mode");
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	82250513          	addi	a0,a0,-2014 # 80008320 <states.1743+0x58>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a3e080e7          	jalr	-1474(ra) # 80000544 <panic>
    if (killed(p))
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	8f0080e7          	jalr	-1808(ra) # 800023fe <killed>
    80002b16:	e531                	bnez	a0,80002b62 <usertrap+0xca>
    p->trapframe->epc += 4;
    80002b18:	6cb8                	ld	a4,88(s1)
    80002b1a:	6f1c                	ld	a5,24(a4)
    80002b1c:	0791                	addi	a5,a5,4
    80002b1e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b28:	10079073          	csrw	sstatus,a5
    syscall();
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	554080e7          	jalr	1364(ra) # 80003080 <syscall>
  if (killed(p))
    80002b34:	8526                	mv	a0,s1
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	8c8080e7          	jalr	-1848(ra) # 800023fe <killed>
    80002b3e:	e52d                	bnez	a0,80002ba8 <usertrap+0x110>
  usertrapret();
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	dcc080e7          	jalr	-564(ra) # 8000290c <usertrapret>
}
    80002b48:	70a6                	ld	ra,104(sp)
    80002b4a:	7406                	ld	s0,96(sp)
    80002b4c:	64e6                	ld	s1,88(sp)
    80002b4e:	6946                	ld	s2,80(sp)
    80002b50:	69a6                	ld	s3,72(sp)
    80002b52:	6a06                	ld	s4,64(sp)
    80002b54:	7ae2                	ld	s5,56(sp)
    80002b56:	7b42                	ld	s6,48(sp)
    80002b58:	7ba2                	ld	s7,40(sp)
    80002b5a:	7c02                	ld	s8,32(sp)
    80002b5c:	6ce2                	ld	s9,24(sp)
    80002b5e:	6165                	addi	sp,sp,112
    80002b60:	8082                	ret
      exit(-1);
    80002b62:	557d                	li	a0,-1
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	706080e7          	jalr	1798(ra) # 8000226a <exit>
    80002b6c:	b775                	j	80002b18 <usertrap+0x80>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b72:	5890                	lw	a2,48(s1)
    80002b74:	00005517          	auipc	a0,0x5
    80002b78:	7cc50513          	addi	a0,a0,1996 # 80008340 <states.1743+0x78>
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	a12080e7          	jalr	-1518(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b84:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b88:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b8c:	00005517          	auipc	a0,0x5
    80002b90:	7e450513          	addi	a0,a0,2020 # 80008370 <states.1743+0xa8>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9fa080e7          	jalr	-1542(ra) # 8000058e <printf>
    setkilled(p);
    80002b9c:	8526                	mv	a0,s1
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	834080e7          	jalr	-1996(ra) # 800023d2 <setkilled>
    80002ba6:	b779                	j	80002b34 <usertrap+0x9c>
  if (killed(p))
    80002ba8:	4901                	li	s2,0
    exit(-1);
    80002baa:	557d                	li	a0,-1
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	6be080e7          	jalr	1726(ra) # 8000226a <exit>
  if (which_dev == 2)
    80002bb4:	4789                	li	a5,2
    80002bb6:	f8f915e3          	bne	s2,a5,80002b40 <usertrap+0xa8>
    if (p->is_sigalarm)
    80002bba:	1744a783          	lw	a5,372(s1)
    80002bbe:	cf81                	beqz	a5,80002bd6 <usertrap+0x13e>
      time_since_called = ticks - p->time_called_at;
    80002bc0:	1784a683          	lw	a3,376(s1)
      if (time_since_called >= p->ticks)
    80002bc4:	17c4a703          	lw	a4,380(s1)
    80002bc8:	00006797          	auipc	a5,0x6
    80002bcc:	d187a783          	lw	a5,-744(a5) # 800088e0 <ticks>
    80002bd0:	9f95                	subw	a5,a5,a3
    80002bd2:	04e7dc63          	bge	a5,a4,80002c2a <usertrap+0x192>
    int time_slices[] = {1, 3, 9, 15};
    80002bd6:	4785                	li	a5,1
    80002bd8:	f8f42823          	sw	a5,-112(s0)
    80002bdc:	478d                	li	a5,3
    80002bde:	f8f42a23          	sw	a5,-108(s0)
    80002be2:	47a5                	li	a5,9
    80002be4:	f8f42c23          	sw	a5,-104(s0)
    80002be8:	47bd                	li	a5,15
    80002bea:	f8f42e23          	sw	a5,-100(s0)
    p->run_time_in_queue++;
    80002bee:	19c4a783          	lw	a5,412(s1)
    80002bf2:	2785                	addiw	a5,a5,1
    80002bf4:	18f4ae23          	sw	a5,412(s1)
    int time_slice = time_slices[p->current_queue];
    80002bf8:	1904a783          	lw	a5,400(s1)
    80002bfc:	078a                	slli	a5,a5,0x2
    80002bfe:	fa040713          	addi	a4,s0,-96
    80002c02:	97ba                	add	a5,a5,a4
    80002c04:	ff07ac03          	lw	s8,-16(a5)
    for (struct proc *pl = proc; pl < &proc[NPROC]; pl++)
    80002c08:	0000e497          	auipc	s1,0xe
    80002c0c:	37848493          	addi	s1,s1,888 # 80010f80 <proc>
    int yield_flag = 0;
    80002c10:	4a01                	li	s4,0
      if (pl->state == RUNNABLE)
    80002c12:	498d                	li	s3,3
          yield_flag = 1;
    80002c14:	4b85                	li	s7,1
          if (ticks - pl->last_time_run_in_queue >= wait_time)
    80002c16:	00006b17          	auipc	s6,0x6
    80002c1a:	ccab0b13          	addi	s6,s6,-822 # 800088e0 <ticks>
    80002c1e:	4af5                	li	s5,29
    for (struct proc *pl = proc; pl < &proc[NPROC]; pl++)
    80002c20:	00015917          	auipc	s2,0x15
    80002c24:	b6090913          	addi	s2,s2,-1184 # 80017780 <tickslock>
    80002c28:	a891                	j	80002c7c <usertrap+0x1e4>
        p->alarm_trapframe = kalloc();
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	ed0080e7          	jalr	-304(ra) # 80000afa <kalloc>
    80002c32:	18a4b423          	sd	a0,392(s1)
        memmove(p->alarm_trapframe, p->trapframe, PGSIZE);
    80002c36:	6605                	lui	a2,0x1
    80002c38:	6cac                	ld	a1,88(s1)
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	10c080e7          	jalr	268(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->alarm_handler;
    80002c42:	6cbc                	ld	a5,88(s1)
    80002c44:	1804b703          	ld	a4,384(s1)
    80002c48:	ef98                	sd	a4,24(a5)
        p->is_sigalarm = 0;
    80002c4a:	1604aa23          	sw	zero,372(s1)
        p->time_called_at = 0;
    80002c4e:	1604ac23          	sw	zero,376(s1)
    80002c52:	b751                	j	80002bd6 <usertrap+0x13e>
        if (pl->current_queue < myproc()->current_queue)
    80002c54:	1904ac83          	lw	s9,400(s1)
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	d6e080e7          	jalr	-658(ra) # 800019c6 <myproc>
    80002c60:	19052783          	lw	a5,400(a0)
    80002c64:	00fcd363          	bge	s9,a5,80002c6a <usertrap+0x1d2>
          yield_flag = 1;
    80002c68:	8a5e                	mv	s4,s7
      release(&pl->lock);
    80002c6a:	8526                	mv	a0,s1
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	032080e7          	jalr	50(ra) # 80000c9e <release>
    for (struct proc *pl = proc; pl < &proc[NPROC]; pl++)
    80002c74:	1a048493          	addi	s1,s1,416
    80002c78:	03248e63          	beq	s1,s2,80002cb4 <usertrap+0x21c>
      acquire(&pl->lock);
    80002c7c:	8526                	mv	a0,s1
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	f6c080e7          	jalr	-148(ra) # 80000bea <acquire>
      if (pl->state == RUNNABLE)
    80002c86:	4c9c                	lw	a5,24(s1)
    80002c88:	ff3791e3          	bne	a5,s3,80002c6a <usertrap+0x1d2>
        if (pl->current_queue != 0)
    80002c8c:	1904a783          	lw	a5,400(s1)
    80002c90:	d3f1                	beqz	a5,80002c54 <usertrap+0x1bc>
          if (ticks - pl->last_time_run_in_queue >= wait_time)
    80002c92:	000b2683          	lw	a3,0(s6)
    80002c96:	1984a703          	lw	a4,408(s1)
    80002c9a:	40e6873b          	subw	a4,a3,a4
    80002c9e:	faeafbe3          	bgeu	s5,a4,80002c54 <usertrap+0x1bc>
            pl->current_queue--;
    80002ca2:	37fd                	addiw	a5,a5,-1
    80002ca4:	18f4a823          	sw	a5,400(s1)
            pl->entry_time_in_queue = ticks;
    80002ca8:	2681                	sext.w	a3,a3
    80002caa:	18d4aa23          	sw	a3,404(s1)
            pl->last_time_run_in_queue = ticks;
    80002cae:	18d4ac23          	sw	a3,408(s1)
    80002cb2:	b74d                	j	80002c54 <usertrap+0x1bc>
    struct proc *curr_proc = myproc();
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	d12080e7          	jalr	-750(ra) # 800019c6 <myproc>
    if (time_slice >= curr_proc->run_time_in_queue)
    80002cbc:	19c52783          	lw	a5,412(a0)
    80002cc0:	02fc4763          	blt	s8,a5,80002cee <usertrap+0x256>
      if (curr_proc->current_queue < 3)
    80002cc4:	19052783          	lw	a5,400(a0)
    80002cc8:	4709                	li	a4,2
    80002cca:	00f74563          	blt	a4,a5,80002cd4 <usertrap+0x23c>
        curr_proc->current_queue++;
    80002cce:	2785                	addiw	a5,a5,1
    80002cd0:	18f52823          	sw	a5,400(a0)
      curr_proc->entry_time_in_queue = ticks;
    80002cd4:	00006797          	auipc	a5,0x6
    80002cd8:	c0c7a783          	lw	a5,-1012(a5) # 800088e0 <ticks>
    80002cdc:	18f52a23          	sw	a5,404(a0)
      curr_proc->run_time_in_queue = 0;
    80002ce0:	18052e23          	sw	zero,412(a0)
      yield();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	3fa080e7          	jalr	1018(ra) # 800020de <yield>
    80002cec:	bd91                	j	80002b40 <usertrap+0xa8>
    else if (yield_flag)
    80002cee:	e40a09e3          	beqz	s4,80002b40 <usertrap+0xa8>
      curr_proc->entry_time_in_queue = ticks;
    80002cf2:	00006797          	auipc	a5,0x6
    80002cf6:	bee7a783          	lw	a5,-1042(a5) # 800088e0 <ticks>
    80002cfa:	18f52a23          	sw	a5,404(a0)
      curr_proc->run_time_in_queue = 0;
    80002cfe:	18052e23          	sw	zero,412(a0)
      yield();
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	3dc080e7          	jalr	988(ra) # 800020de <yield>
    80002d0a:	bd1d                	j	80002b40 <usertrap+0xa8>

0000000080002d0c <kerneltrap>:
{
    80002d0c:	7119                	addi	sp,sp,-128
    80002d0e:	fc86                	sd	ra,120(sp)
    80002d10:	f8a2                	sd	s0,112(sp)
    80002d12:	f4a6                	sd	s1,104(sp)
    80002d14:	f0ca                	sd	s2,96(sp)
    80002d16:	ecce                	sd	s3,88(sp)
    80002d18:	e8d2                	sd	s4,80(sp)
    80002d1a:	e4d6                	sd	s5,72(sp)
    80002d1c:	e0da                	sd	s6,64(sp)
    80002d1e:	fc5e                	sd	s7,56(sp)
    80002d20:	f862                	sd	s8,48(sp)
    80002d22:	f466                	sd	s9,40(sp)
    80002d24:	f06a                	sd	s10,32(sp)
    80002d26:	ec6e                	sd	s11,24(sp)
    80002d28:	0100                	addi	s0,sp,128
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d2a:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d2e:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d32:	142024f3          	csrr	s1,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002d36:	10097793          	andi	a5,s2,256
    80002d3a:	c3a1                	beqz	a5,80002d7a <kerneltrap+0x6e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d3c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d40:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002d42:	e7a1                	bnez	a5,80002d8a <kerneltrap+0x7e>
  if ((which_dev = devintr()) == 0)
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	cb2080e7          	jalr	-846(ra) # 800029f6 <devintr>
    80002d4c:	c539                	beqz	a0,80002d9a <kerneltrap+0x8e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d4e:	4789                	li	a5,2
    80002d50:	08f50263          	beq	a0,a5,80002dd4 <kerneltrap+0xc8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d54:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d58:	10091073          	csrw	sstatus,s2
}
    80002d5c:	70e6                	ld	ra,120(sp)
    80002d5e:	7446                	ld	s0,112(sp)
    80002d60:	74a6                	ld	s1,104(sp)
    80002d62:	7906                	ld	s2,96(sp)
    80002d64:	69e6                	ld	s3,88(sp)
    80002d66:	6a46                	ld	s4,80(sp)
    80002d68:	6aa6                	ld	s5,72(sp)
    80002d6a:	6b06                	ld	s6,64(sp)
    80002d6c:	7be2                	ld	s7,56(sp)
    80002d6e:	7c42                	ld	s8,48(sp)
    80002d70:	7ca2                	ld	s9,40(sp)
    80002d72:	7d02                	ld	s10,32(sp)
    80002d74:	6de2                	ld	s11,24(sp)
    80002d76:	6109                	addi	sp,sp,128
    80002d78:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d7a:	00005517          	auipc	a0,0x5
    80002d7e:	61650513          	addi	a0,a0,1558 # 80008390 <states.1743+0xc8>
    80002d82:	ffffd097          	auipc	ra,0xffffd
    80002d86:	7c2080e7          	jalr	1986(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d8a:	00005517          	auipc	a0,0x5
    80002d8e:	62e50513          	addi	a0,a0,1582 # 800083b8 <states.1743+0xf0>
    80002d92:	ffffd097          	auipc	ra,0xffffd
    80002d96:	7b2080e7          	jalr	1970(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002d9a:	85a6                	mv	a1,s1
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	63c50513          	addi	a0,a0,1596 # 800083d8 <states.1743+0x110>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	7ea080e7          	jalr	2026(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dac:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002db0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002db4:	00005517          	auipc	a0,0x5
    80002db8:	63450513          	addi	a0,a0,1588 # 800083e8 <states.1743+0x120>
    80002dbc:	ffffd097          	auipc	ra,0xffffd
    80002dc0:	7d2080e7          	jalr	2002(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002dc4:	00005517          	auipc	a0,0x5
    80002dc8:	63c50513          	addi	a0,a0,1596 # 80008400 <states.1743+0x138>
    80002dcc:	ffffd097          	auipc	ra,0xffffd
    80002dd0:	778080e7          	jalr	1912(ra) # 80000544 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	bf2080e7          	jalr	-1038(ra) # 800019c6 <myproc>
    80002ddc:	dd25                	beqz	a0,80002d54 <kerneltrap+0x48>
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	be8080e7          	jalr	-1048(ra) # 800019c6 <myproc>
    80002de6:	4d18                	lw	a4,24(a0)
    80002de8:	4791                	li	a5,4
    80002dea:	f6f715e3          	bne	a4,a5,80002d54 <kerneltrap+0x48>
    struct proc *p = myproc();
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	bd8080e7          	jalr	-1064(ra) # 800019c6 <myproc>
    int time_slices[] = {1, 3, 9, 15};
    80002df6:	4785                	li	a5,1
    80002df8:	f8f42023          	sw	a5,-128(s0)
    80002dfc:	478d                	li	a5,3
    80002dfe:	f8f42223          	sw	a5,-124(s0)
    80002e02:	47a5                	li	a5,9
    80002e04:	f8f42423          	sw	a5,-120(s0)
    80002e08:	47bd                	li	a5,15
    80002e0a:	f8f42623          	sw	a5,-116(s0)
    p->run_time_in_queue++;
    80002e0e:	19c52783          	lw	a5,412(a0)
    80002e12:	2785                	addiw	a5,a5,1
    80002e14:	18f52e23          	sw	a5,412(a0)
    int time_slice = time_slices[p->current_queue];
    80002e18:	19052783          	lw	a5,400(a0)
    80002e1c:	078a                	slli	a5,a5,0x2
    80002e1e:	f9040713          	addi	a4,s0,-112
    80002e22:	97ba                	add	a5,a5,a4
    80002e24:	ff07ad03          	lw	s10,-16(a5)
    for (struct proc *pl = proc; pl < &proc[NPROC]; pl++)
    80002e28:	0000e497          	auipc	s1,0xe
    80002e2c:	15848493          	addi	s1,s1,344 # 80010f80 <proc>
    int yield_flag = 0;
    80002e30:	4b01                	li	s6,0
      if (pl->state == RUNNABLE)
    80002e32:	4a8d                	li	s5,3
          yield_flag = 1;
    80002e34:	4c85                	li	s9,1
          if (ticks - pl->last_time_run_in_queue >= wait_time)
    80002e36:	00006c17          	auipc	s8,0x6
    80002e3a:	aaac0c13          	addi	s8,s8,-1366 # 800088e0 <ticks>
    80002e3e:	4bf5                	li	s7,29
    for (struct proc *pl = proc; pl < &proc[NPROC]; pl++)
    80002e40:	00015a17          	auipc	s4,0x15
    80002e44:	940a0a13          	addi	s4,s4,-1728 # 80017780 <tickslock>
    80002e48:	a02d                	j	80002e72 <kerneltrap+0x166>
        if (pl->current_queue < myproc()->current_queue)
    80002e4a:	1904ad83          	lw	s11,400(s1)
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	b78080e7          	jalr	-1160(ra) # 800019c6 <myproc>
    80002e56:	19052783          	lw	a5,400(a0)
    80002e5a:	00fdd363          	bge	s11,a5,80002e60 <kerneltrap+0x154>
          yield_flag = 1;
    80002e5e:	8b66                	mv	s6,s9
      release(&pl->lock);
    80002e60:	8526                	mv	a0,s1
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	e3c080e7          	jalr	-452(ra) # 80000c9e <release>
    for (struct proc *pl = proc; pl < &proc[NPROC]; pl++)
    80002e6a:	1a048493          	addi	s1,s1,416
    80002e6e:	03448e63          	beq	s1,s4,80002eaa <kerneltrap+0x19e>
      acquire(&pl->lock);
    80002e72:	8526                	mv	a0,s1
    80002e74:	ffffe097          	auipc	ra,0xffffe
    80002e78:	d76080e7          	jalr	-650(ra) # 80000bea <acquire>
      if (pl->state == RUNNABLE)
    80002e7c:	4c9c                	lw	a5,24(s1)
    80002e7e:	ff5791e3          	bne	a5,s5,80002e60 <kerneltrap+0x154>
        if (pl->current_queue != 0)
    80002e82:	1904a783          	lw	a5,400(s1)
    80002e86:	d3f1                	beqz	a5,80002e4a <kerneltrap+0x13e>
          if (ticks - pl->last_time_run_in_queue >= wait_time)
    80002e88:	000c2683          	lw	a3,0(s8)
    80002e8c:	1984a703          	lw	a4,408(s1)
    80002e90:	40e6873b          	subw	a4,a3,a4
    80002e94:	faebfbe3          	bgeu	s7,a4,80002e4a <kerneltrap+0x13e>
            pl->current_queue--;
    80002e98:	37fd                	addiw	a5,a5,-1
    80002e9a:	18f4a823          	sw	a5,400(s1)
            pl->entry_time_in_queue = ticks;
    80002e9e:	2681                	sext.w	a3,a3
    80002ea0:	18d4aa23          	sw	a3,404(s1)
            pl->last_time_run_in_queue = ticks;
    80002ea4:	18d4ac23          	sw	a3,408(s1)
    80002ea8:	b74d                	j	80002e4a <kerneltrap+0x13e>
    struct proc *curr_proc = myproc();
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	b1c080e7          	jalr	-1252(ra) # 800019c6 <myproc>
    if (time_slice >= curr_proc->run_time_in_queue)
    80002eb2:	19c52783          	lw	a5,412(a0)
    80002eb6:	02fd4763          	blt	s10,a5,80002ee4 <kerneltrap+0x1d8>
      if (curr_proc->current_queue < 3)
    80002eba:	19052783          	lw	a5,400(a0)
    80002ebe:	4709                	li	a4,2
    80002ec0:	00f74563          	blt	a4,a5,80002eca <kerneltrap+0x1be>
        curr_proc->current_queue++;
    80002ec4:	2785                	addiw	a5,a5,1
    80002ec6:	18f52823          	sw	a5,400(a0)
      curr_proc->entry_time_in_queue = ticks;
    80002eca:	00006797          	auipc	a5,0x6
    80002ece:	a167a783          	lw	a5,-1514(a5) # 800088e0 <ticks>
    80002ed2:	18f52a23          	sw	a5,404(a0)
      curr_proc->run_time_in_queue = 0;
    80002ed6:	18052e23          	sw	zero,412(a0)
      yield();
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	204080e7          	jalr	516(ra) # 800020de <yield>
    80002ee2:	bd8d                	j	80002d54 <kerneltrap+0x48>
    else if (yield_flag)
    80002ee4:	e60b08e3          	beqz	s6,80002d54 <kerneltrap+0x48>
      curr_proc->entry_time_in_queue = ticks;
    80002ee8:	00006797          	auipc	a5,0x6
    80002eec:	9f87a783          	lw	a5,-1544(a5) # 800088e0 <ticks>
    80002ef0:	18f52a23          	sw	a5,404(a0)
      curr_proc->run_time_in_queue = 0;
    80002ef4:	18052e23          	sw	zero,412(a0)
      yield();
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	1e6080e7          	jalr	486(ra) # 800020de <yield>
    80002f00:	bd91                	j	80002d54 <kerneltrap+0x48>

0000000080002f02 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	e426                	sd	s1,8(sp)
    80002f0a:	1000                	addi	s0,sp,32
    80002f0c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	ab8080e7          	jalr	-1352(ra) # 800019c6 <myproc>
  switch (n) {
    80002f16:	4795                	li	a5,5
    80002f18:	0497e163          	bltu	a5,s1,80002f5a <argraw+0x58>
    80002f1c:	048a                	slli	s1,s1,0x2
    80002f1e:	00005717          	auipc	a4,0x5
    80002f22:	51a70713          	addi	a4,a4,1306 # 80008438 <states.1743+0x170>
    80002f26:	94ba                	add	s1,s1,a4
    80002f28:	409c                	lw	a5,0(s1)
    80002f2a:	97ba                	add	a5,a5,a4
    80002f2c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f2e:	6d3c                	ld	a5,88(a0)
    80002f30:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	64a2                	ld	s1,8(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret
    return p->trapframe->a1;
    80002f3c:	6d3c                	ld	a5,88(a0)
    80002f3e:	7fa8                	ld	a0,120(a5)
    80002f40:	bfcd                	j	80002f32 <argraw+0x30>
    return p->trapframe->a2;
    80002f42:	6d3c                	ld	a5,88(a0)
    80002f44:	63c8                	ld	a0,128(a5)
    80002f46:	b7f5                	j	80002f32 <argraw+0x30>
    return p->trapframe->a3;
    80002f48:	6d3c                	ld	a5,88(a0)
    80002f4a:	67c8                	ld	a0,136(a5)
    80002f4c:	b7dd                	j	80002f32 <argraw+0x30>
    return p->trapframe->a4;
    80002f4e:	6d3c                	ld	a5,88(a0)
    80002f50:	6bc8                	ld	a0,144(a5)
    80002f52:	b7c5                	j	80002f32 <argraw+0x30>
    return p->trapframe->a5;
    80002f54:	6d3c                	ld	a5,88(a0)
    80002f56:	6fc8                	ld	a0,152(a5)
    80002f58:	bfe9                	j	80002f32 <argraw+0x30>
  panic("argraw");
    80002f5a:	00005517          	auipc	a0,0x5
    80002f5e:	4b650513          	addi	a0,a0,1206 # 80008410 <states.1743+0x148>
    80002f62:	ffffd097          	auipc	ra,0xffffd
    80002f66:	5e2080e7          	jalr	1506(ra) # 80000544 <panic>

0000000080002f6a <fetchaddr>:
{
    80002f6a:	1101                	addi	sp,sp,-32
    80002f6c:	ec06                	sd	ra,24(sp)
    80002f6e:	e822                	sd	s0,16(sp)
    80002f70:	e426                	sd	s1,8(sp)
    80002f72:	e04a                	sd	s2,0(sp)
    80002f74:	1000                	addi	s0,sp,32
    80002f76:	84aa                	mv	s1,a0
    80002f78:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	a4c080e7          	jalr	-1460(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f82:	653c                	ld	a5,72(a0)
    80002f84:	02f4f863          	bgeu	s1,a5,80002fb4 <fetchaddr+0x4a>
    80002f88:	00848713          	addi	a4,s1,8
    80002f8c:	02e7e663          	bltu	a5,a4,80002fb8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f90:	46a1                	li	a3,8
    80002f92:	8626                	mv	a2,s1
    80002f94:	85ca                	mv	a1,s2
    80002f96:	6928                	ld	a0,80(a0)
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	778080e7          	jalr	1912(ra) # 80001710 <copyin>
    80002fa0:	00a03533          	snez	a0,a0
    80002fa4:	40a00533          	neg	a0,a0
}
    80002fa8:	60e2                	ld	ra,24(sp)
    80002faa:	6442                	ld	s0,16(sp)
    80002fac:	64a2                	ld	s1,8(sp)
    80002fae:	6902                	ld	s2,0(sp)
    80002fb0:	6105                	addi	sp,sp,32
    80002fb2:	8082                	ret
    return -1;
    80002fb4:	557d                	li	a0,-1
    80002fb6:	bfcd                	j	80002fa8 <fetchaddr+0x3e>
    80002fb8:	557d                	li	a0,-1
    80002fba:	b7fd                	j	80002fa8 <fetchaddr+0x3e>

0000000080002fbc <fetchstr>:
{
    80002fbc:	7179                	addi	sp,sp,-48
    80002fbe:	f406                	sd	ra,40(sp)
    80002fc0:	f022                	sd	s0,32(sp)
    80002fc2:	ec26                	sd	s1,24(sp)
    80002fc4:	e84a                	sd	s2,16(sp)
    80002fc6:	e44e                	sd	s3,8(sp)
    80002fc8:	1800                	addi	s0,sp,48
    80002fca:	892a                	mv	s2,a0
    80002fcc:	84ae                	mv	s1,a1
    80002fce:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	9f6080e7          	jalr	-1546(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fd8:	86ce                	mv	a3,s3
    80002fda:	864a                	mv	a2,s2
    80002fdc:	85a6                	mv	a1,s1
    80002fde:	6928                	ld	a0,80(a0)
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	7bc080e7          	jalr	1980(ra) # 8000179c <copyinstr>
    80002fe8:	00054e63          	bltz	a0,80003004 <fetchstr+0x48>
  return strlen(buf);
    80002fec:	8526                	mv	a0,s1
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	e7c080e7          	jalr	-388(ra) # 80000e6a <strlen>
}
    80002ff6:	70a2                	ld	ra,40(sp)
    80002ff8:	7402                	ld	s0,32(sp)
    80002ffa:	64e2                	ld	s1,24(sp)
    80002ffc:	6942                	ld	s2,16(sp)
    80002ffe:	69a2                	ld	s3,8(sp)
    80003000:	6145                	addi	sp,sp,48
    80003002:	8082                	ret
    return -1;
    80003004:	557d                	li	a0,-1
    80003006:	bfc5                	j	80002ff6 <fetchstr+0x3a>

0000000080003008 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003008:	1101                	addi	sp,sp,-32
    8000300a:	ec06                	sd	ra,24(sp)
    8000300c:	e822                	sd	s0,16(sp)
    8000300e:	e426                	sd	s1,8(sp)
    80003010:	1000                	addi	s0,sp,32
    80003012:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003014:	00000097          	auipc	ra,0x0
    80003018:	eee080e7          	jalr	-274(ra) # 80002f02 <argraw>
    8000301c:	c088                	sw	a0,0(s1)
}
    8000301e:	60e2                	ld	ra,24(sp)
    80003020:	6442                	ld	s0,16(sp)
    80003022:	64a2                	ld	s1,8(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	1000                	addi	s0,sp,32
    80003032:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003034:	00000097          	auipc	ra,0x0
    80003038:	ece080e7          	jalr	-306(ra) # 80002f02 <argraw>
    8000303c:	e088                	sd	a0,0(s1)
}
    8000303e:	60e2                	ld	ra,24(sp)
    80003040:	6442                	ld	s0,16(sp)
    80003042:	64a2                	ld	s1,8(sp)
    80003044:	6105                	addi	sp,sp,32
    80003046:	8082                	ret

0000000080003048 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003048:	7179                	addi	sp,sp,-48
    8000304a:	f406                	sd	ra,40(sp)
    8000304c:	f022                	sd	s0,32(sp)
    8000304e:	ec26                	sd	s1,24(sp)
    80003050:	e84a                	sd	s2,16(sp)
    80003052:	1800                	addi	s0,sp,48
    80003054:	84ae                	mv	s1,a1
    80003056:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003058:	fd840593          	addi	a1,s0,-40
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	fcc080e7          	jalr	-52(ra) # 80003028 <argaddr>
  return fetchstr(addr, buf, max);
    80003064:	864a                	mv	a2,s2
    80003066:	85a6                	mv	a1,s1
    80003068:	fd843503          	ld	a0,-40(s0)
    8000306c:	00000097          	auipc	ra,0x0
    80003070:	f50080e7          	jalr	-176(ra) # 80002fbc <fetchstr>
}
    80003074:	70a2                	ld	ra,40(sp)
    80003076:	7402                	ld	s0,32(sp)
    80003078:	64e2                	ld	s1,24(sp)
    8000307a:	6942                	ld	s2,16(sp)
    8000307c:	6145                	addi	sp,sp,48
    8000307e:	8082                	ret

0000000080003080 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80003080:	1101                	addi	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	e426                	sd	s1,8(sp)
    80003088:	e04a                	sd	s2,0(sp)
    8000308a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	93a080e7          	jalr	-1734(ra) # 800019c6 <myproc>
    80003094:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003096:	05853903          	ld	s2,88(a0)
    8000309a:	0a893783          	ld	a5,168(s2)
    8000309e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030a2:	37fd                	addiw	a5,a5,-1
    800030a4:	4761                	li	a4,24
    800030a6:	00f76f63          	bltu	a4,a5,800030c4 <syscall+0x44>
    800030aa:	00369713          	slli	a4,a3,0x3
    800030ae:	00005797          	auipc	a5,0x5
    800030b2:	3a278793          	addi	a5,a5,930 # 80008450 <syscalls>
    800030b6:	97ba                	add	a5,a5,a4
    800030b8:	639c                	ld	a5,0(a5)
    800030ba:	c789                	beqz	a5,800030c4 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800030bc:	9782                	jalr	a5
    800030be:	06a93823          	sd	a0,112(s2)
    800030c2:	a839                	j	800030e0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030c4:	15848613          	addi	a2,s1,344
    800030c8:	588c                	lw	a1,48(s1)
    800030ca:	00005517          	auipc	a0,0x5
    800030ce:	34e50513          	addi	a0,a0,846 # 80008418 <states.1743+0x150>
    800030d2:	ffffd097          	auipc	ra,0xffffd
    800030d6:	4bc080e7          	jalr	1212(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030da:	6cbc                	ld	a5,88(s1)
    800030dc:	577d                	li	a4,-1
    800030de:	fbb8                	sd	a4,112(a5)
  }
}
    800030e0:	60e2                	ld	ra,24(sp)
    800030e2:	6442                	ld	s0,16(sp)
    800030e4:	64a2                	ld	s1,8(sp)
    800030e6:	6902                	ld	s2,0(sp)
    800030e8:	6105                	addi	sp,sp,32
    800030ea:	8082                	ret

00000000800030ec <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800030f4:	fec40593          	addi	a1,s0,-20
    800030f8:	4501                	li	a0,0
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	f0e080e7          	jalr	-242(ra) # 80003008 <argint>
  exit(n);
    80003102:	fec42503          	lw	a0,-20(s0)
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	164080e7          	jalr	356(ra) # 8000226a <exit>
  return 0; // not reached
}
    8000310e:	4501                	li	a0,0
    80003110:	60e2                	ld	ra,24(sp)
    80003112:	6442                	ld	s0,16(sp)
    80003114:	6105                	addi	sp,sp,32
    80003116:	8082                	ret

0000000080003118 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003118:	1141                	addi	sp,sp,-16
    8000311a:	e406                	sd	ra,8(sp)
    8000311c:	e022                	sd	s0,0(sp)
    8000311e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003120:	fffff097          	auipc	ra,0xfffff
    80003124:	8a6080e7          	jalr	-1882(ra) # 800019c6 <myproc>
}
    80003128:	5908                	lw	a0,48(a0)
    8000312a:	60a2                	ld	ra,8(sp)
    8000312c:	6402                	ld	s0,0(sp)
    8000312e:	0141                	addi	sp,sp,16
    80003130:	8082                	ret

0000000080003132 <sys_fork>:

uint64
sys_fork(void)
{
    80003132:	1141                	addi	sp,sp,-16
    80003134:	e406                	sd	ra,8(sp)
    80003136:	e022                	sd	s0,0(sp)
    80003138:	0800                	addi	s0,sp,16
  return fork();
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	c84080e7          	jalr	-892(ra) # 80001dbe <fork>
}
    80003142:	60a2                	ld	ra,8(sp)
    80003144:	6402                	ld	s0,0(sp)
    80003146:	0141                	addi	sp,sp,16
    80003148:	8082                	ret

000000008000314a <sys_wait>:

uint64
sys_wait(void)
{
    8000314a:	1101                	addi	sp,sp,-32
    8000314c:	ec06                	sd	ra,24(sp)
    8000314e:	e822                	sd	s0,16(sp)
    80003150:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003152:	fe840593          	addi	a1,s0,-24
    80003156:	4501                	li	a0,0
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	ed0080e7          	jalr	-304(ra) # 80003028 <argaddr>
  return wait(p);
    80003160:	fe843503          	ld	a0,-24(s0)
    80003164:	fffff097          	auipc	ra,0xfffff
    80003168:	2cc080e7          	jalr	716(ra) # 80002430 <wait>
}
    8000316c:	60e2                	ld	ra,24(sp)
    8000316e:	6442                	ld	s0,16(sp)
    80003170:	6105                	addi	sp,sp,32
    80003172:	8082                	ret

0000000080003174 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003174:	7179                	addi	sp,sp,-48
    80003176:	f406                	sd	ra,40(sp)
    80003178:	f022                	sd	s0,32(sp)
    8000317a:	ec26                	sd	s1,24(sp)
    8000317c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000317e:	fdc40593          	addi	a1,s0,-36
    80003182:	4501                	li	a0,0
    80003184:	00000097          	auipc	ra,0x0
    80003188:	e84080e7          	jalr	-380(ra) # 80003008 <argint>
  addr = myproc()->sz;
    8000318c:	fffff097          	auipc	ra,0xfffff
    80003190:	83a080e7          	jalr	-1990(ra) # 800019c6 <myproc>
    80003194:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003196:	fdc42503          	lw	a0,-36(s0)
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	bc8080e7          	jalr	-1080(ra) # 80001d62 <growproc>
    800031a2:	00054863          	bltz	a0,800031b2 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800031a6:	8526                	mv	a0,s1
    800031a8:	70a2                	ld	ra,40(sp)
    800031aa:	7402                	ld	s0,32(sp)
    800031ac:	64e2                	ld	s1,24(sp)
    800031ae:	6145                	addi	sp,sp,48
    800031b0:	8082                	ret
    return -1;
    800031b2:	54fd                	li	s1,-1
    800031b4:	bfcd                	j	800031a6 <sys_sbrk+0x32>

00000000800031b6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031b6:	7139                	addi	sp,sp,-64
    800031b8:	fc06                	sd	ra,56(sp)
    800031ba:	f822                	sd	s0,48(sp)
    800031bc:	f426                	sd	s1,40(sp)
    800031be:	f04a                	sd	s2,32(sp)
    800031c0:	ec4e                	sd	s3,24(sp)
    800031c2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800031c4:	fcc40593          	addi	a1,s0,-52
    800031c8:	4501                	li	a0,0
    800031ca:	00000097          	auipc	ra,0x0
    800031ce:	e3e080e7          	jalr	-450(ra) # 80003008 <argint>
  acquire(&tickslock);
    800031d2:	00014517          	auipc	a0,0x14
    800031d6:	5ae50513          	addi	a0,a0,1454 # 80017780 <tickslock>
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	a10080e7          	jalr	-1520(ra) # 80000bea <acquire>
  ticks0 = ticks;
    800031e2:	00005917          	auipc	s2,0x5
    800031e6:	6fe92903          	lw	s2,1790(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    800031ea:	fcc42783          	lw	a5,-52(s0)
    800031ee:	cf9d                	beqz	a5,8000322c <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031f0:	00014997          	auipc	s3,0x14
    800031f4:	59098993          	addi	s3,s3,1424 # 80017780 <tickslock>
    800031f8:	00005497          	auipc	s1,0x5
    800031fc:	6e848493          	addi	s1,s1,1768 # 800088e0 <ticks>
    if (killed(myproc()))
    80003200:	ffffe097          	auipc	ra,0xffffe
    80003204:	7c6080e7          	jalr	1990(ra) # 800019c6 <myproc>
    80003208:	fffff097          	auipc	ra,0xfffff
    8000320c:	1f6080e7          	jalr	502(ra) # 800023fe <killed>
    80003210:	ed15                	bnez	a0,8000324c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003212:	85ce                	mv	a1,s3
    80003214:	8526                	mv	a0,s1
    80003216:	fffff097          	auipc	ra,0xfffff
    8000321a:	f04080e7          	jalr	-252(ra) # 8000211a <sleep>
  while (ticks - ticks0 < n)
    8000321e:	409c                	lw	a5,0(s1)
    80003220:	412787bb          	subw	a5,a5,s2
    80003224:	fcc42703          	lw	a4,-52(s0)
    80003228:	fce7ece3          	bltu	a5,a4,80003200 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000322c:	00014517          	auipc	a0,0x14
    80003230:	55450513          	addi	a0,a0,1364 # 80017780 <tickslock>
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	a6a080e7          	jalr	-1430(ra) # 80000c9e <release>
  return 0;
    8000323c:	4501                	li	a0,0
}
    8000323e:	70e2                	ld	ra,56(sp)
    80003240:	7442                	ld	s0,48(sp)
    80003242:	74a2                	ld	s1,40(sp)
    80003244:	7902                	ld	s2,32(sp)
    80003246:	69e2                	ld	s3,24(sp)
    80003248:	6121                	addi	sp,sp,64
    8000324a:	8082                	ret
      release(&tickslock);
    8000324c:	00014517          	auipc	a0,0x14
    80003250:	53450513          	addi	a0,a0,1332 # 80017780 <tickslock>
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	a4a080e7          	jalr	-1462(ra) # 80000c9e <release>
      return -1;
    8000325c:	557d                	li	a0,-1
    8000325e:	b7c5                	j	8000323e <sys_sleep+0x88>

0000000080003260 <sys_kill>:

uint64
sys_kill(void)
{
    80003260:	1101                	addi	sp,sp,-32
    80003262:	ec06                	sd	ra,24(sp)
    80003264:	e822                	sd	s0,16(sp)
    80003266:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003268:	fec40593          	addi	a1,s0,-20
    8000326c:	4501                	li	a0,0
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	d9a080e7          	jalr	-614(ra) # 80003008 <argint>
  return kill(pid);
    80003276:	fec42503          	lw	a0,-20(s0)
    8000327a:	fffff097          	auipc	ra,0xfffff
    8000327e:	0d2080e7          	jalr	210(ra) # 8000234c <kill>
}
    80003282:	60e2                	ld	ra,24(sp)
    80003284:	6442                	ld	s0,16(sp)
    80003286:	6105                	addi	sp,sp,32
    80003288:	8082                	ret

000000008000328a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000328a:	1101                	addi	sp,sp,-32
    8000328c:	ec06                	sd	ra,24(sp)
    8000328e:	e822                	sd	s0,16(sp)
    80003290:	e426                	sd	s1,8(sp)
    80003292:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003294:	00014517          	auipc	a0,0x14
    80003298:	4ec50513          	addi	a0,a0,1260 # 80017780 <tickslock>
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	94e080e7          	jalr	-1714(ra) # 80000bea <acquire>
  xticks = ticks;
    800032a4:	00005497          	auipc	s1,0x5
    800032a8:	63c4a483          	lw	s1,1596(s1) # 800088e0 <ticks>
  release(&tickslock);
    800032ac:	00014517          	auipc	a0,0x14
    800032b0:	4d450513          	addi	a0,a0,1236 # 80017780 <tickslock>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	9ea080e7          	jalr	-1558(ra) # 80000c9e <release>
  return xticks;
}
    800032bc:	02049513          	slli	a0,s1,0x20
    800032c0:	9101                	srli	a0,a0,0x20
    800032c2:	60e2                	ld	ra,24(sp)
    800032c4:	6442                	ld	s0,16(sp)
    800032c6:	64a2                	ld	s1,8(sp)
    800032c8:	6105                	addi	sp,sp,32
    800032ca:	8082                	ret

00000000800032cc <sys_waitx>:

uint64
sys_waitx(void)
{
    800032cc:	7139                	addi	sp,sp,-64
    800032ce:	fc06                	sd	ra,56(sp)
    800032d0:	f822                	sd	s0,48(sp)
    800032d2:	f426                	sd	s1,40(sp)
    800032d4:	f04a                	sd	s2,32(sp)
    800032d6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800032d8:	fd840593          	addi	a1,s0,-40
    800032dc:	4501                	li	a0,0
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	d4a080e7          	jalr	-694(ra) # 80003028 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800032e6:	fd040593          	addi	a1,s0,-48
    800032ea:	4505                	li	a0,1
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	d3c080e7          	jalr	-708(ra) # 80003028 <argaddr>
  argaddr(2, &addr2);
    800032f4:	fc840593          	addi	a1,s0,-56
    800032f8:	4509                	li	a0,2
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	d2e080e7          	jalr	-722(ra) # 80003028 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003302:	fc040613          	addi	a2,s0,-64
    80003306:	fc440593          	addi	a1,s0,-60
    8000330a:	fd843503          	ld	a0,-40(s0)
    8000330e:	fffff097          	auipc	ra,0xfffff
    80003312:	3aa080e7          	jalr	938(ra) # 800026b8 <waitx>
    80003316:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	6ae080e7          	jalr	1710(ra) # 800019c6 <myproc>
    80003320:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003322:	4691                	li	a3,4
    80003324:	fc440613          	addi	a2,s0,-60
    80003328:	fd043583          	ld	a1,-48(s0)
    8000332c:	6928                	ld	a0,80(a0)
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	356080e7          	jalr	854(ra) # 80001684 <copyout>
    return -1;
    80003336:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003338:	00054f63          	bltz	a0,80003356 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000333c:	4691                	li	a3,4
    8000333e:	fc040613          	addi	a2,s0,-64
    80003342:	fc843583          	ld	a1,-56(s0)
    80003346:	68a8                	ld	a0,80(s1)
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	33c080e7          	jalr	828(ra) # 80001684 <copyout>
    80003350:	00054a63          	bltz	a0,80003364 <sys_waitx+0x98>
    return -1;
  return ret;
    80003354:	87ca                	mv	a5,s2
}
    80003356:	853e                	mv	a0,a5
    80003358:	70e2                	ld	ra,56(sp)
    8000335a:	7442                	ld	s0,48(sp)
    8000335c:	74a2                	ld	s1,40(sp)
    8000335e:	7902                	ld	s2,32(sp)
    80003360:	6121                	addi	sp,sp,64
    80003362:	8082                	ret
    return -1;
    80003364:	57fd                	li	a5,-1
    80003366:	bfc5                	j	80003356 <sys_waitx+0x8a>

0000000080003368 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80003368:	7179                	addi	sp,sp,-48
    8000336a:	f406                	sd	ra,40(sp)
    8000336c:	f022                	sd	s0,32(sp)
    8000336e:	ec26                	sd	s1,24(sp)
    80003370:	e84a                	sd	s2,16(sp)
    80003372:	1800                	addi	s0,sp,48
  int input_ticks;
  uint64 input_fn_addr;

  argint(0, &input_ticks);
    80003374:	fdc40593          	addi	a1,s0,-36
    80003378:	4501                	li	a0,0
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	c8e080e7          	jalr	-882(ra) # 80003008 <argint>
  argaddr(1, &input_fn_addr);
    80003382:	fd040593          	addi	a1,s0,-48
    80003386:	4505                	li	a0,1
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	ca0080e7          	jalr	-864(ra) # 80003028 <argaddr>

  if (input_ticks < 0 || input_fn_addr < 0)
    80003390:	fdc42783          	lw	a5,-36(s0)
  {
    return -1;
    80003394:	54fd                	li	s1,-1
  if (input_ticks < 0 || input_fn_addr < 0)
    80003396:	0007c963          	bltz	a5,800033a8 <sys_sigalarm+0x40>
  }
  if(myproc()->alarm_trapframe != 0 || myproc()->is_sigalarm == 1 || myproc()->ticks != 0 || myproc()->alarm_handler != 0 || myproc()->time_called_at != 0)
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	62c080e7          	jalr	1580(ra) # 800019c6 <myproc>
    800033a2:	18853783          	ld	a5,392(a0)
    800033a6:	cb81                	beqz	a5,800033b6 <sys_sigalarm+0x4e>
  myproc()->ticks = input_ticks;
  myproc()->alarm_handler = input_fn_addr;
  myproc()->time_called_at = ticks;

  return 0;
}
    800033a8:	8526                	mv	a0,s1
    800033aa:	70a2                	ld	ra,40(sp)
    800033ac:	7402                	ld	s0,32(sp)
    800033ae:	64e2                	ld	s1,24(sp)
    800033b0:	6942                	ld	s2,16(sp)
    800033b2:	6145                	addi	sp,sp,48
    800033b4:	8082                	ret
  if(myproc()->alarm_trapframe != 0 || myproc()->is_sigalarm == 1 || myproc()->ticks != 0 || myproc()->alarm_handler != 0 || myproc()->time_called_at != 0)
    800033b6:	ffffe097          	auipc	ra,0xffffe
    800033ba:	610080e7          	jalr	1552(ra) # 800019c6 <myproc>
    800033be:	17452703          	lw	a4,372(a0)
    800033c2:	4785                	li	a5,1
    800033c4:	fef702e3          	beq	a4,a5,800033a8 <sys_sigalarm+0x40>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	5fe080e7          	jalr	1534(ra) # 800019c6 <myproc>
    800033d0:	17c52783          	lw	a5,380(a0)
    800033d4:	fbf1                	bnez	a5,800033a8 <sys_sigalarm+0x40>
    800033d6:	ffffe097          	auipc	ra,0xffffe
    800033da:	5f0080e7          	jalr	1520(ra) # 800019c6 <myproc>
    800033de:	18053483          	ld	s1,384(a0)
    800033e2:	e8b1                	bnez	s1,80003436 <sys_sigalarm+0xce>
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	5e2080e7          	jalr	1506(ra) # 800019c6 <myproc>
    800033ec:	17852783          	lw	a5,376(a0)
    800033f0:	e7a9                	bnez	a5,8000343a <sys_sigalarm+0xd2>
  myproc()->is_sigalarm = 1;
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	5d4080e7          	jalr	1492(ra) # 800019c6 <myproc>
    800033fa:	4785                	li	a5,1
    800033fc:	16f52a23          	sw	a5,372(a0)
  myproc()->ticks = input_ticks;
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	5c6080e7          	jalr	1478(ra) # 800019c6 <myproc>
    80003408:	fdc42783          	lw	a5,-36(s0)
    8000340c:	16f52e23          	sw	a5,380(a0)
  myproc()->alarm_handler = input_fn_addr;
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	5b6080e7          	jalr	1462(ra) # 800019c6 <myproc>
    80003418:	fd043783          	ld	a5,-48(s0)
    8000341c:	18f53023          	sd	a5,384(a0)
  myproc()->time_called_at = ticks;
    80003420:	00005917          	auipc	s2,0x5
    80003424:	4c092903          	lw	s2,1216(s2) # 800088e0 <ticks>
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	59e080e7          	jalr	1438(ra) # 800019c6 <myproc>
    80003430:	17252c23          	sw	s2,376(a0)
  return 0;
    80003434:	bf95                	j	800033a8 <sys_sigalarm+0x40>
    return -1;
    80003436:	54fd                	li	s1,-1
    80003438:	bf85                	j	800033a8 <sys_sigalarm+0x40>
    8000343a:	54fd                	li	s1,-1
    8000343c:	b7b5                	j	800033a8 <sys_sigalarm+0x40>

000000008000343e <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	e426                	sd	s1,8(sp)
    80003446:	1000                	addi	s0,sp,32
  struct proc* p = myproc();
    80003448:	ffffe097          	auipc	ra,0xffffe
    8000344c:	57e080e7          	jalr	1406(ra) # 800019c6 <myproc>
    80003450:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alarm_trapframe, PGSIZE);
    80003452:	6605                	lui	a2,0x1
    80003454:	18853583          	ld	a1,392(a0)
    80003458:	6d28                	ld	a0,88(a0)
    8000345a:	ffffe097          	auipc	ra,0xffffe
    8000345e:	8ec080e7          	jalr	-1812(ra) # 80000d46 <memmove>
  kfree(p->alarm_trapframe);
    80003462:	1884b503          	ld	a0,392(s1)
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	598080e7          	jalr	1432(ra) # 800009fe <kfree>
  p->is_sigalarm = 1;
    8000346e:	4785                	li	a5,1
    80003470:	16f4aa23          	sw	a5,372(s1)
  p->alarm_trapframe = 0;
    80003474:	1804b423          	sd	zero,392(s1)
  p->time_called_at = 0;
    80003478:	1604ac23          	sw	zero,376(s1)

  return p->trapframe->a0;
    8000347c:	6cbc                	ld	a5,88(s1)
    8000347e:	7ba8                	ld	a0,112(a5)
    80003480:	60e2                	ld	ra,24(sp)
    80003482:	6442                	ld	s0,16(sp)
    80003484:	64a2                	ld	s1,8(sp)
    80003486:	6105                	addi	sp,sp,32
    80003488:	8082                	ret

000000008000348a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000348a:	7179                	addi	sp,sp,-48
    8000348c:	f406                	sd	ra,40(sp)
    8000348e:	f022                	sd	s0,32(sp)
    80003490:	ec26                	sd	s1,24(sp)
    80003492:	e84a                	sd	s2,16(sp)
    80003494:	e44e                	sd	s3,8(sp)
    80003496:	e052                	sd	s4,0(sp)
    80003498:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000349a:	00005597          	auipc	a1,0x5
    8000349e:	08658593          	addi	a1,a1,134 # 80008520 <syscalls+0xd0>
    800034a2:	00014517          	auipc	a0,0x14
    800034a6:	2f650513          	addi	a0,a0,758 # 80017798 <bcache>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	6b0080e7          	jalr	1712(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034b2:	0001c797          	auipc	a5,0x1c
    800034b6:	2e678793          	addi	a5,a5,742 # 8001f798 <bcache+0x8000>
    800034ba:	0001c717          	auipc	a4,0x1c
    800034be:	54670713          	addi	a4,a4,1350 # 8001fa00 <bcache+0x8268>
    800034c2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034c6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ca:	00014497          	auipc	s1,0x14
    800034ce:	2e648493          	addi	s1,s1,742 # 800177b0 <bcache+0x18>
    b->next = bcache.head.next;
    800034d2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034d4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034d6:	00005a17          	auipc	s4,0x5
    800034da:	052a0a13          	addi	s4,s4,82 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    800034de:	2b893783          	ld	a5,696(s2)
    800034e2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034e4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034e8:	85d2                	mv	a1,s4
    800034ea:	01048513          	addi	a0,s1,16
    800034ee:	00001097          	auipc	ra,0x1
    800034f2:	4c4080e7          	jalr	1220(ra) # 800049b2 <initsleeplock>
    bcache.head.next->prev = b;
    800034f6:	2b893783          	ld	a5,696(s2)
    800034fa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034fc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003500:	45848493          	addi	s1,s1,1112
    80003504:	fd349de3          	bne	s1,s3,800034de <binit+0x54>
  }
}
    80003508:	70a2                	ld	ra,40(sp)
    8000350a:	7402                	ld	s0,32(sp)
    8000350c:	64e2                	ld	s1,24(sp)
    8000350e:	6942                	ld	s2,16(sp)
    80003510:	69a2                	ld	s3,8(sp)
    80003512:	6a02                	ld	s4,0(sp)
    80003514:	6145                	addi	sp,sp,48
    80003516:	8082                	ret

0000000080003518 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003518:	7179                	addi	sp,sp,-48
    8000351a:	f406                	sd	ra,40(sp)
    8000351c:	f022                	sd	s0,32(sp)
    8000351e:	ec26                	sd	s1,24(sp)
    80003520:	e84a                	sd	s2,16(sp)
    80003522:	e44e                	sd	s3,8(sp)
    80003524:	1800                	addi	s0,sp,48
    80003526:	89aa                	mv	s3,a0
    80003528:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000352a:	00014517          	auipc	a0,0x14
    8000352e:	26e50513          	addi	a0,a0,622 # 80017798 <bcache>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	6b8080e7          	jalr	1720(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000353a:	0001c497          	auipc	s1,0x1c
    8000353e:	5164b483          	ld	s1,1302(s1) # 8001fa50 <bcache+0x82b8>
    80003542:	0001c797          	auipc	a5,0x1c
    80003546:	4be78793          	addi	a5,a5,1214 # 8001fa00 <bcache+0x8268>
    8000354a:	02f48f63          	beq	s1,a5,80003588 <bread+0x70>
    8000354e:	873e                	mv	a4,a5
    80003550:	a021                	j	80003558 <bread+0x40>
    80003552:	68a4                	ld	s1,80(s1)
    80003554:	02e48a63          	beq	s1,a4,80003588 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003558:	449c                	lw	a5,8(s1)
    8000355a:	ff379ce3          	bne	a5,s3,80003552 <bread+0x3a>
    8000355e:	44dc                	lw	a5,12(s1)
    80003560:	ff2799e3          	bne	a5,s2,80003552 <bread+0x3a>
      b->refcnt++;
    80003564:	40bc                	lw	a5,64(s1)
    80003566:	2785                	addiw	a5,a5,1
    80003568:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000356a:	00014517          	auipc	a0,0x14
    8000356e:	22e50513          	addi	a0,a0,558 # 80017798 <bcache>
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	72c080e7          	jalr	1836(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000357a:	01048513          	addi	a0,s1,16
    8000357e:	00001097          	auipc	ra,0x1
    80003582:	46e080e7          	jalr	1134(ra) # 800049ec <acquiresleep>
      return b;
    80003586:	a8b9                	j	800035e4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003588:	0001c497          	auipc	s1,0x1c
    8000358c:	4c04b483          	ld	s1,1216(s1) # 8001fa48 <bcache+0x82b0>
    80003590:	0001c797          	auipc	a5,0x1c
    80003594:	47078793          	addi	a5,a5,1136 # 8001fa00 <bcache+0x8268>
    80003598:	00f48863          	beq	s1,a5,800035a8 <bread+0x90>
    8000359c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000359e:	40bc                	lw	a5,64(s1)
    800035a0:	cf81                	beqz	a5,800035b8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035a2:	64a4                	ld	s1,72(s1)
    800035a4:	fee49de3          	bne	s1,a4,8000359e <bread+0x86>
  panic("bget: no buffers");
    800035a8:	00005517          	auipc	a0,0x5
    800035ac:	f8850513          	addi	a0,a0,-120 # 80008530 <syscalls+0xe0>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	f94080e7          	jalr	-108(ra) # 80000544 <panic>
      b->dev = dev;
    800035b8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035bc:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035c0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035c4:	4785                	li	a5,1
    800035c6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035c8:	00014517          	auipc	a0,0x14
    800035cc:	1d050513          	addi	a0,a0,464 # 80017798 <bcache>
    800035d0:	ffffd097          	auipc	ra,0xffffd
    800035d4:	6ce080e7          	jalr	1742(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800035d8:	01048513          	addi	a0,s1,16
    800035dc:	00001097          	auipc	ra,0x1
    800035e0:	410080e7          	jalr	1040(ra) # 800049ec <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035e4:	409c                	lw	a5,0(s1)
    800035e6:	cb89                	beqz	a5,800035f8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035e8:	8526                	mv	a0,s1
    800035ea:	70a2                	ld	ra,40(sp)
    800035ec:	7402                	ld	s0,32(sp)
    800035ee:	64e2                	ld	s1,24(sp)
    800035f0:	6942                	ld	s2,16(sp)
    800035f2:	69a2                	ld	s3,8(sp)
    800035f4:	6145                	addi	sp,sp,48
    800035f6:	8082                	ret
    virtio_disk_rw(b, 0);
    800035f8:	4581                	li	a1,0
    800035fa:	8526                	mv	a0,s1
    800035fc:	00003097          	auipc	ra,0x3
    80003600:	fec080e7          	jalr	-20(ra) # 800065e8 <virtio_disk_rw>
    b->valid = 1;
    80003604:	4785                	li	a5,1
    80003606:	c09c                	sw	a5,0(s1)
  return b;
    80003608:	b7c5                	j	800035e8 <bread+0xd0>

000000008000360a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000360a:	1101                	addi	sp,sp,-32
    8000360c:	ec06                	sd	ra,24(sp)
    8000360e:	e822                	sd	s0,16(sp)
    80003610:	e426                	sd	s1,8(sp)
    80003612:	1000                	addi	s0,sp,32
    80003614:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003616:	0541                	addi	a0,a0,16
    80003618:	00001097          	auipc	ra,0x1
    8000361c:	46e080e7          	jalr	1134(ra) # 80004a86 <holdingsleep>
    80003620:	cd01                	beqz	a0,80003638 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003622:	4585                	li	a1,1
    80003624:	8526                	mv	a0,s1
    80003626:	00003097          	auipc	ra,0x3
    8000362a:	fc2080e7          	jalr	-62(ra) # 800065e8 <virtio_disk_rw>
}
    8000362e:	60e2                	ld	ra,24(sp)
    80003630:	6442                	ld	s0,16(sp)
    80003632:	64a2                	ld	s1,8(sp)
    80003634:	6105                	addi	sp,sp,32
    80003636:	8082                	ret
    panic("bwrite");
    80003638:	00005517          	auipc	a0,0x5
    8000363c:	f1050513          	addi	a0,a0,-240 # 80008548 <syscalls+0xf8>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	f04080e7          	jalr	-252(ra) # 80000544 <panic>

0000000080003648 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003648:	1101                	addi	sp,sp,-32
    8000364a:	ec06                	sd	ra,24(sp)
    8000364c:	e822                	sd	s0,16(sp)
    8000364e:	e426                	sd	s1,8(sp)
    80003650:	e04a                	sd	s2,0(sp)
    80003652:	1000                	addi	s0,sp,32
    80003654:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003656:	01050913          	addi	s2,a0,16
    8000365a:	854a                	mv	a0,s2
    8000365c:	00001097          	auipc	ra,0x1
    80003660:	42a080e7          	jalr	1066(ra) # 80004a86 <holdingsleep>
    80003664:	c92d                	beqz	a0,800036d6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003666:	854a                	mv	a0,s2
    80003668:	00001097          	auipc	ra,0x1
    8000366c:	3da080e7          	jalr	986(ra) # 80004a42 <releasesleep>

  acquire(&bcache.lock);
    80003670:	00014517          	auipc	a0,0x14
    80003674:	12850513          	addi	a0,a0,296 # 80017798 <bcache>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	572080e7          	jalr	1394(ra) # 80000bea <acquire>
  b->refcnt--;
    80003680:	40bc                	lw	a5,64(s1)
    80003682:	37fd                	addiw	a5,a5,-1
    80003684:	0007871b          	sext.w	a4,a5
    80003688:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000368a:	eb05                	bnez	a4,800036ba <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000368c:	68bc                	ld	a5,80(s1)
    8000368e:	64b8                	ld	a4,72(s1)
    80003690:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003692:	64bc                	ld	a5,72(s1)
    80003694:	68b8                	ld	a4,80(s1)
    80003696:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003698:	0001c797          	auipc	a5,0x1c
    8000369c:	10078793          	addi	a5,a5,256 # 8001f798 <bcache+0x8000>
    800036a0:	2b87b703          	ld	a4,696(a5)
    800036a4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036a6:	0001c717          	auipc	a4,0x1c
    800036aa:	35a70713          	addi	a4,a4,858 # 8001fa00 <bcache+0x8268>
    800036ae:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036b0:	2b87b703          	ld	a4,696(a5)
    800036b4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036b6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036ba:	00014517          	auipc	a0,0x14
    800036be:	0de50513          	addi	a0,a0,222 # 80017798 <bcache>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	5dc080e7          	jalr	1500(ra) # 80000c9e <release>
}
    800036ca:	60e2                	ld	ra,24(sp)
    800036cc:	6442                	ld	s0,16(sp)
    800036ce:	64a2                	ld	s1,8(sp)
    800036d0:	6902                	ld	s2,0(sp)
    800036d2:	6105                	addi	sp,sp,32
    800036d4:	8082                	ret
    panic("brelse");
    800036d6:	00005517          	auipc	a0,0x5
    800036da:	e7a50513          	addi	a0,a0,-390 # 80008550 <syscalls+0x100>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	e66080e7          	jalr	-410(ra) # 80000544 <panic>

00000000800036e6 <bpin>:

void
bpin(struct buf *b) {
    800036e6:	1101                	addi	sp,sp,-32
    800036e8:	ec06                	sd	ra,24(sp)
    800036ea:	e822                	sd	s0,16(sp)
    800036ec:	e426                	sd	s1,8(sp)
    800036ee:	1000                	addi	s0,sp,32
    800036f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036f2:	00014517          	auipc	a0,0x14
    800036f6:	0a650513          	addi	a0,a0,166 # 80017798 <bcache>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	4f0080e7          	jalr	1264(ra) # 80000bea <acquire>
  b->refcnt++;
    80003702:	40bc                	lw	a5,64(s1)
    80003704:	2785                	addiw	a5,a5,1
    80003706:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003708:	00014517          	auipc	a0,0x14
    8000370c:	09050513          	addi	a0,a0,144 # 80017798 <bcache>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	58e080e7          	jalr	1422(ra) # 80000c9e <release>
}
    80003718:	60e2                	ld	ra,24(sp)
    8000371a:	6442                	ld	s0,16(sp)
    8000371c:	64a2                	ld	s1,8(sp)
    8000371e:	6105                	addi	sp,sp,32
    80003720:	8082                	ret

0000000080003722 <bunpin>:

void
bunpin(struct buf *b) {
    80003722:	1101                	addi	sp,sp,-32
    80003724:	ec06                	sd	ra,24(sp)
    80003726:	e822                	sd	s0,16(sp)
    80003728:	e426                	sd	s1,8(sp)
    8000372a:	1000                	addi	s0,sp,32
    8000372c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000372e:	00014517          	auipc	a0,0x14
    80003732:	06a50513          	addi	a0,a0,106 # 80017798 <bcache>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	4b4080e7          	jalr	1204(ra) # 80000bea <acquire>
  b->refcnt--;
    8000373e:	40bc                	lw	a5,64(s1)
    80003740:	37fd                	addiw	a5,a5,-1
    80003742:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003744:	00014517          	auipc	a0,0x14
    80003748:	05450513          	addi	a0,a0,84 # 80017798 <bcache>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	552080e7          	jalr	1362(ra) # 80000c9e <release>
}
    80003754:	60e2                	ld	ra,24(sp)
    80003756:	6442                	ld	s0,16(sp)
    80003758:	64a2                	ld	s1,8(sp)
    8000375a:	6105                	addi	sp,sp,32
    8000375c:	8082                	ret

000000008000375e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000375e:	1101                	addi	sp,sp,-32
    80003760:	ec06                	sd	ra,24(sp)
    80003762:	e822                	sd	s0,16(sp)
    80003764:	e426                	sd	s1,8(sp)
    80003766:	e04a                	sd	s2,0(sp)
    80003768:	1000                	addi	s0,sp,32
    8000376a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000376c:	00d5d59b          	srliw	a1,a1,0xd
    80003770:	0001c797          	auipc	a5,0x1c
    80003774:	7047a783          	lw	a5,1796(a5) # 8001fe74 <sb+0x1c>
    80003778:	9dbd                	addw	a1,a1,a5
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	d9e080e7          	jalr	-610(ra) # 80003518 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003782:	0074f713          	andi	a4,s1,7
    80003786:	4785                	li	a5,1
    80003788:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000378c:	14ce                	slli	s1,s1,0x33
    8000378e:	90d9                	srli	s1,s1,0x36
    80003790:	00950733          	add	a4,a0,s1
    80003794:	05874703          	lbu	a4,88(a4)
    80003798:	00e7f6b3          	and	a3,a5,a4
    8000379c:	c69d                	beqz	a3,800037ca <bfree+0x6c>
    8000379e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037a0:	94aa                	add	s1,s1,a0
    800037a2:	fff7c793          	not	a5,a5
    800037a6:	8ff9                	and	a5,a5,a4
    800037a8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037ac:	00001097          	auipc	ra,0x1
    800037b0:	120080e7          	jalr	288(ra) # 800048cc <log_write>
  brelse(bp);
    800037b4:	854a                	mv	a0,s2
    800037b6:	00000097          	auipc	ra,0x0
    800037ba:	e92080e7          	jalr	-366(ra) # 80003648 <brelse>
}
    800037be:	60e2                	ld	ra,24(sp)
    800037c0:	6442                	ld	s0,16(sp)
    800037c2:	64a2                	ld	s1,8(sp)
    800037c4:	6902                	ld	s2,0(sp)
    800037c6:	6105                	addi	sp,sp,32
    800037c8:	8082                	ret
    panic("freeing free block");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	d8e50513          	addi	a0,a0,-626 # 80008558 <syscalls+0x108>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	d72080e7          	jalr	-654(ra) # 80000544 <panic>

00000000800037da <balloc>:
{
    800037da:	711d                	addi	sp,sp,-96
    800037dc:	ec86                	sd	ra,88(sp)
    800037de:	e8a2                	sd	s0,80(sp)
    800037e0:	e4a6                	sd	s1,72(sp)
    800037e2:	e0ca                	sd	s2,64(sp)
    800037e4:	fc4e                	sd	s3,56(sp)
    800037e6:	f852                	sd	s4,48(sp)
    800037e8:	f456                	sd	s5,40(sp)
    800037ea:	f05a                	sd	s6,32(sp)
    800037ec:	ec5e                	sd	s7,24(sp)
    800037ee:	e862                	sd	s8,16(sp)
    800037f0:	e466                	sd	s9,8(sp)
    800037f2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037f4:	0001c797          	auipc	a5,0x1c
    800037f8:	6687a783          	lw	a5,1640(a5) # 8001fe5c <sb+0x4>
    800037fc:	10078163          	beqz	a5,800038fe <balloc+0x124>
    80003800:	8baa                	mv	s7,a0
    80003802:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003804:	0001cb17          	auipc	s6,0x1c
    80003808:	654b0b13          	addi	s6,s6,1620 # 8001fe58 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000380c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000380e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003810:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003812:	6c89                	lui	s9,0x2
    80003814:	a061                	j	8000389c <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003816:	974a                	add	a4,a4,s2
    80003818:	8fd5                	or	a5,a5,a3
    8000381a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000381e:	854a                	mv	a0,s2
    80003820:	00001097          	auipc	ra,0x1
    80003824:	0ac080e7          	jalr	172(ra) # 800048cc <log_write>
        brelse(bp);
    80003828:	854a                	mv	a0,s2
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	e1e080e7          	jalr	-482(ra) # 80003648 <brelse>
  bp = bread(dev, bno);
    80003832:	85a6                	mv	a1,s1
    80003834:	855e                	mv	a0,s7
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	ce2080e7          	jalr	-798(ra) # 80003518 <bread>
    8000383e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003840:	40000613          	li	a2,1024
    80003844:	4581                	li	a1,0
    80003846:	05850513          	addi	a0,a0,88
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	49c080e7          	jalr	1180(ra) # 80000ce6 <memset>
  log_write(bp);
    80003852:	854a                	mv	a0,s2
    80003854:	00001097          	auipc	ra,0x1
    80003858:	078080e7          	jalr	120(ra) # 800048cc <log_write>
  brelse(bp);
    8000385c:	854a                	mv	a0,s2
    8000385e:	00000097          	auipc	ra,0x0
    80003862:	dea080e7          	jalr	-534(ra) # 80003648 <brelse>
}
    80003866:	8526                	mv	a0,s1
    80003868:	60e6                	ld	ra,88(sp)
    8000386a:	6446                	ld	s0,80(sp)
    8000386c:	64a6                	ld	s1,72(sp)
    8000386e:	6906                	ld	s2,64(sp)
    80003870:	79e2                	ld	s3,56(sp)
    80003872:	7a42                	ld	s4,48(sp)
    80003874:	7aa2                	ld	s5,40(sp)
    80003876:	7b02                	ld	s6,32(sp)
    80003878:	6be2                	ld	s7,24(sp)
    8000387a:	6c42                	ld	s8,16(sp)
    8000387c:	6ca2                	ld	s9,8(sp)
    8000387e:	6125                	addi	sp,sp,96
    80003880:	8082                	ret
    brelse(bp);
    80003882:	854a                	mv	a0,s2
    80003884:	00000097          	auipc	ra,0x0
    80003888:	dc4080e7          	jalr	-572(ra) # 80003648 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000388c:	015c87bb          	addw	a5,s9,s5
    80003890:	00078a9b          	sext.w	s5,a5
    80003894:	004b2703          	lw	a4,4(s6)
    80003898:	06eaf363          	bgeu	s5,a4,800038fe <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000389c:	41fad79b          	sraiw	a5,s5,0x1f
    800038a0:	0137d79b          	srliw	a5,a5,0x13
    800038a4:	015787bb          	addw	a5,a5,s5
    800038a8:	40d7d79b          	sraiw	a5,a5,0xd
    800038ac:	01cb2583          	lw	a1,28(s6)
    800038b0:	9dbd                	addw	a1,a1,a5
    800038b2:	855e                	mv	a0,s7
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	c64080e7          	jalr	-924(ra) # 80003518 <bread>
    800038bc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038be:	004b2503          	lw	a0,4(s6)
    800038c2:	000a849b          	sext.w	s1,s5
    800038c6:	8662                	mv	a2,s8
    800038c8:	faa4fde3          	bgeu	s1,a0,80003882 <balloc+0xa8>
      m = 1 << (bi % 8);
    800038cc:	41f6579b          	sraiw	a5,a2,0x1f
    800038d0:	01d7d69b          	srliw	a3,a5,0x1d
    800038d4:	00c6873b          	addw	a4,a3,a2
    800038d8:	00777793          	andi	a5,a4,7
    800038dc:	9f95                	subw	a5,a5,a3
    800038de:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038e2:	4037571b          	sraiw	a4,a4,0x3
    800038e6:	00e906b3          	add	a3,s2,a4
    800038ea:	0586c683          	lbu	a3,88(a3)
    800038ee:	00d7f5b3          	and	a1,a5,a3
    800038f2:	d195                	beqz	a1,80003816 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038f4:	2605                	addiw	a2,a2,1
    800038f6:	2485                	addiw	s1,s1,1
    800038f8:	fd4618e3          	bne	a2,s4,800038c8 <balloc+0xee>
    800038fc:	b759                	j	80003882 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800038fe:	00005517          	auipc	a0,0x5
    80003902:	c7250513          	addi	a0,a0,-910 # 80008570 <syscalls+0x120>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	c88080e7          	jalr	-888(ra) # 8000058e <printf>
  return 0;
    8000390e:	4481                	li	s1,0
    80003910:	bf99                	j	80003866 <balloc+0x8c>

0000000080003912 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003912:	7179                	addi	sp,sp,-48
    80003914:	f406                	sd	ra,40(sp)
    80003916:	f022                	sd	s0,32(sp)
    80003918:	ec26                	sd	s1,24(sp)
    8000391a:	e84a                	sd	s2,16(sp)
    8000391c:	e44e                	sd	s3,8(sp)
    8000391e:	e052                	sd	s4,0(sp)
    80003920:	1800                	addi	s0,sp,48
    80003922:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003924:	47ad                	li	a5,11
    80003926:	02b7e763          	bltu	a5,a1,80003954 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000392a:	02059493          	slli	s1,a1,0x20
    8000392e:	9081                	srli	s1,s1,0x20
    80003930:	048a                	slli	s1,s1,0x2
    80003932:	94aa                	add	s1,s1,a0
    80003934:	0504a903          	lw	s2,80(s1)
    80003938:	06091e63          	bnez	s2,800039b4 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000393c:	4108                	lw	a0,0(a0)
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	e9c080e7          	jalr	-356(ra) # 800037da <balloc>
    80003946:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000394a:	06090563          	beqz	s2,800039b4 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000394e:	0524a823          	sw	s2,80(s1)
    80003952:	a08d                	j	800039b4 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003954:	ff45849b          	addiw	s1,a1,-12
    80003958:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000395c:	0ff00793          	li	a5,255
    80003960:	08e7e563          	bltu	a5,a4,800039ea <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003964:	08052903          	lw	s2,128(a0)
    80003968:	00091d63          	bnez	s2,80003982 <bmap+0x70>
      addr = balloc(ip->dev);
    8000396c:	4108                	lw	a0,0(a0)
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	e6c080e7          	jalr	-404(ra) # 800037da <balloc>
    80003976:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000397a:	02090d63          	beqz	s2,800039b4 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000397e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003982:	85ca                	mv	a1,s2
    80003984:	0009a503          	lw	a0,0(s3)
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	b90080e7          	jalr	-1136(ra) # 80003518 <bread>
    80003990:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003992:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003996:	02049593          	slli	a1,s1,0x20
    8000399a:	9181                	srli	a1,a1,0x20
    8000399c:	058a                	slli	a1,a1,0x2
    8000399e:	00b784b3          	add	s1,a5,a1
    800039a2:	0004a903          	lw	s2,0(s1)
    800039a6:	02090063          	beqz	s2,800039c6 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800039aa:	8552                	mv	a0,s4
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	c9c080e7          	jalr	-868(ra) # 80003648 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800039b4:	854a                	mv	a0,s2
    800039b6:	70a2                	ld	ra,40(sp)
    800039b8:	7402                	ld	s0,32(sp)
    800039ba:	64e2                	ld	s1,24(sp)
    800039bc:	6942                	ld	s2,16(sp)
    800039be:	69a2                	ld	s3,8(sp)
    800039c0:	6a02                	ld	s4,0(sp)
    800039c2:	6145                	addi	sp,sp,48
    800039c4:	8082                	ret
      addr = balloc(ip->dev);
    800039c6:	0009a503          	lw	a0,0(s3)
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	e10080e7          	jalr	-496(ra) # 800037da <balloc>
    800039d2:	0005091b          	sext.w	s2,a0
      if(addr){
    800039d6:	fc090ae3          	beqz	s2,800039aa <bmap+0x98>
        a[bn] = addr;
    800039da:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800039de:	8552                	mv	a0,s4
    800039e0:	00001097          	auipc	ra,0x1
    800039e4:	eec080e7          	jalr	-276(ra) # 800048cc <log_write>
    800039e8:	b7c9                	j	800039aa <bmap+0x98>
  panic("bmap: out of range");
    800039ea:	00005517          	auipc	a0,0x5
    800039ee:	b9e50513          	addi	a0,a0,-1122 # 80008588 <syscalls+0x138>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	b52080e7          	jalr	-1198(ra) # 80000544 <panic>

00000000800039fa <iget>:
{
    800039fa:	7179                	addi	sp,sp,-48
    800039fc:	f406                	sd	ra,40(sp)
    800039fe:	f022                	sd	s0,32(sp)
    80003a00:	ec26                	sd	s1,24(sp)
    80003a02:	e84a                	sd	s2,16(sp)
    80003a04:	e44e                	sd	s3,8(sp)
    80003a06:	e052                	sd	s4,0(sp)
    80003a08:	1800                	addi	s0,sp,48
    80003a0a:	89aa                	mv	s3,a0
    80003a0c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a0e:	0001c517          	auipc	a0,0x1c
    80003a12:	46a50513          	addi	a0,a0,1130 # 8001fe78 <itable>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	1d4080e7          	jalr	468(ra) # 80000bea <acquire>
  empty = 0;
    80003a1e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a20:	0001c497          	auipc	s1,0x1c
    80003a24:	47048493          	addi	s1,s1,1136 # 8001fe90 <itable+0x18>
    80003a28:	0001e697          	auipc	a3,0x1e
    80003a2c:	ef868693          	addi	a3,a3,-264 # 80021920 <log>
    80003a30:	a039                	j	80003a3e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a32:	02090b63          	beqz	s2,80003a68 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a36:	08848493          	addi	s1,s1,136
    80003a3a:	02d48a63          	beq	s1,a3,80003a6e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a3e:	449c                	lw	a5,8(s1)
    80003a40:	fef059e3          	blez	a5,80003a32 <iget+0x38>
    80003a44:	4098                	lw	a4,0(s1)
    80003a46:	ff3716e3          	bne	a4,s3,80003a32 <iget+0x38>
    80003a4a:	40d8                	lw	a4,4(s1)
    80003a4c:	ff4713e3          	bne	a4,s4,80003a32 <iget+0x38>
      ip->ref++;
    80003a50:	2785                	addiw	a5,a5,1
    80003a52:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a54:	0001c517          	auipc	a0,0x1c
    80003a58:	42450513          	addi	a0,a0,1060 # 8001fe78 <itable>
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	242080e7          	jalr	578(ra) # 80000c9e <release>
      return ip;
    80003a64:	8926                	mv	s2,s1
    80003a66:	a03d                	j	80003a94 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a68:	f7f9                	bnez	a5,80003a36 <iget+0x3c>
    80003a6a:	8926                	mv	s2,s1
    80003a6c:	b7e9                	j	80003a36 <iget+0x3c>
  if(empty == 0)
    80003a6e:	02090c63          	beqz	s2,80003aa6 <iget+0xac>
  ip->dev = dev;
    80003a72:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a76:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a7a:	4785                	li	a5,1
    80003a7c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a80:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a84:	0001c517          	auipc	a0,0x1c
    80003a88:	3f450513          	addi	a0,a0,1012 # 8001fe78 <itable>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	212080e7          	jalr	530(ra) # 80000c9e <release>
}
    80003a94:	854a                	mv	a0,s2
    80003a96:	70a2                	ld	ra,40(sp)
    80003a98:	7402                	ld	s0,32(sp)
    80003a9a:	64e2                	ld	s1,24(sp)
    80003a9c:	6942                	ld	s2,16(sp)
    80003a9e:	69a2                	ld	s3,8(sp)
    80003aa0:	6a02                	ld	s4,0(sp)
    80003aa2:	6145                	addi	sp,sp,48
    80003aa4:	8082                	ret
    panic("iget: no inodes");
    80003aa6:	00005517          	auipc	a0,0x5
    80003aaa:	afa50513          	addi	a0,a0,-1286 # 800085a0 <syscalls+0x150>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	a96080e7          	jalr	-1386(ra) # 80000544 <panic>

0000000080003ab6 <fsinit>:
fsinit(int dev) {
    80003ab6:	7179                	addi	sp,sp,-48
    80003ab8:	f406                	sd	ra,40(sp)
    80003aba:	f022                	sd	s0,32(sp)
    80003abc:	ec26                	sd	s1,24(sp)
    80003abe:	e84a                	sd	s2,16(sp)
    80003ac0:	e44e                	sd	s3,8(sp)
    80003ac2:	1800                	addi	s0,sp,48
    80003ac4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ac6:	4585                	li	a1,1
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	a50080e7          	jalr	-1456(ra) # 80003518 <bread>
    80003ad0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ad2:	0001c997          	auipc	s3,0x1c
    80003ad6:	38698993          	addi	s3,s3,902 # 8001fe58 <sb>
    80003ada:	02000613          	li	a2,32
    80003ade:	05850593          	addi	a1,a0,88
    80003ae2:	854e                	mv	a0,s3
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	262080e7          	jalr	610(ra) # 80000d46 <memmove>
  brelse(bp);
    80003aec:	8526                	mv	a0,s1
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	b5a080e7          	jalr	-1190(ra) # 80003648 <brelse>
  if(sb.magic != FSMAGIC)
    80003af6:	0009a703          	lw	a4,0(s3)
    80003afa:	102037b7          	lui	a5,0x10203
    80003afe:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b02:	02f71263          	bne	a4,a5,80003b26 <fsinit+0x70>
  initlog(dev, &sb);
    80003b06:	0001c597          	auipc	a1,0x1c
    80003b0a:	35258593          	addi	a1,a1,850 # 8001fe58 <sb>
    80003b0e:	854a                	mv	a0,s2
    80003b10:	00001097          	auipc	ra,0x1
    80003b14:	b40080e7          	jalr	-1216(ra) # 80004650 <initlog>
}
    80003b18:	70a2                	ld	ra,40(sp)
    80003b1a:	7402                	ld	s0,32(sp)
    80003b1c:	64e2                	ld	s1,24(sp)
    80003b1e:	6942                	ld	s2,16(sp)
    80003b20:	69a2                	ld	s3,8(sp)
    80003b22:	6145                	addi	sp,sp,48
    80003b24:	8082                	ret
    panic("invalid file system");
    80003b26:	00005517          	auipc	a0,0x5
    80003b2a:	a8a50513          	addi	a0,a0,-1398 # 800085b0 <syscalls+0x160>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	a16080e7          	jalr	-1514(ra) # 80000544 <panic>

0000000080003b36 <iinit>:
{
    80003b36:	7179                	addi	sp,sp,-48
    80003b38:	f406                	sd	ra,40(sp)
    80003b3a:	f022                	sd	s0,32(sp)
    80003b3c:	ec26                	sd	s1,24(sp)
    80003b3e:	e84a                	sd	s2,16(sp)
    80003b40:	e44e                	sd	s3,8(sp)
    80003b42:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b44:	00005597          	auipc	a1,0x5
    80003b48:	a8458593          	addi	a1,a1,-1404 # 800085c8 <syscalls+0x178>
    80003b4c:	0001c517          	auipc	a0,0x1c
    80003b50:	32c50513          	addi	a0,a0,812 # 8001fe78 <itable>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	006080e7          	jalr	6(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b5c:	0001c497          	auipc	s1,0x1c
    80003b60:	34448493          	addi	s1,s1,836 # 8001fea0 <itable+0x28>
    80003b64:	0001e997          	auipc	s3,0x1e
    80003b68:	dcc98993          	addi	s3,s3,-564 # 80021930 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b6c:	00005917          	auipc	s2,0x5
    80003b70:	a6490913          	addi	s2,s2,-1436 # 800085d0 <syscalls+0x180>
    80003b74:	85ca                	mv	a1,s2
    80003b76:	8526                	mv	a0,s1
    80003b78:	00001097          	auipc	ra,0x1
    80003b7c:	e3a080e7          	jalr	-454(ra) # 800049b2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b80:	08848493          	addi	s1,s1,136
    80003b84:	ff3498e3          	bne	s1,s3,80003b74 <iinit+0x3e>
}
    80003b88:	70a2                	ld	ra,40(sp)
    80003b8a:	7402                	ld	s0,32(sp)
    80003b8c:	64e2                	ld	s1,24(sp)
    80003b8e:	6942                	ld	s2,16(sp)
    80003b90:	69a2                	ld	s3,8(sp)
    80003b92:	6145                	addi	sp,sp,48
    80003b94:	8082                	ret

0000000080003b96 <ialloc>:
{
    80003b96:	715d                	addi	sp,sp,-80
    80003b98:	e486                	sd	ra,72(sp)
    80003b9a:	e0a2                	sd	s0,64(sp)
    80003b9c:	fc26                	sd	s1,56(sp)
    80003b9e:	f84a                	sd	s2,48(sp)
    80003ba0:	f44e                	sd	s3,40(sp)
    80003ba2:	f052                	sd	s4,32(sp)
    80003ba4:	ec56                	sd	s5,24(sp)
    80003ba6:	e85a                	sd	s6,16(sp)
    80003ba8:	e45e                	sd	s7,8(sp)
    80003baa:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bac:	0001c717          	auipc	a4,0x1c
    80003bb0:	2b872703          	lw	a4,696(a4) # 8001fe64 <sb+0xc>
    80003bb4:	4785                	li	a5,1
    80003bb6:	04e7fa63          	bgeu	a5,a4,80003c0a <ialloc+0x74>
    80003bba:	8aaa                	mv	s5,a0
    80003bbc:	8bae                	mv	s7,a1
    80003bbe:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bc0:	0001ca17          	auipc	s4,0x1c
    80003bc4:	298a0a13          	addi	s4,s4,664 # 8001fe58 <sb>
    80003bc8:	00048b1b          	sext.w	s6,s1
    80003bcc:	0044d593          	srli	a1,s1,0x4
    80003bd0:	018a2783          	lw	a5,24(s4)
    80003bd4:	9dbd                	addw	a1,a1,a5
    80003bd6:	8556                	mv	a0,s5
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	940080e7          	jalr	-1728(ra) # 80003518 <bread>
    80003be0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003be2:	05850993          	addi	s3,a0,88
    80003be6:	00f4f793          	andi	a5,s1,15
    80003bea:	079a                	slli	a5,a5,0x6
    80003bec:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bee:	00099783          	lh	a5,0(s3)
    80003bf2:	c3a1                	beqz	a5,80003c32 <ialloc+0x9c>
    brelse(bp);
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	a54080e7          	jalr	-1452(ra) # 80003648 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bfc:	0485                	addi	s1,s1,1
    80003bfe:	00ca2703          	lw	a4,12(s4)
    80003c02:	0004879b          	sext.w	a5,s1
    80003c06:	fce7e1e3          	bltu	a5,a4,80003bc8 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003c0a:	00005517          	auipc	a0,0x5
    80003c0e:	9ce50513          	addi	a0,a0,-1586 # 800085d8 <syscalls+0x188>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	97c080e7          	jalr	-1668(ra) # 8000058e <printf>
  return 0;
    80003c1a:	4501                	li	a0,0
}
    80003c1c:	60a6                	ld	ra,72(sp)
    80003c1e:	6406                	ld	s0,64(sp)
    80003c20:	74e2                	ld	s1,56(sp)
    80003c22:	7942                	ld	s2,48(sp)
    80003c24:	79a2                	ld	s3,40(sp)
    80003c26:	7a02                	ld	s4,32(sp)
    80003c28:	6ae2                	ld	s5,24(sp)
    80003c2a:	6b42                	ld	s6,16(sp)
    80003c2c:	6ba2                	ld	s7,8(sp)
    80003c2e:	6161                	addi	sp,sp,80
    80003c30:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c32:	04000613          	li	a2,64
    80003c36:	4581                	li	a1,0
    80003c38:	854e                	mv	a0,s3
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	0ac080e7          	jalr	172(ra) # 80000ce6 <memset>
      dip->type = type;
    80003c42:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c46:	854a                	mv	a0,s2
    80003c48:	00001097          	auipc	ra,0x1
    80003c4c:	c84080e7          	jalr	-892(ra) # 800048cc <log_write>
      brelse(bp);
    80003c50:	854a                	mv	a0,s2
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	9f6080e7          	jalr	-1546(ra) # 80003648 <brelse>
      return iget(dev, inum);
    80003c5a:	85da                	mv	a1,s6
    80003c5c:	8556                	mv	a0,s5
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	d9c080e7          	jalr	-612(ra) # 800039fa <iget>
    80003c66:	bf5d                	j	80003c1c <ialloc+0x86>

0000000080003c68 <iupdate>:
{
    80003c68:	1101                	addi	sp,sp,-32
    80003c6a:	ec06                	sd	ra,24(sp)
    80003c6c:	e822                	sd	s0,16(sp)
    80003c6e:	e426                	sd	s1,8(sp)
    80003c70:	e04a                	sd	s2,0(sp)
    80003c72:	1000                	addi	s0,sp,32
    80003c74:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c76:	415c                	lw	a5,4(a0)
    80003c78:	0047d79b          	srliw	a5,a5,0x4
    80003c7c:	0001c597          	auipc	a1,0x1c
    80003c80:	1f45a583          	lw	a1,500(a1) # 8001fe70 <sb+0x18>
    80003c84:	9dbd                	addw	a1,a1,a5
    80003c86:	4108                	lw	a0,0(a0)
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	890080e7          	jalr	-1904(ra) # 80003518 <bread>
    80003c90:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c92:	05850793          	addi	a5,a0,88
    80003c96:	40c8                	lw	a0,4(s1)
    80003c98:	893d                	andi	a0,a0,15
    80003c9a:	051a                	slli	a0,a0,0x6
    80003c9c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c9e:	04449703          	lh	a4,68(s1)
    80003ca2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ca6:	04649703          	lh	a4,70(s1)
    80003caa:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003cae:	04849703          	lh	a4,72(s1)
    80003cb2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003cb6:	04a49703          	lh	a4,74(s1)
    80003cba:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003cbe:	44f8                	lw	a4,76(s1)
    80003cc0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cc2:	03400613          	li	a2,52
    80003cc6:	05048593          	addi	a1,s1,80
    80003cca:	0531                	addi	a0,a0,12
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	07a080e7          	jalr	122(ra) # 80000d46 <memmove>
  log_write(bp);
    80003cd4:	854a                	mv	a0,s2
    80003cd6:	00001097          	auipc	ra,0x1
    80003cda:	bf6080e7          	jalr	-1034(ra) # 800048cc <log_write>
  brelse(bp);
    80003cde:	854a                	mv	a0,s2
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	968080e7          	jalr	-1688(ra) # 80003648 <brelse>
}
    80003ce8:	60e2                	ld	ra,24(sp)
    80003cea:	6442                	ld	s0,16(sp)
    80003cec:	64a2                	ld	s1,8(sp)
    80003cee:	6902                	ld	s2,0(sp)
    80003cf0:	6105                	addi	sp,sp,32
    80003cf2:	8082                	ret

0000000080003cf4 <idup>:
{
    80003cf4:	1101                	addi	sp,sp,-32
    80003cf6:	ec06                	sd	ra,24(sp)
    80003cf8:	e822                	sd	s0,16(sp)
    80003cfa:	e426                	sd	s1,8(sp)
    80003cfc:	1000                	addi	s0,sp,32
    80003cfe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d00:	0001c517          	auipc	a0,0x1c
    80003d04:	17850513          	addi	a0,a0,376 # 8001fe78 <itable>
    80003d08:	ffffd097          	auipc	ra,0xffffd
    80003d0c:	ee2080e7          	jalr	-286(ra) # 80000bea <acquire>
  ip->ref++;
    80003d10:	449c                	lw	a5,8(s1)
    80003d12:	2785                	addiw	a5,a5,1
    80003d14:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d16:	0001c517          	auipc	a0,0x1c
    80003d1a:	16250513          	addi	a0,a0,354 # 8001fe78 <itable>
    80003d1e:	ffffd097          	auipc	ra,0xffffd
    80003d22:	f80080e7          	jalr	-128(ra) # 80000c9e <release>
}
    80003d26:	8526                	mv	a0,s1
    80003d28:	60e2                	ld	ra,24(sp)
    80003d2a:	6442                	ld	s0,16(sp)
    80003d2c:	64a2                	ld	s1,8(sp)
    80003d2e:	6105                	addi	sp,sp,32
    80003d30:	8082                	ret

0000000080003d32 <ilock>:
{
    80003d32:	1101                	addi	sp,sp,-32
    80003d34:	ec06                	sd	ra,24(sp)
    80003d36:	e822                	sd	s0,16(sp)
    80003d38:	e426                	sd	s1,8(sp)
    80003d3a:	e04a                	sd	s2,0(sp)
    80003d3c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d3e:	c115                	beqz	a0,80003d62 <ilock+0x30>
    80003d40:	84aa                	mv	s1,a0
    80003d42:	451c                	lw	a5,8(a0)
    80003d44:	00f05f63          	blez	a5,80003d62 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d48:	0541                	addi	a0,a0,16
    80003d4a:	00001097          	auipc	ra,0x1
    80003d4e:	ca2080e7          	jalr	-862(ra) # 800049ec <acquiresleep>
  if(ip->valid == 0){
    80003d52:	40bc                	lw	a5,64(s1)
    80003d54:	cf99                	beqz	a5,80003d72 <ilock+0x40>
}
    80003d56:	60e2                	ld	ra,24(sp)
    80003d58:	6442                	ld	s0,16(sp)
    80003d5a:	64a2                	ld	s1,8(sp)
    80003d5c:	6902                	ld	s2,0(sp)
    80003d5e:	6105                	addi	sp,sp,32
    80003d60:	8082                	ret
    panic("ilock");
    80003d62:	00005517          	auipc	a0,0x5
    80003d66:	88e50513          	addi	a0,a0,-1906 # 800085f0 <syscalls+0x1a0>
    80003d6a:	ffffc097          	auipc	ra,0xffffc
    80003d6e:	7da080e7          	jalr	2010(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d72:	40dc                	lw	a5,4(s1)
    80003d74:	0047d79b          	srliw	a5,a5,0x4
    80003d78:	0001c597          	auipc	a1,0x1c
    80003d7c:	0f85a583          	lw	a1,248(a1) # 8001fe70 <sb+0x18>
    80003d80:	9dbd                	addw	a1,a1,a5
    80003d82:	4088                	lw	a0,0(s1)
    80003d84:	fffff097          	auipc	ra,0xfffff
    80003d88:	794080e7          	jalr	1940(ra) # 80003518 <bread>
    80003d8c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d8e:	05850593          	addi	a1,a0,88
    80003d92:	40dc                	lw	a5,4(s1)
    80003d94:	8bbd                	andi	a5,a5,15
    80003d96:	079a                	slli	a5,a5,0x6
    80003d98:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d9a:	00059783          	lh	a5,0(a1)
    80003d9e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003da2:	00259783          	lh	a5,2(a1)
    80003da6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003daa:	00459783          	lh	a5,4(a1)
    80003dae:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003db2:	00659783          	lh	a5,6(a1)
    80003db6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003dba:	459c                	lw	a5,8(a1)
    80003dbc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dbe:	03400613          	li	a2,52
    80003dc2:	05b1                	addi	a1,a1,12
    80003dc4:	05048513          	addi	a0,s1,80
    80003dc8:	ffffd097          	auipc	ra,0xffffd
    80003dcc:	f7e080e7          	jalr	-130(ra) # 80000d46 <memmove>
    brelse(bp);
    80003dd0:	854a                	mv	a0,s2
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	876080e7          	jalr	-1930(ra) # 80003648 <brelse>
    ip->valid = 1;
    80003dda:	4785                	li	a5,1
    80003ddc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dde:	04449783          	lh	a5,68(s1)
    80003de2:	fbb5                	bnez	a5,80003d56 <ilock+0x24>
      panic("ilock: no type");
    80003de4:	00005517          	auipc	a0,0x5
    80003de8:	81450513          	addi	a0,a0,-2028 # 800085f8 <syscalls+0x1a8>
    80003dec:	ffffc097          	auipc	ra,0xffffc
    80003df0:	758080e7          	jalr	1880(ra) # 80000544 <panic>

0000000080003df4 <iunlock>:
{
    80003df4:	1101                	addi	sp,sp,-32
    80003df6:	ec06                	sd	ra,24(sp)
    80003df8:	e822                	sd	s0,16(sp)
    80003dfa:	e426                	sd	s1,8(sp)
    80003dfc:	e04a                	sd	s2,0(sp)
    80003dfe:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e00:	c905                	beqz	a0,80003e30 <iunlock+0x3c>
    80003e02:	84aa                	mv	s1,a0
    80003e04:	01050913          	addi	s2,a0,16
    80003e08:	854a                	mv	a0,s2
    80003e0a:	00001097          	auipc	ra,0x1
    80003e0e:	c7c080e7          	jalr	-900(ra) # 80004a86 <holdingsleep>
    80003e12:	cd19                	beqz	a0,80003e30 <iunlock+0x3c>
    80003e14:	449c                	lw	a5,8(s1)
    80003e16:	00f05d63          	blez	a5,80003e30 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e1a:	854a                	mv	a0,s2
    80003e1c:	00001097          	auipc	ra,0x1
    80003e20:	c26080e7          	jalr	-986(ra) # 80004a42 <releasesleep>
}
    80003e24:	60e2                	ld	ra,24(sp)
    80003e26:	6442                	ld	s0,16(sp)
    80003e28:	64a2                	ld	s1,8(sp)
    80003e2a:	6902                	ld	s2,0(sp)
    80003e2c:	6105                	addi	sp,sp,32
    80003e2e:	8082                	ret
    panic("iunlock");
    80003e30:	00004517          	auipc	a0,0x4
    80003e34:	7d850513          	addi	a0,a0,2008 # 80008608 <syscalls+0x1b8>
    80003e38:	ffffc097          	auipc	ra,0xffffc
    80003e3c:	70c080e7          	jalr	1804(ra) # 80000544 <panic>

0000000080003e40 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e40:	7179                	addi	sp,sp,-48
    80003e42:	f406                	sd	ra,40(sp)
    80003e44:	f022                	sd	s0,32(sp)
    80003e46:	ec26                	sd	s1,24(sp)
    80003e48:	e84a                	sd	s2,16(sp)
    80003e4a:	e44e                	sd	s3,8(sp)
    80003e4c:	e052                	sd	s4,0(sp)
    80003e4e:	1800                	addi	s0,sp,48
    80003e50:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e52:	05050493          	addi	s1,a0,80
    80003e56:	08050913          	addi	s2,a0,128
    80003e5a:	a021                	j	80003e62 <itrunc+0x22>
    80003e5c:	0491                	addi	s1,s1,4
    80003e5e:	01248d63          	beq	s1,s2,80003e78 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e62:	408c                	lw	a1,0(s1)
    80003e64:	dde5                	beqz	a1,80003e5c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e66:	0009a503          	lw	a0,0(s3)
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	8f4080e7          	jalr	-1804(ra) # 8000375e <bfree>
      ip->addrs[i] = 0;
    80003e72:	0004a023          	sw	zero,0(s1)
    80003e76:	b7dd                	j	80003e5c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e78:	0809a583          	lw	a1,128(s3)
    80003e7c:	e185                	bnez	a1,80003e9c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e7e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e82:	854e                	mv	a0,s3
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	de4080e7          	jalr	-540(ra) # 80003c68 <iupdate>
}
    80003e8c:	70a2                	ld	ra,40(sp)
    80003e8e:	7402                	ld	s0,32(sp)
    80003e90:	64e2                	ld	s1,24(sp)
    80003e92:	6942                	ld	s2,16(sp)
    80003e94:	69a2                	ld	s3,8(sp)
    80003e96:	6a02                	ld	s4,0(sp)
    80003e98:	6145                	addi	sp,sp,48
    80003e9a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e9c:	0009a503          	lw	a0,0(s3)
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	678080e7          	jalr	1656(ra) # 80003518 <bread>
    80003ea8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003eaa:	05850493          	addi	s1,a0,88
    80003eae:	45850913          	addi	s2,a0,1112
    80003eb2:	a811                	j	80003ec6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003eb4:	0009a503          	lw	a0,0(s3)
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	8a6080e7          	jalr	-1882(ra) # 8000375e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ec0:	0491                	addi	s1,s1,4
    80003ec2:	01248563          	beq	s1,s2,80003ecc <itrunc+0x8c>
      if(a[j])
    80003ec6:	408c                	lw	a1,0(s1)
    80003ec8:	dde5                	beqz	a1,80003ec0 <itrunc+0x80>
    80003eca:	b7ed                	j	80003eb4 <itrunc+0x74>
    brelse(bp);
    80003ecc:	8552                	mv	a0,s4
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	77a080e7          	jalr	1914(ra) # 80003648 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ed6:	0809a583          	lw	a1,128(s3)
    80003eda:	0009a503          	lw	a0,0(s3)
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	880080e7          	jalr	-1920(ra) # 8000375e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ee6:	0809a023          	sw	zero,128(s3)
    80003eea:	bf51                	j	80003e7e <itrunc+0x3e>

0000000080003eec <iput>:
{
    80003eec:	1101                	addi	sp,sp,-32
    80003eee:	ec06                	sd	ra,24(sp)
    80003ef0:	e822                	sd	s0,16(sp)
    80003ef2:	e426                	sd	s1,8(sp)
    80003ef4:	e04a                	sd	s2,0(sp)
    80003ef6:	1000                	addi	s0,sp,32
    80003ef8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003efa:	0001c517          	auipc	a0,0x1c
    80003efe:	f7e50513          	addi	a0,a0,-130 # 8001fe78 <itable>
    80003f02:	ffffd097          	auipc	ra,0xffffd
    80003f06:	ce8080e7          	jalr	-792(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f0a:	4498                	lw	a4,8(s1)
    80003f0c:	4785                	li	a5,1
    80003f0e:	02f70363          	beq	a4,a5,80003f34 <iput+0x48>
  ip->ref--;
    80003f12:	449c                	lw	a5,8(s1)
    80003f14:	37fd                	addiw	a5,a5,-1
    80003f16:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f18:	0001c517          	auipc	a0,0x1c
    80003f1c:	f6050513          	addi	a0,a0,-160 # 8001fe78 <itable>
    80003f20:	ffffd097          	auipc	ra,0xffffd
    80003f24:	d7e080e7          	jalr	-642(ra) # 80000c9e <release>
}
    80003f28:	60e2                	ld	ra,24(sp)
    80003f2a:	6442                	ld	s0,16(sp)
    80003f2c:	64a2                	ld	s1,8(sp)
    80003f2e:	6902                	ld	s2,0(sp)
    80003f30:	6105                	addi	sp,sp,32
    80003f32:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f34:	40bc                	lw	a5,64(s1)
    80003f36:	dff1                	beqz	a5,80003f12 <iput+0x26>
    80003f38:	04a49783          	lh	a5,74(s1)
    80003f3c:	fbf9                	bnez	a5,80003f12 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f3e:	01048913          	addi	s2,s1,16
    80003f42:	854a                	mv	a0,s2
    80003f44:	00001097          	auipc	ra,0x1
    80003f48:	aa8080e7          	jalr	-1368(ra) # 800049ec <acquiresleep>
    release(&itable.lock);
    80003f4c:	0001c517          	auipc	a0,0x1c
    80003f50:	f2c50513          	addi	a0,a0,-212 # 8001fe78 <itable>
    80003f54:	ffffd097          	auipc	ra,0xffffd
    80003f58:	d4a080e7          	jalr	-694(ra) # 80000c9e <release>
    itrunc(ip);
    80003f5c:	8526                	mv	a0,s1
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	ee2080e7          	jalr	-286(ra) # 80003e40 <itrunc>
    ip->type = 0;
    80003f66:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f6a:	8526                	mv	a0,s1
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	cfc080e7          	jalr	-772(ra) # 80003c68 <iupdate>
    ip->valid = 0;
    80003f74:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f78:	854a                	mv	a0,s2
    80003f7a:	00001097          	auipc	ra,0x1
    80003f7e:	ac8080e7          	jalr	-1336(ra) # 80004a42 <releasesleep>
    acquire(&itable.lock);
    80003f82:	0001c517          	auipc	a0,0x1c
    80003f86:	ef650513          	addi	a0,a0,-266 # 8001fe78 <itable>
    80003f8a:	ffffd097          	auipc	ra,0xffffd
    80003f8e:	c60080e7          	jalr	-928(ra) # 80000bea <acquire>
    80003f92:	b741                	j	80003f12 <iput+0x26>

0000000080003f94 <iunlockput>:
{
    80003f94:	1101                	addi	sp,sp,-32
    80003f96:	ec06                	sd	ra,24(sp)
    80003f98:	e822                	sd	s0,16(sp)
    80003f9a:	e426                	sd	s1,8(sp)
    80003f9c:	1000                	addi	s0,sp,32
    80003f9e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	e54080e7          	jalr	-428(ra) # 80003df4 <iunlock>
  iput(ip);
    80003fa8:	8526                	mv	a0,s1
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	f42080e7          	jalr	-190(ra) # 80003eec <iput>
}
    80003fb2:	60e2                	ld	ra,24(sp)
    80003fb4:	6442                	ld	s0,16(sp)
    80003fb6:	64a2                	ld	s1,8(sp)
    80003fb8:	6105                	addi	sp,sp,32
    80003fba:	8082                	ret

0000000080003fbc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fbc:	1141                	addi	sp,sp,-16
    80003fbe:	e422                	sd	s0,8(sp)
    80003fc0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fc2:	411c                	lw	a5,0(a0)
    80003fc4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fc6:	415c                	lw	a5,4(a0)
    80003fc8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fca:	04451783          	lh	a5,68(a0)
    80003fce:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fd2:	04a51783          	lh	a5,74(a0)
    80003fd6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fda:	04c56783          	lwu	a5,76(a0)
    80003fde:	e99c                	sd	a5,16(a1)
}
    80003fe0:	6422                	ld	s0,8(sp)
    80003fe2:	0141                	addi	sp,sp,16
    80003fe4:	8082                	ret

0000000080003fe6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fe6:	457c                	lw	a5,76(a0)
    80003fe8:	0ed7e963          	bltu	a5,a3,800040da <readi+0xf4>
{
    80003fec:	7159                	addi	sp,sp,-112
    80003fee:	f486                	sd	ra,104(sp)
    80003ff0:	f0a2                	sd	s0,96(sp)
    80003ff2:	eca6                	sd	s1,88(sp)
    80003ff4:	e8ca                	sd	s2,80(sp)
    80003ff6:	e4ce                	sd	s3,72(sp)
    80003ff8:	e0d2                	sd	s4,64(sp)
    80003ffa:	fc56                	sd	s5,56(sp)
    80003ffc:	f85a                	sd	s6,48(sp)
    80003ffe:	f45e                	sd	s7,40(sp)
    80004000:	f062                	sd	s8,32(sp)
    80004002:	ec66                	sd	s9,24(sp)
    80004004:	e86a                	sd	s10,16(sp)
    80004006:	e46e                	sd	s11,8(sp)
    80004008:	1880                	addi	s0,sp,112
    8000400a:	8b2a                	mv	s6,a0
    8000400c:	8bae                	mv	s7,a1
    8000400e:	8a32                	mv	s4,a2
    80004010:	84b6                	mv	s1,a3
    80004012:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004014:	9f35                	addw	a4,a4,a3
    return 0;
    80004016:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004018:	0ad76063          	bltu	a4,a3,800040b8 <readi+0xd2>
  if(off + n > ip->size)
    8000401c:	00e7f463          	bgeu	a5,a4,80004024 <readi+0x3e>
    n = ip->size - off;
    80004020:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004024:	0a0a8963          	beqz	s5,800040d6 <readi+0xf0>
    80004028:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000402a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000402e:	5c7d                	li	s8,-1
    80004030:	a82d                	j	8000406a <readi+0x84>
    80004032:	020d1d93          	slli	s11,s10,0x20
    80004036:	020ddd93          	srli	s11,s11,0x20
    8000403a:	05890613          	addi	a2,s2,88
    8000403e:	86ee                	mv	a3,s11
    80004040:	963a                	add	a2,a2,a4
    80004042:	85d2                	mv	a1,s4
    80004044:	855e                	mv	a0,s7
    80004046:	ffffe097          	auipc	ra,0xffffe
    8000404a:	518080e7          	jalr	1304(ra) # 8000255e <either_copyout>
    8000404e:	05850d63          	beq	a0,s8,800040a8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004052:	854a                	mv	a0,s2
    80004054:	fffff097          	auipc	ra,0xfffff
    80004058:	5f4080e7          	jalr	1524(ra) # 80003648 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000405c:	013d09bb          	addw	s3,s10,s3
    80004060:	009d04bb          	addw	s1,s10,s1
    80004064:	9a6e                	add	s4,s4,s11
    80004066:	0559f763          	bgeu	s3,s5,800040b4 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000406a:	00a4d59b          	srliw	a1,s1,0xa
    8000406e:	855a                	mv	a0,s6
    80004070:	00000097          	auipc	ra,0x0
    80004074:	8a2080e7          	jalr	-1886(ra) # 80003912 <bmap>
    80004078:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000407c:	cd85                	beqz	a1,800040b4 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000407e:	000b2503          	lw	a0,0(s6)
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	496080e7          	jalr	1174(ra) # 80003518 <bread>
    8000408a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000408c:	3ff4f713          	andi	a4,s1,1023
    80004090:	40ec87bb          	subw	a5,s9,a4
    80004094:	413a86bb          	subw	a3,s5,s3
    80004098:	8d3e                	mv	s10,a5
    8000409a:	2781                	sext.w	a5,a5
    8000409c:	0006861b          	sext.w	a2,a3
    800040a0:	f8f679e3          	bgeu	a2,a5,80004032 <readi+0x4c>
    800040a4:	8d36                	mv	s10,a3
    800040a6:	b771                	j	80004032 <readi+0x4c>
      brelse(bp);
    800040a8:	854a                	mv	a0,s2
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	59e080e7          	jalr	1438(ra) # 80003648 <brelse>
      tot = -1;
    800040b2:	59fd                	li	s3,-1
  }
  return tot;
    800040b4:	0009851b          	sext.w	a0,s3
}
    800040b8:	70a6                	ld	ra,104(sp)
    800040ba:	7406                	ld	s0,96(sp)
    800040bc:	64e6                	ld	s1,88(sp)
    800040be:	6946                	ld	s2,80(sp)
    800040c0:	69a6                	ld	s3,72(sp)
    800040c2:	6a06                	ld	s4,64(sp)
    800040c4:	7ae2                	ld	s5,56(sp)
    800040c6:	7b42                	ld	s6,48(sp)
    800040c8:	7ba2                	ld	s7,40(sp)
    800040ca:	7c02                	ld	s8,32(sp)
    800040cc:	6ce2                	ld	s9,24(sp)
    800040ce:	6d42                	ld	s10,16(sp)
    800040d0:	6da2                	ld	s11,8(sp)
    800040d2:	6165                	addi	sp,sp,112
    800040d4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040d6:	89d6                	mv	s3,s5
    800040d8:	bff1                	j	800040b4 <readi+0xce>
    return 0;
    800040da:	4501                	li	a0,0
}
    800040dc:	8082                	ret

00000000800040de <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040de:	457c                	lw	a5,76(a0)
    800040e0:	10d7e863          	bltu	a5,a3,800041f0 <writei+0x112>
{
    800040e4:	7159                	addi	sp,sp,-112
    800040e6:	f486                	sd	ra,104(sp)
    800040e8:	f0a2                	sd	s0,96(sp)
    800040ea:	eca6                	sd	s1,88(sp)
    800040ec:	e8ca                	sd	s2,80(sp)
    800040ee:	e4ce                	sd	s3,72(sp)
    800040f0:	e0d2                	sd	s4,64(sp)
    800040f2:	fc56                	sd	s5,56(sp)
    800040f4:	f85a                	sd	s6,48(sp)
    800040f6:	f45e                	sd	s7,40(sp)
    800040f8:	f062                	sd	s8,32(sp)
    800040fa:	ec66                	sd	s9,24(sp)
    800040fc:	e86a                	sd	s10,16(sp)
    800040fe:	e46e                	sd	s11,8(sp)
    80004100:	1880                	addi	s0,sp,112
    80004102:	8aaa                	mv	s5,a0
    80004104:	8bae                	mv	s7,a1
    80004106:	8a32                	mv	s4,a2
    80004108:	8936                	mv	s2,a3
    8000410a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000410c:	00e687bb          	addw	a5,a3,a4
    80004110:	0ed7e263          	bltu	a5,a3,800041f4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004114:	00043737          	lui	a4,0x43
    80004118:	0ef76063          	bltu	a4,a5,800041f8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000411c:	0c0b0863          	beqz	s6,800041ec <writei+0x10e>
    80004120:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004122:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004126:	5c7d                	li	s8,-1
    80004128:	a091                	j	8000416c <writei+0x8e>
    8000412a:	020d1d93          	slli	s11,s10,0x20
    8000412e:	020ddd93          	srli	s11,s11,0x20
    80004132:	05848513          	addi	a0,s1,88
    80004136:	86ee                	mv	a3,s11
    80004138:	8652                	mv	a2,s4
    8000413a:	85de                	mv	a1,s7
    8000413c:	953a                	add	a0,a0,a4
    8000413e:	ffffe097          	auipc	ra,0xffffe
    80004142:	476080e7          	jalr	1142(ra) # 800025b4 <either_copyin>
    80004146:	07850263          	beq	a0,s8,800041aa <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000414a:	8526                	mv	a0,s1
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	780080e7          	jalr	1920(ra) # 800048cc <log_write>
    brelse(bp);
    80004154:	8526                	mv	a0,s1
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	4f2080e7          	jalr	1266(ra) # 80003648 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000415e:	013d09bb          	addw	s3,s10,s3
    80004162:	012d093b          	addw	s2,s10,s2
    80004166:	9a6e                	add	s4,s4,s11
    80004168:	0569f663          	bgeu	s3,s6,800041b4 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000416c:	00a9559b          	srliw	a1,s2,0xa
    80004170:	8556                	mv	a0,s5
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	7a0080e7          	jalr	1952(ra) # 80003912 <bmap>
    8000417a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000417e:	c99d                	beqz	a1,800041b4 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004180:	000aa503          	lw	a0,0(s5)
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	394080e7          	jalr	916(ra) # 80003518 <bread>
    8000418c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000418e:	3ff97713          	andi	a4,s2,1023
    80004192:	40ec87bb          	subw	a5,s9,a4
    80004196:	413b06bb          	subw	a3,s6,s3
    8000419a:	8d3e                	mv	s10,a5
    8000419c:	2781                	sext.w	a5,a5
    8000419e:	0006861b          	sext.w	a2,a3
    800041a2:	f8f674e3          	bgeu	a2,a5,8000412a <writei+0x4c>
    800041a6:	8d36                	mv	s10,a3
    800041a8:	b749                	j	8000412a <writei+0x4c>
      brelse(bp);
    800041aa:	8526                	mv	a0,s1
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	49c080e7          	jalr	1180(ra) # 80003648 <brelse>
  }

  if(off > ip->size)
    800041b4:	04caa783          	lw	a5,76(s5)
    800041b8:	0127f463          	bgeu	a5,s2,800041c0 <writei+0xe2>
    ip->size = off;
    800041bc:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041c0:	8556                	mv	a0,s5
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	aa6080e7          	jalr	-1370(ra) # 80003c68 <iupdate>

  return tot;
    800041ca:	0009851b          	sext.w	a0,s3
}
    800041ce:	70a6                	ld	ra,104(sp)
    800041d0:	7406                	ld	s0,96(sp)
    800041d2:	64e6                	ld	s1,88(sp)
    800041d4:	6946                	ld	s2,80(sp)
    800041d6:	69a6                	ld	s3,72(sp)
    800041d8:	6a06                	ld	s4,64(sp)
    800041da:	7ae2                	ld	s5,56(sp)
    800041dc:	7b42                	ld	s6,48(sp)
    800041de:	7ba2                	ld	s7,40(sp)
    800041e0:	7c02                	ld	s8,32(sp)
    800041e2:	6ce2                	ld	s9,24(sp)
    800041e4:	6d42                	ld	s10,16(sp)
    800041e6:	6da2                	ld	s11,8(sp)
    800041e8:	6165                	addi	sp,sp,112
    800041ea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041ec:	89da                	mv	s3,s6
    800041ee:	bfc9                	j	800041c0 <writei+0xe2>
    return -1;
    800041f0:	557d                	li	a0,-1
}
    800041f2:	8082                	ret
    return -1;
    800041f4:	557d                	li	a0,-1
    800041f6:	bfe1                	j	800041ce <writei+0xf0>
    return -1;
    800041f8:	557d                	li	a0,-1
    800041fa:	bfd1                	j	800041ce <writei+0xf0>

00000000800041fc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041fc:	1141                	addi	sp,sp,-16
    800041fe:	e406                	sd	ra,8(sp)
    80004200:	e022                	sd	s0,0(sp)
    80004202:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004204:	4639                	li	a2,14
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	bb8080e7          	jalr	-1096(ra) # 80000dbe <strncmp>
}
    8000420e:	60a2                	ld	ra,8(sp)
    80004210:	6402                	ld	s0,0(sp)
    80004212:	0141                	addi	sp,sp,16
    80004214:	8082                	ret

0000000080004216 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004216:	7139                	addi	sp,sp,-64
    80004218:	fc06                	sd	ra,56(sp)
    8000421a:	f822                	sd	s0,48(sp)
    8000421c:	f426                	sd	s1,40(sp)
    8000421e:	f04a                	sd	s2,32(sp)
    80004220:	ec4e                	sd	s3,24(sp)
    80004222:	e852                	sd	s4,16(sp)
    80004224:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004226:	04451703          	lh	a4,68(a0)
    8000422a:	4785                	li	a5,1
    8000422c:	00f71a63          	bne	a4,a5,80004240 <dirlookup+0x2a>
    80004230:	892a                	mv	s2,a0
    80004232:	89ae                	mv	s3,a1
    80004234:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004236:	457c                	lw	a5,76(a0)
    80004238:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000423a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000423c:	e79d                	bnez	a5,8000426a <dirlookup+0x54>
    8000423e:	a8a5                	j	800042b6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004240:	00004517          	auipc	a0,0x4
    80004244:	3d050513          	addi	a0,a0,976 # 80008610 <syscalls+0x1c0>
    80004248:	ffffc097          	auipc	ra,0xffffc
    8000424c:	2fc080e7          	jalr	764(ra) # 80000544 <panic>
      panic("dirlookup read");
    80004250:	00004517          	auipc	a0,0x4
    80004254:	3d850513          	addi	a0,a0,984 # 80008628 <syscalls+0x1d8>
    80004258:	ffffc097          	auipc	ra,0xffffc
    8000425c:	2ec080e7          	jalr	748(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004260:	24c1                	addiw	s1,s1,16
    80004262:	04c92783          	lw	a5,76(s2)
    80004266:	04f4f763          	bgeu	s1,a5,800042b4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000426a:	4741                	li	a4,16
    8000426c:	86a6                	mv	a3,s1
    8000426e:	fc040613          	addi	a2,s0,-64
    80004272:	4581                	li	a1,0
    80004274:	854a                	mv	a0,s2
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	d70080e7          	jalr	-656(ra) # 80003fe6 <readi>
    8000427e:	47c1                	li	a5,16
    80004280:	fcf518e3          	bne	a0,a5,80004250 <dirlookup+0x3a>
    if(de.inum == 0)
    80004284:	fc045783          	lhu	a5,-64(s0)
    80004288:	dfe1                	beqz	a5,80004260 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000428a:	fc240593          	addi	a1,s0,-62
    8000428e:	854e                	mv	a0,s3
    80004290:	00000097          	auipc	ra,0x0
    80004294:	f6c080e7          	jalr	-148(ra) # 800041fc <namecmp>
    80004298:	f561                	bnez	a0,80004260 <dirlookup+0x4a>
      if(poff)
    8000429a:	000a0463          	beqz	s4,800042a2 <dirlookup+0x8c>
        *poff = off;
    8000429e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042a2:	fc045583          	lhu	a1,-64(s0)
    800042a6:	00092503          	lw	a0,0(s2)
    800042aa:	fffff097          	auipc	ra,0xfffff
    800042ae:	750080e7          	jalr	1872(ra) # 800039fa <iget>
    800042b2:	a011                	j	800042b6 <dirlookup+0xa0>
  return 0;
    800042b4:	4501                	li	a0,0
}
    800042b6:	70e2                	ld	ra,56(sp)
    800042b8:	7442                	ld	s0,48(sp)
    800042ba:	74a2                	ld	s1,40(sp)
    800042bc:	7902                	ld	s2,32(sp)
    800042be:	69e2                	ld	s3,24(sp)
    800042c0:	6a42                	ld	s4,16(sp)
    800042c2:	6121                	addi	sp,sp,64
    800042c4:	8082                	ret

00000000800042c6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042c6:	711d                	addi	sp,sp,-96
    800042c8:	ec86                	sd	ra,88(sp)
    800042ca:	e8a2                	sd	s0,80(sp)
    800042cc:	e4a6                	sd	s1,72(sp)
    800042ce:	e0ca                	sd	s2,64(sp)
    800042d0:	fc4e                	sd	s3,56(sp)
    800042d2:	f852                	sd	s4,48(sp)
    800042d4:	f456                	sd	s5,40(sp)
    800042d6:	f05a                	sd	s6,32(sp)
    800042d8:	ec5e                	sd	s7,24(sp)
    800042da:	e862                	sd	s8,16(sp)
    800042dc:	e466                	sd	s9,8(sp)
    800042de:	1080                	addi	s0,sp,96
    800042e0:	84aa                	mv	s1,a0
    800042e2:	8b2e                	mv	s6,a1
    800042e4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042e6:	00054703          	lbu	a4,0(a0)
    800042ea:	02f00793          	li	a5,47
    800042ee:	02f70363          	beq	a4,a5,80004314 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	6d4080e7          	jalr	1748(ra) # 800019c6 <myproc>
    800042fa:	15053503          	ld	a0,336(a0)
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	9f6080e7          	jalr	-1546(ra) # 80003cf4 <idup>
    80004306:	89aa                	mv	s3,a0
  while(*path == '/')
    80004308:	02f00913          	li	s2,47
  len = path - s;
    8000430c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000430e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004310:	4c05                	li	s8,1
    80004312:	a865                	j	800043ca <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004314:	4585                	li	a1,1
    80004316:	4505                	li	a0,1
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	6e2080e7          	jalr	1762(ra) # 800039fa <iget>
    80004320:	89aa                	mv	s3,a0
    80004322:	b7dd                	j	80004308 <namex+0x42>
      iunlockput(ip);
    80004324:	854e                	mv	a0,s3
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	c6e080e7          	jalr	-914(ra) # 80003f94 <iunlockput>
      return 0;
    8000432e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004330:	854e                	mv	a0,s3
    80004332:	60e6                	ld	ra,88(sp)
    80004334:	6446                	ld	s0,80(sp)
    80004336:	64a6                	ld	s1,72(sp)
    80004338:	6906                	ld	s2,64(sp)
    8000433a:	79e2                	ld	s3,56(sp)
    8000433c:	7a42                	ld	s4,48(sp)
    8000433e:	7aa2                	ld	s5,40(sp)
    80004340:	7b02                	ld	s6,32(sp)
    80004342:	6be2                	ld	s7,24(sp)
    80004344:	6c42                	ld	s8,16(sp)
    80004346:	6ca2                	ld	s9,8(sp)
    80004348:	6125                	addi	sp,sp,96
    8000434a:	8082                	ret
      iunlock(ip);
    8000434c:	854e                	mv	a0,s3
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	aa6080e7          	jalr	-1370(ra) # 80003df4 <iunlock>
      return ip;
    80004356:	bfe9                	j	80004330 <namex+0x6a>
      iunlockput(ip);
    80004358:	854e                	mv	a0,s3
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	c3a080e7          	jalr	-966(ra) # 80003f94 <iunlockput>
      return 0;
    80004362:	89d2                	mv	s3,s4
    80004364:	b7f1                	j	80004330 <namex+0x6a>
  len = path - s;
    80004366:	40b48633          	sub	a2,s1,a1
    8000436a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000436e:	094cd463          	bge	s9,s4,800043f6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004372:	4639                	li	a2,14
    80004374:	8556                	mv	a0,s5
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	9d0080e7          	jalr	-1584(ra) # 80000d46 <memmove>
  while(*path == '/')
    8000437e:	0004c783          	lbu	a5,0(s1)
    80004382:	01279763          	bne	a5,s2,80004390 <namex+0xca>
    path++;
    80004386:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004388:	0004c783          	lbu	a5,0(s1)
    8000438c:	ff278de3          	beq	a5,s2,80004386 <namex+0xc0>
    ilock(ip);
    80004390:	854e                	mv	a0,s3
    80004392:	00000097          	auipc	ra,0x0
    80004396:	9a0080e7          	jalr	-1632(ra) # 80003d32 <ilock>
    if(ip->type != T_DIR){
    8000439a:	04499783          	lh	a5,68(s3)
    8000439e:	f98793e3          	bne	a5,s8,80004324 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800043a2:	000b0563          	beqz	s6,800043ac <namex+0xe6>
    800043a6:	0004c783          	lbu	a5,0(s1)
    800043aa:	d3cd                	beqz	a5,8000434c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043ac:	865e                	mv	a2,s7
    800043ae:	85d6                	mv	a1,s5
    800043b0:	854e                	mv	a0,s3
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	e64080e7          	jalr	-412(ra) # 80004216 <dirlookup>
    800043ba:	8a2a                	mv	s4,a0
    800043bc:	dd51                	beqz	a0,80004358 <namex+0x92>
    iunlockput(ip);
    800043be:	854e                	mv	a0,s3
    800043c0:	00000097          	auipc	ra,0x0
    800043c4:	bd4080e7          	jalr	-1068(ra) # 80003f94 <iunlockput>
    ip = next;
    800043c8:	89d2                	mv	s3,s4
  while(*path == '/')
    800043ca:	0004c783          	lbu	a5,0(s1)
    800043ce:	05279763          	bne	a5,s2,8000441c <namex+0x156>
    path++;
    800043d2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043d4:	0004c783          	lbu	a5,0(s1)
    800043d8:	ff278de3          	beq	a5,s2,800043d2 <namex+0x10c>
  if(*path == 0)
    800043dc:	c79d                	beqz	a5,8000440a <namex+0x144>
    path++;
    800043de:	85a6                	mv	a1,s1
  len = path - s;
    800043e0:	8a5e                	mv	s4,s7
    800043e2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043e4:	01278963          	beq	a5,s2,800043f6 <namex+0x130>
    800043e8:	dfbd                	beqz	a5,80004366 <namex+0xa0>
    path++;
    800043ea:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043ec:	0004c783          	lbu	a5,0(s1)
    800043f0:	ff279ce3          	bne	a5,s2,800043e8 <namex+0x122>
    800043f4:	bf8d                	j	80004366 <namex+0xa0>
    memmove(name, s, len);
    800043f6:	2601                	sext.w	a2,a2
    800043f8:	8556                	mv	a0,s5
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	94c080e7          	jalr	-1716(ra) # 80000d46 <memmove>
    name[len] = 0;
    80004402:	9a56                	add	s4,s4,s5
    80004404:	000a0023          	sb	zero,0(s4)
    80004408:	bf9d                	j	8000437e <namex+0xb8>
  if(nameiparent){
    8000440a:	f20b03e3          	beqz	s6,80004330 <namex+0x6a>
    iput(ip);
    8000440e:	854e                	mv	a0,s3
    80004410:	00000097          	auipc	ra,0x0
    80004414:	adc080e7          	jalr	-1316(ra) # 80003eec <iput>
    return 0;
    80004418:	4981                	li	s3,0
    8000441a:	bf19                	j	80004330 <namex+0x6a>
  if(*path == 0)
    8000441c:	d7fd                	beqz	a5,8000440a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000441e:	0004c783          	lbu	a5,0(s1)
    80004422:	85a6                	mv	a1,s1
    80004424:	b7d1                	j	800043e8 <namex+0x122>

0000000080004426 <dirlink>:
{
    80004426:	7139                	addi	sp,sp,-64
    80004428:	fc06                	sd	ra,56(sp)
    8000442a:	f822                	sd	s0,48(sp)
    8000442c:	f426                	sd	s1,40(sp)
    8000442e:	f04a                	sd	s2,32(sp)
    80004430:	ec4e                	sd	s3,24(sp)
    80004432:	e852                	sd	s4,16(sp)
    80004434:	0080                	addi	s0,sp,64
    80004436:	892a                	mv	s2,a0
    80004438:	8a2e                	mv	s4,a1
    8000443a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000443c:	4601                	li	a2,0
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	dd8080e7          	jalr	-552(ra) # 80004216 <dirlookup>
    80004446:	e93d                	bnez	a0,800044bc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004448:	04c92483          	lw	s1,76(s2)
    8000444c:	c49d                	beqz	s1,8000447a <dirlink+0x54>
    8000444e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004450:	4741                	li	a4,16
    80004452:	86a6                	mv	a3,s1
    80004454:	fc040613          	addi	a2,s0,-64
    80004458:	4581                	li	a1,0
    8000445a:	854a                	mv	a0,s2
    8000445c:	00000097          	auipc	ra,0x0
    80004460:	b8a080e7          	jalr	-1142(ra) # 80003fe6 <readi>
    80004464:	47c1                	li	a5,16
    80004466:	06f51163          	bne	a0,a5,800044c8 <dirlink+0xa2>
    if(de.inum == 0)
    8000446a:	fc045783          	lhu	a5,-64(s0)
    8000446e:	c791                	beqz	a5,8000447a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004470:	24c1                	addiw	s1,s1,16
    80004472:	04c92783          	lw	a5,76(s2)
    80004476:	fcf4ede3          	bltu	s1,a5,80004450 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000447a:	4639                	li	a2,14
    8000447c:	85d2                	mv	a1,s4
    8000447e:	fc240513          	addi	a0,s0,-62
    80004482:	ffffd097          	auipc	ra,0xffffd
    80004486:	978080e7          	jalr	-1672(ra) # 80000dfa <strncpy>
  de.inum = inum;
    8000448a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000448e:	4741                	li	a4,16
    80004490:	86a6                	mv	a3,s1
    80004492:	fc040613          	addi	a2,s0,-64
    80004496:	4581                	li	a1,0
    80004498:	854a                	mv	a0,s2
    8000449a:	00000097          	auipc	ra,0x0
    8000449e:	c44080e7          	jalr	-956(ra) # 800040de <writei>
    800044a2:	1541                	addi	a0,a0,-16
    800044a4:	00a03533          	snez	a0,a0
    800044a8:	40a00533          	neg	a0,a0
}
    800044ac:	70e2                	ld	ra,56(sp)
    800044ae:	7442                	ld	s0,48(sp)
    800044b0:	74a2                	ld	s1,40(sp)
    800044b2:	7902                	ld	s2,32(sp)
    800044b4:	69e2                	ld	s3,24(sp)
    800044b6:	6a42                	ld	s4,16(sp)
    800044b8:	6121                	addi	sp,sp,64
    800044ba:	8082                	ret
    iput(ip);
    800044bc:	00000097          	auipc	ra,0x0
    800044c0:	a30080e7          	jalr	-1488(ra) # 80003eec <iput>
    return -1;
    800044c4:	557d                	li	a0,-1
    800044c6:	b7dd                	j	800044ac <dirlink+0x86>
      panic("dirlink read");
    800044c8:	00004517          	auipc	a0,0x4
    800044cc:	17050513          	addi	a0,a0,368 # 80008638 <syscalls+0x1e8>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	074080e7          	jalr	116(ra) # 80000544 <panic>

00000000800044d8 <namei>:

struct inode*
namei(char *path)
{
    800044d8:	1101                	addi	sp,sp,-32
    800044da:	ec06                	sd	ra,24(sp)
    800044dc:	e822                	sd	s0,16(sp)
    800044de:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044e0:	fe040613          	addi	a2,s0,-32
    800044e4:	4581                	li	a1,0
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	de0080e7          	jalr	-544(ra) # 800042c6 <namex>
}
    800044ee:	60e2                	ld	ra,24(sp)
    800044f0:	6442                	ld	s0,16(sp)
    800044f2:	6105                	addi	sp,sp,32
    800044f4:	8082                	ret

00000000800044f6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044f6:	1141                	addi	sp,sp,-16
    800044f8:	e406                	sd	ra,8(sp)
    800044fa:	e022                	sd	s0,0(sp)
    800044fc:	0800                	addi	s0,sp,16
    800044fe:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004500:	4585                	li	a1,1
    80004502:	00000097          	auipc	ra,0x0
    80004506:	dc4080e7          	jalr	-572(ra) # 800042c6 <namex>
}
    8000450a:	60a2                	ld	ra,8(sp)
    8000450c:	6402                	ld	s0,0(sp)
    8000450e:	0141                	addi	sp,sp,16
    80004510:	8082                	ret

0000000080004512 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004512:	1101                	addi	sp,sp,-32
    80004514:	ec06                	sd	ra,24(sp)
    80004516:	e822                	sd	s0,16(sp)
    80004518:	e426                	sd	s1,8(sp)
    8000451a:	e04a                	sd	s2,0(sp)
    8000451c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000451e:	0001d917          	auipc	s2,0x1d
    80004522:	40290913          	addi	s2,s2,1026 # 80021920 <log>
    80004526:	01892583          	lw	a1,24(s2)
    8000452a:	02892503          	lw	a0,40(s2)
    8000452e:	fffff097          	auipc	ra,0xfffff
    80004532:	fea080e7          	jalr	-22(ra) # 80003518 <bread>
    80004536:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004538:	02c92683          	lw	a3,44(s2)
    8000453c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000453e:	02d05763          	blez	a3,8000456c <write_head+0x5a>
    80004542:	0001d797          	auipc	a5,0x1d
    80004546:	40e78793          	addi	a5,a5,1038 # 80021950 <log+0x30>
    8000454a:	05c50713          	addi	a4,a0,92
    8000454e:	36fd                	addiw	a3,a3,-1
    80004550:	1682                	slli	a3,a3,0x20
    80004552:	9281                	srli	a3,a3,0x20
    80004554:	068a                	slli	a3,a3,0x2
    80004556:	0001d617          	auipc	a2,0x1d
    8000455a:	3fe60613          	addi	a2,a2,1022 # 80021954 <log+0x34>
    8000455e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004560:	4390                	lw	a2,0(a5)
    80004562:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004564:	0791                	addi	a5,a5,4
    80004566:	0711                	addi	a4,a4,4
    80004568:	fed79ce3          	bne	a5,a3,80004560 <write_head+0x4e>
  }
  bwrite(buf);
    8000456c:	8526                	mv	a0,s1
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	09c080e7          	jalr	156(ra) # 8000360a <bwrite>
  brelse(buf);
    80004576:	8526                	mv	a0,s1
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	0d0080e7          	jalr	208(ra) # 80003648 <brelse>
}
    80004580:	60e2                	ld	ra,24(sp)
    80004582:	6442                	ld	s0,16(sp)
    80004584:	64a2                	ld	s1,8(sp)
    80004586:	6902                	ld	s2,0(sp)
    80004588:	6105                	addi	sp,sp,32
    8000458a:	8082                	ret

000000008000458c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000458c:	0001d797          	auipc	a5,0x1d
    80004590:	3c07a783          	lw	a5,960(a5) # 8002194c <log+0x2c>
    80004594:	0af05d63          	blez	a5,8000464e <install_trans+0xc2>
{
    80004598:	7139                	addi	sp,sp,-64
    8000459a:	fc06                	sd	ra,56(sp)
    8000459c:	f822                	sd	s0,48(sp)
    8000459e:	f426                	sd	s1,40(sp)
    800045a0:	f04a                	sd	s2,32(sp)
    800045a2:	ec4e                	sd	s3,24(sp)
    800045a4:	e852                	sd	s4,16(sp)
    800045a6:	e456                	sd	s5,8(sp)
    800045a8:	e05a                	sd	s6,0(sp)
    800045aa:	0080                	addi	s0,sp,64
    800045ac:	8b2a                	mv	s6,a0
    800045ae:	0001da97          	auipc	s5,0x1d
    800045b2:	3a2a8a93          	addi	s5,s5,930 # 80021950 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045b6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045b8:	0001d997          	auipc	s3,0x1d
    800045bc:	36898993          	addi	s3,s3,872 # 80021920 <log>
    800045c0:	a035                	j	800045ec <install_trans+0x60>
      bunpin(dbuf);
    800045c2:	8526                	mv	a0,s1
    800045c4:	fffff097          	auipc	ra,0xfffff
    800045c8:	15e080e7          	jalr	350(ra) # 80003722 <bunpin>
    brelse(lbuf);
    800045cc:	854a                	mv	a0,s2
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	07a080e7          	jalr	122(ra) # 80003648 <brelse>
    brelse(dbuf);
    800045d6:	8526                	mv	a0,s1
    800045d8:	fffff097          	auipc	ra,0xfffff
    800045dc:	070080e7          	jalr	112(ra) # 80003648 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045e0:	2a05                	addiw	s4,s4,1
    800045e2:	0a91                	addi	s5,s5,4
    800045e4:	02c9a783          	lw	a5,44(s3)
    800045e8:	04fa5963          	bge	s4,a5,8000463a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045ec:	0189a583          	lw	a1,24(s3)
    800045f0:	014585bb          	addw	a1,a1,s4
    800045f4:	2585                	addiw	a1,a1,1
    800045f6:	0289a503          	lw	a0,40(s3)
    800045fa:	fffff097          	auipc	ra,0xfffff
    800045fe:	f1e080e7          	jalr	-226(ra) # 80003518 <bread>
    80004602:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004604:	000aa583          	lw	a1,0(s5)
    80004608:	0289a503          	lw	a0,40(s3)
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	f0c080e7          	jalr	-244(ra) # 80003518 <bread>
    80004614:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004616:	40000613          	li	a2,1024
    8000461a:	05890593          	addi	a1,s2,88
    8000461e:	05850513          	addi	a0,a0,88
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	724080e7          	jalr	1828(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000462a:	8526                	mv	a0,s1
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	fde080e7          	jalr	-34(ra) # 8000360a <bwrite>
    if(recovering == 0)
    80004634:	f80b1ce3          	bnez	s6,800045cc <install_trans+0x40>
    80004638:	b769                	j	800045c2 <install_trans+0x36>
}
    8000463a:	70e2                	ld	ra,56(sp)
    8000463c:	7442                	ld	s0,48(sp)
    8000463e:	74a2                	ld	s1,40(sp)
    80004640:	7902                	ld	s2,32(sp)
    80004642:	69e2                	ld	s3,24(sp)
    80004644:	6a42                	ld	s4,16(sp)
    80004646:	6aa2                	ld	s5,8(sp)
    80004648:	6b02                	ld	s6,0(sp)
    8000464a:	6121                	addi	sp,sp,64
    8000464c:	8082                	ret
    8000464e:	8082                	ret

0000000080004650 <initlog>:
{
    80004650:	7179                	addi	sp,sp,-48
    80004652:	f406                	sd	ra,40(sp)
    80004654:	f022                	sd	s0,32(sp)
    80004656:	ec26                	sd	s1,24(sp)
    80004658:	e84a                	sd	s2,16(sp)
    8000465a:	e44e                	sd	s3,8(sp)
    8000465c:	1800                	addi	s0,sp,48
    8000465e:	892a                	mv	s2,a0
    80004660:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004662:	0001d497          	auipc	s1,0x1d
    80004666:	2be48493          	addi	s1,s1,702 # 80021920 <log>
    8000466a:	00004597          	auipc	a1,0x4
    8000466e:	fde58593          	addi	a1,a1,-34 # 80008648 <syscalls+0x1f8>
    80004672:	8526                	mv	a0,s1
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	4e6080e7          	jalr	1254(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    8000467c:	0149a583          	lw	a1,20(s3)
    80004680:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004682:	0109a783          	lw	a5,16(s3)
    80004686:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004688:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000468c:	854a                	mv	a0,s2
    8000468e:	fffff097          	auipc	ra,0xfffff
    80004692:	e8a080e7          	jalr	-374(ra) # 80003518 <bread>
  log.lh.n = lh->n;
    80004696:	4d3c                	lw	a5,88(a0)
    80004698:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000469a:	02f05563          	blez	a5,800046c4 <initlog+0x74>
    8000469e:	05c50713          	addi	a4,a0,92
    800046a2:	0001d697          	auipc	a3,0x1d
    800046a6:	2ae68693          	addi	a3,a3,686 # 80021950 <log+0x30>
    800046aa:	37fd                	addiw	a5,a5,-1
    800046ac:	1782                	slli	a5,a5,0x20
    800046ae:	9381                	srli	a5,a5,0x20
    800046b0:	078a                	slli	a5,a5,0x2
    800046b2:	06050613          	addi	a2,a0,96
    800046b6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046b8:	4310                	lw	a2,0(a4)
    800046ba:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046bc:	0711                	addi	a4,a4,4
    800046be:	0691                	addi	a3,a3,4
    800046c0:	fef71ce3          	bne	a4,a5,800046b8 <initlog+0x68>
  brelse(buf);
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	f84080e7          	jalr	-124(ra) # 80003648 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046cc:	4505                	li	a0,1
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	ebe080e7          	jalr	-322(ra) # 8000458c <install_trans>
  log.lh.n = 0;
    800046d6:	0001d797          	auipc	a5,0x1d
    800046da:	2607ab23          	sw	zero,630(a5) # 8002194c <log+0x2c>
  write_head(); // clear the log
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	e34080e7          	jalr	-460(ra) # 80004512 <write_head>
}
    800046e6:	70a2                	ld	ra,40(sp)
    800046e8:	7402                	ld	s0,32(sp)
    800046ea:	64e2                	ld	s1,24(sp)
    800046ec:	6942                	ld	s2,16(sp)
    800046ee:	69a2                	ld	s3,8(sp)
    800046f0:	6145                	addi	sp,sp,48
    800046f2:	8082                	ret

00000000800046f4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046f4:	1101                	addi	sp,sp,-32
    800046f6:	ec06                	sd	ra,24(sp)
    800046f8:	e822                	sd	s0,16(sp)
    800046fa:	e426                	sd	s1,8(sp)
    800046fc:	e04a                	sd	s2,0(sp)
    800046fe:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004700:	0001d517          	auipc	a0,0x1d
    80004704:	22050513          	addi	a0,a0,544 # 80021920 <log>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	4e2080e7          	jalr	1250(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004710:	0001d497          	auipc	s1,0x1d
    80004714:	21048493          	addi	s1,s1,528 # 80021920 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004718:	4979                	li	s2,30
    8000471a:	a039                	j	80004728 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000471c:	85a6                	mv	a1,s1
    8000471e:	8526                	mv	a0,s1
    80004720:	ffffe097          	auipc	ra,0xffffe
    80004724:	9fa080e7          	jalr	-1542(ra) # 8000211a <sleep>
    if(log.committing){
    80004728:	50dc                	lw	a5,36(s1)
    8000472a:	fbed                	bnez	a5,8000471c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000472c:	509c                	lw	a5,32(s1)
    8000472e:	0017871b          	addiw	a4,a5,1
    80004732:	0007069b          	sext.w	a3,a4
    80004736:	0027179b          	slliw	a5,a4,0x2
    8000473a:	9fb9                	addw	a5,a5,a4
    8000473c:	0017979b          	slliw	a5,a5,0x1
    80004740:	54d8                	lw	a4,44(s1)
    80004742:	9fb9                	addw	a5,a5,a4
    80004744:	00f95963          	bge	s2,a5,80004756 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004748:	85a6                	mv	a1,s1
    8000474a:	8526                	mv	a0,s1
    8000474c:	ffffe097          	auipc	ra,0xffffe
    80004750:	9ce080e7          	jalr	-1586(ra) # 8000211a <sleep>
    80004754:	bfd1                	j	80004728 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004756:	0001d517          	auipc	a0,0x1d
    8000475a:	1ca50513          	addi	a0,a0,458 # 80021920 <log>
    8000475e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	53e080e7          	jalr	1342(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004768:	60e2                	ld	ra,24(sp)
    8000476a:	6442                	ld	s0,16(sp)
    8000476c:	64a2                	ld	s1,8(sp)
    8000476e:	6902                	ld	s2,0(sp)
    80004770:	6105                	addi	sp,sp,32
    80004772:	8082                	ret

0000000080004774 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004774:	7139                	addi	sp,sp,-64
    80004776:	fc06                	sd	ra,56(sp)
    80004778:	f822                	sd	s0,48(sp)
    8000477a:	f426                	sd	s1,40(sp)
    8000477c:	f04a                	sd	s2,32(sp)
    8000477e:	ec4e                	sd	s3,24(sp)
    80004780:	e852                	sd	s4,16(sp)
    80004782:	e456                	sd	s5,8(sp)
    80004784:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004786:	0001d497          	auipc	s1,0x1d
    8000478a:	19a48493          	addi	s1,s1,410 # 80021920 <log>
    8000478e:	8526                	mv	a0,s1
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	45a080e7          	jalr	1114(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004798:	509c                	lw	a5,32(s1)
    8000479a:	37fd                	addiw	a5,a5,-1
    8000479c:	0007891b          	sext.w	s2,a5
    800047a0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047a2:	50dc                	lw	a5,36(s1)
    800047a4:	efb9                	bnez	a5,80004802 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047a6:	06091663          	bnez	s2,80004812 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800047aa:	0001d497          	auipc	s1,0x1d
    800047ae:	17648493          	addi	s1,s1,374 # 80021920 <log>
    800047b2:	4785                	li	a5,1
    800047b4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	4e6080e7          	jalr	1254(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047c0:	54dc                	lw	a5,44(s1)
    800047c2:	06f04763          	bgtz	a5,80004830 <end_op+0xbc>
    acquire(&log.lock);
    800047c6:	0001d497          	auipc	s1,0x1d
    800047ca:	15a48493          	addi	s1,s1,346 # 80021920 <log>
    800047ce:	8526                	mv	a0,s1
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	41a080e7          	jalr	1050(ra) # 80000bea <acquire>
    log.committing = 0;
    800047d8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047dc:	8526                	mv	a0,s1
    800047de:	ffffe097          	auipc	ra,0xffffe
    800047e2:	9a0080e7          	jalr	-1632(ra) # 8000217e <wakeup>
    release(&log.lock);
    800047e6:	8526                	mv	a0,s1
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	4b6080e7          	jalr	1206(ra) # 80000c9e <release>
}
    800047f0:	70e2                	ld	ra,56(sp)
    800047f2:	7442                	ld	s0,48(sp)
    800047f4:	74a2                	ld	s1,40(sp)
    800047f6:	7902                	ld	s2,32(sp)
    800047f8:	69e2                	ld	s3,24(sp)
    800047fa:	6a42                	ld	s4,16(sp)
    800047fc:	6aa2                	ld	s5,8(sp)
    800047fe:	6121                	addi	sp,sp,64
    80004800:	8082                	ret
    panic("log.committing");
    80004802:	00004517          	auipc	a0,0x4
    80004806:	e4e50513          	addi	a0,a0,-434 # 80008650 <syscalls+0x200>
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	d3a080e7          	jalr	-710(ra) # 80000544 <panic>
    wakeup(&log);
    80004812:	0001d497          	auipc	s1,0x1d
    80004816:	10e48493          	addi	s1,s1,270 # 80021920 <log>
    8000481a:	8526                	mv	a0,s1
    8000481c:	ffffe097          	auipc	ra,0xffffe
    80004820:	962080e7          	jalr	-1694(ra) # 8000217e <wakeup>
  release(&log.lock);
    80004824:	8526                	mv	a0,s1
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	478080e7          	jalr	1144(ra) # 80000c9e <release>
  if(do_commit){
    8000482e:	b7c9                	j	800047f0 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004830:	0001da97          	auipc	s5,0x1d
    80004834:	120a8a93          	addi	s5,s5,288 # 80021950 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004838:	0001da17          	auipc	s4,0x1d
    8000483c:	0e8a0a13          	addi	s4,s4,232 # 80021920 <log>
    80004840:	018a2583          	lw	a1,24(s4)
    80004844:	012585bb          	addw	a1,a1,s2
    80004848:	2585                	addiw	a1,a1,1
    8000484a:	028a2503          	lw	a0,40(s4)
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	cca080e7          	jalr	-822(ra) # 80003518 <bread>
    80004856:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004858:	000aa583          	lw	a1,0(s5)
    8000485c:	028a2503          	lw	a0,40(s4)
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	cb8080e7          	jalr	-840(ra) # 80003518 <bread>
    80004868:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000486a:	40000613          	li	a2,1024
    8000486e:	05850593          	addi	a1,a0,88
    80004872:	05848513          	addi	a0,s1,88
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	4d0080e7          	jalr	1232(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    8000487e:	8526                	mv	a0,s1
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	d8a080e7          	jalr	-630(ra) # 8000360a <bwrite>
    brelse(from);
    80004888:	854e                	mv	a0,s3
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	dbe080e7          	jalr	-578(ra) # 80003648 <brelse>
    brelse(to);
    80004892:	8526                	mv	a0,s1
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	db4080e7          	jalr	-588(ra) # 80003648 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000489c:	2905                	addiw	s2,s2,1
    8000489e:	0a91                	addi	s5,s5,4
    800048a0:	02ca2783          	lw	a5,44(s4)
    800048a4:	f8f94ee3          	blt	s2,a5,80004840 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	c6a080e7          	jalr	-918(ra) # 80004512 <write_head>
    install_trans(0); // Now install writes to home locations
    800048b0:	4501                	li	a0,0
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	cda080e7          	jalr	-806(ra) # 8000458c <install_trans>
    log.lh.n = 0;
    800048ba:	0001d797          	auipc	a5,0x1d
    800048be:	0807a923          	sw	zero,146(a5) # 8002194c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048c2:	00000097          	auipc	ra,0x0
    800048c6:	c50080e7          	jalr	-944(ra) # 80004512 <write_head>
    800048ca:	bdf5                	j	800047c6 <end_op+0x52>

00000000800048cc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048cc:	1101                	addi	sp,sp,-32
    800048ce:	ec06                	sd	ra,24(sp)
    800048d0:	e822                	sd	s0,16(sp)
    800048d2:	e426                	sd	s1,8(sp)
    800048d4:	e04a                	sd	s2,0(sp)
    800048d6:	1000                	addi	s0,sp,32
    800048d8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048da:	0001d917          	auipc	s2,0x1d
    800048de:	04690913          	addi	s2,s2,70 # 80021920 <log>
    800048e2:	854a                	mv	a0,s2
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	306080e7          	jalr	774(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048ec:	02c92603          	lw	a2,44(s2)
    800048f0:	47f5                	li	a5,29
    800048f2:	06c7c563          	blt	a5,a2,8000495c <log_write+0x90>
    800048f6:	0001d797          	auipc	a5,0x1d
    800048fa:	0467a783          	lw	a5,70(a5) # 8002193c <log+0x1c>
    800048fe:	37fd                	addiw	a5,a5,-1
    80004900:	04f65e63          	bge	a2,a5,8000495c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004904:	0001d797          	auipc	a5,0x1d
    80004908:	03c7a783          	lw	a5,60(a5) # 80021940 <log+0x20>
    8000490c:	06f05063          	blez	a5,8000496c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004910:	4781                	li	a5,0
    80004912:	06c05563          	blez	a2,8000497c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004916:	44cc                	lw	a1,12(s1)
    80004918:	0001d717          	auipc	a4,0x1d
    8000491c:	03870713          	addi	a4,a4,56 # 80021950 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004920:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004922:	4314                	lw	a3,0(a4)
    80004924:	04b68c63          	beq	a3,a1,8000497c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004928:	2785                	addiw	a5,a5,1
    8000492a:	0711                	addi	a4,a4,4
    8000492c:	fef61be3          	bne	a2,a5,80004922 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004930:	0621                	addi	a2,a2,8
    80004932:	060a                	slli	a2,a2,0x2
    80004934:	0001d797          	auipc	a5,0x1d
    80004938:	fec78793          	addi	a5,a5,-20 # 80021920 <log>
    8000493c:	963e                	add	a2,a2,a5
    8000493e:	44dc                	lw	a5,12(s1)
    80004940:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004942:	8526                	mv	a0,s1
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	da2080e7          	jalr	-606(ra) # 800036e6 <bpin>
    log.lh.n++;
    8000494c:	0001d717          	auipc	a4,0x1d
    80004950:	fd470713          	addi	a4,a4,-44 # 80021920 <log>
    80004954:	575c                	lw	a5,44(a4)
    80004956:	2785                	addiw	a5,a5,1
    80004958:	d75c                	sw	a5,44(a4)
    8000495a:	a835                	j	80004996 <log_write+0xca>
    panic("too big a transaction");
    8000495c:	00004517          	auipc	a0,0x4
    80004960:	d0450513          	addi	a0,a0,-764 # 80008660 <syscalls+0x210>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	be0080e7          	jalr	-1056(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    8000496c:	00004517          	auipc	a0,0x4
    80004970:	d0c50513          	addi	a0,a0,-756 # 80008678 <syscalls+0x228>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	bd0080e7          	jalr	-1072(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    8000497c:	00878713          	addi	a4,a5,8
    80004980:	00271693          	slli	a3,a4,0x2
    80004984:	0001d717          	auipc	a4,0x1d
    80004988:	f9c70713          	addi	a4,a4,-100 # 80021920 <log>
    8000498c:	9736                	add	a4,a4,a3
    8000498e:	44d4                	lw	a3,12(s1)
    80004990:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004992:	faf608e3          	beq	a2,a5,80004942 <log_write+0x76>
  }
  release(&log.lock);
    80004996:	0001d517          	auipc	a0,0x1d
    8000499a:	f8a50513          	addi	a0,a0,-118 # 80021920 <log>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	300080e7          	jalr	768(ra) # 80000c9e <release>
}
    800049a6:	60e2                	ld	ra,24(sp)
    800049a8:	6442                	ld	s0,16(sp)
    800049aa:	64a2                	ld	s1,8(sp)
    800049ac:	6902                	ld	s2,0(sp)
    800049ae:	6105                	addi	sp,sp,32
    800049b0:	8082                	ret

00000000800049b2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049b2:	1101                	addi	sp,sp,-32
    800049b4:	ec06                	sd	ra,24(sp)
    800049b6:	e822                	sd	s0,16(sp)
    800049b8:	e426                	sd	s1,8(sp)
    800049ba:	e04a                	sd	s2,0(sp)
    800049bc:	1000                	addi	s0,sp,32
    800049be:	84aa                	mv	s1,a0
    800049c0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049c2:	00004597          	auipc	a1,0x4
    800049c6:	cd658593          	addi	a1,a1,-810 # 80008698 <syscalls+0x248>
    800049ca:	0521                	addi	a0,a0,8
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	18e080e7          	jalr	398(ra) # 80000b5a <initlock>
  lk->name = name;
    800049d4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049d8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049dc:	0204a423          	sw	zero,40(s1)
}
    800049e0:	60e2                	ld	ra,24(sp)
    800049e2:	6442                	ld	s0,16(sp)
    800049e4:	64a2                	ld	s1,8(sp)
    800049e6:	6902                	ld	s2,0(sp)
    800049e8:	6105                	addi	sp,sp,32
    800049ea:	8082                	ret

00000000800049ec <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049ec:	1101                	addi	sp,sp,-32
    800049ee:	ec06                	sd	ra,24(sp)
    800049f0:	e822                	sd	s0,16(sp)
    800049f2:	e426                	sd	s1,8(sp)
    800049f4:	e04a                	sd	s2,0(sp)
    800049f6:	1000                	addi	s0,sp,32
    800049f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049fa:	00850913          	addi	s2,a0,8
    800049fe:	854a                	mv	a0,s2
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	1ea080e7          	jalr	490(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004a08:	409c                	lw	a5,0(s1)
    80004a0a:	cb89                	beqz	a5,80004a1c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a0c:	85ca                	mv	a1,s2
    80004a0e:	8526                	mv	a0,s1
    80004a10:	ffffd097          	auipc	ra,0xffffd
    80004a14:	70a080e7          	jalr	1802(ra) # 8000211a <sleep>
  while (lk->locked) {
    80004a18:	409c                	lw	a5,0(s1)
    80004a1a:	fbed                	bnez	a5,80004a0c <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a1c:	4785                	li	a5,1
    80004a1e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a20:	ffffd097          	auipc	ra,0xffffd
    80004a24:	fa6080e7          	jalr	-90(ra) # 800019c6 <myproc>
    80004a28:	591c                	lw	a5,48(a0)
    80004a2a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a2c:	854a                	mv	a0,s2
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	270080e7          	jalr	624(ra) # 80000c9e <release>
}
    80004a36:	60e2                	ld	ra,24(sp)
    80004a38:	6442                	ld	s0,16(sp)
    80004a3a:	64a2                	ld	s1,8(sp)
    80004a3c:	6902                	ld	s2,0(sp)
    80004a3e:	6105                	addi	sp,sp,32
    80004a40:	8082                	ret

0000000080004a42 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a42:	1101                	addi	sp,sp,-32
    80004a44:	ec06                	sd	ra,24(sp)
    80004a46:	e822                	sd	s0,16(sp)
    80004a48:	e426                	sd	s1,8(sp)
    80004a4a:	e04a                	sd	s2,0(sp)
    80004a4c:	1000                	addi	s0,sp,32
    80004a4e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a50:	00850913          	addi	s2,a0,8
    80004a54:	854a                	mv	a0,s2
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	194080e7          	jalr	404(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004a5e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a62:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffd097          	auipc	ra,0xffffd
    80004a6c:	716080e7          	jalr	1814(ra) # 8000217e <wakeup>
  release(&lk->lk);
    80004a70:	854a                	mv	a0,s2
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	22c080e7          	jalr	556(ra) # 80000c9e <release>
}
    80004a7a:	60e2                	ld	ra,24(sp)
    80004a7c:	6442                	ld	s0,16(sp)
    80004a7e:	64a2                	ld	s1,8(sp)
    80004a80:	6902                	ld	s2,0(sp)
    80004a82:	6105                	addi	sp,sp,32
    80004a84:	8082                	ret

0000000080004a86 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a86:	7179                	addi	sp,sp,-48
    80004a88:	f406                	sd	ra,40(sp)
    80004a8a:	f022                	sd	s0,32(sp)
    80004a8c:	ec26                	sd	s1,24(sp)
    80004a8e:	e84a                	sd	s2,16(sp)
    80004a90:	e44e                	sd	s3,8(sp)
    80004a92:	1800                	addi	s0,sp,48
    80004a94:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a96:	00850913          	addi	s2,a0,8
    80004a9a:	854a                	mv	a0,s2
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	14e080e7          	jalr	334(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aa4:	409c                	lw	a5,0(s1)
    80004aa6:	ef99                	bnez	a5,80004ac4 <holdingsleep+0x3e>
    80004aa8:	4481                	li	s1,0
  release(&lk->lk);
    80004aaa:	854a                	mv	a0,s2
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	1f2080e7          	jalr	498(ra) # 80000c9e <release>
  return r;
}
    80004ab4:	8526                	mv	a0,s1
    80004ab6:	70a2                	ld	ra,40(sp)
    80004ab8:	7402                	ld	s0,32(sp)
    80004aba:	64e2                	ld	s1,24(sp)
    80004abc:	6942                	ld	s2,16(sp)
    80004abe:	69a2                	ld	s3,8(sp)
    80004ac0:	6145                	addi	sp,sp,48
    80004ac2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ac4:	0284a983          	lw	s3,40(s1)
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	efe080e7          	jalr	-258(ra) # 800019c6 <myproc>
    80004ad0:	5904                	lw	s1,48(a0)
    80004ad2:	413484b3          	sub	s1,s1,s3
    80004ad6:	0014b493          	seqz	s1,s1
    80004ada:	bfc1                	j	80004aaa <holdingsleep+0x24>

0000000080004adc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004adc:	1141                	addi	sp,sp,-16
    80004ade:	e406                	sd	ra,8(sp)
    80004ae0:	e022                	sd	s0,0(sp)
    80004ae2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ae4:	00004597          	auipc	a1,0x4
    80004ae8:	bc458593          	addi	a1,a1,-1084 # 800086a8 <syscalls+0x258>
    80004aec:	0001d517          	auipc	a0,0x1d
    80004af0:	f7c50513          	addi	a0,a0,-132 # 80021a68 <ftable>
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	066080e7          	jalr	102(ra) # 80000b5a <initlock>
}
    80004afc:	60a2                	ld	ra,8(sp)
    80004afe:	6402                	ld	s0,0(sp)
    80004b00:	0141                	addi	sp,sp,16
    80004b02:	8082                	ret

0000000080004b04 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b04:	1101                	addi	sp,sp,-32
    80004b06:	ec06                	sd	ra,24(sp)
    80004b08:	e822                	sd	s0,16(sp)
    80004b0a:	e426                	sd	s1,8(sp)
    80004b0c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b0e:	0001d517          	auipc	a0,0x1d
    80004b12:	f5a50513          	addi	a0,a0,-166 # 80021a68 <ftable>
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	0d4080e7          	jalr	212(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b1e:	0001d497          	auipc	s1,0x1d
    80004b22:	f6248493          	addi	s1,s1,-158 # 80021a80 <ftable+0x18>
    80004b26:	0001e717          	auipc	a4,0x1e
    80004b2a:	efa70713          	addi	a4,a4,-262 # 80022a20 <disk>
    if(f->ref == 0){
    80004b2e:	40dc                	lw	a5,4(s1)
    80004b30:	cf99                	beqz	a5,80004b4e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b32:	02848493          	addi	s1,s1,40
    80004b36:	fee49ce3          	bne	s1,a4,80004b2e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b3a:	0001d517          	auipc	a0,0x1d
    80004b3e:	f2e50513          	addi	a0,a0,-210 # 80021a68 <ftable>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	15c080e7          	jalr	348(ra) # 80000c9e <release>
  return 0;
    80004b4a:	4481                	li	s1,0
    80004b4c:	a819                	j	80004b62 <filealloc+0x5e>
      f->ref = 1;
    80004b4e:	4785                	li	a5,1
    80004b50:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b52:	0001d517          	auipc	a0,0x1d
    80004b56:	f1650513          	addi	a0,a0,-234 # 80021a68 <ftable>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	144080e7          	jalr	324(ra) # 80000c9e <release>
}
    80004b62:	8526                	mv	a0,s1
    80004b64:	60e2                	ld	ra,24(sp)
    80004b66:	6442                	ld	s0,16(sp)
    80004b68:	64a2                	ld	s1,8(sp)
    80004b6a:	6105                	addi	sp,sp,32
    80004b6c:	8082                	ret

0000000080004b6e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b6e:	1101                	addi	sp,sp,-32
    80004b70:	ec06                	sd	ra,24(sp)
    80004b72:	e822                	sd	s0,16(sp)
    80004b74:	e426                	sd	s1,8(sp)
    80004b76:	1000                	addi	s0,sp,32
    80004b78:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b7a:	0001d517          	auipc	a0,0x1d
    80004b7e:	eee50513          	addi	a0,a0,-274 # 80021a68 <ftable>
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	068080e7          	jalr	104(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004b8a:	40dc                	lw	a5,4(s1)
    80004b8c:	02f05263          	blez	a5,80004bb0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b90:	2785                	addiw	a5,a5,1
    80004b92:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b94:	0001d517          	auipc	a0,0x1d
    80004b98:	ed450513          	addi	a0,a0,-300 # 80021a68 <ftable>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	102080e7          	jalr	258(ra) # 80000c9e <release>
  return f;
}
    80004ba4:	8526                	mv	a0,s1
    80004ba6:	60e2                	ld	ra,24(sp)
    80004ba8:	6442                	ld	s0,16(sp)
    80004baa:	64a2                	ld	s1,8(sp)
    80004bac:	6105                	addi	sp,sp,32
    80004bae:	8082                	ret
    panic("filedup");
    80004bb0:	00004517          	auipc	a0,0x4
    80004bb4:	b0050513          	addi	a0,a0,-1280 # 800086b0 <syscalls+0x260>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	98c080e7          	jalr	-1652(ra) # 80000544 <panic>

0000000080004bc0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bc0:	7139                	addi	sp,sp,-64
    80004bc2:	fc06                	sd	ra,56(sp)
    80004bc4:	f822                	sd	s0,48(sp)
    80004bc6:	f426                	sd	s1,40(sp)
    80004bc8:	f04a                	sd	s2,32(sp)
    80004bca:	ec4e                	sd	s3,24(sp)
    80004bcc:	e852                	sd	s4,16(sp)
    80004bce:	e456                	sd	s5,8(sp)
    80004bd0:	0080                	addi	s0,sp,64
    80004bd2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bd4:	0001d517          	auipc	a0,0x1d
    80004bd8:	e9450513          	addi	a0,a0,-364 # 80021a68 <ftable>
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	00e080e7          	jalr	14(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004be4:	40dc                	lw	a5,4(s1)
    80004be6:	06f05163          	blez	a5,80004c48 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bea:	37fd                	addiw	a5,a5,-1
    80004bec:	0007871b          	sext.w	a4,a5
    80004bf0:	c0dc                	sw	a5,4(s1)
    80004bf2:	06e04363          	bgtz	a4,80004c58 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bf6:	0004a903          	lw	s2,0(s1)
    80004bfa:	0094ca83          	lbu	s5,9(s1)
    80004bfe:	0104ba03          	ld	s4,16(s1)
    80004c02:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c06:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c0a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c0e:	0001d517          	auipc	a0,0x1d
    80004c12:	e5a50513          	addi	a0,a0,-422 # 80021a68 <ftable>
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	088080e7          	jalr	136(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004c1e:	4785                	li	a5,1
    80004c20:	04f90d63          	beq	s2,a5,80004c7a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c24:	3979                	addiw	s2,s2,-2
    80004c26:	4785                	li	a5,1
    80004c28:	0527e063          	bltu	a5,s2,80004c68 <fileclose+0xa8>
    begin_op();
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	ac8080e7          	jalr	-1336(ra) # 800046f4 <begin_op>
    iput(ff.ip);
    80004c34:	854e                	mv	a0,s3
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	2b6080e7          	jalr	694(ra) # 80003eec <iput>
    end_op();
    80004c3e:	00000097          	auipc	ra,0x0
    80004c42:	b36080e7          	jalr	-1226(ra) # 80004774 <end_op>
    80004c46:	a00d                	j	80004c68 <fileclose+0xa8>
    panic("fileclose");
    80004c48:	00004517          	auipc	a0,0x4
    80004c4c:	a7050513          	addi	a0,a0,-1424 # 800086b8 <syscalls+0x268>
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	8f4080e7          	jalr	-1804(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004c58:	0001d517          	auipc	a0,0x1d
    80004c5c:	e1050513          	addi	a0,a0,-496 # 80021a68 <ftable>
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	03e080e7          	jalr	62(ra) # 80000c9e <release>
  }
}
    80004c68:	70e2                	ld	ra,56(sp)
    80004c6a:	7442                	ld	s0,48(sp)
    80004c6c:	74a2                	ld	s1,40(sp)
    80004c6e:	7902                	ld	s2,32(sp)
    80004c70:	69e2                	ld	s3,24(sp)
    80004c72:	6a42                	ld	s4,16(sp)
    80004c74:	6aa2                	ld	s5,8(sp)
    80004c76:	6121                	addi	sp,sp,64
    80004c78:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c7a:	85d6                	mv	a1,s5
    80004c7c:	8552                	mv	a0,s4
    80004c7e:	00000097          	auipc	ra,0x0
    80004c82:	34c080e7          	jalr	844(ra) # 80004fca <pipeclose>
    80004c86:	b7cd                	j	80004c68 <fileclose+0xa8>

0000000080004c88 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c88:	715d                	addi	sp,sp,-80
    80004c8a:	e486                	sd	ra,72(sp)
    80004c8c:	e0a2                	sd	s0,64(sp)
    80004c8e:	fc26                	sd	s1,56(sp)
    80004c90:	f84a                	sd	s2,48(sp)
    80004c92:	f44e                	sd	s3,40(sp)
    80004c94:	0880                	addi	s0,sp,80
    80004c96:	84aa                	mv	s1,a0
    80004c98:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	d2c080e7          	jalr	-724(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ca2:	409c                	lw	a5,0(s1)
    80004ca4:	37f9                	addiw	a5,a5,-2
    80004ca6:	4705                	li	a4,1
    80004ca8:	04f76763          	bltu	a4,a5,80004cf6 <filestat+0x6e>
    80004cac:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cae:	6c88                	ld	a0,24(s1)
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	082080e7          	jalr	130(ra) # 80003d32 <ilock>
    stati(f->ip, &st);
    80004cb8:	fb840593          	addi	a1,s0,-72
    80004cbc:	6c88                	ld	a0,24(s1)
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	2fe080e7          	jalr	766(ra) # 80003fbc <stati>
    iunlock(f->ip);
    80004cc6:	6c88                	ld	a0,24(s1)
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	12c080e7          	jalr	300(ra) # 80003df4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cd0:	46e1                	li	a3,24
    80004cd2:	fb840613          	addi	a2,s0,-72
    80004cd6:	85ce                	mv	a1,s3
    80004cd8:	05093503          	ld	a0,80(s2)
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	9a8080e7          	jalr	-1624(ra) # 80001684 <copyout>
    80004ce4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ce8:	60a6                	ld	ra,72(sp)
    80004cea:	6406                	ld	s0,64(sp)
    80004cec:	74e2                	ld	s1,56(sp)
    80004cee:	7942                	ld	s2,48(sp)
    80004cf0:	79a2                	ld	s3,40(sp)
    80004cf2:	6161                	addi	sp,sp,80
    80004cf4:	8082                	ret
  return -1;
    80004cf6:	557d                	li	a0,-1
    80004cf8:	bfc5                	j	80004ce8 <filestat+0x60>

0000000080004cfa <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cfa:	7179                	addi	sp,sp,-48
    80004cfc:	f406                	sd	ra,40(sp)
    80004cfe:	f022                	sd	s0,32(sp)
    80004d00:	ec26                	sd	s1,24(sp)
    80004d02:	e84a                	sd	s2,16(sp)
    80004d04:	e44e                	sd	s3,8(sp)
    80004d06:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d08:	00854783          	lbu	a5,8(a0)
    80004d0c:	c3d5                	beqz	a5,80004db0 <fileread+0xb6>
    80004d0e:	84aa                	mv	s1,a0
    80004d10:	89ae                	mv	s3,a1
    80004d12:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d14:	411c                	lw	a5,0(a0)
    80004d16:	4705                	li	a4,1
    80004d18:	04e78963          	beq	a5,a4,80004d6a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d1c:	470d                	li	a4,3
    80004d1e:	04e78d63          	beq	a5,a4,80004d78 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d22:	4709                	li	a4,2
    80004d24:	06e79e63          	bne	a5,a4,80004da0 <fileread+0xa6>
    ilock(f->ip);
    80004d28:	6d08                	ld	a0,24(a0)
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	008080e7          	jalr	8(ra) # 80003d32 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d32:	874a                	mv	a4,s2
    80004d34:	5094                	lw	a3,32(s1)
    80004d36:	864e                	mv	a2,s3
    80004d38:	4585                	li	a1,1
    80004d3a:	6c88                	ld	a0,24(s1)
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	2aa080e7          	jalr	682(ra) # 80003fe6 <readi>
    80004d44:	892a                	mv	s2,a0
    80004d46:	00a05563          	blez	a0,80004d50 <fileread+0x56>
      f->off += r;
    80004d4a:	509c                	lw	a5,32(s1)
    80004d4c:	9fa9                	addw	a5,a5,a0
    80004d4e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d50:	6c88                	ld	a0,24(s1)
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	0a2080e7          	jalr	162(ra) # 80003df4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d5a:	854a                	mv	a0,s2
    80004d5c:	70a2                	ld	ra,40(sp)
    80004d5e:	7402                	ld	s0,32(sp)
    80004d60:	64e2                	ld	s1,24(sp)
    80004d62:	6942                	ld	s2,16(sp)
    80004d64:	69a2                	ld	s3,8(sp)
    80004d66:	6145                	addi	sp,sp,48
    80004d68:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d6a:	6908                	ld	a0,16(a0)
    80004d6c:	00000097          	auipc	ra,0x0
    80004d70:	3ce080e7          	jalr	974(ra) # 8000513a <piperead>
    80004d74:	892a                	mv	s2,a0
    80004d76:	b7d5                	j	80004d5a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d78:	02451783          	lh	a5,36(a0)
    80004d7c:	03079693          	slli	a3,a5,0x30
    80004d80:	92c1                	srli	a3,a3,0x30
    80004d82:	4725                	li	a4,9
    80004d84:	02d76863          	bltu	a4,a3,80004db4 <fileread+0xba>
    80004d88:	0792                	slli	a5,a5,0x4
    80004d8a:	0001d717          	auipc	a4,0x1d
    80004d8e:	c3e70713          	addi	a4,a4,-962 # 800219c8 <devsw>
    80004d92:	97ba                	add	a5,a5,a4
    80004d94:	639c                	ld	a5,0(a5)
    80004d96:	c38d                	beqz	a5,80004db8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d98:	4505                	li	a0,1
    80004d9a:	9782                	jalr	a5
    80004d9c:	892a                	mv	s2,a0
    80004d9e:	bf75                	j	80004d5a <fileread+0x60>
    panic("fileread");
    80004da0:	00004517          	auipc	a0,0x4
    80004da4:	92850513          	addi	a0,a0,-1752 # 800086c8 <syscalls+0x278>
    80004da8:	ffffb097          	auipc	ra,0xffffb
    80004dac:	79c080e7          	jalr	1948(ra) # 80000544 <panic>
    return -1;
    80004db0:	597d                	li	s2,-1
    80004db2:	b765                	j	80004d5a <fileread+0x60>
      return -1;
    80004db4:	597d                	li	s2,-1
    80004db6:	b755                	j	80004d5a <fileread+0x60>
    80004db8:	597d                	li	s2,-1
    80004dba:	b745                	j	80004d5a <fileread+0x60>

0000000080004dbc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004dbc:	715d                	addi	sp,sp,-80
    80004dbe:	e486                	sd	ra,72(sp)
    80004dc0:	e0a2                	sd	s0,64(sp)
    80004dc2:	fc26                	sd	s1,56(sp)
    80004dc4:	f84a                	sd	s2,48(sp)
    80004dc6:	f44e                	sd	s3,40(sp)
    80004dc8:	f052                	sd	s4,32(sp)
    80004dca:	ec56                	sd	s5,24(sp)
    80004dcc:	e85a                	sd	s6,16(sp)
    80004dce:	e45e                	sd	s7,8(sp)
    80004dd0:	e062                	sd	s8,0(sp)
    80004dd2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dd4:	00954783          	lbu	a5,9(a0)
    80004dd8:	10078663          	beqz	a5,80004ee4 <filewrite+0x128>
    80004ddc:	892a                	mv	s2,a0
    80004dde:	8aae                	mv	s5,a1
    80004de0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004de2:	411c                	lw	a5,0(a0)
    80004de4:	4705                	li	a4,1
    80004de6:	02e78263          	beq	a5,a4,80004e0a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dea:	470d                	li	a4,3
    80004dec:	02e78663          	beq	a5,a4,80004e18 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004df0:	4709                	li	a4,2
    80004df2:	0ee79163          	bne	a5,a4,80004ed4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004df6:	0ac05d63          	blez	a2,80004eb0 <filewrite+0xf4>
    int i = 0;
    80004dfa:	4981                	li	s3,0
    80004dfc:	6b05                	lui	s6,0x1
    80004dfe:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e02:	6b85                	lui	s7,0x1
    80004e04:	c00b8b9b          	addiw	s7,s7,-1024
    80004e08:	a861                	j	80004ea0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e0a:	6908                	ld	a0,16(a0)
    80004e0c:	00000097          	auipc	ra,0x0
    80004e10:	22e080e7          	jalr	558(ra) # 8000503a <pipewrite>
    80004e14:	8a2a                	mv	s4,a0
    80004e16:	a045                	j	80004eb6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e18:	02451783          	lh	a5,36(a0)
    80004e1c:	03079693          	slli	a3,a5,0x30
    80004e20:	92c1                	srli	a3,a3,0x30
    80004e22:	4725                	li	a4,9
    80004e24:	0cd76263          	bltu	a4,a3,80004ee8 <filewrite+0x12c>
    80004e28:	0792                	slli	a5,a5,0x4
    80004e2a:	0001d717          	auipc	a4,0x1d
    80004e2e:	b9e70713          	addi	a4,a4,-1122 # 800219c8 <devsw>
    80004e32:	97ba                	add	a5,a5,a4
    80004e34:	679c                	ld	a5,8(a5)
    80004e36:	cbdd                	beqz	a5,80004eec <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e38:	4505                	li	a0,1
    80004e3a:	9782                	jalr	a5
    80004e3c:	8a2a                	mv	s4,a0
    80004e3e:	a8a5                	j	80004eb6 <filewrite+0xfa>
    80004e40:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e44:	00000097          	auipc	ra,0x0
    80004e48:	8b0080e7          	jalr	-1872(ra) # 800046f4 <begin_op>
      ilock(f->ip);
    80004e4c:	01893503          	ld	a0,24(s2)
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	ee2080e7          	jalr	-286(ra) # 80003d32 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e58:	8762                	mv	a4,s8
    80004e5a:	02092683          	lw	a3,32(s2)
    80004e5e:	01598633          	add	a2,s3,s5
    80004e62:	4585                	li	a1,1
    80004e64:	01893503          	ld	a0,24(s2)
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	276080e7          	jalr	630(ra) # 800040de <writei>
    80004e70:	84aa                	mv	s1,a0
    80004e72:	00a05763          	blez	a0,80004e80 <filewrite+0xc4>
        f->off += r;
    80004e76:	02092783          	lw	a5,32(s2)
    80004e7a:	9fa9                	addw	a5,a5,a0
    80004e7c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e80:	01893503          	ld	a0,24(s2)
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	f70080e7          	jalr	-144(ra) # 80003df4 <iunlock>
      end_op();
    80004e8c:	00000097          	auipc	ra,0x0
    80004e90:	8e8080e7          	jalr	-1816(ra) # 80004774 <end_op>

      if(r != n1){
    80004e94:	009c1f63          	bne	s8,s1,80004eb2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e98:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e9c:	0149db63          	bge	s3,s4,80004eb2 <filewrite+0xf6>
      int n1 = n - i;
    80004ea0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ea4:	84be                	mv	s1,a5
    80004ea6:	2781                	sext.w	a5,a5
    80004ea8:	f8fb5ce3          	bge	s6,a5,80004e40 <filewrite+0x84>
    80004eac:	84de                	mv	s1,s7
    80004eae:	bf49                	j	80004e40 <filewrite+0x84>
    int i = 0;
    80004eb0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004eb2:	013a1f63          	bne	s4,s3,80004ed0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004eb6:	8552                	mv	a0,s4
    80004eb8:	60a6                	ld	ra,72(sp)
    80004eba:	6406                	ld	s0,64(sp)
    80004ebc:	74e2                	ld	s1,56(sp)
    80004ebe:	7942                	ld	s2,48(sp)
    80004ec0:	79a2                	ld	s3,40(sp)
    80004ec2:	7a02                	ld	s4,32(sp)
    80004ec4:	6ae2                	ld	s5,24(sp)
    80004ec6:	6b42                	ld	s6,16(sp)
    80004ec8:	6ba2                	ld	s7,8(sp)
    80004eca:	6c02                	ld	s8,0(sp)
    80004ecc:	6161                	addi	sp,sp,80
    80004ece:	8082                	ret
    ret = (i == n ? n : -1);
    80004ed0:	5a7d                	li	s4,-1
    80004ed2:	b7d5                	j	80004eb6 <filewrite+0xfa>
    panic("filewrite");
    80004ed4:	00004517          	auipc	a0,0x4
    80004ed8:	80450513          	addi	a0,a0,-2044 # 800086d8 <syscalls+0x288>
    80004edc:	ffffb097          	auipc	ra,0xffffb
    80004ee0:	668080e7          	jalr	1640(ra) # 80000544 <panic>
    return -1;
    80004ee4:	5a7d                	li	s4,-1
    80004ee6:	bfc1                	j	80004eb6 <filewrite+0xfa>
      return -1;
    80004ee8:	5a7d                	li	s4,-1
    80004eea:	b7f1                	j	80004eb6 <filewrite+0xfa>
    80004eec:	5a7d                	li	s4,-1
    80004eee:	b7e1                	j	80004eb6 <filewrite+0xfa>

0000000080004ef0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ef0:	7179                	addi	sp,sp,-48
    80004ef2:	f406                	sd	ra,40(sp)
    80004ef4:	f022                	sd	s0,32(sp)
    80004ef6:	ec26                	sd	s1,24(sp)
    80004ef8:	e84a                	sd	s2,16(sp)
    80004efa:	e44e                	sd	s3,8(sp)
    80004efc:	e052                	sd	s4,0(sp)
    80004efe:	1800                	addi	s0,sp,48
    80004f00:	84aa                	mv	s1,a0
    80004f02:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f04:	0005b023          	sd	zero,0(a1)
    80004f08:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f0c:	00000097          	auipc	ra,0x0
    80004f10:	bf8080e7          	jalr	-1032(ra) # 80004b04 <filealloc>
    80004f14:	e088                	sd	a0,0(s1)
    80004f16:	c551                	beqz	a0,80004fa2 <pipealloc+0xb2>
    80004f18:	00000097          	auipc	ra,0x0
    80004f1c:	bec080e7          	jalr	-1044(ra) # 80004b04 <filealloc>
    80004f20:	00aa3023          	sd	a0,0(s4)
    80004f24:	c92d                	beqz	a0,80004f96 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	bd4080e7          	jalr	-1068(ra) # 80000afa <kalloc>
    80004f2e:	892a                	mv	s2,a0
    80004f30:	c125                	beqz	a0,80004f90 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f32:	4985                	li	s3,1
    80004f34:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f38:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f3c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f40:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f44:	00003597          	auipc	a1,0x3
    80004f48:	7a458593          	addi	a1,a1,1956 # 800086e8 <syscalls+0x298>
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	c0e080e7          	jalr	-1010(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004f54:	609c                	ld	a5,0(s1)
    80004f56:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f5a:	609c                	ld	a5,0(s1)
    80004f5c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f60:	609c                	ld	a5,0(s1)
    80004f62:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f66:	609c                	ld	a5,0(s1)
    80004f68:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f6c:	000a3783          	ld	a5,0(s4)
    80004f70:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f74:	000a3783          	ld	a5,0(s4)
    80004f78:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f7c:	000a3783          	ld	a5,0(s4)
    80004f80:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f84:	000a3783          	ld	a5,0(s4)
    80004f88:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f8c:	4501                	li	a0,0
    80004f8e:	a025                	j	80004fb6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f90:	6088                	ld	a0,0(s1)
    80004f92:	e501                	bnez	a0,80004f9a <pipealloc+0xaa>
    80004f94:	a039                	j	80004fa2 <pipealloc+0xb2>
    80004f96:	6088                	ld	a0,0(s1)
    80004f98:	c51d                	beqz	a0,80004fc6 <pipealloc+0xd6>
    fileclose(*f0);
    80004f9a:	00000097          	auipc	ra,0x0
    80004f9e:	c26080e7          	jalr	-986(ra) # 80004bc0 <fileclose>
  if(*f1)
    80004fa2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fa6:	557d                	li	a0,-1
  if(*f1)
    80004fa8:	c799                	beqz	a5,80004fb6 <pipealloc+0xc6>
    fileclose(*f1);
    80004faa:	853e                	mv	a0,a5
    80004fac:	00000097          	auipc	ra,0x0
    80004fb0:	c14080e7          	jalr	-1004(ra) # 80004bc0 <fileclose>
  return -1;
    80004fb4:	557d                	li	a0,-1
}
    80004fb6:	70a2                	ld	ra,40(sp)
    80004fb8:	7402                	ld	s0,32(sp)
    80004fba:	64e2                	ld	s1,24(sp)
    80004fbc:	6942                	ld	s2,16(sp)
    80004fbe:	69a2                	ld	s3,8(sp)
    80004fc0:	6a02                	ld	s4,0(sp)
    80004fc2:	6145                	addi	sp,sp,48
    80004fc4:	8082                	ret
  return -1;
    80004fc6:	557d                	li	a0,-1
    80004fc8:	b7fd                	j	80004fb6 <pipealloc+0xc6>

0000000080004fca <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fca:	1101                	addi	sp,sp,-32
    80004fcc:	ec06                	sd	ra,24(sp)
    80004fce:	e822                	sd	s0,16(sp)
    80004fd0:	e426                	sd	s1,8(sp)
    80004fd2:	e04a                	sd	s2,0(sp)
    80004fd4:	1000                	addi	s0,sp,32
    80004fd6:	84aa                	mv	s1,a0
    80004fd8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	c10080e7          	jalr	-1008(ra) # 80000bea <acquire>
  if(writable){
    80004fe2:	02090d63          	beqz	s2,8000501c <pipeclose+0x52>
    pi->writeopen = 0;
    80004fe6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fea:	21848513          	addi	a0,s1,536
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	190080e7          	jalr	400(ra) # 8000217e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ff6:	2204b783          	ld	a5,544(s1)
    80004ffa:	eb95                	bnez	a5,8000502e <pipeclose+0x64>
    release(&pi->lock);
    80004ffc:	8526                	mv	a0,s1
    80004ffe:	ffffc097          	auipc	ra,0xffffc
    80005002:	ca0080e7          	jalr	-864(ra) # 80000c9e <release>
    kfree((char*)pi);
    80005006:	8526                	mv	a0,s1
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	9f6080e7          	jalr	-1546(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80005010:	60e2                	ld	ra,24(sp)
    80005012:	6442                	ld	s0,16(sp)
    80005014:	64a2                	ld	s1,8(sp)
    80005016:	6902                	ld	s2,0(sp)
    80005018:	6105                	addi	sp,sp,32
    8000501a:	8082                	ret
    pi->readopen = 0;
    8000501c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005020:	21c48513          	addi	a0,s1,540
    80005024:	ffffd097          	auipc	ra,0xffffd
    80005028:	15a080e7          	jalr	346(ra) # 8000217e <wakeup>
    8000502c:	b7e9                	j	80004ff6 <pipeclose+0x2c>
    release(&pi->lock);
    8000502e:	8526                	mv	a0,s1
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	c6e080e7          	jalr	-914(ra) # 80000c9e <release>
}
    80005038:	bfe1                	j	80005010 <pipeclose+0x46>

000000008000503a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000503a:	7159                	addi	sp,sp,-112
    8000503c:	f486                	sd	ra,104(sp)
    8000503e:	f0a2                	sd	s0,96(sp)
    80005040:	eca6                	sd	s1,88(sp)
    80005042:	e8ca                	sd	s2,80(sp)
    80005044:	e4ce                	sd	s3,72(sp)
    80005046:	e0d2                	sd	s4,64(sp)
    80005048:	fc56                	sd	s5,56(sp)
    8000504a:	f85a                	sd	s6,48(sp)
    8000504c:	f45e                	sd	s7,40(sp)
    8000504e:	f062                	sd	s8,32(sp)
    80005050:	ec66                	sd	s9,24(sp)
    80005052:	1880                	addi	s0,sp,112
    80005054:	84aa                	mv	s1,a0
    80005056:	8aae                	mv	s5,a1
    80005058:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000505a:	ffffd097          	auipc	ra,0xffffd
    8000505e:	96c080e7          	jalr	-1684(ra) # 800019c6 <myproc>
    80005062:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005064:	8526                	mv	a0,s1
    80005066:	ffffc097          	auipc	ra,0xffffc
    8000506a:	b84080e7          	jalr	-1148(ra) # 80000bea <acquire>
  while(i < n){
    8000506e:	0d405463          	blez	s4,80005136 <pipewrite+0xfc>
    80005072:	8ba6                	mv	s7,s1
  int i = 0;
    80005074:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005076:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005078:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000507c:	21c48c13          	addi	s8,s1,540
    80005080:	a08d                	j	800050e2 <pipewrite+0xa8>
      release(&pi->lock);
    80005082:	8526                	mv	a0,s1
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	c1a080e7          	jalr	-998(ra) # 80000c9e <release>
      return -1;
    8000508c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000508e:	854a                	mv	a0,s2
    80005090:	70a6                	ld	ra,104(sp)
    80005092:	7406                	ld	s0,96(sp)
    80005094:	64e6                	ld	s1,88(sp)
    80005096:	6946                	ld	s2,80(sp)
    80005098:	69a6                	ld	s3,72(sp)
    8000509a:	6a06                	ld	s4,64(sp)
    8000509c:	7ae2                	ld	s5,56(sp)
    8000509e:	7b42                	ld	s6,48(sp)
    800050a0:	7ba2                	ld	s7,40(sp)
    800050a2:	7c02                	ld	s8,32(sp)
    800050a4:	6ce2                	ld	s9,24(sp)
    800050a6:	6165                	addi	sp,sp,112
    800050a8:	8082                	ret
      wakeup(&pi->nread);
    800050aa:	8566                	mv	a0,s9
    800050ac:	ffffd097          	auipc	ra,0xffffd
    800050b0:	0d2080e7          	jalr	210(ra) # 8000217e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050b4:	85de                	mv	a1,s7
    800050b6:	8562                	mv	a0,s8
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	062080e7          	jalr	98(ra) # 8000211a <sleep>
    800050c0:	a839                	j	800050de <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050c2:	21c4a783          	lw	a5,540(s1)
    800050c6:	0017871b          	addiw	a4,a5,1
    800050ca:	20e4ae23          	sw	a4,540(s1)
    800050ce:	1ff7f793          	andi	a5,a5,511
    800050d2:	97a6                	add	a5,a5,s1
    800050d4:	f9f44703          	lbu	a4,-97(s0)
    800050d8:	00e78c23          	sb	a4,24(a5)
      i++;
    800050dc:	2905                	addiw	s2,s2,1
  while(i < n){
    800050de:	05495063          	bge	s2,s4,8000511e <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    800050e2:	2204a783          	lw	a5,544(s1)
    800050e6:	dfd1                	beqz	a5,80005082 <pipewrite+0x48>
    800050e8:	854e                	mv	a0,s3
    800050ea:	ffffd097          	auipc	ra,0xffffd
    800050ee:	314080e7          	jalr	788(ra) # 800023fe <killed>
    800050f2:	f941                	bnez	a0,80005082 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050f4:	2184a783          	lw	a5,536(s1)
    800050f8:	21c4a703          	lw	a4,540(s1)
    800050fc:	2007879b          	addiw	a5,a5,512
    80005100:	faf705e3          	beq	a4,a5,800050aa <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005104:	4685                	li	a3,1
    80005106:	01590633          	add	a2,s2,s5
    8000510a:	f9f40593          	addi	a1,s0,-97
    8000510e:	0509b503          	ld	a0,80(s3)
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	5fe080e7          	jalr	1534(ra) # 80001710 <copyin>
    8000511a:	fb6514e3          	bne	a0,s6,800050c2 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000511e:	21848513          	addi	a0,s1,536
    80005122:	ffffd097          	auipc	ra,0xffffd
    80005126:	05c080e7          	jalr	92(ra) # 8000217e <wakeup>
  release(&pi->lock);
    8000512a:	8526                	mv	a0,s1
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	b72080e7          	jalr	-1166(ra) # 80000c9e <release>
  return i;
    80005134:	bfa9                	j	8000508e <pipewrite+0x54>
  int i = 0;
    80005136:	4901                	li	s2,0
    80005138:	b7dd                	j	8000511e <pipewrite+0xe4>

000000008000513a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000513a:	715d                	addi	sp,sp,-80
    8000513c:	e486                	sd	ra,72(sp)
    8000513e:	e0a2                	sd	s0,64(sp)
    80005140:	fc26                	sd	s1,56(sp)
    80005142:	f84a                	sd	s2,48(sp)
    80005144:	f44e                	sd	s3,40(sp)
    80005146:	f052                	sd	s4,32(sp)
    80005148:	ec56                	sd	s5,24(sp)
    8000514a:	e85a                	sd	s6,16(sp)
    8000514c:	0880                	addi	s0,sp,80
    8000514e:	84aa                	mv	s1,a0
    80005150:	892e                	mv	s2,a1
    80005152:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005154:	ffffd097          	auipc	ra,0xffffd
    80005158:	872080e7          	jalr	-1934(ra) # 800019c6 <myproc>
    8000515c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000515e:	8b26                	mv	s6,s1
    80005160:	8526                	mv	a0,s1
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	a88080e7          	jalr	-1400(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000516a:	2184a703          	lw	a4,536(s1)
    8000516e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005172:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005176:	02f71763          	bne	a4,a5,800051a4 <piperead+0x6a>
    8000517a:	2244a783          	lw	a5,548(s1)
    8000517e:	c39d                	beqz	a5,800051a4 <piperead+0x6a>
    if(killed(pr)){
    80005180:	8552                	mv	a0,s4
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	27c080e7          	jalr	636(ra) # 800023fe <killed>
    8000518a:	e941                	bnez	a0,8000521a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000518c:	85da                	mv	a1,s6
    8000518e:	854e                	mv	a0,s3
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	f8a080e7          	jalr	-118(ra) # 8000211a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005198:	2184a703          	lw	a4,536(s1)
    8000519c:	21c4a783          	lw	a5,540(s1)
    800051a0:	fcf70de3          	beq	a4,a5,8000517a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051a4:	09505263          	blez	s5,80005228 <piperead+0xee>
    800051a8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051aa:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800051ac:	2184a783          	lw	a5,536(s1)
    800051b0:	21c4a703          	lw	a4,540(s1)
    800051b4:	02f70d63          	beq	a4,a5,800051ee <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051b8:	0017871b          	addiw	a4,a5,1
    800051bc:	20e4ac23          	sw	a4,536(s1)
    800051c0:	1ff7f793          	andi	a5,a5,511
    800051c4:	97a6                	add	a5,a5,s1
    800051c6:	0187c783          	lbu	a5,24(a5)
    800051ca:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051ce:	4685                	li	a3,1
    800051d0:	fbf40613          	addi	a2,s0,-65
    800051d4:	85ca                	mv	a1,s2
    800051d6:	050a3503          	ld	a0,80(s4)
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	4aa080e7          	jalr	1194(ra) # 80001684 <copyout>
    800051e2:	01650663          	beq	a0,s6,800051ee <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051e6:	2985                	addiw	s3,s3,1
    800051e8:	0905                	addi	s2,s2,1
    800051ea:	fd3a91e3          	bne	s5,s3,800051ac <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051ee:	21c48513          	addi	a0,s1,540
    800051f2:	ffffd097          	auipc	ra,0xffffd
    800051f6:	f8c080e7          	jalr	-116(ra) # 8000217e <wakeup>
  release(&pi->lock);
    800051fa:	8526                	mv	a0,s1
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	aa2080e7          	jalr	-1374(ra) # 80000c9e <release>
  return i;
}
    80005204:	854e                	mv	a0,s3
    80005206:	60a6                	ld	ra,72(sp)
    80005208:	6406                	ld	s0,64(sp)
    8000520a:	74e2                	ld	s1,56(sp)
    8000520c:	7942                	ld	s2,48(sp)
    8000520e:	79a2                	ld	s3,40(sp)
    80005210:	7a02                	ld	s4,32(sp)
    80005212:	6ae2                	ld	s5,24(sp)
    80005214:	6b42                	ld	s6,16(sp)
    80005216:	6161                	addi	sp,sp,80
    80005218:	8082                	ret
      release(&pi->lock);
    8000521a:	8526                	mv	a0,s1
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	a82080e7          	jalr	-1406(ra) # 80000c9e <release>
      return -1;
    80005224:	59fd                	li	s3,-1
    80005226:	bff9                	j	80005204 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005228:	4981                	li	s3,0
    8000522a:	b7d1                	j	800051ee <piperead+0xb4>

000000008000522c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000522c:	1141                	addi	sp,sp,-16
    8000522e:	e422                	sd	s0,8(sp)
    80005230:	0800                	addi	s0,sp,16
    80005232:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005234:	8905                	andi	a0,a0,1
    80005236:	c111                	beqz	a0,8000523a <flags2perm+0xe>
      perm = PTE_X;
    80005238:	4521                	li	a0,8
    if(flags & 0x2)
    8000523a:	8b89                	andi	a5,a5,2
    8000523c:	c399                	beqz	a5,80005242 <flags2perm+0x16>
      perm |= PTE_W;
    8000523e:	00456513          	ori	a0,a0,4
    return perm;
}
    80005242:	6422                	ld	s0,8(sp)
    80005244:	0141                	addi	sp,sp,16
    80005246:	8082                	ret

0000000080005248 <exec>:

int
exec(char *path, char **argv)
{
    80005248:	df010113          	addi	sp,sp,-528
    8000524c:	20113423          	sd	ra,520(sp)
    80005250:	20813023          	sd	s0,512(sp)
    80005254:	ffa6                	sd	s1,504(sp)
    80005256:	fbca                	sd	s2,496(sp)
    80005258:	f7ce                	sd	s3,488(sp)
    8000525a:	f3d2                	sd	s4,480(sp)
    8000525c:	efd6                	sd	s5,472(sp)
    8000525e:	ebda                	sd	s6,464(sp)
    80005260:	e7de                	sd	s7,456(sp)
    80005262:	e3e2                	sd	s8,448(sp)
    80005264:	ff66                	sd	s9,440(sp)
    80005266:	fb6a                	sd	s10,432(sp)
    80005268:	f76e                	sd	s11,424(sp)
    8000526a:	0c00                	addi	s0,sp,528
    8000526c:	84aa                	mv	s1,a0
    8000526e:	dea43c23          	sd	a0,-520(s0)
    80005272:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	750080e7          	jalr	1872(ra) # 800019c6 <myproc>
    8000527e:	892a                	mv	s2,a0

  begin_op();
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	474080e7          	jalr	1140(ra) # 800046f4 <begin_op>

  if((ip = namei(path)) == 0){
    80005288:	8526                	mv	a0,s1
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	24e080e7          	jalr	590(ra) # 800044d8 <namei>
    80005292:	c92d                	beqz	a0,80005304 <exec+0xbc>
    80005294:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	a9c080e7          	jalr	-1380(ra) # 80003d32 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000529e:	04000713          	li	a4,64
    800052a2:	4681                	li	a3,0
    800052a4:	e5040613          	addi	a2,s0,-432
    800052a8:	4581                	li	a1,0
    800052aa:	8526                	mv	a0,s1
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	d3a080e7          	jalr	-710(ra) # 80003fe6 <readi>
    800052b4:	04000793          	li	a5,64
    800052b8:	00f51a63          	bne	a0,a5,800052cc <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800052bc:	e5042703          	lw	a4,-432(s0)
    800052c0:	464c47b7          	lui	a5,0x464c4
    800052c4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052c8:	04f70463          	beq	a4,a5,80005310 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052cc:	8526                	mv	a0,s1
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	cc6080e7          	jalr	-826(ra) # 80003f94 <iunlockput>
    end_op();
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	49e080e7          	jalr	1182(ra) # 80004774 <end_op>
  }
  return -1;
    800052de:	557d                	li	a0,-1
}
    800052e0:	20813083          	ld	ra,520(sp)
    800052e4:	20013403          	ld	s0,512(sp)
    800052e8:	74fe                	ld	s1,504(sp)
    800052ea:	795e                	ld	s2,496(sp)
    800052ec:	79be                	ld	s3,488(sp)
    800052ee:	7a1e                	ld	s4,480(sp)
    800052f0:	6afe                	ld	s5,472(sp)
    800052f2:	6b5e                	ld	s6,464(sp)
    800052f4:	6bbe                	ld	s7,456(sp)
    800052f6:	6c1e                	ld	s8,448(sp)
    800052f8:	7cfa                	ld	s9,440(sp)
    800052fa:	7d5a                	ld	s10,432(sp)
    800052fc:	7dba                	ld	s11,424(sp)
    800052fe:	21010113          	addi	sp,sp,528
    80005302:	8082                	ret
    end_op();
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	470080e7          	jalr	1136(ra) # 80004774 <end_op>
    return -1;
    8000530c:	557d                	li	a0,-1
    8000530e:	bfc9                	j	800052e0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005310:	854a                	mv	a0,s2
    80005312:	ffffc097          	auipc	ra,0xffffc
    80005316:	778080e7          	jalr	1912(ra) # 80001a8a <proc_pagetable>
    8000531a:	8baa                	mv	s7,a0
    8000531c:	d945                	beqz	a0,800052cc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000531e:	e7042983          	lw	s3,-400(s0)
    80005322:	e8845783          	lhu	a5,-376(s0)
    80005326:	c7ad                	beqz	a5,80005390 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005328:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000532a:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    8000532c:	6c85                	lui	s9,0x1
    8000532e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005332:	def43823          	sd	a5,-528(s0)
    80005336:	ac0d                	j	80005568 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005338:	00003517          	auipc	a0,0x3
    8000533c:	3b850513          	addi	a0,a0,952 # 800086f0 <syscalls+0x2a0>
    80005340:	ffffb097          	auipc	ra,0xffffb
    80005344:	204080e7          	jalr	516(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005348:	8756                	mv	a4,s5
    8000534a:	012d86bb          	addw	a3,s11,s2
    8000534e:	4581                	li	a1,0
    80005350:	8526                	mv	a0,s1
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	c94080e7          	jalr	-876(ra) # 80003fe6 <readi>
    8000535a:	2501                	sext.w	a0,a0
    8000535c:	1aaa9a63          	bne	s5,a0,80005510 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005360:	6785                	lui	a5,0x1
    80005362:	0127893b          	addw	s2,a5,s2
    80005366:	77fd                	lui	a5,0xfffff
    80005368:	01478a3b          	addw	s4,a5,s4
    8000536c:	1f897563          	bgeu	s2,s8,80005556 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80005370:	02091593          	slli	a1,s2,0x20
    80005374:	9181                	srli	a1,a1,0x20
    80005376:	95ea                	add	a1,a1,s10
    80005378:	855e                	mv	a0,s7
    8000537a:	ffffc097          	auipc	ra,0xffffc
    8000537e:	cfe080e7          	jalr	-770(ra) # 80001078 <walkaddr>
    80005382:	862a                	mv	a2,a0
    if(pa == 0)
    80005384:	d955                	beqz	a0,80005338 <exec+0xf0>
      n = PGSIZE;
    80005386:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005388:	fd9a70e3          	bgeu	s4,s9,80005348 <exec+0x100>
      n = sz - i;
    8000538c:	8ad2                	mv	s5,s4
    8000538e:	bf6d                	j	80005348 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005390:	4a01                	li	s4,0
  iunlockput(ip);
    80005392:	8526                	mv	a0,s1
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	c00080e7          	jalr	-1024(ra) # 80003f94 <iunlockput>
  end_op();
    8000539c:	fffff097          	auipc	ra,0xfffff
    800053a0:	3d8080e7          	jalr	984(ra) # 80004774 <end_op>
  p = myproc();
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	622080e7          	jalr	1570(ra) # 800019c6 <myproc>
    800053ac:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800053ae:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800053b2:	6785                	lui	a5,0x1
    800053b4:	17fd                	addi	a5,a5,-1
    800053b6:	9a3e                	add	s4,s4,a5
    800053b8:	757d                	lui	a0,0xfffff
    800053ba:	00aa77b3          	and	a5,s4,a0
    800053be:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053c2:	4691                	li	a3,4
    800053c4:	6609                	lui	a2,0x2
    800053c6:	963e                	add	a2,a2,a5
    800053c8:	85be                	mv	a1,a5
    800053ca:	855e                	mv	a0,s7
    800053cc:	ffffc097          	auipc	ra,0xffffc
    800053d0:	060080e7          	jalr	96(ra) # 8000142c <uvmalloc>
    800053d4:	8b2a                	mv	s6,a0
  ip = 0;
    800053d6:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053d8:	12050c63          	beqz	a0,80005510 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053dc:	75f9                	lui	a1,0xffffe
    800053de:	95aa                	add	a1,a1,a0
    800053e0:	855e                	mv	a0,s7
    800053e2:	ffffc097          	auipc	ra,0xffffc
    800053e6:	270080e7          	jalr	624(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    800053ea:	7c7d                	lui	s8,0xfffff
    800053ec:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053ee:	e0043783          	ld	a5,-512(s0)
    800053f2:	6388                	ld	a0,0(a5)
    800053f4:	c535                	beqz	a0,80005460 <exec+0x218>
    800053f6:	e9040993          	addi	s3,s0,-368
    800053fa:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053fe:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	a6a080e7          	jalr	-1430(ra) # 80000e6a <strlen>
    80005408:	2505                	addiw	a0,a0,1
    8000540a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000540e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005412:	13896663          	bltu	s2,s8,8000553e <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005416:	e0043d83          	ld	s11,-512(s0)
    8000541a:	000dba03          	ld	s4,0(s11)
    8000541e:	8552                	mv	a0,s4
    80005420:	ffffc097          	auipc	ra,0xffffc
    80005424:	a4a080e7          	jalr	-1462(ra) # 80000e6a <strlen>
    80005428:	0015069b          	addiw	a3,a0,1
    8000542c:	8652                	mv	a2,s4
    8000542e:	85ca                	mv	a1,s2
    80005430:	855e                	mv	a0,s7
    80005432:	ffffc097          	auipc	ra,0xffffc
    80005436:	252080e7          	jalr	594(ra) # 80001684 <copyout>
    8000543a:	10054663          	bltz	a0,80005546 <exec+0x2fe>
    ustack[argc] = sp;
    8000543e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005442:	0485                	addi	s1,s1,1
    80005444:	008d8793          	addi	a5,s11,8
    80005448:	e0f43023          	sd	a5,-512(s0)
    8000544c:	008db503          	ld	a0,8(s11)
    80005450:	c911                	beqz	a0,80005464 <exec+0x21c>
    if(argc >= MAXARG)
    80005452:	09a1                	addi	s3,s3,8
    80005454:	fb3c96e3          	bne	s9,s3,80005400 <exec+0x1b8>
  sz = sz1;
    80005458:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000545c:	4481                	li	s1,0
    8000545e:	a84d                	j	80005510 <exec+0x2c8>
  sp = sz;
    80005460:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005462:	4481                	li	s1,0
  ustack[argc] = 0;
    80005464:	00349793          	slli	a5,s1,0x3
    80005468:	f9040713          	addi	a4,s0,-112
    8000546c:	97ba                	add	a5,a5,a4
    8000546e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005472:	00148693          	addi	a3,s1,1
    80005476:	068e                	slli	a3,a3,0x3
    80005478:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000547c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005480:	01897663          	bgeu	s2,s8,8000548c <exec+0x244>
  sz = sz1;
    80005484:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005488:	4481                	li	s1,0
    8000548a:	a059                	j	80005510 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000548c:	e9040613          	addi	a2,s0,-368
    80005490:	85ca                	mv	a1,s2
    80005492:	855e                	mv	a0,s7
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	1f0080e7          	jalr	496(ra) # 80001684 <copyout>
    8000549c:	0a054963          	bltz	a0,8000554e <exec+0x306>
  p->trapframe->a1 = sp;
    800054a0:	058ab783          	ld	a5,88(s5)
    800054a4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800054a8:	df843783          	ld	a5,-520(s0)
    800054ac:	0007c703          	lbu	a4,0(a5)
    800054b0:	cf11                	beqz	a4,800054cc <exec+0x284>
    800054b2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800054b4:	02f00693          	li	a3,47
    800054b8:	a039                	j	800054c6 <exec+0x27e>
      last = s+1;
    800054ba:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800054be:	0785                	addi	a5,a5,1
    800054c0:	fff7c703          	lbu	a4,-1(a5)
    800054c4:	c701                	beqz	a4,800054cc <exec+0x284>
    if(*s == '/')
    800054c6:	fed71ce3          	bne	a4,a3,800054be <exec+0x276>
    800054ca:	bfc5                	j	800054ba <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    800054cc:	4641                	li	a2,16
    800054ce:	df843583          	ld	a1,-520(s0)
    800054d2:	158a8513          	addi	a0,s5,344
    800054d6:	ffffc097          	auipc	ra,0xffffc
    800054da:	962080e7          	jalr	-1694(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    800054de:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054e2:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800054e6:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054ea:	058ab783          	ld	a5,88(s5)
    800054ee:	e6843703          	ld	a4,-408(s0)
    800054f2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054f4:	058ab783          	ld	a5,88(s5)
    800054f8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054fc:	85ea                	mv	a1,s10
    800054fe:	ffffc097          	auipc	ra,0xffffc
    80005502:	628080e7          	jalr	1576(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005506:	0004851b          	sext.w	a0,s1
    8000550a:	bbd9                	j	800052e0 <exec+0x98>
    8000550c:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005510:	e0843583          	ld	a1,-504(s0)
    80005514:	855e                	mv	a0,s7
    80005516:	ffffc097          	auipc	ra,0xffffc
    8000551a:	610080e7          	jalr	1552(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    8000551e:	da0497e3          	bnez	s1,800052cc <exec+0x84>
  return -1;
    80005522:	557d                	li	a0,-1
    80005524:	bb75                	j	800052e0 <exec+0x98>
    80005526:	e1443423          	sd	s4,-504(s0)
    8000552a:	b7dd                	j	80005510 <exec+0x2c8>
    8000552c:	e1443423          	sd	s4,-504(s0)
    80005530:	b7c5                	j	80005510 <exec+0x2c8>
    80005532:	e1443423          	sd	s4,-504(s0)
    80005536:	bfe9                	j	80005510 <exec+0x2c8>
    80005538:	e1443423          	sd	s4,-504(s0)
    8000553c:	bfd1                	j	80005510 <exec+0x2c8>
  sz = sz1;
    8000553e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005542:	4481                	li	s1,0
    80005544:	b7f1                	j	80005510 <exec+0x2c8>
  sz = sz1;
    80005546:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000554a:	4481                	li	s1,0
    8000554c:	b7d1                	j	80005510 <exec+0x2c8>
  sz = sz1;
    8000554e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005552:	4481                	li	s1,0
    80005554:	bf75                	j	80005510 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005556:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000555a:	2b05                	addiw	s6,s6,1
    8000555c:	0389899b          	addiw	s3,s3,56
    80005560:	e8845783          	lhu	a5,-376(s0)
    80005564:	e2fb57e3          	bge	s6,a5,80005392 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005568:	2981                	sext.w	s3,s3
    8000556a:	03800713          	li	a4,56
    8000556e:	86ce                	mv	a3,s3
    80005570:	e1840613          	addi	a2,s0,-488
    80005574:	4581                	li	a1,0
    80005576:	8526                	mv	a0,s1
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	a6e080e7          	jalr	-1426(ra) # 80003fe6 <readi>
    80005580:	03800793          	li	a5,56
    80005584:	f8f514e3          	bne	a0,a5,8000550c <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005588:	e1842783          	lw	a5,-488(s0)
    8000558c:	4705                	li	a4,1
    8000558e:	fce796e3          	bne	a5,a4,8000555a <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005592:	e4043903          	ld	s2,-448(s0)
    80005596:	e3843783          	ld	a5,-456(s0)
    8000559a:	f8f966e3          	bltu	s2,a5,80005526 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000559e:	e2843783          	ld	a5,-472(s0)
    800055a2:	993e                	add	s2,s2,a5
    800055a4:	f8f964e3          	bltu	s2,a5,8000552c <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800055a8:	df043703          	ld	a4,-528(s0)
    800055ac:	8ff9                	and	a5,a5,a4
    800055ae:	f3d1                	bnez	a5,80005532 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055b0:	e1c42503          	lw	a0,-484(s0)
    800055b4:	00000097          	auipc	ra,0x0
    800055b8:	c78080e7          	jalr	-904(ra) # 8000522c <flags2perm>
    800055bc:	86aa                	mv	a3,a0
    800055be:	864a                	mv	a2,s2
    800055c0:	85d2                	mv	a1,s4
    800055c2:	855e                	mv	a0,s7
    800055c4:	ffffc097          	auipc	ra,0xffffc
    800055c8:	e68080e7          	jalr	-408(ra) # 8000142c <uvmalloc>
    800055cc:	e0a43423          	sd	a0,-504(s0)
    800055d0:	d525                	beqz	a0,80005538 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055d2:	e2843d03          	ld	s10,-472(s0)
    800055d6:	e2042d83          	lw	s11,-480(s0)
    800055da:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055de:	f60c0ce3          	beqz	s8,80005556 <exec+0x30e>
    800055e2:	8a62                	mv	s4,s8
    800055e4:	4901                	li	s2,0
    800055e6:	b369                	j	80005370 <exec+0x128>

00000000800055e8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055e8:	7179                	addi	sp,sp,-48
    800055ea:	f406                	sd	ra,40(sp)
    800055ec:	f022                	sd	s0,32(sp)
    800055ee:	ec26                	sd	s1,24(sp)
    800055f0:	e84a                	sd	s2,16(sp)
    800055f2:	1800                	addi	s0,sp,48
    800055f4:	892e                	mv	s2,a1
    800055f6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800055f8:	fdc40593          	addi	a1,s0,-36
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	a0c080e7          	jalr	-1524(ra) # 80003008 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005604:	fdc42703          	lw	a4,-36(s0)
    80005608:	47bd                	li	a5,15
    8000560a:	02e7eb63          	bltu	a5,a4,80005640 <argfd+0x58>
    8000560e:	ffffc097          	auipc	ra,0xffffc
    80005612:	3b8080e7          	jalr	952(ra) # 800019c6 <myproc>
    80005616:	fdc42703          	lw	a4,-36(s0)
    8000561a:	01a70793          	addi	a5,a4,26
    8000561e:	078e                	slli	a5,a5,0x3
    80005620:	953e                	add	a0,a0,a5
    80005622:	611c                	ld	a5,0(a0)
    80005624:	c385                	beqz	a5,80005644 <argfd+0x5c>
    return -1;
  if(pfd)
    80005626:	00090463          	beqz	s2,8000562e <argfd+0x46>
    *pfd = fd;
    8000562a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000562e:	4501                	li	a0,0
  if(pf)
    80005630:	c091                	beqz	s1,80005634 <argfd+0x4c>
    *pf = f;
    80005632:	e09c                	sd	a5,0(s1)
}
    80005634:	70a2                	ld	ra,40(sp)
    80005636:	7402                	ld	s0,32(sp)
    80005638:	64e2                	ld	s1,24(sp)
    8000563a:	6942                	ld	s2,16(sp)
    8000563c:	6145                	addi	sp,sp,48
    8000563e:	8082                	ret
    return -1;
    80005640:	557d                	li	a0,-1
    80005642:	bfcd                	j	80005634 <argfd+0x4c>
    80005644:	557d                	li	a0,-1
    80005646:	b7fd                	j	80005634 <argfd+0x4c>

0000000080005648 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005648:	1101                	addi	sp,sp,-32
    8000564a:	ec06                	sd	ra,24(sp)
    8000564c:	e822                	sd	s0,16(sp)
    8000564e:	e426                	sd	s1,8(sp)
    80005650:	1000                	addi	s0,sp,32
    80005652:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005654:	ffffc097          	auipc	ra,0xffffc
    80005658:	372080e7          	jalr	882(ra) # 800019c6 <myproc>
    8000565c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000565e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdc570>
    80005662:	4501                	li	a0,0
    80005664:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005666:	6398                	ld	a4,0(a5)
    80005668:	cb19                	beqz	a4,8000567e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000566a:	2505                	addiw	a0,a0,1
    8000566c:	07a1                	addi	a5,a5,8
    8000566e:	fed51ce3          	bne	a0,a3,80005666 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005672:	557d                	li	a0,-1
}
    80005674:	60e2                	ld	ra,24(sp)
    80005676:	6442                	ld	s0,16(sp)
    80005678:	64a2                	ld	s1,8(sp)
    8000567a:	6105                	addi	sp,sp,32
    8000567c:	8082                	ret
      p->ofile[fd] = f;
    8000567e:	01a50793          	addi	a5,a0,26
    80005682:	078e                	slli	a5,a5,0x3
    80005684:	963e                	add	a2,a2,a5
    80005686:	e204                	sd	s1,0(a2)
      return fd;
    80005688:	b7f5                	j	80005674 <fdalloc+0x2c>

000000008000568a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000568a:	715d                	addi	sp,sp,-80
    8000568c:	e486                	sd	ra,72(sp)
    8000568e:	e0a2                	sd	s0,64(sp)
    80005690:	fc26                	sd	s1,56(sp)
    80005692:	f84a                	sd	s2,48(sp)
    80005694:	f44e                	sd	s3,40(sp)
    80005696:	f052                	sd	s4,32(sp)
    80005698:	ec56                	sd	s5,24(sp)
    8000569a:	e85a                	sd	s6,16(sp)
    8000569c:	0880                	addi	s0,sp,80
    8000569e:	8b2e                	mv	s6,a1
    800056a0:	89b2                	mv	s3,a2
    800056a2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056a4:	fb040593          	addi	a1,s0,-80
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	e4e080e7          	jalr	-434(ra) # 800044f6 <nameiparent>
    800056b0:	84aa                	mv	s1,a0
    800056b2:	16050063          	beqz	a0,80005812 <create+0x188>
    return 0;

  ilock(dp);
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	67c080e7          	jalr	1660(ra) # 80003d32 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056be:	4601                	li	a2,0
    800056c0:	fb040593          	addi	a1,s0,-80
    800056c4:	8526                	mv	a0,s1
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	b50080e7          	jalr	-1200(ra) # 80004216 <dirlookup>
    800056ce:	8aaa                	mv	s5,a0
    800056d0:	c931                	beqz	a0,80005724 <create+0x9a>
    iunlockput(dp);
    800056d2:	8526                	mv	a0,s1
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	8c0080e7          	jalr	-1856(ra) # 80003f94 <iunlockput>
    ilock(ip);
    800056dc:	8556                	mv	a0,s5
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	654080e7          	jalr	1620(ra) # 80003d32 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056e6:	000b059b          	sext.w	a1,s6
    800056ea:	4789                	li	a5,2
    800056ec:	02f59563          	bne	a1,a5,80005716 <create+0x8c>
    800056f0:	044ad783          	lhu	a5,68(s5)
    800056f4:	37f9                	addiw	a5,a5,-2
    800056f6:	17c2                	slli	a5,a5,0x30
    800056f8:	93c1                	srli	a5,a5,0x30
    800056fa:	4705                	li	a4,1
    800056fc:	00f76d63          	bltu	a4,a5,80005716 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005700:	8556                	mv	a0,s5
    80005702:	60a6                	ld	ra,72(sp)
    80005704:	6406                	ld	s0,64(sp)
    80005706:	74e2                	ld	s1,56(sp)
    80005708:	7942                	ld	s2,48(sp)
    8000570a:	79a2                	ld	s3,40(sp)
    8000570c:	7a02                	ld	s4,32(sp)
    8000570e:	6ae2                	ld	s5,24(sp)
    80005710:	6b42                	ld	s6,16(sp)
    80005712:	6161                	addi	sp,sp,80
    80005714:	8082                	ret
    iunlockput(ip);
    80005716:	8556                	mv	a0,s5
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	87c080e7          	jalr	-1924(ra) # 80003f94 <iunlockput>
    return 0;
    80005720:	4a81                	li	s5,0
    80005722:	bff9                	j	80005700 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005724:	85da                	mv	a1,s6
    80005726:	4088                	lw	a0,0(s1)
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	46e080e7          	jalr	1134(ra) # 80003b96 <ialloc>
    80005730:	8a2a                	mv	s4,a0
    80005732:	c921                	beqz	a0,80005782 <create+0xf8>
  ilock(ip);
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	5fe080e7          	jalr	1534(ra) # 80003d32 <ilock>
  ip->major = major;
    8000573c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005740:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005744:	4785                	li	a5,1
    80005746:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    8000574a:	8552                	mv	a0,s4
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	51c080e7          	jalr	1308(ra) # 80003c68 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005754:	000b059b          	sext.w	a1,s6
    80005758:	4785                	li	a5,1
    8000575a:	02f58b63          	beq	a1,a5,80005790 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    8000575e:	004a2603          	lw	a2,4(s4)
    80005762:	fb040593          	addi	a1,s0,-80
    80005766:	8526                	mv	a0,s1
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	cbe080e7          	jalr	-834(ra) # 80004426 <dirlink>
    80005770:	06054f63          	bltz	a0,800057ee <create+0x164>
  iunlockput(dp);
    80005774:	8526                	mv	a0,s1
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	81e080e7          	jalr	-2018(ra) # 80003f94 <iunlockput>
  return ip;
    8000577e:	8ad2                	mv	s5,s4
    80005780:	b741                	j	80005700 <create+0x76>
    iunlockput(dp);
    80005782:	8526                	mv	a0,s1
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	810080e7          	jalr	-2032(ra) # 80003f94 <iunlockput>
    return 0;
    8000578c:	8ad2                	mv	s5,s4
    8000578e:	bf8d                	j	80005700 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005790:	004a2603          	lw	a2,4(s4)
    80005794:	00003597          	auipc	a1,0x3
    80005798:	f7c58593          	addi	a1,a1,-132 # 80008710 <syscalls+0x2c0>
    8000579c:	8552                	mv	a0,s4
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	c88080e7          	jalr	-888(ra) # 80004426 <dirlink>
    800057a6:	04054463          	bltz	a0,800057ee <create+0x164>
    800057aa:	40d0                	lw	a2,4(s1)
    800057ac:	00003597          	auipc	a1,0x3
    800057b0:	f6c58593          	addi	a1,a1,-148 # 80008718 <syscalls+0x2c8>
    800057b4:	8552                	mv	a0,s4
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	c70080e7          	jalr	-912(ra) # 80004426 <dirlink>
    800057be:	02054863          	bltz	a0,800057ee <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800057c2:	004a2603          	lw	a2,4(s4)
    800057c6:	fb040593          	addi	a1,s0,-80
    800057ca:	8526                	mv	a0,s1
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	c5a080e7          	jalr	-934(ra) # 80004426 <dirlink>
    800057d4:	00054d63          	bltz	a0,800057ee <create+0x164>
    dp->nlink++;  // for ".."
    800057d8:	04a4d783          	lhu	a5,74(s1)
    800057dc:	2785                	addiw	a5,a5,1
    800057de:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057e2:	8526                	mv	a0,s1
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	484080e7          	jalr	1156(ra) # 80003c68 <iupdate>
    800057ec:	b761                	j	80005774 <create+0xea>
  ip->nlink = 0;
    800057ee:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800057f2:	8552                	mv	a0,s4
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	474080e7          	jalr	1140(ra) # 80003c68 <iupdate>
  iunlockput(ip);
    800057fc:	8552                	mv	a0,s4
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	796080e7          	jalr	1942(ra) # 80003f94 <iunlockput>
  iunlockput(dp);
    80005806:	8526                	mv	a0,s1
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	78c080e7          	jalr	1932(ra) # 80003f94 <iunlockput>
  return 0;
    80005810:	bdc5                	j	80005700 <create+0x76>
    return 0;
    80005812:	8aaa                	mv	s5,a0
    80005814:	b5f5                	j	80005700 <create+0x76>

0000000080005816 <sys_getreadcount>:
{
    80005816:	1141                	addi	sp,sp,-16
    80005818:	e422                	sd	s0,8(sp)
    8000581a:	0800                	addi	s0,sp,16
}
    8000581c:	00003517          	auipc	a0,0x3
    80005820:	0c852503          	lw	a0,200(a0) # 800088e4 <readcount>
    80005824:	6422                	ld	s0,8(sp)
    80005826:	0141                	addi	sp,sp,16
    80005828:	8082                	ret

000000008000582a <sys_dup>:
{
    8000582a:	7179                	addi	sp,sp,-48
    8000582c:	f406                	sd	ra,40(sp)
    8000582e:	f022                	sd	s0,32(sp)
    80005830:	ec26                	sd	s1,24(sp)
    80005832:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005834:	fd840613          	addi	a2,s0,-40
    80005838:	4581                	li	a1,0
    8000583a:	4501                	li	a0,0
    8000583c:	00000097          	auipc	ra,0x0
    80005840:	dac080e7          	jalr	-596(ra) # 800055e8 <argfd>
    return -1;
    80005844:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005846:	02054363          	bltz	a0,8000586c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000584a:	fd843503          	ld	a0,-40(s0)
    8000584e:	00000097          	auipc	ra,0x0
    80005852:	dfa080e7          	jalr	-518(ra) # 80005648 <fdalloc>
    80005856:	84aa                	mv	s1,a0
    return -1;
    80005858:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000585a:	00054963          	bltz	a0,8000586c <sys_dup+0x42>
  filedup(f);
    8000585e:	fd843503          	ld	a0,-40(s0)
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	30c080e7          	jalr	780(ra) # 80004b6e <filedup>
  return fd;
    8000586a:	87a6                	mv	a5,s1
}
    8000586c:	853e                	mv	a0,a5
    8000586e:	70a2                	ld	ra,40(sp)
    80005870:	7402                	ld	s0,32(sp)
    80005872:	64e2                	ld	s1,24(sp)
    80005874:	6145                	addi	sp,sp,48
    80005876:	8082                	ret

0000000080005878 <sys_read>:
{
    80005878:	7179                	addi	sp,sp,-48
    8000587a:	f406                	sd	ra,40(sp)
    8000587c:	f022                	sd	s0,32(sp)
    8000587e:	1800                	addi	s0,sp,48
  readcount++;
    80005880:	00003717          	auipc	a4,0x3
    80005884:	06470713          	addi	a4,a4,100 # 800088e4 <readcount>
    80005888:	431c                	lw	a5,0(a4)
    8000588a:	2785                	addiw	a5,a5,1
    8000588c:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    8000588e:	fd840593          	addi	a1,s0,-40
    80005892:	4505                	li	a0,1
    80005894:	ffffd097          	auipc	ra,0xffffd
    80005898:	794080e7          	jalr	1940(ra) # 80003028 <argaddr>
  argint(2, &n);
    8000589c:	fe440593          	addi	a1,s0,-28
    800058a0:	4509                	li	a0,2
    800058a2:	ffffd097          	auipc	ra,0xffffd
    800058a6:	766080e7          	jalr	1894(ra) # 80003008 <argint>
  if(argfd(0, 0, &f) < 0)
    800058aa:	fe840613          	addi	a2,s0,-24
    800058ae:	4581                	li	a1,0
    800058b0:	4501                	li	a0,0
    800058b2:	00000097          	auipc	ra,0x0
    800058b6:	d36080e7          	jalr	-714(ra) # 800055e8 <argfd>
    800058ba:	87aa                	mv	a5,a0
    return -1;
    800058bc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058be:	0007cc63          	bltz	a5,800058d6 <sys_read+0x5e>
  return fileread(f, p, n);
    800058c2:	fe442603          	lw	a2,-28(s0)
    800058c6:	fd843583          	ld	a1,-40(s0)
    800058ca:	fe843503          	ld	a0,-24(s0)
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	42c080e7          	jalr	1068(ra) # 80004cfa <fileread>
}
    800058d6:	70a2                	ld	ra,40(sp)
    800058d8:	7402                	ld	s0,32(sp)
    800058da:	6145                	addi	sp,sp,48
    800058dc:	8082                	ret

00000000800058de <sys_write>:
{
    800058de:	7179                	addi	sp,sp,-48
    800058e0:	f406                	sd	ra,40(sp)
    800058e2:	f022                	sd	s0,32(sp)
    800058e4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058e6:	fd840593          	addi	a1,s0,-40
    800058ea:	4505                	li	a0,1
    800058ec:	ffffd097          	auipc	ra,0xffffd
    800058f0:	73c080e7          	jalr	1852(ra) # 80003028 <argaddr>
  argint(2, &n);
    800058f4:	fe440593          	addi	a1,s0,-28
    800058f8:	4509                	li	a0,2
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	70e080e7          	jalr	1806(ra) # 80003008 <argint>
  if(argfd(0, 0, &f) < 0)
    80005902:	fe840613          	addi	a2,s0,-24
    80005906:	4581                	li	a1,0
    80005908:	4501                	li	a0,0
    8000590a:	00000097          	auipc	ra,0x0
    8000590e:	cde080e7          	jalr	-802(ra) # 800055e8 <argfd>
    80005912:	87aa                	mv	a5,a0
    return -1;
    80005914:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005916:	0007cc63          	bltz	a5,8000592e <sys_write+0x50>
  return filewrite(f, p, n);
    8000591a:	fe442603          	lw	a2,-28(s0)
    8000591e:	fd843583          	ld	a1,-40(s0)
    80005922:	fe843503          	ld	a0,-24(s0)
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	496080e7          	jalr	1174(ra) # 80004dbc <filewrite>
}
    8000592e:	70a2                	ld	ra,40(sp)
    80005930:	7402                	ld	s0,32(sp)
    80005932:	6145                	addi	sp,sp,48
    80005934:	8082                	ret

0000000080005936 <sys_close>:
{
    80005936:	1101                	addi	sp,sp,-32
    80005938:	ec06                	sd	ra,24(sp)
    8000593a:	e822                	sd	s0,16(sp)
    8000593c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000593e:	fe040613          	addi	a2,s0,-32
    80005942:	fec40593          	addi	a1,s0,-20
    80005946:	4501                	li	a0,0
    80005948:	00000097          	auipc	ra,0x0
    8000594c:	ca0080e7          	jalr	-864(ra) # 800055e8 <argfd>
    return -1;
    80005950:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005952:	02054463          	bltz	a0,8000597a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005956:	ffffc097          	auipc	ra,0xffffc
    8000595a:	070080e7          	jalr	112(ra) # 800019c6 <myproc>
    8000595e:	fec42783          	lw	a5,-20(s0)
    80005962:	07e9                	addi	a5,a5,26
    80005964:	078e                	slli	a5,a5,0x3
    80005966:	97aa                	add	a5,a5,a0
    80005968:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000596c:	fe043503          	ld	a0,-32(s0)
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	250080e7          	jalr	592(ra) # 80004bc0 <fileclose>
  return 0;
    80005978:	4781                	li	a5,0
}
    8000597a:	853e                	mv	a0,a5
    8000597c:	60e2                	ld	ra,24(sp)
    8000597e:	6442                	ld	s0,16(sp)
    80005980:	6105                	addi	sp,sp,32
    80005982:	8082                	ret

0000000080005984 <sys_fstat>:
{
    80005984:	1101                	addi	sp,sp,-32
    80005986:	ec06                	sd	ra,24(sp)
    80005988:	e822                	sd	s0,16(sp)
    8000598a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000598c:	fe040593          	addi	a1,s0,-32
    80005990:	4505                	li	a0,1
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	696080e7          	jalr	1686(ra) # 80003028 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000599a:	fe840613          	addi	a2,s0,-24
    8000599e:	4581                	li	a1,0
    800059a0:	4501                	li	a0,0
    800059a2:	00000097          	auipc	ra,0x0
    800059a6:	c46080e7          	jalr	-954(ra) # 800055e8 <argfd>
    800059aa:	87aa                	mv	a5,a0
    return -1;
    800059ac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059ae:	0007ca63          	bltz	a5,800059c2 <sys_fstat+0x3e>
  return filestat(f, st);
    800059b2:	fe043583          	ld	a1,-32(s0)
    800059b6:	fe843503          	ld	a0,-24(s0)
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	2ce080e7          	jalr	718(ra) # 80004c88 <filestat>
}
    800059c2:	60e2                	ld	ra,24(sp)
    800059c4:	6442                	ld	s0,16(sp)
    800059c6:	6105                	addi	sp,sp,32
    800059c8:	8082                	ret

00000000800059ca <sys_link>:
{
    800059ca:	7169                	addi	sp,sp,-304
    800059cc:	f606                	sd	ra,296(sp)
    800059ce:	f222                	sd	s0,288(sp)
    800059d0:	ee26                	sd	s1,280(sp)
    800059d2:	ea4a                	sd	s2,272(sp)
    800059d4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059d6:	08000613          	li	a2,128
    800059da:	ed040593          	addi	a1,s0,-304
    800059de:	4501                	li	a0,0
    800059e0:	ffffd097          	auipc	ra,0xffffd
    800059e4:	668080e7          	jalr	1640(ra) # 80003048 <argstr>
    return -1;
    800059e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059ea:	10054e63          	bltz	a0,80005b06 <sys_link+0x13c>
    800059ee:	08000613          	li	a2,128
    800059f2:	f5040593          	addi	a1,s0,-176
    800059f6:	4505                	li	a0,1
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	650080e7          	jalr	1616(ra) # 80003048 <argstr>
    return -1;
    80005a00:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a02:	10054263          	bltz	a0,80005b06 <sys_link+0x13c>
  begin_op();
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	cee080e7          	jalr	-786(ra) # 800046f4 <begin_op>
  if((ip = namei(old)) == 0){
    80005a0e:	ed040513          	addi	a0,s0,-304
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	ac6080e7          	jalr	-1338(ra) # 800044d8 <namei>
    80005a1a:	84aa                	mv	s1,a0
    80005a1c:	c551                	beqz	a0,80005aa8 <sys_link+0xde>
  ilock(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	314080e7          	jalr	788(ra) # 80003d32 <ilock>
  if(ip->type == T_DIR){
    80005a26:	04449703          	lh	a4,68(s1)
    80005a2a:	4785                	li	a5,1
    80005a2c:	08f70463          	beq	a4,a5,80005ab4 <sys_link+0xea>
  ip->nlink++;
    80005a30:	04a4d783          	lhu	a5,74(s1)
    80005a34:	2785                	addiw	a5,a5,1
    80005a36:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	22c080e7          	jalr	556(ra) # 80003c68 <iupdate>
  iunlock(ip);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	3ae080e7          	jalr	942(ra) # 80003df4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a4e:	fd040593          	addi	a1,s0,-48
    80005a52:	f5040513          	addi	a0,s0,-176
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	aa0080e7          	jalr	-1376(ra) # 800044f6 <nameiparent>
    80005a5e:	892a                	mv	s2,a0
    80005a60:	c935                	beqz	a0,80005ad4 <sys_link+0x10a>
  ilock(dp);
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	2d0080e7          	jalr	720(ra) # 80003d32 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a6a:	00092703          	lw	a4,0(s2)
    80005a6e:	409c                	lw	a5,0(s1)
    80005a70:	04f71d63          	bne	a4,a5,80005aca <sys_link+0x100>
    80005a74:	40d0                	lw	a2,4(s1)
    80005a76:	fd040593          	addi	a1,s0,-48
    80005a7a:	854a                	mv	a0,s2
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	9aa080e7          	jalr	-1622(ra) # 80004426 <dirlink>
    80005a84:	04054363          	bltz	a0,80005aca <sys_link+0x100>
  iunlockput(dp);
    80005a88:	854a                	mv	a0,s2
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	50a080e7          	jalr	1290(ra) # 80003f94 <iunlockput>
  iput(ip);
    80005a92:	8526                	mv	a0,s1
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	458080e7          	jalr	1112(ra) # 80003eec <iput>
  end_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	cd8080e7          	jalr	-808(ra) # 80004774 <end_op>
  return 0;
    80005aa4:	4781                	li	a5,0
    80005aa6:	a085                	j	80005b06 <sys_link+0x13c>
    end_op();
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	ccc080e7          	jalr	-820(ra) # 80004774 <end_op>
    return -1;
    80005ab0:	57fd                	li	a5,-1
    80005ab2:	a891                	j	80005b06 <sys_link+0x13c>
    iunlockput(ip);
    80005ab4:	8526                	mv	a0,s1
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	4de080e7          	jalr	1246(ra) # 80003f94 <iunlockput>
    end_op();
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	cb6080e7          	jalr	-842(ra) # 80004774 <end_op>
    return -1;
    80005ac6:	57fd                	li	a5,-1
    80005ac8:	a83d                	j	80005b06 <sys_link+0x13c>
    iunlockput(dp);
    80005aca:	854a                	mv	a0,s2
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	4c8080e7          	jalr	1224(ra) # 80003f94 <iunlockput>
  ilock(ip);
    80005ad4:	8526                	mv	a0,s1
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	25c080e7          	jalr	604(ra) # 80003d32 <ilock>
  ip->nlink--;
    80005ade:	04a4d783          	lhu	a5,74(s1)
    80005ae2:	37fd                	addiw	a5,a5,-1
    80005ae4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ae8:	8526                	mv	a0,s1
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	17e080e7          	jalr	382(ra) # 80003c68 <iupdate>
  iunlockput(ip);
    80005af2:	8526                	mv	a0,s1
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	4a0080e7          	jalr	1184(ra) # 80003f94 <iunlockput>
  end_op();
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	c78080e7          	jalr	-904(ra) # 80004774 <end_op>
  return -1;
    80005b04:	57fd                	li	a5,-1
}
    80005b06:	853e                	mv	a0,a5
    80005b08:	70b2                	ld	ra,296(sp)
    80005b0a:	7412                	ld	s0,288(sp)
    80005b0c:	64f2                	ld	s1,280(sp)
    80005b0e:	6952                	ld	s2,272(sp)
    80005b10:	6155                	addi	sp,sp,304
    80005b12:	8082                	ret

0000000080005b14 <sys_unlink>:
{
    80005b14:	7151                	addi	sp,sp,-240
    80005b16:	f586                	sd	ra,232(sp)
    80005b18:	f1a2                	sd	s0,224(sp)
    80005b1a:	eda6                	sd	s1,216(sp)
    80005b1c:	e9ca                	sd	s2,208(sp)
    80005b1e:	e5ce                	sd	s3,200(sp)
    80005b20:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b22:	08000613          	li	a2,128
    80005b26:	f3040593          	addi	a1,s0,-208
    80005b2a:	4501                	li	a0,0
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	51c080e7          	jalr	1308(ra) # 80003048 <argstr>
    80005b34:	18054163          	bltz	a0,80005cb6 <sys_unlink+0x1a2>
  begin_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	bbc080e7          	jalr	-1092(ra) # 800046f4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b40:	fb040593          	addi	a1,s0,-80
    80005b44:	f3040513          	addi	a0,s0,-208
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	9ae080e7          	jalr	-1618(ra) # 800044f6 <nameiparent>
    80005b50:	84aa                	mv	s1,a0
    80005b52:	c979                	beqz	a0,80005c28 <sys_unlink+0x114>
  ilock(dp);
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	1de080e7          	jalr	478(ra) # 80003d32 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b5c:	00003597          	auipc	a1,0x3
    80005b60:	bb458593          	addi	a1,a1,-1100 # 80008710 <syscalls+0x2c0>
    80005b64:	fb040513          	addi	a0,s0,-80
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	694080e7          	jalr	1684(ra) # 800041fc <namecmp>
    80005b70:	14050a63          	beqz	a0,80005cc4 <sys_unlink+0x1b0>
    80005b74:	00003597          	auipc	a1,0x3
    80005b78:	ba458593          	addi	a1,a1,-1116 # 80008718 <syscalls+0x2c8>
    80005b7c:	fb040513          	addi	a0,s0,-80
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	67c080e7          	jalr	1660(ra) # 800041fc <namecmp>
    80005b88:	12050e63          	beqz	a0,80005cc4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b8c:	f2c40613          	addi	a2,s0,-212
    80005b90:	fb040593          	addi	a1,s0,-80
    80005b94:	8526                	mv	a0,s1
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	680080e7          	jalr	1664(ra) # 80004216 <dirlookup>
    80005b9e:	892a                	mv	s2,a0
    80005ba0:	12050263          	beqz	a0,80005cc4 <sys_unlink+0x1b0>
  ilock(ip);
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	18e080e7          	jalr	398(ra) # 80003d32 <ilock>
  if(ip->nlink < 1)
    80005bac:	04a91783          	lh	a5,74(s2)
    80005bb0:	08f05263          	blez	a5,80005c34 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005bb4:	04491703          	lh	a4,68(s2)
    80005bb8:	4785                	li	a5,1
    80005bba:	08f70563          	beq	a4,a5,80005c44 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005bbe:	4641                	li	a2,16
    80005bc0:	4581                	li	a1,0
    80005bc2:	fc040513          	addi	a0,s0,-64
    80005bc6:	ffffb097          	auipc	ra,0xffffb
    80005bca:	120080e7          	jalr	288(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bce:	4741                	li	a4,16
    80005bd0:	f2c42683          	lw	a3,-212(s0)
    80005bd4:	fc040613          	addi	a2,s0,-64
    80005bd8:	4581                	li	a1,0
    80005bda:	8526                	mv	a0,s1
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	502080e7          	jalr	1282(ra) # 800040de <writei>
    80005be4:	47c1                	li	a5,16
    80005be6:	0af51563          	bne	a0,a5,80005c90 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bea:	04491703          	lh	a4,68(s2)
    80005bee:	4785                	li	a5,1
    80005bf0:	0af70863          	beq	a4,a5,80005ca0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005bf4:	8526                	mv	a0,s1
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	39e080e7          	jalr	926(ra) # 80003f94 <iunlockput>
  ip->nlink--;
    80005bfe:	04a95783          	lhu	a5,74(s2)
    80005c02:	37fd                	addiw	a5,a5,-1
    80005c04:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c08:	854a                	mv	a0,s2
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	05e080e7          	jalr	94(ra) # 80003c68 <iupdate>
  iunlockput(ip);
    80005c12:	854a                	mv	a0,s2
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	380080e7          	jalr	896(ra) # 80003f94 <iunlockput>
  end_op();
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	b58080e7          	jalr	-1192(ra) # 80004774 <end_op>
  return 0;
    80005c24:	4501                	li	a0,0
    80005c26:	a84d                	j	80005cd8 <sys_unlink+0x1c4>
    end_op();
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	b4c080e7          	jalr	-1204(ra) # 80004774 <end_op>
    return -1;
    80005c30:	557d                	li	a0,-1
    80005c32:	a05d                	j	80005cd8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c34:	00003517          	auipc	a0,0x3
    80005c38:	aec50513          	addi	a0,a0,-1300 # 80008720 <syscalls+0x2d0>
    80005c3c:	ffffb097          	auipc	ra,0xffffb
    80005c40:	908080e7          	jalr	-1784(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c44:	04c92703          	lw	a4,76(s2)
    80005c48:	02000793          	li	a5,32
    80005c4c:	f6e7f9e3          	bgeu	a5,a4,80005bbe <sys_unlink+0xaa>
    80005c50:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c54:	4741                	li	a4,16
    80005c56:	86ce                	mv	a3,s3
    80005c58:	f1840613          	addi	a2,s0,-232
    80005c5c:	4581                	li	a1,0
    80005c5e:	854a                	mv	a0,s2
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	386080e7          	jalr	902(ra) # 80003fe6 <readi>
    80005c68:	47c1                	li	a5,16
    80005c6a:	00f51b63          	bne	a0,a5,80005c80 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c6e:	f1845783          	lhu	a5,-232(s0)
    80005c72:	e7a1                	bnez	a5,80005cba <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c74:	29c1                	addiw	s3,s3,16
    80005c76:	04c92783          	lw	a5,76(s2)
    80005c7a:	fcf9ede3          	bltu	s3,a5,80005c54 <sys_unlink+0x140>
    80005c7e:	b781                	j	80005bbe <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c80:	00003517          	auipc	a0,0x3
    80005c84:	ab850513          	addi	a0,a0,-1352 # 80008738 <syscalls+0x2e8>
    80005c88:	ffffb097          	auipc	ra,0xffffb
    80005c8c:	8bc080e7          	jalr	-1860(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005c90:	00003517          	auipc	a0,0x3
    80005c94:	ac050513          	addi	a0,a0,-1344 # 80008750 <syscalls+0x300>
    80005c98:	ffffb097          	auipc	ra,0xffffb
    80005c9c:	8ac080e7          	jalr	-1876(ra) # 80000544 <panic>
    dp->nlink--;
    80005ca0:	04a4d783          	lhu	a5,74(s1)
    80005ca4:	37fd                	addiw	a5,a5,-1
    80005ca6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005caa:	8526                	mv	a0,s1
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	fbc080e7          	jalr	-68(ra) # 80003c68 <iupdate>
    80005cb4:	b781                	j	80005bf4 <sys_unlink+0xe0>
    return -1;
    80005cb6:	557d                	li	a0,-1
    80005cb8:	a005                	j	80005cd8 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005cba:	854a                	mv	a0,s2
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	2d8080e7          	jalr	728(ra) # 80003f94 <iunlockput>
  iunlockput(dp);
    80005cc4:	8526                	mv	a0,s1
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	2ce080e7          	jalr	718(ra) # 80003f94 <iunlockput>
  end_op();
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	aa6080e7          	jalr	-1370(ra) # 80004774 <end_op>
  return -1;
    80005cd6:	557d                	li	a0,-1
}
    80005cd8:	70ae                	ld	ra,232(sp)
    80005cda:	740e                	ld	s0,224(sp)
    80005cdc:	64ee                	ld	s1,216(sp)
    80005cde:	694e                	ld	s2,208(sp)
    80005ce0:	69ae                	ld	s3,200(sp)
    80005ce2:	616d                	addi	sp,sp,240
    80005ce4:	8082                	ret

0000000080005ce6 <sys_open>:

uint64
sys_open(void)
{
    80005ce6:	7131                	addi	sp,sp,-192
    80005ce8:	fd06                	sd	ra,184(sp)
    80005cea:	f922                	sd	s0,176(sp)
    80005cec:	f526                	sd	s1,168(sp)
    80005cee:	f14a                	sd	s2,160(sp)
    80005cf0:	ed4e                	sd	s3,152(sp)
    80005cf2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005cf4:	f4c40593          	addi	a1,s0,-180
    80005cf8:	4505                	li	a0,1
    80005cfa:	ffffd097          	auipc	ra,0xffffd
    80005cfe:	30e080e7          	jalr	782(ra) # 80003008 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d02:	08000613          	li	a2,128
    80005d06:	f5040593          	addi	a1,s0,-176
    80005d0a:	4501                	li	a0,0
    80005d0c:	ffffd097          	auipc	ra,0xffffd
    80005d10:	33c080e7          	jalr	828(ra) # 80003048 <argstr>
    80005d14:	87aa                	mv	a5,a0
    return -1;
    80005d16:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d18:	0a07c963          	bltz	a5,80005dca <sys_open+0xe4>

  begin_op();
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	9d8080e7          	jalr	-1576(ra) # 800046f4 <begin_op>

  if(omode & O_CREATE){
    80005d24:	f4c42783          	lw	a5,-180(s0)
    80005d28:	2007f793          	andi	a5,a5,512
    80005d2c:	cfc5                	beqz	a5,80005de4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d2e:	4681                	li	a3,0
    80005d30:	4601                	li	a2,0
    80005d32:	4589                	li	a1,2
    80005d34:	f5040513          	addi	a0,s0,-176
    80005d38:	00000097          	auipc	ra,0x0
    80005d3c:	952080e7          	jalr	-1710(ra) # 8000568a <create>
    80005d40:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d42:	c959                	beqz	a0,80005dd8 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d44:	04449703          	lh	a4,68(s1)
    80005d48:	478d                	li	a5,3
    80005d4a:	00f71763          	bne	a4,a5,80005d58 <sys_open+0x72>
    80005d4e:	0464d703          	lhu	a4,70(s1)
    80005d52:	47a5                	li	a5,9
    80005d54:	0ce7ed63          	bltu	a5,a4,80005e2e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	dac080e7          	jalr	-596(ra) # 80004b04 <filealloc>
    80005d60:	89aa                	mv	s3,a0
    80005d62:	10050363          	beqz	a0,80005e68 <sys_open+0x182>
    80005d66:	00000097          	auipc	ra,0x0
    80005d6a:	8e2080e7          	jalr	-1822(ra) # 80005648 <fdalloc>
    80005d6e:	892a                	mv	s2,a0
    80005d70:	0e054763          	bltz	a0,80005e5e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d74:	04449703          	lh	a4,68(s1)
    80005d78:	478d                	li	a5,3
    80005d7a:	0cf70563          	beq	a4,a5,80005e44 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d7e:	4789                	li	a5,2
    80005d80:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d84:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d88:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d8c:	f4c42783          	lw	a5,-180(s0)
    80005d90:	0017c713          	xori	a4,a5,1
    80005d94:	8b05                	andi	a4,a4,1
    80005d96:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d9a:	0037f713          	andi	a4,a5,3
    80005d9e:	00e03733          	snez	a4,a4
    80005da2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005da6:	4007f793          	andi	a5,a5,1024
    80005daa:	c791                	beqz	a5,80005db6 <sys_open+0xd0>
    80005dac:	04449703          	lh	a4,68(s1)
    80005db0:	4789                	li	a5,2
    80005db2:	0af70063          	beq	a4,a5,80005e52 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005db6:	8526                	mv	a0,s1
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	03c080e7          	jalr	60(ra) # 80003df4 <iunlock>
  end_op();
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	9b4080e7          	jalr	-1612(ra) # 80004774 <end_op>

  return fd;
    80005dc8:	854a                	mv	a0,s2
}
    80005dca:	70ea                	ld	ra,184(sp)
    80005dcc:	744a                	ld	s0,176(sp)
    80005dce:	74aa                	ld	s1,168(sp)
    80005dd0:	790a                	ld	s2,160(sp)
    80005dd2:	69ea                	ld	s3,152(sp)
    80005dd4:	6129                	addi	sp,sp,192
    80005dd6:	8082                	ret
      end_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	99c080e7          	jalr	-1636(ra) # 80004774 <end_op>
      return -1;
    80005de0:	557d                	li	a0,-1
    80005de2:	b7e5                	j	80005dca <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005de4:	f5040513          	addi	a0,s0,-176
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	6f0080e7          	jalr	1776(ra) # 800044d8 <namei>
    80005df0:	84aa                	mv	s1,a0
    80005df2:	c905                	beqz	a0,80005e22 <sys_open+0x13c>
    ilock(ip);
    80005df4:	ffffe097          	auipc	ra,0xffffe
    80005df8:	f3e080e7          	jalr	-194(ra) # 80003d32 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005dfc:	04449703          	lh	a4,68(s1)
    80005e00:	4785                	li	a5,1
    80005e02:	f4f711e3          	bne	a4,a5,80005d44 <sys_open+0x5e>
    80005e06:	f4c42783          	lw	a5,-180(s0)
    80005e0a:	d7b9                	beqz	a5,80005d58 <sys_open+0x72>
      iunlockput(ip);
    80005e0c:	8526                	mv	a0,s1
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	186080e7          	jalr	390(ra) # 80003f94 <iunlockput>
      end_op();
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	95e080e7          	jalr	-1698(ra) # 80004774 <end_op>
      return -1;
    80005e1e:	557d                	li	a0,-1
    80005e20:	b76d                	j	80005dca <sys_open+0xe4>
      end_op();
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	952080e7          	jalr	-1710(ra) # 80004774 <end_op>
      return -1;
    80005e2a:	557d                	li	a0,-1
    80005e2c:	bf79                	j	80005dca <sys_open+0xe4>
    iunlockput(ip);
    80005e2e:	8526                	mv	a0,s1
    80005e30:	ffffe097          	auipc	ra,0xffffe
    80005e34:	164080e7          	jalr	356(ra) # 80003f94 <iunlockput>
    end_op();
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	93c080e7          	jalr	-1732(ra) # 80004774 <end_op>
    return -1;
    80005e40:	557d                	li	a0,-1
    80005e42:	b761                	j	80005dca <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e44:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e48:	04649783          	lh	a5,70(s1)
    80005e4c:	02f99223          	sh	a5,36(s3)
    80005e50:	bf25                	j	80005d88 <sys_open+0xa2>
    itrunc(ip);
    80005e52:	8526                	mv	a0,s1
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	fec080e7          	jalr	-20(ra) # 80003e40 <itrunc>
    80005e5c:	bfa9                	j	80005db6 <sys_open+0xd0>
      fileclose(f);
    80005e5e:	854e                	mv	a0,s3
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	d60080e7          	jalr	-672(ra) # 80004bc0 <fileclose>
    iunlockput(ip);
    80005e68:	8526                	mv	a0,s1
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	12a080e7          	jalr	298(ra) # 80003f94 <iunlockput>
    end_op();
    80005e72:	fffff097          	auipc	ra,0xfffff
    80005e76:	902080e7          	jalr	-1790(ra) # 80004774 <end_op>
    return -1;
    80005e7a:	557d                	li	a0,-1
    80005e7c:	b7b9                	j	80005dca <sys_open+0xe4>

0000000080005e7e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e7e:	7175                	addi	sp,sp,-144
    80005e80:	e506                	sd	ra,136(sp)
    80005e82:	e122                	sd	s0,128(sp)
    80005e84:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e86:	fffff097          	auipc	ra,0xfffff
    80005e8a:	86e080e7          	jalr	-1938(ra) # 800046f4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e8e:	08000613          	li	a2,128
    80005e92:	f7040593          	addi	a1,s0,-144
    80005e96:	4501                	li	a0,0
    80005e98:	ffffd097          	auipc	ra,0xffffd
    80005e9c:	1b0080e7          	jalr	432(ra) # 80003048 <argstr>
    80005ea0:	02054963          	bltz	a0,80005ed2 <sys_mkdir+0x54>
    80005ea4:	4681                	li	a3,0
    80005ea6:	4601                	li	a2,0
    80005ea8:	4585                	li	a1,1
    80005eaa:	f7040513          	addi	a0,s0,-144
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	7dc080e7          	jalr	2012(ra) # 8000568a <create>
    80005eb6:	cd11                	beqz	a0,80005ed2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	0dc080e7          	jalr	220(ra) # 80003f94 <iunlockput>
  end_op();
    80005ec0:	fffff097          	auipc	ra,0xfffff
    80005ec4:	8b4080e7          	jalr	-1868(ra) # 80004774 <end_op>
  return 0;
    80005ec8:	4501                	li	a0,0
}
    80005eca:	60aa                	ld	ra,136(sp)
    80005ecc:	640a                	ld	s0,128(sp)
    80005ece:	6149                	addi	sp,sp,144
    80005ed0:	8082                	ret
    end_op();
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	8a2080e7          	jalr	-1886(ra) # 80004774 <end_op>
    return -1;
    80005eda:	557d                	li	a0,-1
    80005edc:	b7fd                	j	80005eca <sys_mkdir+0x4c>

0000000080005ede <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ede:	7135                	addi	sp,sp,-160
    80005ee0:	ed06                	sd	ra,152(sp)
    80005ee2:	e922                	sd	s0,144(sp)
    80005ee4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	80e080e7          	jalr	-2034(ra) # 800046f4 <begin_op>
  argint(1, &major);
    80005eee:	f6c40593          	addi	a1,s0,-148
    80005ef2:	4505                	li	a0,1
    80005ef4:	ffffd097          	auipc	ra,0xffffd
    80005ef8:	114080e7          	jalr	276(ra) # 80003008 <argint>
  argint(2, &minor);
    80005efc:	f6840593          	addi	a1,s0,-152
    80005f00:	4509                	li	a0,2
    80005f02:	ffffd097          	auipc	ra,0xffffd
    80005f06:	106080e7          	jalr	262(ra) # 80003008 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f0a:	08000613          	li	a2,128
    80005f0e:	f7040593          	addi	a1,s0,-144
    80005f12:	4501                	li	a0,0
    80005f14:	ffffd097          	auipc	ra,0xffffd
    80005f18:	134080e7          	jalr	308(ra) # 80003048 <argstr>
    80005f1c:	02054b63          	bltz	a0,80005f52 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f20:	f6841683          	lh	a3,-152(s0)
    80005f24:	f6c41603          	lh	a2,-148(s0)
    80005f28:	458d                	li	a1,3
    80005f2a:	f7040513          	addi	a0,s0,-144
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	75c080e7          	jalr	1884(ra) # 8000568a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f36:	cd11                	beqz	a0,80005f52 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f38:	ffffe097          	auipc	ra,0xffffe
    80005f3c:	05c080e7          	jalr	92(ra) # 80003f94 <iunlockput>
  end_op();
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	834080e7          	jalr	-1996(ra) # 80004774 <end_op>
  return 0;
    80005f48:	4501                	li	a0,0
}
    80005f4a:	60ea                	ld	ra,152(sp)
    80005f4c:	644a                	ld	s0,144(sp)
    80005f4e:	610d                	addi	sp,sp,160
    80005f50:	8082                	ret
    end_op();
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	822080e7          	jalr	-2014(ra) # 80004774 <end_op>
    return -1;
    80005f5a:	557d                	li	a0,-1
    80005f5c:	b7fd                	j	80005f4a <sys_mknod+0x6c>

0000000080005f5e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f5e:	7135                	addi	sp,sp,-160
    80005f60:	ed06                	sd	ra,152(sp)
    80005f62:	e922                	sd	s0,144(sp)
    80005f64:	e526                	sd	s1,136(sp)
    80005f66:	e14a                	sd	s2,128(sp)
    80005f68:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f6a:	ffffc097          	auipc	ra,0xffffc
    80005f6e:	a5c080e7          	jalr	-1444(ra) # 800019c6 <myproc>
    80005f72:	892a                	mv	s2,a0
  
  begin_op();
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	780080e7          	jalr	1920(ra) # 800046f4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f7c:	08000613          	li	a2,128
    80005f80:	f6040593          	addi	a1,s0,-160
    80005f84:	4501                	li	a0,0
    80005f86:	ffffd097          	auipc	ra,0xffffd
    80005f8a:	0c2080e7          	jalr	194(ra) # 80003048 <argstr>
    80005f8e:	04054b63          	bltz	a0,80005fe4 <sys_chdir+0x86>
    80005f92:	f6040513          	addi	a0,s0,-160
    80005f96:	ffffe097          	auipc	ra,0xffffe
    80005f9a:	542080e7          	jalr	1346(ra) # 800044d8 <namei>
    80005f9e:	84aa                	mv	s1,a0
    80005fa0:	c131                	beqz	a0,80005fe4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fa2:	ffffe097          	auipc	ra,0xffffe
    80005fa6:	d90080e7          	jalr	-624(ra) # 80003d32 <ilock>
  if(ip->type != T_DIR){
    80005faa:	04449703          	lh	a4,68(s1)
    80005fae:	4785                	li	a5,1
    80005fb0:	04f71063          	bne	a4,a5,80005ff0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005fb4:	8526                	mv	a0,s1
    80005fb6:	ffffe097          	auipc	ra,0xffffe
    80005fba:	e3e080e7          	jalr	-450(ra) # 80003df4 <iunlock>
  iput(p->cwd);
    80005fbe:	15093503          	ld	a0,336(s2)
    80005fc2:	ffffe097          	auipc	ra,0xffffe
    80005fc6:	f2a080e7          	jalr	-214(ra) # 80003eec <iput>
  end_op();
    80005fca:	ffffe097          	auipc	ra,0xffffe
    80005fce:	7aa080e7          	jalr	1962(ra) # 80004774 <end_op>
  p->cwd = ip;
    80005fd2:	14993823          	sd	s1,336(s2)
  return 0;
    80005fd6:	4501                	li	a0,0
}
    80005fd8:	60ea                	ld	ra,152(sp)
    80005fda:	644a                	ld	s0,144(sp)
    80005fdc:	64aa                	ld	s1,136(sp)
    80005fde:	690a                	ld	s2,128(sp)
    80005fe0:	610d                	addi	sp,sp,160
    80005fe2:	8082                	ret
    end_op();
    80005fe4:	ffffe097          	auipc	ra,0xffffe
    80005fe8:	790080e7          	jalr	1936(ra) # 80004774 <end_op>
    return -1;
    80005fec:	557d                	li	a0,-1
    80005fee:	b7ed                	j	80005fd8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ff0:	8526                	mv	a0,s1
    80005ff2:	ffffe097          	auipc	ra,0xffffe
    80005ff6:	fa2080e7          	jalr	-94(ra) # 80003f94 <iunlockput>
    end_op();
    80005ffa:	ffffe097          	auipc	ra,0xffffe
    80005ffe:	77a080e7          	jalr	1914(ra) # 80004774 <end_op>
    return -1;
    80006002:	557d                	li	a0,-1
    80006004:	bfd1                	j	80005fd8 <sys_chdir+0x7a>

0000000080006006 <sys_exec>:

uint64
sys_exec(void)
{
    80006006:	7145                	addi	sp,sp,-464
    80006008:	e786                	sd	ra,456(sp)
    8000600a:	e3a2                	sd	s0,448(sp)
    8000600c:	ff26                	sd	s1,440(sp)
    8000600e:	fb4a                	sd	s2,432(sp)
    80006010:	f74e                	sd	s3,424(sp)
    80006012:	f352                	sd	s4,416(sp)
    80006014:	ef56                	sd	s5,408(sp)
    80006016:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006018:	e3840593          	addi	a1,s0,-456
    8000601c:	4505                	li	a0,1
    8000601e:	ffffd097          	auipc	ra,0xffffd
    80006022:	00a080e7          	jalr	10(ra) # 80003028 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006026:	08000613          	li	a2,128
    8000602a:	f4040593          	addi	a1,s0,-192
    8000602e:	4501                	li	a0,0
    80006030:	ffffd097          	auipc	ra,0xffffd
    80006034:	018080e7          	jalr	24(ra) # 80003048 <argstr>
    80006038:	87aa                	mv	a5,a0
    return -1;
    8000603a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000603c:	0c07c263          	bltz	a5,80006100 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006040:	10000613          	li	a2,256
    80006044:	4581                	li	a1,0
    80006046:	e4040513          	addi	a0,s0,-448
    8000604a:	ffffb097          	auipc	ra,0xffffb
    8000604e:	c9c080e7          	jalr	-868(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006052:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006056:	89a6                	mv	s3,s1
    80006058:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000605a:	02000a13          	li	s4,32
    8000605e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006062:	00391513          	slli	a0,s2,0x3
    80006066:	e3040593          	addi	a1,s0,-464
    8000606a:	e3843783          	ld	a5,-456(s0)
    8000606e:	953e                	add	a0,a0,a5
    80006070:	ffffd097          	auipc	ra,0xffffd
    80006074:	efa080e7          	jalr	-262(ra) # 80002f6a <fetchaddr>
    80006078:	02054a63          	bltz	a0,800060ac <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000607c:	e3043783          	ld	a5,-464(s0)
    80006080:	c3b9                	beqz	a5,800060c6 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006082:	ffffb097          	auipc	ra,0xffffb
    80006086:	a78080e7          	jalr	-1416(ra) # 80000afa <kalloc>
    8000608a:	85aa                	mv	a1,a0
    8000608c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006090:	cd11                	beqz	a0,800060ac <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006092:	6605                	lui	a2,0x1
    80006094:	e3043503          	ld	a0,-464(s0)
    80006098:	ffffd097          	auipc	ra,0xffffd
    8000609c:	f24080e7          	jalr	-220(ra) # 80002fbc <fetchstr>
    800060a0:	00054663          	bltz	a0,800060ac <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800060a4:	0905                	addi	s2,s2,1
    800060a6:	09a1                	addi	s3,s3,8
    800060a8:	fb491be3          	bne	s2,s4,8000605e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060ac:	10048913          	addi	s2,s1,256
    800060b0:	6088                	ld	a0,0(s1)
    800060b2:	c531                	beqz	a0,800060fe <sys_exec+0xf8>
    kfree(argv[i]);
    800060b4:	ffffb097          	auipc	ra,0xffffb
    800060b8:	94a080e7          	jalr	-1718(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060bc:	04a1                	addi	s1,s1,8
    800060be:	ff2499e3          	bne	s1,s2,800060b0 <sys_exec+0xaa>
  return -1;
    800060c2:	557d                	li	a0,-1
    800060c4:	a835                	j	80006100 <sys_exec+0xfa>
      argv[i] = 0;
    800060c6:	0a8e                	slli	s5,s5,0x3
    800060c8:	fc040793          	addi	a5,s0,-64
    800060cc:	9abe                	add	s5,s5,a5
    800060ce:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800060d2:	e4040593          	addi	a1,s0,-448
    800060d6:	f4040513          	addi	a0,s0,-192
    800060da:	fffff097          	auipc	ra,0xfffff
    800060de:	16e080e7          	jalr	366(ra) # 80005248 <exec>
    800060e2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060e4:	10048993          	addi	s3,s1,256
    800060e8:	6088                	ld	a0,0(s1)
    800060ea:	c901                	beqz	a0,800060fa <sys_exec+0xf4>
    kfree(argv[i]);
    800060ec:	ffffb097          	auipc	ra,0xffffb
    800060f0:	912080e7          	jalr	-1774(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060f4:	04a1                	addi	s1,s1,8
    800060f6:	ff3499e3          	bne	s1,s3,800060e8 <sys_exec+0xe2>
  return ret;
    800060fa:	854a                	mv	a0,s2
    800060fc:	a011                	j	80006100 <sys_exec+0xfa>
  return -1;
    800060fe:	557d                	li	a0,-1
}
    80006100:	60be                	ld	ra,456(sp)
    80006102:	641e                	ld	s0,448(sp)
    80006104:	74fa                	ld	s1,440(sp)
    80006106:	795a                	ld	s2,432(sp)
    80006108:	79ba                	ld	s3,424(sp)
    8000610a:	7a1a                	ld	s4,416(sp)
    8000610c:	6afa                	ld	s5,408(sp)
    8000610e:	6179                	addi	sp,sp,464
    80006110:	8082                	ret

0000000080006112 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006112:	7139                	addi	sp,sp,-64
    80006114:	fc06                	sd	ra,56(sp)
    80006116:	f822                	sd	s0,48(sp)
    80006118:	f426                	sd	s1,40(sp)
    8000611a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000611c:	ffffc097          	auipc	ra,0xffffc
    80006120:	8aa080e7          	jalr	-1878(ra) # 800019c6 <myproc>
    80006124:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006126:	fd840593          	addi	a1,s0,-40
    8000612a:	4501                	li	a0,0
    8000612c:	ffffd097          	auipc	ra,0xffffd
    80006130:	efc080e7          	jalr	-260(ra) # 80003028 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006134:	fc840593          	addi	a1,s0,-56
    80006138:	fd040513          	addi	a0,s0,-48
    8000613c:	fffff097          	auipc	ra,0xfffff
    80006140:	db4080e7          	jalr	-588(ra) # 80004ef0 <pipealloc>
    return -1;
    80006144:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006146:	0c054463          	bltz	a0,8000620e <sys_pipe+0xfc>
  fd0 = -1;
    8000614a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000614e:	fd043503          	ld	a0,-48(s0)
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	4f6080e7          	jalr	1270(ra) # 80005648 <fdalloc>
    8000615a:	fca42223          	sw	a0,-60(s0)
    8000615e:	08054b63          	bltz	a0,800061f4 <sys_pipe+0xe2>
    80006162:	fc843503          	ld	a0,-56(s0)
    80006166:	fffff097          	auipc	ra,0xfffff
    8000616a:	4e2080e7          	jalr	1250(ra) # 80005648 <fdalloc>
    8000616e:	fca42023          	sw	a0,-64(s0)
    80006172:	06054863          	bltz	a0,800061e2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006176:	4691                	li	a3,4
    80006178:	fc440613          	addi	a2,s0,-60
    8000617c:	fd843583          	ld	a1,-40(s0)
    80006180:	68a8                	ld	a0,80(s1)
    80006182:	ffffb097          	auipc	ra,0xffffb
    80006186:	502080e7          	jalr	1282(ra) # 80001684 <copyout>
    8000618a:	02054063          	bltz	a0,800061aa <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000618e:	4691                	li	a3,4
    80006190:	fc040613          	addi	a2,s0,-64
    80006194:	fd843583          	ld	a1,-40(s0)
    80006198:	0591                	addi	a1,a1,4
    8000619a:	68a8                	ld	a0,80(s1)
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	4e8080e7          	jalr	1256(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061a4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061a6:	06055463          	bgez	a0,8000620e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800061aa:	fc442783          	lw	a5,-60(s0)
    800061ae:	07e9                	addi	a5,a5,26
    800061b0:	078e                	slli	a5,a5,0x3
    800061b2:	97a6                	add	a5,a5,s1
    800061b4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800061b8:	fc042503          	lw	a0,-64(s0)
    800061bc:	0569                	addi	a0,a0,26
    800061be:	050e                	slli	a0,a0,0x3
    800061c0:	94aa                	add	s1,s1,a0
    800061c2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061c6:	fd043503          	ld	a0,-48(s0)
    800061ca:	fffff097          	auipc	ra,0xfffff
    800061ce:	9f6080e7          	jalr	-1546(ra) # 80004bc0 <fileclose>
    fileclose(wf);
    800061d2:	fc843503          	ld	a0,-56(s0)
    800061d6:	fffff097          	auipc	ra,0xfffff
    800061da:	9ea080e7          	jalr	-1558(ra) # 80004bc0 <fileclose>
    return -1;
    800061de:	57fd                	li	a5,-1
    800061e0:	a03d                	j	8000620e <sys_pipe+0xfc>
    if(fd0 >= 0)
    800061e2:	fc442783          	lw	a5,-60(s0)
    800061e6:	0007c763          	bltz	a5,800061f4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800061ea:	07e9                	addi	a5,a5,26
    800061ec:	078e                	slli	a5,a5,0x3
    800061ee:	94be                	add	s1,s1,a5
    800061f0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061f4:	fd043503          	ld	a0,-48(s0)
    800061f8:	fffff097          	auipc	ra,0xfffff
    800061fc:	9c8080e7          	jalr	-1592(ra) # 80004bc0 <fileclose>
    fileclose(wf);
    80006200:	fc843503          	ld	a0,-56(s0)
    80006204:	fffff097          	auipc	ra,0xfffff
    80006208:	9bc080e7          	jalr	-1604(ra) # 80004bc0 <fileclose>
    return -1;
    8000620c:	57fd                	li	a5,-1
}
    8000620e:	853e                	mv	a0,a5
    80006210:	70e2                	ld	ra,56(sp)
    80006212:	7442                	ld	s0,48(sp)
    80006214:	74a2                	ld	s1,40(sp)
    80006216:	6121                	addi	sp,sp,64
    80006218:	8082                	ret
    8000621a:	0000                	unimp
    8000621c:	0000                	unimp
	...

0000000080006220 <kernelvec>:
    80006220:	7111                	addi	sp,sp,-256
    80006222:	e006                	sd	ra,0(sp)
    80006224:	e40a                	sd	sp,8(sp)
    80006226:	e80e                	sd	gp,16(sp)
    80006228:	ec12                	sd	tp,24(sp)
    8000622a:	f016                	sd	t0,32(sp)
    8000622c:	f41a                	sd	t1,40(sp)
    8000622e:	f81e                	sd	t2,48(sp)
    80006230:	fc22                	sd	s0,56(sp)
    80006232:	e0a6                	sd	s1,64(sp)
    80006234:	e4aa                	sd	a0,72(sp)
    80006236:	e8ae                	sd	a1,80(sp)
    80006238:	ecb2                	sd	a2,88(sp)
    8000623a:	f0b6                	sd	a3,96(sp)
    8000623c:	f4ba                	sd	a4,104(sp)
    8000623e:	f8be                	sd	a5,112(sp)
    80006240:	fcc2                	sd	a6,120(sp)
    80006242:	e146                	sd	a7,128(sp)
    80006244:	e54a                	sd	s2,136(sp)
    80006246:	e94e                	sd	s3,144(sp)
    80006248:	ed52                	sd	s4,152(sp)
    8000624a:	f156                	sd	s5,160(sp)
    8000624c:	f55a                	sd	s6,168(sp)
    8000624e:	f95e                	sd	s7,176(sp)
    80006250:	fd62                	sd	s8,184(sp)
    80006252:	e1e6                	sd	s9,192(sp)
    80006254:	e5ea                	sd	s10,200(sp)
    80006256:	e9ee                	sd	s11,208(sp)
    80006258:	edf2                	sd	t3,216(sp)
    8000625a:	f1f6                	sd	t4,224(sp)
    8000625c:	f5fa                	sd	t5,232(sp)
    8000625e:	f9fe                	sd	t6,240(sp)
    80006260:	aadfc0ef          	jal	ra,80002d0c <kerneltrap>
    80006264:	6082                	ld	ra,0(sp)
    80006266:	6122                	ld	sp,8(sp)
    80006268:	61c2                	ld	gp,16(sp)
    8000626a:	7282                	ld	t0,32(sp)
    8000626c:	7322                	ld	t1,40(sp)
    8000626e:	73c2                	ld	t2,48(sp)
    80006270:	7462                	ld	s0,56(sp)
    80006272:	6486                	ld	s1,64(sp)
    80006274:	6526                	ld	a0,72(sp)
    80006276:	65c6                	ld	a1,80(sp)
    80006278:	6666                	ld	a2,88(sp)
    8000627a:	7686                	ld	a3,96(sp)
    8000627c:	7726                	ld	a4,104(sp)
    8000627e:	77c6                	ld	a5,112(sp)
    80006280:	7866                	ld	a6,120(sp)
    80006282:	688a                	ld	a7,128(sp)
    80006284:	692a                	ld	s2,136(sp)
    80006286:	69ca                	ld	s3,144(sp)
    80006288:	6a6a                	ld	s4,152(sp)
    8000628a:	7a8a                	ld	s5,160(sp)
    8000628c:	7b2a                	ld	s6,168(sp)
    8000628e:	7bca                	ld	s7,176(sp)
    80006290:	7c6a                	ld	s8,184(sp)
    80006292:	6c8e                	ld	s9,192(sp)
    80006294:	6d2e                	ld	s10,200(sp)
    80006296:	6dce                	ld	s11,208(sp)
    80006298:	6e6e                	ld	t3,216(sp)
    8000629a:	7e8e                	ld	t4,224(sp)
    8000629c:	7f2e                	ld	t5,232(sp)
    8000629e:	7fce                	ld	t6,240(sp)
    800062a0:	6111                	addi	sp,sp,256
    800062a2:	10200073          	sret
    800062a6:	00000013          	nop
    800062aa:	00000013          	nop
    800062ae:	0001                	nop

00000000800062b0 <timervec>:
    800062b0:	34051573          	csrrw	a0,mscratch,a0
    800062b4:	e10c                	sd	a1,0(a0)
    800062b6:	e510                	sd	a2,8(a0)
    800062b8:	e914                	sd	a3,16(a0)
    800062ba:	6d0c                	ld	a1,24(a0)
    800062bc:	7110                	ld	a2,32(a0)
    800062be:	6194                	ld	a3,0(a1)
    800062c0:	96b2                	add	a3,a3,a2
    800062c2:	e194                	sd	a3,0(a1)
    800062c4:	4589                	li	a1,2
    800062c6:	14459073          	csrw	sip,a1
    800062ca:	6914                	ld	a3,16(a0)
    800062cc:	6510                	ld	a2,8(a0)
    800062ce:	610c                	ld	a1,0(a0)
    800062d0:	34051573          	csrrw	a0,mscratch,a0
    800062d4:	30200073          	mret
	...

00000000800062da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062da:	1141                	addi	sp,sp,-16
    800062dc:	e422                	sd	s0,8(sp)
    800062de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062e0:	0c0007b7          	lui	a5,0xc000
    800062e4:	4705                	li	a4,1
    800062e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062e8:	c3d8                	sw	a4,4(a5)
}
    800062ea:	6422                	ld	s0,8(sp)
    800062ec:	0141                	addi	sp,sp,16
    800062ee:	8082                	ret

00000000800062f0 <plicinithart>:

void
plicinithart(void)
{
    800062f0:	1141                	addi	sp,sp,-16
    800062f2:	e406                	sd	ra,8(sp)
    800062f4:	e022                	sd	s0,0(sp)
    800062f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062f8:	ffffb097          	auipc	ra,0xffffb
    800062fc:	6a2080e7          	jalr	1698(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006300:	0085171b          	slliw	a4,a0,0x8
    80006304:	0c0027b7          	lui	a5,0xc002
    80006308:	97ba                	add	a5,a5,a4
    8000630a:	40200713          	li	a4,1026
    8000630e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006312:	00d5151b          	slliw	a0,a0,0xd
    80006316:	0c2017b7          	lui	a5,0xc201
    8000631a:	953e                	add	a0,a0,a5
    8000631c:	00052023          	sw	zero,0(a0)
}
    80006320:	60a2                	ld	ra,8(sp)
    80006322:	6402                	ld	s0,0(sp)
    80006324:	0141                	addi	sp,sp,16
    80006326:	8082                	ret

0000000080006328 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006328:	1141                	addi	sp,sp,-16
    8000632a:	e406                	sd	ra,8(sp)
    8000632c:	e022                	sd	s0,0(sp)
    8000632e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	66a080e7          	jalr	1642(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006338:	00d5179b          	slliw	a5,a0,0xd
    8000633c:	0c201537          	lui	a0,0xc201
    80006340:	953e                	add	a0,a0,a5
  return irq;
}
    80006342:	4148                	lw	a0,4(a0)
    80006344:	60a2                	ld	ra,8(sp)
    80006346:	6402                	ld	s0,0(sp)
    80006348:	0141                	addi	sp,sp,16
    8000634a:	8082                	ret

000000008000634c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000634c:	1101                	addi	sp,sp,-32
    8000634e:	ec06                	sd	ra,24(sp)
    80006350:	e822                	sd	s0,16(sp)
    80006352:	e426                	sd	s1,8(sp)
    80006354:	1000                	addi	s0,sp,32
    80006356:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006358:	ffffb097          	auipc	ra,0xffffb
    8000635c:	642080e7          	jalr	1602(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006360:	00d5151b          	slliw	a0,a0,0xd
    80006364:	0c2017b7          	lui	a5,0xc201
    80006368:	97aa                	add	a5,a5,a0
    8000636a:	c3c4                	sw	s1,4(a5)
}
    8000636c:	60e2                	ld	ra,24(sp)
    8000636e:	6442                	ld	s0,16(sp)
    80006370:	64a2                	ld	s1,8(sp)
    80006372:	6105                	addi	sp,sp,32
    80006374:	8082                	ret

0000000080006376 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006376:	1141                	addi	sp,sp,-16
    80006378:	e406                	sd	ra,8(sp)
    8000637a:	e022                	sd	s0,0(sp)
    8000637c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000637e:	479d                	li	a5,7
    80006380:	04a7cc63          	blt	a5,a0,800063d8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006384:	0001c797          	auipc	a5,0x1c
    80006388:	69c78793          	addi	a5,a5,1692 # 80022a20 <disk>
    8000638c:	97aa                	add	a5,a5,a0
    8000638e:	0187c783          	lbu	a5,24(a5)
    80006392:	ebb9                	bnez	a5,800063e8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006394:	00451613          	slli	a2,a0,0x4
    80006398:	0001c797          	auipc	a5,0x1c
    8000639c:	68878793          	addi	a5,a5,1672 # 80022a20 <disk>
    800063a0:	6394                	ld	a3,0(a5)
    800063a2:	96b2                	add	a3,a3,a2
    800063a4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800063a8:	6398                	ld	a4,0(a5)
    800063aa:	9732                	add	a4,a4,a2
    800063ac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800063b0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800063b4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800063b8:	953e                	add	a0,a0,a5
    800063ba:	4785                	li	a5,1
    800063bc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800063c0:	0001c517          	auipc	a0,0x1c
    800063c4:	67850513          	addi	a0,a0,1656 # 80022a38 <disk+0x18>
    800063c8:	ffffc097          	auipc	ra,0xffffc
    800063cc:	db6080e7          	jalr	-586(ra) # 8000217e <wakeup>
}
    800063d0:	60a2                	ld	ra,8(sp)
    800063d2:	6402                	ld	s0,0(sp)
    800063d4:	0141                	addi	sp,sp,16
    800063d6:	8082                	ret
    panic("free_desc 1");
    800063d8:	00002517          	auipc	a0,0x2
    800063dc:	38850513          	addi	a0,a0,904 # 80008760 <syscalls+0x310>
    800063e0:	ffffa097          	auipc	ra,0xffffa
    800063e4:	164080e7          	jalr	356(ra) # 80000544 <panic>
    panic("free_desc 2");
    800063e8:	00002517          	auipc	a0,0x2
    800063ec:	38850513          	addi	a0,a0,904 # 80008770 <syscalls+0x320>
    800063f0:	ffffa097          	auipc	ra,0xffffa
    800063f4:	154080e7          	jalr	340(ra) # 80000544 <panic>

00000000800063f8 <virtio_disk_init>:
{
    800063f8:	1101                	addi	sp,sp,-32
    800063fa:	ec06                	sd	ra,24(sp)
    800063fc:	e822                	sd	s0,16(sp)
    800063fe:	e426                	sd	s1,8(sp)
    80006400:	e04a                	sd	s2,0(sp)
    80006402:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006404:	00002597          	auipc	a1,0x2
    80006408:	37c58593          	addi	a1,a1,892 # 80008780 <syscalls+0x330>
    8000640c:	0001c517          	auipc	a0,0x1c
    80006410:	73c50513          	addi	a0,a0,1852 # 80022b48 <disk+0x128>
    80006414:	ffffa097          	auipc	ra,0xffffa
    80006418:	746080e7          	jalr	1862(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000641c:	100017b7          	lui	a5,0x10001
    80006420:	4398                	lw	a4,0(a5)
    80006422:	2701                	sext.w	a4,a4
    80006424:	747277b7          	lui	a5,0x74727
    80006428:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000642c:	14f71e63          	bne	a4,a5,80006588 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006430:	100017b7          	lui	a5,0x10001
    80006434:	43dc                	lw	a5,4(a5)
    80006436:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006438:	4709                	li	a4,2
    8000643a:	14e79763          	bne	a5,a4,80006588 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000643e:	100017b7          	lui	a5,0x10001
    80006442:	479c                	lw	a5,8(a5)
    80006444:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006446:	14e79163          	bne	a5,a4,80006588 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000644a:	100017b7          	lui	a5,0x10001
    8000644e:	47d8                	lw	a4,12(a5)
    80006450:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006452:	554d47b7          	lui	a5,0x554d4
    80006456:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000645a:	12f71763          	bne	a4,a5,80006588 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000645e:	100017b7          	lui	a5,0x10001
    80006462:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006466:	4705                	li	a4,1
    80006468:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000646a:	470d                	li	a4,3
    8000646c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000646e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006470:	c7ffe737          	lui	a4,0xc7ffe
    80006474:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbbff>
    80006478:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000647a:	2701                	sext.w	a4,a4
    8000647c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000647e:	472d                	li	a4,11
    80006480:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006482:	0707a903          	lw	s2,112(a5)
    80006486:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006488:	00897793          	andi	a5,s2,8
    8000648c:	10078663          	beqz	a5,80006598 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006490:	100017b7          	lui	a5,0x10001
    80006494:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006498:	43fc                	lw	a5,68(a5)
    8000649a:	2781                	sext.w	a5,a5
    8000649c:	10079663          	bnez	a5,800065a8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064a0:	100017b7          	lui	a5,0x10001
    800064a4:	5bdc                	lw	a5,52(a5)
    800064a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800064a8:	10078863          	beqz	a5,800065b8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    800064ac:	471d                	li	a4,7
    800064ae:	10f77d63          	bgeu	a4,a5,800065c8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    800064b2:	ffffa097          	auipc	ra,0xffffa
    800064b6:	648080e7          	jalr	1608(ra) # 80000afa <kalloc>
    800064ba:	0001c497          	auipc	s1,0x1c
    800064be:	56648493          	addi	s1,s1,1382 # 80022a20 <disk>
    800064c2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800064c4:	ffffa097          	auipc	ra,0xffffa
    800064c8:	636080e7          	jalr	1590(ra) # 80000afa <kalloc>
    800064cc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	62c080e7          	jalr	1580(ra) # 80000afa <kalloc>
    800064d6:	87aa                	mv	a5,a0
    800064d8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064da:	6088                	ld	a0,0(s1)
    800064dc:	cd75                	beqz	a0,800065d8 <virtio_disk_init+0x1e0>
    800064de:	0001c717          	auipc	a4,0x1c
    800064e2:	54a73703          	ld	a4,1354(a4) # 80022a28 <disk+0x8>
    800064e6:	cb6d                	beqz	a4,800065d8 <virtio_disk_init+0x1e0>
    800064e8:	cbe5                	beqz	a5,800065d8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    800064ea:	6605                	lui	a2,0x1
    800064ec:	4581                	li	a1,0
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	7f8080e7          	jalr	2040(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    800064f6:	0001c497          	auipc	s1,0x1c
    800064fa:	52a48493          	addi	s1,s1,1322 # 80022a20 <disk>
    800064fe:	6605                	lui	a2,0x1
    80006500:	4581                	li	a1,0
    80006502:	6488                	ld	a0,8(s1)
    80006504:	ffffa097          	auipc	ra,0xffffa
    80006508:	7e2080e7          	jalr	2018(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000650c:	6605                	lui	a2,0x1
    8000650e:	4581                	li	a1,0
    80006510:	6888                	ld	a0,16(s1)
    80006512:	ffffa097          	auipc	ra,0xffffa
    80006516:	7d4080e7          	jalr	2004(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000651a:	100017b7          	lui	a5,0x10001
    8000651e:	4721                	li	a4,8
    80006520:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006522:	4098                	lw	a4,0(s1)
    80006524:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006528:	40d8                	lw	a4,4(s1)
    8000652a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000652e:	6498                	ld	a4,8(s1)
    80006530:	0007069b          	sext.w	a3,a4
    80006534:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006538:	9701                	srai	a4,a4,0x20
    8000653a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000653e:	6898                	ld	a4,16(s1)
    80006540:	0007069b          	sext.w	a3,a4
    80006544:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006548:	9701                	srai	a4,a4,0x20
    8000654a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000654e:	4685                	li	a3,1
    80006550:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006552:	4705                	li	a4,1
    80006554:	00d48c23          	sb	a3,24(s1)
    80006558:	00e48ca3          	sb	a4,25(s1)
    8000655c:	00e48d23          	sb	a4,26(s1)
    80006560:	00e48da3          	sb	a4,27(s1)
    80006564:	00e48e23          	sb	a4,28(s1)
    80006568:	00e48ea3          	sb	a4,29(s1)
    8000656c:	00e48f23          	sb	a4,30(s1)
    80006570:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006574:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006578:	0727a823          	sw	s2,112(a5)
}
    8000657c:	60e2                	ld	ra,24(sp)
    8000657e:	6442                	ld	s0,16(sp)
    80006580:	64a2                	ld	s1,8(sp)
    80006582:	6902                	ld	s2,0(sp)
    80006584:	6105                	addi	sp,sp,32
    80006586:	8082                	ret
    panic("could not find virtio disk");
    80006588:	00002517          	auipc	a0,0x2
    8000658c:	20850513          	addi	a0,a0,520 # 80008790 <syscalls+0x340>
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	fb4080e7          	jalr	-76(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006598:	00002517          	auipc	a0,0x2
    8000659c:	21850513          	addi	a0,a0,536 # 800087b0 <syscalls+0x360>
    800065a0:	ffffa097          	auipc	ra,0xffffa
    800065a4:	fa4080e7          	jalr	-92(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    800065a8:	00002517          	auipc	a0,0x2
    800065ac:	22850513          	addi	a0,a0,552 # 800087d0 <syscalls+0x380>
    800065b0:	ffffa097          	auipc	ra,0xffffa
    800065b4:	f94080e7          	jalr	-108(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800065b8:	00002517          	auipc	a0,0x2
    800065bc:	23850513          	addi	a0,a0,568 # 800087f0 <syscalls+0x3a0>
    800065c0:	ffffa097          	auipc	ra,0xffffa
    800065c4:	f84080e7          	jalr	-124(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800065c8:	00002517          	auipc	a0,0x2
    800065cc:	24850513          	addi	a0,a0,584 # 80008810 <syscalls+0x3c0>
    800065d0:	ffffa097          	auipc	ra,0xffffa
    800065d4:	f74080e7          	jalr	-140(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800065d8:	00002517          	auipc	a0,0x2
    800065dc:	25850513          	addi	a0,a0,600 # 80008830 <syscalls+0x3e0>
    800065e0:	ffffa097          	auipc	ra,0xffffa
    800065e4:	f64080e7          	jalr	-156(ra) # 80000544 <panic>

00000000800065e8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065e8:	7159                	addi	sp,sp,-112
    800065ea:	f486                	sd	ra,104(sp)
    800065ec:	f0a2                	sd	s0,96(sp)
    800065ee:	eca6                	sd	s1,88(sp)
    800065f0:	e8ca                	sd	s2,80(sp)
    800065f2:	e4ce                	sd	s3,72(sp)
    800065f4:	e0d2                	sd	s4,64(sp)
    800065f6:	fc56                	sd	s5,56(sp)
    800065f8:	f85a                	sd	s6,48(sp)
    800065fa:	f45e                	sd	s7,40(sp)
    800065fc:	f062                	sd	s8,32(sp)
    800065fe:	ec66                	sd	s9,24(sp)
    80006600:	e86a                	sd	s10,16(sp)
    80006602:	1880                	addi	s0,sp,112
    80006604:	892a                	mv	s2,a0
    80006606:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006608:	00c52c83          	lw	s9,12(a0)
    8000660c:	001c9c9b          	slliw	s9,s9,0x1
    80006610:	1c82                	slli	s9,s9,0x20
    80006612:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006616:	0001c517          	auipc	a0,0x1c
    8000661a:	53250513          	addi	a0,a0,1330 # 80022b48 <disk+0x128>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	5cc080e7          	jalr	1484(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006626:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006628:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000662a:	0001cb17          	auipc	s6,0x1c
    8000662e:	3f6b0b13          	addi	s6,s6,1014 # 80022a20 <disk>
  for(int i = 0; i < 3; i++){
    80006632:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006634:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006636:	0001cc17          	auipc	s8,0x1c
    8000663a:	512c0c13          	addi	s8,s8,1298 # 80022b48 <disk+0x128>
    8000663e:	a8b5                	j	800066ba <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006640:	00fb06b3          	add	a3,s6,a5
    80006644:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006648:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000664a:	0207c563          	bltz	a5,80006674 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000664e:	2485                	addiw	s1,s1,1
    80006650:	0711                	addi	a4,a4,4
    80006652:	1f548a63          	beq	s1,s5,80006846 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006656:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006658:	0001c697          	auipc	a3,0x1c
    8000665c:	3c868693          	addi	a3,a3,968 # 80022a20 <disk>
    80006660:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006662:	0186c583          	lbu	a1,24(a3)
    80006666:	fde9                	bnez	a1,80006640 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006668:	2785                	addiw	a5,a5,1
    8000666a:	0685                	addi	a3,a3,1
    8000666c:	ff779be3          	bne	a5,s7,80006662 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006670:	57fd                	li	a5,-1
    80006672:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006674:	02905a63          	blez	s1,800066a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006678:	f9042503          	lw	a0,-112(s0)
    8000667c:	00000097          	auipc	ra,0x0
    80006680:	cfa080e7          	jalr	-774(ra) # 80006376 <free_desc>
      for(int j = 0; j < i; j++)
    80006684:	4785                	li	a5,1
    80006686:	0297d163          	bge	a5,s1,800066a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000668a:	f9442503          	lw	a0,-108(s0)
    8000668e:	00000097          	auipc	ra,0x0
    80006692:	ce8080e7          	jalr	-792(ra) # 80006376 <free_desc>
      for(int j = 0; j < i; j++)
    80006696:	4789                	li	a5,2
    80006698:	0097d863          	bge	a5,s1,800066a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000669c:	f9842503          	lw	a0,-104(s0)
    800066a0:	00000097          	auipc	ra,0x0
    800066a4:	cd6080e7          	jalr	-810(ra) # 80006376 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066a8:	85e2                	mv	a1,s8
    800066aa:	0001c517          	auipc	a0,0x1c
    800066ae:	38e50513          	addi	a0,a0,910 # 80022a38 <disk+0x18>
    800066b2:	ffffc097          	auipc	ra,0xffffc
    800066b6:	a68080e7          	jalr	-1432(ra) # 8000211a <sleep>
  for(int i = 0; i < 3; i++){
    800066ba:	f9040713          	addi	a4,s0,-112
    800066be:	84ce                	mv	s1,s3
    800066c0:	bf59                	j	80006656 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066c2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800066c6:	00479693          	slli	a3,a5,0x4
    800066ca:	0001c797          	auipc	a5,0x1c
    800066ce:	35678793          	addi	a5,a5,854 # 80022a20 <disk>
    800066d2:	97b6                	add	a5,a5,a3
    800066d4:	4685                	li	a3,1
    800066d6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066d8:	0001c597          	auipc	a1,0x1c
    800066dc:	34858593          	addi	a1,a1,840 # 80022a20 <disk>
    800066e0:	00a60793          	addi	a5,a2,10
    800066e4:	0792                	slli	a5,a5,0x4
    800066e6:	97ae                	add	a5,a5,a1
    800066e8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800066ec:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066f0:	f6070693          	addi	a3,a4,-160
    800066f4:	619c                	ld	a5,0(a1)
    800066f6:	97b6                	add	a5,a5,a3
    800066f8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066fa:	6188                	ld	a0,0(a1)
    800066fc:	96aa                	add	a3,a3,a0
    800066fe:	47c1                	li	a5,16
    80006700:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006702:	4785                	li	a5,1
    80006704:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006708:	f9442783          	lw	a5,-108(s0)
    8000670c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006710:	0792                	slli	a5,a5,0x4
    80006712:	953e                	add	a0,a0,a5
    80006714:	05890693          	addi	a3,s2,88
    80006718:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000671a:	6188                	ld	a0,0(a1)
    8000671c:	97aa                	add	a5,a5,a0
    8000671e:	40000693          	li	a3,1024
    80006722:	c794                	sw	a3,8(a5)
  if(write)
    80006724:	100d0d63          	beqz	s10,8000683e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006728:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000672c:	00c7d683          	lhu	a3,12(a5)
    80006730:	0016e693          	ori	a3,a3,1
    80006734:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006738:	f9842583          	lw	a1,-104(s0)
    8000673c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006740:	0001c697          	auipc	a3,0x1c
    80006744:	2e068693          	addi	a3,a3,736 # 80022a20 <disk>
    80006748:	00260793          	addi	a5,a2,2
    8000674c:	0792                	slli	a5,a5,0x4
    8000674e:	97b6                	add	a5,a5,a3
    80006750:	587d                	li	a6,-1
    80006752:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006756:	0592                	slli	a1,a1,0x4
    80006758:	952e                	add	a0,a0,a1
    8000675a:	f9070713          	addi	a4,a4,-112
    8000675e:	9736                	add	a4,a4,a3
    80006760:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006762:	6298                	ld	a4,0(a3)
    80006764:	972e                	add	a4,a4,a1
    80006766:	4585                	li	a1,1
    80006768:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000676a:	4509                	li	a0,2
    8000676c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006770:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006774:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006778:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000677c:	6698                	ld	a4,8(a3)
    8000677e:	00275783          	lhu	a5,2(a4)
    80006782:	8b9d                	andi	a5,a5,7
    80006784:	0786                	slli	a5,a5,0x1
    80006786:	97ba                	add	a5,a5,a4
    80006788:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000678c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006790:	6698                	ld	a4,8(a3)
    80006792:	00275783          	lhu	a5,2(a4)
    80006796:	2785                	addiw	a5,a5,1
    80006798:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000679c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067a0:	100017b7          	lui	a5,0x10001
    800067a4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067a8:	00492703          	lw	a4,4(s2)
    800067ac:	4785                	li	a5,1
    800067ae:	02f71163          	bne	a4,a5,800067d0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800067b2:	0001c997          	auipc	s3,0x1c
    800067b6:	39698993          	addi	s3,s3,918 # 80022b48 <disk+0x128>
  while(b->disk == 1) {
    800067ba:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067bc:	85ce                	mv	a1,s3
    800067be:	854a                	mv	a0,s2
    800067c0:	ffffc097          	auipc	ra,0xffffc
    800067c4:	95a080e7          	jalr	-1702(ra) # 8000211a <sleep>
  while(b->disk == 1) {
    800067c8:	00492783          	lw	a5,4(s2)
    800067cc:	fe9788e3          	beq	a5,s1,800067bc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800067d0:	f9042903          	lw	s2,-112(s0)
    800067d4:	00290793          	addi	a5,s2,2
    800067d8:	00479713          	slli	a4,a5,0x4
    800067dc:	0001c797          	auipc	a5,0x1c
    800067e0:	24478793          	addi	a5,a5,580 # 80022a20 <disk>
    800067e4:	97ba                	add	a5,a5,a4
    800067e6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800067ea:	0001c997          	auipc	s3,0x1c
    800067ee:	23698993          	addi	s3,s3,566 # 80022a20 <disk>
    800067f2:	00491713          	slli	a4,s2,0x4
    800067f6:	0009b783          	ld	a5,0(s3)
    800067fa:	97ba                	add	a5,a5,a4
    800067fc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006800:	854a                	mv	a0,s2
    80006802:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006806:	00000097          	auipc	ra,0x0
    8000680a:	b70080e7          	jalr	-1168(ra) # 80006376 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000680e:	8885                	andi	s1,s1,1
    80006810:	f0ed                	bnez	s1,800067f2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006812:	0001c517          	auipc	a0,0x1c
    80006816:	33650513          	addi	a0,a0,822 # 80022b48 <disk+0x128>
    8000681a:	ffffa097          	auipc	ra,0xffffa
    8000681e:	484080e7          	jalr	1156(ra) # 80000c9e <release>
}
    80006822:	70a6                	ld	ra,104(sp)
    80006824:	7406                	ld	s0,96(sp)
    80006826:	64e6                	ld	s1,88(sp)
    80006828:	6946                	ld	s2,80(sp)
    8000682a:	69a6                	ld	s3,72(sp)
    8000682c:	6a06                	ld	s4,64(sp)
    8000682e:	7ae2                	ld	s5,56(sp)
    80006830:	7b42                	ld	s6,48(sp)
    80006832:	7ba2                	ld	s7,40(sp)
    80006834:	7c02                	ld	s8,32(sp)
    80006836:	6ce2                	ld	s9,24(sp)
    80006838:	6d42                	ld	s10,16(sp)
    8000683a:	6165                	addi	sp,sp,112
    8000683c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000683e:	4689                	li	a3,2
    80006840:	00d79623          	sh	a3,12(a5)
    80006844:	b5e5                	j	8000672c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006846:	f9042603          	lw	a2,-112(s0)
    8000684a:	00a60713          	addi	a4,a2,10
    8000684e:	0712                	slli	a4,a4,0x4
    80006850:	0001c517          	auipc	a0,0x1c
    80006854:	1d850513          	addi	a0,a0,472 # 80022a28 <disk+0x8>
    80006858:	953a                	add	a0,a0,a4
  if(write)
    8000685a:	e60d14e3          	bnez	s10,800066c2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000685e:	00a60793          	addi	a5,a2,10
    80006862:	00479693          	slli	a3,a5,0x4
    80006866:	0001c797          	auipc	a5,0x1c
    8000686a:	1ba78793          	addi	a5,a5,442 # 80022a20 <disk>
    8000686e:	97b6                	add	a5,a5,a3
    80006870:	0007a423          	sw	zero,8(a5)
    80006874:	b595                	j	800066d8 <virtio_disk_rw+0xf0>

0000000080006876 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006876:	1101                	addi	sp,sp,-32
    80006878:	ec06                	sd	ra,24(sp)
    8000687a:	e822                	sd	s0,16(sp)
    8000687c:	e426                	sd	s1,8(sp)
    8000687e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006880:	0001c497          	auipc	s1,0x1c
    80006884:	1a048493          	addi	s1,s1,416 # 80022a20 <disk>
    80006888:	0001c517          	auipc	a0,0x1c
    8000688c:	2c050513          	addi	a0,a0,704 # 80022b48 <disk+0x128>
    80006890:	ffffa097          	auipc	ra,0xffffa
    80006894:	35a080e7          	jalr	858(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006898:	10001737          	lui	a4,0x10001
    8000689c:	533c                	lw	a5,96(a4)
    8000689e:	8b8d                	andi	a5,a5,3
    800068a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068a6:	689c                	ld	a5,16(s1)
    800068a8:	0204d703          	lhu	a4,32(s1)
    800068ac:	0027d783          	lhu	a5,2(a5)
    800068b0:	04f70863          	beq	a4,a5,80006900 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800068b4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068b8:	6898                	ld	a4,16(s1)
    800068ba:	0204d783          	lhu	a5,32(s1)
    800068be:	8b9d                	andi	a5,a5,7
    800068c0:	078e                	slli	a5,a5,0x3
    800068c2:	97ba                	add	a5,a5,a4
    800068c4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068c6:	00278713          	addi	a4,a5,2
    800068ca:	0712                	slli	a4,a4,0x4
    800068cc:	9726                	add	a4,a4,s1
    800068ce:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800068d2:	e721                	bnez	a4,8000691a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068d4:	0789                	addi	a5,a5,2
    800068d6:	0792                	slli	a5,a5,0x4
    800068d8:	97a6                	add	a5,a5,s1
    800068da:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800068dc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068e0:	ffffc097          	auipc	ra,0xffffc
    800068e4:	89e080e7          	jalr	-1890(ra) # 8000217e <wakeup>

    disk.used_idx += 1;
    800068e8:	0204d783          	lhu	a5,32(s1)
    800068ec:	2785                	addiw	a5,a5,1
    800068ee:	17c2                	slli	a5,a5,0x30
    800068f0:	93c1                	srli	a5,a5,0x30
    800068f2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068f6:	6898                	ld	a4,16(s1)
    800068f8:	00275703          	lhu	a4,2(a4)
    800068fc:	faf71ce3          	bne	a4,a5,800068b4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006900:	0001c517          	auipc	a0,0x1c
    80006904:	24850513          	addi	a0,a0,584 # 80022b48 <disk+0x128>
    80006908:	ffffa097          	auipc	ra,0xffffa
    8000690c:	396080e7          	jalr	918(ra) # 80000c9e <release>
}
    80006910:	60e2                	ld	ra,24(sp)
    80006912:	6442                	ld	s0,16(sp)
    80006914:	64a2                	ld	s1,8(sp)
    80006916:	6105                	addi	sp,sp,32
    80006918:	8082                	ret
      panic("virtio_disk_intr status");
    8000691a:	00002517          	auipc	a0,0x2
    8000691e:	f2e50513          	addi	a0,a0,-210 # 80008848 <syscalls+0x3f8>
    80006922:	ffffa097          	auipc	ra,0xffffa
    80006926:	c22080e7          	jalr	-990(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
