
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a4010113          	addi	sp,sp,-1472 # 80008a40 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	8000008e <start>

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
    8000001e:	e406                	sd	ra,8(sp)
    80000020:	e022                	sd	s0,0(sp)
    80000022:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000024:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000028:	2781                	sext.w	a5,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037961b          	slliw	a2,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	963a                	add	a2,a2,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f46b7          	lui	a3,0xf4
    80000040:	24068693          	addi	a3,a3,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9736                	add	a4,a4,a3
    80000046:	e218                	sd	a4,0(a2)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00279713          	slli	a4,a5,0x2
    8000004c:	973e                	add	a4,a4,a5
    8000004e:	070e                	slli	a4,a4,0x3
    80000050:	00009797          	auipc	a5,0x9
    80000054:	8b078793          	addi	a5,a5,-1872 # 80008900 <timer_scratch>
    80000058:	97ba                	add	a5,a5,a4
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef90                	sd	a2,24(a5)
  scratch[4] = interval;
    8000005c:	f394                	sd	a3,32(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	e5e78793          	addi	a5,a5,-418 # 80005ec0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	60a2                	ld	ra,8(sp)
    80000088:	6402                	ld	s0,0(sp)
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca8f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e8a78793          	addi	a5,a5,-374 # 80000f38 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
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
    80000102:	711d                	addi	sp,sp,-96
    80000104:	ec86                	sd	ra,88(sp)
    80000106:	e8a2                	sd	s0,80(sp)
    80000108:	e0ca                	sd	s2,64(sp)
    8000010a:	1080                	addi	s0,sp,96
  int i;

  for(i = 0; i < n; i++){
    8000010c:	04c05c63          	blez	a2,80000164 <consolewrite+0x62>
    80000110:	e4a6                	sd	s1,72(sp)
    80000112:	fc4e                	sd	s3,56(sp)
    80000114:	f852                	sd	s4,48(sp)
    80000116:	f456                	sd	s5,40(sp)
    80000118:	f05a                	sd	s6,32(sp)
    8000011a:	ec5e                	sd	s7,24(sp)
    8000011c:	8a2a                	mv	s4,a0
    8000011e:	84ae                	mv	s1,a1
    80000120:	89b2                	mv	s3,a2
    80000122:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000124:	faf40b93          	addi	s7,s0,-81
    80000128:	4b05                	li	s6,1
    8000012a:	5afd                	li	s5,-1
    8000012c:	86da                	mv	a3,s6
    8000012e:	8626                	mv	a2,s1
    80000130:	85d2                	mv	a1,s4
    80000132:	855e                	mv	a0,s7
    80000134:	00002097          	auipc	ra,0x2
    80000138:	47e080e7          	jalr	1150(ra) # 800025b2 <either_copyin>
    8000013c:	03550663          	beq	a0,s5,80000168 <consolewrite+0x66>
      break;
    uartputc(c);
    80000140:	faf44503          	lbu	a0,-81(s0)
    80000144:	00000097          	auipc	ra,0x0
    80000148:	7da080e7          	jalr	2010(ra) # 8000091e <uartputc>
  for(i = 0; i < n; i++){
    8000014c:	2905                	addiw	s2,s2,1
    8000014e:	0485                	addi	s1,s1,1
    80000150:	fd299ee3          	bne	s3,s2,8000012c <consolewrite+0x2a>
    80000154:	894e                	mv	s2,s3
    80000156:	64a6                	ld	s1,72(sp)
    80000158:	79e2                	ld	s3,56(sp)
    8000015a:	7a42                	ld	s4,48(sp)
    8000015c:	7aa2                	ld	s5,40(sp)
    8000015e:	7b02                	ld	s6,32(sp)
    80000160:	6be2                	ld	s7,24(sp)
    80000162:	a809                	j	80000174 <consolewrite+0x72>
    80000164:	4901                	li	s2,0
    80000166:	a039                	j	80000174 <consolewrite+0x72>
    80000168:	64a6                	ld	s1,72(sp)
    8000016a:	79e2                	ld	s3,56(sp)
    8000016c:	7a42                	ld	s4,48(sp)
    8000016e:	7aa2                	ld	s5,40(sp)
    80000170:	7b02                	ld	s6,32(sp)
    80000172:	6be2                	ld	s7,24(sp)
  }

  return i;
}
    80000174:	854a                	mv	a0,s2
    80000176:	60e6                	ld	ra,88(sp)
    80000178:	6446                	ld	s0,80(sp)
    8000017a:	6906                	ld	s2,64(sp)
    8000017c:	6125                	addi	sp,sp,96
    8000017e:	8082                	ret

0000000080000180 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000180:	711d                	addi	sp,sp,-96
    80000182:	ec86                	sd	ra,88(sp)
    80000184:	e8a2                	sd	s0,80(sp)
    80000186:	e4a6                	sd	s1,72(sp)
    80000188:	e0ca                	sd	s2,64(sp)
    8000018a:	fc4e                	sd	s3,56(sp)
    8000018c:	f852                	sd	s4,48(sp)
    8000018e:	f456                	sd	s5,40(sp)
    80000190:	f05a                	sd	s6,32(sp)
    80000192:	1080                	addi	s0,sp,96
    80000194:	8aaa                	mv	s5,a0
    80000196:	8a2e                	mv	s4,a1
    80000198:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019a:	8b32                	mv	s6,a2
  acquire(&cons.lock);
    8000019c:	00011517          	auipc	a0,0x11
    800001a0:	8a450513          	addi	a0,a0,-1884 # 80010a40 <cons>
    800001a4:	00001097          	auipc	ra,0x1
    800001a8:	ae2080e7          	jalr	-1310(ra) # 80000c86 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ac:	00011497          	auipc	s1,0x11
    800001b0:	89448493          	addi	s1,s1,-1900 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b4:	00011917          	auipc	s2,0x11
    800001b8:	92490913          	addi	s2,s2,-1756 # 80010ad8 <cons+0x98>
  while(n > 0){
    800001bc:	0d305563          	blez	s3,80000286 <consoleread+0x106>
    while(cons.r == cons.w){
    800001c0:	0984a783          	lw	a5,152(s1)
    800001c4:	09c4a703          	lw	a4,156(s1)
    800001c8:	0af71a63          	bne	a4,a5,8000027c <consoleread+0xfc>
      if(killed(myproc())){
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	8e4080e7          	jalr	-1820(ra) # 80001ab0 <myproc>
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	22e080e7          	jalr	558(ra) # 80002402 <killed>
    800001dc:	e52d                	bnez	a0,80000246 <consoleread+0xc6>
      sleep(&cons.r, &cons.lock);
    800001de:	85a6                	mv	a1,s1
    800001e0:	854a                	mv	a0,s2
    800001e2:	00002097          	auipc	ra,0x2
    800001e6:	f78080e7          	jalr	-136(ra) # 8000215a <sleep>
    while(cons.r == cons.w){
    800001ea:	0984a783          	lw	a5,152(s1)
    800001ee:	09c4a703          	lw	a4,156(s1)
    800001f2:	fcf70de3          	beq	a4,a5,800001cc <consoleread+0x4c>
    800001f6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001f8:	00011717          	auipc	a4,0x11
    800001fc:	84870713          	addi	a4,a4,-1976 # 80010a40 <cons>
    80000200:	0017869b          	addiw	a3,a5,1
    80000204:	08d72c23          	sw	a3,152(a4)
    80000208:	07f7f693          	andi	a3,a5,127
    8000020c:	9736                	add	a4,a4,a3
    8000020e:	01874703          	lbu	a4,24(a4)
    80000212:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000216:	4691                	li	a3,4
    80000218:	04db8a63          	beq	s7,a3,8000026c <consoleread+0xec>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    8000021c:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000220:	4685                	li	a3,1
    80000222:	faf40613          	addi	a2,s0,-81
    80000226:	85d2                	mv	a1,s4
    80000228:	8556                	mv	a0,s5
    8000022a:	00002097          	auipc	ra,0x2
    8000022e:	332080e7          	jalr	818(ra) # 8000255c <either_copyout>
    80000232:	57fd                	li	a5,-1
    80000234:	04f50863          	beq	a0,a5,80000284 <consoleread+0x104>
      break;

    dst++;
    80000238:	0a05                	addi	s4,s4,1
    --n;
    8000023a:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    8000023c:	47a9                	li	a5,10
    8000023e:	04fb8f63          	beq	s7,a5,8000029c <consoleread+0x11c>
    80000242:	6be2                	ld	s7,24(sp)
    80000244:	bfa5                	j	800001bc <consoleread+0x3c>
        release(&cons.lock);
    80000246:	00010517          	auipc	a0,0x10
    8000024a:	7fa50513          	addi	a0,a0,2042 # 80010a40 <cons>
    8000024e:	00001097          	auipc	ra,0x1
    80000252:	ae8080e7          	jalr	-1304(ra) # 80000d36 <release>
        return -1;
    80000256:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000258:	60e6                	ld	ra,88(sp)
    8000025a:	6446                	ld	s0,80(sp)
    8000025c:	64a6                	ld	s1,72(sp)
    8000025e:	6906                	ld	s2,64(sp)
    80000260:	79e2                	ld	s3,56(sp)
    80000262:	7a42                	ld	s4,48(sp)
    80000264:	7aa2                	ld	s5,40(sp)
    80000266:	7b02                	ld	s6,32(sp)
    80000268:	6125                	addi	sp,sp,96
    8000026a:	8082                	ret
      if(n < target){
    8000026c:	0169fa63          	bgeu	s3,s6,80000280 <consoleread+0x100>
        cons.r--;
    80000270:	00011717          	auipc	a4,0x11
    80000274:	86f72423          	sw	a5,-1944(a4) # 80010ad8 <cons+0x98>
    80000278:	6be2                	ld	s7,24(sp)
    8000027a:	a031                	j	80000286 <consoleread+0x106>
    8000027c:	ec5e                	sd	s7,24(sp)
    8000027e:	bfad                	j	800001f8 <consoleread+0x78>
    80000280:	6be2                	ld	s7,24(sp)
    80000282:	a011                	j	80000286 <consoleread+0x106>
    80000284:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000286:	00010517          	auipc	a0,0x10
    8000028a:	7ba50513          	addi	a0,a0,1978 # 80010a40 <cons>
    8000028e:	00001097          	auipc	ra,0x1
    80000292:	aa8080e7          	jalr	-1368(ra) # 80000d36 <release>
  return target - n;
    80000296:	413b053b          	subw	a0,s6,s3
    8000029a:	bf7d                	j	80000258 <consoleread+0xd8>
    8000029c:	6be2                	ld	s7,24(sp)
    8000029e:	b7e5                	j	80000286 <consoleread+0x106>

00000000800002a0 <consputc>:
{
    800002a0:	1141                	addi	sp,sp,-16
    800002a2:	e406                	sd	ra,8(sp)
    800002a4:	e022                	sd	s0,0(sp)
    800002a6:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    800002a8:	10000793          	li	a5,256
    800002ac:	00f50a63          	beq	a0,a5,800002c0 <consputc+0x20>
    uartputc_sync(c);
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	590080e7          	jalr	1424(ra) # 80000840 <uartputc_sync>
}
    800002b8:	60a2                	ld	ra,8(sp)
    800002ba:	6402                	ld	s0,0(sp)
    800002bc:	0141                	addi	sp,sp,16
    800002be:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002c0:	4521                	li	a0,8
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	57e080e7          	jalr	1406(ra) # 80000840 <uartputc_sync>
    800002ca:	02000513          	li	a0,32
    800002ce:	00000097          	auipc	ra,0x0
    800002d2:	572080e7          	jalr	1394(ra) # 80000840 <uartputc_sync>
    800002d6:	4521                	li	a0,8
    800002d8:	00000097          	auipc	ra,0x0
    800002dc:	568080e7          	jalr	1384(ra) # 80000840 <uartputc_sync>
    800002e0:	bfe1                	j	800002b8 <consputc+0x18>

00000000800002e2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002e2:	7179                	addi	sp,sp,-48
    800002e4:	f406                	sd	ra,40(sp)
    800002e6:	f022                	sd	s0,32(sp)
    800002e8:	ec26                	sd	s1,24(sp)
    800002ea:	1800                	addi	s0,sp,48
    800002ec:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002ee:	00010517          	auipc	a0,0x10
    800002f2:	75250513          	addi	a0,a0,1874 # 80010a40 <cons>
    800002f6:	00001097          	auipc	ra,0x1
    800002fa:	990080e7          	jalr	-1648(ra) # 80000c86 <acquire>

  switch(c){
    800002fe:	47d5                	li	a5,21
    80000300:	0af48463          	beq	s1,a5,800003a8 <consoleintr+0xc6>
    80000304:	0297c963          	blt	a5,s1,80000336 <consoleintr+0x54>
    80000308:	47a1                	li	a5,8
    8000030a:	10f48063          	beq	s1,a5,8000040a <consoleintr+0x128>
    8000030e:	47c1                	li	a5,16
    80000310:	12f49363          	bne	s1,a5,80000436 <consoleintr+0x154>
  case C('P'):  // Print process list.
    procdump();
    80000314:	00002097          	auipc	ra,0x2
    80000318:	2f4080e7          	jalr	756(ra) # 80002608 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000031c:	00010517          	auipc	a0,0x10
    80000320:	72450513          	addi	a0,a0,1828 # 80010a40 <cons>
    80000324:	00001097          	auipc	ra,0x1
    80000328:	a12080e7          	jalr	-1518(ra) # 80000d36 <release>
}
    8000032c:	70a2                	ld	ra,40(sp)
    8000032e:	7402                	ld	s0,32(sp)
    80000330:	64e2                	ld	s1,24(sp)
    80000332:	6145                	addi	sp,sp,48
    80000334:	8082                	ret
  switch(c){
    80000336:	07f00793          	li	a5,127
    8000033a:	0cf48863          	beq	s1,a5,8000040a <consoleintr+0x128>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000033e:	00010717          	auipc	a4,0x10
    80000342:	70270713          	addi	a4,a4,1794 # 80010a40 <cons>
    80000346:	0a072783          	lw	a5,160(a4)
    8000034a:	09872703          	lw	a4,152(a4)
    8000034e:	9f99                	subw	a5,a5,a4
    80000350:	07f00713          	li	a4,127
    80000354:	fcf764e3          	bltu	a4,a5,8000031c <consoleintr+0x3a>
      c = (c == '\r') ? '\n' : c;
    80000358:	47b5                	li	a5,13
    8000035a:	0ef48163          	beq	s1,a5,8000043c <consoleintr+0x15a>
      consputc(c);
    8000035e:	8526                	mv	a0,s1
    80000360:	00000097          	auipc	ra,0x0
    80000364:	f40080e7          	jalr	-192(ra) # 800002a0 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000368:	00010797          	auipc	a5,0x10
    8000036c:	6d878793          	addi	a5,a5,1752 # 80010a40 <cons>
    80000370:	0a07a683          	lw	a3,160(a5)
    80000374:	0016871b          	addiw	a4,a3,1
    80000378:	863a                	mv	a2,a4
    8000037a:	0ae7a023          	sw	a4,160(a5)
    8000037e:	07f6f693          	andi	a3,a3,127
    80000382:	97b6                	add	a5,a5,a3
    80000384:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000388:	47a9                	li	a5,10
    8000038a:	0cf48f63          	beq	s1,a5,80000468 <consoleintr+0x186>
    8000038e:	4791                	li	a5,4
    80000390:	0cf48c63          	beq	s1,a5,80000468 <consoleintr+0x186>
    80000394:	00010797          	auipc	a5,0x10
    80000398:	7447a783          	lw	a5,1860(a5) # 80010ad8 <cons+0x98>
    8000039c:	9f1d                	subw	a4,a4,a5
    8000039e:	08000793          	li	a5,128
    800003a2:	f6f71de3          	bne	a4,a5,8000031c <consoleintr+0x3a>
    800003a6:	a0c9                	j	80000468 <consoleintr+0x186>
    800003a8:	e84a                	sd	s2,16(sp)
    800003aa:	e44e                	sd	s3,8(sp)
    while(cons.e != cons.w &&
    800003ac:	00010717          	auipc	a4,0x10
    800003b0:	69470713          	addi	a4,a4,1684 # 80010a40 <cons>
    800003b4:	0a072783          	lw	a5,160(a4)
    800003b8:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003bc:	00010497          	auipc	s1,0x10
    800003c0:	68448493          	addi	s1,s1,1668 # 80010a40 <cons>
    while(cons.e != cons.w &&
    800003c4:	4929                	li	s2,10
      consputc(BACKSPACE);
    800003c6:	10000993          	li	s3,256
    while(cons.e != cons.w &&
    800003ca:	02f70a63          	beq	a4,a5,800003fe <consoleintr+0x11c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ce:	37fd                	addiw	a5,a5,-1
    800003d0:	07f7f713          	andi	a4,a5,127
    800003d4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003d6:	01874703          	lbu	a4,24(a4)
    800003da:	03270563          	beq	a4,s2,80000404 <consoleintr+0x122>
      cons.e--;
    800003de:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003e2:	854e                	mv	a0,s3
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	ebc080e7          	jalr	-324(ra) # 800002a0 <consputc>
    while(cons.e != cons.w &&
    800003ec:	0a04a783          	lw	a5,160(s1)
    800003f0:	09c4a703          	lw	a4,156(s1)
    800003f4:	fcf71de3          	bne	a4,a5,800003ce <consoleintr+0xec>
    800003f8:	6942                	ld	s2,16(sp)
    800003fa:	69a2                	ld	s3,8(sp)
    800003fc:	b705                	j	8000031c <consoleintr+0x3a>
    800003fe:	6942                	ld	s2,16(sp)
    80000400:	69a2                	ld	s3,8(sp)
    80000402:	bf29                	j	8000031c <consoleintr+0x3a>
    80000404:	6942                	ld	s2,16(sp)
    80000406:	69a2                	ld	s3,8(sp)
    80000408:	bf11                	j	8000031c <consoleintr+0x3a>
    if(cons.e != cons.w){
    8000040a:	00010717          	auipc	a4,0x10
    8000040e:	63670713          	addi	a4,a4,1590 # 80010a40 <cons>
    80000412:	0a072783          	lw	a5,160(a4)
    80000416:	09c72703          	lw	a4,156(a4)
    8000041a:	f0f701e3          	beq	a4,a5,8000031c <consoleintr+0x3a>
      cons.e--;
    8000041e:	37fd                	addiw	a5,a5,-1
    80000420:	00010717          	auipc	a4,0x10
    80000424:	6cf72023          	sw	a5,1728(a4) # 80010ae0 <cons+0xa0>
      consputc(BACKSPACE);
    80000428:	10000513          	li	a0,256
    8000042c:	00000097          	auipc	ra,0x0
    80000430:	e74080e7          	jalr	-396(ra) # 800002a0 <consputc>
    80000434:	b5e5                	j	8000031c <consoleintr+0x3a>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000436:	ee0483e3          	beqz	s1,8000031c <consoleintr+0x3a>
    8000043a:	b711                	j	8000033e <consoleintr+0x5c>
      consputc(c);
    8000043c:	4529                	li	a0,10
    8000043e:	00000097          	auipc	ra,0x0
    80000442:	e62080e7          	jalr	-414(ra) # 800002a0 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000446:	00010797          	auipc	a5,0x10
    8000044a:	5fa78793          	addi	a5,a5,1530 # 80010a40 <cons>
    8000044e:	0a07a703          	lw	a4,160(a5)
    80000452:	0017069b          	addiw	a3,a4,1
    80000456:	8636                	mv	a2,a3
    80000458:	0ad7a023          	sw	a3,160(a5)
    8000045c:	07f77713          	andi	a4,a4,127
    80000460:	97ba                	add	a5,a5,a4
    80000462:	4729                	li	a4,10
    80000464:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000468:	00010797          	auipc	a5,0x10
    8000046c:	66c7aa23          	sw	a2,1652(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    80000470:	00010517          	auipc	a0,0x10
    80000474:	66850513          	addi	a0,a0,1640 # 80010ad8 <cons+0x98>
    80000478:	00002097          	auipc	ra,0x2
    8000047c:	d46080e7          	jalr	-698(ra) # 800021be <wakeup>
    80000480:	bd71                	j	8000031c <consoleintr+0x3a>

0000000080000482 <consoleinit>:

void
consoleinit(void)
{
    80000482:	1141                	addi	sp,sp,-16
    80000484:	e406                	sd	ra,8(sp)
    80000486:	e022                	sd	s0,0(sp)
    80000488:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000048a:	00008597          	auipc	a1,0x8
    8000048e:	b7658593          	addi	a1,a1,-1162 # 80008000 <etext>
    80000492:	00010517          	auipc	a0,0x10
    80000496:	5ae50513          	addi	a0,a0,1454 # 80010a40 <cons>
    8000049a:	00000097          	auipc	ra,0x0
    8000049e:	758080e7          	jalr	1880(ra) # 80000bf2 <initlock>

  uartinit();
    800004a2:	00000097          	auipc	ra,0x0
    800004a6:	344080e7          	jalr	836(ra) # 800007e6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    800004aa:	00020797          	auipc	a5,0x20
    800004ae:	72e78793          	addi	a5,a5,1838 # 80020bd8 <devsw>
    800004b2:	00000717          	auipc	a4,0x0
    800004b6:	cce70713          	addi	a4,a4,-818 # 80000180 <consoleread>
    800004ba:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004bc:	00000717          	auipc	a4,0x0
    800004c0:	c4670713          	addi	a4,a4,-954 # 80000102 <consolewrite>
    800004c4:	ef98                	sd	a4,24(a5)
}
    800004c6:	60a2                	ld	ra,8(sp)
    800004c8:	6402                	ld	s0,0(sp)
    800004ca:	0141                	addi	sp,sp,16
    800004cc:	8082                	ret

00000000800004ce <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ce:	7179                	addi	sp,sp,-48
    800004d0:	f406                	sd	ra,40(sp)
    800004d2:	f022                	sd	s0,32(sp)
    800004d4:	ec26                	sd	s1,24(sp)
    800004d6:	e84a                	sd	s2,16(sp)
    800004d8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004da:	c219                	beqz	a2,800004e0 <printint+0x12>
    800004dc:	06054e63          	bltz	a0,80000558 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    800004e0:	4e01                	li	t3,0

  i = 0;
    800004e2:	fd040313          	addi	t1,s0,-48
    x = xx;
    800004e6:	869a                	mv	a3,t1
  i = 0;
    800004e8:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    800004ea:	00008817          	auipc	a6,0x8
    800004ee:	25e80813          	addi	a6,a6,606 # 80008748 <digits>
    800004f2:	88be                	mv	a7,a5
    800004f4:	0017861b          	addiw	a2,a5,1
    800004f8:	87b2                	mv	a5,a2
    800004fa:	02b5773b          	remuw	a4,a0,a1
    800004fe:	1702                	slli	a4,a4,0x20
    80000500:	9301                	srli	a4,a4,0x20
    80000502:	9742                	add	a4,a4,a6
    80000504:	00074703          	lbu	a4,0(a4)
    80000508:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    8000050c:	872a                	mv	a4,a0
    8000050e:	02b5553b          	divuw	a0,a0,a1
    80000512:	0685                	addi	a3,a3,1
    80000514:	fcb77fe3          	bgeu	a4,a1,800004f2 <printint+0x24>

  if(sign)
    80000518:	000e0c63          	beqz	t3,80000530 <printint+0x62>
    buf[i++] = '-';
    8000051c:	fe060793          	addi	a5,a2,-32
    80000520:	00878633          	add	a2,a5,s0
    80000524:	02d00793          	li	a5,45
    80000528:	fef60823          	sb	a5,-16(a2)
    8000052c:	0028879b          	addiw	a5,a7,2

  while(--i >= 0)
    80000530:	fff7891b          	addiw	s2,a5,-1
    80000534:	006784b3          	add	s1,a5,t1
    consputc(buf[i]);
    80000538:	fff4c503          	lbu	a0,-1(s1)
    8000053c:	00000097          	auipc	ra,0x0
    80000540:	d64080e7          	jalr	-668(ra) # 800002a0 <consputc>
  while(--i >= 0)
    80000544:	397d                	addiw	s2,s2,-1
    80000546:	14fd                	addi	s1,s1,-1
    80000548:	fe0958e3          	bgez	s2,80000538 <printint+0x6a>
}
    8000054c:	70a2                	ld	ra,40(sp)
    8000054e:	7402                	ld	s0,32(sp)
    80000550:	64e2                	ld	s1,24(sp)
    80000552:	6942                	ld	s2,16(sp)
    80000554:	6145                	addi	sp,sp,48
    80000556:	8082                	ret
    x = -xx;
    80000558:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000055c:	4e05                	li	t3,1
    x = -xx;
    8000055e:	b751                	j	800004e2 <printint+0x14>

0000000080000560 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000560:	1101                	addi	sp,sp,-32
    80000562:	ec06                	sd	ra,24(sp)
    80000564:	e822                	sd	s0,16(sp)
    80000566:	e426                	sd	s1,8(sp)
    80000568:	1000                	addi	s0,sp,32
    8000056a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000056c:	00010797          	auipc	a5,0x10
    80000570:	5807aa23          	sw	zero,1428(a5) # 80010b00 <pr+0x18>
  printf("panic: ");
    80000574:	00008517          	auipc	a0,0x8
    80000578:	a9450513          	addi	a0,a0,-1388 # 80008008 <etext+0x8>
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	02e080e7          	jalr	46(ra) # 800005aa <printf>
  printf(s);
    80000584:	8526                	mv	a0,s1
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	024080e7          	jalr	36(ra) # 800005aa <printf>
  printf("\n");
    8000058e:	00008517          	auipc	a0,0x8
    80000592:	a8250513          	addi	a0,a0,-1406 # 80008010 <etext+0x10>
    80000596:	00000097          	auipc	ra,0x0
    8000059a:	014080e7          	jalr	20(ra) # 800005aa <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000059e:	4785                	li	a5,1
    800005a0:	00008717          	auipc	a4,0x8
    800005a4:	32f72023          	sw	a5,800(a4) # 800088c0 <panicked>
  for(;;)
    800005a8:	a001                	j	800005a8 <panic+0x48>

00000000800005aa <printf>:
{
    800005aa:	7131                	addi	sp,sp,-192
    800005ac:	fc86                	sd	ra,120(sp)
    800005ae:	f8a2                	sd	s0,112(sp)
    800005b0:	e8d2                	sd	s4,80(sp)
    800005b2:	ec6e                	sd	s11,24(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ca:	00010d97          	auipc	s11,0x10
    800005ce:	536dad83          	lw	s11,1334(s11) # 80010b00 <pr+0x18>
  if(locking)
    800005d2:	040d9463          	bnez	s11,8000061a <printf+0x70>
  if (fmt == 0)
    800005d6:	040a0b63          	beqz	s4,8000062c <printf+0x82>
  va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	18050c63          	beqz	a0,8000077e <printf+0x1d4>
    800005ea:	f4a6                	sd	s1,104(sp)
    800005ec:	f0ca                	sd	s2,96(sp)
    800005ee:	ecce                	sd	s3,88(sp)
    800005f0:	e4d6                	sd	s5,72(sp)
    800005f2:	e0da                	sd	s6,64(sp)
    800005f4:	fc5e                	sd	s7,56(sp)
    800005f6:	f862                	sd	s8,48(sp)
    800005f8:	f466                	sd	s9,40(sp)
    800005fa:	f06a                	sd	s10,32(sp)
    800005fc:	4981                	li	s3,0
    if(c != '%'){
    800005fe:	02500b13          	li	s6,37
    switch(c){
    80000602:	07000b93          	li	s7,112
  consputc('x');
    80000606:	07800c93          	li	s9,120
    8000060a:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000060c:	00008a97          	auipc	s5,0x8
    80000610:	13ca8a93          	addi	s5,s5,316 # 80008748 <digits>
    switch(c){
    80000614:	07300c13          	li	s8,115
    80000618:	a0b9                	j	80000666 <printf+0xbc>
    acquire(&pr.lock);
    8000061a:	00010517          	auipc	a0,0x10
    8000061e:	4ce50513          	addi	a0,a0,1230 # 80010ae8 <pr>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	664080e7          	jalr	1636(ra) # 80000c86 <acquire>
    8000062a:	b775                	j	800005d6 <printf+0x2c>
    8000062c:	f4a6                	sd	s1,104(sp)
    8000062e:	f0ca                	sd	s2,96(sp)
    80000630:	ecce                	sd	s3,88(sp)
    80000632:	e4d6                	sd	s5,72(sp)
    80000634:	e0da                	sd	s6,64(sp)
    80000636:	fc5e                	sd	s7,56(sp)
    80000638:	f862                	sd	s8,48(sp)
    8000063a:	f466                	sd	s9,40(sp)
    8000063c:	f06a                	sd	s10,32(sp)
    panic("null fmt");
    8000063e:	00008517          	auipc	a0,0x8
    80000642:	9e250513          	addi	a0,a0,-1566 # 80008020 <etext+0x20>
    80000646:	00000097          	auipc	ra,0x0
    8000064a:	f1a080e7          	jalr	-230(ra) # 80000560 <panic>
      consputc(c);
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	c52080e7          	jalr	-942(ra) # 800002a0 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000656:	0019879b          	addiw	a5,s3,1
    8000065a:	89be                	mv	s3,a5
    8000065c:	97d2                	add	a5,a5,s4
    8000065e:	0007c503          	lbu	a0,0(a5)
    80000662:	10050563          	beqz	a0,8000076c <printf+0x1c2>
    if(c != '%'){
    80000666:	ff6514e3          	bne	a0,s6,8000064e <printf+0xa4>
    c = fmt[++i] & 0xff;
    8000066a:	0019879b          	addiw	a5,s3,1
    8000066e:	89be                	mv	s3,a5
    80000670:	97d2                	add	a5,a5,s4
    80000672:	0007c783          	lbu	a5,0(a5)
    80000676:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000067a:	10078a63          	beqz	a5,8000078e <printf+0x1e4>
    switch(c){
    8000067e:	05778a63          	beq	a5,s7,800006d2 <printf+0x128>
    80000682:	02fbf463          	bgeu	s7,a5,800006aa <printf+0x100>
    80000686:	09878763          	beq	a5,s8,80000714 <printf+0x16a>
    8000068a:	0d979663          	bne	a5,s9,80000756 <printf+0x1ac>
      printint(va_arg(ap, int), 16, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	85ea                	mv	a1,s10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e2e080e7          	jalr	-466(ra) # 800004ce <printint>
      break;
    800006a8:	b77d                	j	80000656 <printf+0xac>
    switch(c){
    800006aa:	0b678063          	beq	a5,s6,8000074a <printf+0x1a0>
    800006ae:	06400713          	li	a4,100
    800006b2:	0ae79263          	bne	a5,a4,80000756 <printf+0x1ac>
      printint(va_arg(ap, int), 10, 1);
    800006b6:	f8843783          	ld	a5,-120(s0)
    800006ba:	00878713          	addi	a4,a5,8
    800006be:	f8e43423          	sd	a4,-120(s0)
    800006c2:	4605                	li	a2,1
    800006c4:	45a9                	li	a1,10
    800006c6:	4388                	lw	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	e06080e7          	jalr	-506(ra) # 800004ce <printint>
      break;
    800006d0:	b759                	j	80000656 <printf+0xac>
      printptr(va_arg(ap, uint64));
    800006d2:	f8843783          	ld	a5,-120(s0)
    800006d6:	00878713          	addi	a4,a5,8
    800006da:	f8e43423          	sd	a4,-120(s0)
    800006de:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006e2:	03000513          	li	a0,48
    800006e6:	00000097          	auipc	ra,0x0
    800006ea:	bba080e7          	jalr	-1094(ra) # 800002a0 <consputc>
  consputc('x');
    800006ee:	8566                	mv	a0,s9
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	bb0080e7          	jalr	-1104(ra) # 800002a0 <consputc>
    800006f8:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006fa:	03c95793          	srli	a5,s2,0x3c
    800006fe:	97d6                	add	a5,a5,s5
    80000700:	0007c503          	lbu	a0,0(a5)
    80000704:	00000097          	auipc	ra,0x0
    80000708:	b9c080e7          	jalr	-1124(ra) # 800002a0 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000070c:	0912                	slli	s2,s2,0x4
    8000070e:	34fd                	addiw	s1,s1,-1
    80000710:	f4ed                	bnez	s1,800006fa <printf+0x150>
    80000712:	b791                	j	80000656 <printf+0xac>
      if((s = va_arg(ap, char*)) == 0)
    80000714:	f8843783          	ld	a5,-120(s0)
    80000718:	00878713          	addi	a4,a5,8
    8000071c:	f8e43423          	sd	a4,-120(s0)
    80000720:	6384                	ld	s1,0(a5)
    80000722:	cc89                	beqz	s1,8000073c <printf+0x192>
      for(; *s; s++)
    80000724:	0004c503          	lbu	a0,0(s1)
    80000728:	d51d                	beqz	a0,80000656 <printf+0xac>
        consputc(*s);
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b76080e7          	jalr	-1162(ra) # 800002a0 <consputc>
      for(; *s; s++)
    80000732:	0485                	addi	s1,s1,1
    80000734:	0004c503          	lbu	a0,0(s1)
    80000738:	f96d                	bnez	a0,8000072a <printf+0x180>
    8000073a:	bf31                	j	80000656 <printf+0xac>
        s = "(null)";
    8000073c:	00008497          	auipc	s1,0x8
    80000740:	8dc48493          	addi	s1,s1,-1828 # 80008018 <etext+0x18>
      for(; *s; s++)
    80000744:	02800513          	li	a0,40
    80000748:	b7cd                	j	8000072a <printf+0x180>
      consputc('%');
    8000074a:	855a                	mv	a0,s6
    8000074c:	00000097          	auipc	ra,0x0
    80000750:	b54080e7          	jalr	-1196(ra) # 800002a0 <consputc>
      break;
    80000754:	b709                	j	80000656 <printf+0xac>
      consputc('%');
    80000756:	855a                	mv	a0,s6
    80000758:	00000097          	auipc	ra,0x0
    8000075c:	b48080e7          	jalr	-1208(ra) # 800002a0 <consputc>
      consputc(c);
    80000760:	8526                	mv	a0,s1
    80000762:	00000097          	auipc	ra,0x0
    80000766:	b3e080e7          	jalr	-1218(ra) # 800002a0 <consputc>
      break;
    8000076a:	b5f5                	j	80000656 <printf+0xac>
    8000076c:	74a6                	ld	s1,104(sp)
    8000076e:	7906                	ld	s2,96(sp)
    80000770:	69e6                	ld	s3,88(sp)
    80000772:	6aa6                	ld	s5,72(sp)
    80000774:	6b06                	ld	s6,64(sp)
    80000776:	7be2                	ld	s7,56(sp)
    80000778:	7c42                	ld	s8,48(sp)
    8000077a:	7ca2                	ld	s9,40(sp)
    8000077c:	7d02                	ld	s10,32(sp)
  if(locking)
    8000077e:	020d9263          	bnez	s11,800007a2 <printf+0x1f8>
}
    80000782:	70e6                	ld	ra,120(sp)
    80000784:	7446                	ld	s0,112(sp)
    80000786:	6a46                	ld	s4,80(sp)
    80000788:	6de2                	ld	s11,24(sp)
    8000078a:	6129                	addi	sp,sp,192
    8000078c:	8082                	ret
    8000078e:	74a6                	ld	s1,104(sp)
    80000790:	7906                	ld	s2,96(sp)
    80000792:	69e6                	ld	s3,88(sp)
    80000794:	6aa6                	ld	s5,72(sp)
    80000796:	6b06                	ld	s6,64(sp)
    80000798:	7be2                	ld	s7,56(sp)
    8000079a:	7c42                	ld	s8,48(sp)
    8000079c:	7ca2                	ld	s9,40(sp)
    8000079e:	7d02                	ld	s10,32(sp)
    800007a0:	bff9                	j	8000077e <printf+0x1d4>
    release(&pr.lock);
    800007a2:	00010517          	auipc	a0,0x10
    800007a6:	34650513          	addi	a0,a0,838 # 80010ae8 <pr>
    800007aa:	00000097          	auipc	ra,0x0
    800007ae:	58c080e7          	jalr	1420(ra) # 80000d36 <release>
}
    800007b2:	bfc1                	j	80000782 <printf+0x1d8>

00000000800007b4 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007b4:	1101                	addi	sp,sp,-32
    800007b6:	ec06                	sd	ra,24(sp)
    800007b8:	e822                	sd	s0,16(sp)
    800007ba:	e426                	sd	s1,8(sp)
    800007bc:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007be:	00010497          	auipc	s1,0x10
    800007c2:	32a48493          	addi	s1,s1,810 # 80010ae8 <pr>
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	86a58593          	addi	a1,a1,-1942 # 80008030 <etext+0x30>
    800007ce:	8526                	mv	a0,s1
    800007d0:	00000097          	auipc	ra,0x0
    800007d4:	422080e7          	jalr	1058(ra) # 80000bf2 <initlock>
  pr.locking = 1;
    800007d8:	4785                	li	a5,1
    800007da:	cc9c                	sw	a5,24(s1)
}
    800007dc:	60e2                	ld	ra,24(sp)
    800007de:	6442                	ld	s0,16(sp)
    800007e0:	64a2                	ld	s1,8(sp)
    800007e2:	6105                	addi	sp,sp,32
    800007e4:	8082                	ret

00000000800007e6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007e6:	1141                	addi	sp,sp,-16
    800007e8:	e406                	sd	ra,8(sp)
    800007ea:	e022                	sd	s0,0(sp)
    800007ec:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ee:	100007b7          	lui	a5,0x10000
    800007f2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007f6:	10000737          	lui	a4,0x10000
    800007fa:	f8000693          	li	a3,-128
    800007fe:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000802:	468d                	li	a3,3
    80000804:	10000637          	lui	a2,0x10000
    80000808:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000080c:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000810:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000814:	8732                	mv	a4,a2
    80000816:	461d                	li	a2,7
    80000818:	00c70123          	sb	a2,2(a4)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000081c:	00d780a3          	sb	a3,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000820:	00008597          	auipc	a1,0x8
    80000824:	81858593          	addi	a1,a1,-2024 # 80008038 <etext+0x38>
    80000828:	00010517          	auipc	a0,0x10
    8000082c:	2e050513          	addi	a0,a0,736 # 80010b08 <uart_tx_lock>
    80000830:	00000097          	auipc	ra,0x0
    80000834:	3c2080e7          	jalr	962(ra) # 80000bf2 <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000840:	1101                	addi	sp,sp,-32
    80000842:	ec06                	sd	ra,24(sp)
    80000844:	e822                	sd	s0,16(sp)
    80000846:	e426                	sd	s1,8(sp)
    80000848:	1000                	addi	s0,sp,32
    8000084a:	84aa                	mv	s1,a0
  push_off();
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	3ee080e7          	jalr	1006(ra) # 80000c3a <push_off>

  if(panicked){
    80000854:	00008797          	auipc	a5,0x8
    80000858:	06c7a783          	lw	a5,108(a5) # 800088c0 <panicked>
    8000085c:	eb85                	bnez	a5,8000088c <uartputc_sync+0x4c>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000085e:	10000737          	lui	a4,0x10000
    80000862:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000864:	00074783          	lbu	a5,0(a4)
    80000868:	0207f793          	andi	a5,a5,32
    8000086c:	dfe5                	beqz	a5,80000864 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000086e:	0ff4f513          	zext.b	a0,s1
    80000872:	100007b7          	lui	a5,0x10000
    80000876:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	460080e7          	jalr	1120(ra) # 80000cda <pop_off>
}
    80000882:	60e2                	ld	ra,24(sp)
    80000884:	6442                	ld	s0,16(sp)
    80000886:	64a2                	ld	s1,8(sp)
    80000888:	6105                	addi	sp,sp,32
    8000088a:	8082                	ret
    for(;;)
    8000088c:	a001                	j	8000088c <uartputc_sync+0x4c>

000000008000088e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000088e:	00008797          	auipc	a5,0x8
    80000892:	03a7b783          	ld	a5,58(a5) # 800088c8 <uart_tx_r>
    80000896:	00008717          	auipc	a4,0x8
    8000089a:	03a73703          	ld	a4,58(a4) # 800088d0 <uart_tx_w>
    8000089e:	06f70f63          	beq	a4,a5,8000091c <uartstart+0x8e>
{
    800008a2:	7139                	addi	sp,sp,-64
    800008a4:	fc06                	sd	ra,56(sp)
    800008a6:	f822                	sd	s0,48(sp)
    800008a8:	f426                	sd	s1,40(sp)
    800008aa:	f04a                	sd	s2,32(sp)
    800008ac:	ec4e                	sd	s3,24(sp)
    800008ae:	e852                	sd	s4,16(sp)
    800008b0:	e456                	sd	s5,8(sp)
    800008b2:	e05a                	sd	s6,0(sp)
    800008b4:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008b6:	10000937          	lui	s2,0x10000
    800008ba:	0915                	addi	s2,s2,5 # 10000005 <_entry-0x6ffffffb>
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008bc:	00010a97          	auipc	s5,0x10
    800008c0:	24ca8a93          	addi	s5,s5,588 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    800008c4:	00008497          	auipc	s1,0x8
    800008c8:	00448493          	addi	s1,s1,4 # 800088c8 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008cc:	10000a37          	lui	s4,0x10000
    if(uart_tx_w == uart_tx_r){
    800008d0:	00008997          	auipc	s3,0x8
    800008d4:	00098993          	mv	s3,s3
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d8:	00094703          	lbu	a4,0(s2)
    800008dc:	02077713          	andi	a4,a4,32
    800008e0:	c705                	beqz	a4,80000908 <uartstart+0x7a>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008e2:	01f7f713          	andi	a4,a5,31
    800008e6:	9756                	add	a4,a4,s5
    800008e8:	01874b03          	lbu	s6,24(a4)
    uart_tx_r += 1;
    800008ec:	0785                	addi	a5,a5,1
    800008ee:	e09c                	sd	a5,0(s1)
    wakeup(&uart_tx_r);
    800008f0:	8526                	mv	a0,s1
    800008f2:	00002097          	auipc	ra,0x2
    800008f6:	8cc080e7          	jalr	-1844(ra) # 800021be <wakeup>
    WriteReg(THR, c);
    800008fa:	016a0023          	sb	s6,0(s4) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008fe:	609c                	ld	a5,0(s1)
    80000900:	0009b703          	ld	a4,0(s3) # 800088d0 <uart_tx_w>
    80000904:	fcf71ae3          	bne	a4,a5,800008d8 <uartstart+0x4a>
  }
}
    80000908:	70e2                	ld	ra,56(sp)
    8000090a:	7442                	ld	s0,48(sp)
    8000090c:	74a2                	ld	s1,40(sp)
    8000090e:	7902                	ld	s2,32(sp)
    80000910:	69e2                	ld	s3,24(sp)
    80000912:	6a42                	ld	s4,16(sp)
    80000914:	6aa2                	ld	s5,8(sp)
    80000916:	6b02                	ld	s6,0(sp)
    80000918:	6121                	addi	sp,sp,64
    8000091a:	8082                	ret
    8000091c:	8082                	ret

000000008000091e <uartputc>:
{
    8000091e:	7179                	addi	sp,sp,-48
    80000920:	f406                	sd	ra,40(sp)
    80000922:	f022                	sd	s0,32(sp)
    80000924:	ec26                	sd	s1,24(sp)
    80000926:	e84a                	sd	s2,16(sp)
    80000928:	e44e                	sd	s3,8(sp)
    8000092a:	e052                	sd	s4,0(sp)
    8000092c:	1800                	addi	s0,sp,48
    8000092e:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000930:	00010517          	auipc	a0,0x10
    80000934:	1d850513          	addi	a0,a0,472 # 80010b08 <uart_tx_lock>
    80000938:	00000097          	auipc	ra,0x0
    8000093c:	34e080e7          	jalr	846(ra) # 80000c86 <acquire>
  if(panicked){
    80000940:	00008797          	auipc	a5,0x8
    80000944:	f807a783          	lw	a5,-128(a5) # 800088c0 <panicked>
    80000948:	e7c9                	bnez	a5,800009d2 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	00008717          	auipc	a4,0x8
    8000094e:	f8673703          	ld	a4,-122(a4) # 800088d0 <uart_tx_w>
    80000952:	00008797          	auipc	a5,0x8
    80000956:	f767b783          	ld	a5,-138(a5) # 800088c8 <uart_tx_r>
    8000095a:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000095e:	00010997          	auipc	s3,0x10
    80000962:	1aa98993          	addi	s3,s3,426 # 80010b08 <uart_tx_lock>
    80000966:	00008497          	auipc	s1,0x8
    8000096a:	f6248493          	addi	s1,s1,-158 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000096e:	00008917          	auipc	s2,0x8
    80000972:	f6290913          	addi	s2,s2,-158 # 800088d0 <uart_tx_w>
    80000976:	00e79f63          	bne	a5,a4,80000994 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000097a:	85ce                	mv	a1,s3
    8000097c:	8526                	mv	a0,s1
    8000097e:	00001097          	auipc	ra,0x1
    80000982:	7dc080e7          	jalr	2012(ra) # 8000215a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000986:	00093703          	ld	a4,0(s2)
    8000098a:	609c                	ld	a5,0(s1)
    8000098c:	02078793          	addi	a5,a5,32
    80000990:	fee785e3          	beq	a5,a4,8000097a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000994:	00010497          	auipc	s1,0x10
    80000998:	17448493          	addi	s1,s1,372 # 80010b08 <uart_tx_lock>
    8000099c:	01f77793          	andi	a5,a4,31
    800009a0:	97a6                	add	a5,a5,s1
    800009a2:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009a6:	0705                	addi	a4,a4,1
    800009a8:	00008797          	auipc	a5,0x8
    800009ac:	f2e7b423          	sd	a4,-216(a5) # 800088d0 <uart_tx_w>
  uartstart();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	ede080e7          	jalr	-290(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    800009b8:	8526                	mv	a0,s1
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	37c080e7          	jalr	892(ra) # 80000d36 <release>
}
    800009c2:	70a2                	ld	ra,40(sp)
    800009c4:	7402                	ld	s0,32(sp)
    800009c6:	64e2                	ld	s1,24(sp)
    800009c8:	6942                	ld	s2,16(sp)
    800009ca:	69a2                	ld	s3,8(sp)
    800009cc:	6a02                	ld	s4,0(sp)
    800009ce:	6145                	addi	sp,sp,48
    800009d0:	8082                	ret
    for(;;)
    800009d2:	a001                	j	800009d2 <uartputc+0xb4>

00000000800009d4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009d4:	1141                	addi	sp,sp,-16
    800009d6:	e406                	sd	ra,8(sp)
    800009d8:	e022                	sd	s0,0(sp)
    800009da:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009dc:	100007b7          	lui	a5,0x10000
    800009e0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009e4:	8b85                	andi	a5,a5,1
    800009e6:	cb89                	beqz	a5,800009f8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009e8:	100007b7          	lui	a5,0x10000
    800009ec:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009f0:	60a2                	ld	ra,8(sp)
    800009f2:	6402                	ld	s0,0(sp)
    800009f4:	0141                	addi	sp,sp,16
    800009f6:	8082                	ret
    return -1;
    800009f8:	557d                	li	a0,-1
    800009fa:	bfdd                	j	800009f0 <uartgetc+0x1c>

00000000800009fc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009fc:	1101                	addi	sp,sp,-32
    800009fe:	ec06                	sd	ra,24(sp)
    80000a00:	e822                	sd	s0,16(sp)
    80000a02:	e426                	sd	s1,8(sp)
    80000a04:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a06:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	fcc080e7          	jalr	-52(ra) # 800009d4 <uartgetc>
    if(c == -1)
    80000a10:	00950763          	beq	a0,s1,80000a1e <uartintr+0x22>
      break;
    consoleintr(c);
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	8ce080e7          	jalr	-1842(ra) # 800002e2 <consoleintr>
  while(1){
    80000a1c:	b7f5                	j	80000a08 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a1e:	00010497          	auipc	s1,0x10
    80000a22:	0ea48493          	addi	s1,s1,234 # 80010b08 <uart_tx_lock>
    80000a26:	8526                	mv	a0,s1
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	25e080e7          	jalr	606(ra) # 80000c86 <acquire>
  uartstart();
    80000a30:	00000097          	auipc	ra,0x0
    80000a34:	e5e080e7          	jalr	-418(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    80000a38:	8526                	mv	a0,s1
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	2fc080e7          	jalr	764(ra) # 80000d36 <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6105                	addi	sp,sp,32
    80000a4a:	8082                	ret

0000000080000a4c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a4c:	1101                	addi	sp,sp,-32
    80000a4e:	ec06                	sd	ra,24(sp)
    80000a50:	e822                	sd	s0,16(sp)
    80000a52:	e426                	sd	s1,8(sp)
    80000a54:	e04a                	sd	s2,0(sp)
    80000a56:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a58:	03451793          	slli	a5,a0,0x34
    80000a5c:	ebb9                	bnez	a5,80000ab2 <kfree+0x66>
    80000a5e:	84aa                	mv	s1,a0
    80000a60:	00021797          	auipc	a5,0x21
    80000a64:	31078793          	addi	a5,a5,784 # 80021d70 <end>
    80000a68:	04f56563          	bltu	a0,a5,80000ab2 <kfree+0x66>
    80000a6c:	47c5                	li	a5,17
    80000a6e:	07ee                	slli	a5,a5,0x1b
    80000a70:	04f57163          	bgeu	a0,a5,80000ab2 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a74:	6605                	lui	a2,0x1
    80000a76:	4585                	li	a1,1
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	306080e7          	jalr	774(ra) # 80000d7e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a80:	00010917          	auipc	s2,0x10
    80000a84:	0c090913          	addi	s2,s2,192 # 80010b40 <kmem>
    80000a88:	854a                	mv	a0,s2
    80000a8a:	00000097          	auipc	ra,0x0
    80000a8e:	1fc080e7          	jalr	508(ra) # 80000c86 <acquire>
  r->next = kmem.freelist;
    80000a92:	01893783          	ld	a5,24(s2)
    80000a96:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a98:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9c:	854a                	mv	a0,s2
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	298080e7          	jalr	664(ra) # 80000d36 <release>
}
    80000aa6:	60e2                	ld	ra,24(sp)
    80000aa8:	6442                	ld	s0,16(sp)
    80000aaa:	64a2                	ld	s1,8(sp)
    80000aac:	6902                	ld	s2,0(sp)
    80000aae:	6105                	addi	sp,sp,32
    80000ab0:	8082                	ret
    panic("kfree");
    80000ab2:	00007517          	auipc	a0,0x7
    80000ab6:	58e50513          	addi	a0,a0,1422 # 80008040 <etext+0x40>
    80000aba:	00000097          	auipc	ra,0x0
    80000abe:	aa6080e7          	jalr	-1370(ra) # 80000560 <panic>

0000000080000ac2 <freerange>:
{
    80000ac2:	7179                	addi	sp,sp,-48
    80000ac4:	f406                	sd	ra,40(sp)
    80000ac6:	f022                	sd	s0,32(sp)
    80000ac8:	ec26                	sd	s1,24(sp)
    80000aca:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000acc:	6785                	lui	a5,0x1
    80000ace:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad2:	00e504b3          	add	s1,a0,a4
    80000ad6:	777d                	lui	a4,0xfffff
    80000ad8:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ada:	94be                	add	s1,s1,a5
    80000adc:	0295e463          	bltu	a1,s1,80000b04 <freerange+0x42>
    80000ae0:	e84a                	sd	s2,16(sp)
    80000ae2:	e44e                	sd	s3,8(sp)
    80000ae4:	e052                	sd	s4,0(sp)
    80000ae6:	892e                	mv	s2,a1
    kfree(p);
    80000ae8:	8a3a                	mv	s4,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aea:	89be                	mv	s3,a5
    kfree(p);
    80000aec:	01448533          	add	a0,s1,s4
    80000af0:	00000097          	auipc	ra,0x0
    80000af4:	f5c080e7          	jalr	-164(ra) # 80000a4c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	94ce                	add	s1,s1,s3
    80000afa:	fe9979e3          	bgeu	s2,s1,80000aec <freerange+0x2a>
    80000afe:	6942                	ld	s2,16(sp)
    80000b00:	69a2                	ld	s3,8(sp)
    80000b02:	6a02                	ld	s4,0(sp)
}
    80000b04:	70a2                	ld	ra,40(sp)
    80000b06:	7402                	ld	s0,32(sp)
    80000b08:	64e2                	ld	s1,24(sp)
    80000b0a:	6145                	addi	sp,sp,48
    80000b0c:	8082                	ret

0000000080000b0e <kinit>:
{
    80000b0e:	1141                	addi	sp,sp,-16
    80000b10:	e406                	sd	ra,8(sp)
    80000b12:	e022                	sd	s0,0(sp)
    80000b14:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b16:	00007597          	auipc	a1,0x7
    80000b1a:	53258593          	addi	a1,a1,1330 # 80008048 <etext+0x48>
    80000b1e:	00010517          	auipc	a0,0x10
    80000b22:	02250513          	addi	a0,a0,34 # 80010b40 <kmem>
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	0cc080e7          	jalr	204(ra) # 80000bf2 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b2e:	45c5                	li	a1,17
    80000b30:	05ee                	slli	a1,a1,0x1b
    80000b32:	00021517          	auipc	a0,0x21
    80000b36:	23e50513          	addi	a0,a0,574 # 80021d70 <end>
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	f88080e7          	jalr	-120(ra) # 80000ac2 <freerange>
}
    80000b42:	60a2                	ld	ra,8(sp)
    80000b44:	6402                	ld	s0,0(sp)
    80000b46:	0141                	addi	sp,sp,16
    80000b48:	8082                	ret

0000000080000b4a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b4a:	1101                	addi	sp,sp,-32
    80000b4c:	ec06                	sd	ra,24(sp)
    80000b4e:	e822                	sd	s0,16(sp)
    80000b50:	e426                	sd	s1,8(sp)
    80000b52:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b54:	00010497          	auipc	s1,0x10
    80000b58:	fec48493          	addi	s1,s1,-20 # 80010b40 <kmem>
    80000b5c:	8526                	mv	a0,s1
    80000b5e:	00000097          	auipc	ra,0x0
    80000b62:	128080e7          	jalr	296(ra) # 80000c86 <acquire>
  r = kmem.freelist;
    80000b66:	6c84                	ld	s1,24(s1)
  if(r)
    80000b68:	c885                	beqz	s1,80000b98 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b6a:	609c                	ld	a5,0(s1)
    80000b6c:	00010517          	auipc	a0,0x10
    80000b70:	fd450513          	addi	a0,a0,-44 # 80010b40 <kmem>
    80000b74:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	1c0080e7          	jalr	448(ra) # 80000d36 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b7e:	6605                	lui	a2,0x1
    80000b80:	4595                	li	a1,5
    80000b82:	8526                	mv	a0,s1
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	1fa080e7          	jalr	506(ra) # 80000d7e <memset>
  return (void*)r;
}
    80000b8c:	8526                	mv	a0,s1
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret
  release(&kmem.lock);
    80000b98:	00010517          	auipc	a0,0x10
    80000b9c:	fa850513          	addi	a0,a0,-88 # 80010b40 <kmem>
    80000ba0:	00000097          	auipc	ra,0x0
    80000ba4:	196080e7          	jalr	406(ra) # 80000d36 <release>
  if(r)
    80000ba8:	b7d5                	j	80000b8c <kalloc+0x42>

0000000080000baa <count_free_pages>:
// Count the number of free memory pages
int
count_free_pages(void)
{
    80000baa:	1101                	addi	sp,sp,-32
    80000bac:	ec06                	sd	ra,24(sp)
    80000bae:	e822                	sd	s0,16(sp)
    80000bb0:	e426                	sd	s1,8(sp)
    80000bb2:	1000                	addi	s0,sp,32
  struct run *r;
  int count = 0;
  
  acquire(&kmem.lock);
    80000bb4:	00010497          	auipc	s1,0x10
    80000bb8:	f8c48493          	addi	s1,s1,-116 # 80010b40 <kmem>
    80000bbc:	8526                	mv	a0,s1
    80000bbe:	00000097          	auipc	ra,0x0
    80000bc2:	0c8080e7          	jalr	200(ra) # 80000c86 <acquire>
  r = kmem.freelist;
    80000bc6:	6c9c                	ld	a5,24(s1)
  while(r) {
    80000bc8:	c39d                	beqz	a5,80000bee <count_free_pages+0x44>
  int count = 0;
    80000bca:	4481                	li	s1,0
    count++;
    80000bcc:	2485                	addiw	s1,s1,1
    r = r->next;
    80000bce:	639c                	ld	a5,0(a5)
  while(r) {
    80000bd0:	fff5                	bnez	a5,80000bcc <count_free_pages+0x22>
  }
  release(&kmem.lock);
    80000bd2:	00010517          	auipc	a0,0x10
    80000bd6:	f6e50513          	addi	a0,a0,-146 # 80010b40 <kmem>
    80000bda:	00000097          	auipc	ra,0x0
    80000bde:	15c080e7          	jalr	348(ra) # 80000d36 <release>
  
  return count;
    80000be2:	8526                	mv	a0,s1
    80000be4:	60e2                	ld	ra,24(sp)
    80000be6:	6442                	ld	s0,16(sp)
    80000be8:	64a2                	ld	s1,8(sp)
    80000bea:	6105                	addi	sp,sp,32
    80000bec:	8082                	ret
  int count = 0;
    80000bee:	4481                	li	s1,0
    80000bf0:	b7cd                	j	80000bd2 <count_free_pages+0x28>

0000000080000bf2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bf2:	1141                	addi	sp,sp,-16
    80000bf4:	e406                	sd	ra,8(sp)
    80000bf6:	e022                	sd	s0,0(sp)
    80000bf8:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bfa:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bfc:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c00:	00053823          	sd	zero,16(a0)
}
    80000c04:	60a2                	ld	ra,8(sp)
    80000c06:	6402                	ld	s0,0(sp)
    80000c08:	0141                	addi	sp,sp,16
    80000c0a:	8082                	ret

0000000080000c0c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c0c:	411c                	lw	a5,0(a0)
    80000c0e:	e399                	bnez	a5,80000c14 <holding+0x8>
    80000c10:	4501                	li	a0,0
  return r;
}
    80000c12:	8082                	ret
{
    80000c14:	1101                	addi	sp,sp,-32
    80000c16:	ec06                	sd	ra,24(sp)
    80000c18:	e822                	sd	s0,16(sp)
    80000c1a:	e426                	sd	s1,8(sp)
    80000c1c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c1e:	6904                	ld	s1,16(a0)
    80000c20:	00001097          	auipc	ra,0x1
    80000c24:	e70080e7          	jalr	-400(ra) # 80001a90 <mycpu>
    80000c28:	40a48533          	sub	a0,s1,a0
    80000c2c:	00153513          	seqz	a0,a0
}
    80000c30:	60e2                	ld	ra,24(sp)
    80000c32:	6442                	ld	s0,16(sp)
    80000c34:	64a2                	ld	s1,8(sp)
    80000c36:	6105                	addi	sp,sp,32
    80000c38:	8082                	ret

0000000080000c3a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c3a:	1101                	addi	sp,sp,-32
    80000c3c:	ec06                	sd	ra,24(sp)
    80000c3e:	e822                	sd	s0,16(sp)
    80000c40:	e426                	sd	s1,8(sp)
    80000c42:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c44:	100024f3          	csrr	s1,sstatus
    80000c48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	e3e080e7          	jalr	-450(ra) # 80001a90 <mycpu>
    80000c5a:	5d3c                	lw	a5,120(a0)
    80000c5c:	cf89                	beqz	a5,80000c76 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c5e:	00001097          	auipc	ra,0x1
    80000c62:	e32080e7          	jalr	-462(ra) # 80001a90 <mycpu>
    80000c66:	5d3c                	lw	a5,120(a0)
    80000c68:	2785                	addiw	a5,a5,1
    80000c6a:	dd3c                	sw	a5,120(a0)
}
    80000c6c:	60e2                	ld	ra,24(sp)
    80000c6e:	6442                	ld	s0,16(sp)
    80000c70:	64a2                	ld	s1,8(sp)
    80000c72:	6105                	addi	sp,sp,32
    80000c74:	8082                	ret
    mycpu()->intena = old;
    80000c76:	00001097          	auipc	ra,0x1
    80000c7a:	e1a080e7          	jalr	-486(ra) # 80001a90 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c7e:	8085                	srli	s1,s1,0x1
    80000c80:	8885                	andi	s1,s1,1
    80000c82:	dd64                	sw	s1,124(a0)
    80000c84:	bfe9                	j	80000c5e <push_off+0x24>

0000000080000c86 <acquire>:
{
    80000c86:	1101                	addi	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	addi	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	fa8080e7          	jalr	-88(ra) # 80000c3a <push_off>
  if(holding(lk))
    80000c9a:	8526                	mv	a0,s1
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f70080e7          	jalr	-144(ra) # 80000c0c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ca4:	4705                	li	a4,1
  if(holding(lk))
    80000ca6:	e115                	bnez	a0,80000cca <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ca8:	87ba                	mv	a5,a4
    80000caa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cae:	2781                	sext.w	a5,a5
    80000cb0:	ffe5                	bnez	a5,80000ca8 <acquire+0x22>
  __sync_synchronize();
    80000cb2:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	dda080e7          	jalr	-550(ra) # 80001a90 <mycpu>
    80000cbe:	e888                	sd	a0,16(s1)
}
    80000cc0:	60e2                	ld	ra,24(sp)
    80000cc2:	6442                	ld	s0,16(sp)
    80000cc4:	64a2                	ld	s1,8(sp)
    80000cc6:	6105                	addi	sp,sp,32
    80000cc8:	8082                	ret
    panic("acquire");
    80000cca:	00007517          	auipc	a0,0x7
    80000cce:	38650513          	addi	a0,a0,902 # 80008050 <etext+0x50>
    80000cd2:	00000097          	auipc	ra,0x0
    80000cd6:	88e080e7          	jalr	-1906(ra) # 80000560 <panic>

0000000080000cda <pop_off>:

void
pop_off(void)
{
    80000cda:	1141                	addi	sp,sp,-16
    80000cdc:	e406                	sd	ra,8(sp)
    80000cde:	e022                	sd	s0,0(sp)
    80000ce0:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ce2:	00001097          	auipc	ra,0x1
    80000ce6:	dae080e7          	jalr	-594(ra) # 80001a90 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cee:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cf0:	e39d                	bnez	a5,80000d16 <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cf2:	5d3c                	lw	a5,120(a0)
    80000cf4:	02f05963          	blez	a5,80000d26 <pop_off+0x4c>
    panic("pop_off");
  c->noff -= 1;
    80000cf8:	37fd                	addiw	a5,a5,-1
    80000cfa:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cfc:	eb89                	bnez	a5,80000d0e <pop_off+0x34>
    80000cfe:	5d7c                	lw	a5,124(a0)
    80000d00:	c799                	beqz	a5,80000d0e <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d02:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d06:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d0a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d0e:	60a2                	ld	ra,8(sp)
    80000d10:	6402                	ld	s0,0(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
    panic("pop_off - interruptible");
    80000d16:	00007517          	auipc	a0,0x7
    80000d1a:	34250513          	addi	a0,a0,834 # 80008058 <etext+0x58>
    80000d1e:	00000097          	auipc	ra,0x0
    80000d22:	842080e7          	jalr	-1982(ra) # 80000560 <panic>
    panic("pop_off");
    80000d26:	00007517          	auipc	a0,0x7
    80000d2a:	34a50513          	addi	a0,a0,842 # 80008070 <etext+0x70>
    80000d2e:	00000097          	auipc	ra,0x0
    80000d32:	832080e7          	jalr	-1998(ra) # 80000560 <panic>

0000000080000d36 <release>:
{
    80000d36:	1101                	addi	sp,sp,-32
    80000d38:	ec06                	sd	ra,24(sp)
    80000d3a:	e822                	sd	s0,16(sp)
    80000d3c:	e426                	sd	s1,8(sp)
    80000d3e:	1000                	addi	s0,sp,32
    80000d40:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d42:	00000097          	auipc	ra,0x0
    80000d46:	eca080e7          	jalr	-310(ra) # 80000c0c <holding>
    80000d4a:	c115                	beqz	a0,80000d6e <release+0x38>
  lk->cpu = 0;
    80000d4c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d50:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000d54:	0310000f          	fence	rw,w
    80000d58:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000d5c:	00000097          	auipc	ra,0x0
    80000d60:	f7e080e7          	jalr	-130(ra) # 80000cda <pop_off>
}
    80000d64:	60e2                	ld	ra,24(sp)
    80000d66:	6442                	ld	s0,16(sp)
    80000d68:	64a2                	ld	s1,8(sp)
    80000d6a:	6105                	addi	sp,sp,32
    80000d6c:	8082                	ret
    panic("release");
    80000d6e:	00007517          	auipc	a0,0x7
    80000d72:	30a50513          	addi	a0,a0,778 # 80008078 <etext+0x78>
    80000d76:	fffff097          	auipc	ra,0xfffff
    80000d7a:	7ea080e7          	jalr	2026(ra) # 80000560 <panic>

0000000080000d7e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d86:	ca19                	beqz	a2,80000d9c <memset+0x1e>
    80000d88:	87aa                	mv	a5,a0
    80000d8a:	1602                	slli	a2,a2,0x20
    80000d8c:	9201                	srli	a2,a2,0x20
    80000d8e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d92:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fee79de3          	bne	a5,a4,80000d92 <memset+0x14>
  }
  return dst;
}
    80000d9c:	60a2                	ld	ra,8(sp)
    80000d9e:	6402                	ld	s0,0(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret

0000000080000da4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000da4:	1141                	addi	sp,sp,-16
    80000da6:	e406                	sd	ra,8(sp)
    80000da8:	e022                	sd	s0,0(sp)
    80000daa:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dac:	ca0d                	beqz	a2,80000dde <memcmp+0x3a>
    80000dae:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000db2:	1682                	slli	a3,a3,0x20
    80000db4:	9281                	srli	a3,a3,0x20
    80000db6:	0685                	addi	a3,a3,1
    80000db8:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dba:	00054783          	lbu	a5,0(a0)
    80000dbe:	0005c703          	lbu	a4,0(a1)
    80000dc2:	00e79863          	bne	a5,a4,80000dd2 <memcmp+0x2e>
      return *s1 - *s2;
    s1++, s2++;
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dca:	fed518e3          	bne	a0,a3,80000dba <memcmp+0x16>
  }

  return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	a019                	j	80000dd6 <memcmp+0x32>
      return *s1 - *s2;
    80000dd2:	40e7853b          	subw	a0,a5,a4
}
    80000dd6:	60a2                	ld	ra,8(sp)
    80000dd8:	6402                	ld	s0,0(sp)
    80000dda:	0141                	addi	sp,sp,16
    80000ddc:	8082                	ret
  return 0;
    80000dde:	4501                	li	a0,0
    80000de0:	bfdd                	j	80000dd6 <memcmp+0x32>

0000000080000de2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000de2:	1141                	addi	sp,sp,-16
    80000de4:	e406                	sd	ra,8(sp)
    80000de6:	e022                	sd	s0,0(sp)
    80000de8:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000dea:	c205                	beqz	a2,80000e0a <memmove+0x28>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dec:	02a5e363          	bltu	a1,a0,80000e12 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000df0:	1602                	slli	a2,a2,0x20
    80000df2:	9201                	srli	a2,a2,0x20
    80000df4:	00c587b3          	add	a5,a1,a2
{
    80000df8:	872a                	mv	a4,a0
      *d++ = *s++;
    80000dfa:	0585                	addi	a1,a1,1
    80000dfc:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd291>
    80000dfe:	fff5c683          	lbu	a3,-1(a1)
    80000e02:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e06:	feb79ae3          	bne	a5,a1,80000dfa <memmove+0x18>

  return dst;
}
    80000e0a:	60a2                	ld	ra,8(sp)
    80000e0c:	6402                	ld	s0,0(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret
  if(s < d && s + n > d){
    80000e12:	02061693          	slli	a3,a2,0x20
    80000e16:	9281                	srli	a3,a3,0x20
    80000e18:	00d58733          	add	a4,a1,a3
    80000e1c:	fce57ae3          	bgeu	a0,a4,80000df0 <memmove+0xe>
    d += n;
    80000e20:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e22:	fff6079b          	addiw	a5,a2,-1
    80000e26:	1782                	slli	a5,a5,0x20
    80000e28:	9381                	srli	a5,a5,0x20
    80000e2a:	fff7c793          	not	a5,a5
    80000e2e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e30:	177d                	addi	a4,a4,-1
    80000e32:	16fd                	addi	a3,a3,-1
    80000e34:	00074603          	lbu	a2,0(a4)
    80000e38:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e3c:	fee79ae3          	bne	a5,a4,80000e30 <memmove+0x4e>
    80000e40:	b7e9                	j	80000e0a <memmove+0x28>

0000000080000e42 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e406                	sd	ra,8(sp)
    80000e46:	e022                	sd	s0,0(sp)
    80000e48:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e4a:	00000097          	auipc	ra,0x0
    80000e4e:	f98080e7          	jalr	-104(ra) # 80000de2 <memmove>
}
    80000e52:	60a2                	ld	ra,8(sp)
    80000e54:	6402                	ld	s0,0(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e406                	sd	ra,8(sp)
    80000e5e:	e022                	sd	s0,0(sp)
    80000e60:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e62:	ce11                	beqz	a2,80000e7e <strncmp+0x24>
    80000e64:	00054783          	lbu	a5,0(a0)
    80000e68:	cf89                	beqz	a5,80000e82 <strncmp+0x28>
    80000e6a:	0005c703          	lbu	a4,0(a1)
    80000e6e:	00f71a63          	bne	a4,a5,80000e82 <strncmp+0x28>
    n--, p++, q++;
    80000e72:	367d                	addiw	a2,a2,-1
    80000e74:	0505                	addi	a0,a0,1
    80000e76:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e78:	f675                	bnez	a2,80000e64 <strncmp+0xa>
  if(n == 0)
    return 0;
    80000e7a:	4501                	li	a0,0
    80000e7c:	a801                	j	80000e8c <strncmp+0x32>
    80000e7e:	4501                	li	a0,0
    80000e80:	a031                	j	80000e8c <strncmp+0x32>
  return (uchar)*p - (uchar)*q;
    80000e82:	00054503          	lbu	a0,0(a0)
    80000e86:	0005c783          	lbu	a5,0(a1)
    80000e8a:	9d1d                	subw	a0,a0,a5
}
    80000e8c:	60a2                	ld	ra,8(sp)
    80000e8e:	6402                	ld	s0,0(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e9c:	87aa                	mv	a5,a0
    80000e9e:	86b2                	mv	a3,a2
    80000ea0:	367d                	addiw	a2,a2,-1
    80000ea2:	02d05563          	blez	a3,80000ecc <strncpy+0x38>
    80000ea6:	0785                	addi	a5,a5,1
    80000ea8:	0005c703          	lbu	a4,0(a1)
    80000eac:	fee78fa3          	sb	a4,-1(a5)
    80000eb0:	0585                	addi	a1,a1,1
    80000eb2:	f775                	bnez	a4,80000e9e <strncpy+0xa>
    ;
  while(n-- > 0)
    80000eb4:	873e                	mv	a4,a5
    80000eb6:	00c05b63          	blez	a2,80000ecc <strncpy+0x38>
    80000eba:	9fb5                	addw	a5,a5,a3
    80000ebc:	37fd                	addiw	a5,a5,-1
    *s++ = 0;
    80000ebe:	0705                	addi	a4,a4,1
    80000ec0:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000ec4:	40e786bb          	subw	a3,a5,a4
    80000ec8:	fed04be3          	bgtz	a3,80000ebe <strncpy+0x2a>
  return os;
}
    80000ecc:	60a2                	ld	ra,8(sp)
    80000ece:	6402                	ld	s0,0(sp)
    80000ed0:	0141                	addi	sp,sp,16
    80000ed2:	8082                	ret

0000000080000ed4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ed4:	1141                	addi	sp,sp,-16
    80000ed6:	e406                	sd	ra,8(sp)
    80000ed8:	e022                	sd	s0,0(sp)
    80000eda:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000edc:	02c05363          	blez	a2,80000f02 <safestrcpy+0x2e>
    80000ee0:	fff6069b          	addiw	a3,a2,-1
    80000ee4:	1682                	slli	a3,a3,0x20
    80000ee6:	9281                	srli	a3,a3,0x20
    80000ee8:	96ae                	add	a3,a3,a1
    80000eea:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000eec:	00d58963          	beq	a1,a3,80000efe <safestrcpy+0x2a>
    80000ef0:	0585                	addi	a1,a1,1
    80000ef2:	0785                	addi	a5,a5,1
    80000ef4:	fff5c703          	lbu	a4,-1(a1)
    80000ef8:	fee78fa3          	sb	a4,-1(a5)
    80000efc:	fb65                	bnez	a4,80000eec <safestrcpy+0x18>
    ;
  *s = 0;
    80000efe:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f02:	60a2                	ld	ra,8(sp)
    80000f04:	6402                	ld	s0,0(sp)
    80000f06:	0141                	addi	sp,sp,16
    80000f08:	8082                	ret

0000000080000f0a <strlen>:

int
strlen(const char *s)
{
    80000f0a:	1141                	addi	sp,sp,-16
    80000f0c:	e406                	sd	ra,8(sp)
    80000f0e:	e022                	sd	s0,0(sp)
    80000f10:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f12:	00054783          	lbu	a5,0(a0)
    80000f16:	cf99                	beqz	a5,80000f34 <strlen+0x2a>
    80000f18:	0505                	addi	a0,a0,1
    80000f1a:	87aa                	mv	a5,a0
    80000f1c:	86be                	mv	a3,a5
    80000f1e:	0785                	addi	a5,a5,1
    80000f20:	fff7c703          	lbu	a4,-1(a5)
    80000f24:	ff65                	bnez	a4,80000f1c <strlen+0x12>
    80000f26:	40a6853b          	subw	a0,a3,a0
    80000f2a:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000f2c:	60a2                	ld	ra,8(sp)
    80000f2e:	6402                	ld	s0,0(sp)
    80000f30:	0141                	addi	sp,sp,16
    80000f32:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f34:	4501                	li	a0,0
    80000f36:	bfdd                	j	80000f2c <strlen+0x22>

0000000080000f38 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f38:	1141                	addi	sp,sp,-16
    80000f3a:	e406                	sd	ra,8(sp)
    80000f3c:	e022                	sd	s0,0(sp)
    80000f3e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f40:	00001097          	auipc	ra,0x1
    80000f44:	b3c080e7          	jalr	-1220(ra) # 80001a7c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f48:	00008717          	auipc	a4,0x8
    80000f4c:	99070713          	addi	a4,a4,-1648 # 800088d8 <started>
  if(cpuid() == 0){
    80000f50:	c139                	beqz	a0,80000f96 <main+0x5e>
    while(started == 0)
    80000f52:	431c                	lw	a5,0(a4)
    80000f54:	2781                	sext.w	a5,a5
    80000f56:	dff5                	beqz	a5,80000f52 <main+0x1a>
      ;
    __sync_synchronize();
    80000f58:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000f5c:	00001097          	auipc	ra,0x1
    80000f60:	b20080e7          	jalr	-1248(ra) # 80001a7c <cpuid>
    80000f64:	85aa                	mv	a1,a0
    80000f66:	00007517          	auipc	a0,0x7
    80000f6a:	13250513          	addi	a0,a0,306 # 80008098 <etext+0x98>
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	63c080e7          	jalr	1596(ra) # 800005aa <printf>
    kvminithart();    // turn on paging
    80000f76:	00000097          	auipc	ra,0x0
    80000f7a:	0d8080e7          	jalr	216(ra) # 8000104e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f7e:	00002097          	auipc	ra,0x2
    80000f82:	822080e7          	jalr	-2014(ra) # 800027a0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	f7e080e7          	jalr	-130(ra) # 80005f04 <plicinithart>
  }

  scheduler();        
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	01a080e7          	jalr	26(ra) # 80001fa8 <scheduler>
    consoleinit();
    80000f96:	fffff097          	auipc	ra,0xfffff
    80000f9a:	4ec080e7          	jalr	1260(ra) # 80000482 <consoleinit>
    printfinit();
    80000f9e:	00000097          	auipc	ra,0x0
    80000fa2:	816080e7          	jalr	-2026(ra) # 800007b4 <printfinit>
    printf("\n");
    80000fa6:	00007517          	auipc	a0,0x7
    80000faa:	06a50513          	addi	a0,a0,106 # 80008010 <etext+0x10>
    80000fae:	fffff097          	auipc	ra,0xfffff
    80000fb2:	5fc080e7          	jalr	1532(ra) # 800005aa <printf>
    printf("xv6 kernel is booting\n");
    80000fb6:	00007517          	auipc	a0,0x7
    80000fba:	0ca50513          	addi	a0,a0,202 # 80008080 <etext+0x80>
    80000fbe:	fffff097          	auipc	ra,0xfffff
    80000fc2:	5ec080e7          	jalr	1516(ra) # 800005aa <printf>
    printf("\n");
    80000fc6:	00007517          	auipc	a0,0x7
    80000fca:	04a50513          	addi	a0,a0,74 # 80008010 <etext+0x10>
    80000fce:	fffff097          	auipc	ra,0xfffff
    80000fd2:	5dc080e7          	jalr	1500(ra) # 800005aa <printf>
    kinit();         // physical page allocator
    80000fd6:	00000097          	auipc	ra,0x0
    80000fda:	b38080e7          	jalr	-1224(ra) # 80000b0e <kinit>
    kvminit();       // create kernel page table
    80000fde:	00000097          	auipc	ra,0x0
    80000fe2:	32a080e7          	jalr	810(ra) # 80001308 <kvminit>
    kvminithart();   // turn on paging
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	068080e7          	jalr	104(ra) # 8000104e <kvminithart>
    procinit();      // process table
    80000fee:	00001097          	auipc	ra,0x1
    80000ff2:	9d2080e7          	jalr	-1582(ra) # 800019c0 <procinit>
    trapinit();      // trap vectors
    80000ff6:	00001097          	auipc	ra,0x1
    80000ffa:	782080e7          	jalr	1922(ra) # 80002778 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ffe:	00001097          	auipc	ra,0x1
    80001002:	7a2080e7          	jalr	1954(ra) # 800027a0 <trapinithart>
    plicinit();      // set up interrupt controller
    80001006:	00005097          	auipc	ra,0x5
    8000100a:	ee4080e7          	jalr	-284(ra) # 80005eea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000100e:	00005097          	auipc	ra,0x5
    80001012:	ef6080e7          	jalr	-266(ra) # 80005f04 <plicinithart>
    binit();         // buffer cache
    80001016:	00002097          	auipc	ra,0x2
    8000101a:	f74080e7          	jalr	-140(ra) # 80002f8a <binit>
    iinit();         // inode table
    8000101e:	00002097          	auipc	ra,0x2
    80001022:	604080e7          	jalr	1540(ra) # 80003622 <iinit>
    fileinit();      // file table
    80001026:	00003097          	auipc	ra,0x3
    8000102a:	5d6080e7          	jalr	1494(ra) # 800045fc <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000102e:	00005097          	auipc	ra,0x5
    80001032:	fde080e7          	jalr	-34(ra) # 8000600c <virtio_disk_init>
    userinit();      // first user process
    80001036:	00001097          	auipc	ra,0x1
    8000103a:	d52080e7          	jalr	-686(ra) # 80001d88 <userinit>
    __sync_synchronize();
    8000103e:	0330000f          	fence	rw,rw
    started = 1;
    80001042:	4785                	li	a5,1
    80001044:	00008717          	auipc	a4,0x8
    80001048:	88f72a23          	sw	a5,-1900(a4) # 800088d8 <started>
    8000104c:	b789                	j	80000f8e <main+0x56>

000000008000104e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000104e:	1141                	addi	sp,sp,-16
    80001050:	e406                	sd	ra,8(sp)
    80001052:	e022                	sd	s0,0(sp)
    80001054:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001056:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000105a:	00008797          	auipc	a5,0x8
    8000105e:	8867b783          	ld	a5,-1914(a5) # 800088e0 <kernel_pagetable>
    80001062:	83b1                	srli	a5,a5,0xc
    80001064:	577d                	li	a4,-1
    80001066:	177e                	slli	a4,a4,0x3f
    80001068:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000106a:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000106e:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001072:	60a2                	ld	ra,8(sp)
    80001074:	6402                	ld	s0,0(sp)
    80001076:	0141                	addi	sp,sp,16
    80001078:	8082                	ret

000000008000107a <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000107a:	7139                	addi	sp,sp,-64
    8000107c:	fc06                	sd	ra,56(sp)
    8000107e:	f822                	sd	s0,48(sp)
    80001080:	f426                	sd	s1,40(sp)
    80001082:	f04a                	sd	s2,32(sp)
    80001084:	ec4e                	sd	s3,24(sp)
    80001086:	e852                	sd	s4,16(sp)
    80001088:	e456                	sd	s5,8(sp)
    8000108a:	e05a                	sd	s6,0(sp)
    8000108c:	0080                	addi	s0,sp,64
    8000108e:	84aa                	mv	s1,a0
    80001090:	89ae                	mv	s3,a1
    80001092:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001094:	57fd                	li	a5,-1
    80001096:	83e9                	srli	a5,a5,0x1a
    80001098:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000109a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000109c:	04b7e263          	bltu	a5,a1,800010e0 <walk+0x66>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a0:	0149d933          	srl	s2,s3,s4
    800010a4:	1ff97913          	andi	s2,s2,511
    800010a8:	090e                	slli	s2,s2,0x3
    800010aa:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010ac:	00093483          	ld	s1,0(s2)
    800010b0:	0014f793          	andi	a5,s1,1
    800010b4:	cf95                	beqz	a5,800010f0 <walk+0x76>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010b6:	80a9                	srli	s1,s1,0xa
    800010b8:	04b2                	slli	s1,s1,0xc
  for(int level = 2; level > 0; level--) {
    800010ba:	3a5d                	addiw	s4,s4,-9
    800010bc:	ff6a12e3          	bne	s4,s6,800010a0 <walk+0x26>
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
    800010c0:	00c9d513          	srli	a0,s3,0xc
    800010c4:	1ff57513          	andi	a0,a0,511
    800010c8:	050e                	slli	a0,a0,0x3
    800010ca:	9526                	add	a0,a0,s1
}
    800010cc:	70e2                	ld	ra,56(sp)
    800010ce:	7442                	ld	s0,48(sp)
    800010d0:	74a2                	ld	s1,40(sp)
    800010d2:	7902                	ld	s2,32(sp)
    800010d4:	69e2                	ld	s3,24(sp)
    800010d6:	6a42                	ld	s4,16(sp)
    800010d8:	6aa2                	ld	s5,8(sp)
    800010da:	6b02                	ld	s6,0(sp)
    800010dc:	6121                	addi	sp,sp,64
    800010de:	8082                	ret
    panic("walk");
    800010e0:	00007517          	auipc	a0,0x7
    800010e4:	fd050513          	addi	a0,a0,-48 # 800080b0 <etext+0xb0>
    800010e8:	fffff097          	auipc	ra,0xfffff
    800010ec:	478080e7          	jalr	1144(ra) # 80000560 <panic>
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010f0:	020a8663          	beqz	s5,8000111c <walk+0xa2>
    800010f4:	00000097          	auipc	ra,0x0
    800010f8:	a56080e7          	jalr	-1450(ra) # 80000b4a <kalloc>
    800010fc:	84aa                	mv	s1,a0
    800010fe:	d579                	beqz	a0,800010cc <walk+0x52>
      memset(pagetable, 0, PGSIZE);
    80001100:	6605                	lui	a2,0x1
    80001102:	4581                	li	a1,0
    80001104:	00000097          	auipc	ra,0x0
    80001108:	c7a080e7          	jalr	-902(ra) # 80000d7e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000110c:	00c4d793          	srli	a5,s1,0xc
    80001110:	07aa                	slli	a5,a5,0xa
    80001112:	0017e793          	ori	a5,a5,1
    80001116:	00f93023          	sd	a5,0(s2)
    8000111a:	b745                	j	800010ba <walk+0x40>
        return 0;
    8000111c:	4501                	li	a0,0
    8000111e:	b77d                	j	800010cc <walk+0x52>

0000000080001120 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001120:	57fd                	li	a5,-1
    80001122:	83e9                	srli	a5,a5,0x1a
    80001124:	00b7f463          	bgeu	a5,a1,8000112c <walkaddr+0xc>
    return 0;
    80001128:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000112a:	8082                	ret
{
    8000112c:	1141                	addi	sp,sp,-16
    8000112e:	e406                	sd	ra,8(sp)
    80001130:	e022                	sd	s0,0(sp)
    80001132:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001134:	4601                	li	a2,0
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	f44080e7          	jalr	-188(ra) # 8000107a <walk>
  if(pte == 0)
    8000113e:	c105                	beqz	a0,8000115e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001140:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001142:	0117f693          	andi	a3,a5,17
    80001146:	4745                	li	a4,17
    return 0;
    80001148:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000114a:	00e68663          	beq	a3,a4,80001156 <walkaddr+0x36>
}
    8000114e:	60a2                	ld	ra,8(sp)
    80001150:	6402                	ld	s0,0(sp)
    80001152:	0141                	addi	sp,sp,16
    80001154:	8082                	ret
  pa = PTE2PA(*pte);
    80001156:	83a9                	srli	a5,a5,0xa
    80001158:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000115c:	bfcd                	j	8000114e <walkaddr+0x2e>
    return 0;
    8000115e:	4501                	li	a0,0
    80001160:	b7fd                	j	8000114e <walkaddr+0x2e>

0000000080001162 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001162:	715d                	addi	sp,sp,-80
    80001164:	e486                	sd	ra,72(sp)
    80001166:	e0a2                	sd	s0,64(sp)
    80001168:	fc26                	sd	s1,56(sp)
    8000116a:	f84a                	sd	s2,48(sp)
    8000116c:	f44e                	sd	s3,40(sp)
    8000116e:	f052                	sd	s4,32(sp)
    80001170:	ec56                	sd	s5,24(sp)
    80001172:	e85a                	sd	s6,16(sp)
    80001174:	e45e                	sd	s7,8(sp)
    80001176:	e062                	sd	s8,0(sp)
    80001178:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000117a:	ca21                	beqz	a2,800011ca <mappages+0x68>
    8000117c:	8aaa                	mv	s5,a0
    8000117e:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001180:	777d                	lui	a4,0xfffff
    80001182:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001186:	fff58993          	addi	s3,a1,-1
    8000118a:	99b2                	add	s3,s3,a2
    8000118c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001190:	893e                	mv	s2,a5
    80001192:	40f68a33          	sub	s4,a3,a5
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
    80001196:	4b85                	li	s7,1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001198:	6c05                	lui	s8,0x1
    8000119a:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	865e                	mv	a2,s7
    800011a0:	85ca                	mv	a1,s2
    800011a2:	8556                	mv	a0,s5
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	ed6080e7          	jalr	-298(ra) # 8000107a <walk>
    800011ac:	cd1d                	beqz	a0,800011ea <mappages+0x88>
    if(*pte & PTE_V)
    800011ae:	611c                	ld	a5,0(a0)
    800011b0:	8b85                	andi	a5,a5,1
    800011b2:	e785                	bnez	a5,800011da <mappages+0x78>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011b4:	80b1                	srli	s1,s1,0xc
    800011b6:	04aa                	slli	s1,s1,0xa
    800011b8:	0164e4b3          	or	s1,s1,s6
    800011bc:	0014e493          	ori	s1,s1,1
    800011c0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011c2:	05390163          	beq	s2,s3,80001204 <mappages+0xa2>
    a += PGSIZE;
    800011c6:	9962                	add	s2,s2,s8
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c8:	bfc9                	j	8000119a <mappages+0x38>
    panic("mappages: size");
    800011ca:	00007517          	auipc	a0,0x7
    800011ce:	eee50513          	addi	a0,a0,-274 # 800080b8 <etext+0xb8>
    800011d2:	fffff097          	auipc	ra,0xfffff
    800011d6:	38e080e7          	jalr	910(ra) # 80000560 <panic>
      panic("mappages: remap");
    800011da:	00007517          	auipc	a0,0x7
    800011de:	eee50513          	addi	a0,a0,-274 # 800080c8 <etext+0xc8>
    800011e2:	fffff097          	auipc	ra,0xfffff
    800011e6:	37e080e7          	jalr	894(ra) # 80000560 <panic>
      return -1;
    800011ea:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011ec:	60a6                	ld	ra,72(sp)
    800011ee:	6406                	ld	s0,64(sp)
    800011f0:	74e2                	ld	s1,56(sp)
    800011f2:	7942                	ld	s2,48(sp)
    800011f4:	79a2                	ld	s3,40(sp)
    800011f6:	7a02                	ld	s4,32(sp)
    800011f8:	6ae2                	ld	s5,24(sp)
    800011fa:	6b42                	ld	s6,16(sp)
    800011fc:	6ba2                	ld	s7,8(sp)
    800011fe:	6c02                	ld	s8,0(sp)
    80001200:	6161                	addi	sp,sp,80
    80001202:	8082                	ret
  return 0;
    80001204:	4501                	li	a0,0
    80001206:	b7dd                	j	800011ec <mappages+0x8a>

0000000080001208 <kvmmap>:
{
    80001208:	1141                	addi	sp,sp,-16
    8000120a:	e406                	sd	ra,8(sp)
    8000120c:	e022                	sd	s0,0(sp)
    8000120e:	0800                	addi	s0,sp,16
    80001210:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001212:	86b2                	mv	a3,a2
    80001214:	863e                	mv	a2,a5
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	f4c080e7          	jalr	-180(ra) # 80001162 <mappages>
    8000121e:	e509                	bnez	a0,80001228 <kvmmap+0x20>
}
    80001220:	60a2                	ld	ra,8(sp)
    80001222:	6402                	ld	s0,0(sp)
    80001224:	0141                	addi	sp,sp,16
    80001226:	8082                	ret
    panic("kvmmap");
    80001228:	00007517          	auipc	a0,0x7
    8000122c:	eb050513          	addi	a0,a0,-336 # 800080d8 <etext+0xd8>
    80001230:	fffff097          	auipc	ra,0xfffff
    80001234:	330080e7          	jalr	816(ra) # 80000560 <panic>

0000000080001238 <kvmmake>:
{
    80001238:	1101                	addi	sp,sp,-32
    8000123a:	ec06                	sd	ra,24(sp)
    8000123c:	e822                	sd	s0,16(sp)
    8000123e:	e426                	sd	s1,8(sp)
    80001240:	e04a                	sd	s2,0(sp)
    80001242:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001244:	00000097          	auipc	ra,0x0
    80001248:	906080e7          	jalr	-1786(ra) # 80000b4a <kalloc>
    8000124c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000124e:	6605                	lui	a2,0x1
    80001250:	4581                	li	a1,0
    80001252:	00000097          	auipc	ra,0x0
    80001256:	b2c080e7          	jalr	-1236(ra) # 80000d7e <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000125a:	4719                	li	a4,6
    8000125c:	6685                	lui	a3,0x1
    8000125e:	10000637          	lui	a2,0x10000
    80001262:	85b2                	mv	a1,a2
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	fa2080e7          	jalr	-94(ra) # 80001208 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	6685                	lui	a3,0x1
    80001272:	10001637          	lui	a2,0x10001
    80001276:	85b2                	mv	a1,a2
    80001278:	8526                	mv	a0,s1
    8000127a:	00000097          	auipc	ra,0x0
    8000127e:	f8e080e7          	jalr	-114(ra) # 80001208 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001282:	4719                	li	a4,6
    80001284:	004006b7          	lui	a3,0x400
    80001288:	0c000637          	lui	a2,0xc000
    8000128c:	85b2                	mv	a1,a2
    8000128e:	8526                	mv	a0,s1
    80001290:	00000097          	auipc	ra,0x0
    80001294:	f78080e7          	jalr	-136(ra) # 80001208 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001298:	00007917          	auipc	s2,0x7
    8000129c:	d6890913          	addi	s2,s2,-664 # 80008000 <etext>
    800012a0:	4729                	li	a4,10
    800012a2:	80007697          	auipc	a3,0x80007
    800012a6:	d5e68693          	addi	a3,a3,-674 # 8000 <_entry-0x7fff8000>
    800012aa:	4605                	li	a2,1
    800012ac:	067e                	slli	a2,a2,0x1f
    800012ae:	85b2                	mv	a1,a2
    800012b0:	8526                	mv	a0,s1
    800012b2:	00000097          	auipc	ra,0x0
    800012b6:	f56080e7          	jalr	-170(ra) # 80001208 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ba:	4719                	li	a4,6
    800012bc:	46c5                	li	a3,17
    800012be:	06ee                	slli	a3,a3,0x1b
    800012c0:	412686b3          	sub	a3,a3,s2
    800012c4:	864a                	mv	a2,s2
    800012c6:	85ca                	mv	a1,s2
    800012c8:	8526                	mv	a0,s1
    800012ca:	00000097          	auipc	ra,0x0
    800012ce:	f3e080e7          	jalr	-194(ra) # 80001208 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012d2:	4729                	li	a4,10
    800012d4:	6685                	lui	a3,0x1
    800012d6:	00006617          	auipc	a2,0x6
    800012da:	d2a60613          	addi	a2,a2,-726 # 80007000 <_trampoline>
    800012de:	040005b7          	lui	a1,0x4000
    800012e2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800012e4:	05b2                	slli	a1,a1,0xc
    800012e6:	8526                	mv	a0,s1
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	f20080e7          	jalr	-224(ra) # 80001208 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012f0:	8526                	mv	a0,s1
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	624080e7          	jalr	1572(ra) # 80001916 <proc_mapstacks>
}
    800012fa:	8526                	mv	a0,s1
    800012fc:	60e2                	ld	ra,24(sp)
    800012fe:	6442                	ld	s0,16(sp)
    80001300:	64a2                	ld	s1,8(sp)
    80001302:	6902                	ld	s2,0(sp)
    80001304:	6105                	addi	sp,sp,32
    80001306:	8082                	ret

0000000080001308 <kvminit>:
{
    80001308:	1141                	addi	sp,sp,-16
    8000130a:	e406                	sd	ra,8(sp)
    8000130c:	e022                	sd	s0,0(sp)
    8000130e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001310:	00000097          	auipc	ra,0x0
    80001314:	f28080e7          	jalr	-216(ra) # 80001238 <kvmmake>
    80001318:	00007797          	auipc	a5,0x7
    8000131c:	5ca7b423          	sd	a0,1480(a5) # 800088e0 <kernel_pagetable>
}
    80001320:	60a2                	ld	ra,8(sp)
    80001322:	6402                	ld	s0,0(sp)
    80001324:	0141                	addi	sp,sp,16
    80001326:	8082                	ret

0000000080001328 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001328:	715d                	addi	sp,sp,-80
    8000132a:	e486                	sd	ra,72(sp)
    8000132c:	e0a2                	sd	s0,64(sp)
    8000132e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001330:	03459793          	slli	a5,a1,0x34
    80001334:	e39d                	bnez	a5,8000135a <uvmunmap+0x32>
    80001336:	f84a                	sd	s2,48(sp)
    80001338:	f44e                	sd	s3,40(sp)
    8000133a:	f052                	sd	s4,32(sp)
    8000133c:	ec56                	sd	s5,24(sp)
    8000133e:	e85a                	sd	s6,16(sp)
    80001340:	e45e                	sd	s7,8(sp)
    80001342:	8a2a                	mv	s4,a0
    80001344:	892e                	mv	s2,a1
    80001346:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001348:	0632                	slli	a2,a2,0xc
    8000134a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000134e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001350:	6b05                	lui	s6,0x1
    80001352:	0935fb63          	bgeu	a1,s3,800013e8 <uvmunmap+0xc0>
    80001356:	fc26                	sd	s1,56(sp)
    80001358:	a8a9                	j	800013b2 <uvmunmap+0x8a>
    8000135a:	fc26                	sd	s1,56(sp)
    8000135c:	f84a                	sd	s2,48(sp)
    8000135e:	f44e                	sd	s3,40(sp)
    80001360:	f052                	sd	s4,32(sp)
    80001362:	ec56                	sd	s5,24(sp)
    80001364:	e85a                	sd	s6,16(sp)
    80001366:	e45e                	sd	s7,8(sp)
    panic("uvmunmap: not aligned");
    80001368:	00007517          	auipc	a0,0x7
    8000136c:	d7850513          	addi	a0,a0,-648 # 800080e0 <etext+0xe0>
    80001370:	fffff097          	auipc	ra,0xfffff
    80001374:	1f0080e7          	jalr	496(ra) # 80000560 <panic>
      panic("uvmunmap: walk");
    80001378:	00007517          	auipc	a0,0x7
    8000137c:	d8050513          	addi	a0,a0,-640 # 800080f8 <etext+0xf8>
    80001380:	fffff097          	auipc	ra,0xfffff
    80001384:	1e0080e7          	jalr	480(ra) # 80000560 <panic>
      panic("uvmunmap: not mapped");
    80001388:	00007517          	auipc	a0,0x7
    8000138c:	d8050513          	addi	a0,a0,-640 # 80008108 <etext+0x108>
    80001390:	fffff097          	auipc	ra,0xfffff
    80001394:	1d0080e7          	jalr	464(ra) # 80000560 <panic>
      panic("uvmunmap: not a leaf");
    80001398:	00007517          	auipc	a0,0x7
    8000139c:	d8850513          	addi	a0,a0,-632 # 80008120 <etext+0x120>
    800013a0:	fffff097          	auipc	ra,0xfffff
    800013a4:	1c0080e7          	jalr	448(ra) # 80000560 <panic>
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    800013a8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013ac:	995a                	add	s2,s2,s6
    800013ae:	03397c63          	bgeu	s2,s3,800013e6 <uvmunmap+0xbe>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013b2:	4601                	li	a2,0
    800013b4:	85ca                	mv	a1,s2
    800013b6:	8552                	mv	a0,s4
    800013b8:	00000097          	auipc	ra,0x0
    800013bc:	cc2080e7          	jalr	-830(ra) # 8000107a <walk>
    800013c0:	84aa                	mv	s1,a0
    800013c2:	d95d                	beqz	a0,80001378 <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)
    800013c4:	6108                	ld	a0,0(a0)
    800013c6:	00157793          	andi	a5,a0,1
    800013ca:	dfdd                	beqz	a5,80001388 <uvmunmap+0x60>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013cc:	3ff57793          	andi	a5,a0,1023
    800013d0:	fd7784e3          	beq	a5,s7,80001398 <uvmunmap+0x70>
    if(do_free){
    800013d4:	fc0a8ae3          	beqz	s5,800013a8 <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
    800013d8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013da:	0532                	slli	a0,a0,0xc
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	670080e7          	jalr	1648(ra) # 80000a4c <kfree>
    800013e4:	b7d1                	j	800013a8 <uvmunmap+0x80>
    800013e6:	74e2                	ld	s1,56(sp)
    800013e8:	7942                	ld	s2,48(sp)
    800013ea:	79a2                	ld	s3,40(sp)
    800013ec:	7a02                	ld	s4,32(sp)
    800013ee:	6ae2                	ld	s5,24(sp)
    800013f0:	6b42                	ld	s6,16(sp)
    800013f2:	6ba2                	ld	s7,8(sp)
  }
}
    800013f4:	60a6                	ld	ra,72(sp)
    800013f6:	6406                	ld	s0,64(sp)
    800013f8:	6161                	addi	sp,sp,80
    800013fa:	8082                	ret

00000000800013fc <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013fc:	1101                	addi	sp,sp,-32
    800013fe:	ec06                	sd	ra,24(sp)
    80001400:	e822                	sd	s0,16(sp)
    80001402:	e426                	sd	s1,8(sp)
    80001404:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001406:	fffff097          	auipc	ra,0xfffff
    8000140a:	744080e7          	jalr	1860(ra) # 80000b4a <kalloc>
    8000140e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001410:	c519                	beqz	a0,8000141e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001412:	6605                	lui	a2,0x1
    80001414:	4581                	li	a1,0
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	968080e7          	jalr	-1688(ra) # 80000d7e <memset>
  return pagetable;
}
    8000141e:	8526                	mv	a0,s1
    80001420:	60e2                	ld	ra,24(sp)
    80001422:	6442                	ld	s0,16(sp)
    80001424:	64a2                	ld	s1,8(sp)
    80001426:	6105                	addi	sp,sp,32
    80001428:	8082                	ret

000000008000142a <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000142a:	7179                	addi	sp,sp,-48
    8000142c:	f406                	sd	ra,40(sp)
    8000142e:	f022                	sd	s0,32(sp)
    80001430:	ec26                	sd	s1,24(sp)
    80001432:	e84a                	sd	s2,16(sp)
    80001434:	e44e                	sd	s3,8(sp)
    80001436:	e052                	sd	s4,0(sp)
    80001438:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000143a:	6785                	lui	a5,0x1
    8000143c:	04f67863          	bgeu	a2,a5,8000148c <uvmfirst+0x62>
    80001440:	8a2a                	mv	s4,a0
    80001442:	89ae                	mv	s3,a1
    80001444:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001446:	fffff097          	auipc	ra,0xfffff
    8000144a:	704080e7          	jalr	1796(ra) # 80000b4a <kalloc>
    8000144e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001450:	6605                	lui	a2,0x1
    80001452:	4581                	li	a1,0
    80001454:	00000097          	auipc	ra,0x0
    80001458:	92a080e7          	jalr	-1750(ra) # 80000d7e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000145c:	4779                	li	a4,30
    8000145e:	86ca                	mv	a3,s2
    80001460:	6605                	lui	a2,0x1
    80001462:	4581                	li	a1,0
    80001464:	8552                	mv	a0,s4
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	cfc080e7          	jalr	-772(ra) # 80001162 <mappages>
  memmove(mem, src, sz);
    8000146e:	8626                	mv	a2,s1
    80001470:	85ce                	mv	a1,s3
    80001472:	854a                	mv	a0,s2
    80001474:	00000097          	auipc	ra,0x0
    80001478:	96e080e7          	jalr	-1682(ra) # 80000de2 <memmove>
}
    8000147c:	70a2                	ld	ra,40(sp)
    8000147e:	7402                	ld	s0,32(sp)
    80001480:	64e2                	ld	s1,24(sp)
    80001482:	6942                	ld	s2,16(sp)
    80001484:	69a2                	ld	s3,8(sp)
    80001486:	6a02                	ld	s4,0(sp)
    80001488:	6145                	addi	sp,sp,48
    8000148a:	8082                	ret
    panic("uvmfirst: more than a page");
    8000148c:	00007517          	auipc	a0,0x7
    80001490:	cac50513          	addi	a0,a0,-852 # 80008138 <etext+0x138>
    80001494:	fffff097          	auipc	ra,0xfffff
    80001498:	0cc080e7          	jalr	204(ra) # 80000560 <panic>

000000008000149c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000149c:	1101                	addi	sp,sp,-32
    8000149e:	ec06                	sd	ra,24(sp)
    800014a0:	e822                	sd	s0,16(sp)
    800014a2:	e426                	sd	s1,8(sp)
    800014a4:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014a6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014a8:	00b67d63          	bgeu	a2,a1,800014c2 <uvmdealloc+0x26>
    800014ac:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014ae:	6785                	lui	a5,0x1
    800014b0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014b2:	00f60733          	add	a4,a2,a5
    800014b6:	76fd                	lui	a3,0xfffff
    800014b8:	8f75                	and	a4,a4,a3
    800014ba:	97ae                	add	a5,a5,a1
    800014bc:	8ff5                	and	a5,a5,a3
    800014be:	00f76863          	bltu	a4,a5,800014ce <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014c2:	8526                	mv	a0,s1
    800014c4:	60e2                	ld	ra,24(sp)
    800014c6:	6442                	ld	s0,16(sp)
    800014c8:	64a2                	ld	s1,8(sp)
    800014ca:	6105                	addi	sp,sp,32
    800014cc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014ce:	8f99                	sub	a5,a5,a4
    800014d0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014d2:	4685                	li	a3,1
    800014d4:	0007861b          	sext.w	a2,a5
    800014d8:	85ba                	mv	a1,a4
    800014da:	00000097          	auipc	ra,0x0
    800014de:	e4e080e7          	jalr	-434(ra) # 80001328 <uvmunmap>
    800014e2:	b7c5                	j	800014c2 <uvmdealloc+0x26>

00000000800014e4 <uvmalloc>:
  if(newsz < oldsz)
    800014e4:	0ab66f63          	bltu	a2,a1,800015a2 <uvmalloc+0xbe>
{
    800014e8:	715d                	addi	sp,sp,-80
    800014ea:	e486                	sd	ra,72(sp)
    800014ec:	e0a2                	sd	s0,64(sp)
    800014ee:	f052                	sd	s4,32(sp)
    800014f0:	ec56                	sd	s5,24(sp)
    800014f2:	e85a                	sd	s6,16(sp)
    800014f4:	0880                	addi	s0,sp,80
    800014f6:	8b2a                	mv	s6,a0
    800014f8:	8ab2                	mv	s5,a2
  oldsz = PGROUNDUP(oldsz);
    800014fa:	6785                	lui	a5,0x1
    800014fc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014fe:	95be                	add	a1,a1,a5
    80001500:	77fd                	lui	a5,0xfffff
    80001502:	00f5fa33          	and	s4,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001506:	0aca7063          	bgeu	s4,a2,800015a6 <uvmalloc+0xc2>
    8000150a:	fc26                	sd	s1,56(sp)
    8000150c:	f84a                	sd	s2,48(sp)
    8000150e:	f44e                	sd	s3,40(sp)
    80001510:	e45e                	sd	s7,8(sp)
    80001512:	8952                	mv	s2,s4
    memset(mem, 0, PGSIZE);
    80001514:	6985                	lui	s3,0x1
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001516:	0126eb93          	ori	s7,a3,18
    mem = kalloc();
    8000151a:	fffff097          	auipc	ra,0xfffff
    8000151e:	630080e7          	jalr	1584(ra) # 80000b4a <kalloc>
    80001522:	84aa                	mv	s1,a0
    if(mem == 0){
    80001524:	c915                	beqz	a0,80001558 <uvmalloc+0x74>
    memset(mem, 0, PGSIZE);
    80001526:	864e                	mv	a2,s3
    80001528:	4581                	li	a1,0
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	854080e7          	jalr	-1964(ra) # 80000d7e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001532:	875e                	mv	a4,s7
    80001534:	86a6                	mv	a3,s1
    80001536:	864e                	mv	a2,s3
    80001538:	85ca                	mv	a1,s2
    8000153a:	855a                	mv	a0,s6
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	c26080e7          	jalr	-986(ra) # 80001162 <mappages>
    80001544:	ed0d                	bnez	a0,8000157e <uvmalloc+0x9a>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001546:	994e                	add	s2,s2,s3
    80001548:	fd5969e3          	bltu	s2,s5,8000151a <uvmalloc+0x36>
  return newsz;
    8000154c:	8556                	mv	a0,s5
    8000154e:	74e2                	ld	s1,56(sp)
    80001550:	7942                	ld	s2,48(sp)
    80001552:	79a2                	ld	s3,40(sp)
    80001554:	6ba2                	ld	s7,8(sp)
    80001556:	a829                	j	80001570 <uvmalloc+0x8c>
      uvmdealloc(pagetable, a, oldsz);
    80001558:	8652                	mv	a2,s4
    8000155a:	85ca                	mv	a1,s2
    8000155c:	855a                	mv	a0,s6
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	f3e080e7          	jalr	-194(ra) # 8000149c <uvmdealloc>
      return 0;
    80001566:	4501                	li	a0,0
    80001568:	74e2                	ld	s1,56(sp)
    8000156a:	7942                	ld	s2,48(sp)
    8000156c:	79a2                	ld	s3,40(sp)
    8000156e:	6ba2                	ld	s7,8(sp)
}
    80001570:	60a6                	ld	ra,72(sp)
    80001572:	6406                	ld	s0,64(sp)
    80001574:	7a02                	ld	s4,32(sp)
    80001576:	6ae2                	ld	s5,24(sp)
    80001578:	6b42                	ld	s6,16(sp)
    8000157a:	6161                	addi	sp,sp,80
    8000157c:	8082                	ret
      kfree(mem);
    8000157e:	8526                	mv	a0,s1
    80001580:	fffff097          	auipc	ra,0xfffff
    80001584:	4cc080e7          	jalr	1228(ra) # 80000a4c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001588:	8652                	mv	a2,s4
    8000158a:	85ca                	mv	a1,s2
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	f0e080e7          	jalr	-242(ra) # 8000149c <uvmdealloc>
      return 0;
    80001596:	4501                	li	a0,0
    80001598:	74e2                	ld	s1,56(sp)
    8000159a:	7942                	ld	s2,48(sp)
    8000159c:	79a2                	ld	s3,40(sp)
    8000159e:	6ba2                	ld	s7,8(sp)
    800015a0:	bfc1                	j	80001570 <uvmalloc+0x8c>
    return oldsz;
    800015a2:	852e                	mv	a0,a1
}
    800015a4:	8082                	ret
  return newsz;
    800015a6:	8532                	mv	a0,a2
    800015a8:	b7e1                	j	80001570 <uvmalloc+0x8c>

00000000800015aa <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015aa:	7179                	addi	sp,sp,-48
    800015ac:	f406                	sd	ra,40(sp)
    800015ae:	f022                	sd	s0,32(sp)
    800015b0:	ec26                	sd	s1,24(sp)
    800015b2:	e84a                	sd	s2,16(sp)
    800015b4:	e44e                	sd	s3,8(sp)
    800015b6:	e052                	sd	s4,0(sp)
    800015b8:	1800                	addi	s0,sp,48
    800015ba:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015bc:	84aa                	mv	s1,a0
    800015be:	6905                	lui	s2,0x1
    800015c0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015c2:	4985                	li	s3,1
    800015c4:	a829                	j	800015de <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015c6:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015c8:	00c79513          	slli	a0,a5,0xc
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	fde080e7          	jalr	-34(ra) # 800015aa <freewalk>
      pagetable[i] = 0;
    800015d4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015d8:	04a1                	addi	s1,s1,8
    800015da:	03248163          	beq	s1,s2,800015fc <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015de:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e0:	00f7f713          	andi	a4,a5,15
    800015e4:	ff3701e3          	beq	a4,s3,800015c6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015e8:	8b85                	andi	a5,a5,1
    800015ea:	d7fd                	beqz	a5,800015d8 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015ec:	00007517          	auipc	a0,0x7
    800015f0:	b6c50513          	addi	a0,a0,-1172 # 80008158 <etext+0x158>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f6c080e7          	jalr	-148(ra) # 80000560 <panic>
    }
  }
  kfree((void*)pagetable);
    800015fc:	8552                	mv	a0,s4
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	44e080e7          	jalr	1102(ra) # 80000a4c <kfree>
}
    80001606:	70a2                	ld	ra,40(sp)
    80001608:	7402                	ld	s0,32(sp)
    8000160a:	64e2                	ld	s1,24(sp)
    8000160c:	6942                	ld	s2,16(sp)
    8000160e:	69a2                	ld	s3,8(sp)
    80001610:	6a02                	ld	s4,0(sp)
    80001612:	6145                	addi	sp,sp,48
    80001614:	8082                	ret

0000000080001616 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001616:	1101                	addi	sp,sp,-32
    80001618:	ec06                	sd	ra,24(sp)
    8000161a:	e822                	sd	s0,16(sp)
    8000161c:	e426                	sd	s1,8(sp)
    8000161e:	1000                	addi	s0,sp,32
    80001620:	84aa                	mv	s1,a0
  if(sz > 0)
    80001622:	e999                	bnez	a1,80001638 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001624:	8526                	mv	a0,s1
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	f84080e7          	jalr	-124(ra) # 800015aa <freewalk>
}
    8000162e:	60e2                	ld	ra,24(sp)
    80001630:	6442                	ld	s0,16(sp)
    80001632:	64a2                	ld	s1,8(sp)
    80001634:	6105                	addi	sp,sp,32
    80001636:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001638:	6785                	lui	a5,0x1
    8000163a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000163c:	95be                	add	a1,a1,a5
    8000163e:	4685                	li	a3,1
    80001640:	00c5d613          	srli	a2,a1,0xc
    80001644:	4581                	li	a1,0
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	ce2080e7          	jalr	-798(ra) # 80001328 <uvmunmap>
    8000164e:	bfd9                	j	80001624 <uvmfree+0xe>

0000000080001650 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001650:	ca69                	beqz	a2,80001722 <uvmcopy+0xd2>
{
    80001652:	715d                	addi	sp,sp,-80
    80001654:	e486                	sd	ra,72(sp)
    80001656:	e0a2                	sd	s0,64(sp)
    80001658:	fc26                	sd	s1,56(sp)
    8000165a:	f84a                	sd	s2,48(sp)
    8000165c:	f44e                	sd	s3,40(sp)
    8000165e:	f052                	sd	s4,32(sp)
    80001660:	ec56                	sd	s5,24(sp)
    80001662:	e85a                	sd	s6,16(sp)
    80001664:	e45e                	sd	s7,8(sp)
    80001666:	e062                	sd	s8,0(sp)
    80001668:	0880                	addi	s0,sp,80
    8000166a:	8baa                	mv	s7,a0
    8000166c:	8b2e                	mv	s6,a1
    8000166e:	8ab2                	mv	s5,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001670:	4981                	li	s3,0
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001672:	6a05                	lui	s4,0x1
    if((pte = walk(old, i, 0)) == 0)
    80001674:	4601                	li	a2,0
    80001676:	85ce                	mv	a1,s3
    80001678:	855e                	mv	a0,s7
    8000167a:	00000097          	auipc	ra,0x0
    8000167e:	a00080e7          	jalr	-1536(ra) # 8000107a <walk>
    80001682:	c529                	beqz	a0,800016cc <uvmcopy+0x7c>
    if((*pte & PTE_V) == 0)
    80001684:	6118                	ld	a4,0(a0)
    80001686:	00177793          	andi	a5,a4,1
    8000168a:	cba9                	beqz	a5,800016dc <uvmcopy+0x8c>
    pa = PTE2PA(*pte);
    8000168c:	00a75593          	srli	a1,a4,0xa
    80001690:	00c59c13          	slli	s8,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001694:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001698:	fffff097          	auipc	ra,0xfffff
    8000169c:	4b2080e7          	jalr	1202(ra) # 80000b4a <kalloc>
    800016a0:	892a                	mv	s2,a0
    800016a2:	c931                	beqz	a0,800016f6 <uvmcopy+0xa6>
    memmove(mem, (char*)pa, PGSIZE);
    800016a4:	8652                	mv	a2,s4
    800016a6:	85e2                	mv	a1,s8
    800016a8:	fffff097          	auipc	ra,0xfffff
    800016ac:	73a080e7          	jalr	1850(ra) # 80000de2 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016b0:	8726                	mv	a4,s1
    800016b2:	86ca                	mv	a3,s2
    800016b4:	8652                	mv	a2,s4
    800016b6:	85ce                	mv	a1,s3
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	aa8080e7          	jalr	-1368(ra) # 80001162 <mappages>
    800016c2:	e50d                	bnez	a0,800016ec <uvmcopy+0x9c>
  for(i = 0; i < sz; i += PGSIZE){
    800016c4:	99d2                	add	s3,s3,s4
    800016c6:	fb59e7e3          	bltu	s3,s5,80001674 <uvmcopy+0x24>
    800016ca:	a081                	j	8000170a <uvmcopy+0xba>
      panic("uvmcopy: pte should exist");
    800016cc:	00007517          	auipc	a0,0x7
    800016d0:	a9c50513          	addi	a0,a0,-1380 # 80008168 <etext+0x168>
    800016d4:	fffff097          	auipc	ra,0xfffff
    800016d8:	e8c080e7          	jalr	-372(ra) # 80000560 <panic>
      panic("uvmcopy: page not present");
    800016dc:	00007517          	auipc	a0,0x7
    800016e0:	aac50513          	addi	a0,a0,-1364 # 80008188 <etext+0x188>
    800016e4:	fffff097          	auipc	ra,0xfffff
    800016e8:	e7c080e7          	jalr	-388(ra) # 80000560 <panic>
      kfree(mem);
    800016ec:	854a                	mv	a0,s2
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	35e080e7          	jalr	862(ra) # 80000a4c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016f6:	4685                	li	a3,1
    800016f8:	00c9d613          	srli	a2,s3,0xc
    800016fc:	4581                	li	a1,0
    800016fe:	855a                	mv	a0,s6
    80001700:	00000097          	auipc	ra,0x0
    80001704:	c28080e7          	jalr	-984(ra) # 80001328 <uvmunmap>
  return -1;
    80001708:	557d                	li	a0,-1
}
    8000170a:	60a6                	ld	ra,72(sp)
    8000170c:	6406                	ld	s0,64(sp)
    8000170e:	74e2                	ld	s1,56(sp)
    80001710:	7942                	ld	s2,48(sp)
    80001712:	79a2                	ld	s3,40(sp)
    80001714:	7a02                	ld	s4,32(sp)
    80001716:	6ae2                	ld	s5,24(sp)
    80001718:	6b42                	ld	s6,16(sp)
    8000171a:	6ba2                	ld	s7,8(sp)
    8000171c:	6c02                	ld	s8,0(sp)
    8000171e:	6161                	addi	sp,sp,80
    80001720:	8082                	ret
  return 0;
    80001722:	4501                	li	a0,0
}
    80001724:	8082                	ret

0000000080001726 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001726:	1141                	addi	sp,sp,-16
    80001728:	e406                	sd	ra,8(sp)
    8000172a:	e022                	sd	s0,0(sp)
    8000172c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000172e:	4601                	li	a2,0
    80001730:	00000097          	auipc	ra,0x0
    80001734:	94a080e7          	jalr	-1718(ra) # 8000107a <walk>
  if(pte == 0)
    80001738:	c901                	beqz	a0,80001748 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000173a:	611c                	ld	a5,0(a0)
    8000173c:	9bbd                	andi	a5,a5,-17
    8000173e:	e11c                	sd	a5,0(a0)
}
    80001740:	60a2                	ld	ra,8(sp)
    80001742:	6402                	ld	s0,0(sp)
    80001744:	0141                	addi	sp,sp,16
    80001746:	8082                	ret
    panic("uvmclear");
    80001748:	00007517          	auipc	a0,0x7
    8000174c:	a6050513          	addi	a0,a0,-1440 # 800081a8 <etext+0x1a8>
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	e10080e7          	jalr	-496(ra) # 80000560 <panic>

0000000080001758 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001758:	c6bd                	beqz	a3,800017c6 <copyout+0x6e>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	e062                	sd	s8,0(sp)
    80001770:	0880                	addi	s0,sp,80
    80001772:	8b2a                	mv	s6,a0
    80001774:	8c2e                	mv	s8,a1
    80001776:	8a32                	mv	s4,a2
    80001778:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000177a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000177c:	6a85                	lui	s5,0x1
    8000177e:	a015                	j	800017a2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001780:	9562                	add	a0,a0,s8
    80001782:	0004861b          	sext.w	a2,s1
    80001786:	85d2                	mv	a1,s4
    80001788:	41250533          	sub	a0,a0,s2
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	656080e7          	jalr	1622(ra) # 80000de2 <memmove>

    len -= n;
    80001794:	409989b3          	sub	s3,s3,s1
    src += n;
    80001798:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000179a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000179e:	02098263          	beqz	s3,800017c2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a6:	85ca                	mv	a1,s2
    800017a8:	855a                	mv	a0,s6
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	976080e7          	jalr	-1674(ra) # 80001120 <walkaddr>
    if(pa0 == 0)
    800017b2:	cd01                	beqz	a0,800017ca <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017b4:	418904b3          	sub	s1,s2,s8
    800017b8:	94d6                	add	s1,s1,s5
    if(n > len)
    800017ba:	fc99f3e3          	bgeu	s3,s1,80001780 <copyout+0x28>
    800017be:	84ce                	mv	s1,s3
    800017c0:	b7c1                	j	80001780 <copyout+0x28>
  }
  return 0;
    800017c2:	4501                	li	a0,0
    800017c4:	a021                	j	800017cc <copyout+0x74>
    800017c6:	4501                	li	a0,0
}
    800017c8:	8082                	ret
      return -1;
    800017ca:	557d                	li	a0,-1
}
    800017cc:	60a6                	ld	ra,72(sp)
    800017ce:	6406                	ld	s0,64(sp)
    800017d0:	74e2                	ld	s1,56(sp)
    800017d2:	7942                	ld	s2,48(sp)
    800017d4:	79a2                	ld	s3,40(sp)
    800017d6:	7a02                	ld	s4,32(sp)
    800017d8:	6ae2                	ld	s5,24(sp)
    800017da:	6b42                	ld	s6,16(sp)
    800017dc:	6ba2                	ld	s7,8(sp)
    800017de:	6c02                	ld	s8,0(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret

00000000800017e4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017e4:	caa5                	beqz	a3,80001854 <copyin+0x70>
{
    800017e6:	715d                	addi	sp,sp,-80
    800017e8:	e486                	sd	ra,72(sp)
    800017ea:	e0a2                	sd	s0,64(sp)
    800017ec:	fc26                	sd	s1,56(sp)
    800017ee:	f84a                	sd	s2,48(sp)
    800017f0:	f44e                	sd	s3,40(sp)
    800017f2:	f052                	sd	s4,32(sp)
    800017f4:	ec56                	sd	s5,24(sp)
    800017f6:	e85a                	sd	s6,16(sp)
    800017f8:	e45e                	sd	s7,8(sp)
    800017fa:	e062                	sd	s8,0(sp)
    800017fc:	0880                	addi	s0,sp,80
    800017fe:	8b2a                	mv	s6,a0
    80001800:	8a2e                	mv	s4,a1
    80001802:	8c32                	mv	s8,a2
    80001804:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001806:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001808:	6a85                	lui	s5,0x1
    8000180a:	a01d                	j	80001830 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000180c:	018505b3          	add	a1,a0,s8
    80001810:	0004861b          	sext.w	a2,s1
    80001814:	412585b3          	sub	a1,a1,s2
    80001818:	8552                	mv	a0,s4
    8000181a:	fffff097          	auipc	ra,0xfffff
    8000181e:	5c8080e7          	jalr	1480(ra) # 80000de2 <memmove>

    len -= n;
    80001822:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001826:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001828:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000182c:	02098263          	beqz	s3,80001850 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001830:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001834:	85ca                	mv	a1,s2
    80001836:	855a                	mv	a0,s6
    80001838:	00000097          	auipc	ra,0x0
    8000183c:	8e8080e7          	jalr	-1816(ra) # 80001120 <walkaddr>
    if(pa0 == 0)
    80001840:	cd01                	beqz	a0,80001858 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001842:	418904b3          	sub	s1,s2,s8
    80001846:	94d6                	add	s1,s1,s5
    if(n > len)
    80001848:	fc99f2e3          	bgeu	s3,s1,8000180c <copyin+0x28>
    8000184c:	84ce                	mv	s1,s3
    8000184e:	bf7d                	j	8000180c <copyin+0x28>
  }
  return 0;
    80001850:	4501                	li	a0,0
    80001852:	a021                	j	8000185a <copyin+0x76>
    80001854:	4501                	li	a0,0
}
    80001856:	8082                	ret
      return -1;
    80001858:	557d                	li	a0,-1
}
    8000185a:	60a6                	ld	ra,72(sp)
    8000185c:	6406                	ld	s0,64(sp)
    8000185e:	74e2                	ld	s1,56(sp)
    80001860:	7942                	ld	s2,48(sp)
    80001862:	79a2                	ld	s3,40(sp)
    80001864:	7a02                	ld	s4,32(sp)
    80001866:	6ae2                	ld	s5,24(sp)
    80001868:	6b42                	ld	s6,16(sp)
    8000186a:	6ba2                	ld	s7,8(sp)
    8000186c:	6c02                	ld	s8,0(sp)
    8000186e:	6161                	addi	sp,sp,80
    80001870:	8082                	ret

0000000080001872 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80001872:	715d                	addi	sp,sp,-80
    80001874:	e486                	sd	ra,72(sp)
    80001876:	e0a2                	sd	s0,64(sp)
    80001878:	fc26                	sd	s1,56(sp)
    8000187a:	f84a                	sd	s2,48(sp)
    8000187c:	f44e                	sd	s3,40(sp)
    8000187e:	f052                	sd	s4,32(sp)
    80001880:	ec56                	sd	s5,24(sp)
    80001882:	e85a                	sd	s6,16(sp)
    80001884:	e45e                	sd	s7,8(sp)
    80001886:	0880                	addi	s0,sp,80
    80001888:	8aaa                	mv	s5,a0
    8000188a:	89ae                	mv	s3,a1
    8000188c:	8bb2                	mv	s7,a2
    8000188e:	84b6                	mv	s1,a3
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    va0 = PGROUNDDOWN(srcva);
    80001890:	7b7d                	lui	s6,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001892:	6a05                	lui	s4,0x1
    80001894:	a02d                	j	800018be <copyinstr+0x4c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001896:	00078023          	sb	zero,0(a5)
    8000189a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000189c:	0017c793          	xori	a5,a5,1
    800018a0:	40f0053b          	negw	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018a4:	60a6                	ld	ra,72(sp)
    800018a6:	6406                	ld	s0,64(sp)
    800018a8:	74e2                	ld	s1,56(sp)
    800018aa:	7942                	ld	s2,48(sp)
    800018ac:	79a2                	ld	s3,40(sp)
    800018ae:	7a02                	ld	s4,32(sp)
    800018b0:	6ae2                	ld	s5,24(sp)
    800018b2:	6b42                	ld	s6,16(sp)
    800018b4:	6ba2                	ld	s7,8(sp)
    800018b6:	6161                	addi	sp,sp,80
    800018b8:	8082                	ret
    srcva = va0 + PGSIZE;
    800018ba:	01490bb3          	add	s7,s2,s4
  while(got_null == 0 && max > 0){
    800018be:	c8a1                	beqz	s1,8000190e <copyinstr+0x9c>
    va0 = PGROUNDDOWN(srcva);
    800018c0:	016bf933          	and	s2,s7,s6
    pa0 = walkaddr(pagetable, va0);
    800018c4:	85ca                	mv	a1,s2
    800018c6:	8556                	mv	a0,s5
    800018c8:	00000097          	auipc	ra,0x0
    800018cc:	858080e7          	jalr	-1960(ra) # 80001120 <walkaddr>
    if(pa0 == 0)
    800018d0:	c129                	beqz	a0,80001912 <copyinstr+0xa0>
    n = PGSIZE - (srcva - va0);
    800018d2:	41790633          	sub	a2,s2,s7
    800018d6:	9652                	add	a2,a2,s4
    if(n > max)
    800018d8:	00c4f363          	bgeu	s1,a2,800018de <copyinstr+0x6c>
    800018dc:	8626                	mv	a2,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018de:	412b8bb3          	sub	s7,s7,s2
    800018e2:	9baa                	add	s7,s7,a0
    while(n > 0){
    800018e4:	da79                	beqz	a2,800018ba <copyinstr+0x48>
    800018e6:	87ce                	mv	a5,s3
      if(*p == '\0'){
    800018e8:	413b86b3          	sub	a3,s7,s3
    while(n > 0){
    800018ec:	964e                	add	a2,a2,s3
    800018ee:	85be                	mv	a1,a5
      if(*p == '\0'){
    800018f0:	00f68733          	add	a4,a3,a5
    800018f4:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd290>
    800018f8:	df59                	beqz	a4,80001896 <copyinstr+0x24>
        *dst = *p;
    800018fa:	00e78023          	sb	a4,0(a5)
      dst++;
    800018fe:	0785                	addi	a5,a5,1
    while(n > 0){
    80001900:	fec797e3          	bne	a5,a2,800018ee <copyinstr+0x7c>
    80001904:	14fd                	addi	s1,s1,-1
    80001906:	94ce                	add	s1,s1,s3
      --max;
    80001908:	8c8d                	sub	s1,s1,a1
    8000190a:	89be                	mv	s3,a5
    8000190c:	b77d                	j	800018ba <copyinstr+0x48>
    8000190e:	4781                	li	a5,0
    80001910:	b771                	j	8000189c <copyinstr+0x2a>
      return -1;
    80001912:	557d                	li	a0,-1
    80001914:	bf41                	j	800018a4 <copyinstr+0x32>

0000000080001916 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001916:	715d                	addi	sp,sp,-80
    80001918:	e486                	sd	ra,72(sp)
    8000191a:	e0a2                	sd	s0,64(sp)
    8000191c:	fc26                	sd	s1,56(sp)
    8000191e:	f84a                	sd	s2,48(sp)
    80001920:	f44e                	sd	s3,40(sp)
    80001922:	f052                	sd	s4,32(sp)
    80001924:	ec56                	sd	s5,24(sp)
    80001926:	e85a                	sd	s6,16(sp)
    80001928:	e45e                	sd	s7,8(sp)
    8000192a:	e062                	sd	s8,0(sp)
    8000192c:	0880                	addi	s0,sp,80
    8000192e:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	0000f497          	auipc	s1,0xf
    80001934:	66048493          	addi	s1,s1,1632 # 80010f90 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001938:	8c26                	mv	s8,s1
    8000193a:	a4fa57b7          	lui	a5,0xa4fa5
    8000193e:	fa578793          	addi	a5,a5,-91 # ffffffffa4fa4fa5 <end+0xffffffff24f83235>
    80001942:	4fa50937          	lui	s2,0x4fa50
    80001946:	a5090913          	addi	s2,s2,-1456 # 4fa4fa50 <_entry-0x305b05b0>
    8000194a:	1902                	slli	s2,s2,0x20
    8000194c:	993e                	add	s2,s2,a5
    8000194e:	040009b7          	lui	s3,0x4000
    80001952:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001954:	09b2                	slli	s3,s3,0xc
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001956:	4b99                	li	s7,6
    80001958:	6b05                	lui	s6,0x1
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00015a97          	auipc	s5,0x15
    8000195e:	036a8a93          	addi	s5,s5,54 # 80016990 <tickslock>
    char *pa = kalloc();
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	1e8080e7          	jalr	488(ra) # 80000b4a <kalloc>
    8000196a:	862a                	mv	a2,a0
    if(pa == 0)
    8000196c:	c131                	beqz	a0,800019b0 <proc_mapstacks+0x9a>
    uint64 va = KSTACK((int) (p - proc));
    8000196e:	418485b3          	sub	a1,s1,s8
    80001972:	858d                	srai	a1,a1,0x3
    80001974:	032585b3          	mul	a1,a1,s2
    80001978:	2585                	addiw	a1,a1,1
    8000197a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000197e:	875e                	mv	a4,s7
    80001980:	86da                	mv	a3,s6
    80001982:	40b985b3          	sub	a1,s3,a1
    80001986:	8552                	mv	a0,s4
    80001988:	00000097          	auipc	ra,0x0
    8000198c:	880080e7          	jalr	-1920(ra) # 80001208 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001990:	16848493          	addi	s1,s1,360
    80001994:	fd5497e3          	bne	s1,s5,80001962 <proc_mapstacks+0x4c>
  }
}
    80001998:	60a6                	ld	ra,72(sp)
    8000199a:	6406                	ld	s0,64(sp)
    8000199c:	74e2                	ld	s1,56(sp)
    8000199e:	7942                	ld	s2,48(sp)
    800019a0:	79a2                	ld	s3,40(sp)
    800019a2:	7a02                	ld	s4,32(sp)
    800019a4:	6ae2                	ld	s5,24(sp)
    800019a6:	6b42                	ld	s6,16(sp)
    800019a8:	6ba2                	ld	s7,8(sp)
    800019aa:	6c02                	ld	s8,0(sp)
    800019ac:	6161                	addi	sp,sp,80
    800019ae:	8082                	ret
      panic("kalloc");
    800019b0:	00007517          	auipc	a0,0x7
    800019b4:	80850513          	addi	a0,a0,-2040 # 800081b8 <etext+0x1b8>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	ba8080e7          	jalr	-1112(ra) # 80000560 <panic>

00000000800019c0 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800019c0:	7139                	addi	sp,sp,-64
    800019c2:	fc06                	sd	ra,56(sp)
    800019c4:	f822                	sd	s0,48(sp)
    800019c6:	f426                	sd	s1,40(sp)
    800019c8:	f04a                	sd	s2,32(sp)
    800019ca:	ec4e                	sd	s3,24(sp)
    800019cc:	e852                	sd	s4,16(sp)
    800019ce:	e456                	sd	s5,8(sp)
    800019d0:	e05a                	sd	s6,0(sp)
    800019d2:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019d4:	00006597          	auipc	a1,0x6
    800019d8:	7ec58593          	addi	a1,a1,2028 # 800081c0 <etext+0x1c0>
    800019dc:	0000f517          	auipc	a0,0xf
    800019e0:	18450513          	addi	a0,a0,388 # 80010b60 <pid_lock>
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	20e080e7          	jalr	526(ra) # 80000bf2 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019ec:	00006597          	auipc	a1,0x6
    800019f0:	7dc58593          	addi	a1,a1,2012 # 800081c8 <etext+0x1c8>
    800019f4:	0000f517          	auipc	a0,0xf
    800019f8:	18450513          	addi	a0,a0,388 # 80010b78 <wait_lock>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	1f6080e7          	jalr	502(ra) # 80000bf2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a04:	0000f497          	auipc	s1,0xf
    80001a08:	58c48493          	addi	s1,s1,1420 # 80010f90 <proc>
      initlock(&p->lock, "proc");
    80001a0c:	00006b17          	auipc	s6,0x6
    80001a10:	7ccb0b13          	addi	s6,s6,1996 # 800081d8 <etext+0x1d8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a14:	8aa6                	mv	s5,s1
    80001a16:	a4fa57b7          	lui	a5,0xa4fa5
    80001a1a:	fa578793          	addi	a5,a5,-91 # ffffffffa4fa4fa5 <end+0xffffffff24f83235>
    80001a1e:	4fa50937          	lui	s2,0x4fa50
    80001a22:	a5090913          	addi	s2,s2,-1456 # 4fa4fa50 <_entry-0x305b05b0>
    80001a26:	1902                	slli	s2,s2,0x20
    80001a28:	993e                	add	s2,s2,a5
    80001a2a:	040009b7          	lui	s3,0x4000
    80001a2e:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001a30:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a32:	00015a17          	auipc	s4,0x15
    80001a36:	f5ea0a13          	addi	s4,s4,-162 # 80016990 <tickslock>
      initlock(&p->lock, "proc");
    80001a3a:	85da                	mv	a1,s6
    80001a3c:	8526                	mv	a0,s1
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	1b4080e7          	jalr	436(ra) # 80000bf2 <initlock>
      p->state = UNUSED;
    80001a46:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a4a:	415487b3          	sub	a5,s1,s5
    80001a4e:	878d                	srai	a5,a5,0x3
    80001a50:	032787b3          	mul	a5,a5,s2
    80001a54:	2785                	addiw	a5,a5,1
    80001a56:	00d7979b          	slliw	a5,a5,0xd
    80001a5a:	40f987b3          	sub	a5,s3,a5
    80001a5e:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a60:	16848493          	addi	s1,s1,360
    80001a64:	fd449be3          	bne	s1,s4,80001a3a <procinit+0x7a>
  }
}
    80001a68:	70e2                	ld	ra,56(sp)
    80001a6a:	7442                	ld	s0,48(sp)
    80001a6c:	74a2                	ld	s1,40(sp)
    80001a6e:	7902                	ld	s2,32(sp)
    80001a70:	69e2                	ld	s3,24(sp)
    80001a72:	6a42                	ld	s4,16(sp)
    80001a74:	6aa2                	ld	s5,8(sp)
    80001a76:	6b02                	ld	s6,0(sp)
    80001a78:	6121                	addi	sp,sp,64
    80001a7a:	8082                	ret

0000000080001a7c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a7c:	1141                	addi	sp,sp,-16
    80001a7e:	e406                	sd	ra,8(sp)
    80001a80:	e022                	sd	s0,0(sp)
    80001a82:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a84:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a86:	2501                	sext.w	a0,a0
    80001a88:	60a2                	ld	ra,8(sp)
    80001a8a:	6402                	ld	s0,0(sp)
    80001a8c:	0141                	addi	sp,sp,16
    80001a8e:	8082                	ret

0000000080001a90 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a90:	1141                	addi	sp,sp,-16
    80001a92:	e406                	sd	ra,8(sp)
    80001a94:	e022                	sd	s0,0(sp)
    80001a96:	0800                	addi	s0,sp,16
    80001a98:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a9a:	2781                	sext.w	a5,a5
    80001a9c:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a9e:	0000f517          	auipc	a0,0xf
    80001aa2:	0f250513          	addi	a0,a0,242 # 80010b90 <cpus>
    80001aa6:	953e                	add	a0,a0,a5
    80001aa8:	60a2                	ld	ra,8(sp)
    80001aaa:	6402                	ld	s0,0(sp)
    80001aac:	0141                	addi	sp,sp,16
    80001aae:	8082                	ret

0000000080001ab0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001ab0:	1101                	addi	sp,sp,-32
    80001ab2:	ec06                	sd	ra,24(sp)
    80001ab4:	e822                	sd	s0,16(sp)
    80001ab6:	e426                	sd	s1,8(sp)
    80001ab8:	1000                	addi	s0,sp,32
  push_off();
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	180080e7          	jalr	384(ra) # 80000c3a <push_off>
    80001ac2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ac4:	2781                	sext.w	a5,a5
    80001ac6:	079e                	slli	a5,a5,0x7
    80001ac8:	0000f717          	auipc	a4,0xf
    80001acc:	09870713          	addi	a4,a4,152 # 80010b60 <pid_lock>
    80001ad0:	97ba                	add	a5,a5,a4
    80001ad2:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	206080e7          	jalr	518(ra) # 80000cda <pop_off>
  return p;
}
    80001adc:	8526                	mv	a0,s1
    80001ade:	60e2                	ld	ra,24(sp)
    80001ae0:	6442                	ld	s0,16(sp)
    80001ae2:	64a2                	ld	s1,8(sp)
    80001ae4:	6105                	addi	sp,sp,32
    80001ae6:	8082                	ret

0000000080001ae8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ae8:	1141                	addi	sp,sp,-16
    80001aea:	e406                	sd	ra,8(sp)
    80001aec:	e022                	sd	s0,0(sp)
    80001aee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001af0:	00000097          	auipc	ra,0x0
    80001af4:	fc0080e7          	jalr	-64(ra) # 80001ab0 <myproc>
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	23e080e7          	jalr	574(ra) # 80000d36 <release>

  if (first) {
    80001b00:	00007797          	auipc	a5,0x7
    80001b04:	d707a783          	lw	a5,-656(a5) # 80008870 <first.1>
    80001b08:	eb89                	bnez	a5,80001b1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b0a:	00001097          	auipc	ra,0x1
    80001b0e:	cb2080e7          	jalr	-846(ra) # 800027bc <usertrapret>
}
    80001b12:	60a2                	ld	ra,8(sp)
    80001b14:	6402                	ld	s0,0(sp)
    80001b16:	0141                	addi	sp,sp,16
    80001b18:	8082                	ret
    first = 0;
    80001b1a:	00007797          	auipc	a5,0x7
    80001b1e:	d407ab23          	sw	zero,-682(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001b22:	4505                	li	a0,1
    80001b24:	00002097          	auipc	ra,0x2
    80001b28:	a7e080e7          	jalr	-1410(ra) # 800035a2 <fsinit>
    80001b2c:	bff9                	j	80001b0a <forkret+0x22>

0000000080001b2e <allocpid>:
{
    80001b2e:	1101                	addi	sp,sp,-32
    80001b30:	ec06                	sd	ra,24(sp)
    80001b32:	e822                	sd	s0,16(sp)
    80001b34:	e426                	sd	s1,8(sp)
    80001b36:	e04a                	sd	s2,0(sp)
    80001b38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b3a:	0000f917          	auipc	s2,0xf
    80001b3e:	02690913          	addi	s2,s2,38 # 80010b60 <pid_lock>
    80001b42:	854a                	mv	a0,s2
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	142080e7          	jalr	322(ra) # 80000c86 <acquire>
  pid = nextpid;
    80001b4c:	00007797          	auipc	a5,0x7
    80001b50:	d2878793          	addi	a5,a5,-728 # 80008874 <nextpid>
    80001b54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b56:	0014871b          	addiw	a4,s1,1
    80001b5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b5c:	854a                	mv	a0,s2
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	1d8080e7          	jalr	472(ra) # 80000d36 <release>
}
    80001b66:	8526                	mv	a0,s1
    80001b68:	60e2                	ld	ra,24(sp)
    80001b6a:	6442                	ld	s0,16(sp)
    80001b6c:	64a2                	ld	s1,8(sp)
    80001b6e:	6902                	ld	s2,0(sp)
    80001b70:	6105                	addi	sp,sp,32
    80001b72:	8082                	ret

0000000080001b74 <proc_pagetable>:
{
    80001b74:	1101                	addi	sp,sp,-32
    80001b76:	ec06                	sd	ra,24(sp)
    80001b78:	e822                	sd	s0,16(sp)
    80001b7a:	e426                	sd	s1,8(sp)
    80001b7c:	e04a                	sd	s2,0(sp)
    80001b7e:	1000                	addi	s0,sp,32
    80001b80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b82:	00000097          	auipc	ra,0x0
    80001b86:	87a080e7          	jalr	-1926(ra) # 800013fc <uvmcreate>
    80001b8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b8c:	c121                	beqz	a0,80001bcc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b8e:	4729                	li	a4,10
    80001b90:	00005697          	auipc	a3,0x5
    80001b94:	47068693          	addi	a3,a3,1136 # 80007000 <_trampoline>
    80001b98:	6605                	lui	a2,0x1
    80001b9a:	040005b7          	lui	a1,0x4000
    80001b9e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ba0:	05b2                	slli	a1,a1,0xc
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	5c0080e7          	jalr	1472(ra) # 80001162 <mappages>
    80001baa:	02054863          	bltz	a0,80001bda <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bae:	4719                	li	a4,6
    80001bb0:	05893683          	ld	a3,88(s2)
    80001bb4:	6605                	lui	a2,0x1
    80001bb6:	020005b7          	lui	a1,0x2000
    80001bba:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bbc:	05b6                	slli	a1,a1,0xd
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	5a2080e7          	jalr	1442(ra) # 80001162 <mappages>
    80001bc8:	02054163          	bltz	a0,80001bea <proc_pagetable+0x76>
}
    80001bcc:	8526                	mv	a0,s1
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6902                	ld	s2,0(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret
    uvmfree(pagetable, 0);
    80001bda:	4581                	li	a1,0
    80001bdc:	8526                	mv	a0,s1
    80001bde:	00000097          	auipc	ra,0x0
    80001be2:	a38080e7          	jalr	-1480(ra) # 80001616 <uvmfree>
    return 0;
    80001be6:	4481                	li	s1,0
    80001be8:	b7d5                	j	80001bcc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bea:	4681                	li	a3,0
    80001bec:	4605                	li	a2,1
    80001bee:	040005b7          	lui	a1,0x4000
    80001bf2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bf4:	05b2                	slli	a1,a1,0xc
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	730080e7          	jalr	1840(ra) # 80001328 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c00:	4581                	li	a1,0
    80001c02:	8526                	mv	a0,s1
    80001c04:	00000097          	auipc	ra,0x0
    80001c08:	a12080e7          	jalr	-1518(ra) # 80001616 <uvmfree>
    return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	bf7d                	j	80001bcc <proc_pagetable+0x58>

0000000080001c10 <proc_freepagetable>:
{
    80001c10:	1101                	addi	sp,sp,-32
    80001c12:	ec06                	sd	ra,24(sp)
    80001c14:	e822                	sd	s0,16(sp)
    80001c16:	e426                	sd	s1,8(sp)
    80001c18:	e04a                	sd	s2,0(sp)
    80001c1a:	1000                	addi	s0,sp,32
    80001c1c:	84aa                	mv	s1,a0
    80001c1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c20:	4681                	li	a3,0
    80001c22:	4605                	li	a2,1
    80001c24:	040005b7          	lui	a1,0x4000
    80001c28:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c2a:	05b2                	slli	a1,a1,0xc
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	6fc080e7          	jalr	1788(ra) # 80001328 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c34:	4681                	li	a3,0
    80001c36:	4605                	li	a2,1
    80001c38:	020005b7          	lui	a1,0x2000
    80001c3c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c3e:	05b6                	slli	a1,a1,0xd
    80001c40:	8526                	mv	a0,s1
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	6e6080e7          	jalr	1766(ra) # 80001328 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c4a:	85ca                	mv	a1,s2
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	9c8080e7          	jalr	-1592(ra) # 80001616 <uvmfree>
}
    80001c56:	60e2                	ld	ra,24(sp)
    80001c58:	6442                	ld	s0,16(sp)
    80001c5a:	64a2                	ld	s1,8(sp)
    80001c5c:	6902                	ld	s2,0(sp)
    80001c5e:	6105                	addi	sp,sp,32
    80001c60:	8082                	ret

0000000080001c62 <freeproc>:
{
    80001c62:	1101                	addi	sp,sp,-32
    80001c64:	ec06                	sd	ra,24(sp)
    80001c66:	e822                	sd	s0,16(sp)
    80001c68:	e426                	sd	s1,8(sp)
    80001c6a:	1000                	addi	s0,sp,32
    80001c6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c6e:	6d28                	ld	a0,88(a0)
    80001c70:	c509                	beqz	a0,80001c7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	dda080e7          	jalr	-550(ra) # 80000a4c <kfree>
  p->trapframe = 0;
    80001c7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c7e:	68a8                	ld	a0,80(s1)
    80001c80:	c511                	beqz	a0,80001c8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c82:	64ac                	ld	a1,72(s1)
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	f8c080e7          	jalr	-116(ra) # 80001c10 <proc_freepagetable>
  p->pagetable = 0;
    80001c8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ca0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ca4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ca8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cac:	0004ac23          	sw	zero,24(s1)
}
    80001cb0:	60e2                	ld	ra,24(sp)
    80001cb2:	6442                	ld	s0,16(sp)
    80001cb4:	64a2                	ld	s1,8(sp)
    80001cb6:	6105                	addi	sp,sp,32
    80001cb8:	8082                	ret

0000000080001cba <allocproc>:
{
    80001cba:	1101                	addi	sp,sp,-32
    80001cbc:	ec06                	sd	ra,24(sp)
    80001cbe:	e822                	sd	s0,16(sp)
    80001cc0:	e426                	sd	s1,8(sp)
    80001cc2:	e04a                	sd	s2,0(sp)
    80001cc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc6:	0000f497          	auipc	s1,0xf
    80001cca:	2ca48493          	addi	s1,s1,714 # 80010f90 <proc>
    80001cce:	00015917          	auipc	s2,0x15
    80001cd2:	cc290913          	addi	s2,s2,-830 # 80016990 <tickslock>
    acquire(&p->lock);
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	fae080e7          	jalr	-82(ra) # 80000c86 <acquire>
    if(p->state == UNUSED) {
    80001ce0:	4c9c                	lw	a5,24(s1)
    80001ce2:	cf81                	beqz	a5,80001cfa <allocproc+0x40>
      release(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	050080e7          	jalr	80(ra) # 80000d36 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cee:	16848493          	addi	s1,s1,360
    80001cf2:	ff2492e3          	bne	s1,s2,80001cd6 <allocproc+0x1c>
  return 0;
    80001cf6:	4481                	li	s1,0
    80001cf8:	a889                	j	80001d4a <allocproc+0x90>
  p->pid = allocpid();
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	e34080e7          	jalr	-460(ra) # 80001b2e <allocpid>
    80001d02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d04:	4785                	li	a5,1
    80001d06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	e42080e7          	jalr	-446(ra) # 80000b4a <kalloc>
    80001d10:	892a                	mv	s2,a0
    80001d12:	eca8                	sd	a0,88(s1)
    80001d14:	c131                	beqz	a0,80001d58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d16:	8526                	mv	a0,s1
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	e5c080e7          	jalr	-420(ra) # 80001b74 <proc_pagetable>
    80001d20:	892a                	mv	s2,a0
    80001d22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d24:	c531                	beqz	a0,80001d70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d26:	07000613          	li	a2,112
    80001d2a:	4581                	li	a1,0
    80001d2c:	06048513          	addi	a0,s1,96
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	04e080e7          	jalr	78(ra) # 80000d7e <memset>
  p->context.ra = (uint64)forkret;
    80001d38:	00000797          	auipc	a5,0x0
    80001d3c:	db078793          	addi	a5,a5,-592 # 80001ae8 <forkret>
    80001d40:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d42:	60bc                	ld	a5,64(s1)
    80001d44:	6705                	lui	a4,0x1
    80001d46:	97ba                	add	a5,a5,a4
    80001d48:	f4bc                	sd	a5,104(s1)
}
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6902                	ld	s2,0(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret
    freeproc(p);
    80001d58:	8526                	mv	a0,s1
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	f08080e7          	jalr	-248(ra) # 80001c62 <freeproc>
    release(&p->lock);
    80001d62:	8526                	mv	a0,s1
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	fd2080e7          	jalr	-46(ra) # 80000d36 <release>
    return 0;
    80001d6c:	84ca                	mv	s1,s2
    80001d6e:	bff1                	j	80001d4a <allocproc+0x90>
    freeproc(p);
    80001d70:	8526                	mv	a0,s1
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	ef0080e7          	jalr	-272(ra) # 80001c62 <freeproc>
    release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	fba080e7          	jalr	-70(ra) # 80000d36 <release>
    return 0;
    80001d84:	84ca                	mv	s1,s2
    80001d86:	b7d1                	j	80001d4a <allocproc+0x90>

0000000080001d88 <userinit>:
{
    80001d88:	1101                	addi	sp,sp,-32
    80001d8a:	ec06                	sd	ra,24(sp)
    80001d8c:	e822                	sd	s0,16(sp)
    80001d8e:	e426                	sd	s1,8(sp)
    80001d90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	f28080e7          	jalr	-216(ra) # 80001cba <allocproc>
    80001d9a:	84aa                	mv	s1,a0
  initproc = p;
    80001d9c:	00007797          	auipc	a5,0x7
    80001da0:	b4a7b623          	sd	a0,-1204(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001da4:	03400613          	li	a2,52
    80001da8:	00007597          	auipc	a1,0x7
    80001dac:	ad858593          	addi	a1,a1,-1320 # 80008880 <initcode>
    80001db0:	6928                	ld	a0,80(a0)
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	678080e7          	jalr	1656(ra) # 8000142a <uvmfirst>
  p->sz = PGSIZE;
    80001dba:	6785                	lui	a5,0x1
    80001dbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dbe:	6cb8                	ld	a4,88(s1)
    80001dc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dc4:	6cb8                	ld	a4,88(s1)
    80001dc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dc8:	4641                	li	a2,16
    80001dca:	00006597          	auipc	a1,0x6
    80001dce:	41658593          	addi	a1,a1,1046 # 800081e0 <etext+0x1e0>
    80001dd2:	15848513          	addi	a0,s1,344
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	0fe080e7          	jalr	254(ra) # 80000ed4 <safestrcpy>
  p->cwd = namei("/");
    80001dde:	00006517          	auipc	a0,0x6
    80001de2:	41250513          	addi	a0,a0,1042 # 800081f0 <etext+0x1f0>
    80001de6:	00002097          	auipc	ra,0x2
    80001dea:	224080e7          	jalr	548(ra) # 8000400a <namei>
    80001dee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001df2:	478d                	li	a5,3
    80001df4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001df6:	8526                	mv	a0,s1
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	f3e080e7          	jalr	-194(ra) # 80000d36 <release>
}
    80001e00:	60e2                	ld	ra,24(sp)
    80001e02:	6442                	ld	s0,16(sp)
    80001e04:	64a2                	ld	s1,8(sp)
    80001e06:	6105                	addi	sp,sp,32
    80001e08:	8082                	ret

0000000080001e0a <growproc>:
{
    80001e0a:	1101                	addi	sp,sp,-32
    80001e0c:	ec06                	sd	ra,24(sp)
    80001e0e:	e822                	sd	s0,16(sp)
    80001e10:	e426                	sd	s1,8(sp)
    80001e12:	e04a                	sd	s2,0(sp)
    80001e14:	1000                	addi	s0,sp,32
    80001e16:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	c98080e7          	jalr	-872(ra) # 80001ab0 <myproc>
    80001e20:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e22:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e24:	01204c63          	bgtz	s2,80001e3c <growproc+0x32>
  } else if(n < 0){
    80001e28:	02094663          	bltz	s2,80001e54 <growproc+0x4a>
  p->sz = sz;
    80001e2c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e2e:	4501                	li	a0,0
}
    80001e30:	60e2                	ld	ra,24(sp)
    80001e32:	6442                	ld	s0,16(sp)
    80001e34:	64a2                	ld	s1,8(sp)
    80001e36:	6902                	ld	s2,0(sp)
    80001e38:	6105                	addi	sp,sp,32
    80001e3a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e3c:	4691                	li	a3,4
    80001e3e:	00b90633          	add	a2,s2,a1
    80001e42:	6928                	ld	a0,80(a0)
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	6a0080e7          	jalr	1696(ra) # 800014e4 <uvmalloc>
    80001e4c:	85aa                	mv	a1,a0
    80001e4e:	fd79                	bnez	a0,80001e2c <growproc+0x22>
      return -1;
    80001e50:	557d                	li	a0,-1
    80001e52:	bff9                	j	80001e30 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e54:	00b90633          	add	a2,s2,a1
    80001e58:	6928                	ld	a0,80(a0)
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	642080e7          	jalr	1602(ra) # 8000149c <uvmdealloc>
    80001e62:	85aa                	mv	a1,a0
    80001e64:	b7e1                	j	80001e2c <growproc+0x22>

0000000080001e66 <fork>:
{
    80001e66:	7139                	addi	sp,sp,-64
    80001e68:	fc06                	sd	ra,56(sp)
    80001e6a:	f822                	sd	s0,48(sp)
    80001e6c:	f04a                	sd	s2,32(sp)
    80001e6e:	e456                	sd	s5,8(sp)
    80001e70:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e72:	00000097          	auipc	ra,0x0
    80001e76:	c3e080e7          	jalr	-962(ra) # 80001ab0 <myproc>
    80001e7a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	e3e080e7          	jalr	-450(ra) # 80001cba <allocproc>
    80001e84:	12050063          	beqz	a0,80001fa4 <fork+0x13e>
    80001e88:	e852                	sd	s4,16(sp)
    80001e8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e8c:	048ab603          	ld	a2,72(s5)
    80001e90:	692c                	ld	a1,80(a0)
    80001e92:	050ab503          	ld	a0,80(s5)
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	7ba080e7          	jalr	1978(ra) # 80001650 <uvmcopy>
    80001e9e:	04054a63          	bltz	a0,80001ef2 <fork+0x8c>
    80001ea2:	f426                	sd	s1,40(sp)
    80001ea4:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001ea6:	048ab783          	ld	a5,72(s5)
    80001eaa:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001eae:	058ab683          	ld	a3,88(s5)
    80001eb2:	87b6                	mv	a5,a3
    80001eb4:	058a3703          	ld	a4,88(s4)
    80001eb8:	12068693          	addi	a3,a3,288
    80001ebc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ec0:	6788                	ld	a0,8(a5)
    80001ec2:	6b8c                	ld	a1,16(a5)
    80001ec4:	6f90                	ld	a2,24(a5)
    80001ec6:	01073023          	sd	a6,0(a4)
    80001eca:	e708                	sd	a0,8(a4)
    80001ecc:	eb0c                	sd	a1,16(a4)
    80001ece:	ef10                	sd	a2,24(a4)
    80001ed0:	02078793          	addi	a5,a5,32
    80001ed4:	02070713          	addi	a4,a4,32
    80001ed8:	fed792e3          	bne	a5,a3,80001ebc <fork+0x56>
  np->trapframe->a0 = 0;
    80001edc:	058a3783          	ld	a5,88(s4)
    80001ee0:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ee4:	0d0a8493          	addi	s1,s5,208
    80001ee8:	0d0a0913          	addi	s2,s4,208
    80001eec:	150a8993          	addi	s3,s5,336
    80001ef0:	a015                	j	80001f14 <fork+0xae>
    freeproc(np);
    80001ef2:	8552                	mv	a0,s4
    80001ef4:	00000097          	auipc	ra,0x0
    80001ef8:	d6e080e7          	jalr	-658(ra) # 80001c62 <freeproc>
    release(&np->lock);
    80001efc:	8552                	mv	a0,s4
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	e38080e7          	jalr	-456(ra) # 80000d36 <release>
    return -1;
    80001f06:	597d                	li	s2,-1
    80001f08:	6a42                	ld	s4,16(sp)
    80001f0a:	a071                	j	80001f96 <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001f0c:	04a1                	addi	s1,s1,8
    80001f0e:	0921                	addi	s2,s2,8
    80001f10:	01348b63          	beq	s1,s3,80001f26 <fork+0xc0>
    if(p->ofile[i])
    80001f14:	6088                	ld	a0,0(s1)
    80001f16:	d97d                	beqz	a0,80001f0c <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f18:	00002097          	auipc	ra,0x2
    80001f1c:	776080e7          	jalr	1910(ra) # 8000468e <filedup>
    80001f20:	00a93023          	sd	a0,0(s2)
    80001f24:	b7e5                	j	80001f0c <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001f26:	150ab503          	ld	a0,336(s5)
    80001f2a:	00002097          	auipc	ra,0x2
    80001f2e:	8be080e7          	jalr	-1858(ra) # 800037e8 <idup>
    80001f32:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f36:	4641                	li	a2,16
    80001f38:	158a8593          	addi	a1,s5,344
    80001f3c:	158a0513          	addi	a0,s4,344
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	f94080e7          	jalr	-108(ra) # 80000ed4 <safestrcpy>
  pid = np->pid;
    80001f48:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f4c:	8552                	mv	a0,s4
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	de8080e7          	jalr	-536(ra) # 80000d36 <release>
  acquire(&wait_lock);
    80001f56:	0000f497          	auipc	s1,0xf
    80001f5a:	c2248493          	addi	s1,s1,-990 # 80010b78 <wait_lock>
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d26080e7          	jalr	-730(ra) # 80000c86 <acquire>
  np->parent = p;
    80001f68:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	dc8080e7          	jalr	-568(ra) # 80000d36 <release>
  acquire(&np->lock);
    80001f76:	8552                	mv	a0,s4
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	d0e080e7          	jalr	-754(ra) # 80000c86 <acquire>
  np->state = RUNNABLE;
    80001f80:	478d                	li	a5,3
    80001f82:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f86:	8552                	mv	a0,s4
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	dae080e7          	jalr	-594(ra) # 80000d36 <release>
  return pid;
    80001f90:	74a2                	ld	s1,40(sp)
    80001f92:	69e2                	ld	s3,24(sp)
    80001f94:	6a42                	ld	s4,16(sp)
}
    80001f96:	854a                	mv	a0,s2
    80001f98:	70e2                	ld	ra,56(sp)
    80001f9a:	7442                	ld	s0,48(sp)
    80001f9c:	7902                	ld	s2,32(sp)
    80001f9e:	6aa2                	ld	s5,8(sp)
    80001fa0:	6121                	addi	sp,sp,64
    80001fa2:	8082                	ret
    return -1;
    80001fa4:	597d                	li	s2,-1
    80001fa6:	bfc5                	j	80001f96 <fork+0x130>

0000000080001fa8 <scheduler>:
{
    80001fa8:	7139                	addi	sp,sp,-64
    80001faa:	fc06                	sd	ra,56(sp)
    80001fac:	f822                	sd	s0,48(sp)
    80001fae:	f426                	sd	s1,40(sp)
    80001fb0:	f04a                	sd	s2,32(sp)
    80001fb2:	ec4e                	sd	s3,24(sp)
    80001fb4:	e852                	sd	s4,16(sp)
    80001fb6:	e456                	sd	s5,8(sp)
    80001fb8:	e05a                	sd	s6,0(sp)
    80001fba:	0080                	addi	s0,sp,64
    80001fbc:	8792                	mv	a5,tp
  int id = r_tp();
    80001fbe:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fc0:	00779a93          	slli	s5,a5,0x7
    80001fc4:	0000f717          	auipc	a4,0xf
    80001fc8:	b9c70713          	addi	a4,a4,-1124 # 80010b60 <pid_lock>
    80001fcc:	9756                	add	a4,a4,s5
    80001fce:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fd2:	0000f717          	auipc	a4,0xf
    80001fd6:	bc670713          	addi	a4,a4,-1082 # 80010b98 <cpus+0x8>
    80001fda:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fdc:	498d                	li	s3,3
        p->state = RUNNING;
    80001fde:	4b11                	li	s6,4
        c->proc = p;
    80001fe0:	079e                	slli	a5,a5,0x7
    80001fe2:	0000fa17          	auipc	s4,0xf
    80001fe6:	b7ea0a13          	addi	s4,s4,-1154 # 80010b60 <pid_lock>
    80001fea:	9a3e                	add	s4,s4,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff4:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ff8:	0000f497          	auipc	s1,0xf
    80001ffc:	f9848493          	addi	s1,s1,-104 # 80010f90 <proc>
    80002000:	00015917          	auipc	s2,0x15
    80002004:	99090913          	addi	s2,s2,-1648 # 80016990 <tickslock>
    80002008:	a811                	j	8000201c <scheduler+0x74>
      release(&p->lock);
    8000200a:	8526                	mv	a0,s1
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	d2a080e7          	jalr	-726(ra) # 80000d36 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002014:	16848493          	addi	s1,s1,360
    80002018:	fd248ae3          	beq	s1,s2,80001fec <scheduler+0x44>
      acquire(&p->lock);
    8000201c:	8526                	mv	a0,s1
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	c68080e7          	jalr	-920(ra) # 80000c86 <acquire>
      if(p->state == RUNNABLE) {
    80002026:	4c9c                	lw	a5,24(s1)
    80002028:	ff3791e3          	bne	a5,s3,8000200a <scheduler+0x62>
        p->state = RUNNING;
    8000202c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002030:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002034:	06048593          	addi	a1,s1,96
    80002038:	8556                	mv	a0,s5
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	6d4080e7          	jalr	1748(ra) # 8000270e <swtch>
        c->proc = 0;
    80002042:	020a3823          	sd	zero,48(s4)
    80002046:	b7d1                	j	8000200a <scheduler+0x62>

0000000080002048 <sched>:
{
    80002048:	7179                	addi	sp,sp,-48
    8000204a:	f406                	sd	ra,40(sp)
    8000204c:	f022                	sd	s0,32(sp)
    8000204e:	ec26                	sd	s1,24(sp)
    80002050:	e84a                	sd	s2,16(sp)
    80002052:	e44e                	sd	s3,8(sp)
    80002054:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	a5a080e7          	jalr	-1446(ra) # 80001ab0 <myproc>
    8000205e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	bac080e7          	jalr	-1108(ra) # 80000c0c <holding>
    80002068:	c93d                	beqz	a0,800020de <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000206a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000206c:	2781                	sext.w	a5,a5
    8000206e:	079e                	slli	a5,a5,0x7
    80002070:	0000f717          	auipc	a4,0xf
    80002074:	af070713          	addi	a4,a4,-1296 # 80010b60 <pid_lock>
    80002078:	97ba                	add	a5,a5,a4
    8000207a:	0a87a703          	lw	a4,168(a5)
    8000207e:	4785                	li	a5,1
    80002080:	06f71763          	bne	a4,a5,800020ee <sched+0xa6>
  if(p->state == RUNNING)
    80002084:	4c98                	lw	a4,24(s1)
    80002086:	4791                	li	a5,4
    80002088:	06f70b63          	beq	a4,a5,800020fe <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000208c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002090:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002092:	efb5                	bnez	a5,8000210e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002094:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002096:	0000f917          	auipc	s2,0xf
    8000209a:	aca90913          	addi	s2,s2,-1334 # 80010b60 <pid_lock>
    8000209e:	2781                	sext.w	a5,a5
    800020a0:	079e                	slli	a5,a5,0x7
    800020a2:	97ca                	add	a5,a5,s2
    800020a4:	0ac7a983          	lw	s3,172(a5)
    800020a8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020aa:	2781                	sext.w	a5,a5
    800020ac:	079e                	slli	a5,a5,0x7
    800020ae:	0000f597          	auipc	a1,0xf
    800020b2:	aea58593          	addi	a1,a1,-1302 # 80010b98 <cpus+0x8>
    800020b6:	95be                	add	a1,a1,a5
    800020b8:	06048513          	addi	a0,s1,96
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	652080e7          	jalr	1618(ra) # 8000270e <swtch>
    800020c4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020c6:	2781                	sext.w	a5,a5
    800020c8:	079e                	slli	a5,a5,0x7
    800020ca:	993e                	add	s2,s2,a5
    800020cc:	0b392623          	sw	s3,172(s2)
}
    800020d0:	70a2                	ld	ra,40(sp)
    800020d2:	7402                	ld	s0,32(sp)
    800020d4:	64e2                	ld	s1,24(sp)
    800020d6:	6942                	ld	s2,16(sp)
    800020d8:	69a2                	ld	s3,8(sp)
    800020da:	6145                	addi	sp,sp,48
    800020dc:	8082                	ret
    panic("sched p->lock");
    800020de:	00006517          	auipc	a0,0x6
    800020e2:	11a50513          	addi	a0,a0,282 # 800081f8 <etext+0x1f8>
    800020e6:	ffffe097          	auipc	ra,0xffffe
    800020ea:	47a080e7          	jalr	1146(ra) # 80000560 <panic>
    panic("sched locks");
    800020ee:	00006517          	auipc	a0,0x6
    800020f2:	11a50513          	addi	a0,a0,282 # 80008208 <etext+0x208>
    800020f6:	ffffe097          	auipc	ra,0xffffe
    800020fa:	46a080e7          	jalr	1130(ra) # 80000560 <panic>
    panic("sched running");
    800020fe:	00006517          	auipc	a0,0x6
    80002102:	11a50513          	addi	a0,a0,282 # 80008218 <etext+0x218>
    80002106:	ffffe097          	auipc	ra,0xffffe
    8000210a:	45a080e7          	jalr	1114(ra) # 80000560 <panic>
    panic("sched interruptible");
    8000210e:	00006517          	auipc	a0,0x6
    80002112:	11a50513          	addi	a0,a0,282 # 80008228 <etext+0x228>
    80002116:	ffffe097          	auipc	ra,0xffffe
    8000211a:	44a080e7          	jalr	1098(ra) # 80000560 <panic>

000000008000211e <yield>:
{
    8000211e:	1101                	addi	sp,sp,-32
    80002120:	ec06                	sd	ra,24(sp)
    80002122:	e822                	sd	s0,16(sp)
    80002124:	e426                	sd	s1,8(sp)
    80002126:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002128:	00000097          	auipc	ra,0x0
    8000212c:	988080e7          	jalr	-1656(ra) # 80001ab0 <myproc>
    80002130:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	b54080e7          	jalr	-1196(ra) # 80000c86 <acquire>
  p->state = RUNNABLE;
    8000213a:	478d                	li	a5,3
    8000213c:	cc9c                	sw	a5,24(s1)
  sched();
    8000213e:	00000097          	auipc	ra,0x0
    80002142:	f0a080e7          	jalr	-246(ra) # 80002048 <sched>
  release(&p->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	bee080e7          	jalr	-1042(ra) # 80000d36 <release>
}
    80002150:	60e2                	ld	ra,24(sp)
    80002152:	6442                	ld	s0,16(sp)
    80002154:	64a2                	ld	s1,8(sp)
    80002156:	6105                	addi	sp,sp,32
    80002158:	8082                	ret

000000008000215a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000215a:	7179                	addi	sp,sp,-48
    8000215c:	f406                	sd	ra,40(sp)
    8000215e:	f022                	sd	s0,32(sp)
    80002160:	ec26                	sd	s1,24(sp)
    80002162:	e84a                	sd	s2,16(sp)
    80002164:	e44e                	sd	s3,8(sp)
    80002166:	1800                	addi	s0,sp,48
    80002168:	89aa                	mv	s3,a0
    8000216a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	944080e7          	jalr	-1724(ra) # 80001ab0 <myproc>
    80002174:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b10080e7          	jalr	-1264(ra) # 80000c86 <acquire>
  release(lk);
    8000217e:	854a                	mv	a0,s2
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	bb6080e7          	jalr	-1098(ra) # 80000d36 <release>

  // Go to sleep.
  p->chan = chan;
    80002188:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000218c:	4789                	li	a5,2
    8000218e:	cc9c                	sw	a5,24(s1)

  sched();
    80002190:	00000097          	auipc	ra,0x0
    80002194:	eb8080e7          	jalr	-328(ra) # 80002048 <sched>

  // Tidy up.
  p->chan = 0;
    80002198:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	b98080e7          	jalr	-1128(ra) # 80000d36 <release>
  acquire(lk);
    800021a6:	854a                	mv	a0,s2
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	ade080e7          	jalr	-1314(ra) # 80000c86 <acquire>
}
    800021b0:	70a2                	ld	ra,40(sp)
    800021b2:	7402                	ld	s0,32(sp)
    800021b4:	64e2                	ld	s1,24(sp)
    800021b6:	6942                	ld	s2,16(sp)
    800021b8:	69a2                	ld	s3,8(sp)
    800021ba:	6145                	addi	sp,sp,48
    800021bc:	8082                	ret

00000000800021be <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021be:	7139                	addi	sp,sp,-64
    800021c0:	fc06                	sd	ra,56(sp)
    800021c2:	f822                	sd	s0,48(sp)
    800021c4:	f426                	sd	s1,40(sp)
    800021c6:	f04a                	sd	s2,32(sp)
    800021c8:	ec4e                	sd	s3,24(sp)
    800021ca:	e852                	sd	s4,16(sp)
    800021cc:	e456                	sd	s5,8(sp)
    800021ce:	0080                	addi	s0,sp,64
    800021d0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021d2:	0000f497          	auipc	s1,0xf
    800021d6:	dbe48493          	addi	s1,s1,-578 # 80010f90 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021da:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021dc:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021de:	00014917          	auipc	s2,0x14
    800021e2:	7b290913          	addi	s2,s2,1970 # 80016990 <tickslock>
    800021e6:	a811                	j	800021fa <wakeup+0x3c>
      }
      release(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	b4c080e7          	jalr	-1204(ra) # 80000d36 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021f2:	16848493          	addi	s1,s1,360
    800021f6:	03248663          	beq	s1,s2,80002222 <wakeup+0x64>
    if(p != myproc()){
    800021fa:	00000097          	auipc	ra,0x0
    800021fe:	8b6080e7          	jalr	-1866(ra) # 80001ab0 <myproc>
    80002202:	fea488e3          	beq	s1,a0,800021f2 <wakeup+0x34>
      acquire(&p->lock);
    80002206:	8526                	mv	a0,s1
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	a7e080e7          	jalr	-1410(ra) # 80000c86 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002210:	4c9c                	lw	a5,24(s1)
    80002212:	fd379be3          	bne	a5,s3,800021e8 <wakeup+0x2a>
    80002216:	709c                	ld	a5,32(s1)
    80002218:	fd4798e3          	bne	a5,s4,800021e8 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000221c:	0154ac23          	sw	s5,24(s1)
    80002220:	b7e1                	j	800021e8 <wakeup+0x2a>
    }
  }
}
    80002222:	70e2                	ld	ra,56(sp)
    80002224:	7442                	ld	s0,48(sp)
    80002226:	74a2                	ld	s1,40(sp)
    80002228:	7902                	ld	s2,32(sp)
    8000222a:	69e2                	ld	s3,24(sp)
    8000222c:	6a42                	ld	s4,16(sp)
    8000222e:	6aa2                	ld	s5,8(sp)
    80002230:	6121                	addi	sp,sp,64
    80002232:	8082                	ret

0000000080002234 <reparent>:
{
    80002234:	7179                	addi	sp,sp,-48
    80002236:	f406                	sd	ra,40(sp)
    80002238:	f022                	sd	s0,32(sp)
    8000223a:	ec26                	sd	s1,24(sp)
    8000223c:	e84a                	sd	s2,16(sp)
    8000223e:	e44e                	sd	s3,8(sp)
    80002240:	e052                	sd	s4,0(sp)
    80002242:	1800                	addi	s0,sp,48
    80002244:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002246:	0000f497          	auipc	s1,0xf
    8000224a:	d4a48493          	addi	s1,s1,-694 # 80010f90 <proc>
      pp->parent = initproc;
    8000224e:	00006a17          	auipc	s4,0x6
    80002252:	69aa0a13          	addi	s4,s4,1690 # 800088e8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002256:	00014997          	auipc	s3,0x14
    8000225a:	73a98993          	addi	s3,s3,1850 # 80016990 <tickslock>
    8000225e:	a029                	j	80002268 <reparent+0x34>
    80002260:	16848493          	addi	s1,s1,360
    80002264:	01348d63          	beq	s1,s3,8000227e <reparent+0x4a>
    if(pp->parent == p){
    80002268:	7c9c                	ld	a5,56(s1)
    8000226a:	ff279be3          	bne	a5,s2,80002260 <reparent+0x2c>
      pp->parent = initproc;
    8000226e:	000a3503          	ld	a0,0(s4)
    80002272:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002274:	00000097          	auipc	ra,0x0
    80002278:	f4a080e7          	jalr	-182(ra) # 800021be <wakeup>
    8000227c:	b7d5                	j	80002260 <reparent+0x2c>
}
    8000227e:	70a2                	ld	ra,40(sp)
    80002280:	7402                	ld	s0,32(sp)
    80002282:	64e2                	ld	s1,24(sp)
    80002284:	6942                	ld	s2,16(sp)
    80002286:	69a2                	ld	s3,8(sp)
    80002288:	6a02                	ld	s4,0(sp)
    8000228a:	6145                	addi	sp,sp,48
    8000228c:	8082                	ret

000000008000228e <exit>:
{
    8000228e:	7179                	addi	sp,sp,-48
    80002290:	f406                	sd	ra,40(sp)
    80002292:	f022                	sd	s0,32(sp)
    80002294:	ec26                	sd	s1,24(sp)
    80002296:	e84a                	sd	s2,16(sp)
    80002298:	e44e                	sd	s3,8(sp)
    8000229a:	e052                	sd	s4,0(sp)
    8000229c:	1800                	addi	s0,sp,48
    8000229e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	810080e7          	jalr	-2032(ra) # 80001ab0 <myproc>
    800022a8:	89aa                	mv	s3,a0
  if(p == initproc)
    800022aa:	00006797          	auipc	a5,0x6
    800022ae:	63e7b783          	ld	a5,1598(a5) # 800088e8 <initproc>
    800022b2:	0d050493          	addi	s1,a0,208
    800022b6:	15050913          	addi	s2,a0,336
    800022ba:	00a79d63          	bne	a5,a0,800022d4 <exit+0x46>
    panic("init exiting");
    800022be:	00006517          	auipc	a0,0x6
    800022c2:	f8250513          	addi	a0,a0,-126 # 80008240 <etext+0x240>
    800022c6:	ffffe097          	auipc	ra,0xffffe
    800022ca:	29a080e7          	jalr	666(ra) # 80000560 <panic>
  for(int fd = 0; fd < NOFILE; fd++){
    800022ce:	04a1                	addi	s1,s1,8
    800022d0:	01248b63          	beq	s1,s2,800022e6 <exit+0x58>
    if(p->ofile[fd]){
    800022d4:	6088                	ld	a0,0(s1)
    800022d6:	dd65                	beqz	a0,800022ce <exit+0x40>
      fileclose(f);
    800022d8:	00002097          	auipc	ra,0x2
    800022dc:	408080e7          	jalr	1032(ra) # 800046e0 <fileclose>
      p->ofile[fd] = 0;
    800022e0:	0004b023          	sd	zero,0(s1)
    800022e4:	b7ed                	j	800022ce <exit+0x40>
  begin_op();
    800022e6:	00002097          	auipc	ra,0x2
    800022ea:	f2a080e7          	jalr	-214(ra) # 80004210 <begin_op>
  iput(p->cwd);
    800022ee:	1509b503          	ld	a0,336(s3)
    800022f2:	00001097          	auipc	ra,0x1
    800022f6:	6f2080e7          	jalr	1778(ra) # 800039e4 <iput>
  end_op();
    800022fa:	00002097          	auipc	ra,0x2
    800022fe:	f90080e7          	jalr	-112(ra) # 8000428a <end_op>
  p->cwd = 0;
    80002302:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002306:	0000f497          	auipc	s1,0xf
    8000230a:	87248493          	addi	s1,s1,-1934 # 80010b78 <wait_lock>
    8000230e:	8526                	mv	a0,s1
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	976080e7          	jalr	-1674(ra) # 80000c86 <acquire>
  reparent(p);
    80002318:	854e                	mv	a0,s3
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	f1a080e7          	jalr	-230(ra) # 80002234 <reparent>
  wakeup(p->parent);
    80002322:	0389b503          	ld	a0,56(s3)
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	e98080e7          	jalr	-360(ra) # 800021be <wakeup>
  acquire(&p->lock);
    8000232e:	854e                	mv	a0,s3
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	956080e7          	jalr	-1706(ra) # 80000c86 <acquire>
  p->xstate = status;
    80002338:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000233c:	4795                	li	a5,5
    8000233e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	9f2080e7          	jalr	-1550(ra) # 80000d36 <release>
  sched();
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	cfc080e7          	jalr	-772(ra) # 80002048 <sched>
  panic("zombie exit");
    80002354:	00006517          	auipc	a0,0x6
    80002358:	efc50513          	addi	a0,a0,-260 # 80008250 <etext+0x250>
    8000235c:	ffffe097          	auipc	ra,0xffffe
    80002360:	204080e7          	jalr	516(ra) # 80000560 <panic>

0000000080002364 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002364:	7179                	addi	sp,sp,-48
    80002366:	f406                	sd	ra,40(sp)
    80002368:	f022                	sd	s0,32(sp)
    8000236a:	ec26                	sd	s1,24(sp)
    8000236c:	e84a                	sd	s2,16(sp)
    8000236e:	e44e                	sd	s3,8(sp)
    80002370:	1800                	addi	s0,sp,48
    80002372:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002374:	0000f497          	auipc	s1,0xf
    80002378:	c1c48493          	addi	s1,s1,-996 # 80010f90 <proc>
    8000237c:	00014997          	auipc	s3,0x14
    80002380:	61498993          	addi	s3,s3,1556 # 80016990 <tickslock>
    acquire(&p->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	900080e7          	jalr	-1792(ra) # 80000c86 <acquire>
    if(p->pid == pid){
    8000238e:	589c                	lw	a5,48(s1)
    80002390:	01278d63          	beq	a5,s2,800023aa <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	9a0080e7          	jalr	-1632(ra) # 80000d36 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000239e:	16848493          	addi	s1,s1,360
    800023a2:	ff3491e3          	bne	s1,s3,80002384 <kill+0x20>
  }
  return -1;
    800023a6:	557d                	li	a0,-1
    800023a8:	a829                	j	800023c2 <kill+0x5e>
      p->killed = 1;
    800023aa:	4785                	li	a5,1
    800023ac:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023ae:	4c98                	lw	a4,24(s1)
    800023b0:	4789                	li	a5,2
    800023b2:	00f70f63          	beq	a4,a5,800023d0 <kill+0x6c>
      release(&p->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	97e080e7          	jalr	-1666(ra) # 80000d36 <release>
      return 0;
    800023c0:	4501                	li	a0,0
}
    800023c2:	70a2                	ld	ra,40(sp)
    800023c4:	7402                	ld	s0,32(sp)
    800023c6:	64e2                	ld	s1,24(sp)
    800023c8:	6942                	ld	s2,16(sp)
    800023ca:	69a2                	ld	s3,8(sp)
    800023cc:	6145                	addi	sp,sp,48
    800023ce:	8082                	ret
        p->state = RUNNABLE;
    800023d0:	478d                	li	a5,3
    800023d2:	cc9c                	sw	a5,24(s1)
    800023d4:	b7cd                	j	800023b6 <kill+0x52>

00000000800023d6 <setkilled>:

void
setkilled(struct proc *p)
{
    800023d6:	1101                	addi	sp,sp,-32
    800023d8:	ec06                	sd	ra,24(sp)
    800023da:	e822                	sd	s0,16(sp)
    800023dc:	e426                	sd	s1,8(sp)
    800023de:	1000                	addi	s0,sp,32
    800023e0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8a4080e7          	jalr	-1884(ra) # 80000c86 <acquire>
  p->killed = 1;
    800023ea:	4785                	li	a5,1
    800023ec:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023ee:	8526                	mv	a0,s1
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	946080e7          	jalr	-1722(ra) # 80000d36 <release>
}
    800023f8:	60e2                	ld	ra,24(sp)
    800023fa:	6442                	ld	s0,16(sp)
    800023fc:	64a2                	ld	s1,8(sp)
    800023fe:	6105                	addi	sp,sp,32
    80002400:	8082                	ret

0000000080002402 <killed>:

int
killed(struct proc *p)
{
    80002402:	1101                	addi	sp,sp,-32
    80002404:	ec06                	sd	ra,24(sp)
    80002406:	e822                	sd	s0,16(sp)
    80002408:	e426                	sd	s1,8(sp)
    8000240a:	e04a                	sd	s2,0(sp)
    8000240c:	1000                	addi	s0,sp,32
    8000240e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	876080e7          	jalr	-1930(ra) # 80000c86 <acquire>
  k = p->killed;
    80002418:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	918080e7          	jalr	-1768(ra) # 80000d36 <release>
  return k;
}
    80002426:	854a                	mv	a0,s2
    80002428:	60e2                	ld	ra,24(sp)
    8000242a:	6442                	ld	s0,16(sp)
    8000242c:	64a2                	ld	s1,8(sp)
    8000242e:	6902                	ld	s2,0(sp)
    80002430:	6105                	addi	sp,sp,32
    80002432:	8082                	ret

0000000080002434 <wait>:
{
    80002434:	715d                	addi	sp,sp,-80
    80002436:	e486                	sd	ra,72(sp)
    80002438:	e0a2                	sd	s0,64(sp)
    8000243a:	fc26                	sd	s1,56(sp)
    8000243c:	f84a                	sd	s2,48(sp)
    8000243e:	f44e                	sd	s3,40(sp)
    80002440:	f052                	sd	s4,32(sp)
    80002442:	ec56                	sd	s5,24(sp)
    80002444:	e85a                	sd	s6,16(sp)
    80002446:	e45e                	sd	s7,8(sp)
    80002448:	0880                	addi	s0,sp,80
    8000244a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	664080e7          	jalr	1636(ra) # 80001ab0 <myproc>
    80002454:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002456:	0000e517          	auipc	a0,0xe
    8000245a:	72250513          	addi	a0,a0,1826 # 80010b78 <wait_lock>
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	828080e7          	jalr	-2008(ra) # 80000c86 <acquire>
        if(pp->state == ZOMBIE){
    80002466:	4a15                	li	s4,5
        havekids = 1;
    80002468:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000246a:	00014997          	auipc	s3,0x14
    8000246e:	52698993          	addi	s3,s3,1318 # 80016990 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002472:	0000eb97          	auipc	s7,0xe
    80002476:	706b8b93          	addi	s7,s7,1798 # 80010b78 <wait_lock>
    8000247a:	a0c9                	j	8000253c <wait+0x108>
          pid = pp->pid;
    8000247c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002480:	000b0e63          	beqz	s6,8000249c <wait+0x68>
    80002484:	4691                	li	a3,4
    80002486:	02c48613          	addi	a2,s1,44
    8000248a:	85da                	mv	a1,s6
    8000248c:	05093503          	ld	a0,80(s2)
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	2c8080e7          	jalr	712(ra) # 80001758 <copyout>
    80002498:	04054063          	bltz	a0,800024d8 <wait+0xa4>
          freeproc(pp);
    8000249c:	8526                	mv	a0,s1
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	7c4080e7          	jalr	1988(ra) # 80001c62 <freeproc>
          release(&pp->lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	88e080e7          	jalr	-1906(ra) # 80000d36 <release>
          release(&wait_lock);
    800024b0:	0000e517          	auipc	a0,0xe
    800024b4:	6c850513          	addi	a0,a0,1736 # 80010b78 <wait_lock>
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	87e080e7          	jalr	-1922(ra) # 80000d36 <release>
}
    800024c0:	854e                	mv	a0,s3
    800024c2:	60a6                	ld	ra,72(sp)
    800024c4:	6406                	ld	s0,64(sp)
    800024c6:	74e2                	ld	s1,56(sp)
    800024c8:	7942                	ld	s2,48(sp)
    800024ca:	79a2                	ld	s3,40(sp)
    800024cc:	7a02                	ld	s4,32(sp)
    800024ce:	6ae2                	ld	s5,24(sp)
    800024d0:	6b42                	ld	s6,16(sp)
    800024d2:	6ba2                	ld	s7,8(sp)
    800024d4:	6161                	addi	sp,sp,80
    800024d6:	8082                	ret
            release(&pp->lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	85c080e7          	jalr	-1956(ra) # 80000d36 <release>
            release(&wait_lock);
    800024e2:	0000e517          	auipc	a0,0xe
    800024e6:	69650513          	addi	a0,a0,1686 # 80010b78 <wait_lock>
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	84c080e7          	jalr	-1972(ra) # 80000d36 <release>
            return -1;
    800024f2:	59fd                	li	s3,-1
    800024f4:	b7f1                	j	800024c0 <wait+0x8c>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024f6:	16848493          	addi	s1,s1,360
    800024fa:	03348463          	beq	s1,s3,80002522 <wait+0xee>
      if(pp->parent == p){
    800024fe:	7c9c                	ld	a5,56(s1)
    80002500:	ff279be3          	bne	a5,s2,800024f6 <wait+0xc2>
        acquire(&pp->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	780080e7          	jalr	1920(ra) # 80000c86 <acquire>
        if(pp->state == ZOMBIE){
    8000250e:	4c9c                	lw	a5,24(s1)
    80002510:	f74786e3          	beq	a5,s4,8000247c <wait+0x48>
        release(&pp->lock);
    80002514:	8526                	mv	a0,s1
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	820080e7          	jalr	-2016(ra) # 80000d36 <release>
        havekids = 1;
    8000251e:	8756                	mv	a4,s5
    80002520:	bfd9                	j	800024f6 <wait+0xc2>
    if(!havekids || killed(p)){
    80002522:	c31d                	beqz	a4,80002548 <wait+0x114>
    80002524:	854a                	mv	a0,s2
    80002526:	00000097          	auipc	ra,0x0
    8000252a:	edc080e7          	jalr	-292(ra) # 80002402 <killed>
    8000252e:	ed09                	bnez	a0,80002548 <wait+0x114>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002530:	85de                	mv	a1,s7
    80002532:	854a                	mv	a0,s2
    80002534:	00000097          	auipc	ra,0x0
    80002538:	c26080e7          	jalr	-986(ra) # 8000215a <sleep>
    havekids = 0;
    8000253c:	4701                	li	a4,0
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000253e:	0000f497          	auipc	s1,0xf
    80002542:	a5248493          	addi	s1,s1,-1454 # 80010f90 <proc>
    80002546:	bf65                	j	800024fe <wait+0xca>
      release(&wait_lock);
    80002548:	0000e517          	auipc	a0,0xe
    8000254c:	63050513          	addi	a0,a0,1584 # 80010b78 <wait_lock>
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	7e6080e7          	jalr	2022(ra) # 80000d36 <release>
      return -1;
    80002558:	59fd                	li	s3,-1
    8000255a:	b79d                	j	800024c0 <wait+0x8c>

000000008000255c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000255c:	7179                	addi	sp,sp,-48
    8000255e:	f406                	sd	ra,40(sp)
    80002560:	f022                	sd	s0,32(sp)
    80002562:	ec26                	sd	s1,24(sp)
    80002564:	e84a                	sd	s2,16(sp)
    80002566:	e44e                	sd	s3,8(sp)
    80002568:	e052                	sd	s4,0(sp)
    8000256a:	1800                	addi	s0,sp,48
    8000256c:	84aa                	mv	s1,a0
    8000256e:	892e                	mv	s2,a1
    80002570:	89b2                	mv	s3,a2
    80002572:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	53c080e7          	jalr	1340(ra) # 80001ab0 <myproc>
  if(user_dst){
    8000257c:	c08d                	beqz	s1,8000259e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000257e:	86d2                	mv	a3,s4
    80002580:	864e                	mv	a2,s3
    80002582:	85ca                	mv	a1,s2
    80002584:	6928                	ld	a0,80(a0)
    80002586:	fffff097          	auipc	ra,0xfffff
    8000258a:	1d2080e7          	jalr	466(ra) # 80001758 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000258e:	70a2                	ld	ra,40(sp)
    80002590:	7402                	ld	s0,32(sp)
    80002592:	64e2                	ld	s1,24(sp)
    80002594:	6942                	ld	s2,16(sp)
    80002596:	69a2                	ld	s3,8(sp)
    80002598:	6a02                	ld	s4,0(sp)
    8000259a:	6145                	addi	sp,sp,48
    8000259c:	8082                	ret
    memmove((char *)dst, src, len);
    8000259e:	000a061b          	sext.w	a2,s4
    800025a2:	85ce                	mv	a1,s3
    800025a4:	854a                	mv	a0,s2
    800025a6:	fffff097          	auipc	ra,0xfffff
    800025aa:	83c080e7          	jalr	-1988(ra) # 80000de2 <memmove>
    return 0;
    800025ae:	8526                	mv	a0,s1
    800025b0:	bff9                	j	8000258e <either_copyout+0x32>

00000000800025b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025b2:	7179                	addi	sp,sp,-48
    800025b4:	f406                	sd	ra,40(sp)
    800025b6:	f022                	sd	s0,32(sp)
    800025b8:	ec26                	sd	s1,24(sp)
    800025ba:	e84a                	sd	s2,16(sp)
    800025bc:	e44e                	sd	s3,8(sp)
    800025be:	e052                	sd	s4,0(sp)
    800025c0:	1800                	addi	s0,sp,48
    800025c2:	892a                	mv	s2,a0
    800025c4:	84ae                	mv	s1,a1
    800025c6:	89b2                	mv	s3,a2
    800025c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	4e6080e7          	jalr	1254(ra) # 80001ab0 <myproc>
  if(user_src){
    800025d2:	c08d                	beqz	s1,800025f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025d4:	86d2                	mv	a3,s4
    800025d6:	864e                	mv	a2,s3
    800025d8:	85ca                	mv	a1,s2
    800025da:	6928                	ld	a0,80(a0)
    800025dc:	fffff097          	auipc	ra,0xfffff
    800025e0:	208080e7          	jalr	520(ra) # 800017e4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025e4:	70a2                	ld	ra,40(sp)
    800025e6:	7402                	ld	s0,32(sp)
    800025e8:	64e2                	ld	s1,24(sp)
    800025ea:	6942                	ld	s2,16(sp)
    800025ec:	69a2                	ld	s3,8(sp)
    800025ee:	6a02                	ld	s4,0(sp)
    800025f0:	6145                	addi	sp,sp,48
    800025f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800025f4:	000a061b          	sext.w	a2,s4
    800025f8:	85ce                	mv	a1,s3
    800025fa:	854a                	mv	a0,s2
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	7e6080e7          	jalr	2022(ra) # 80000de2 <memmove>
    return 0;
    80002604:	8526                	mv	a0,s1
    80002606:	bff9                	j	800025e4 <either_copyin+0x32>

0000000080002608 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002608:	715d                	addi	sp,sp,-80
    8000260a:	e486                	sd	ra,72(sp)
    8000260c:	e0a2                	sd	s0,64(sp)
    8000260e:	fc26                	sd	s1,56(sp)
    80002610:	f84a                	sd	s2,48(sp)
    80002612:	f44e                	sd	s3,40(sp)
    80002614:	f052                	sd	s4,32(sp)
    80002616:	ec56                	sd	s5,24(sp)
    80002618:	e85a                	sd	s6,16(sp)
    8000261a:	e45e                	sd	s7,8(sp)
    8000261c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000261e:	00006517          	auipc	a0,0x6
    80002622:	9f250513          	addi	a0,a0,-1550 # 80008010 <etext+0x10>
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	f84080e7          	jalr	-124(ra) # 800005aa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000262e:	0000f497          	auipc	s1,0xf
    80002632:	aba48493          	addi	s1,s1,-1350 # 800110e8 <proc+0x158>
    80002636:	00014917          	auipc	s2,0x14
    8000263a:	4b290913          	addi	s2,s2,1202 # 80016ae8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000263e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002640:	00006997          	auipc	s3,0x6
    80002644:	c2098993          	addi	s3,s3,-992 # 80008260 <etext+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002648:	00006a97          	auipc	s5,0x6
    8000264c:	c20a8a93          	addi	s5,s5,-992 # 80008268 <etext+0x268>
    printf("\n");
    80002650:	00006a17          	auipc	s4,0x6
    80002654:	9c0a0a13          	addi	s4,s4,-1600 # 80008010 <etext+0x10>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002658:	00006b97          	auipc	s7,0x6
    8000265c:	108b8b93          	addi	s7,s7,264 # 80008760 <states.0>
    80002660:	a00d                	j	80002682 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002662:	ed86a583          	lw	a1,-296(a3)
    80002666:	8556                	mv	a0,s5
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	f42080e7          	jalr	-190(ra) # 800005aa <printf>
    printf("\n");
    80002670:	8552                	mv	a0,s4
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	f38080e7          	jalr	-200(ra) # 800005aa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000267a:	16848493          	addi	s1,s1,360
    8000267e:	03248263          	beq	s1,s2,800026a2 <procdump+0x9a>
    if(p->state == UNUSED)
    80002682:	86a6                	mv	a3,s1
    80002684:	ec04a783          	lw	a5,-320(s1)
    80002688:	dbed                	beqz	a5,8000267a <procdump+0x72>
      state = "???";
    8000268a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000268c:	fcfb6be3          	bltu	s6,a5,80002662 <procdump+0x5a>
    80002690:	02079713          	slli	a4,a5,0x20
    80002694:	01d75793          	srli	a5,a4,0x1d
    80002698:	97de                	add	a5,a5,s7
    8000269a:	6390                	ld	a2,0(a5)
    8000269c:	f279                	bnez	a2,80002662 <procdump+0x5a>
      state = "???";
    8000269e:	864e                	mv	a2,s3
    800026a0:	b7c9                	j	80002662 <procdump+0x5a>
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

00000000800026b8 <print_hello>:
void print_hello(int n)
{
    800026b8:	1141                	addi	sp,sp,-16
    800026ba:	e406                	sd	ra,8(sp)
    800026bc:	e022                	sd	s0,0(sp)
    800026be:	0800                	addi	s0,sp,16
    800026c0:	85aa                	mv	a1,a0
  printf("Hello from the kernel space %d\n",n);
    800026c2:	00006517          	auipc	a0,0x6
    800026c6:	bb650513          	addi	a0,a0,-1098 # 80008278 <etext+0x278>
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	ee0080e7          	jalr	-288(ra) # 800005aa <printf>
}
    800026d2:	60a2                	ld	ra,8(sp)
    800026d4:	6402                	ld	s0,0(sp)
    800026d6:	0141                	addi	sp,sp,16
    800026d8:	8082                	ret

00000000800026da <count_active_procs>:

int
count_active_procs(void)
{
    800026da:	1141                	addi	sp,sp,-16
    800026dc:	e406                	sd	ra,8(sp)
    800026de:	e022                	sd	s0,0(sp)
    800026e0:	0800                	addi	s0,sp,16
  struct proc *p;
  int count = 0;
    800026e2:	4501                	li	a0,0
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800026e4:	0000f797          	auipc	a5,0xf
    800026e8:	8ac78793          	addi	a5,a5,-1876 # 80010f90 <proc>
    800026ec:	00014697          	auipc	a3,0x14
    800026f0:	2a468693          	addi	a3,a3,676 # 80016990 <tickslock>
    800026f4:	a029                	j	800026fe <count_active_procs+0x24>
    800026f6:	16878793          	addi	a5,a5,360
    800026fa:	00d78663          	beq	a5,a3,80002706 <count_active_procs+0x2c>
    if(p->state != UNUSED)
    800026fe:	4f98                	lw	a4,24(a5)
    80002700:	db7d                	beqz	a4,800026f6 <count_active_procs+0x1c>
      count++;
    80002702:	2505                	addiw	a0,a0,1
    80002704:	bfcd                	j	800026f6 <count_active_procs+0x1c>
  }
  
  return count;
    80002706:	60a2                	ld	ra,8(sp)
    80002708:	6402                	ld	s0,0(sp)
    8000270a:	0141                	addi	sp,sp,16
    8000270c:	8082                	ret

000000008000270e <swtch>:
    8000270e:	00153023          	sd	ra,0(a0)
    80002712:	00253423          	sd	sp,8(a0)
    80002716:	e900                	sd	s0,16(a0)
    80002718:	ed04                	sd	s1,24(a0)
    8000271a:	03253023          	sd	s2,32(a0)
    8000271e:	03353423          	sd	s3,40(a0)
    80002722:	03453823          	sd	s4,48(a0)
    80002726:	03553c23          	sd	s5,56(a0)
    8000272a:	05653023          	sd	s6,64(a0)
    8000272e:	05753423          	sd	s7,72(a0)
    80002732:	05853823          	sd	s8,80(a0)
    80002736:	05953c23          	sd	s9,88(a0)
    8000273a:	07a53023          	sd	s10,96(a0)
    8000273e:	07b53423          	sd	s11,104(a0)
    80002742:	0005b083          	ld	ra,0(a1)
    80002746:	0085b103          	ld	sp,8(a1)
    8000274a:	6980                	ld	s0,16(a1)
    8000274c:	6d84                	ld	s1,24(a1)
    8000274e:	0205b903          	ld	s2,32(a1)
    80002752:	0285b983          	ld	s3,40(a1)
    80002756:	0305ba03          	ld	s4,48(a1)
    8000275a:	0385ba83          	ld	s5,56(a1)
    8000275e:	0405bb03          	ld	s6,64(a1)
    80002762:	0485bb83          	ld	s7,72(a1)
    80002766:	0505bc03          	ld	s8,80(a1)
    8000276a:	0585bc83          	ld	s9,88(a1)
    8000276e:	0605bd03          	ld	s10,96(a1)
    80002772:	0685bd83          	ld	s11,104(a1)
    80002776:	8082                	ret

0000000080002778 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002778:	1141                	addi	sp,sp,-16
    8000277a:	e406                	sd	ra,8(sp)
    8000277c:	e022                	sd	s0,0(sp)
    8000277e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002780:	00006597          	auipc	a1,0x6
    80002784:	b4858593          	addi	a1,a1,-1208 # 800082c8 <etext+0x2c8>
    80002788:	00014517          	auipc	a0,0x14
    8000278c:	20850513          	addi	a0,a0,520 # 80016990 <tickslock>
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	462080e7          	jalr	1122(ra) # 80000bf2 <initlock>
}
    80002798:	60a2                	ld	ra,8(sp)
    8000279a:	6402                	ld	s0,0(sp)
    8000279c:	0141                	addi	sp,sp,16
    8000279e:	8082                	ret

00000000800027a0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027a0:	1141                	addi	sp,sp,-16
    800027a2:	e406                	sd	ra,8(sp)
    800027a4:	e022                	sd	s0,0(sp)
    800027a6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a8:	00003797          	auipc	a5,0x3
    800027ac:	68878793          	addi	a5,a5,1672 # 80005e30 <kernelvec>
    800027b0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027b4:	60a2                	ld	ra,8(sp)
    800027b6:	6402                	ld	s0,0(sp)
    800027b8:	0141                	addi	sp,sp,16
    800027ba:	8082                	ret

00000000800027bc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027bc:	1141                	addi	sp,sp,-16
    800027be:	e406                	sd	ra,8(sp)
    800027c0:	e022                	sd	s0,0(sp)
    800027c2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	2ec080e7          	jalr	748(ra) # 80001ab0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027d0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027d6:	00005697          	auipc	a3,0x5
    800027da:	82a68693          	addi	a3,a3,-2006 # 80007000 <_trampoline>
    800027de:	00005717          	auipc	a4,0x5
    800027e2:	82270713          	addi	a4,a4,-2014 # 80007000 <_trampoline>
    800027e6:	8f15                	sub	a4,a4,a3
    800027e8:	040007b7          	lui	a5,0x4000
    800027ec:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800027ee:	07b2                	slli	a5,a5,0xc
    800027f0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027f6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027f8:	18002673          	csrr	a2,satp
    800027fc:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027fe:	6d30                	ld	a2,88(a0)
    80002800:	6138                	ld	a4,64(a0)
    80002802:	6585                	lui	a1,0x1
    80002804:	972e                	add	a4,a4,a1
    80002806:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002808:	6d38                	ld	a4,88(a0)
    8000280a:	00000617          	auipc	a2,0x0
    8000280e:	13860613          	addi	a2,a2,312 # 80002942 <usertrap>
    80002812:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002814:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002816:	8612                	mv	a2,tp
    80002818:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000281a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000281e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002822:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002826:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000282a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000282c:	6f18                	ld	a4,24(a4)
    8000282e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002832:	6928                	ld	a0,80(a0)
    80002834:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002836:	00005717          	auipc	a4,0x5
    8000283a:	86670713          	addi	a4,a4,-1946 # 8000709c <userret>
    8000283e:	8f15                	sub	a4,a4,a3
    80002840:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002842:	577d                	li	a4,-1
    80002844:	177e                	slli	a4,a4,0x3f
    80002846:	8d59                	or	a0,a0,a4
    80002848:	9782                	jalr	a5
}
    8000284a:	60a2                	ld	ra,8(sp)
    8000284c:	6402                	ld	s0,0(sp)
    8000284e:	0141                	addi	sp,sp,16
    80002850:	8082                	ret

0000000080002852 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002852:	1101                	addi	sp,sp,-32
    80002854:	ec06                	sd	ra,24(sp)
    80002856:	e822                	sd	s0,16(sp)
    80002858:	e426                	sd	s1,8(sp)
    8000285a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000285c:	00014497          	auipc	s1,0x14
    80002860:	13448493          	addi	s1,s1,308 # 80016990 <tickslock>
    80002864:	8526                	mv	a0,s1
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	420080e7          	jalr	1056(ra) # 80000c86 <acquire>
  ticks++;
    8000286e:	00006517          	auipc	a0,0x6
    80002872:	08250513          	addi	a0,a0,130 # 800088f0 <ticks>
    80002876:	411c                	lw	a5,0(a0)
    80002878:	2785                	addiw	a5,a5,1
    8000287a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	942080e7          	jalr	-1726(ra) # 800021be <wakeup>
  release(&tickslock);
    80002884:	8526                	mv	a0,s1
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	4b0080e7          	jalr	1200(ra) # 80000d36 <release>
}
    8000288e:	60e2                	ld	ra,24(sp)
    80002890:	6442                	ld	s0,16(sp)
    80002892:	64a2                	ld	s1,8(sp)
    80002894:	6105                	addi	sp,sp,32
    80002896:	8082                	ret

0000000080002898 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002898:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000289c:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    8000289e:	0a07d163          	bgez	a5,80002940 <devintr+0xa8>
{
    800028a2:	1101                	addi	sp,sp,-32
    800028a4:	ec06                	sd	ra,24(sp)
    800028a6:	e822                	sd	s0,16(sp)
    800028a8:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    800028aa:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    800028ae:	46a5                	li	a3,9
    800028b0:	00d70c63          	beq	a4,a3,800028c8 <devintr+0x30>
  } else if(scause == 0x8000000000000001L){
    800028b4:	577d                	li	a4,-1
    800028b6:	177e                	slli	a4,a4,0x3f
    800028b8:	0705                	addi	a4,a4,1
    return 0;
    800028ba:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028bc:	06e78163          	beq	a5,a4,8000291e <devintr+0x86>
  }
}
    800028c0:	60e2                	ld	ra,24(sp)
    800028c2:	6442                	ld	s0,16(sp)
    800028c4:	6105                	addi	sp,sp,32
    800028c6:	8082                	ret
    800028c8:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    800028ca:	00003097          	auipc	ra,0x3
    800028ce:	672080e7          	jalr	1650(ra) # 80005f3c <plic_claim>
    800028d2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028d4:	47a9                	li	a5,10
    800028d6:	00f50963          	beq	a0,a5,800028e8 <devintr+0x50>
    } else if(irq == VIRTIO0_IRQ){
    800028da:	4785                	li	a5,1
    800028dc:	00f50b63          	beq	a0,a5,800028f2 <devintr+0x5a>
    return 1;
    800028e0:	4505                	li	a0,1
    } else if(irq){
    800028e2:	ec89                	bnez	s1,800028fc <devintr+0x64>
    800028e4:	64a2                	ld	s1,8(sp)
    800028e6:	bfe9                	j	800028c0 <devintr+0x28>
      uartintr();
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	114080e7          	jalr	276(ra) # 800009fc <uartintr>
    if(irq)
    800028f0:	a839                	j	8000290e <devintr+0x76>
      virtio_disk_intr();
    800028f2:	00004097          	auipc	ra,0x4
    800028f6:	b3e080e7          	jalr	-1218(ra) # 80006430 <virtio_disk_intr>
    if(irq)
    800028fa:	a811                	j	8000290e <devintr+0x76>
      printf("unexpected interrupt irq=%d\n", irq);
    800028fc:	85a6                	mv	a1,s1
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	9d250513          	addi	a0,a0,-1582 # 800082d0 <etext+0x2d0>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	ca4080e7          	jalr	-860(ra) # 800005aa <printf>
      plic_complete(irq);
    8000290e:	8526                	mv	a0,s1
    80002910:	00003097          	auipc	ra,0x3
    80002914:	650080e7          	jalr	1616(ra) # 80005f60 <plic_complete>
    return 1;
    80002918:	4505                	li	a0,1
    8000291a:	64a2                	ld	s1,8(sp)
    8000291c:	b755                	j	800028c0 <devintr+0x28>
    if(cpuid() == 0){
    8000291e:	fffff097          	auipc	ra,0xfffff
    80002922:	15e080e7          	jalr	350(ra) # 80001a7c <cpuid>
    80002926:	c901                	beqz	a0,80002936 <devintr+0x9e>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002928:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000292c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000292e:	14479073          	csrw	sip,a5
    return 2;
    80002932:	4509                	li	a0,2
    80002934:	b771                	j	800028c0 <devintr+0x28>
      clockintr();
    80002936:	00000097          	auipc	ra,0x0
    8000293a:	f1c080e7          	jalr	-228(ra) # 80002852 <clockintr>
    8000293e:	b7ed                	j	80002928 <devintr+0x90>
}
    80002940:	8082                	ret

0000000080002942 <usertrap>:
{
    80002942:	1101                	addi	sp,sp,-32
    80002944:	ec06                	sd	ra,24(sp)
    80002946:	e822                	sd	s0,16(sp)
    80002948:	e426                	sd	s1,8(sp)
    8000294a:	e04a                	sd	s2,0(sp)
    8000294c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000294e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002952:	1007f793          	andi	a5,a5,256
    80002956:	e3b1                	bnez	a5,8000299a <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002958:	00003797          	auipc	a5,0x3
    8000295c:	4d878793          	addi	a5,a5,1240 # 80005e30 <kernelvec>
    80002960:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002964:	fffff097          	auipc	ra,0xfffff
    80002968:	14c080e7          	jalr	332(ra) # 80001ab0 <myproc>
    8000296c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000296e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002970:	14102773          	csrr	a4,sepc
    80002974:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002976:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000297a:	47a1                	li	a5,8
    8000297c:	02f70763          	beq	a4,a5,800029aa <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002980:	00000097          	auipc	ra,0x0
    80002984:	f18080e7          	jalr	-232(ra) # 80002898 <devintr>
    80002988:	892a                	mv	s2,a0
    8000298a:	c151                	beqz	a0,80002a0e <usertrap+0xcc>
  if(killed(p))
    8000298c:	8526                	mv	a0,s1
    8000298e:	00000097          	auipc	ra,0x0
    80002992:	a74080e7          	jalr	-1420(ra) # 80002402 <killed>
    80002996:	c929                	beqz	a0,800029e8 <usertrap+0xa6>
    80002998:	a099                	j	800029de <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000299a:	00006517          	auipc	a0,0x6
    8000299e:	95650513          	addi	a0,a0,-1706 # 800082f0 <etext+0x2f0>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	bbe080e7          	jalr	-1090(ra) # 80000560 <panic>
    if(killed(p))
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	a58080e7          	jalr	-1448(ra) # 80002402 <killed>
    800029b2:	e921                	bnez	a0,80002a02 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800029b4:	6cb8                	ld	a4,88(s1)
    800029b6:	6f1c                	ld	a5,24(a4)
    800029b8:	0791                	addi	a5,a5,4
    800029ba:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029c0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c4:	10079073          	csrw	sstatus,a5
    syscall();
    800029c8:	00000097          	auipc	ra,0x0
    800029cc:	2cc080e7          	jalr	716(ra) # 80002c94 <syscall>
  if(killed(p))
    800029d0:	8526                	mv	a0,s1
    800029d2:	00000097          	auipc	ra,0x0
    800029d6:	a30080e7          	jalr	-1488(ra) # 80002402 <killed>
    800029da:	c911                	beqz	a0,800029ee <usertrap+0xac>
    800029dc:	4901                	li	s2,0
    exit(-1);
    800029de:	557d                	li	a0,-1
    800029e0:	00000097          	auipc	ra,0x0
    800029e4:	8ae080e7          	jalr	-1874(ra) # 8000228e <exit>
  if(which_dev == 2)
    800029e8:	4789                	li	a5,2
    800029ea:	04f90f63          	beq	s2,a5,80002a48 <usertrap+0x106>
  usertrapret();
    800029ee:	00000097          	auipc	ra,0x0
    800029f2:	dce080e7          	jalr	-562(ra) # 800027bc <usertrapret>
}
    800029f6:	60e2                	ld	ra,24(sp)
    800029f8:	6442                	ld	s0,16(sp)
    800029fa:	64a2                	ld	s1,8(sp)
    800029fc:	6902                	ld	s2,0(sp)
    800029fe:	6105                	addi	sp,sp,32
    80002a00:	8082                	ret
      exit(-1);
    80002a02:	557d                	li	a0,-1
    80002a04:	00000097          	auipc	ra,0x0
    80002a08:	88a080e7          	jalr	-1910(ra) # 8000228e <exit>
    80002a0c:	b765                	j	800029b4 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a12:	5890                	lw	a2,48(s1)
    80002a14:	00006517          	auipc	a0,0x6
    80002a18:	8fc50513          	addi	a0,a0,-1796 # 80008310 <etext+0x310>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	b8e080e7          	jalr	-1138(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a24:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a28:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	91450513          	addi	a0,a0,-1772 # 80008340 <etext+0x340>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b76080e7          	jalr	-1162(ra) # 800005aa <printf>
    setkilled(p);
    80002a3c:	8526                	mv	a0,s1
    80002a3e:	00000097          	auipc	ra,0x0
    80002a42:	998080e7          	jalr	-1640(ra) # 800023d6 <setkilled>
    80002a46:	b769                	j	800029d0 <usertrap+0x8e>
    yield();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	6d6080e7          	jalr	1750(ra) # 8000211e <yield>
    80002a50:	bf79                	j	800029ee <usertrap+0xac>

0000000080002a52 <kerneltrap>:
{
    80002a52:	7179                	addi	sp,sp,-48
    80002a54:	f406                	sd	ra,40(sp)
    80002a56:	f022                	sd	s0,32(sp)
    80002a58:	ec26                	sd	s1,24(sp)
    80002a5a:	e84a                	sd	s2,16(sp)
    80002a5c:	e44e                	sd	s3,8(sp)
    80002a5e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a60:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a64:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a68:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a6c:	1004f793          	andi	a5,s1,256
    80002a70:	cb85                	beqz	a5,80002aa0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a76:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a78:	ef85                	bnez	a5,80002ab0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	e1e080e7          	jalr	-482(ra) # 80002898 <devintr>
    80002a82:	cd1d                	beqz	a0,80002ac0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a84:	4789                	li	a5,2
    80002a86:	06f50a63          	beq	a0,a5,80002afa <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a8a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a8e:	10049073          	csrw	sstatus,s1
}
    80002a92:	70a2                	ld	ra,40(sp)
    80002a94:	7402                	ld	s0,32(sp)
    80002a96:	64e2                	ld	s1,24(sp)
    80002a98:	6942                	ld	s2,16(sp)
    80002a9a:	69a2                	ld	s3,8(sp)
    80002a9c:	6145                	addi	sp,sp,48
    80002a9e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	8c050513          	addi	a0,a0,-1856 # 80008360 <etext+0x360>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	ab8080e7          	jalr	-1352(ra) # 80000560 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ab0:	00006517          	auipc	a0,0x6
    80002ab4:	8d850513          	addi	a0,a0,-1832 # 80008388 <etext+0x388>
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	aa8080e7          	jalr	-1368(ra) # 80000560 <panic>
    printf("scause %p\n", scause);
    80002ac0:	85ce                	mv	a1,s3
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	8e650513          	addi	a0,a0,-1818 # 800083a8 <etext+0x3a8>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	ae0080e7          	jalr	-1312(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ad6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ada:	00006517          	auipc	a0,0x6
    80002ade:	8de50513          	addi	a0,a0,-1826 # 800083b8 <etext+0x3b8>
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	ac8080e7          	jalr	-1336(ra) # 800005aa <printf>
    panic("kerneltrap");
    80002aea:	00006517          	auipc	a0,0x6
    80002aee:	8e650513          	addi	a0,a0,-1818 # 800083d0 <etext+0x3d0>
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	a6e080e7          	jalr	-1426(ra) # 80000560 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002afa:	fffff097          	auipc	ra,0xfffff
    80002afe:	fb6080e7          	jalr	-74(ra) # 80001ab0 <myproc>
    80002b02:	d541                	beqz	a0,80002a8a <kerneltrap+0x38>
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	fac080e7          	jalr	-84(ra) # 80001ab0 <myproc>
    80002b0c:	4d18                	lw	a4,24(a0)
    80002b0e:	4791                	li	a5,4
    80002b10:	f6f71de3          	bne	a4,a5,80002a8a <kerneltrap+0x38>
    yield();
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	60a080e7          	jalr	1546(ra) # 8000211e <yield>
    80002b1c:	b7bd                	j	80002a8a <kerneltrap+0x38>

0000000080002b1e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b1e:	1101                	addi	sp,sp,-32
    80002b20:	ec06                	sd	ra,24(sp)
    80002b22:	e822                	sd	s0,16(sp)
    80002b24:	e426                	sd	s1,8(sp)
    80002b26:	1000                	addi	s0,sp,32
    80002b28:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	f86080e7          	jalr	-122(ra) # 80001ab0 <myproc>
  switch (n) {
    80002b32:	4795                	li	a5,5
    80002b34:	0497e163          	bltu	a5,s1,80002b76 <argraw+0x58>
    80002b38:	048a                	slli	s1,s1,0x2
    80002b3a:	00006717          	auipc	a4,0x6
    80002b3e:	c5670713          	addi	a4,a4,-938 # 80008790 <states.0+0x30>
    80002b42:	94ba                	add	s1,s1,a4
    80002b44:	409c                	lw	a5,0(s1)
    80002b46:	97ba                	add	a5,a5,a4
    80002b48:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b4a:	6d3c                	ld	a5,88(a0)
    80002b4c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b4e:	60e2                	ld	ra,24(sp)
    80002b50:	6442                	ld	s0,16(sp)
    80002b52:	64a2                	ld	s1,8(sp)
    80002b54:	6105                	addi	sp,sp,32
    80002b56:	8082                	ret
    return p->trapframe->a1;
    80002b58:	6d3c                	ld	a5,88(a0)
    80002b5a:	7fa8                	ld	a0,120(a5)
    80002b5c:	bfcd                	j	80002b4e <argraw+0x30>
    return p->trapframe->a2;
    80002b5e:	6d3c                	ld	a5,88(a0)
    80002b60:	63c8                	ld	a0,128(a5)
    80002b62:	b7f5                	j	80002b4e <argraw+0x30>
    return p->trapframe->a3;
    80002b64:	6d3c                	ld	a5,88(a0)
    80002b66:	67c8                	ld	a0,136(a5)
    80002b68:	b7dd                	j	80002b4e <argraw+0x30>
    return p->trapframe->a4;
    80002b6a:	6d3c                	ld	a5,88(a0)
    80002b6c:	6bc8                	ld	a0,144(a5)
    80002b6e:	b7c5                	j	80002b4e <argraw+0x30>
    return p->trapframe->a5;
    80002b70:	6d3c                	ld	a5,88(a0)
    80002b72:	6fc8                	ld	a0,152(a5)
    80002b74:	bfe9                	j	80002b4e <argraw+0x30>
  panic("argraw");
    80002b76:	00006517          	auipc	a0,0x6
    80002b7a:	86a50513          	addi	a0,a0,-1942 # 800083e0 <etext+0x3e0>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	9e2080e7          	jalr	-1566(ra) # 80000560 <panic>

0000000080002b86 <fetchaddr>:
{
    80002b86:	1101                	addi	sp,sp,-32
    80002b88:	ec06                	sd	ra,24(sp)
    80002b8a:	e822                	sd	s0,16(sp)
    80002b8c:	e426                	sd	s1,8(sp)
    80002b8e:	e04a                	sd	s2,0(sp)
    80002b90:	1000                	addi	s0,sp,32
    80002b92:	84aa                	mv	s1,a0
    80002b94:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	f1a080e7          	jalr	-230(ra) # 80001ab0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b9e:	653c                	ld	a5,72(a0)
    80002ba0:	02f4f863          	bgeu	s1,a5,80002bd0 <fetchaddr+0x4a>
    80002ba4:	00848713          	addi	a4,s1,8
    80002ba8:	02e7e663          	bltu	a5,a4,80002bd4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bac:	46a1                	li	a3,8
    80002bae:	8626                	mv	a2,s1
    80002bb0:	85ca                	mv	a1,s2
    80002bb2:	6928                	ld	a0,80(a0)
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	c30080e7          	jalr	-976(ra) # 800017e4 <copyin>
    80002bbc:	00a03533          	snez	a0,a0
    80002bc0:	40a0053b          	negw	a0,a0
}
    80002bc4:	60e2                	ld	ra,24(sp)
    80002bc6:	6442                	ld	s0,16(sp)
    80002bc8:	64a2                	ld	s1,8(sp)
    80002bca:	6902                	ld	s2,0(sp)
    80002bcc:	6105                	addi	sp,sp,32
    80002bce:	8082                	ret
    return -1;
    80002bd0:	557d                	li	a0,-1
    80002bd2:	bfcd                	j	80002bc4 <fetchaddr+0x3e>
    80002bd4:	557d                	li	a0,-1
    80002bd6:	b7fd                	j	80002bc4 <fetchaddr+0x3e>

0000000080002bd8 <fetchstr>:
{
    80002bd8:	7179                	addi	sp,sp,-48
    80002bda:	f406                	sd	ra,40(sp)
    80002bdc:	f022                	sd	s0,32(sp)
    80002bde:	ec26                	sd	s1,24(sp)
    80002be0:	e84a                	sd	s2,16(sp)
    80002be2:	e44e                	sd	s3,8(sp)
    80002be4:	1800                	addi	s0,sp,48
    80002be6:	892a                	mv	s2,a0
    80002be8:	84ae                	mv	s1,a1
    80002bea:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bec:	fffff097          	auipc	ra,0xfffff
    80002bf0:	ec4080e7          	jalr	-316(ra) # 80001ab0 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002bf4:	86ce                	mv	a3,s3
    80002bf6:	864a                	mv	a2,s2
    80002bf8:	85a6                	mv	a1,s1
    80002bfa:	6928                	ld	a0,80(a0)
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	c76080e7          	jalr	-906(ra) # 80001872 <copyinstr>
    80002c04:	00054e63          	bltz	a0,80002c20 <fetchstr+0x48>
  return strlen(buf);
    80002c08:	8526                	mv	a0,s1
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	300080e7          	jalr	768(ra) # 80000f0a <strlen>
}
    80002c12:	70a2                	ld	ra,40(sp)
    80002c14:	7402                	ld	s0,32(sp)
    80002c16:	64e2                	ld	s1,24(sp)
    80002c18:	6942                	ld	s2,16(sp)
    80002c1a:	69a2                	ld	s3,8(sp)
    80002c1c:	6145                	addi	sp,sp,48
    80002c1e:	8082                	ret
    return -1;
    80002c20:	557d                	li	a0,-1
    80002c22:	bfc5                	j	80002c12 <fetchstr+0x3a>

0000000080002c24 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	1000                	addi	s0,sp,32
    80002c2e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	eee080e7          	jalr	-274(ra) # 80002b1e <argraw>
    80002c38:	c088                	sw	a0,0(s1)
}
    80002c3a:	60e2                	ld	ra,24(sp)
    80002c3c:	6442                	ld	s0,16(sp)
    80002c3e:	64a2                	ld	s1,8(sp)
    80002c40:	6105                	addi	sp,sp,32
    80002c42:	8082                	ret

0000000080002c44 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c44:	1101                	addi	sp,sp,-32
    80002c46:	ec06                	sd	ra,24(sp)
    80002c48:	e822                	sd	s0,16(sp)
    80002c4a:	e426                	sd	s1,8(sp)
    80002c4c:	1000                	addi	s0,sp,32
    80002c4e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	ece080e7          	jalr	-306(ra) # 80002b1e <argraw>
    80002c58:	e088                	sd	a0,0(s1)
}
    80002c5a:	60e2                	ld	ra,24(sp)
    80002c5c:	6442                	ld	s0,16(sp)
    80002c5e:	64a2                	ld	s1,8(sp)
    80002c60:	6105                	addi	sp,sp,32
    80002c62:	8082                	ret

0000000080002c64 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c64:	1101                	addi	sp,sp,-32
    80002c66:	ec06                	sd	ra,24(sp)
    80002c68:	e822                	sd	s0,16(sp)
    80002c6a:	e426                	sd	s1,8(sp)
    80002c6c:	e04a                	sd	s2,0(sp)
    80002c6e:	1000                	addi	s0,sp,32
    80002c70:	84ae                	mv	s1,a1
    80002c72:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	eaa080e7          	jalr	-342(ra) # 80002b1e <argraw>
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
    80002c7c:	864a                	mv	a2,s2
    80002c7e:	85a6                	mv	a1,s1
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	f58080e7          	jalr	-168(ra) # 80002bd8 <fetchstr>
}
    80002c88:	60e2                	ld	ra,24(sp)
    80002c8a:	6442                	ld	s0,16(sp)
    80002c8c:	64a2                	ld	s1,8(sp)
    80002c8e:	6902                	ld	s2,0(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <syscall>:
[SYS_sysinfo]  sys_sysinfo,
};

void
syscall(void)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	e426                	sd	s1,8(sp)
    80002c9c:	e04a                	sd	s2,0(sp)
    80002c9e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	e10080e7          	jalr	-496(ra) # 80001ab0 <myproc>
    80002ca8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002caa:	05853903          	ld	s2,88(a0)
    80002cae:	0a893783          	ld	a5,168(s2)
    80002cb2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cb6:	37fd                	addiw	a5,a5,-1
    80002cb8:	4759                	li	a4,22
    80002cba:	02f76663          	bltu	a4,a5,80002ce6 <syscall+0x52>
    80002cbe:	00369713          	slli	a4,a3,0x3
    80002cc2:	00006797          	auipc	a5,0x6
    80002cc6:	ae678793          	addi	a5,a5,-1306 # 800087a8 <syscalls>
    80002cca:	97ba                	add	a5,a5,a4
    80002ccc:	6398                	ld	a4,0(a5)
    80002cce:	cf01                	beqz	a4,80002ce6 <syscall+0x52>
    total_syscalls++;
    80002cd0:	00006697          	auipc	a3,0x6
    80002cd4:	c2468693          	addi	a3,a3,-988 # 800088f4 <total_syscalls>
    80002cd8:	429c                	lw	a5,0(a3)
    80002cda:	2785                	addiw	a5,a5,1
    80002cdc:	c29c                	sw	a5,0(a3)
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002cde:	9702                	jalr	a4
    80002ce0:	06a93823          	sd	a0,112(s2)
    80002ce4:	a839                	j	80002d02 <syscall+0x6e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ce6:	15848613          	addi	a2,s1,344
    80002cea:	588c                	lw	a1,48(s1)
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	6fc50513          	addi	a0,a0,1788 # 800083e8 <etext+0x3e8>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	8b6080e7          	jalr	-1866(ra) # 800005aa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cfc:	6cbc                	ld	a5,88(s1)
    80002cfe:	577d                	li	a4,-1
    80002d00:	fbb8                	sd	a4,112(a5)
  }
}
    80002d02:	60e2                	ld	ra,24(sp)
    80002d04:	6442                	ld	s0,16(sp)
    80002d06:	64a2                	ld	s1,8(sp)
    80002d08:	6902                	ld	s2,0(sp)
    80002d0a:	6105                	addi	sp,sp,32
    80002d0c:	8082                	ret

0000000080002d0e <get_total_syscalls>:
uint
get_total_syscalls(void)
{
    80002d0e:	1141                	addi	sp,sp,-16
    80002d10:	e406                	sd	ra,8(sp)
    80002d12:	e022                	sd	s0,0(sp)
    80002d14:	0800                	addi	s0,sp,16
  return total_syscalls;
}
    80002d16:	00006517          	auipc	a0,0x6
    80002d1a:	bde52503          	lw	a0,-1058(a0) # 800088f4 <total_syscalls>
    80002d1e:	60a2                	ld	ra,8(sp)
    80002d20:	6402                	ld	s0,0(sp)
    80002d22:	0141                	addi	sp,sp,16
    80002d24:	8082                	ret

0000000080002d26 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d26:	1101                	addi	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d2e:	fec40593          	addi	a1,s0,-20
    80002d32:	4501                	li	a0,0
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	ef0080e7          	jalr	-272(ra) # 80002c24 <argint>
  exit(n);
    80002d3c:	fec42503          	lw	a0,-20(s0)
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	54e080e7          	jalr	1358(ra) # 8000228e <exit>
  return 0;  // not reached
}
    80002d48:	4501                	li	a0,0
    80002d4a:	60e2                	ld	ra,24(sp)
    80002d4c:	6442                	ld	s0,16(sp)
    80002d4e:	6105                	addi	sp,sp,32
    80002d50:	8082                	ret

0000000080002d52 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d52:	1141                	addi	sp,sp,-16
    80002d54:	e406                	sd	ra,8(sp)
    80002d56:	e022                	sd	s0,0(sp)
    80002d58:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	d56080e7          	jalr	-682(ra) # 80001ab0 <myproc>
}
    80002d62:	5908                	lw	a0,48(a0)
    80002d64:	60a2                	ld	ra,8(sp)
    80002d66:	6402                	ld	s0,0(sp)
    80002d68:	0141                	addi	sp,sp,16
    80002d6a:	8082                	ret

0000000080002d6c <sys_fork>:

uint64
sys_fork(void)
{
    80002d6c:	1141                	addi	sp,sp,-16
    80002d6e:	e406                	sd	ra,8(sp)
    80002d70:	e022                	sd	s0,0(sp)
    80002d72:	0800                	addi	s0,sp,16
  return fork();
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	0f2080e7          	jalr	242(ra) # 80001e66 <fork>
}
    80002d7c:	60a2                	ld	ra,8(sp)
    80002d7e:	6402                	ld	s0,0(sp)
    80002d80:	0141                	addi	sp,sp,16
    80002d82:	8082                	ret

0000000080002d84 <sys_wait>:

uint64
sys_wait(void)
{
    80002d84:	1101                	addi	sp,sp,-32
    80002d86:	ec06                	sd	ra,24(sp)
    80002d88:	e822                	sd	s0,16(sp)
    80002d8a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d8c:	fe840593          	addi	a1,s0,-24
    80002d90:	4501                	li	a0,0
    80002d92:	00000097          	auipc	ra,0x0
    80002d96:	eb2080e7          	jalr	-334(ra) # 80002c44 <argaddr>
  return wait(p);
    80002d9a:	fe843503          	ld	a0,-24(s0)
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	696080e7          	jalr	1686(ra) # 80002434 <wait>
}
    80002da6:	60e2                	ld	ra,24(sp)
    80002da8:	6442                	ld	s0,16(sp)
    80002daa:	6105                	addi	sp,sp,32
    80002dac:	8082                	ret

0000000080002dae <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dae:	7179                	addi	sp,sp,-48
    80002db0:	f406                	sd	ra,40(sp)
    80002db2:	f022                	sd	s0,32(sp)
    80002db4:	ec26                	sd	s1,24(sp)
    80002db6:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002db8:	fdc40593          	addi	a1,s0,-36
    80002dbc:	4501                	li	a0,0
    80002dbe:	00000097          	auipc	ra,0x0
    80002dc2:	e66080e7          	jalr	-410(ra) # 80002c24 <argint>
  addr = myproc()->sz;
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	cea080e7          	jalr	-790(ra) # 80001ab0 <myproc>
    80002dce:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002dd0:	fdc42503          	lw	a0,-36(s0)
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	036080e7          	jalr	54(ra) # 80001e0a <growproc>
    80002ddc:	00054863          	bltz	a0,80002dec <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002de0:	8526                	mv	a0,s1
    80002de2:	70a2                	ld	ra,40(sp)
    80002de4:	7402                	ld	s0,32(sp)
    80002de6:	64e2                	ld	s1,24(sp)
    80002de8:	6145                	addi	sp,sp,48
    80002dea:	8082                	ret
    return -1;
    80002dec:	54fd                	li	s1,-1
    80002dee:	bfcd                	j	80002de0 <sys_sbrk+0x32>

0000000080002df0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002df0:	7139                	addi	sp,sp,-64
    80002df2:	fc06                	sd	ra,56(sp)
    80002df4:	f822                	sd	s0,48(sp)
    80002df6:	f04a                	sd	s2,32(sp)
    80002df8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002dfa:	fcc40593          	addi	a1,s0,-52
    80002dfe:	4501                	li	a0,0
    80002e00:	00000097          	auipc	ra,0x0
    80002e04:	e24080e7          	jalr	-476(ra) # 80002c24 <argint>
  acquire(&tickslock);
    80002e08:	00014517          	auipc	a0,0x14
    80002e0c:	b8850513          	addi	a0,a0,-1144 # 80016990 <tickslock>
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	e76080e7          	jalr	-394(ra) # 80000c86 <acquire>
  ticks0 = ticks;
    80002e18:	00006917          	auipc	s2,0x6
    80002e1c:	ad892903          	lw	s2,-1320(s2) # 800088f0 <ticks>
  while(ticks - ticks0 < n){
    80002e20:	fcc42783          	lw	a5,-52(s0)
    80002e24:	c3b9                	beqz	a5,80002e6a <sys_sleep+0x7a>
    80002e26:	f426                	sd	s1,40(sp)
    80002e28:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e2a:	00014997          	auipc	s3,0x14
    80002e2e:	b6698993          	addi	s3,s3,-1178 # 80016990 <tickslock>
    80002e32:	00006497          	auipc	s1,0x6
    80002e36:	abe48493          	addi	s1,s1,-1346 # 800088f0 <ticks>
    if(killed(myproc())){
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	c76080e7          	jalr	-906(ra) # 80001ab0 <myproc>
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	5c0080e7          	jalr	1472(ra) # 80002402 <killed>
    80002e4a:	ed15                	bnez	a0,80002e86 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e4c:	85ce                	mv	a1,s3
    80002e4e:	8526                	mv	a0,s1
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	30a080e7          	jalr	778(ra) # 8000215a <sleep>
  while(ticks - ticks0 < n){
    80002e58:	409c                	lw	a5,0(s1)
    80002e5a:	412787bb          	subw	a5,a5,s2
    80002e5e:	fcc42703          	lw	a4,-52(s0)
    80002e62:	fce7ece3          	bltu	a5,a4,80002e3a <sys_sleep+0x4a>
    80002e66:	74a2                	ld	s1,40(sp)
    80002e68:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002e6a:	00014517          	auipc	a0,0x14
    80002e6e:	b2650513          	addi	a0,a0,-1242 # 80016990 <tickslock>
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	ec4080e7          	jalr	-316(ra) # 80000d36 <release>
  return 0;
    80002e7a:	4501                	li	a0,0
}
    80002e7c:	70e2                	ld	ra,56(sp)
    80002e7e:	7442                	ld	s0,48(sp)
    80002e80:	7902                	ld	s2,32(sp)
    80002e82:	6121                	addi	sp,sp,64
    80002e84:	8082                	ret
      release(&tickslock);
    80002e86:	00014517          	auipc	a0,0x14
    80002e8a:	b0a50513          	addi	a0,a0,-1270 # 80016990 <tickslock>
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	ea8080e7          	jalr	-344(ra) # 80000d36 <release>
      return -1;
    80002e96:	557d                	li	a0,-1
    80002e98:	74a2                	ld	s1,40(sp)
    80002e9a:	69e2                	ld	s3,24(sp)
    80002e9c:	b7c5                	j	80002e7c <sys_sleep+0x8c>

0000000080002e9e <sys_kill>:

uint64
sys_kill(void)
{
    80002e9e:	1101                	addi	sp,sp,-32
    80002ea0:	ec06                	sd	ra,24(sp)
    80002ea2:	e822                	sd	s0,16(sp)
    80002ea4:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ea6:	fec40593          	addi	a1,s0,-20
    80002eaa:	4501                	li	a0,0
    80002eac:	00000097          	auipc	ra,0x0
    80002eb0:	d78080e7          	jalr	-648(ra) # 80002c24 <argint>
  return kill(pid);
    80002eb4:	fec42503          	lw	a0,-20(s0)
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	4ac080e7          	jalr	1196(ra) # 80002364 <kill>
}
    80002ec0:	60e2                	ld	ra,24(sp)
    80002ec2:	6442                	ld	s0,16(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret

0000000080002ec8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	e426                	sd	s1,8(sp)
    80002ed0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ed2:	00014517          	auipc	a0,0x14
    80002ed6:	abe50513          	addi	a0,a0,-1346 # 80016990 <tickslock>
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	dac080e7          	jalr	-596(ra) # 80000c86 <acquire>
  xticks = ticks;
    80002ee2:	00006497          	auipc	s1,0x6
    80002ee6:	a0e4a483          	lw	s1,-1522(s1) # 800088f0 <ticks>
  release(&tickslock);
    80002eea:	00014517          	auipc	a0,0x14
    80002eee:	aa650513          	addi	a0,a0,-1370 # 80016990 <tickslock>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	e44080e7          	jalr	-444(ra) # 80000d36 <release>
  return xticks;
}
    80002efa:	02049513          	slli	a0,s1,0x20
    80002efe:	9101                	srli	a0,a0,0x20
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret

0000000080002f0a <sys_hello>:
uint64 sys_hello(void)
{
    80002f0a:	1101                	addi	sp,sp,-32
    80002f0c:	ec06                	sd	ra,24(sp)
    80002f0e:	e822                	sd	s0,16(sp)
    80002f10:	1000                	addi	s0,sp,32
  int n;
  argint(0,&n);
    80002f12:	fec40593          	addi	a1,s0,-20
    80002f16:	4501                	li	a0,0
    80002f18:	00000097          	auipc	ra,0x0
    80002f1c:	d0c080e7          	jalr	-756(ra) # 80002c24 <argint>
  print_hello(n);
    80002f20:	fec42503          	lw	a0,-20(s0)
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	794080e7          	jalr	1940(ra) # 800026b8 <print_hello>
  return 0;
}
    80002f2c:	4501                	li	a0,0
    80002f2e:	60e2                	ld	ra,24(sp)
    80002f30:	6442                	ld	s0,16(sp)
    80002f32:	6105                	addi	sp,sp,32
    80002f34:	8082                	ret

0000000080002f36 <sys_sysinfo>:

uint64
sys_sysinfo(void)
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	1000                	addi	s0,sp,32
  int param;
  
  // Fix argint usage - in xv6, argint doesn't return a value to check
  argint(0, &param);
    80002f3e:	fec40593          	addi	a1,s0,-20
    80002f42:	4501                	li	a0,0
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	ce0080e7          	jalr	-800(ra) # 80002c24 <argint>
  
  switch(param) {
    80002f4c:	fec42783          	lw	a5,-20(s0)
    80002f50:	4705                	li	a4,1
    80002f52:	00e78f63          	beq	a5,a4,80002f70 <sys_sysinfo+0x3a>
    80002f56:	4709                	li	a4,2
    80002f58:	02e78463          	beq	a5,a4,80002f80 <sys_sysinfo+0x4a>
    80002f5c:	557d                	li	a0,-1
    80002f5e:	e789                	bnez	a5,80002f68 <sys_sysinfo+0x32>
    case 0:
      // Return number of active processes
      return count_active_procs();
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	77a080e7          	jalr	1914(ra) # 800026da <count_active_procs>
      // Return number of free memory pages
      return count_free_pages();
    default:
      return -1;
  }
}
    80002f68:	60e2                	ld	ra,24(sp)
    80002f6a:	6442                	ld	s0,16(sp)
    80002f6c:	6105                	addi	sp,sp,32
    80002f6e:	8082                	ret
      return get_total_syscalls() - 1;
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	d9e080e7          	jalr	-610(ra) # 80002d0e <get_total_syscalls>
    80002f78:	357d                	addiw	a0,a0,-1
    80002f7a:	1502                	slli	a0,a0,0x20
    80002f7c:	9101                	srli	a0,a0,0x20
    80002f7e:	b7ed                	j	80002f68 <sys_sysinfo+0x32>
      return count_free_pages();
    80002f80:	ffffe097          	auipc	ra,0xffffe
    80002f84:	c2a080e7          	jalr	-982(ra) # 80000baa <count_free_pages>
    80002f88:	b7c5                	j	80002f68 <sys_sysinfo+0x32>

0000000080002f8a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f8a:	7179                	addi	sp,sp,-48
    80002f8c:	f406                	sd	ra,40(sp)
    80002f8e:	f022                	sd	s0,32(sp)
    80002f90:	ec26                	sd	s1,24(sp)
    80002f92:	e84a                	sd	s2,16(sp)
    80002f94:	e44e                	sd	s3,8(sp)
    80002f96:	e052                	sd	s4,0(sp)
    80002f98:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f9a:	00005597          	auipc	a1,0x5
    80002f9e:	46e58593          	addi	a1,a1,1134 # 80008408 <etext+0x408>
    80002fa2:	00014517          	auipc	a0,0x14
    80002fa6:	a0650513          	addi	a0,a0,-1530 # 800169a8 <bcache>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	c48080e7          	jalr	-952(ra) # 80000bf2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fb2:	0001c797          	auipc	a5,0x1c
    80002fb6:	9f678793          	addi	a5,a5,-1546 # 8001e9a8 <bcache+0x8000>
    80002fba:	0001c717          	auipc	a4,0x1c
    80002fbe:	c5670713          	addi	a4,a4,-938 # 8001ec10 <bcache+0x8268>
    80002fc2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fc6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fca:	00014497          	auipc	s1,0x14
    80002fce:	9f648493          	addi	s1,s1,-1546 # 800169c0 <bcache+0x18>
    b->next = bcache.head.next;
    80002fd2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fd4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fd6:	00005a17          	auipc	s4,0x5
    80002fda:	43aa0a13          	addi	s4,s4,1082 # 80008410 <etext+0x410>
    b->next = bcache.head.next;
    80002fde:	2b893783          	ld	a5,696(s2)
    80002fe2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fe4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fe8:	85d2                	mv	a1,s4
    80002fea:	01048513          	addi	a0,s1,16
    80002fee:	00001097          	auipc	ra,0x1
    80002ff2:	4e4080e7          	jalr	1252(ra) # 800044d2 <initsleeplock>
    bcache.head.next->prev = b;
    80002ff6:	2b893783          	ld	a5,696(s2)
    80002ffa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ffc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003000:	45848493          	addi	s1,s1,1112
    80003004:	fd349de3          	bne	s1,s3,80002fde <binit+0x54>
  }
}
    80003008:	70a2                	ld	ra,40(sp)
    8000300a:	7402                	ld	s0,32(sp)
    8000300c:	64e2                	ld	s1,24(sp)
    8000300e:	6942                	ld	s2,16(sp)
    80003010:	69a2                	ld	s3,8(sp)
    80003012:	6a02                	ld	s4,0(sp)
    80003014:	6145                	addi	sp,sp,48
    80003016:	8082                	ret

0000000080003018 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003018:	7179                	addi	sp,sp,-48
    8000301a:	f406                	sd	ra,40(sp)
    8000301c:	f022                	sd	s0,32(sp)
    8000301e:	ec26                	sd	s1,24(sp)
    80003020:	e84a                	sd	s2,16(sp)
    80003022:	e44e                	sd	s3,8(sp)
    80003024:	1800                	addi	s0,sp,48
    80003026:	892a                	mv	s2,a0
    80003028:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000302a:	00014517          	auipc	a0,0x14
    8000302e:	97e50513          	addi	a0,a0,-1666 # 800169a8 <bcache>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c54080e7          	jalr	-940(ra) # 80000c86 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000303a:	0001c497          	auipc	s1,0x1c
    8000303e:	c264b483          	ld	s1,-986(s1) # 8001ec60 <bcache+0x82b8>
    80003042:	0001c797          	auipc	a5,0x1c
    80003046:	bce78793          	addi	a5,a5,-1074 # 8001ec10 <bcache+0x8268>
    8000304a:	02f48f63          	beq	s1,a5,80003088 <bread+0x70>
    8000304e:	873e                	mv	a4,a5
    80003050:	a021                	j	80003058 <bread+0x40>
    80003052:	68a4                	ld	s1,80(s1)
    80003054:	02e48a63          	beq	s1,a4,80003088 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003058:	449c                	lw	a5,8(s1)
    8000305a:	ff279ce3          	bne	a5,s2,80003052 <bread+0x3a>
    8000305e:	44dc                	lw	a5,12(s1)
    80003060:	ff3799e3          	bne	a5,s3,80003052 <bread+0x3a>
      b->refcnt++;
    80003064:	40bc                	lw	a5,64(s1)
    80003066:	2785                	addiw	a5,a5,1
    80003068:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000306a:	00014517          	auipc	a0,0x14
    8000306e:	93e50513          	addi	a0,a0,-1730 # 800169a8 <bcache>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	cc4080e7          	jalr	-828(ra) # 80000d36 <release>
      acquiresleep(&b->lock);
    8000307a:	01048513          	addi	a0,s1,16
    8000307e:	00001097          	auipc	ra,0x1
    80003082:	48e080e7          	jalr	1166(ra) # 8000450c <acquiresleep>
      return b;
    80003086:	a8b9                	j	800030e4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003088:	0001c497          	auipc	s1,0x1c
    8000308c:	bd04b483          	ld	s1,-1072(s1) # 8001ec58 <bcache+0x82b0>
    80003090:	0001c797          	auipc	a5,0x1c
    80003094:	b8078793          	addi	a5,a5,-1152 # 8001ec10 <bcache+0x8268>
    80003098:	00f48863          	beq	s1,a5,800030a8 <bread+0x90>
    8000309c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000309e:	40bc                	lw	a5,64(s1)
    800030a0:	cf81                	beqz	a5,800030b8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030a2:	64a4                	ld	s1,72(s1)
    800030a4:	fee49de3          	bne	s1,a4,8000309e <bread+0x86>
  panic("bget: no buffers");
    800030a8:	00005517          	auipc	a0,0x5
    800030ac:	37050513          	addi	a0,a0,880 # 80008418 <etext+0x418>
    800030b0:	ffffd097          	auipc	ra,0xffffd
    800030b4:	4b0080e7          	jalr	1200(ra) # 80000560 <panic>
      b->dev = dev;
    800030b8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030bc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030c0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030c4:	4785                	li	a5,1
    800030c6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030c8:	00014517          	auipc	a0,0x14
    800030cc:	8e050513          	addi	a0,a0,-1824 # 800169a8 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	c66080e7          	jalr	-922(ra) # 80000d36 <release>
      acquiresleep(&b->lock);
    800030d8:	01048513          	addi	a0,s1,16
    800030dc:	00001097          	auipc	ra,0x1
    800030e0:	430080e7          	jalr	1072(ra) # 8000450c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030e4:	409c                	lw	a5,0(s1)
    800030e6:	cb89                	beqz	a5,800030f8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030e8:	8526                	mv	a0,s1
    800030ea:	70a2                	ld	ra,40(sp)
    800030ec:	7402                	ld	s0,32(sp)
    800030ee:	64e2                	ld	s1,24(sp)
    800030f0:	6942                	ld	s2,16(sp)
    800030f2:	69a2                	ld	s3,8(sp)
    800030f4:	6145                	addi	sp,sp,48
    800030f6:	8082                	ret
    virtio_disk_rw(b, 0);
    800030f8:	4581                	li	a1,0
    800030fa:	8526                	mv	a0,s1
    800030fc:	00003097          	auipc	ra,0x3
    80003100:	10c080e7          	jalr	268(ra) # 80006208 <virtio_disk_rw>
    b->valid = 1;
    80003104:	4785                	li	a5,1
    80003106:	c09c                	sw	a5,0(s1)
  return b;
    80003108:	b7c5                	j	800030e8 <bread+0xd0>

000000008000310a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000310a:	1101                	addi	sp,sp,-32
    8000310c:	ec06                	sd	ra,24(sp)
    8000310e:	e822                	sd	s0,16(sp)
    80003110:	e426                	sd	s1,8(sp)
    80003112:	1000                	addi	s0,sp,32
    80003114:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003116:	0541                	addi	a0,a0,16
    80003118:	00001097          	auipc	ra,0x1
    8000311c:	48e080e7          	jalr	1166(ra) # 800045a6 <holdingsleep>
    80003120:	cd01                	beqz	a0,80003138 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003122:	4585                	li	a1,1
    80003124:	8526                	mv	a0,s1
    80003126:	00003097          	auipc	ra,0x3
    8000312a:	0e2080e7          	jalr	226(ra) # 80006208 <virtio_disk_rw>
}
    8000312e:	60e2                	ld	ra,24(sp)
    80003130:	6442                	ld	s0,16(sp)
    80003132:	64a2                	ld	s1,8(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret
    panic("bwrite");
    80003138:	00005517          	auipc	a0,0x5
    8000313c:	2f850513          	addi	a0,a0,760 # 80008430 <etext+0x430>
    80003140:	ffffd097          	auipc	ra,0xffffd
    80003144:	420080e7          	jalr	1056(ra) # 80000560 <panic>

0000000080003148 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003148:	1101                	addi	sp,sp,-32
    8000314a:	ec06                	sd	ra,24(sp)
    8000314c:	e822                	sd	s0,16(sp)
    8000314e:	e426                	sd	s1,8(sp)
    80003150:	e04a                	sd	s2,0(sp)
    80003152:	1000                	addi	s0,sp,32
    80003154:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003156:	01050913          	addi	s2,a0,16
    8000315a:	854a                	mv	a0,s2
    8000315c:	00001097          	auipc	ra,0x1
    80003160:	44a080e7          	jalr	1098(ra) # 800045a6 <holdingsleep>
    80003164:	c535                	beqz	a0,800031d0 <brelse+0x88>
    panic("brelse");

  releasesleep(&b->lock);
    80003166:	854a                	mv	a0,s2
    80003168:	00001097          	auipc	ra,0x1
    8000316c:	3fa080e7          	jalr	1018(ra) # 80004562 <releasesleep>

  acquire(&bcache.lock);
    80003170:	00014517          	auipc	a0,0x14
    80003174:	83850513          	addi	a0,a0,-1992 # 800169a8 <bcache>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	b0e080e7          	jalr	-1266(ra) # 80000c86 <acquire>
  b->refcnt--;
    80003180:	40bc                	lw	a5,64(s1)
    80003182:	37fd                	addiw	a5,a5,-1
    80003184:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003186:	e79d                	bnez	a5,800031b4 <brelse+0x6c>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003188:	68b8                	ld	a4,80(s1)
    8000318a:	64bc                	ld	a5,72(s1)
    8000318c:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000318e:	68b8                	ld	a4,80(s1)
    80003190:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003192:	0001c797          	auipc	a5,0x1c
    80003196:	81678793          	addi	a5,a5,-2026 # 8001e9a8 <bcache+0x8000>
    8000319a:	2b87b703          	ld	a4,696(a5)
    8000319e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031a0:	0001c717          	auipc	a4,0x1c
    800031a4:	a7070713          	addi	a4,a4,-1424 # 8001ec10 <bcache+0x8268>
    800031a8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031aa:	2b87b703          	ld	a4,696(a5)
    800031ae:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031b0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031b4:	00013517          	auipc	a0,0x13
    800031b8:	7f450513          	addi	a0,a0,2036 # 800169a8 <bcache>
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	b7a080e7          	jalr	-1158(ra) # 80000d36 <release>
}
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	64a2                	ld	s1,8(sp)
    800031ca:	6902                	ld	s2,0(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret
    panic("brelse");
    800031d0:	00005517          	auipc	a0,0x5
    800031d4:	26850513          	addi	a0,a0,616 # 80008438 <etext+0x438>
    800031d8:	ffffd097          	auipc	ra,0xffffd
    800031dc:	388080e7          	jalr	904(ra) # 80000560 <panic>

00000000800031e0 <bpin>:

void
bpin(struct buf *b) {
    800031e0:	1101                	addi	sp,sp,-32
    800031e2:	ec06                	sd	ra,24(sp)
    800031e4:	e822                	sd	s0,16(sp)
    800031e6:	e426                	sd	s1,8(sp)
    800031e8:	1000                	addi	s0,sp,32
    800031ea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ec:	00013517          	auipc	a0,0x13
    800031f0:	7bc50513          	addi	a0,a0,1980 # 800169a8 <bcache>
    800031f4:	ffffe097          	auipc	ra,0xffffe
    800031f8:	a92080e7          	jalr	-1390(ra) # 80000c86 <acquire>
  b->refcnt++;
    800031fc:	40bc                	lw	a5,64(s1)
    800031fe:	2785                	addiw	a5,a5,1
    80003200:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003202:	00013517          	auipc	a0,0x13
    80003206:	7a650513          	addi	a0,a0,1958 # 800169a8 <bcache>
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	b2c080e7          	jalr	-1236(ra) # 80000d36 <release>
}
    80003212:	60e2                	ld	ra,24(sp)
    80003214:	6442                	ld	s0,16(sp)
    80003216:	64a2                	ld	s1,8(sp)
    80003218:	6105                	addi	sp,sp,32
    8000321a:	8082                	ret

000000008000321c <bunpin>:

void
bunpin(struct buf *b) {
    8000321c:	1101                	addi	sp,sp,-32
    8000321e:	ec06                	sd	ra,24(sp)
    80003220:	e822                	sd	s0,16(sp)
    80003222:	e426                	sd	s1,8(sp)
    80003224:	1000                	addi	s0,sp,32
    80003226:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003228:	00013517          	auipc	a0,0x13
    8000322c:	78050513          	addi	a0,a0,1920 # 800169a8 <bcache>
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	a56080e7          	jalr	-1450(ra) # 80000c86 <acquire>
  b->refcnt--;
    80003238:	40bc                	lw	a5,64(s1)
    8000323a:	37fd                	addiw	a5,a5,-1
    8000323c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000323e:	00013517          	auipc	a0,0x13
    80003242:	76a50513          	addi	a0,a0,1898 # 800169a8 <bcache>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	af0080e7          	jalr	-1296(ra) # 80000d36 <release>
}
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	64a2                	ld	s1,8(sp)
    80003254:	6105                	addi	sp,sp,32
    80003256:	8082                	ret

0000000080003258 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003258:	1101                	addi	sp,sp,-32
    8000325a:	ec06                	sd	ra,24(sp)
    8000325c:	e822                	sd	s0,16(sp)
    8000325e:	e426                	sd	s1,8(sp)
    80003260:	e04a                	sd	s2,0(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003266:	00d5d79b          	srliw	a5,a1,0xd
    8000326a:	0001c597          	auipc	a1,0x1c
    8000326e:	e1a5a583          	lw	a1,-486(a1) # 8001f084 <sb+0x1c>
    80003272:	9dbd                	addw	a1,a1,a5
    80003274:	00000097          	auipc	ra,0x0
    80003278:	da4080e7          	jalr	-604(ra) # 80003018 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000327c:	0074f713          	andi	a4,s1,7
    80003280:	4785                	li	a5,1
    80003282:	00e797bb          	sllw	a5,a5,a4
  bi = b % BPB;
    80003286:	14ce                	slli	s1,s1,0x33
  if((bp->data[bi/8] & m) == 0)
    80003288:	90d9                	srli	s1,s1,0x36
    8000328a:	00950733          	add	a4,a0,s1
    8000328e:	05874703          	lbu	a4,88(a4)
    80003292:	00e7f6b3          	and	a3,a5,a4
    80003296:	c69d                	beqz	a3,800032c4 <bfree+0x6c>
    80003298:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000329a:	94aa                	add	s1,s1,a0
    8000329c:	fff7c793          	not	a5,a5
    800032a0:	8f7d                	and	a4,a4,a5
    800032a2:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800032a6:	00001097          	auipc	ra,0x1
    800032aa:	148080e7          	jalr	328(ra) # 800043ee <log_write>
  brelse(bp);
    800032ae:	854a                	mv	a0,s2
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	e98080e7          	jalr	-360(ra) # 80003148 <brelse>
}
    800032b8:	60e2                	ld	ra,24(sp)
    800032ba:	6442                	ld	s0,16(sp)
    800032bc:	64a2                	ld	s1,8(sp)
    800032be:	6902                	ld	s2,0(sp)
    800032c0:	6105                	addi	sp,sp,32
    800032c2:	8082                	ret
    panic("freeing free block");
    800032c4:	00005517          	auipc	a0,0x5
    800032c8:	17c50513          	addi	a0,a0,380 # 80008440 <etext+0x440>
    800032cc:	ffffd097          	auipc	ra,0xffffd
    800032d0:	294080e7          	jalr	660(ra) # 80000560 <panic>

00000000800032d4 <balloc>:
{
    800032d4:	715d                	addi	sp,sp,-80
    800032d6:	e486                	sd	ra,72(sp)
    800032d8:	e0a2                	sd	s0,64(sp)
    800032da:	fc26                	sd	s1,56(sp)
    800032dc:	0880                	addi	s0,sp,80
  for(b = 0; b < sb.size; b += BPB){
    800032de:	0001c797          	auipc	a5,0x1c
    800032e2:	d8e7a783          	lw	a5,-626(a5) # 8001f06c <sb+0x4>
    800032e6:	10078863          	beqz	a5,800033f6 <balloc+0x122>
    800032ea:	f84a                	sd	s2,48(sp)
    800032ec:	f44e                	sd	s3,40(sp)
    800032ee:	f052                	sd	s4,32(sp)
    800032f0:	ec56                	sd	s5,24(sp)
    800032f2:	e85a                	sd	s6,16(sp)
    800032f4:	e45e                	sd	s7,8(sp)
    800032f6:	e062                	sd	s8,0(sp)
    800032f8:	8baa                	mv	s7,a0
    800032fa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032fc:	0001cb17          	auipc	s6,0x1c
    80003300:	d6cb0b13          	addi	s6,s6,-660 # 8001f068 <sb>
      m = 1 << (bi % 8);
    80003304:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003306:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003308:	6c09                	lui	s8,0x2
    8000330a:	a049                	j	8000338c <balloc+0xb8>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000330c:	97ca                	add	a5,a5,s2
    8000330e:	8e55                	or	a2,a2,a3
    80003310:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003314:	854a                	mv	a0,s2
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	0d8080e7          	jalr	216(ra) # 800043ee <log_write>
        brelse(bp);
    8000331e:	854a                	mv	a0,s2
    80003320:	00000097          	auipc	ra,0x0
    80003324:	e28080e7          	jalr	-472(ra) # 80003148 <brelse>
  bp = bread(dev, bno);
    80003328:	85a6                	mv	a1,s1
    8000332a:	855e                	mv	a0,s7
    8000332c:	00000097          	auipc	ra,0x0
    80003330:	cec080e7          	jalr	-788(ra) # 80003018 <bread>
    80003334:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003336:	40000613          	li	a2,1024
    8000333a:	4581                	li	a1,0
    8000333c:	05850513          	addi	a0,a0,88
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	a3e080e7          	jalr	-1474(ra) # 80000d7e <memset>
  log_write(bp);
    80003348:	854a                	mv	a0,s2
    8000334a:	00001097          	auipc	ra,0x1
    8000334e:	0a4080e7          	jalr	164(ra) # 800043ee <log_write>
  brelse(bp);
    80003352:	854a                	mv	a0,s2
    80003354:	00000097          	auipc	ra,0x0
    80003358:	df4080e7          	jalr	-524(ra) # 80003148 <brelse>
}
    8000335c:	7942                	ld	s2,48(sp)
    8000335e:	79a2                	ld	s3,40(sp)
    80003360:	7a02                	ld	s4,32(sp)
    80003362:	6ae2                	ld	s5,24(sp)
    80003364:	6b42                	ld	s6,16(sp)
    80003366:	6ba2                	ld	s7,8(sp)
    80003368:	6c02                	ld	s8,0(sp)
}
    8000336a:	8526                	mv	a0,s1
    8000336c:	60a6                	ld	ra,72(sp)
    8000336e:	6406                	ld	s0,64(sp)
    80003370:	74e2                	ld	s1,56(sp)
    80003372:	6161                	addi	sp,sp,80
    80003374:	8082                	ret
    brelse(bp);
    80003376:	854a                	mv	a0,s2
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	dd0080e7          	jalr	-560(ra) # 80003148 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003380:	015c0abb          	addw	s5,s8,s5
    80003384:	004b2783          	lw	a5,4(s6)
    80003388:	06faf063          	bgeu	s5,a5,800033e8 <balloc+0x114>
    bp = bread(dev, BBLOCK(b, sb));
    8000338c:	41fad79b          	sraiw	a5,s5,0x1f
    80003390:	0137d79b          	srliw	a5,a5,0x13
    80003394:	015787bb          	addw	a5,a5,s5
    80003398:	40d7d79b          	sraiw	a5,a5,0xd
    8000339c:	01cb2583          	lw	a1,28(s6)
    800033a0:	9dbd                	addw	a1,a1,a5
    800033a2:	855e                	mv	a0,s7
    800033a4:	00000097          	auipc	ra,0x0
    800033a8:	c74080e7          	jalr	-908(ra) # 80003018 <bread>
    800033ac:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ae:	004b2503          	lw	a0,4(s6)
    800033b2:	84d6                	mv	s1,s5
    800033b4:	4701                	li	a4,0
    800033b6:	fca4f0e3          	bgeu	s1,a0,80003376 <balloc+0xa2>
      m = 1 << (bi % 8);
    800033ba:	00777693          	andi	a3,a4,7
    800033be:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033c2:	41f7579b          	sraiw	a5,a4,0x1f
    800033c6:	01d7d79b          	srliw	a5,a5,0x1d
    800033ca:	9fb9                	addw	a5,a5,a4
    800033cc:	4037d79b          	sraiw	a5,a5,0x3
    800033d0:	00f90633          	add	a2,s2,a5
    800033d4:	05864603          	lbu	a2,88(a2)
    800033d8:	00c6f5b3          	and	a1,a3,a2
    800033dc:	d985                	beqz	a1,8000330c <balloc+0x38>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033de:	2705                	addiw	a4,a4,1
    800033e0:	2485                	addiw	s1,s1,1
    800033e2:	fd471ae3          	bne	a4,s4,800033b6 <balloc+0xe2>
    800033e6:	bf41                	j	80003376 <balloc+0xa2>
    800033e8:	7942                	ld	s2,48(sp)
    800033ea:	79a2                	ld	s3,40(sp)
    800033ec:	7a02                	ld	s4,32(sp)
    800033ee:	6ae2                	ld	s5,24(sp)
    800033f0:	6b42                	ld	s6,16(sp)
    800033f2:	6ba2                	ld	s7,8(sp)
    800033f4:	6c02                	ld	s8,0(sp)
  printf("balloc: out of blocks\n");
    800033f6:	00005517          	auipc	a0,0x5
    800033fa:	06250513          	addi	a0,a0,98 # 80008458 <etext+0x458>
    800033fe:	ffffd097          	auipc	ra,0xffffd
    80003402:	1ac080e7          	jalr	428(ra) # 800005aa <printf>
  return 0;
    80003406:	4481                	li	s1,0
    80003408:	b78d                	j	8000336a <balloc+0x96>

000000008000340a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000340a:	7179                	addi	sp,sp,-48
    8000340c:	f406                	sd	ra,40(sp)
    8000340e:	f022                	sd	s0,32(sp)
    80003410:	ec26                	sd	s1,24(sp)
    80003412:	e84a                	sd	s2,16(sp)
    80003414:	e44e                	sd	s3,8(sp)
    80003416:	1800                	addi	s0,sp,48
    80003418:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000341a:	47ad                	li	a5,11
    8000341c:	02b7e563          	bltu	a5,a1,80003446 <bmap+0x3c>
    if((addr = ip->addrs[bn]) == 0){
    80003420:	02059793          	slli	a5,a1,0x20
    80003424:	01e7d593          	srli	a1,a5,0x1e
    80003428:	00b504b3          	add	s1,a0,a1
    8000342c:	0504a903          	lw	s2,80(s1)
    80003430:	06091b63          	bnez	s2,800034a6 <bmap+0x9c>
      addr = balloc(ip->dev);
    80003434:	4108                	lw	a0,0(a0)
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	e9e080e7          	jalr	-354(ra) # 800032d4 <balloc>
    8000343e:	892a                	mv	s2,a0
      if(addr == 0)
    80003440:	c13d                	beqz	a0,800034a6 <bmap+0x9c>
        return 0;
      ip->addrs[bn] = addr;
    80003442:	c8a8                	sw	a0,80(s1)
    80003444:	a08d                	j	800034a6 <bmap+0x9c>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003446:	ff45849b          	addiw	s1,a1,-12

  if(bn < NINDIRECT){
    8000344a:	0ff00793          	li	a5,255
    8000344e:	0897e363          	bltu	a5,s1,800034d4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003452:	08052903          	lw	s2,128(a0)
    80003456:	00091d63          	bnez	s2,80003470 <bmap+0x66>
      addr = balloc(ip->dev);
    8000345a:	4108                	lw	a0,0(a0)
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	e78080e7          	jalr	-392(ra) # 800032d4 <balloc>
    80003464:	892a                	mv	s2,a0
      if(addr == 0)
    80003466:	c121                	beqz	a0,800034a6 <bmap+0x9c>
    80003468:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000346a:	08a9a023          	sw	a0,128(s3)
    8000346e:	a011                	j	80003472 <bmap+0x68>
    80003470:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80003472:	85ca                	mv	a1,s2
    80003474:	0009a503          	lw	a0,0(s3)
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	ba0080e7          	jalr	-1120(ra) # 80003018 <bread>
    80003480:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003482:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003486:	02049713          	slli	a4,s1,0x20
    8000348a:	01e75593          	srli	a1,a4,0x1e
    8000348e:	00b784b3          	add	s1,a5,a1
    80003492:	0004a903          	lw	s2,0(s1)
    80003496:	02090063          	beqz	s2,800034b6 <bmap+0xac>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000349a:	8552                	mv	a0,s4
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	cac080e7          	jalr	-852(ra) # 80003148 <brelse>
    return addr;
    800034a4:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    800034a6:	854a                	mv	a0,s2
    800034a8:	70a2                	ld	ra,40(sp)
    800034aa:	7402                	ld	s0,32(sp)
    800034ac:	64e2                	ld	s1,24(sp)
    800034ae:	6942                	ld	s2,16(sp)
    800034b0:	69a2                	ld	s3,8(sp)
    800034b2:	6145                	addi	sp,sp,48
    800034b4:	8082                	ret
      addr = balloc(ip->dev);
    800034b6:	0009a503          	lw	a0,0(s3)
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	e1a080e7          	jalr	-486(ra) # 800032d4 <balloc>
    800034c2:	892a                	mv	s2,a0
      if(addr){
    800034c4:	d979                	beqz	a0,8000349a <bmap+0x90>
        a[bn] = addr;
    800034c6:	c088                	sw	a0,0(s1)
        log_write(bp);
    800034c8:	8552                	mv	a0,s4
    800034ca:	00001097          	auipc	ra,0x1
    800034ce:	f24080e7          	jalr	-220(ra) # 800043ee <log_write>
    800034d2:	b7e1                	j	8000349a <bmap+0x90>
    800034d4:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    800034d6:	00005517          	auipc	a0,0x5
    800034da:	f9a50513          	addi	a0,a0,-102 # 80008470 <etext+0x470>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	082080e7          	jalr	130(ra) # 80000560 <panic>

00000000800034e6 <iget>:
{
    800034e6:	7179                	addi	sp,sp,-48
    800034e8:	f406                	sd	ra,40(sp)
    800034ea:	f022                	sd	s0,32(sp)
    800034ec:	ec26                	sd	s1,24(sp)
    800034ee:	e84a                	sd	s2,16(sp)
    800034f0:	e44e                	sd	s3,8(sp)
    800034f2:	e052                	sd	s4,0(sp)
    800034f4:	1800                	addi	s0,sp,48
    800034f6:	89aa                	mv	s3,a0
    800034f8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034fa:	0001c517          	auipc	a0,0x1c
    800034fe:	b8e50513          	addi	a0,a0,-1138 # 8001f088 <itable>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	784080e7          	jalr	1924(ra) # 80000c86 <acquire>
  empty = 0;
    8000350a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000350c:	0001c497          	auipc	s1,0x1c
    80003510:	b9448493          	addi	s1,s1,-1132 # 8001f0a0 <itable+0x18>
    80003514:	0001d697          	auipc	a3,0x1d
    80003518:	61c68693          	addi	a3,a3,1564 # 80020b30 <log>
    8000351c:	a039                	j	8000352a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000351e:	02090b63          	beqz	s2,80003554 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003522:	08848493          	addi	s1,s1,136
    80003526:	02d48a63          	beq	s1,a3,8000355a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000352a:	449c                	lw	a5,8(s1)
    8000352c:	fef059e3          	blez	a5,8000351e <iget+0x38>
    80003530:	4098                	lw	a4,0(s1)
    80003532:	ff3716e3          	bne	a4,s3,8000351e <iget+0x38>
    80003536:	40d8                	lw	a4,4(s1)
    80003538:	ff4713e3          	bne	a4,s4,8000351e <iget+0x38>
      ip->ref++;
    8000353c:	2785                	addiw	a5,a5,1
    8000353e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003540:	0001c517          	auipc	a0,0x1c
    80003544:	b4850513          	addi	a0,a0,-1208 # 8001f088 <itable>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	7ee080e7          	jalr	2030(ra) # 80000d36 <release>
      return ip;
    80003550:	8926                	mv	s2,s1
    80003552:	a03d                	j	80003580 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003554:	f7f9                	bnez	a5,80003522 <iget+0x3c>
      empty = ip;
    80003556:	8926                	mv	s2,s1
    80003558:	b7e9                	j	80003522 <iget+0x3c>
  if(empty == 0)
    8000355a:	02090c63          	beqz	s2,80003592 <iget+0xac>
  ip->dev = dev;
    8000355e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003562:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003566:	4785                	li	a5,1
    80003568:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000356c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003570:	0001c517          	auipc	a0,0x1c
    80003574:	b1850513          	addi	a0,a0,-1256 # 8001f088 <itable>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	7be080e7          	jalr	1982(ra) # 80000d36 <release>
}
    80003580:	854a                	mv	a0,s2
    80003582:	70a2                	ld	ra,40(sp)
    80003584:	7402                	ld	s0,32(sp)
    80003586:	64e2                	ld	s1,24(sp)
    80003588:	6942                	ld	s2,16(sp)
    8000358a:	69a2                	ld	s3,8(sp)
    8000358c:	6a02                	ld	s4,0(sp)
    8000358e:	6145                	addi	sp,sp,48
    80003590:	8082                	ret
    panic("iget: no inodes");
    80003592:	00005517          	auipc	a0,0x5
    80003596:	ef650513          	addi	a0,a0,-266 # 80008488 <etext+0x488>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	fc6080e7          	jalr	-58(ra) # 80000560 <panic>

00000000800035a2 <fsinit>:
fsinit(int dev) {
    800035a2:	7179                	addi	sp,sp,-48
    800035a4:	f406                	sd	ra,40(sp)
    800035a6:	f022                	sd	s0,32(sp)
    800035a8:	ec26                	sd	s1,24(sp)
    800035aa:	e84a                	sd	s2,16(sp)
    800035ac:	e44e                	sd	s3,8(sp)
    800035ae:	1800                	addi	s0,sp,48
    800035b0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035b2:	4585                	li	a1,1
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	a64080e7          	jalr	-1436(ra) # 80003018 <bread>
    800035bc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035be:	0001c997          	auipc	s3,0x1c
    800035c2:	aaa98993          	addi	s3,s3,-1366 # 8001f068 <sb>
    800035c6:	02000613          	li	a2,32
    800035ca:	05850593          	addi	a1,a0,88
    800035ce:	854e                	mv	a0,s3
    800035d0:	ffffe097          	auipc	ra,0xffffe
    800035d4:	812080e7          	jalr	-2030(ra) # 80000de2 <memmove>
  brelse(bp);
    800035d8:	8526                	mv	a0,s1
    800035da:	00000097          	auipc	ra,0x0
    800035de:	b6e080e7          	jalr	-1170(ra) # 80003148 <brelse>
  if(sb.magic != FSMAGIC)
    800035e2:	0009a703          	lw	a4,0(s3)
    800035e6:	102037b7          	lui	a5,0x10203
    800035ea:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035ee:	02f71263          	bne	a4,a5,80003612 <fsinit+0x70>
  initlog(dev, &sb);
    800035f2:	0001c597          	auipc	a1,0x1c
    800035f6:	a7658593          	addi	a1,a1,-1418 # 8001f068 <sb>
    800035fa:	854a                	mv	a0,s2
    800035fc:	00001097          	auipc	ra,0x1
    80003600:	b7c080e7          	jalr	-1156(ra) # 80004178 <initlog>
}
    80003604:	70a2                	ld	ra,40(sp)
    80003606:	7402                	ld	s0,32(sp)
    80003608:	64e2                	ld	s1,24(sp)
    8000360a:	6942                	ld	s2,16(sp)
    8000360c:	69a2                	ld	s3,8(sp)
    8000360e:	6145                	addi	sp,sp,48
    80003610:	8082                	ret
    panic("invalid file system");
    80003612:	00005517          	auipc	a0,0x5
    80003616:	e8650513          	addi	a0,a0,-378 # 80008498 <etext+0x498>
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	f46080e7          	jalr	-186(ra) # 80000560 <panic>

0000000080003622 <iinit>:
{
    80003622:	7179                	addi	sp,sp,-48
    80003624:	f406                	sd	ra,40(sp)
    80003626:	f022                	sd	s0,32(sp)
    80003628:	ec26                	sd	s1,24(sp)
    8000362a:	e84a                	sd	s2,16(sp)
    8000362c:	e44e                	sd	s3,8(sp)
    8000362e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003630:	00005597          	auipc	a1,0x5
    80003634:	e8058593          	addi	a1,a1,-384 # 800084b0 <etext+0x4b0>
    80003638:	0001c517          	auipc	a0,0x1c
    8000363c:	a5050513          	addi	a0,a0,-1456 # 8001f088 <itable>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	5b2080e7          	jalr	1458(ra) # 80000bf2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003648:	0001c497          	auipc	s1,0x1c
    8000364c:	a6848493          	addi	s1,s1,-1432 # 8001f0b0 <itable+0x28>
    80003650:	0001d997          	auipc	s3,0x1d
    80003654:	4f098993          	addi	s3,s3,1264 # 80020b40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003658:	00005917          	auipc	s2,0x5
    8000365c:	e6090913          	addi	s2,s2,-416 # 800084b8 <etext+0x4b8>
    80003660:	85ca                	mv	a1,s2
    80003662:	8526                	mv	a0,s1
    80003664:	00001097          	auipc	ra,0x1
    80003668:	e6e080e7          	jalr	-402(ra) # 800044d2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000366c:	08848493          	addi	s1,s1,136
    80003670:	ff3498e3          	bne	s1,s3,80003660 <iinit+0x3e>
}
    80003674:	70a2                	ld	ra,40(sp)
    80003676:	7402                	ld	s0,32(sp)
    80003678:	64e2                	ld	s1,24(sp)
    8000367a:	6942                	ld	s2,16(sp)
    8000367c:	69a2                	ld	s3,8(sp)
    8000367e:	6145                	addi	sp,sp,48
    80003680:	8082                	ret

0000000080003682 <ialloc>:
{
    80003682:	7139                	addi	sp,sp,-64
    80003684:	fc06                	sd	ra,56(sp)
    80003686:	f822                	sd	s0,48(sp)
    80003688:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000368a:	0001c717          	auipc	a4,0x1c
    8000368e:	9ea72703          	lw	a4,-1558(a4) # 8001f074 <sb+0xc>
    80003692:	4785                	li	a5,1
    80003694:	06e7f463          	bgeu	a5,a4,800036fc <ialloc+0x7a>
    80003698:	f426                	sd	s1,40(sp)
    8000369a:	f04a                	sd	s2,32(sp)
    8000369c:	ec4e                	sd	s3,24(sp)
    8000369e:	e852                	sd	s4,16(sp)
    800036a0:	e456                	sd	s5,8(sp)
    800036a2:	e05a                	sd	s6,0(sp)
    800036a4:	8aaa                	mv	s5,a0
    800036a6:	8b2e                	mv	s6,a1
    800036a8:	893e                	mv	s2,a5
    bp = bread(dev, IBLOCK(inum, sb));
    800036aa:	0001ca17          	auipc	s4,0x1c
    800036ae:	9bea0a13          	addi	s4,s4,-1602 # 8001f068 <sb>
    800036b2:	00495593          	srli	a1,s2,0x4
    800036b6:	018a2783          	lw	a5,24(s4)
    800036ba:	9dbd                	addw	a1,a1,a5
    800036bc:	8556                	mv	a0,s5
    800036be:	00000097          	auipc	ra,0x0
    800036c2:	95a080e7          	jalr	-1702(ra) # 80003018 <bread>
    800036c6:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036c8:	05850993          	addi	s3,a0,88
    800036cc:	00f97793          	andi	a5,s2,15
    800036d0:	079a                	slli	a5,a5,0x6
    800036d2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036d4:	00099783          	lh	a5,0(s3)
    800036d8:	cf9d                	beqz	a5,80003716 <ialloc+0x94>
    brelse(bp);
    800036da:	00000097          	auipc	ra,0x0
    800036de:	a6e080e7          	jalr	-1426(ra) # 80003148 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036e2:	0905                	addi	s2,s2,1
    800036e4:	00ca2703          	lw	a4,12(s4)
    800036e8:	0009079b          	sext.w	a5,s2
    800036ec:	fce7e3e3          	bltu	a5,a4,800036b2 <ialloc+0x30>
    800036f0:	74a2                	ld	s1,40(sp)
    800036f2:	7902                	ld	s2,32(sp)
    800036f4:	69e2                	ld	s3,24(sp)
    800036f6:	6a42                	ld	s4,16(sp)
    800036f8:	6aa2                	ld	s5,8(sp)
    800036fa:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    800036fc:	00005517          	auipc	a0,0x5
    80003700:	dc450513          	addi	a0,a0,-572 # 800084c0 <etext+0x4c0>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	ea6080e7          	jalr	-346(ra) # 800005aa <printf>
  return 0;
    8000370c:	4501                	li	a0,0
}
    8000370e:	70e2                	ld	ra,56(sp)
    80003710:	7442                	ld	s0,48(sp)
    80003712:	6121                	addi	sp,sp,64
    80003714:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003716:	04000613          	li	a2,64
    8000371a:	4581                	li	a1,0
    8000371c:	854e                	mv	a0,s3
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	660080e7          	jalr	1632(ra) # 80000d7e <memset>
      dip->type = type;
    80003726:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000372a:	8526                	mv	a0,s1
    8000372c:	00001097          	auipc	ra,0x1
    80003730:	cc2080e7          	jalr	-830(ra) # 800043ee <log_write>
      brelse(bp);
    80003734:	8526                	mv	a0,s1
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	a12080e7          	jalr	-1518(ra) # 80003148 <brelse>
      return iget(dev, inum);
    8000373e:	0009059b          	sext.w	a1,s2
    80003742:	8556                	mv	a0,s5
    80003744:	00000097          	auipc	ra,0x0
    80003748:	da2080e7          	jalr	-606(ra) # 800034e6 <iget>
    8000374c:	74a2                	ld	s1,40(sp)
    8000374e:	7902                	ld	s2,32(sp)
    80003750:	69e2                	ld	s3,24(sp)
    80003752:	6a42                	ld	s4,16(sp)
    80003754:	6aa2                	ld	s5,8(sp)
    80003756:	6b02                	ld	s6,0(sp)
    80003758:	bf5d                	j	8000370e <ialloc+0x8c>

000000008000375a <iupdate>:
{
    8000375a:	1101                	addi	sp,sp,-32
    8000375c:	ec06                	sd	ra,24(sp)
    8000375e:	e822                	sd	s0,16(sp)
    80003760:	e426                	sd	s1,8(sp)
    80003762:	e04a                	sd	s2,0(sp)
    80003764:	1000                	addi	s0,sp,32
    80003766:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003768:	415c                	lw	a5,4(a0)
    8000376a:	0047d79b          	srliw	a5,a5,0x4
    8000376e:	0001c597          	auipc	a1,0x1c
    80003772:	9125a583          	lw	a1,-1774(a1) # 8001f080 <sb+0x18>
    80003776:	9dbd                	addw	a1,a1,a5
    80003778:	4108                	lw	a0,0(a0)
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	89e080e7          	jalr	-1890(ra) # 80003018 <bread>
    80003782:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003784:	05850793          	addi	a5,a0,88
    80003788:	40d8                	lw	a4,4(s1)
    8000378a:	8b3d                	andi	a4,a4,15
    8000378c:	071a                	slli	a4,a4,0x6
    8000378e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003790:	04449703          	lh	a4,68(s1)
    80003794:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003798:	04649703          	lh	a4,70(s1)
    8000379c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800037a0:	04849703          	lh	a4,72(s1)
    800037a4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800037a8:	04a49703          	lh	a4,74(s1)
    800037ac:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800037b0:	44f8                	lw	a4,76(s1)
    800037b2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037b4:	03400613          	li	a2,52
    800037b8:	05048593          	addi	a1,s1,80
    800037bc:	00c78513          	addi	a0,a5,12
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	622080e7          	jalr	1570(ra) # 80000de2 <memmove>
  log_write(bp);
    800037c8:	854a                	mv	a0,s2
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	c24080e7          	jalr	-988(ra) # 800043ee <log_write>
  brelse(bp);
    800037d2:	854a                	mv	a0,s2
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	974080e7          	jalr	-1676(ra) # 80003148 <brelse>
}
    800037dc:	60e2                	ld	ra,24(sp)
    800037de:	6442                	ld	s0,16(sp)
    800037e0:	64a2                	ld	s1,8(sp)
    800037e2:	6902                	ld	s2,0(sp)
    800037e4:	6105                	addi	sp,sp,32
    800037e6:	8082                	ret

00000000800037e8 <idup>:
{
    800037e8:	1101                	addi	sp,sp,-32
    800037ea:	ec06                	sd	ra,24(sp)
    800037ec:	e822                	sd	s0,16(sp)
    800037ee:	e426                	sd	s1,8(sp)
    800037f0:	1000                	addi	s0,sp,32
    800037f2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037f4:	0001c517          	auipc	a0,0x1c
    800037f8:	89450513          	addi	a0,a0,-1900 # 8001f088 <itable>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	48a080e7          	jalr	1162(ra) # 80000c86 <acquire>
  ip->ref++;
    80003804:	449c                	lw	a5,8(s1)
    80003806:	2785                	addiw	a5,a5,1
    80003808:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000380a:	0001c517          	auipc	a0,0x1c
    8000380e:	87e50513          	addi	a0,a0,-1922 # 8001f088 <itable>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	524080e7          	jalr	1316(ra) # 80000d36 <release>
}
    8000381a:	8526                	mv	a0,s1
    8000381c:	60e2                	ld	ra,24(sp)
    8000381e:	6442                	ld	s0,16(sp)
    80003820:	64a2                	ld	s1,8(sp)
    80003822:	6105                	addi	sp,sp,32
    80003824:	8082                	ret

0000000080003826 <ilock>:
{
    80003826:	1101                	addi	sp,sp,-32
    80003828:	ec06                	sd	ra,24(sp)
    8000382a:	e822                	sd	s0,16(sp)
    8000382c:	e426                	sd	s1,8(sp)
    8000382e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003830:	c10d                	beqz	a0,80003852 <ilock+0x2c>
    80003832:	84aa                	mv	s1,a0
    80003834:	451c                	lw	a5,8(a0)
    80003836:	00f05e63          	blez	a5,80003852 <ilock+0x2c>
  acquiresleep(&ip->lock);
    8000383a:	0541                	addi	a0,a0,16
    8000383c:	00001097          	auipc	ra,0x1
    80003840:	cd0080e7          	jalr	-816(ra) # 8000450c <acquiresleep>
  if(ip->valid == 0){
    80003844:	40bc                	lw	a5,64(s1)
    80003846:	cf99                	beqz	a5,80003864 <ilock+0x3e>
}
    80003848:	60e2                	ld	ra,24(sp)
    8000384a:	6442                	ld	s0,16(sp)
    8000384c:	64a2                	ld	s1,8(sp)
    8000384e:	6105                	addi	sp,sp,32
    80003850:	8082                	ret
    80003852:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003854:	00005517          	auipc	a0,0x5
    80003858:	c8450513          	addi	a0,a0,-892 # 800084d8 <etext+0x4d8>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	d04080e7          	jalr	-764(ra) # 80000560 <panic>
    80003864:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003866:	40dc                	lw	a5,4(s1)
    80003868:	0047d79b          	srliw	a5,a5,0x4
    8000386c:	0001c597          	auipc	a1,0x1c
    80003870:	8145a583          	lw	a1,-2028(a1) # 8001f080 <sb+0x18>
    80003874:	9dbd                	addw	a1,a1,a5
    80003876:	4088                	lw	a0,0(s1)
    80003878:	fffff097          	auipc	ra,0xfffff
    8000387c:	7a0080e7          	jalr	1952(ra) # 80003018 <bread>
    80003880:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003882:	05850593          	addi	a1,a0,88
    80003886:	40dc                	lw	a5,4(s1)
    80003888:	8bbd                	andi	a5,a5,15
    8000388a:	079a                	slli	a5,a5,0x6
    8000388c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000388e:	00059783          	lh	a5,0(a1)
    80003892:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003896:	00259783          	lh	a5,2(a1)
    8000389a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000389e:	00459783          	lh	a5,4(a1)
    800038a2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038a6:	00659783          	lh	a5,6(a1)
    800038aa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038ae:	459c                	lw	a5,8(a1)
    800038b0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038b2:	03400613          	li	a2,52
    800038b6:	05b1                	addi	a1,a1,12
    800038b8:	05048513          	addi	a0,s1,80
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	526080e7          	jalr	1318(ra) # 80000de2 <memmove>
    brelse(bp);
    800038c4:	854a                	mv	a0,s2
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	882080e7          	jalr	-1918(ra) # 80003148 <brelse>
    ip->valid = 1;
    800038ce:	4785                	li	a5,1
    800038d0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038d2:	04449783          	lh	a5,68(s1)
    800038d6:	c399                	beqz	a5,800038dc <ilock+0xb6>
    800038d8:	6902                	ld	s2,0(sp)
    800038da:	b7bd                	j	80003848 <ilock+0x22>
      panic("ilock: no type");
    800038dc:	00005517          	auipc	a0,0x5
    800038e0:	c0450513          	addi	a0,a0,-1020 # 800084e0 <etext+0x4e0>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	c7c080e7          	jalr	-900(ra) # 80000560 <panic>

00000000800038ec <iunlock>:
{
    800038ec:	1101                	addi	sp,sp,-32
    800038ee:	ec06                	sd	ra,24(sp)
    800038f0:	e822                	sd	s0,16(sp)
    800038f2:	e426                	sd	s1,8(sp)
    800038f4:	e04a                	sd	s2,0(sp)
    800038f6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038f8:	c905                	beqz	a0,80003928 <iunlock+0x3c>
    800038fa:	84aa                	mv	s1,a0
    800038fc:	01050913          	addi	s2,a0,16
    80003900:	854a                	mv	a0,s2
    80003902:	00001097          	auipc	ra,0x1
    80003906:	ca4080e7          	jalr	-860(ra) # 800045a6 <holdingsleep>
    8000390a:	cd19                	beqz	a0,80003928 <iunlock+0x3c>
    8000390c:	449c                	lw	a5,8(s1)
    8000390e:	00f05d63          	blez	a5,80003928 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003912:	854a                	mv	a0,s2
    80003914:	00001097          	auipc	ra,0x1
    80003918:	c4e080e7          	jalr	-946(ra) # 80004562 <releasesleep>
}
    8000391c:	60e2                	ld	ra,24(sp)
    8000391e:	6442                	ld	s0,16(sp)
    80003920:	64a2                	ld	s1,8(sp)
    80003922:	6902                	ld	s2,0(sp)
    80003924:	6105                	addi	sp,sp,32
    80003926:	8082                	ret
    panic("iunlock");
    80003928:	00005517          	auipc	a0,0x5
    8000392c:	bc850513          	addi	a0,a0,-1080 # 800084f0 <etext+0x4f0>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	c30080e7          	jalr	-976(ra) # 80000560 <panic>

0000000080003938 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003938:	7179                	addi	sp,sp,-48
    8000393a:	f406                	sd	ra,40(sp)
    8000393c:	f022                	sd	s0,32(sp)
    8000393e:	ec26                	sd	s1,24(sp)
    80003940:	e84a                	sd	s2,16(sp)
    80003942:	e44e                	sd	s3,8(sp)
    80003944:	1800                	addi	s0,sp,48
    80003946:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003948:	05050493          	addi	s1,a0,80
    8000394c:	08050913          	addi	s2,a0,128
    80003950:	a021                	j	80003958 <itrunc+0x20>
    80003952:	0491                	addi	s1,s1,4
    80003954:	01248d63          	beq	s1,s2,8000396e <itrunc+0x36>
    if(ip->addrs[i]){
    80003958:	408c                	lw	a1,0(s1)
    8000395a:	dde5                	beqz	a1,80003952 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    8000395c:	0009a503          	lw	a0,0(s3)
    80003960:	00000097          	auipc	ra,0x0
    80003964:	8f8080e7          	jalr	-1800(ra) # 80003258 <bfree>
      ip->addrs[i] = 0;
    80003968:	0004a023          	sw	zero,0(s1)
    8000396c:	b7dd                	j	80003952 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000396e:	0809a583          	lw	a1,128(s3)
    80003972:	ed99                	bnez	a1,80003990 <itrunc+0x58>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003974:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003978:	854e                	mv	a0,s3
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	de0080e7          	jalr	-544(ra) # 8000375a <iupdate>
}
    80003982:	70a2                	ld	ra,40(sp)
    80003984:	7402                	ld	s0,32(sp)
    80003986:	64e2                	ld	s1,24(sp)
    80003988:	6942                	ld	s2,16(sp)
    8000398a:	69a2                	ld	s3,8(sp)
    8000398c:	6145                	addi	sp,sp,48
    8000398e:	8082                	ret
    80003990:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003992:	0009a503          	lw	a0,0(s3)
    80003996:	fffff097          	auipc	ra,0xfffff
    8000399a:	682080e7          	jalr	1666(ra) # 80003018 <bread>
    8000399e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039a0:	05850493          	addi	s1,a0,88
    800039a4:	45850913          	addi	s2,a0,1112
    800039a8:	a021                	j	800039b0 <itrunc+0x78>
    800039aa:	0491                	addi	s1,s1,4
    800039ac:	01248b63          	beq	s1,s2,800039c2 <itrunc+0x8a>
      if(a[j])
    800039b0:	408c                	lw	a1,0(s1)
    800039b2:	dde5                	beqz	a1,800039aa <itrunc+0x72>
        bfree(ip->dev, a[j]);
    800039b4:	0009a503          	lw	a0,0(s3)
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	8a0080e7          	jalr	-1888(ra) # 80003258 <bfree>
    800039c0:	b7ed                	j	800039aa <itrunc+0x72>
    brelse(bp);
    800039c2:	8552                	mv	a0,s4
    800039c4:	fffff097          	auipc	ra,0xfffff
    800039c8:	784080e7          	jalr	1924(ra) # 80003148 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039cc:	0809a583          	lw	a1,128(s3)
    800039d0:	0009a503          	lw	a0,0(s3)
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	884080e7          	jalr	-1916(ra) # 80003258 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039dc:	0809a023          	sw	zero,128(s3)
    800039e0:	6a02                	ld	s4,0(sp)
    800039e2:	bf49                	j	80003974 <itrunc+0x3c>

00000000800039e4 <iput>:
{
    800039e4:	1101                	addi	sp,sp,-32
    800039e6:	ec06                	sd	ra,24(sp)
    800039e8:	e822                	sd	s0,16(sp)
    800039ea:	e426                	sd	s1,8(sp)
    800039ec:	1000                	addi	s0,sp,32
    800039ee:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039f0:	0001b517          	auipc	a0,0x1b
    800039f4:	69850513          	addi	a0,a0,1688 # 8001f088 <itable>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	28e080e7          	jalr	654(ra) # 80000c86 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a00:	4498                	lw	a4,8(s1)
    80003a02:	4785                	li	a5,1
    80003a04:	02f70263          	beq	a4,a5,80003a28 <iput+0x44>
  ip->ref--;
    80003a08:	449c                	lw	a5,8(s1)
    80003a0a:	37fd                	addiw	a5,a5,-1
    80003a0c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a0e:	0001b517          	auipc	a0,0x1b
    80003a12:	67a50513          	addi	a0,a0,1658 # 8001f088 <itable>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	320080e7          	jalr	800(ra) # 80000d36 <release>
}
    80003a1e:	60e2                	ld	ra,24(sp)
    80003a20:	6442                	ld	s0,16(sp)
    80003a22:	64a2                	ld	s1,8(sp)
    80003a24:	6105                	addi	sp,sp,32
    80003a26:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a28:	40bc                	lw	a5,64(s1)
    80003a2a:	dff9                	beqz	a5,80003a08 <iput+0x24>
    80003a2c:	04a49783          	lh	a5,74(s1)
    80003a30:	ffe1                	bnez	a5,80003a08 <iput+0x24>
    80003a32:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003a34:	01048913          	addi	s2,s1,16
    80003a38:	854a                	mv	a0,s2
    80003a3a:	00001097          	auipc	ra,0x1
    80003a3e:	ad2080e7          	jalr	-1326(ra) # 8000450c <acquiresleep>
    release(&itable.lock);
    80003a42:	0001b517          	auipc	a0,0x1b
    80003a46:	64650513          	addi	a0,a0,1606 # 8001f088 <itable>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	2ec080e7          	jalr	748(ra) # 80000d36 <release>
    itrunc(ip);
    80003a52:	8526                	mv	a0,s1
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	ee4080e7          	jalr	-284(ra) # 80003938 <itrunc>
    ip->type = 0;
    80003a5c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a60:	8526                	mv	a0,s1
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	cf8080e7          	jalr	-776(ra) # 8000375a <iupdate>
    ip->valid = 0;
    80003a6a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a6e:	854a                	mv	a0,s2
    80003a70:	00001097          	auipc	ra,0x1
    80003a74:	af2080e7          	jalr	-1294(ra) # 80004562 <releasesleep>
    acquire(&itable.lock);
    80003a78:	0001b517          	auipc	a0,0x1b
    80003a7c:	61050513          	addi	a0,a0,1552 # 8001f088 <itable>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	206080e7          	jalr	518(ra) # 80000c86 <acquire>
    80003a88:	6902                	ld	s2,0(sp)
    80003a8a:	bfbd                	j	80003a08 <iput+0x24>

0000000080003a8c <iunlockput>:
{
    80003a8c:	1101                	addi	sp,sp,-32
    80003a8e:	ec06                	sd	ra,24(sp)
    80003a90:	e822                	sd	s0,16(sp)
    80003a92:	e426                	sd	s1,8(sp)
    80003a94:	1000                	addi	s0,sp,32
    80003a96:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	e54080e7          	jalr	-428(ra) # 800038ec <iunlock>
  iput(ip);
    80003aa0:	8526                	mv	a0,s1
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	f42080e7          	jalr	-190(ra) # 800039e4 <iput>
}
    80003aaa:	60e2                	ld	ra,24(sp)
    80003aac:	6442                	ld	s0,16(sp)
    80003aae:	64a2                	ld	s1,8(sp)
    80003ab0:	6105                	addi	sp,sp,32
    80003ab2:	8082                	ret

0000000080003ab4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ab4:	1141                	addi	sp,sp,-16
    80003ab6:	e406                	sd	ra,8(sp)
    80003ab8:	e022                	sd	s0,0(sp)
    80003aba:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003abc:	411c                	lw	a5,0(a0)
    80003abe:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ac0:	415c                	lw	a5,4(a0)
    80003ac2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ac4:	04451783          	lh	a5,68(a0)
    80003ac8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003acc:	04a51783          	lh	a5,74(a0)
    80003ad0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ad4:	04c56783          	lwu	a5,76(a0)
    80003ad8:	e99c                	sd	a5,16(a1)
}
    80003ada:	60a2                	ld	ra,8(sp)
    80003adc:	6402                	ld	s0,0(sp)
    80003ade:	0141                	addi	sp,sp,16
    80003ae0:	8082                	ret

0000000080003ae2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae2:	457c                	lw	a5,76(a0)
    80003ae4:	10d7e063          	bltu	a5,a3,80003be4 <readi+0x102>
{
    80003ae8:	7159                	addi	sp,sp,-112
    80003aea:	f486                	sd	ra,104(sp)
    80003aec:	f0a2                	sd	s0,96(sp)
    80003aee:	eca6                	sd	s1,88(sp)
    80003af0:	e0d2                	sd	s4,64(sp)
    80003af2:	fc56                	sd	s5,56(sp)
    80003af4:	f85a                	sd	s6,48(sp)
    80003af6:	f45e                	sd	s7,40(sp)
    80003af8:	1880                	addi	s0,sp,112
    80003afa:	8b2a                	mv	s6,a0
    80003afc:	8bae                	mv	s7,a1
    80003afe:	8a32                	mv	s4,a2
    80003b00:	84b6                	mv	s1,a3
    80003b02:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b04:	9f35                	addw	a4,a4,a3
    return 0;
    80003b06:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b08:	0cd76563          	bltu	a4,a3,80003bd2 <readi+0xf0>
    80003b0c:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80003b0e:	00e7f463          	bgeu	a5,a4,80003b16 <readi+0x34>
    n = ip->size - off;
    80003b12:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b16:	0a0a8563          	beqz	s5,80003bc0 <readi+0xde>
    80003b1a:	e8ca                	sd	s2,80(sp)
    80003b1c:	f062                	sd	s8,32(sp)
    80003b1e:	ec66                	sd	s9,24(sp)
    80003b20:	e86a                	sd	s10,16(sp)
    80003b22:	e46e                	sd	s11,8(sp)
    80003b24:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b26:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b2a:	5c7d                	li	s8,-1
    80003b2c:	a82d                	j	80003b66 <readi+0x84>
    80003b2e:	020d1d93          	slli	s11,s10,0x20
    80003b32:	020ddd93          	srli	s11,s11,0x20
    80003b36:	05890613          	addi	a2,s2,88
    80003b3a:	86ee                	mv	a3,s11
    80003b3c:	963e                	add	a2,a2,a5
    80003b3e:	85d2                	mv	a1,s4
    80003b40:	855e                	mv	a0,s7
    80003b42:	fffff097          	auipc	ra,0xfffff
    80003b46:	a1a080e7          	jalr	-1510(ra) # 8000255c <either_copyout>
    80003b4a:	05850963          	beq	a0,s8,80003b9c <readi+0xba>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b4e:	854a                	mv	a0,s2
    80003b50:	fffff097          	auipc	ra,0xfffff
    80003b54:	5f8080e7          	jalr	1528(ra) # 80003148 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b58:	013d09bb          	addw	s3,s10,s3
    80003b5c:	009d04bb          	addw	s1,s10,s1
    80003b60:	9a6e                	add	s4,s4,s11
    80003b62:	0559f963          	bgeu	s3,s5,80003bb4 <readi+0xd2>
    uint addr = bmap(ip, off/BSIZE);
    80003b66:	00a4d59b          	srliw	a1,s1,0xa
    80003b6a:	855a                	mv	a0,s6
    80003b6c:	00000097          	auipc	ra,0x0
    80003b70:	89e080e7          	jalr	-1890(ra) # 8000340a <bmap>
    80003b74:	85aa                	mv	a1,a0
    if(addr == 0)
    80003b76:	c539                	beqz	a0,80003bc4 <readi+0xe2>
    bp = bread(ip->dev, addr);
    80003b78:	000b2503          	lw	a0,0(s6)
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	49c080e7          	jalr	1180(ra) # 80003018 <bread>
    80003b84:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b86:	3ff4f793          	andi	a5,s1,1023
    80003b8a:	40fc873b          	subw	a4,s9,a5
    80003b8e:	413a86bb          	subw	a3,s5,s3
    80003b92:	8d3a                	mv	s10,a4
    80003b94:	f8e6fde3          	bgeu	a3,a4,80003b2e <readi+0x4c>
    80003b98:	8d36                	mv	s10,a3
    80003b9a:	bf51                	j	80003b2e <readi+0x4c>
      brelse(bp);
    80003b9c:	854a                	mv	a0,s2
    80003b9e:	fffff097          	auipc	ra,0xfffff
    80003ba2:	5aa080e7          	jalr	1450(ra) # 80003148 <brelse>
      tot = -1;
    80003ba6:	59fd                	li	s3,-1
      break;
    80003ba8:	6946                	ld	s2,80(sp)
    80003baa:	7c02                	ld	s8,32(sp)
    80003bac:	6ce2                	ld	s9,24(sp)
    80003bae:	6d42                	ld	s10,16(sp)
    80003bb0:	6da2                	ld	s11,8(sp)
    80003bb2:	a831                	j	80003bce <readi+0xec>
    80003bb4:	6946                	ld	s2,80(sp)
    80003bb6:	7c02                	ld	s8,32(sp)
    80003bb8:	6ce2                	ld	s9,24(sp)
    80003bba:	6d42                	ld	s10,16(sp)
    80003bbc:	6da2                	ld	s11,8(sp)
    80003bbe:	a801                	j	80003bce <readi+0xec>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc0:	89d6                	mv	s3,s5
    80003bc2:	a031                	j	80003bce <readi+0xec>
    80003bc4:	6946                	ld	s2,80(sp)
    80003bc6:	7c02                	ld	s8,32(sp)
    80003bc8:	6ce2                	ld	s9,24(sp)
    80003bca:	6d42                	ld	s10,16(sp)
    80003bcc:	6da2                	ld	s11,8(sp)
  }
  return tot;
    80003bce:	854e                	mv	a0,s3
    80003bd0:	69a6                	ld	s3,72(sp)
}
    80003bd2:	70a6                	ld	ra,104(sp)
    80003bd4:	7406                	ld	s0,96(sp)
    80003bd6:	64e6                	ld	s1,88(sp)
    80003bd8:	6a06                	ld	s4,64(sp)
    80003bda:	7ae2                	ld	s5,56(sp)
    80003bdc:	7b42                	ld	s6,48(sp)
    80003bde:	7ba2                	ld	s7,40(sp)
    80003be0:	6165                	addi	sp,sp,112
    80003be2:	8082                	ret
    return 0;
    80003be4:	4501                	li	a0,0
}
    80003be6:	8082                	ret

0000000080003be8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003be8:	457c                	lw	a5,76(a0)
    80003bea:	10d7e963          	bltu	a5,a3,80003cfc <writei+0x114>
{
    80003bee:	7159                	addi	sp,sp,-112
    80003bf0:	f486                	sd	ra,104(sp)
    80003bf2:	f0a2                	sd	s0,96(sp)
    80003bf4:	e8ca                	sd	s2,80(sp)
    80003bf6:	e0d2                	sd	s4,64(sp)
    80003bf8:	fc56                	sd	s5,56(sp)
    80003bfa:	f85a                	sd	s6,48(sp)
    80003bfc:	f45e                	sd	s7,40(sp)
    80003bfe:	1880                	addi	s0,sp,112
    80003c00:	8aaa                	mv	s5,a0
    80003c02:	8bae                	mv	s7,a1
    80003c04:	8a32                	mv	s4,a2
    80003c06:	8936                	mv	s2,a3
    80003c08:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c0a:	00e687bb          	addw	a5,a3,a4
    80003c0e:	0ed7e963          	bltu	a5,a3,80003d00 <writei+0x118>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c12:	00043737          	lui	a4,0x43
    80003c16:	0ef76763          	bltu	a4,a5,80003d04 <writei+0x11c>
    80003c1a:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c1c:	0c0b0863          	beqz	s6,80003cec <writei+0x104>
    80003c20:	eca6                	sd	s1,88(sp)
    80003c22:	f062                	sd	s8,32(sp)
    80003c24:	ec66                	sd	s9,24(sp)
    80003c26:	e86a                	sd	s10,16(sp)
    80003c28:	e46e                	sd	s11,8(sp)
    80003c2a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c30:	5c7d                	li	s8,-1
    80003c32:	a091                	j	80003c76 <writei+0x8e>
    80003c34:	020d1d93          	slli	s11,s10,0x20
    80003c38:	020ddd93          	srli	s11,s11,0x20
    80003c3c:	05848513          	addi	a0,s1,88
    80003c40:	86ee                	mv	a3,s11
    80003c42:	8652                	mv	a2,s4
    80003c44:	85de                	mv	a1,s7
    80003c46:	953e                	add	a0,a0,a5
    80003c48:	fffff097          	auipc	ra,0xfffff
    80003c4c:	96a080e7          	jalr	-1686(ra) # 800025b2 <either_copyin>
    80003c50:	05850e63          	beq	a0,s8,80003cac <writei+0xc4>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c54:	8526                	mv	a0,s1
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	798080e7          	jalr	1944(ra) # 800043ee <log_write>
    brelse(bp);
    80003c5e:	8526                	mv	a0,s1
    80003c60:	fffff097          	auipc	ra,0xfffff
    80003c64:	4e8080e7          	jalr	1256(ra) # 80003148 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c68:	013d09bb          	addw	s3,s10,s3
    80003c6c:	012d093b          	addw	s2,s10,s2
    80003c70:	9a6e                	add	s4,s4,s11
    80003c72:	0569f263          	bgeu	s3,s6,80003cb6 <writei+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c76:	00a9559b          	srliw	a1,s2,0xa
    80003c7a:	8556                	mv	a0,s5
    80003c7c:	fffff097          	auipc	ra,0xfffff
    80003c80:	78e080e7          	jalr	1934(ra) # 8000340a <bmap>
    80003c84:	85aa                	mv	a1,a0
    if(addr == 0)
    80003c86:	c905                	beqz	a0,80003cb6 <writei+0xce>
    bp = bread(ip->dev, addr);
    80003c88:	000aa503          	lw	a0,0(s5)
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	38c080e7          	jalr	908(ra) # 80003018 <bread>
    80003c94:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c96:	3ff97793          	andi	a5,s2,1023
    80003c9a:	40fc873b          	subw	a4,s9,a5
    80003c9e:	413b06bb          	subw	a3,s6,s3
    80003ca2:	8d3a                	mv	s10,a4
    80003ca4:	f8e6f8e3          	bgeu	a3,a4,80003c34 <writei+0x4c>
    80003ca8:	8d36                	mv	s10,a3
    80003caa:	b769                	j	80003c34 <writei+0x4c>
      brelse(bp);
    80003cac:	8526                	mv	a0,s1
    80003cae:	fffff097          	auipc	ra,0xfffff
    80003cb2:	49a080e7          	jalr	1178(ra) # 80003148 <brelse>
  }

  if(off > ip->size)
    80003cb6:	04caa783          	lw	a5,76(s5)
    80003cba:	0327fb63          	bgeu	a5,s2,80003cf0 <writei+0x108>
    ip->size = off;
    80003cbe:	052aa623          	sw	s2,76(s5)
    80003cc2:	64e6                	ld	s1,88(sp)
    80003cc4:	7c02                	ld	s8,32(sp)
    80003cc6:	6ce2                	ld	s9,24(sp)
    80003cc8:	6d42                	ld	s10,16(sp)
    80003cca:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ccc:	8556                	mv	a0,s5
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	a8c080e7          	jalr	-1396(ra) # 8000375a <iupdate>

  return tot;
    80003cd6:	854e                	mv	a0,s3
    80003cd8:	69a6                	ld	s3,72(sp)
}
    80003cda:	70a6                	ld	ra,104(sp)
    80003cdc:	7406                	ld	s0,96(sp)
    80003cde:	6946                	ld	s2,80(sp)
    80003ce0:	6a06                	ld	s4,64(sp)
    80003ce2:	7ae2                	ld	s5,56(sp)
    80003ce4:	7b42                	ld	s6,48(sp)
    80003ce6:	7ba2                	ld	s7,40(sp)
    80003ce8:	6165                	addi	sp,sp,112
    80003cea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cec:	89da                	mv	s3,s6
    80003cee:	bff9                	j	80003ccc <writei+0xe4>
    80003cf0:	64e6                	ld	s1,88(sp)
    80003cf2:	7c02                	ld	s8,32(sp)
    80003cf4:	6ce2                	ld	s9,24(sp)
    80003cf6:	6d42                	ld	s10,16(sp)
    80003cf8:	6da2                	ld	s11,8(sp)
    80003cfa:	bfc9                	j	80003ccc <writei+0xe4>
    return -1;
    80003cfc:	557d                	li	a0,-1
}
    80003cfe:	8082                	ret
    return -1;
    80003d00:	557d                	li	a0,-1
    80003d02:	bfe1                	j	80003cda <writei+0xf2>
    return -1;
    80003d04:	557d                	li	a0,-1
    80003d06:	bfd1                	j	80003cda <writei+0xf2>

0000000080003d08 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d08:	1141                	addi	sp,sp,-16
    80003d0a:	e406                	sd	ra,8(sp)
    80003d0c:	e022                	sd	s0,0(sp)
    80003d0e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d10:	4639                	li	a2,14
    80003d12:	ffffd097          	auipc	ra,0xffffd
    80003d16:	148080e7          	jalr	328(ra) # 80000e5a <strncmp>
}
    80003d1a:	60a2                	ld	ra,8(sp)
    80003d1c:	6402                	ld	s0,0(sp)
    80003d1e:	0141                	addi	sp,sp,16
    80003d20:	8082                	ret

0000000080003d22 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d22:	711d                	addi	sp,sp,-96
    80003d24:	ec86                	sd	ra,88(sp)
    80003d26:	e8a2                	sd	s0,80(sp)
    80003d28:	e4a6                	sd	s1,72(sp)
    80003d2a:	e0ca                	sd	s2,64(sp)
    80003d2c:	fc4e                	sd	s3,56(sp)
    80003d2e:	f852                	sd	s4,48(sp)
    80003d30:	f456                	sd	s5,40(sp)
    80003d32:	f05a                	sd	s6,32(sp)
    80003d34:	ec5e                	sd	s7,24(sp)
    80003d36:	1080                	addi	s0,sp,96
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d38:	04451703          	lh	a4,68(a0)
    80003d3c:	4785                	li	a5,1
    80003d3e:	00f71f63          	bne	a4,a5,80003d5c <dirlookup+0x3a>
    80003d42:	892a                	mv	s2,a0
    80003d44:	8aae                	mv	s5,a1
    80003d46:	8bb2                	mv	s7,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d48:	457c                	lw	a5,76(a0)
    80003d4a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d4c:	fa040a13          	addi	s4,s0,-96
    80003d50:	49c1                	li	s3,16
      panic("dirlookup read");
    if(de.inum == 0)
      continue;
    if(namecmp(name, de.name) == 0){
    80003d52:	fa240b13          	addi	s6,s0,-94
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d56:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d58:	e79d                	bnez	a5,80003d86 <dirlookup+0x64>
    80003d5a:	a88d                	j	80003dcc <dirlookup+0xaa>
    panic("dirlookup not DIR");
    80003d5c:	00004517          	auipc	a0,0x4
    80003d60:	79c50513          	addi	a0,a0,1948 # 800084f8 <etext+0x4f8>
    80003d64:	ffffc097          	auipc	ra,0xffffc
    80003d68:	7fc080e7          	jalr	2044(ra) # 80000560 <panic>
      panic("dirlookup read");
    80003d6c:	00004517          	auipc	a0,0x4
    80003d70:	7a450513          	addi	a0,a0,1956 # 80008510 <etext+0x510>
    80003d74:	ffffc097          	auipc	ra,0xffffc
    80003d78:	7ec080e7          	jalr	2028(ra) # 80000560 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d7c:	24c1                	addiw	s1,s1,16
    80003d7e:	04c92783          	lw	a5,76(s2)
    80003d82:	04f4f463          	bgeu	s1,a5,80003dca <dirlookup+0xa8>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d86:	874e                	mv	a4,s3
    80003d88:	86a6                	mv	a3,s1
    80003d8a:	8652                	mv	a2,s4
    80003d8c:	4581                	li	a1,0
    80003d8e:	854a                	mv	a0,s2
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	d52080e7          	jalr	-686(ra) # 80003ae2 <readi>
    80003d98:	fd351ae3          	bne	a0,s3,80003d6c <dirlookup+0x4a>
    if(de.inum == 0)
    80003d9c:	fa045783          	lhu	a5,-96(s0)
    80003da0:	dff1                	beqz	a5,80003d7c <dirlookup+0x5a>
    if(namecmp(name, de.name) == 0){
    80003da2:	85da                	mv	a1,s6
    80003da4:	8556                	mv	a0,s5
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	f62080e7          	jalr	-158(ra) # 80003d08 <namecmp>
    80003dae:	f579                	bnez	a0,80003d7c <dirlookup+0x5a>
      if(poff)
    80003db0:	000b8463          	beqz	s7,80003db8 <dirlookup+0x96>
        *poff = off;
    80003db4:	009ba023          	sw	s1,0(s7)
      return iget(dp->dev, inum);
    80003db8:	fa045583          	lhu	a1,-96(s0)
    80003dbc:	00092503          	lw	a0,0(s2)
    80003dc0:	fffff097          	auipc	ra,0xfffff
    80003dc4:	726080e7          	jalr	1830(ra) # 800034e6 <iget>
    80003dc8:	a011                	j	80003dcc <dirlookup+0xaa>
  return 0;
    80003dca:	4501                	li	a0,0
}
    80003dcc:	60e6                	ld	ra,88(sp)
    80003dce:	6446                	ld	s0,80(sp)
    80003dd0:	64a6                	ld	s1,72(sp)
    80003dd2:	6906                	ld	s2,64(sp)
    80003dd4:	79e2                	ld	s3,56(sp)
    80003dd6:	7a42                	ld	s4,48(sp)
    80003dd8:	7aa2                	ld	s5,40(sp)
    80003dda:	7b02                	ld	s6,32(sp)
    80003ddc:	6be2                	ld	s7,24(sp)
    80003dde:	6125                	addi	sp,sp,96
    80003de0:	8082                	ret

0000000080003de2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003de2:	711d                	addi	sp,sp,-96
    80003de4:	ec86                	sd	ra,88(sp)
    80003de6:	e8a2                	sd	s0,80(sp)
    80003de8:	e4a6                	sd	s1,72(sp)
    80003dea:	e0ca                	sd	s2,64(sp)
    80003dec:	fc4e                	sd	s3,56(sp)
    80003dee:	f852                	sd	s4,48(sp)
    80003df0:	f456                	sd	s5,40(sp)
    80003df2:	f05a                	sd	s6,32(sp)
    80003df4:	ec5e                	sd	s7,24(sp)
    80003df6:	e862                	sd	s8,16(sp)
    80003df8:	e466                	sd	s9,8(sp)
    80003dfa:	e06a                	sd	s10,0(sp)
    80003dfc:	1080                	addi	s0,sp,96
    80003dfe:	84aa                	mv	s1,a0
    80003e00:	8b2e                	mv	s6,a1
    80003e02:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e04:	00054703          	lbu	a4,0(a0)
    80003e08:	02f00793          	li	a5,47
    80003e0c:	02f70363          	beq	a4,a5,80003e32 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e10:	ffffe097          	auipc	ra,0xffffe
    80003e14:	ca0080e7          	jalr	-864(ra) # 80001ab0 <myproc>
    80003e18:	15053503          	ld	a0,336(a0)
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	9cc080e7          	jalr	-1588(ra) # 800037e8 <idup>
    80003e24:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003e26:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003e2a:	4c35                	li	s8,13
    memmove(name, s, DIRSIZ);
    80003e2c:	4cb9                	li	s9,14

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e2e:	4b85                	li	s7,1
    80003e30:	a87d                	j	80003eee <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003e32:	4585                	li	a1,1
    80003e34:	852e                	mv	a0,a1
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	6b0080e7          	jalr	1712(ra) # 800034e6 <iget>
    80003e3e:	8a2a                	mv	s4,a0
    80003e40:	b7dd                	j	80003e26 <namex+0x44>
      iunlockput(ip);
    80003e42:	8552                	mv	a0,s4
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	c48080e7          	jalr	-952(ra) # 80003a8c <iunlockput>
      return 0;
    80003e4c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e4e:	8552                	mv	a0,s4
    80003e50:	60e6                	ld	ra,88(sp)
    80003e52:	6446                	ld	s0,80(sp)
    80003e54:	64a6                	ld	s1,72(sp)
    80003e56:	6906                	ld	s2,64(sp)
    80003e58:	79e2                	ld	s3,56(sp)
    80003e5a:	7a42                	ld	s4,48(sp)
    80003e5c:	7aa2                	ld	s5,40(sp)
    80003e5e:	7b02                	ld	s6,32(sp)
    80003e60:	6be2                	ld	s7,24(sp)
    80003e62:	6c42                	ld	s8,16(sp)
    80003e64:	6ca2                	ld	s9,8(sp)
    80003e66:	6d02                	ld	s10,0(sp)
    80003e68:	6125                	addi	sp,sp,96
    80003e6a:	8082                	ret
      iunlock(ip);
    80003e6c:	8552                	mv	a0,s4
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	a7e080e7          	jalr	-1410(ra) # 800038ec <iunlock>
      return ip;
    80003e76:	bfe1                	j	80003e4e <namex+0x6c>
      iunlockput(ip);
    80003e78:	8552                	mv	a0,s4
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	c12080e7          	jalr	-1006(ra) # 80003a8c <iunlockput>
      return 0;
    80003e82:	8a4e                	mv	s4,s3
    80003e84:	b7e9                	j	80003e4e <namex+0x6c>
  len = path - s;
    80003e86:	40998633          	sub	a2,s3,s1
    80003e8a:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e8e:	09ac5863          	bge	s8,s10,80003f1e <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003e92:	8666                	mv	a2,s9
    80003e94:	85a6                	mv	a1,s1
    80003e96:	8556                	mv	a0,s5
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	f4a080e7          	jalr	-182(ra) # 80000de2 <memmove>
    80003ea0:	84ce                	mv	s1,s3
  while(*path == '/')
    80003ea2:	0004c783          	lbu	a5,0(s1)
    80003ea6:	01279763          	bne	a5,s2,80003eb4 <namex+0xd2>
    path++;
    80003eaa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eac:	0004c783          	lbu	a5,0(s1)
    80003eb0:	ff278de3          	beq	a5,s2,80003eaa <namex+0xc8>
    ilock(ip);
    80003eb4:	8552                	mv	a0,s4
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	970080e7          	jalr	-1680(ra) # 80003826 <ilock>
    if(ip->type != T_DIR){
    80003ebe:	044a1783          	lh	a5,68(s4)
    80003ec2:	f97790e3          	bne	a5,s7,80003e42 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003ec6:	000b0563          	beqz	s6,80003ed0 <namex+0xee>
    80003eca:	0004c783          	lbu	a5,0(s1)
    80003ece:	dfd9                	beqz	a5,80003e6c <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ed0:	4601                	li	a2,0
    80003ed2:	85d6                	mv	a1,s5
    80003ed4:	8552                	mv	a0,s4
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	e4c080e7          	jalr	-436(ra) # 80003d22 <dirlookup>
    80003ede:	89aa                	mv	s3,a0
    80003ee0:	dd41                	beqz	a0,80003e78 <namex+0x96>
    iunlockput(ip);
    80003ee2:	8552                	mv	a0,s4
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	ba8080e7          	jalr	-1112(ra) # 80003a8c <iunlockput>
    ip = next;
    80003eec:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003eee:	0004c783          	lbu	a5,0(s1)
    80003ef2:	01279763          	bne	a5,s2,80003f00 <namex+0x11e>
    path++;
    80003ef6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef8:	0004c783          	lbu	a5,0(s1)
    80003efc:	ff278de3          	beq	a5,s2,80003ef6 <namex+0x114>
  if(*path == 0)
    80003f00:	cb9d                	beqz	a5,80003f36 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003f02:	0004c783          	lbu	a5,0(s1)
    80003f06:	89a6                	mv	s3,s1
  len = path - s;
    80003f08:	4d01                	li	s10,0
    80003f0a:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003f0c:	01278963          	beq	a5,s2,80003f1e <namex+0x13c>
    80003f10:	dbbd                	beqz	a5,80003e86 <namex+0xa4>
    path++;
    80003f12:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003f14:	0009c783          	lbu	a5,0(s3)
    80003f18:	ff279ce3          	bne	a5,s2,80003f10 <namex+0x12e>
    80003f1c:	b7ad                	j	80003e86 <namex+0xa4>
    memmove(name, s, len);
    80003f1e:	2601                	sext.w	a2,a2
    80003f20:	85a6                	mv	a1,s1
    80003f22:	8556                	mv	a0,s5
    80003f24:	ffffd097          	auipc	ra,0xffffd
    80003f28:	ebe080e7          	jalr	-322(ra) # 80000de2 <memmove>
    name[len] = 0;
    80003f2c:	9d56                	add	s10,s10,s5
    80003f2e:	000d0023          	sb	zero,0(s10)
    80003f32:	84ce                	mv	s1,s3
    80003f34:	b7bd                	j	80003ea2 <namex+0xc0>
  if(nameiparent){
    80003f36:	f00b0ce3          	beqz	s6,80003e4e <namex+0x6c>
    iput(ip);
    80003f3a:	8552                	mv	a0,s4
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	aa8080e7          	jalr	-1368(ra) # 800039e4 <iput>
    return 0;
    80003f44:	4a01                	li	s4,0
    80003f46:	b721                	j	80003e4e <namex+0x6c>

0000000080003f48 <dirlink>:
{
    80003f48:	715d                	addi	sp,sp,-80
    80003f4a:	e486                	sd	ra,72(sp)
    80003f4c:	e0a2                	sd	s0,64(sp)
    80003f4e:	f84a                	sd	s2,48(sp)
    80003f50:	ec56                	sd	s5,24(sp)
    80003f52:	e85a                	sd	s6,16(sp)
    80003f54:	0880                	addi	s0,sp,80
    80003f56:	892a                	mv	s2,a0
    80003f58:	8aae                	mv	s5,a1
    80003f5a:	8b32                	mv	s6,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f5c:	4601                	li	a2,0
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	dc4080e7          	jalr	-572(ra) # 80003d22 <dirlookup>
    80003f66:	e129                	bnez	a0,80003fa8 <dirlink+0x60>
    80003f68:	fc26                	sd	s1,56(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f6a:	04c92483          	lw	s1,76(s2)
    80003f6e:	cca9                	beqz	s1,80003fc8 <dirlink+0x80>
    80003f70:	f44e                	sd	s3,40(sp)
    80003f72:	f052                	sd	s4,32(sp)
    80003f74:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f76:	fb040a13          	addi	s4,s0,-80
    80003f7a:	49c1                	li	s3,16
    80003f7c:	874e                	mv	a4,s3
    80003f7e:	86a6                	mv	a3,s1
    80003f80:	8652                	mv	a2,s4
    80003f82:	4581                	li	a1,0
    80003f84:	854a                	mv	a0,s2
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	b5c080e7          	jalr	-1188(ra) # 80003ae2 <readi>
    80003f8e:	03351363          	bne	a0,s3,80003fb4 <dirlink+0x6c>
    if(de.inum == 0)
    80003f92:	fb045783          	lhu	a5,-80(s0)
    80003f96:	c79d                	beqz	a5,80003fc4 <dirlink+0x7c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f98:	24c1                	addiw	s1,s1,16
    80003f9a:	04c92783          	lw	a5,76(s2)
    80003f9e:	fcf4efe3          	bltu	s1,a5,80003f7c <dirlink+0x34>
    80003fa2:	79a2                	ld	s3,40(sp)
    80003fa4:	7a02                	ld	s4,32(sp)
    80003fa6:	a00d                	j	80003fc8 <dirlink+0x80>
    iput(ip);
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	a3c080e7          	jalr	-1476(ra) # 800039e4 <iput>
    return -1;
    80003fb0:	557d                	li	a0,-1
    80003fb2:	a0a9                	j	80003ffc <dirlink+0xb4>
      panic("dirlink read");
    80003fb4:	00004517          	auipc	a0,0x4
    80003fb8:	56c50513          	addi	a0,a0,1388 # 80008520 <etext+0x520>
    80003fbc:	ffffc097          	auipc	ra,0xffffc
    80003fc0:	5a4080e7          	jalr	1444(ra) # 80000560 <panic>
    80003fc4:	79a2                	ld	s3,40(sp)
    80003fc6:	7a02                	ld	s4,32(sp)
  strncpy(de.name, name, DIRSIZ);
    80003fc8:	4639                	li	a2,14
    80003fca:	85d6                	mv	a1,s5
    80003fcc:	fb240513          	addi	a0,s0,-78
    80003fd0:	ffffd097          	auipc	ra,0xffffd
    80003fd4:	ec4080e7          	jalr	-316(ra) # 80000e94 <strncpy>
  de.inum = inum;
    80003fd8:	fb641823          	sh	s6,-80(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fdc:	4741                	li	a4,16
    80003fde:	86a6                	mv	a3,s1
    80003fe0:	fb040613          	addi	a2,s0,-80
    80003fe4:	4581                	li	a1,0
    80003fe6:	854a                	mv	a0,s2
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	c00080e7          	jalr	-1024(ra) # 80003be8 <writei>
    80003ff0:	1541                	addi	a0,a0,-16
    80003ff2:	00a03533          	snez	a0,a0
    80003ff6:	40a0053b          	negw	a0,a0
    80003ffa:	74e2                	ld	s1,56(sp)
}
    80003ffc:	60a6                	ld	ra,72(sp)
    80003ffe:	6406                	ld	s0,64(sp)
    80004000:	7942                	ld	s2,48(sp)
    80004002:	6ae2                	ld	s5,24(sp)
    80004004:	6b42                	ld	s6,16(sp)
    80004006:	6161                	addi	sp,sp,80
    80004008:	8082                	ret

000000008000400a <namei>:

struct inode*
namei(char *path)
{
    8000400a:	1101                	addi	sp,sp,-32
    8000400c:	ec06                	sd	ra,24(sp)
    8000400e:	e822                	sd	s0,16(sp)
    80004010:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004012:	fe040613          	addi	a2,s0,-32
    80004016:	4581                	li	a1,0
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	dca080e7          	jalr	-566(ra) # 80003de2 <namex>
}
    80004020:	60e2                	ld	ra,24(sp)
    80004022:	6442                	ld	s0,16(sp)
    80004024:	6105                	addi	sp,sp,32
    80004026:	8082                	ret

0000000080004028 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004028:	1141                	addi	sp,sp,-16
    8000402a:	e406                	sd	ra,8(sp)
    8000402c:	e022                	sd	s0,0(sp)
    8000402e:	0800                	addi	s0,sp,16
    80004030:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004032:	4585                	li	a1,1
    80004034:	00000097          	auipc	ra,0x0
    80004038:	dae080e7          	jalr	-594(ra) # 80003de2 <namex>
}
    8000403c:	60a2                	ld	ra,8(sp)
    8000403e:	6402                	ld	s0,0(sp)
    80004040:	0141                	addi	sp,sp,16
    80004042:	8082                	ret

0000000080004044 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004044:	1101                	addi	sp,sp,-32
    80004046:	ec06                	sd	ra,24(sp)
    80004048:	e822                	sd	s0,16(sp)
    8000404a:	e426                	sd	s1,8(sp)
    8000404c:	e04a                	sd	s2,0(sp)
    8000404e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004050:	0001d917          	auipc	s2,0x1d
    80004054:	ae090913          	addi	s2,s2,-1312 # 80020b30 <log>
    80004058:	01892583          	lw	a1,24(s2)
    8000405c:	02892503          	lw	a0,40(s2)
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	fb8080e7          	jalr	-72(ra) # 80003018 <bread>
    80004068:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000406a:	02c92603          	lw	a2,44(s2)
    8000406e:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004070:	00c05f63          	blez	a2,8000408e <write_head+0x4a>
    80004074:	0001d717          	auipc	a4,0x1d
    80004078:	aec70713          	addi	a4,a4,-1300 # 80020b60 <log+0x30>
    8000407c:	87aa                	mv	a5,a0
    8000407e:	060a                	slli	a2,a2,0x2
    80004080:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004082:	4314                	lw	a3,0(a4)
    80004084:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004086:	0711                	addi	a4,a4,4
    80004088:	0791                	addi	a5,a5,4
    8000408a:	fec79ce3          	bne	a5,a2,80004082 <write_head+0x3e>
  }
  bwrite(buf);
    8000408e:	8526                	mv	a0,s1
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	07a080e7          	jalr	122(ra) # 8000310a <bwrite>
  brelse(buf);
    80004098:	8526                	mv	a0,s1
    8000409a:	fffff097          	auipc	ra,0xfffff
    8000409e:	0ae080e7          	jalr	174(ra) # 80003148 <brelse>
}
    800040a2:	60e2                	ld	ra,24(sp)
    800040a4:	6442                	ld	s0,16(sp)
    800040a6:	64a2                	ld	s1,8(sp)
    800040a8:	6902                	ld	s2,0(sp)
    800040aa:	6105                	addi	sp,sp,32
    800040ac:	8082                	ret

00000000800040ae <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ae:	0001d797          	auipc	a5,0x1d
    800040b2:	aae7a783          	lw	a5,-1362(a5) # 80020b5c <log+0x2c>
    800040b6:	0cf05063          	blez	a5,80004176 <install_trans+0xc8>
{
    800040ba:	715d                	addi	sp,sp,-80
    800040bc:	e486                	sd	ra,72(sp)
    800040be:	e0a2                	sd	s0,64(sp)
    800040c0:	fc26                	sd	s1,56(sp)
    800040c2:	f84a                	sd	s2,48(sp)
    800040c4:	f44e                	sd	s3,40(sp)
    800040c6:	f052                	sd	s4,32(sp)
    800040c8:	ec56                	sd	s5,24(sp)
    800040ca:	e85a                	sd	s6,16(sp)
    800040cc:	e45e                	sd	s7,8(sp)
    800040ce:	0880                	addi	s0,sp,80
    800040d0:	8b2a                	mv	s6,a0
    800040d2:	0001da97          	auipc	s5,0x1d
    800040d6:	a8ea8a93          	addi	s5,s5,-1394 # 80020b60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040da:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040dc:	0001d997          	auipc	s3,0x1d
    800040e0:	a5498993          	addi	s3,s3,-1452 # 80020b30 <log>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040e4:	40000b93          	li	s7,1024
    800040e8:	a00d                	j	8000410a <install_trans+0x5c>
    brelse(lbuf);
    800040ea:	854a                	mv	a0,s2
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	05c080e7          	jalr	92(ra) # 80003148 <brelse>
    brelse(dbuf);
    800040f4:	8526                	mv	a0,s1
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	052080e7          	jalr	82(ra) # 80003148 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040fe:	2a05                	addiw	s4,s4,1
    80004100:	0a91                	addi	s5,s5,4
    80004102:	02c9a783          	lw	a5,44(s3)
    80004106:	04fa5d63          	bge	s4,a5,80004160 <install_trans+0xb2>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000410a:	0189a583          	lw	a1,24(s3)
    8000410e:	014585bb          	addw	a1,a1,s4
    80004112:	2585                	addiw	a1,a1,1
    80004114:	0289a503          	lw	a0,40(s3)
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	f00080e7          	jalr	-256(ra) # 80003018 <bread>
    80004120:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004122:	000aa583          	lw	a1,0(s5)
    80004126:	0289a503          	lw	a0,40(s3)
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	eee080e7          	jalr	-274(ra) # 80003018 <bread>
    80004132:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004134:	865e                	mv	a2,s7
    80004136:	05890593          	addi	a1,s2,88
    8000413a:	05850513          	addi	a0,a0,88
    8000413e:	ffffd097          	auipc	ra,0xffffd
    80004142:	ca4080e7          	jalr	-860(ra) # 80000de2 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	fc2080e7          	jalr	-62(ra) # 8000310a <bwrite>
    if(recovering == 0)
    80004150:	f80b1de3          	bnez	s6,800040ea <install_trans+0x3c>
      bunpin(dbuf);
    80004154:	8526                	mv	a0,s1
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	0c6080e7          	jalr	198(ra) # 8000321c <bunpin>
    8000415e:	b771                	j	800040ea <install_trans+0x3c>
}
    80004160:	60a6                	ld	ra,72(sp)
    80004162:	6406                	ld	s0,64(sp)
    80004164:	74e2                	ld	s1,56(sp)
    80004166:	7942                	ld	s2,48(sp)
    80004168:	79a2                	ld	s3,40(sp)
    8000416a:	7a02                	ld	s4,32(sp)
    8000416c:	6ae2                	ld	s5,24(sp)
    8000416e:	6b42                	ld	s6,16(sp)
    80004170:	6ba2                	ld	s7,8(sp)
    80004172:	6161                	addi	sp,sp,80
    80004174:	8082                	ret
    80004176:	8082                	ret

0000000080004178 <initlog>:
{
    80004178:	7179                	addi	sp,sp,-48
    8000417a:	f406                	sd	ra,40(sp)
    8000417c:	f022                	sd	s0,32(sp)
    8000417e:	ec26                	sd	s1,24(sp)
    80004180:	e84a                	sd	s2,16(sp)
    80004182:	e44e                	sd	s3,8(sp)
    80004184:	1800                	addi	s0,sp,48
    80004186:	892a                	mv	s2,a0
    80004188:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000418a:	0001d497          	auipc	s1,0x1d
    8000418e:	9a648493          	addi	s1,s1,-1626 # 80020b30 <log>
    80004192:	00004597          	auipc	a1,0x4
    80004196:	39e58593          	addi	a1,a1,926 # 80008530 <etext+0x530>
    8000419a:	8526                	mv	a0,s1
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	a56080e7          	jalr	-1450(ra) # 80000bf2 <initlock>
  log.start = sb->logstart;
    800041a4:	0149a583          	lw	a1,20(s3)
    800041a8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041aa:	0109a783          	lw	a5,16(s3)
    800041ae:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041b0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041b4:	854a                	mv	a0,s2
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	e62080e7          	jalr	-414(ra) # 80003018 <bread>
  log.lh.n = lh->n;
    800041be:	4d30                	lw	a2,88(a0)
    800041c0:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041c2:	00c05f63          	blez	a2,800041e0 <initlog+0x68>
    800041c6:	87aa                	mv	a5,a0
    800041c8:	0001d717          	auipc	a4,0x1d
    800041cc:	99870713          	addi	a4,a4,-1640 # 80020b60 <log+0x30>
    800041d0:	060a                	slli	a2,a2,0x2
    800041d2:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800041d4:	4ff4                	lw	a3,92(a5)
    800041d6:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041d8:	0791                	addi	a5,a5,4
    800041da:	0711                	addi	a4,a4,4
    800041dc:	fec79ce3          	bne	a5,a2,800041d4 <initlog+0x5c>
  brelse(buf);
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	f68080e7          	jalr	-152(ra) # 80003148 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041e8:	4505                	li	a0,1
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	ec4080e7          	jalr	-316(ra) # 800040ae <install_trans>
  log.lh.n = 0;
    800041f2:	0001d797          	auipc	a5,0x1d
    800041f6:	9607a523          	sw	zero,-1686(a5) # 80020b5c <log+0x2c>
  write_head(); // clear the log
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	e4a080e7          	jalr	-438(ra) # 80004044 <write_head>
}
    80004202:	70a2                	ld	ra,40(sp)
    80004204:	7402                	ld	s0,32(sp)
    80004206:	64e2                	ld	s1,24(sp)
    80004208:	6942                	ld	s2,16(sp)
    8000420a:	69a2                	ld	s3,8(sp)
    8000420c:	6145                	addi	sp,sp,48
    8000420e:	8082                	ret

0000000080004210 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004210:	1101                	addi	sp,sp,-32
    80004212:	ec06                	sd	ra,24(sp)
    80004214:	e822                	sd	s0,16(sp)
    80004216:	e426                	sd	s1,8(sp)
    80004218:	e04a                	sd	s2,0(sp)
    8000421a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000421c:	0001d517          	auipc	a0,0x1d
    80004220:	91450513          	addi	a0,a0,-1772 # 80020b30 <log>
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	a62080e7          	jalr	-1438(ra) # 80000c86 <acquire>
  while(1){
    if(log.committing){
    8000422c:	0001d497          	auipc	s1,0x1d
    80004230:	90448493          	addi	s1,s1,-1788 # 80020b30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004234:	4979                	li	s2,30
    80004236:	a039                	j	80004244 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004238:	85a6                	mv	a1,s1
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffe097          	auipc	ra,0xffffe
    80004240:	f1e080e7          	jalr	-226(ra) # 8000215a <sleep>
    if(log.committing){
    80004244:	50dc                	lw	a5,36(s1)
    80004246:	fbed                	bnez	a5,80004238 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004248:	5098                	lw	a4,32(s1)
    8000424a:	2705                	addiw	a4,a4,1
    8000424c:	0027179b          	slliw	a5,a4,0x2
    80004250:	9fb9                	addw	a5,a5,a4
    80004252:	0017979b          	slliw	a5,a5,0x1
    80004256:	54d4                	lw	a3,44(s1)
    80004258:	9fb5                	addw	a5,a5,a3
    8000425a:	00f95963          	bge	s2,a5,8000426c <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000425e:	85a6                	mv	a1,s1
    80004260:	8526                	mv	a0,s1
    80004262:	ffffe097          	auipc	ra,0xffffe
    80004266:	ef8080e7          	jalr	-264(ra) # 8000215a <sleep>
    8000426a:	bfe9                	j	80004244 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000426c:	0001d517          	auipc	a0,0x1d
    80004270:	8c450513          	addi	a0,a0,-1852 # 80020b30 <log>
    80004274:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	ac0080e7          	jalr	-1344(ra) # 80000d36 <release>
      break;
    }
  }
}
    8000427e:	60e2                	ld	ra,24(sp)
    80004280:	6442                	ld	s0,16(sp)
    80004282:	64a2                	ld	s1,8(sp)
    80004284:	6902                	ld	s2,0(sp)
    80004286:	6105                	addi	sp,sp,32
    80004288:	8082                	ret

000000008000428a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000428a:	7139                	addi	sp,sp,-64
    8000428c:	fc06                	sd	ra,56(sp)
    8000428e:	f822                	sd	s0,48(sp)
    80004290:	f426                	sd	s1,40(sp)
    80004292:	f04a                	sd	s2,32(sp)
    80004294:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004296:	0001d497          	auipc	s1,0x1d
    8000429a:	89a48493          	addi	s1,s1,-1894 # 80020b30 <log>
    8000429e:	8526                	mv	a0,s1
    800042a0:	ffffd097          	auipc	ra,0xffffd
    800042a4:	9e6080e7          	jalr	-1562(ra) # 80000c86 <acquire>
  log.outstanding -= 1;
    800042a8:	509c                	lw	a5,32(s1)
    800042aa:	37fd                	addiw	a5,a5,-1
    800042ac:	893e                	mv	s2,a5
    800042ae:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042b0:	50dc                	lw	a5,36(s1)
    800042b2:	e7b9                	bnez	a5,80004300 <end_op+0x76>
    panic("log.committing");
  if(log.outstanding == 0){
    800042b4:	06091263          	bnez	s2,80004318 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042b8:	0001d497          	auipc	s1,0x1d
    800042bc:	87848493          	addi	s1,s1,-1928 # 80020b30 <log>
    800042c0:	4785                	li	a5,1
    800042c2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042c4:	8526                	mv	a0,s1
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	a70080e7          	jalr	-1424(ra) # 80000d36 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042ce:	54dc                	lw	a5,44(s1)
    800042d0:	06f04863          	bgtz	a5,80004340 <end_op+0xb6>
    acquire(&log.lock);
    800042d4:	0001d497          	auipc	s1,0x1d
    800042d8:	85c48493          	addi	s1,s1,-1956 # 80020b30 <log>
    800042dc:	8526                	mv	a0,s1
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	9a8080e7          	jalr	-1624(ra) # 80000c86 <acquire>
    log.committing = 0;
    800042e6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042ea:	8526                	mv	a0,s1
    800042ec:	ffffe097          	auipc	ra,0xffffe
    800042f0:	ed2080e7          	jalr	-302(ra) # 800021be <wakeup>
    release(&log.lock);
    800042f4:	8526                	mv	a0,s1
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	a40080e7          	jalr	-1472(ra) # 80000d36 <release>
}
    800042fe:	a81d                	j	80004334 <end_op+0xaa>
    80004300:	ec4e                	sd	s3,24(sp)
    80004302:	e852                	sd	s4,16(sp)
    80004304:	e456                	sd	s5,8(sp)
    80004306:	e05a                	sd	s6,0(sp)
    panic("log.committing");
    80004308:	00004517          	auipc	a0,0x4
    8000430c:	23050513          	addi	a0,a0,560 # 80008538 <etext+0x538>
    80004310:	ffffc097          	auipc	ra,0xffffc
    80004314:	250080e7          	jalr	592(ra) # 80000560 <panic>
    wakeup(&log);
    80004318:	0001d497          	auipc	s1,0x1d
    8000431c:	81848493          	addi	s1,s1,-2024 # 80020b30 <log>
    80004320:	8526                	mv	a0,s1
    80004322:	ffffe097          	auipc	ra,0xffffe
    80004326:	e9c080e7          	jalr	-356(ra) # 800021be <wakeup>
  release(&log.lock);
    8000432a:	8526                	mv	a0,s1
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	a0a080e7          	jalr	-1526(ra) # 80000d36 <release>
}
    80004334:	70e2                	ld	ra,56(sp)
    80004336:	7442                	ld	s0,48(sp)
    80004338:	74a2                	ld	s1,40(sp)
    8000433a:	7902                	ld	s2,32(sp)
    8000433c:	6121                	addi	sp,sp,64
    8000433e:	8082                	ret
    80004340:	ec4e                	sd	s3,24(sp)
    80004342:	e852                	sd	s4,16(sp)
    80004344:	e456                	sd	s5,8(sp)
    80004346:	e05a                	sd	s6,0(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80004348:	0001da97          	auipc	s5,0x1d
    8000434c:	818a8a93          	addi	s5,s5,-2024 # 80020b60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004350:	0001ca17          	auipc	s4,0x1c
    80004354:	7e0a0a13          	addi	s4,s4,2016 # 80020b30 <log>
    memmove(to->data, from->data, BSIZE);
    80004358:	40000b13          	li	s6,1024
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000435c:	018a2583          	lw	a1,24(s4)
    80004360:	012585bb          	addw	a1,a1,s2
    80004364:	2585                	addiw	a1,a1,1
    80004366:	028a2503          	lw	a0,40(s4)
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	cae080e7          	jalr	-850(ra) # 80003018 <bread>
    80004372:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004374:	000aa583          	lw	a1,0(s5)
    80004378:	028a2503          	lw	a0,40(s4)
    8000437c:	fffff097          	auipc	ra,0xfffff
    80004380:	c9c080e7          	jalr	-868(ra) # 80003018 <bread>
    80004384:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004386:	865a                	mv	a2,s6
    80004388:	05850593          	addi	a1,a0,88
    8000438c:	05848513          	addi	a0,s1,88
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	a52080e7          	jalr	-1454(ra) # 80000de2 <memmove>
    bwrite(to);  // write the log
    80004398:	8526                	mv	a0,s1
    8000439a:	fffff097          	auipc	ra,0xfffff
    8000439e:	d70080e7          	jalr	-656(ra) # 8000310a <bwrite>
    brelse(from);
    800043a2:	854e                	mv	a0,s3
    800043a4:	fffff097          	auipc	ra,0xfffff
    800043a8:	da4080e7          	jalr	-604(ra) # 80003148 <brelse>
    brelse(to);
    800043ac:	8526                	mv	a0,s1
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	d9a080e7          	jalr	-614(ra) # 80003148 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b6:	2905                	addiw	s2,s2,1
    800043b8:	0a91                	addi	s5,s5,4
    800043ba:	02ca2783          	lw	a5,44(s4)
    800043be:	f8f94fe3          	blt	s2,a5,8000435c <end_op+0xd2>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	c82080e7          	jalr	-894(ra) # 80004044 <write_head>
    install_trans(0); // Now install writes to home locations
    800043ca:	4501                	li	a0,0
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	ce2080e7          	jalr	-798(ra) # 800040ae <install_trans>
    log.lh.n = 0;
    800043d4:	0001c797          	auipc	a5,0x1c
    800043d8:	7807a423          	sw	zero,1928(a5) # 80020b5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	c68080e7          	jalr	-920(ra) # 80004044 <write_head>
    800043e4:	69e2                	ld	s3,24(sp)
    800043e6:	6a42                	ld	s4,16(sp)
    800043e8:	6aa2                	ld	s5,8(sp)
    800043ea:	6b02                	ld	s6,0(sp)
    800043ec:	b5e5                	j	800042d4 <end_op+0x4a>

00000000800043ee <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043ee:	1101                	addi	sp,sp,-32
    800043f0:	ec06                	sd	ra,24(sp)
    800043f2:	e822                	sd	s0,16(sp)
    800043f4:	e426                	sd	s1,8(sp)
    800043f6:	e04a                	sd	s2,0(sp)
    800043f8:	1000                	addi	s0,sp,32
    800043fa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043fc:	0001c917          	auipc	s2,0x1c
    80004400:	73490913          	addi	s2,s2,1844 # 80020b30 <log>
    80004404:	854a                	mv	a0,s2
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	880080e7          	jalr	-1920(ra) # 80000c86 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000440e:	02c92603          	lw	a2,44(s2)
    80004412:	47f5                	li	a5,29
    80004414:	06c7c563          	blt	a5,a2,8000447e <log_write+0x90>
    80004418:	0001c797          	auipc	a5,0x1c
    8000441c:	7347a783          	lw	a5,1844(a5) # 80020b4c <log+0x1c>
    80004420:	37fd                	addiw	a5,a5,-1
    80004422:	04f65e63          	bge	a2,a5,8000447e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004426:	0001c797          	auipc	a5,0x1c
    8000442a:	72a7a783          	lw	a5,1834(a5) # 80020b50 <log+0x20>
    8000442e:	06f05063          	blez	a5,8000448e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004432:	4781                	li	a5,0
    80004434:	06c05563          	blez	a2,8000449e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004438:	44cc                	lw	a1,12(s1)
    8000443a:	0001c717          	auipc	a4,0x1c
    8000443e:	72670713          	addi	a4,a4,1830 # 80020b60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004442:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004444:	4314                	lw	a3,0(a4)
    80004446:	04b68c63          	beq	a3,a1,8000449e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000444a:	2785                	addiw	a5,a5,1
    8000444c:	0711                	addi	a4,a4,4
    8000444e:	fef61be3          	bne	a2,a5,80004444 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004452:	0621                	addi	a2,a2,8
    80004454:	060a                	slli	a2,a2,0x2
    80004456:	0001c797          	auipc	a5,0x1c
    8000445a:	6da78793          	addi	a5,a5,1754 # 80020b30 <log>
    8000445e:	97b2                	add	a5,a5,a2
    80004460:	44d8                	lw	a4,12(s1)
    80004462:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004464:	8526                	mv	a0,s1
    80004466:	fffff097          	auipc	ra,0xfffff
    8000446a:	d7a080e7          	jalr	-646(ra) # 800031e0 <bpin>
    log.lh.n++;
    8000446e:	0001c717          	auipc	a4,0x1c
    80004472:	6c270713          	addi	a4,a4,1730 # 80020b30 <log>
    80004476:	575c                	lw	a5,44(a4)
    80004478:	2785                	addiw	a5,a5,1
    8000447a:	d75c                	sw	a5,44(a4)
    8000447c:	a82d                	j	800044b6 <log_write+0xc8>
    panic("too big a transaction");
    8000447e:	00004517          	auipc	a0,0x4
    80004482:	0ca50513          	addi	a0,a0,202 # 80008548 <etext+0x548>
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	0da080e7          	jalr	218(ra) # 80000560 <panic>
    panic("log_write outside of trans");
    8000448e:	00004517          	auipc	a0,0x4
    80004492:	0d250513          	addi	a0,a0,210 # 80008560 <etext+0x560>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	0ca080e7          	jalr	202(ra) # 80000560 <panic>
  log.lh.block[i] = b->blockno;
    8000449e:	00878693          	addi	a3,a5,8
    800044a2:	068a                	slli	a3,a3,0x2
    800044a4:	0001c717          	auipc	a4,0x1c
    800044a8:	68c70713          	addi	a4,a4,1676 # 80020b30 <log>
    800044ac:	9736                	add	a4,a4,a3
    800044ae:	44d4                	lw	a3,12(s1)
    800044b0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044b2:	faf609e3          	beq	a2,a5,80004464 <log_write+0x76>
  }
  release(&log.lock);
    800044b6:	0001c517          	auipc	a0,0x1c
    800044ba:	67a50513          	addi	a0,a0,1658 # 80020b30 <log>
    800044be:	ffffd097          	auipc	ra,0xffffd
    800044c2:	878080e7          	jalr	-1928(ra) # 80000d36 <release>
}
    800044c6:	60e2                	ld	ra,24(sp)
    800044c8:	6442                	ld	s0,16(sp)
    800044ca:	64a2                	ld	s1,8(sp)
    800044cc:	6902                	ld	s2,0(sp)
    800044ce:	6105                	addi	sp,sp,32
    800044d0:	8082                	ret

00000000800044d2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044d2:	1101                	addi	sp,sp,-32
    800044d4:	ec06                	sd	ra,24(sp)
    800044d6:	e822                	sd	s0,16(sp)
    800044d8:	e426                	sd	s1,8(sp)
    800044da:	e04a                	sd	s2,0(sp)
    800044dc:	1000                	addi	s0,sp,32
    800044de:	84aa                	mv	s1,a0
    800044e0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044e2:	00004597          	auipc	a1,0x4
    800044e6:	09e58593          	addi	a1,a1,158 # 80008580 <etext+0x580>
    800044ea:	0521                	addi	a0,a0,8
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	706080e7          	jalr	1798(ra) # 80000bf2 <initlock>
  lk->name = name;
    800044f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fc:	0204a423          	sw	zero,40(s1)
}
    80004500:	60e2                	ld	ra,24(sp)
    80004502:	6442                	ld	s0,16(sp)
    80004504:	64a2                	ld	s1,8(sp)
    80004506:	6902                	ld	s2,0(sp)
    80004508:	6105                	addi	sp,sp,32
    8000450a:	8082                	ret

000000008000450c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000450c:	1101                	addi	sp,sp,-32
    8000450e:	ec06                	sd	ra,24(sp)
    80004510:	e822                	sd	s0,16(sp)
    80004512:	e426                	sd	s1,8(sp)
    80004514:	e04a                	sd	s2,0(sp)
    80004516:	1000                	addi	s0,sp,32
    80004518:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000451a:	00850913          	addi	s2,a0,8
    8000451e:	854a                	mv	a0,s2
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	766080e7          	jalr	1894(ra) # 80000c86 <acquire>
  while (lk->locked) {
    80004528:	409c                	lw	a5,0(s1)
    8000452a:	cb89                	beqz	a5,8000453c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000452c:	85ca                	mv	a1,s2
    8000452e:	8526                	mv	a0,s1
    80004530:	ffffe097          	auipc	ra,0xffffe
    80004534:	c2a080e7          	jalr	-982(ra) # 8000215a <sleep>
  while (lk->locked) {
    80004538:	409c                	lw	a5,0(s1)
    8000453a:	fbed                	bnez	a5,8000452c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000453c:	4785                	li	a5,1
    8000453e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004540:	ffffd097          	auipc	ra,0xffffd
    80004544:	570080e7          	jalr	1392(ra) # 80001ab0 <myproc>
    80004548:	591c                	lw	a5,48(a0)
    8000454a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000454c:	854a                	mv	a0,s2
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	7e8080e7          	jalr	2024(ra) # 80000d36 <release>
}
    80004556:	60e2                	ld	ra,24(sp)
    80004558:	6442                	ld	s0,16(sp)
    8000455a:	64a2                	ld	s1,8(sp)
    8000455c:	6902                	ld	s2,0(sp)
    8000455e:	6105                	addi	sp,sp,32
    80004560:	8082                	ret

0000000080004562 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004562:	1101                	addi	sp,sp,-32
    80004564:	ec06                	sd	ra,24(sp)
    80004566:	e822                	sd	s0,16(sp)
    80004568:	e426                	sd	s1,8(sp)
    8000456a:	e04a                	sd	s2,0(sp)
    8000456c:	1000                	addi	s0,sp,32
    8000456e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004570:	00850913          	addi	s2,a0,8
    80004574:	854a                	mv	a0,s2
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	710080e7          	jalr	1808(ra) # 80000c86 <acquire>
  lk->locked = 0;
    8000457e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004582:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004586:	8526                	mv	a0,s1
    80004588:	ffffe097          	auipc	ra,0xffffe
    8000458c:	c36080e7          	jalr	-970(ra) # 800021be <wakeup>
  release(&lk->lk);
    80004590:	854a                	mv	a0,s2
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	7a4080e7          	jalr	1956(ra) # 80000d36 <release>
}
    8000459a:	60e2                	ld	ra,24(sp)
    8000459c:	6442                	ld	s0,16(sp)
    8000459e:	64a2                	ld	s1,8(sp)
    800045a0:	6902                	ld	s2,0(sp)
    800045a2:	6105                	addi	sp,sp,32
    800045a4:	8082                	ret

00000000800045a6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045a6:	7179                	addi	sp,sp,-48
    800045a8:	f406                	sd	ra,40(sp)
    800045aa:	f022                	sd	s0,32(sp)
    800045ac:	ec26                	sd	s1,24(sp)
    800045ae:	e84a                	sd	s2,16(sp)
    800045b0:	1800                	addi	s0,sp,48
    800045b2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045b4:	00850913          	addi	s2,a0,8
    800045b8:	854a                	mv	a0,s2
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	6cc080e7          	jalr	1740(ra) # 80000c86 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c2:	409c                	lw	a5,0(s1)
    800045c4:	ef91                	bnez	a5,800045e0 <holdingsleep+0x3a>
    800045c6:	4481                	li	s1,0
  release(&lk->lk);
    800045c8:	854a                	mv	a0,s2
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	76c080e7          	jalr	1900(ra) # 80000d36 <release>
  return r;
}
    800045d2:	8526                	mv	a0,s1
    800045d4:	70a2                	ld	ra,40(sp)
    800045d6:	7402                	ld	s0,32(sp)
    800045d8:	64e2                	ld	s1,24(sp)
    800045da:	6942                	ld	s2,16(sp)
    800045dc:	6145                	addi	sp,sp,48
    800045de:	8082                	ret
    800045e0:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    800045e2:	0284a983          	lw	s3,40(s1)
    800045e6:	ffffd097          	auipc	ra,0xffffd
    800045ea:	4ca080e7          	jalr	1226(ra) # 80001ab0 <myproc>
    800045ee:	5904                	lw	s1,48(a0)
    800045f0:	413484b3          	sub	s1,s1,s3
    800045f4:	0014b493          	seqz	s1,s1
    800045f8:	69a2                	ld	s3,8(sp)
    800045fa:	b7f9                	j	800045c8 <holdingsleep+0x22>

00000000800045fc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045fc:	1141                	addi	sp,sp,-16
    800045fe:	e406                	sd	ra,8(sp)
    80004600:	e022                	sd	s0,0(sp)
    80004602:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004604:	00004597          	auipc	a1,0x4
    80004608:	f8c58593          	addi	a1,a1,-116 # 80008590 <etext+0x590>
    8000460c:	0001c517          	auipc	a0,0x1c
    80004610:	66c50513          	addi	a0,a0,1644 # 80020c78 <ftable>
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	5de080e7          	jalr	1502(ra) # 80000bf2 <initlock>
}
    8000461c:	60a2                	ld	ra,8(sp)
    8000461e:	6402                	ld	s0,0(sp)
    80004620:	0141                	addi	sp,sp,16
    80004622:	8082                	ret

0000000080004624 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004624:	1101                	addi	sp,sp,-32
    80004626:	ec06                	sd	ra,24(sp)
    80004628:	e822                	sd	s0,16(sp)
    8000462a:	e426                	sd	s1,8(sp)
    8000462c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000462e:	0001c517          	auipc	a0,0x1c
    80004632:	64a50513          	addi	a0,a0,1610 # 80020c78 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	650080e7          	jalr	1616(ra) # 80000c86 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000463e:	0001c497          	auipc	s1,0x1c
    80004642:	65248493          	addi	s1,s1,1618 # 80020c90 <ftable+0x18>
    80004646:	0001d717          	auipc	a4,0x1d
    8000464a:	5ea70713          	addi	a4,a4,1514 # 80021c30 <disk>
    if(f->ref == 0){
    8000464e:	40dc                	lw	a5,4(s1)
    80004650:	cf99                	beqz	a5,8000466e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004652:	02848493          	addi	s1,s1,40
    80004656:	fee49ce3          	bne	s1,a4,8000464e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000465a:	0001c517          	auipc	a0,0x1c
    8000465e:	61e50513          	addi	a0,a0,1566 # 80020c78 <ftable>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	6d4080e7          	jalr	1748(ra) # 80000d36 <release>
  return 0;
    8000466a:	4481                	li	s1,0
    8000466c:	a819                	j	80004682 <filealloc+0x5e>
      f->ref = 1;
    8000466e:	4785                	li	a5,1
    80004670:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004672:	0001c517          	auipc	a0,0x1c
    80004676:	60650513          	addi	a0,a0,1542 # 80020c78 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	6bc080e7          	jalr	1724(ra) # 80000d36 <release>
}
    80004682:	8526                	mv	a0,s1
    80004684:	60e2                	ld	ra,24(sp)
    80004686:	6442                	ld	s0,16(sp)
    80004688:	64a2                	ld	s1,8(sp)
    8000468a:	6105                	addi	sp,sp,32
    8000468c:	8082                	ret

000000008000468e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000468e:	1101                	addi	sp,sp,-32
    80004690:	ec06                	sd	ra,24(sp)
    80004692:	e822                	sd	s0,16(sp)
    80004694:	e426                	sd	s1,8(sp)
    80004696:	1000                	addi	s0,sp,32
    80004698:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000469a:	0001c517          	auipc	a0,0x1c
    8000469e:	5de50513          	addi	a0,a0,1502 # 80020c78 <ftable>
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	5e4080e7          	jalr	1508(ra) # 80000c86 <acquire>
  if(f->ref < 1)
    800046aa:	40dc                	lw	a5,4(s1)
    800046ac:	02f05263          	blez	a5,800046d0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046b0:	2785                	addiw	a5,a5,1
    800046b2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046b4:	0001c517          	auipc	a0,0x1c
    800046b8:	5c450513          	addi	a0,a0,1476 # 80020c78 <ftable>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	67a080e7          	jalr	1658(ra) # 80000d36 <release>
  return f;
}
    800046c4:	8526                	mv	a0,s1
    800046c6:	60e2                	ld	ra,24(sp)
    800046c8:	6442                	ld	s0,16(sp)
    800046ca:	64a2                	ld	s1,8(sp)
    800046cc:	6105                	addi	sp,sp,32
    800046ce:	8082                	ret
    panic("filedup");
    800046d0:	00004517          	auipc	a0,0x4
    800046d4:	ec850513          	addi	a0,a0,-312 # 80008598 <etext+0x598>
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	e88080e7          	jalr	-376(ra) # 80000560 <panic>

00000000800046e0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046e0:	7139                	addi	sp,sp,-64
    800046e2:	fc06                	sd	ra,56(sp)
    800046e4:	f822                	sd	s0,48(sp)
    800046e6:	f426                	sd	s1,40(sp)
    800046e8:	0080                	addi	s0,sp,64
    800046ea:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046ec:	0001c517          	auipc	a0,0x1c
    800046f0:	58c50513          	addi	a0,a0,1420 # 80020c78 <ftable>
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	592080e7          	jalr	1426(ra) # 80000c86 <acquire>
  if(f->ref < 1)
    800046fc:	40dc                	lw	a5,4(s1)
    800046fe:	04f05a63          	blez	a5,80004752 <fileclose+0x72>
    panic("fileclose");
  if(--f->ref > 0){
    80004702:	37fd                	addiw	a5,a5,-1
    80004704:	c0dc                	sw	a5,4(s1)
    80004706:	06f04263          	bgtz	a5,8000476a <fileclose+0x8a>
    8000470a:	f04a                	sd	s2,32(sp)
    8000470c:	ec4e                	sd	s3,24(sp)
    8000470e:	e852                	sd	s4,16(sp)
    80004710:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004712:	0004a903          	lw	s2,0(s1)
    80004716:	0094ca83          	lbu	s5,9(s1)
    8000471a:	0104ba03          	ld	s4,16(s1)
    8000471e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004722:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004726:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000472a:	0001c517          	auipc	a0,0x1c
    8000472e:	54e50513          	addi	a0,a0,1358 # 80020c78 <ftable>
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	604080e7          	jalr	1540(ra) # 80000d36 <release>

  if(ff.type == FD_PIPE){
    8000473a:	4785                	li	a5,1
    8000473c:	04f90463          	beq	s2,a5,80004784 <fileclose+0xa4>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004740:	3979                	addiw	s2,s2,-2
    80004742:	4785                	li	a5,1
    80004744:	0527fb63          	bgeu	a5,s2,8000479a <fileclose+0xba>
    80004748:	7902                	ld	s2,32(sp)
    8000474a:	69e2                	ld	s3,24(sp)
    8000474c:	6a42                	ld	s4,16(sp)
    8000474e:	6aa2                	ld	s5,8(sp)
    80004750:	a02d                	j	8000477a <fileclose+0x9a>
    80004752:	f04a                	sd	s2,32(sp)
    80004754:	ec4e                	sd	s3,24(sp)
    80004756:	e852                	sd	s4,16(sp)
    80004758:	e456                	sd	s5,8(sp)
    panic("fileclose");
    8000475a:	00004517          	auipc	a0,0x4
    8000475e:	e4650513          	addi	a0,a0,-442 # 800085a0 <etext+0x5a0>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	dfe080e7          	jalr	-514(ra) # 80000560 <panic>
    release(&ftable.lock);
    8000476a:	0001c517          	auipc	a0,0x1c
    8000476e:	50e50513          	addi	a0,a0,1294 # 80020c78 <ftable>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	5c4080e7          	jalr	1476(ra) # 80000d36 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    8000477a:	70e2                	ld	ra,56(sp)
    8000477c:	7442                	ld	s0,48(sp)
    8000477e:	74a2                	ld	s1,40(sp)
    80004780:	6121                	addi	sp,sp,64
    80004782:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004784:	85d6                	mv	a1,s5
    80004786:	8552                	mv	a0,s4
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	3ac080e7          	jalr	940(ra) # 80004b34 <pipeclose>
    80004790:	7902                	ld	s2,32(sp)
    80004792:	69e2                	ld	s3,24(sp)
    80004794:	6a42                	ld	s4,16(sp)
    80004796:	6aa2                	ld	s5,8(sp)
    80004798:	b7cd                	j	8000477a <fileclose+0x9a>
    begin_op();
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	a76080e7          	jalr	-1418(ra) # 80004210 <begin_op>
    iput(ff.ip);
    800047a2:	854e                	mv	a0,s3
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	240080e7          	jalr	576(ra) # 800039e4 <iput>
    end_op();
    800047ac:	00000097          	auipc	ra,0x0
    800047b0:	ade080e7          	jalr	-1314(ra) # 8000428a <end_op>
    800047b4:	7902                	ld	s2,32(sp)
    800047b6:	69e2                	ld	s3,24(sp)
    800047b8:	6a42                	ld	s4,16(sp)
    800047ba:	6aa2                	ld	s5,8(sp)
    800047bc:	bf7d                	j	8000477a <fileclose+0x9a>

00000000800047be <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047be:	715d                	addi	sp,sp,-80
    800047c0:	e486                	sd	ra,72(sp)
    800047c2:	e0a2                	sd	s0,64(sp)
    800047c4:	fc26                	sd	s1,56(sp)
    800047c6:	f44e                	sd	s3,40(sp)
    800047c8:	0880                	addi	s0,sp,80
    800047ca:	84aa                	mv	s1,a0
    800047cc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047ce:	ffffd097          	auipc	ra,0xffffd
    800047d2:	2e2080e7          	jalr	738(ra) # 80001ab0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047d6:	409c                	lw	a5,0(s1)
    800047d8:	37f9                	addiw	a5,a5,-2
    800047da:	4705                	li	a4,1
    800047dc:	04f76a63          	bltu	a4,a5,80004830 <filestat+0x72>
    800047e0:	f84a                	sd	s2,48(sp)
    800047e2:	f052                	sd	s4,32(sp)
    800047e4:	892a                	mv	s2,a0
    ilock(f->ip);
    800047e6:	6c88                	ld	a0,24(s1)
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	03e080e7          	jalr	62(ra) # 80003826 <ilock>
    stati(f->ip, &st);
    800047f0:	fb840a13          	addi	s4,s0,-72
    800047f4:	85d2                	mv	a1,s4
    800047f6:	6c88                	ld	a0,24(s1)
    800047f8:	fffff097          	auipc	ra,0xfffff
    800047fc:	2bc080e7          	jalr	700(ra) # 80003ab4 <stati>
    iunlock(f->ip);
    80004800:	6c88                	ld	a0,24(s1)
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	0ea080e7          	jalr	234(ra) # 800038ec <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000480a:	46e1                	li	a3,24
    8000480c:	8652                	mv	a2,s4
    8000480e:	85ce                	mv	a1,s3
    80004810:	05093503          	ld	a0,80(s2)
    80004814:	ffffd097          	auipc	ra,0xffffd
    80004818:	f44080e7          	jalr	-188(ra) # 80001758 <copyout>
    8000481c:	41f5551b          	sraiw	a0,a0,0x1f
    80004820:	7942                	ld	s2,48(sp)
    80004822:	7a02                	ld	s4,32(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004824:	60a6                	ld	ra,72(sp)
    80004826:	6406                	ld	s0,64(sp)
    80004828:	74e2                	ld	s1,56(sp)
    8000482a:	79a2                	ld	s3,40(sp)
    8000482c:	6161                	addi	sp,sp,80
    8000482e:	8082                	ret
  return -1;
    80004830:	557d                	li	a0,-1
    80004832:	bfcd                	j	80004824 <filestat+0x66>

0000000080004834 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004834:	7179                	addi	sp,sp,-48
    80004836:	f406                	sd	ra,40(sp)
    80004838:	f022                	sd	s0,32(sp)
    8000483a:	e84a                	sd	s2,16(sp)
    8000483c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000483e:	00854783          	lbu	a5,8(a0)
    80004842:	cbc5                	beqz	a5,800048f2 <fileread+0xbe>
    80004844:	ec26                	sd	s1,24(sp)
    80004846:	e44e                	sd	s3,8(sp)
    80004848:	84aa                	mv	s1,a0
    8000484a:	89ae                	mv	s3,a1
    8000484c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000484e:	411c                	lw	a5,0(a0)
    80004850:	4705                	li	a4,1
    80004852:	04e78963          	beq	a5,a4,800048a4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004856:	470d                	li	a4,3
    80004858:	04e78f63          	beq	a5,a4,800048b6 <fileread+0x82>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000485c:	4709                	li	a4,2
    8000485e:	08e79263          	bne	a5,a4,800048e2 <fileread+0xae>
    ilock(f->ip);
    80004862:	6d08                	ld	a0,24(a0)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	fc2080e7          	jalr	-62(ra) # 80003826 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000486c:	874a                	mv	a4,s2
    8000486e:	5094                	lw	a3,32(s1)
    80004870:	864e                	mv	a2,s3
    80004872:	4585                	li	a1,1
    80004874:	6c88                	ld	a0,24(s1)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	26c080e7          	jalr	620(ra) # 80003ae2 <readi>
    8000487e:	892a                	mv	s2,a0
    80004880:	00a05563          	blez	a0,8000488a <fileread+0x56>
      f->off += r;
    80004884:	509c                	lw	a5,32(s1)
    80004886:	9fa9                	addw	a5,a5,a0
    80004888:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000488a:	6c88                	ld	a0,24(s1)
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	060080e7          	jalr	96(ra) # 800038ec <iunlock>
    80004894:	64e2                	ld	s1,24(sp)
    80004896:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004898:	854a                	mv	a0,s2
    8000489a:	70a2                	ld	ra,40(sp)
    8000489c:	7402                	ld	s0,32(sp)
    8000489e:	6942                	ld	s2,16(sp)
    800048a0:	6145                	addi	sp,sp,48
    800048a2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048a4:	6908                	ld	a0,16(a0)
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	41a080e7          	jalr	1050(ra) # 80004cc0 <piperead>
    800048ae:	892a                	mv	s2,a0
    800048b0:	64e2                	ld	s1,24(sp)
    800048b2:	69a2                	ld	s3,8(sp)
    800048b4:	b7d5                	j	80004898 <fileread+0x64>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048b6:	02451783          	lh	a5,36(a0)
    800048ba:	03079693          	slli	a3,a5,0x30
    800048be:	92c1                	srli	a3,a3,0x30
    800048c0:	4725                	li	a4,9
    800048c2:	02d76a63          	bltu	a4,a3,800048f6 <fileread+0xc2>
    800048c6:	0792                	slli	a5,a5,0x4
    800048c8:	0001c717          	auipc	a4,0x1c
    800048cc:	31070713          	addi	a4,a4,784 # 80020bd8 <devsw>
    800048d0:	97ba                	add	a5,a5,a4
    800048d2:	639c                	ld	a5,0(a5)
    800048d4:	c78d                	beqz	a5,800048fe <fileread+0xca>
    r = devsw[f->major].read(1, addr, n);
    800048d6:	4505                	li	a0,1
    800048d8:	9782                	jalr	a5
    800048da:	892a                	mv	s2,a0
    800048dc:	64e2                	ld	s1,24(sp)
    800048de:	69a2                	ld	s3,8(sp)
    800048e0:	bf65                	j	80004898 <fileread+0x64>
    panic("fileread");
    800048e2:	00004517          	auipc	a0,0x4
    800048e6:	cce50513          	addi	a0,a0,-818 # 800085b0 <etext+0x5b0>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	c76080e7          	jalr	-906(ra) # 80000560 <panic>
    return -1;
    800048f2:	597d                	li	s2,-1
    800048f4:	b755                	j	80004898 <fileread+0x64>
      return -1;
    800048f6:	597d                	li	s2,-1
    800048f8:	64e2                	ld	s1,24(sp)
    800048fa:	69a2                	ld	s3,8(sp)
    800048fc:	bf71                	j	80004898 <fileread+0x64>
    800048fe:	597d                	li	s2,-1
    80004900:	64e2                	ld	s1,24(sp)
    80004902:	69a2                	ld	s3,8(sp)
    80004904:	bf51                	j	80004898 <fileread+0x64>

0000000080004906 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004906:	00954783          	lbu	a5,9(a0)
    8000490a:	12078c63          	beqz	a5,80004a42 <filewrite+0x13c>
{
    8000490e:	711d                	addi	sp,sp,-96
    80004910:	ec86                	sd	ra,88(sp)
    80004912:	e8a2                	sd	s0,80(sp)
    80004914:	e0ca                	sd	s2,64(sp)
    80004916:	f456                	sd	s5,40(sp)
    80004918:	f05a                	sd	s6,32(sp)
    8000491a:	1080                	addi	s0,sp,96
    8000491c:	892a                	mv	s2,a0
    8000491e:	8b2e                	mv	s6,a1
    80004920:	8ab2                	mv	s5,a2
    return -1;

  if(f->type == FD_PIPE){
    80004922:	411c                	lw	a5,0(a0)
    80004924:	4705                	li	a4,1
    80004926:	02e78963          	beq	a5,a4,80004958 <filewrite+0x52>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000492a:	470d                	li	a4,3
    8000492c:	02e78c63          	beq	a5,a4,80004964 <filewrite+0x5e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004930:	4709                	li	a4,2
    80004932:	0ee79a63          	bne	a5,a4,80004a26 <filewrite+0x120>
    80004936:	f852                	sd	s4,48(sp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004938:	0cc05563          	blez	a2,80004a02 <filewrite+0xfc>
    8000493c:	e4a6                	sd	s1,72(sp)
    8000493e:	fc4e                	sd	s3,56(sp)
    80004940:	ec5e                	sd	s7,24(sp)
    80004942:	e862                	sd	s8,16(sp)
    80004944:	e466                	sd	s9,8(sp)
    int i = 0;
    80004946:	4a01                	li	s4,0
      int n1 = n - i;
      if(n1 > max)
    80004948:	6b85                	lui	s7,0x1
    8000494a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000494e:	6c85                	lui	s9,0x1
    80004950:	c00c8c9b          	addiw	s9,s9,-1024 # c00 <_entry-0x7ffff400>
        n1 = max;

      begin_op();
      ilock(f->ip);
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004954:	4c05                	li	s8,1
    80004956:	a849                	j	800049e8 <filewrite+0xe2>
    ret = pipewrite(f->pipe, addr, n);
    80004958:	6908                	ld	a0,16(a0)
    8000495a:	00000097          	auipc	ra,0x0
    8000495e:	24a080e7          	jalr	586(ra) # 80004ba4 <pipewrite>
    80004962:	a85d                	j	80004a18 <filewrite+0x112>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004964:	02451783          	lh	a5,36(a0)
    80004968:	03079693          	slli	a3,a5,0x30
    8000496c:	92c1                	srli	a3,a3,0x30
    8000496e:	4725                	li	a4,9
    80004970:	0cd76b63          	bltu	a4,a3,80004a46 <filewrite+0x140>
    80004974:	0792                	slli	a5,a5,0x4
    80004976:	0001c717          	auipc	a4,0x1c
    8000497a:	26270713          	addi	a4,a4,610 # 80020bd8 <devsw>
    8000497e:	97ba                	add	a5,a5,a4
    80004980:	679c                	ld	a5,8(a5)
    80004982:	c7e1                	beqz	a5,80004a4a <filewrite+0x144>
    ret = devsw[f->major].write(1, addr, n);
    80004984:	4505                	li	a0,1
    80004986:	9782                	jalr	a5
    80004988:	a841                	j	80004a18 <filewrite+0x112>
      if(n1 > max)
    8000498a:	2981                	sext.w	s3,s3
      begin_op();
    8000498c:	00000097          	auipc	ra,0x0
    80004990:	884080e7          	jalr	-1916(ra) # 80004210 <begin_op>
      ilock(f->ip);
    80004994:	01893503          	ld	a0,24(s2)
    80004998:	fffff097          	auipc	ra,0xfffff
    8000499c:	e8e080e7          	jalr	-370(ra) # 80003826 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049a0:	874e                	mv	a4,s3
    800049a2:	02092683          	lw	a3,32(s2)
    800049a6:	016a0633          	add	a2,s4,s6
    800049aa:	85e2                	mv	a1,s8
    800049ac:	01893503          	ld	a0,24(s2)
    800049b0:	fffff097          	auipc	ra,0xfffff
    800049b4:	238080e7          	jalr	568(ra) # 80003be8 <writei>
    800049b8:	84aa                	mv	s1,a0
    800049ba:	00a05763          	blez	a0,800049c8 <filewrite+0xc2>
        f->off += r;
    800049be:	02092783          	lw	a5,32(s2)
    800049c2:	9fa9                	addw	a5,a5,a0
    800049c4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049c8:	01893503          	ld	a0,24(s2)
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	f20080e7          	jalr	-224(ra) # 800038ec <iunlock>
      end_op();
    800049d4:	00000097          	auipc	ra,0x0
    800049d8:	8b6080e7          	jalr	-1866(ra) # 8000428a <end_op>

      if(r != n1){
    800049dc:	02999563          	bne	s3,s1,80004a06 <filewrite+0x100>
        // error from writei
        break;
      }
      i += r;
    800049e0:	01448a3b          	addw	s4,s1,s4
    while(i < n){
    800049e4:	015a5963          	bge	s4,s5,800049f6 <filewrite+0xf0>
      int n1 = n - i;
    800049e8:	414a87bb          	subw	a5,s5,s4
    800049ec:	89be                	mv	s3,a5
      if(n1 > max)
    800049ee:	f8fbdee3          	bge	s7,a5,8000498a <filewrite+0x84>
    800049f2:	89e6                	mv	s3,s9
    800049f4:	bf59                	j	8000498a <filewrite+0x84>
    800049f6:	64a6                	ld	s1,72(sp)
    800049f8:	79e2                	ld	s3,56(sp)
    800049fa:	6be2                	ld	s7,24(sp)
    800049fc:	6c42                	ld	s8,16(sp)
    800049fe:	6ca2                	ld	s9,8(sp)
    80004a00:	a801                	j	80004a10 <filewrite+0x10a>
    int i = 0;
    80004a02:	4a01                	li	s4,0
    80004a04:	a031                	j	80004a10 <filewrite+0x10a>
    80004a06:	64a6                	ld	s1,72(sp)
    80004a08:	79e2                	ld	s3,56(sp)
    80004a0a:	6be2                	ld	s7,24(sp)
    80004a0c:	6c42                	ld	s8,16(sp)
    80004a0e:	6ca2                	ld	s9,8(sp)
    }
    ret = (i == n ? n : -1);
    80004a10:	034a9f63          	bne	s5,s4,80004a4e <filewrite+0x148>
    80004a14:	8556                	mv	a0,s5
    80004a16:	7a42                	ld	s4,48(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a18:	60e6                	ld	ra,88(sp)
    80004a1a:	6446                	ld	s0,80(sp)
    80004a1c:	6906                	ld	s2,64(sp)
    80004a1e:	7aa2                	ld	s5,40(sp)
    80004a20:	7b02                	ld	s6,32(sp)
    80004a22:	6125                	addi	sp,sp,96
    80004a24:	8082                	ret
    80004a26:	e4a6                	sd	s1,72(sp)
    80004a28:	fc4e                	sd	s3,56(sp)
    80004a2a:	f852                	sd	s4,48(sp)
    80004a2c:	ec5e                	sd	s7,24(sp)
    80004a2e:	e862                	sd	s8,16(sp)
    80004a30:	e466                	sd	s9,8(sp)
    panic("filewrite");
    80004a32:	00004517          	auipc	a0,0x4
    80004a36:	b8e50513          	addi	a0,a0,-1138 # 800085c0 <etext+0x5c0>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	b26080e7          	jalr	-1242(ra) # 80000560 <panic>
    return -1;
    80004a42:	557d                	li	a0,-1
}
    80004a44:	8082                	ret
      return -1;
    80004a46:	557d                	li	a0,-1
    80004a48:	bfc1                	j	80004a18 <filewrite+0x112>
    80004a4a:	557d                	li	a0,-1
    80004a4c:	b7f1                	j	80004a18 <filewrite+0x112>
    ret = (i == n ? n : -1);
    80004a4e:	557d                	li	a0,-1
    80004a50:	7a42                	ld	s4,48(sp)
    80004a52:	b7d9                	j	80004a18 <filewrite+0x112>

0000000080004a54 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a54:	7179                	addi	sp,sp,-48
    80004a56:	f406                	sd	ra,40(sp)
    80004a58:	f022                	sd	s0,32(sp)
    80004a5a:	ec26                	sd	s1,24(sp)
    80004a5c:	e052                	sd	s4,0(sp)
    80004a5e:	1800                	addi	s0,sp,48
    80004a60:	84aa                	mv	s1,a0
    80004a62:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a64:	0005b023          	sd	zero,0(a1)
    80004a68:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	bb8080e7          	jalr	-1096(ra) # 80004624 <filealloc>
    80004a74:	e088                	sd	a0,0(s1)
    80004a76:	cd49                	beqz	a0,80004b10 <pipealloc+0xbc>
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	bac080e7          	jalr	-1108(ra) # 80004624 <filealloc>
    80004a80:	00aa3023          	sd	a0,0(s4)
    80004a84:	c141                	beqz	a0,80004b04 <pipealloc+0xb0>
    80004a86:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	0c2080e7          	jalr	194(ra) # 80000b4a <kalloc>
    80004a90:	892a                	mv	s2,a0
    80004a92:	c13d                	beqz	a0,80004af8 <pipealloc+0xa4>
    80004a94:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004a96:	4985                	li	s3,1
    80004a98:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a9c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aa0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aa4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004aa8:	00004597          	auipc	a1,0x4
    80004aac:	b2858593          	addi	a1,a1,-1240 # 800085d0 <etext+0x5d0>
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	142080e7          	jalr	322(ra) # 80000bf2 <initlock>
  (*f0)->type = FD_PIPE;
    80004ab8:	609c                	ld	a5,0(s1)
    80004aba:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004abe:	609c                	ld	a5,0(s1)
    80004ac0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ac4:	609c                	ld	a5,0(s1)
    80004ac6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aca:	609c                	ld	a5,0(s1)
    80004acc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ad0:	000a3783          	ld	a5,0(s4)
    80004ad4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ad8:	000a3783          	ld	a5,0(s4)
    80004adc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ae0:	000a3783          	ld	a5,0(s4)
    80004ae4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ae8:	000a3783          	ld	a5,0(s4)
    80004aec:	0127b823          	sd	s2,16(a5)
  return 0;
    80004af0:	4501                	li	a0,0
    80004af2:	6942                	ld	s2,16(sp)
    80004af4:	69a2                	ld	s3,8(sp)
    80004af6:	a03d                	j	80004b24 <pipealloc+0xd0>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004af8:	6088                	ld	a0,0(s1)
    80004afa:	c119                	beqz	a0,80004b00 <pipealloc+0xac>
    80004afc:	6942                	ld	s2,16(sp)
    80004afe:	a029                	j	80004b08 <pipealloc+0xb4>
    80004b00:	6942                	ld	s2,16(sp)
    80004b02:	a039                	j	80004b10 <pipealloc+0xbc>
    80004b04:	6088                	ld	a0,0(s1)
    80004b06:	c50d                	beqz	a0,80004b30 <pipealloc+0xdc>
    fileclose(*f0);
    80004b08:	00000097          	auipc	ra,0x0
    80004b0c:	bd8080e7          	jalr	-1064(ra) # 800046e0 <fileclose>
  if(*f1)
    80004b10:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b14:	557d                	li	a0,-1
  if(*f1)
    80004b16:	c799                	beqz	a5,80004b24 <pipealloc+0xd0>
    fileclose(*f1);
    80004b18:	853e                	mv	a0,a5
    80004b1a:	00000097          	auipc	ra,0x0
    80004b1e:	bc6080e7          	jalr	-1082(ra) # 800046e0 <fileclose>
  return -1;
    80004b22:	557d                	li	a0,-1
}
    80004b24:	70a2                	ld	ra,40(sp)
    80004b26:	7402                	ld	s0,32(sp)
    80004b28:	64e2                	ld	s1,24(sp)
    80004b2a:	6a02                	ld	s4,0(sp)
    80004b2c:	6145                	addi	sp,sp,48
    80004b2e:	8082                	ret
  return -1;
    80004b30:	557d                	li	a0,-1
    80004b32:	bfcd                	j	80004b24 <pipealloc+0xd0>

0000000080004b34 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b34:	1101                	addi	sp,sp,-32
    80004b36:	ec06                	sd	ra,24(sp)
    80004b38:	e822                	sd	s0,16(sp)
    80004b3a:	e426                	sd	s1,8(sp)
    80004b3c:	e04a                	sd	s2,0(sp)
    80004b3e:	1000                	addi	s0,sp,32
    80004b40:	84aa                	mv	s1,a0
    80004b42:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	142080e7          	jalr	322(ra) # 80000c86 <acquire>
  if(writable){
    80004b4c:	02090d63          	beqz	s2,80004b86 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b50:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b54:	21848513          	addi	a0,s1,536
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	666080e7          	jalr	1638(ra) # 800021be <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b60:	2204b783          	ld	a5,544(s1)
    80004b64:	eb95                	bnez	a5,80004b98 <pipeclose+0x64>
    release(&pi->lock);
    80004b66:	8526                	mv	a0,s1
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	1ce080e7          	jalr	462(ra) # 80000d36 <release>
    kfree((char*)pi);
    80004b70:	8526                	mv	a0,s1
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	eda080e7          	jalr	-294(ra) # 80000a4c <kfree>
  } else
    release(&pi->lock);
}
    80004b7a:	60e2                	ld	ra,24(sp)
    80004b7c:	6442                	ld	s0,16(sp)
    80004b7e:	64a2                	ld	s1,8(sp)
    80004b80:	6902                	ld	s2,0(sp)
    80004b82:	6105                	addi	sp,sp,32
    80004b84:	8082                	ret
    pi->readopen = 0;
    80004b86:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b8a:	21c48513          	addi	a0,s1,540
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	630080e7          	jalr	1584(ra) # 800021be <wakeup>
    80004b96:	b7e9                	j	80004b60 <pipeclose+0x2c>
    release(&pi->lock);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	19c080e7          	jalr	412(ra) # 80000d36 <release>
}
    80004ba2:	bfe1                	j	80004b7a <pipeclose+0x46>

0000000080004ba4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ba4:	7159                	addi	sp,sp,-112
    80004ba6:	f486                	sd	ra,104(sp)
    80004ba8:	f0a2                	sd	s0,96(sp)
    80004baa:	eca6                	sd	s1,88(sp)
    80004bac:	e8ca                	sd	s2,80(sp)
    80004bae:	e4ce                	sd	s3,72(sp)
    80004bb0:	e0d2                	sd	s4,64(sp)
    80004bb2:	fc56                	sd	s5,56(sp)
    80004bb4:	1880                	addi	s0,sp,112
    80004bb6:	84aa                	mv	s1,a0
    80004bb8:	8aae                	mv	s5,a1
    80004bba:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	ef4080e7          	jalr	-268(ra) # 80001ab0 <myproc>
    80004bc4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	0be080e7          	jalr	190(ra) # 80000c86 <acquire>
  while(i < n){
    80004bd0:	0f405063          	blez	s4,80004cb0 <pipewrite+0x10c>
    80004bd4:	f85a                	sd	s6,48(sp)
    80004bd6:	f45e                	sd	s7,40(sp)
    80004bd8:	f062                	sd	s8,32(sp)
    80004bda:	ec66                	sd	s9,24(sp)
    80004bdc:	e86a                	sd	s10,16(sp)
  int i = 0;
    80004bde:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004be0:	f9f40c13          	addi	s8,s0,-97
    80004be4:	4b85                	li	s7,1
    80004be6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004be8:	21848d13          	addi	s10,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bec:	21c48c93          	addi	s9,s1,540
    80004bf0:	a099                	j	80004c36 <pipewrite+0x92>
      release(&pi->lock);
    80004bf2:	8526                	mv	a0,s1
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	142080e7          	jalr	322(ra) # 80000d36 <release>
      return -1;
    80004bfc:	597d                	li	s2,-1
    80004bfe:	7b42                	ld	s6,48(sp)
    80004c00:	7ba2                	ld	s7,40(sp)
    80004c02:	7c02                	ld	s8,32(sp)
    80004c04:	6ce2                	ld	s9,24(sp)
    80004c06:	6d42                	ld	s10,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c08:	854a                	mv	a0,s2
    80004c0a:	70a6                	ld	ra,104(sp)
    80004c0c:	7406                	ld	s0,96(sp)
    80004c0e:	64e6                	ld	s1,88(sp)
    80004c10:	6946                	ld	s2,80(sp)
    80004c12:	69a6                	ld	s3,72(sp)
    80004c14:	6a06                	ld	s4,64(sp)
    80004c16:	7ae2                	ld	s5,56(sp)
    80004c18:	6165                	addi	sp,sp,112
    80004c1a:	8082                	ret
      wakeup(&pi->nread);
    80004c1c:	856a                	mv	a0,s10
    80004c1e:	ffffd097          	auipc	ra,0xffffd
    80004c22:	5a0080e7          	jalr	1440(ra) # 800021be <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c26:	85a6                	mv	a1,s1
    80004c28:	8566                	mv	a0,s9
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	530080e7          	jalr	1328(ra) # 8000215a <sleep>
  while(i < n){
    80004c32:	05495e63          	bge	s2,s4,80004c8e <pipewrite+0xea>
    if(pi->readopen == 0 || killed(pr)){
    80004c36:	2204a783          	lw	a5,544(s1)
    80004c3a:	dfc5                	beqz	a5,80004bf2 <pipewrite+0x4e>
    80004c3c:	854e                	mv	a0,s3
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	7c4080e7          	jalr	1988(ra) # 80002402 <killed>
    80004c46:	f555                	bnez	a0,80004bf2 <pipewrite+0x4e>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c48:	2184a783          	lw	a5,536(s1)
    80004c4c:	21c4a703          	lw	a4,540(s1)
    80004c50:	2007879b          	addiw	a5,a5,512
    80004c54:	fcf704e3          	beq	a4,a5,80004c1c <pipewrite+0x78>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c58:	86de                	mv	a3,s7
    80004c5a:	01590633          	add	a2,s2,s5
    80004c5e:	85e2                	mv	a1,s8
    80004c60:	0509b503          	ld	a0,80(s3)
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	b80080e7          	jalr	-1152(ra) # 800017e4 <copyin>
    80004c6c:	05650463          	beq	a0,s6,80004cb4 <pipewrite+0x110>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c70:	21c4a783          	lw	a5,540(s1)
    80004c74:	0017871b          	addiw	a4,a5,1
    80004c78:	20e4ae23          	sw	a4,540(s1)
    80004c7c:	1ff7f793          	andi	a5,a5,511
    80004c80:	97a6                	add	a5,a5,s1
    80004c82:	f9f44703          	lbu	a4,-97(s0)
    80004c86:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c8a:	2905                	addiw	s2,s2,1
    80004c8c:	b75d                	j	80004c32 <pipewrite+0x8e>
    80004c8e:	7b42                	ld	s6,48(sp)
    80004c90:	7ba2                	ld	s7,40(sp)
    80004c92:	7c02                	ld	s8,32(sp)
    80004c94:	6ce2                	ld	s9,24(sp)
    80004c96:	6d42                	ld	s10,16(sp)
  wakeup(&pi->nread);
    80004c98:	21848513          	addi	a0,s1,536
    80004c9c:	ffffd097          	auipc	ra,0xffffd
    80004ca0:	522080e7          	jalr	1314(ra) # 800021be <wakeup>
  release(&pi->lock);
    80004ca4:	8526                	mv	a0,s1
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	090080e7          	jalr	144(ra) # 80000d36 <release>
  return i;
    80004cae:	bfa9                	j	80004c08 <pipewrite+0x64>
  int i = 0;
    80004cb0:	4901                	li	s2,0
    80004cb2:	b7dd                	j	80004c98 <pipewrite+0xf4>
    80004cb4:	7b42                	ld	s6,48(sp)
    80004cb6:	7ba2                	ld	s7,40(sp)
    80004cb8:	7c02                	ld	s8,32(sp)
    80004cba:	6ce2                	ld	s9,24(sp)
    80004cbc:	6d42                	ld	s10,16(sp)
    80004cbe:	bfe9                	j	80004c98 <pipewrite+0xf4>

0000000080004cc0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cc0:	711d                	addi	sp,sp,-96
    80004cc2:	ec86                	sd	ra,88(sp)
    80004cc4:	e8a2                	sd	s0,80(sp)
    80004cc6:	e4a6                	sd	s1,72(sp)
    80004cc8:	e0ca                	sd	s2,64(sp)
    80004cca:	fc4e                	sd	s3,56(sp)
    80004ccc:	f852                	sd	s4,48(sp)
    80004cce:	f456                	sd	s5,40(sp)
    80004cd0:	1080                	addi	s0,sp,96
    80004cd2:	84aa                	mv	s1,a0
    80004cd4:	892e                	mv	s2,a1
    80004cd6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	dd8080e7          	jalr	-552(ra) # 80001ab0 <myproc>
    80004ce0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	fa2080e7          	jalr	-94(ra) # 80000c86 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cec:	2184a703          	lw	a4,536(s1)
    80004cf0:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cf4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf8:	02f71b63          	bne	a4,a5,80004d2e <piperead+0x6e>
    80004cfc:	2244a783          	lw	a5,548(s1)
    80004d00:	c3b1                	beqz	a5,80004d44 <piperead+0x84>
    if(killed(pr)){
    80004d02:	8552                	mv	a0,s4
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	6fe080e7          	jalr	1790(ra) # 80002402 <killed>
    80004d0c:	e50d                	bnez	a0,80004d36 <piperead+0x76>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d0e:	85a6                	mv	a1,s1
    80004d10:	854e                	mv	a0,s3
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	448080e7          	jalr	1096(ra) # 8000215a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d1a:	2184a703          	lw	a4,536(s1)
    80004d1e:	21c4a783          	lw	a5,540(s1)
    80004d22:	fcf70de3          	beq	a4,a5,80004cfc <piperead+0x3c>
    80004d26:	f05a                	sd	s6,32(sp)
    80004d28:	ec5e                	sd	s7,24(sp)
    80004d2a:	e862                	sd	s8,16(sp)
    80004d2c:	a839                	j	80004d4a <piperead+0x8a>
    80004d2e:	f05a                	sd	s6,32(sp)
    80004d30:	ec5e                	sd	s7,24(sp)
    80004d32:	e862                	sd	s8,16(sp)
    80004d34:	a819                	j	80004d4a <piperead+0x8a>
      release(&pi->lock);
    80004d36:	8526                	mv	a0,s1
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	ffe080e7          	jalr	-2(ra) # 80000d36 <release>
      return -1;
    80004d40:	59fd                	li	s3,-1
    80004d42:	a895                	j	80004db6 <piperead+0xf6>
    80004d44:	f05a                	sd	s6,32(sp)
    80004d46:	ec5e                	sd	s7,24(sp)
    80004d48:	e862                	sd	s8,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d4a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d4c:	faf40c13          	addi	s8,s0,-81
    80004d50:	4b85                	li	s7,1
    80004d52:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d54:	05505363          	blez	s5,80004d9a <piperead+0xda>
    if(pi->nread == pi->nwrite)
    80004d58:	2184a783          	lw	a5,536(s1)
    80004d5c:	21c4a703          	lw	a4,540(s1)
    80004d60:	02f70d63          	beq	a4,a5,80004d9a <piperead+0xda>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d64:	0017871b          	addiw	a4,a5,1
    80004d68:	20e4ac23          	sw	a4,536(s1)
    80004d6c:	1ff7f793          	andi	a5,a5,511
    80004d70:	97a6                	add	a5,a5,s1
    80004d72:	0187c783          	lbu	a5,24(a5)
    80004d76:	faf407a3          	sb	a5,-81(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d7a:	86de                	mv	a3,s7
    80004d7c:	8662                	mv	a2,s8
    80004d7e:	85ca                	mv	a1,s2
    80004d80:	050a3503          	ld	a0,80(s4)
    80004d84:	ffffd097          	auipc	ra,0xffffd
    80004d88:	9d4080e7          	jalr	-1580(ra) # 80001758 <copyout>
    80004d8c:	01650763          	beq	a0,s6,80004d9a <piperead+0xda>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d90:	2985                	addiw	s3,s3,1
    80004d92:	0905                	addi	s2,s2,1
    80004d94:	fd3a92e3          	bne	s5,s3,80004d58 <piperead+0x98>
    80004d98:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d9a:	21c48513          	addi	a0,s1,540
    80004d9e:	ffffd097          	auipc	ra,0xffffd
    80004da2:	420080e7          	jalr	1056(ra) # 800021be <wakeup>
  release(&pi->lock);
    80004da6:	8526                	mv	a0,s1
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	f8e080e7          	jalr	-114(ra) # 80000d36 <release>
    80004db0:	7b02                	ld	s6,32(sp)
    80004db2:	6be2                	ld	s7,24(sp)
    80004db4:	6c42                	ld	s8,16(sp)
  return i;
}
    80004db6:	854e                	mv	a0,s3
    80004db8:	60e6                	ld	ra,88(sp)
    80004dba:	6446                	ld	s0,80(sp)
    80004dbc:	64a6                	ld	s1,72(sp)
    80004dbe:	6906                	ld	s2,64(sp)
    80004dc0:	79e2                	ld	s3,56(sp)
    80004dc2:	7a42                	ld	s4,48(sp)
    80004dc4:	7aa2                	ld	s5,40(sp)
    80004dc6:	6125                	addi	sp,sp,96
    80004dc8:	8082                	ret

0000000080004dca <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004dca:	1141                	addi	sp,sp,-16
    80004dcc:	e406                	sd	ra,8(sp)
    80004dce:	e022                	sd	s0,0(sp)
    80004dd0:	0800                	addi	s0,sp,16
    80004dd2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004dd4:	0035151b          	slliw	a0,a0,0x3
    80004dd8:	8921                	andi	a0,a0,8
      perm = PTE_X;
    if(flags & 0x2)
    80004dda:	8b89                	andi	a5,a5,2
    80004ddc:	c399                	beqz	a5,80004de2 <flags2perm+0x18>
      perm |= PTE_W;
    80004dde:	00456513          	ori	a0,a0,4
    return perm;
}
    80004de2:	60a2                	ld	ra,8(sp)
    80004de4:	6402                	ld	s0,0(sp)
    80004de6:	0141                	addi	sp,sp,16
    80004de8:	8082                	ret

0000000080004dea <exec>:

int
exec(char *path, char **argv)
{
    80004dea:	de010113          	addi	sp,sp,-544
    80004dee:	20113c23          	sd	ra,536(sp)
    80004df2:	20813823          	sd	s0,528(sp)
    80004df6:	20913423          	sd	s1,520(sp)
    80004dfa:	21213023          	sd	s2,512(sp)
    80004dfe:	1400                	addi	s0,sp,544
    80004e00:	892a                	mv	s2,a0
    80004e02:	dea43823          	sd	a0,-528(s0)
    80004e06:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	ca6080e7          	jalr	-858(ra) # 80001ab0 <myproc>
    80004e12:	84aa                	mv	s1,a0

  begin_op();
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	3fc080e7          	jalr	1020(ra) # 80004210 <begin_op>

  if((ip = namei(path)) == 0){
    80004e1c:	854a                	mv	a0,s2
    80004e1e:	fffff097          	auipc	ra,0xfffff
    80004e22:	1ec080e7          	jalr	492(ra) # 8000400a <namei>
    80004e26:	c525                	beqz	a0,80004e8e <exec+0xa4>
    80004e28:	fbd2                	sd	s4,496(sp)
    80004e2a:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	9fa080e7          	jalr	-1542(ra) # 80003826 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e34:	04000713          	li	a4,64
    80004e38:	4681                	li	a3,0
    80004e3a:	e5040613          	addi	a2,s0,-432
    80004e3e:	4581                	li	a1,0
    80004e40:	8552                	mv	a0,s4
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	ca0080e7          	jalr	-864(ra) # 80003ae2 <readi>
    80004e4a:	04000793          	li	a5,64
    80004e4e:	00f51a63          	bne	a0,a5,80004e62 <exec+0x78>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e52:	e5042703          	lw	a4,-432(s0)
    80004e56:	464c47b7          	lui	a5,0x464c4
    80004e5a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e5e:	02f70e63          	beq	a4,a5,80004e9a <exec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e62:	8552                	mv	a0,s4
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	c28080e7          	jalr	-984(ra) # 80003a8c <iunlockput>
    end_op();
    80004e6c:	fffff097          	auipc	ra,0xfffff
    80004e70:	41e080e7          	jalr	1054(ra) # 8000428a <end_op>
  }
  return -1;
    80004e74:	557d                	li	a0,-1
    80004e76:	7a5e                	ld	s4,496(sp)
}
    80004e78:	21813083          	ld	ra,536(sp)
    80004e7c:	21013403          	ld	s0,528(sp)
    80004e80:	20813483          	ld	s1,520(sp)
    80004e84:	20013903          	ld	s2,512(sp)
    80004e88:	22010113          	addi	sp,sp,544
    80004e8c:	8082                	ret
    end_op();
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	3fc080e7          	jalr	1020(ra) # 8000428a <end_op>
    return -1;
    80004e96:	557d                	li	a0,-1
    80004e98:	b7c5                	j	80004e78 <exec+0x8e>
    80004e9a:	f3da                	sd	s6,480(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	cd6080e7          	jalr	-810(ra) # 80001b74 <proc_pagetable>
    80004ea6:	8b2a                	mv	s6,a0
    80004ea8:	2c050163          	beqz	a0,8000516a <exec+0x380>
    80004eac:	ffce                	sd	s3,504(sp)
    80004eae:	f7d6                	sd	s5,488(sp)
    80004eb0:	efde                	sd	s7,472(sp)
    80004eb2:	ebe2                	sd	s8,464(sp)
    80004eb4:	e7e6                	sd	s9,456(sp)
    80004eb6:	e3ea                	sd	s10,448(sp)
    80004eb8:	ff6e                	sd	s11,440(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eba:	e7042683          	lw	a3,-400(s0)
    80004ebe:	e8845783          	lhu	a5,-376(s0)
    80004ec2:	10078363          	beqz	a5,80004fc8 <exec+0x1de>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ec6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ec8:	4d01                	li	s10,0
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004eca:	03800d93          	li	s11,56
    if(ph.vaddr % PGSIZE != 0)
    80004ece:	6c85                	lui	s9,0x1
    80004ed0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ed4:	def43423          	sd	a5,-536(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004ed8:	6a85                	lui	s5,0x1
    80004eda:	a0b5                	j	80004f46 <exec+0x15c>
      panic("loadseg: address should exist");
    80004edc:	00003517          	auipc	a0,0x3
    80004ee0:	6fc50513          	addi	a0,a0,1788 # 800085d8 <etext+0x5d8>
    80004ee4:	ffffb097          	auipc	ra,0xffffb
    80004ee8:	67c080e7          	jalr	1660(ra) # 80000560 <panic>
    if(sz - i < PGSIZE)
    80004eec:	2901                	sext.w	s2,s2
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eee:	874a                	mv	a4,s2
    80004ef0:	009c06bb          	addw	a3,s8,s1
    80004ef4:	4581                	li	a1,0
    80004ef6:	8552                	mv	a0,s4
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	bea080e7          	jalr	-1046(ra) # 80003ae2 <readi>
    80004f00:	26a91963          	bne	s2,a0,80005172 <exec+0x388>
  for(i = 0; i < sz; i += PGSIZE){
    80004f04:	009a84bb          	addw	s1,s5,s1
    80004f08:	0334f463          	bgeu	s1,s3,80004f30 <exec+0x146>
    pa = walkaddr(pagetable, va + i);
    80004f0c:	02049593          	slli	a1,s1,0x20
    80004f10:	9181                	srli	a1,a1,0x20
    80004f12:	95de                	add	a1,a1,s7
    80004f14:	855a                	mv	a0,s6
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	20a080e7          	jalr	522(ra) # 80001120 <walkaddr>
    80004f1e:	862a                	mv	a2,a0
    if(pa == 0)
    80004f20:	dd55                	beqz	a0,80004edc <exec+0xf2>
    if(sz - i < PGSIZE)
    80004f22:	409987bb          	subw	a5,s3,s1
    80004f26:	893e                	mv	s2,a5
    80004f28:	fcfcf2e3          	bgeu	s9,a5,80004eec <exec+0x102>
    80004f2c:	8956                	mv	s2,s5
    80004f2e:	bf7d                	j	80004eec <exec+0x102>
    sz = sz1;
    80004f30:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f34:	2d05                	addiw	s10,s10,1
    80004f36:	e0843783          	ld	a5,-504(s0)
    80004f3a:	0387869b          	addiw	a3,a5,56
    80004f3e:	e8845783          	lhu	a5,-376(s0)
    80004f42:	08fd5463          	bge	s10,a5,80004fca <exec+0x1e0>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f46:	e0d43423          	sd	a3,-504(s0)
    80004f4a:	876e                	mv	a4,s11
    80004f4c:	e1840613          	addi	a2,s0,-488
    80004f50:	4581                	li	a1,0
    80004f52:	8552                	mv	a0,s4
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	b8e080e7          	jalr	-1138(ra) # 80003ae2 <readi>
    80004f5c:	21b51963          	bne	a0,s11,8000516e <exec+0x384>
    if(ph.type != ELF_PROG_LOAD)
    80004f60:	e1842783          	lw	a5,-488(s0)
    80004f64:	4705                	li	a4,1
    80004f66:	fce797e3          	bne	a5,a4,80004f34 <exec+0x14a>
    if(ph.memsz < ph.filesz)
    80004f6a:	e4043483          	ld	s1,-448(s0)
    80004f6e:	e3843783          	ld	a5,-456(s0)
    80004f72:	22f4e063          	bltu	s1,a5,80005192 <exec+0x3a8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f76:	e2843783          	ld	a5,-472(s0)
    80004f7a:	94be                	add	s1,s1,a5
    80004f7c:	20f4ee63          	bltu	s1,a5,80005198 <exec+0x3ae>
    if(ph.vaddr % PGSIZE != 0)
    80004f80:	de843703          	ld	a4,-536(s0)
    80004f84:	8ff9                	and	a5,a5,a4
    80004f86:	20079c63          	bnez	a5,8000519e <exec+0x3b4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f8a:	e1c42503          	lw	a0,-484(s0)
    80004f8e:	00000097          	auipc	ra,0x0
    80004f92:	e3c080e7          	jalr	-452(ra) # 80004dca <flags2perm>
    80004f96:	86aa                	mv	a3,a0
    80004f98:	8626                	mv	a2,s1
    80004f9a:	85ca                	mv	a1,s2
    80004f9c:	855a                	mv	a0,s6
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	546080e7          	jalr	1350(ra) # 800014e4 <uvmalloc>
    80004fa6:	dea43c23          	sd	a0,-520(s0)
    80004faa:	1e050d63          	beqz	a0,800051a4 <exec+0x3ba>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fae:	e2843b83          	ld	s7,-472(s0)
    80004fb2:	e2042c03          	lw	s8,-480(s0)
    80004fb6:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fba:	00098463          	beqz	s3,80004fc2 <exec+0x1d8>
    80004fbe:	4481                	li	s1,0
    80004fc0:	b7b1                	j	80004f0c <exec+0x122>
    sz = sz1;
    80004fc2:	df843903          	ld	s2,-520(s0)
    80004fc6:	b7bd                	j	80004f34 <exec+0x14a>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fc8:	4901                	li	s2,0
  iunlockput(ip);
    80004fca:	8552                	mv	a0,s4
    80004fcc:	fffff097          	auipc	ra,0xfffff
    80004fd0:	ac0080e7          	jalr	-1344(ra) # 80003a8c <iunlockput>
  end_op();
    80004fd4:	fffff097          	auipc	ra,0xfffff
    80004fd8:	2b6080e7          	jalr	694(ra) # 8000428a <end_op>
  p = myproc();
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	ad4080e7          	jalr	-1324(ra) # 80001ab0 <myproc>
    80004fe4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fe6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fea:	6985                	lui	s3,0x1
    80004fec:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004fee:	99ca                	add	s3,s3,s2
    80004ff0:	77fd                	lui	a5,0xfffff
    80004ff2:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ff6:	4691                	li	a3,4
    80004ff8:	6609                	lui	a2,0x2
    80004ffa:	964e                	add	a2,a2,s3
    80004ffc:	85ce                	mv	a1,s3
    80004ffe:	855a                	mv	a0,s6
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	4e4080e7          	jalr	1252(ra) # 800014e4 <uvmalloc>
    80005008:	8a2a                	mv	s4,a0
    8000500a:	e115                	bnez	a0,8000502e <exec+0x244>
    proc_freepagetable(pagetable, sz);
    8000500c:	85ce                	mv	a1,s3
    8000500e:	855a                	mv	a0,s6
    80005010:	ffffd097          	auipc	ra,0xffffd
    80005014:	c00080e7          	jalr	-1024(ra) # 80001c10 <proc_freepagetable>
  return -1;
    80005018:	557d                	li	a0,-1
    8000501a:	79fe                	ld	s3,504(sp)
    8000501c:	7a5e                	ld	s4,496(sp)
    8000501e:	7abe                	ld	s5,488(sp)
    80005020:	7b1e                	ld	s6,480(sp)
    80005022:	6bfe                	ld	s7,472(sp)
    80005024:	6c5e                	ld	s8,464(sp)
    80005026:	6cbe                	ld	s9,456(sp)
    80005028:	6d1e                	ld	s10,448(sp)
    8000502a:	7dfa                	ld	s11,440(sp)
    8000502c:	b5b1                	j	80004e78 <exec+0x8e>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000502e:	75f9                	lui	a1,0xffffe
    80005030:	95aa                	add	a1,a1,a0
    80005032:	855a                	mv	a0,s6
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	6f2080e7          	jalr	1778(ra) # 80001726 <uvmclear>
  stackbase = sp - PGSIZE;
    8000503c:	7bfd                	lui	s7,0xfffff
    8000503e:	9bd2                	add	s7,s7,s4
  for(argc = 0; argv[argc]; argc++) {
    80005040:	e0043783          	ld	a5,-512(s0)
    80005044:	6388                	ld	a0,0(a5)
  sp = sz;
    80005046:	8952                	mv	s2,s4
  for(argc = 0; argv[argc]; argc++) {
    80005048:	4481                	li	s1,0
    ustack[argc] = sp;
    8000504a:	e9040c93          	addi	s9,s0,-368
    if(argc >= MAXARG)
    8000504e:	02000c13          	li	s8,32
  for(argc = 0; argv[argc]; argc++) {
    80005052:	c135                	beqz	a0,800050b6 <exec+0x2cc>
    sp -= strlen(argv[argc]) + 1;
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	eb6080e7          	jalr	-330(ra) # 80000f0a <strlen>
    8000505c:	0015079b          	addiw	a5,a0,1
    80005060:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005064:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005068:	15796163          	bltu	s2,s7,800051aa <exec+0x3c0>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000506c:	e0043d83          	ld	s11,-512(s0)
    80005070:	000db983          	ld	s3,0(s11)
    80005074:	854e                	mv	a0,s3
    80005076:	ffffc097          	auipc	ra,0xffffc
    8000507a:	e94080e7          	jalr	-364(ra) # 80000f0a <strlen>
    8000507e:	0015069b          	addiw	a3,a0,1
    80005082:	864e                	mv	a2,s3
    80005084:	85ca                	mv	a1,s2
    80005086:	855a                	mv	a0,s6
    80005088:	ffffc097          	auipc	ra,0xffffc
    8000508c:	6d0080e7          	jalr	1744(ra) # 80001758 <copyout>
    80005090:	10054f63          	bltz	a0,800051ae <exec+0x3c4>
    ustack[argc] = sp;
    80005094:	00349793          	slli	a5,s1,0x3
    80005098:	97e6                	add	a5,a5,s9
    8000509a:	0127b023          	sd	s2,0(a5) # fffffffffffff000 <end+0xffffffff7ffdd290>
  for(argc = 0; argv[argc]; argc++) {
    8000509e:	0485                	addi	s1,s1,1
    800050a0:	008d8793          	addi	a5,s11,8
    800050a4:	e0f43023          	sd	a5,-512(s0)
    800050a8:	008db503          	ld	a0,8(s11)
    800050ac:	c509                	beqz	a0,800050b6 <exec+0x2cc>
    if(argc >= MAXARG)
    800050ae:	fb8493e3          	bne	s1,s8,80005054 <exec+0x26a>
  sz = sz1;
    800050b2:	89d2                	mv	s3,s4
    800050b4:	bfa1                	j	8000500c <exec+0x222>
  ustack[argc] = 0;
    800050b6:	00349793          	slli	a5,s1,0x3
    800050ba:	f9078793          	addi	a5,a5,-112
    800050be:	97a2                	add	a5,a5,s0
    800050c0:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800050c4:	00148693          	addi	a3,s1,1
    800050c8:	068e                	slli	a3,a3,0x3
    800050ca:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050ce:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800050d2:	89d2                	mv	s3,s4
  if(sp < stackbase)
    800050d4:	f3796ce3          	bltu	s2,s7,8000500c <exec+0x222>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050d8:	e9040613          	addi	a2,s0,-368
    800050dc:	85ca                	mv	a1,s2
    800050de:	855a                	mv	a0,s6
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	678080e7          	jalr	1656(ra) # 80001758 <copyout>
    800050e8:	f20542e3          	bltz	a0,8000500c <exec+0x222>
  p->trapframe->a1 = sp;
    800050ec:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800050f0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050f4:	df043783          	ld	a5,-528(s0)
    800050f8:	0007c703          	lbu	a4,0(a5)
    800050fc:	cf11                	beqz	a4,80005118 <exec+0x32e>
    800050fe:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005100:	02f00693          	li	a3,47
    80005104:	a029                	j	8000510e <exec+0x324>
  for(last=s=path; *s; s++)
    80005106:	0785                	addi	a5,a5,1
    80005108:	fff7c703          	lbu	a4,-1(a5)
    8000510c:	c711                	beqz	a4,80005118 <exec+0x32e>
    if(*s == '/')
    8000510e:	fed71ce3          	bne	a4,a3,80005106 <exec+0x31c>
      last = s+1;
    80005112:	def43823          	sd	a5,-528(s0)
    80005116:	bfc5                	j	80005106 <exec+0x31c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005118:	4641                	li	a2,16
    8000511a:	df043583          	ld	a1,-528(s0)
    8000511e:	158a8513          	addi	a0,s5,344
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	db2080e7          	jalr	-590(ra) # 80000ed4 <safestrcpy>
  oldpagetable = p->pagetable;
    8000512a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000512e:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005132:	054ab423          	sd	s4,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005136:	058ab783          	ld	a5,88(s5)
    8000513a:	e6843703          	ld	a4,-408(s0)
    8000513e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005140:	058ab783          	ld	a5,88(s5)
    80005144:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005148:	85ea                	mv	a1,s10
    8000514a:	ffffd097          	auipc	ra,0xffffd
    8000514e:	ac6080e7          	jalr	-1338(ra) # 80001c10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005152:	0004851b          	sext.w	a0,s1
    80005156:	79fe                	ld	s3,504(sp)
    80005158:	7a5e                	ld	s4,496(sp)
    8000515a:	7abe                	ld	s5,488(sp)
    8000515c:	7b1e                	ld	s6,480(sp)
    8000515e:	6bfe                	ld	s7,472(sp)
    80005160:	6c5e                	ld	s8,464(sp)
    80005162:	6cbe                	ld	s9,456(sp)
    80005164:	6d1e                	ld	s10,448(sp)
    80005166:	7dfa                	ld	s11,440(sp)
    80005168:	bb01                	j	80004e78 <exec+0x8e>
    8000516a:	7b1e                	ld	s6,480(sp)
    8000516c:	b9dd                	j	80004e62 <exec+0x78>
    8000516e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005172:	df843583          	ld	a1,-520(s0)
    80005176:	855a                	mv	a0,s6
    80005178:	ffffd097          	auipc	ra,0xffffd
    8000517c:	a98080e7          	jalr	-1384(ra) # 80001c10 <proc_freepagetable>
  if(ip){
    80005180:	79fe                	ld	s3,504(sp)
    80005182:	7abe                	ld	s5,488(sp)
    80005184:	7b1e                	ld	s6,480(sp)
    80005186:	6bfe                	ld	s7,472(sp)
    80005188:	6c5e                	ld	s8,464(sp)
    8000518a:	6cbe                	ld	s9,456(sp)
    8000518c:	6d1e                	ld	s10,448(sp)
    8000518e:	7dfa                	ld	s11,440(sp)
    80005190:	b9c9                	j	80004e62 <exec+0x78>
    80005192:	df243c23          	sd	s2,-520(s0)
    80005196:	bff1                	j	80005172 <exec+0x388>
    80005198:	df243c23          	sd	s2,-520(s0)
    8000519c:	bfd9                	j	80005172 <exec+0x388>
    8000519e:	df243c23          	sd	s2,-520(s0)
    800051a2:	bfc1                	j	80005172 <exec+0x388>
    800051a4:	df243c23          	sd	s2,-520(s0)
    800051a8:	b7e9                	j	80005172 <exec+0x388>
  sz = sz1;
    800051aa:	89d2                	mv	s3,s4
    800051ac:	b585                	j	8000500c <exec+0x222>
    800051ae:	89d2                	mv	s3,s4
    800051b0:	bdb1                	j	8000500c <exec+0x222>

00000000800051b2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051b2:	7179                	addi	sp,sp,-48
    800051b4:	f406                	sd	ra,40(sp)
    800051b6:	f022                	sd	s0,32(sp)
    800051b8:	ec26                	sd	s1,24(sp)
    800051ba:	e84a                	sd	s2,16(sp)
    800051bc:	1800                	addi	s0,sp,48
    800051be:	892e                	mv	s2,a1
    800051c0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800051c2:	fdc40593          	addi	a1,s0,-36
    800051c6:	ffffe097          	auipc	ra,0xffffe
    800051ca:	a5e080e7          	jalr	-1442(ra) # 80002c24 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051ce:	fdc42703          	lw	a4,-36(s0)
    800051d2:	47bd                	li	a5,15
    800051d4:	02e7eb63          	bltu	a5,a4,8000520a <argfd+0x58>
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	8d8080e7          	jalr	-1832(ra) # 80001ab0 <myproc>
    800051e0:	fdc42703          	lw	a4,-36(s0)
    800051e4:	01a70793          	addi	a5,a4,26
    800051e8:	078e                	slli	a5,a5,0x3
    800051ea:	953e                	add	a0,a0,a5
    800051ec:	611c                	ld	a5,0(a0)
    800051ee:	c385                	beqz	a5,8000520e <argfd+0x5c>
    return -1;
  if(pfd)
    800051f0:	00090463          	beqz	s2,800051f8 <argfd+0x46>
    *pfd = fd;
    800051f4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051f8:	4501                	li	a0,0
  if(pf)
    800051fa:	c091                	beqz	s1,800051fe <argfd+0x4c>
    *pf = f;
    800051fc:	e09c                	sd	a5,0(s1)
}
    800051fe:	70a2                	ld	ra,40(sp)
    80005200:	7402                	ld	s0,32(sp)
    80005202:	64e2                	ld	s1,24(sp)
    80005204:	6942                	ld	s2,16(sp)
    80005206:	6145                	addi	sp,sp,48
    80005208:	8082                	ret
    return -1;
    8000520a:	557d                	li	a0,-1
    8000520c:	bfcd                	j	800051fe <argfd+0x4c>
    8000520e:	557d                	li	a0,-1
    80005210:	b7fd                	j	800051fe <argfd+0x4c>

0000000080005212 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005212:	1101                	addi	sp,sp,-32
    80005214:	ec06                	sd	ra,24(sp)
    80005216:	e822                	sd	s0,16(sp)
    80005218:	e426                	sd	s1,8(sp)
    8000521a:	1000                	addi	s0,sp,32
    8000521c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000521e:	ffffd097          	auipc	ra,0xffffd
    80005222:	892080e7          	jalr	-1902(ra) # 80001ab0 <myproc>
    80005226:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005228:	0d050793          	addi	a5,a0,208
    8000522c:	4501                	li	a0,0
    8000522e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005230:	6398                	ld	a4,0(a5)
    80005232:	cb19                	beqz	a4,80005248 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005234:	2505                	addiw	a0,a0,1
    80005236:	07a1                	addi	a5,a5,8
    80005238:	fed51ce3          	bne	a0,a3,80005230 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000523c:	557d                	li	a0,-1
}
    8000523e:	60e2                	ld	ra,24(sp)
    80005240:	6442                	ld	s0,16(sp)
    80005242:	64a2                	ld	s1,8(sp)
    80005244:	6105                	addi	sp,sp,32
    80005246:	8082                	ret
      p->ofile[fd] = f;
    80005248:	01a50793          	addi	a5,a0,26
    8000524c:	078e                	slli	a5,a5,0x3
    8000524e:	963e                	add	a2,a2,a5
    80005250:	e204                	sd	s1,0(a2)
      return fd;
    80005252:	b7f5                	j	8000523e <fdalloc+0x2c>

0000000080005254 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005254:	715d                	addi	sp,sp,-80
    80005256:	e486                	sd	ra,72(sp)
    80005258:	e0a2                	sd	s0,64(sp)
    8000525a:	fc26                	sd	s1,56(sp)
    8000525c:	f84a                	sd	s2,48(sp)
    8000525e:	f44e                	sd	s3,40(sp)
    80005260:	ec56                	sd	s5,24(sp)
    80005262:	e85a                	sd	s6,16(sp)
    80005264:	0880                	addi	s0,sp,80
    80005266:	8b2e                	mv	s6,a1
    80005268:	89b2                	mv	s3,a2
    8000526a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000526c:	fb040593          	addi	a1,s0,-80
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	db8080e7          	jalr	-584(ra) # 80004028 <nameiparent>
    80005278:	84aa                	mv	s1,a0
    8000527a:	14050e63          	beqz	a0,800053d6 <create+0x182>
    return 0;

  ilock(dp);
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	5a8080e7          	jalr	1448(ra) # 80003826 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005286:	4601                	li	a2,0
    80005288:	fb040593          	addi	a1,s0,-80
    8000528c:	8526                	mv	a0,s1
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	a94080e7          	jalr	-1388(ra) # 80003d22 <dirlookup>
    80005296:	8aaa                	mv	s5,a0
    80005298:	c539                	beqz	a0,800052e6 <create+0x92>
    iunlockput(dp);
    8000529a:	8526                	mv	a0,s1
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	7f0080e7          	jalr	2032(ra) # 80003a8c <iunlockput>
    ilock(ip);
    800052a4:	8556                	mv	a0,s5
    800052a6:	ffffe097          	auipc	ra,0xffffe
    800052aa:	580080e7          	jalr	1408(ra) # 80003826 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052ae:	4789                	li	a5,2
    800052b0:	02fb1463          	bne	s6,a5,800052d8 <create+0x84>
    800052b4:	044ad783          	lhu	a5,68(s5)
    800052b8:	37f9                	addiw	a5,a5,-2
    800052ba:	17c2                	slli	a5,a5,0x30
    800052bc:	93c1                	srli	a5,a5,0x30
    800052be:	4705                	li	a4,1
    800052c0:	00f76c63          	bltu	a4,a5,800052d8 <create+0x84>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800052c4:	8556                	mv	a0,s5
    800052c6:	60a6                	ld	ra,72(sp)
    800052c8:	6406                	ld	s0,64(sp)
    800052ca:	74e2                	ld	s1,56(sp)
    800052cc:	7942                	ld	s2,48(sp)
    800052ce:	79a2                	ld	s3,40(sp)
    800052d0:	6ae2                	ld	s5,24(sp)
    800052d2:	6b42                	ld	s6,16(sp)
    800052d4:	6161                	addi	sp,sp,80
    800052d6:	8082                	ret
    iunlockput(ip);
    800052d8:	8556                	mv	a0,s5
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	7b2080e7          	jalr	1970(ra) # 80003a8c <iunlockput>
    return 0;
    800052e2:	4a81                	li	s5,0
    800052e4:	b7c5                	j	800052c4 <create+0x70>
    800052e6:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    800052e8:	85da                	mv	a1,s6
    800052ea:	4088                	lw	a0,0(s1)
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	396080e7          	jalr	918(ra) # 80003682 <ialloc>
    800052f4:	8a2a                	mv	s4,a0
    800052f6:	c531                	beqz	a0,80005342 <create+0xee>
  ilock(ip);
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	52e080e7          	jalr	1326(ra) # 80003826 <ilock>
  ip->major = major;
    80005300:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005304:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005308:	4905                	li	s2,1
    8000530a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000530e:	8552                	mv	a0,s4
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	44a080e7          	jalr	1098(ra) # 8000375a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005318:	032b0d63          	beq	s6,s2,80005352 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000531c:	004a2603          	lw	a2,4(s4)
    80005320:	fb040593          	addi	a1,s0,-80
    80005324:	8526                	mv	a0,s1
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	c22080e7          	jalr	-990(ra) # 80003f48 <dirlink>
    8000532e:	08054163          	bltz	a0,800053b0 <create+0x15c>
  iunlockput(dp);
    80005332:	8526                	mv	a0,s1
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	758080e7          	jalr	1880(ra) # 80003a8c <iunlockput>
  return ip;
    8000533c:	8ad2                	mv	s5,s4
    8000533e:	7a02                	ld	s4,32(sp)
    80005340:	b751                	j	800052c4 <create+0x70>
    iunlockput(dp);
    80005342:	8526                	mv	a0,s1
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	748080e7          	jalr	1864(ra) # 80003a8c <iunlockput>
    return 0;
    8000534c:	8ad2                	mv	s5,s4
    8000534e:	7a02                	ld	s4,32(sp)
    80005350:	bf95                	j	800052c4 <create+0x70>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005352:	004a2603          	lw	a2,4(s4)
    80005356:	00003597          	auipc	a1,0x3
    8000535a:	2a258593          	addi	a1,a1,674 # 800085f8 <etext+0x5f8>
    8000535e:	8552                	mv	a0,s4
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	be8080e7          	jalr	-1048(ra) # 80003f48 <dirlink>
    80005368:	04054463          	bltz	a0,800053b0 <create+0x15c>
    8000536c:	40d0                	lw	a2,4(s1)
    8000536e:	00003597          	auipc	a1,0x3
    80005372:	29258593          	addi	a1,a1,658 # 80008600 <etext+0x600>
    80005376:	8552                	mv	a0,s4
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	bd0080e7          	jalr	-1072(ra) # 80003f48 <dirlink>
    80005380:	02054863          	bltz	a0,800053b0 <create+0x15c>
  if(dirlink(dp, name, ip->inum) < 0)
    80005384:	004a2603          	lw	a2,4(s4)
    80005388:	fb040593          	addi	a1,s0,-80
    8000538c:	8526                	mv	a0,s1
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	bba080e7          	jalr	-1094(ra) # 80003f48 <dirlink>
    80005396:	00054d63          	bltz	a0,800053b0 <create+0x15c>
    dp->nlink++;  // for ".."
    8000539a:	04a4d783          	lhu	a5,74(s1)
    8000539e:	2785                	addiw	a5,a5,1
    800053a0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800053a4:	8526                	mv	a0,s1
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	3b4080e7          	jalr	948(ra) # 8000375a <iupdate>
    800053ae:	b751                	j	80005332 <create+0xde>
  ip->nlink = 0;
    800053b0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053b4:	8552                	mv	a0,s4
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	3a4080e7          	jalr	932(ra) # 8000375a <iupdate>
  iunlockput(ip);
    800053be:	8552                	mv	a0,s4
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	6cc080e7          	jalr	1740(ra) # 80003a8c <iunlockput>
  iunlockput(dp);
    800053c8:	8526                	mv	a0,s1
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	6c2080e7          	jalr	1730(ra) # 80003a8c <iunlockput>
  return 0;
    800053d2:	7a02                	ld	s4,32(sp)
    800053d4:	bdc5                	j	800052c4 <create+0x70>
    return 0;
    800053d6:	8aaa                	mv	s5,a0
    800053d8:	b5f5                	j	800052c4 <create+0x70>

00000000800053da <sys_dup>:
{
    800053da:	7179                	addi	sp,sp,-48
    800053dc:	f406                	sd	ra,40(sp)
    800053de:	f022                	sd	s0,32(sp)
    800053e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053e2:	fd840613          	addi	a2,s0,-40
    800053e6:	4581                	li	a1,0
    800053e8:	4501                	li	a0,0
    800053ea:	00000097          	auipc	ra,0x0
    800053ee:	dc8080e7          	jalr	-568(ra) # 800051b2 <argfd>
    return -1;
    800053f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053f4:	02054763          	bltz	a0,80005422 <sys_dup+0x48>
    800053f8:	ec26                	sd	s1,24(sp)
    800053fa:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    800053fc:	fd843903          	ld	s2,-40(s0)
    80005400:	854a                	mv	a0,s2
    80005402:	00000097          	auipc	ra,0x0
    80005406:	e10080e7          	jalr	-496(ra) # 80005212 <fdalloc>
    8000540a:	84aa                	mv	s1,a0
    return -1;
    8000540c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000540e:	00054f63          	bltz	a0,8000542c <sys_dup+0x52>
  filedup(f);
    80005412:	854a                	mv	a0,s2
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	27a080e7          	jalr	634(ra) # 8000468e <filedup>
  return fd;
    8000541c:	87a6                	mv	a5,s1
    8000541e:	64e2                	ld	s1,24(sp)
    80005420:	6942                	ld	s2,16(sp)
}
    80005422:	853e                	mv	a0,a5
    80005424:	70a2                	ld	ra,40(sp)
    80005426:	7402                	ld	s0,32(sp)
    80005428:	6145                	addi	sp,sp,48
    8000542a:	8082                	ret
    8000542c:	64e2                	ld	s1,24(sp)
    8000542e:	6942                	ld	s2,16(sp)
    80005430:	bfcd                	j	80005422 <sys_dup+0x48>

0000000080005432 <sys_read>:
{
    80005432:	7179                	addi	sp,sp,-48
    80005434:	f406                	sd	ra,40(sp)
    80005436:	f022                	sd	s0,32(sp)
    80005438:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000543a:	fd840593          	addi	a1,s0,-40
    8000543e:	4505                	li	a0,1
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	804080e7          	jalr	-2044(ra) # 80002c44 <argaddr>
  argint(2, &n);
    80005448:	fe440593          	addi	a1,s0,-28
    8000544c:	4509                	li	a0,2
    8000544e:	ffffd097          	auipc	ra,0xffffd
    80005452:	7d6080e7          	jalr	2006(ra) # 80002c24 <argint>
  if(argfd(0, 0, &f) < 0)
    80005456:	fe840613          	addi	a2,s0,-24
    8000545a:	4581                	li	a1,0
    8000545c:	4501                	li	a0,0
    8000545e:	00000097          	auipc	ra,0x0
    80005462:	d54080e7          	jalr	-684(ra) # 800051b2 <argfd>
    80005466:	87aa                	mv	a5,a0
    return -1;
    80005468:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000546a:	0007cc63          	bltz	a5,80005482 <sys_read+0x50>
  return fileread(f, p, n);
    8000546e:	fe442603          	lw	a2,-28(s0)
    80005472:	fd843583          	ld	a1,-40(s0)
    80005476:	fe843503          	ld	a0,-24(s0)
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	3ba080e7          	jalr	954(ra) # 80004834 <fileread>
}
    80005482:	70a2                	ld	ra,40(sp)
    80005484:	7402                	ld	s0,32(sp)
    80005486:	6145                	addi	sp,sp,48
    80005488:	8082                	ret

000000008000548a <sys_write>:
{
    8000548a:	7179                	addi	sp,sp,-48
    8000548c:	f406                	sd	ra,40(sp)
    8000548e:	f022                	sd	s0,32(sp)
    80005490:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005492:	fd840593          	addi	a1,s0,-40
    80005496:	4505                	li	a0,1
    80005498:	ffffd097          	auipc	ra,0xffffd
    8000549c:	7ac080e7          	jalr	1964(ra) # 80002c44 <argaddr>
  argint(2, &n);
    800054a0:	fe440593          	addi	a1,s0,-28
    800054a4:	4509                	li	a0,2
    800054a6:	ffffd097          	auipc	ra,0xffffd
    800054aa:	77e080e7          	jalr	1918(ra) # 80002c24 <argint>
  if(argfd(0, 0, &f) < 0)
    800054ae:	fe840613          	addi	a2,s0,-24
    800054b2:	4581                	li	a1,0
    800054b4:	4501                	li	a0,0
    800054b6:	00000097          	auipc	ra,0x0
    800054ba:	cfc080e7          	jalr	-772(ra) # 800051b2 <argfd>
    800054be:	87aa                	mv	a5,a0
    return -1;
    800054c0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054c2:	0007cc63          	bltz	a5,800054da <sys_write+0x50>
  return filewrite(f, p, n);
    800054c6:	fe442603          	lw	a2,-28(s0)
    800054ca:	fd843583          	ld	a1,-40(s0)
    800054ce:	fe843503          	ld	a0,-24(s0)
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	434080e7          	jalr	1076(ra) # 80004906 <filewrite>
}
    800054da:	70a2                	ld	ra,40(sp)
    800054dc:	7402                	ld	s0,32(sp)
    800054de:	6145                	addi	sp,sp,48
    800054e0:	8082                	ret

00000000800054e2 <sys_close>:
{
    800054e2:	1101                	addi	sp,sp,-32
    800054e4:	ec06                	sd	ra,24(sp)
    800054e6:	e822                	sd	s0,16(sp)
    800054e8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054ea:	fe040613          	addi	a2,s0,-32
    800054ee:	fec40593          	addi	a1,s0,-20
    800054f2:	4501                	li	a0,0
    800054f4:	00000097          	auipc	ra,0x0
    800054f8:	cbe080e7          	jalr	-834(ra) # 800051b2 <argfd>
    return -1;
    800054fc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054fe:	02054463          	bltz	a0,80005526 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005502:	ffffc097          	auipc	ra,0xffffc
    80005506:	5ae080e7          	jalr	1454(ra) # 80001ab0 <myproc>
    8000550a:	fec42783          	lw	a5,-20(s0)
    8000550e:	07e9                	addi	a5,a5,26
    80005510:	078e                	slli	a5,a5,0x3
    80005512:	953e                	add	a0,a0,a5
    80005514:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005518:	fe043503          	ld	a0,-32(s0)
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	1c4080e7          	jalr	452(ra) # 800046e0 <fileclose>
  return 0;
    80005524:	4781                	li	a5,0
}
    80005526:	853e                	mv	a0,a5
    80005528:	60e2                	ld	ra,24(sp)
    8000552a:	6442                	ld	s0,16(sp)
    8000552c:	6105                	addi	sp,sp,32
    8000552e:	8082                	ret

0000000080005530 <sys_fstat>:
{
    80005530:	1101                	addi	sp,sp,-32
    80005532:	ec06                	sd	ra,24(sp)
    80005534:	e822                	sd	s0,16(sp)
    80005536:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005538:	fe040593          	addi	a1,s0,-32
    8000553c:	4505                	li	a0,1
    8000553e:	ffffd097          	auipc	ra,0xffffd
    80005542:	706080e7          	jalr	1798(ra) # 80002c44 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005546:	fe840613          	addi	a2,s0,-24
    8000554a:	4581                	li	a1,0
    8000554c:	4501                	li	a0,0
    8000554e:	00000097          	auipc	ra,0x0
    80005552:	c64080e7          	jalr	-924(ra) # 800051b2 <argfd>
    80005556:	87aa                	mv	a5,a0
    return -1;
    80005558:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000555a:	0007ca63          	bltz	a5,8000556e <sys_fstat+0x3e>
  return filestat(f, st);
    8000555e:	fe043583          	ld	a1,-32(s0)
    80005562:	fe843503          	ld	a0,-24(s0)
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	258080e7          	jalr	600(ra) # 800047be <filestat>
}
    8000556e:	60e2                	ld	ra,24(sp)
    80005570:	6442                	ld	s0,16(sp)
    80005572:	6105                	addi	sp,sp,32
    80005574:	8082                	ret

0000000080005576 <sys_link>:
{
    80005576:	7169                	addi	sp,sp,-304
    80005578:	f606                	sd	ra,296(sp)
    8000557a:	f222                	sd	s0,288(sp)
    8000557c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000557e:	08000613          	li	a2,128
    80005582:	ed040593          	addi	a1,s0,-304
    80005586:	4501                	li	a0,0
    80005588:	ffffd097          	auipc	ra,0xffffd
    8000558c:	6dc080e7          	jalr	1756(ra) # 80002c64 <argstr>
    return -1;
    80005590:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005592:	12054663          	bltz	a0,800056be <sys_link+0x148>
    80005596:	08000613          	li	a2,128
    8000559a:	f5040593          	addi	a1,s0,-176
    8000559e:	4505                	li	a0,1
    800055a0:	ffffd097          	auipc	ra,0xffffd
    800055a4:	6c4080e7          	jalr	1732(ra) # 80002c64 <argstr>
    return -1;
    800055a8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055aa:	10054a63          	bltz	a0,800056be <sys_link+0x148>
    800055ae:	ee26                	sd	s1,280(sp)
  begin_op();
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	c60080e7          	jalr	-928(ra) # 80004210 <begin_op>
  if((ip = namei(old)) == 0){
    800055b8:	ed040513          	addi	a0,s0,-304
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	a4e080e7          	jalr	-1458(ra) # 8000400a <namei>
    800055c4:	84aa                	mv	s1,a0
    800055c6:	c949                	beqz	a0,80005658 <sys_link+0xe2>
  ilock(ip);
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	25e080e7          	jalr	606(ra) # 80003826 <ilock>
  if(ip->type == T_DIR){
    800055d0:	04449703          	lh	a4,68(s1)
    800055d4:	4785                	li	a5,1
    800055d6:	08f70863          	beq	a4,a5,80005666 <sys_link+0xf0>
    800055da:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    800055dc:	04a4d783          	lhu	a5,74(s1)
    800055e0:	2785                	addiw	a5,a5,1
    800055e2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	172080e7          	jalr	370(ra) # 8000375a <iupdate>
  iunlock(ip);
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	2fa080e7          	jalr	762(ra) # 800038ec <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055fa:	fd040593          	addi	a1,s0,-48
    800055fe:	f5040513          	addi	a0,s0,-176
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	a26080e7          	jalr	-1498(ra) # 80004028 <nameiparent>
    8000560a:	892a                	mv	s2,a0
    8000560c:	cd35                	beqz	a0,80005688 <sys_link+0x112>
  ilock(dp);
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	218080e7          	jalr	536(ra) # 80003826 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005616:	00092703          	lw	a4,0(s2)
    8000561a:	409c                	lw	a5,0(s1)
    8000561c:	06f71163          	bne	a4,a5,8000567e <sys_link+0x108>
    80005620:	40d0                	lw	a2,4(s1)
    80005622:	fd040593          	addi	a1,s0,-48
    80005626:	854a                	mv	a0,s2
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	920080e7          	jalr	-1760(ra) # 80003f48 <dirlink>
    80005630:	04054763          	bltz	a0,8000567e <sys_link+0x108>
  iunlockput(dp);
    80005634:	854a                	mv	a0,s2
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	456080e7          	jalr	1110(ra) # 80003a8c <iunlockput>
  iput(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	3a4080e7          	jalr	932(ra) # 800039e4 <iput>
  end_op();
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	c42080e7          	jalr	-958(ra) # 8000428a <end_op>
  return 0;
    80005650:	4781                	li	a5,0
    80005652:	64f2                	ld	s1,280(sp)
    80005654:	6952                	ld	s2,272(sp)
    80005656:	a0a5                	j	800056be <sys_link+0x148>
    end_op();
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	c32080e7          	jalr	-974(ra) # 8000428a <end_op>
    return -1;
    80005660:	57fd                	li	a5,-1
    80005662:	64f2                	ld	s1,280(sp)
    80005664:	a8a9                	j	800056be <sys_link+0x148>
    iunlockput(ip);
    80005666:	8526                	mv	a0,s1
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	424080e7          	jalr	1060(ra) # 80003a8c <iunlockput>
    end_op();
    80005670:	fffff097          	auipc	ra,0xfffff
    80005674:	c1a080e7          	jalr	-998(ra) # 8000428a <end_op>
    return -1;
    80005678:	57fd                	li	a5,-1
    8000567a:	64f2                	ld	s1,280(sp)
    8000567c:	a089                	j	800056be <sys_link+0x148>
    iunlockput(dp);
    8000567e:	854a                	mv	a0,s2
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	40c080e7          	jalr	1036(ra) # 80003a8c <iunlockput>
  ilock(ip);
    80005688:	8526                	mv	a0,s1
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	19c080e7          	jalr	412(ra) # 80003826 <ilock>
  ip->nlink--;
    80005692:	04a4d783          	lhu	a5,74(s1)
    80005696:	37fd                	addiw	a5,a5,-1
    80005698:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000569c:	8526                	mv	a0,s1
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	0bc080e7          	jalr	188(ra) # 8000375a <iupdate>
  iunlockput(ip);
    800056a6:	8526                	mv	a0,s1
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	3e4080e7          	jalr	996(ra) # 80003a8c <iunlockput>
  end_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	bda080e7          	jalr	-1062(ra) # 8000428a <end_op>
  return -1;
    800056b8:	57fd                	li	a5,-1
    800056ba:	64f2                	ld	s1,280(sp)
    800056bc:	6952                	ld	s2,272(sp)
}
    800056be:	853e                	mv	a0,a5
    800056c0:	70b2                	ld	ra,296(sp)
    800056c2:	7412                	ld	s0,288(sp)
    800056c4:	6155                	addi	sp,sp,304
    800056c6:	8082                	ret

00000000800056c8 <sys_unlink>:
{
    800056c8:	7111                	addi	sp,sp,-256
    800056ca:	fd86                	sd	ra,248(sp)
    800056cc:	f9a2                	sd	s0,240(sp)
    800056ce:	0200                	addi	s0,sp,256
  if(argstr(0, path, MAXPATH) < 0)
    800056d0:	08000613          	li	a2,128
    800056d4:	f2040593          	addi	a1,s0,-224
    800056d8:	4501                	li	a0,0
    800056da:	ffffd097          	auipc	ra,0xffffd
    800056de:	58a080e7          	jalr	1418(ra) # 80002c64 <argstr>
    800056e2:	1c054063          	bltz	a0,800058a2 <sys_unlink+0x1da>
    800056e6:	f5a6                	sd	s1,232(sp)
  begin_op();
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	b28080e7          	jalr	-1240(ra) # 80004210 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056f0:	fa040593          	addi	a1,s0,-96
    800056f4:	f2040513          	addi	a0,s0,-224
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	930080e7          	jalr	-1744(ra) # 80004028 <nameiparent>
    80005700:	84aa                	mv	s1,a0
    80005702:	c165                	beqz	a0,800057e2 <sys_unlink+0x11a>
  ilock(dp);
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	122080e7          	jalr	290(ra) # 80003826 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000570c:	00003597          	auipc	a1,0x3
    80005710:	eec58593          	addi	a1,a1,-276 # 800085f8 <etext+0x5f8>
    80005714:	fa040513          	addi	a0,s0,-96
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	5f0080e7          	jalr	1520(ra) # 80003d08 <namecmp>
    80005720:	16050263          	beqz	a0,80005884 <sys_unlink+0x1bc>
    80005724:	00003597          	auipc	a1,0x3
    80005728:	edc58593          	addi	a1,a1,-292 # 80008600 <etext+0x600>
    8000572c:	fa040513          	addi	a0,s0,-96
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	5d8080e7          	jalr	1496(ra) # 80003d08 <namecmp>
    80005738:	14050663          	beqz	a0,80005884 <sys_unlink+0x1bc>
    8000573c:	f1ca                	sd	s2,224(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000573e:	f1c40613          	addi	a2,s0,-228
    80005742:	fa040593          	addi	a1,s0,-96
    80005746:	8526                	mv	a0,s1
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	5da080e7          	jalr	1498(ra) # 80003d22 <dirlookup>
    80005750:	892a                	mv	s2,a0
    80005752:	12050863          	beqz	a0,80005882 <sys_unlink+0x1ba>
    80005756:	edce                	sd	s3,216(sp)
  ilock(ip);
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	0ce080e7          	jalr	206(ra) # 80003826 <ilock>
  if(ip->nlink < 1)
    80005760:	04a91783          	lh	a5,74(s2)
    80005764:	08f05663          	blez	a5,800057f0 <sys_unlink+0x128>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005768:	04491703          	lh	a4,68(s2)
    8000576c:	4785                	li	a5,1
    8000576e:	08f70b63          	beq	a4,a5,80005804 <sys_unlink+0x13c>
  memset(&de, 0, sizeof(de));
    80005772:	fb040993          	addi	s3,s0,-80
    80005776:	4641                	li	a2,16
    80005778:	4581                	li	a1,0
    8000577a:	854e                	mv	a0,s3
    8000577c:	ffffb097          	auipc	ra,0xffffb
    80005780:	602080e7          	jalr	1538(ra) # 80000d7e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005784:	4741                	li	a4,16
    80005786:	f1c42683          	lw	a3,-228(s0)
    8000578a:	864e                	mv	a2,s3
    8000578c:	4581                	li	a1,0
    8000578e:	8526                	mv	a0,s1
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	458080e7          	jalr	1112(ra) # 80003be8 <writei>
    80005798:	47c1                	li	a5,16
    8000579a:	0af51f63          	bne	a0,a5,80005858 <sys_unlink+0x190>
  if(ip->type == T_DIR){
    8000579e:	04491703          	lh	a4,68(s2)
    800057a2:	4785                	li	a5,1
    800057a4:	0cf70463          	beq	a4,a5,8000586c <sys_unlink+0x1a4>
  iunlockput(dp);
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	2e2080e7          	jalr	738(ra) # 80003a8c <iunlockput>
  ip->nlink--;
    800057b2:	04a95783          	lhu	a5,74(s2)
    800057b6:	37fd                	addiw	a5,a5,-1
    800057b8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057bc:	854a                	mv	a0,s2
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	f9c080e7          	jalr	-100(ra) # 8000375a <iupdate>
  iunlockput(ip);
    800057c6:	854a                	mv	a0,s2
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	2c4080e7          	jalr	708(ra) # 80003a8c <iunlockput>
  end_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	aba080e7          	jalr	-1350(ra) # 8000428a <end_op>
  return 0;
    800057d8:	4501                	li	a0,0
    800057da:	74ae                	ld	s1,232(sp)
    800057dc:	790e                	ld	s2,224(sp)
    800057de:	69ee                	ld	s3,216(sp)
    800057e0:	a86d                	j	8000589a <sys_unlink+0x1d2>
    end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	aa8080e7          	jalr	-1368(ra) # 8000428a <end_op>
    return -1;
    800057ea:	557d                	li	a0,-1
    800057ec:	74ae                	ld	s1,232(sp)
    800057ee:	a075                	j	8000589a <sys_unlink+0x1d2>
    800057f0:	e9d2                	sd	s4,208(sp)
    800057f2:	e5d6                	sd	s5,200(sp)
    panic("unlink: nlink < 1");
    800057f4:	00003517          	auipc	a0,0x3
    800057f8:	e1450513          	addi	a0,a0,-492 # 80008608 <etext+0x608>
    800057fc:	ffffb097          	auipc	ra,0xffffb
    80005800:	d64080e7          	jalr	-668(ra) # 80000560 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005804:	04c92703          	lw	a4,76(s2)
    80005808:	02000793          	li	a5,32
    8000580c:	f6e7f3e3          	bgeu	a5,a4,80005772 <sys_unlink+0xaa>
    80005810:	e9d2                	sd	s4,208(sp)
    80005812:	e5d6                	sd	s5,200(sp)
    80005814:	89be                	mv	s3,a5
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005816:	f0840a93          	addi	s5,s0,-248
    8000581a:	4a41                	li	s4,16
    8000581c:	8752                	mv	a4,s4
    8000581e:	86ce                	mv	a3,s3
    80005820:	8656                	mv	a2,s5
    80005822:	4581                	li	a1,0
    80005824:	854a                	mv	a0,s2
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	2bc080e7          	jalr	700(ra) # 80003ae2 <readi>
    8000582e:	01451d63          	bne	a0,s4,80005848 <sys_unlink+0x180>
    if(de.inum != 0)
    80005832:	f0845783          	lhu	a5,-248(s0)
    80005836:	eba5                	bnez	a5,800058a6 <sys_unlink+0x1de>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005838:	29c1                	addiw	s3,s3,16
    8000583a:	04c92783          	lw	a5,76(s2)
    8000583e:	fcf9efe3          	bltu	s3,a5,8000581c <sys_unlink+0x154>
    80005842:	6a4e                	ld	s4,208(sp)
    80005844:	6aae                	ld	s5,200(sp)
    80005846:	b735                	j	80005772 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005848:	00003517          	auipc	a0,0x3
    8000584c:	dd850513          	addi	a0,a0,-552 # 80008620 <etext+0x620>
    80005850:	ffffb097          	auipc	ra,0xffffb
    80005854:	d10080e7          	jalr	-752(ra) # 80000560 <panic>
    80005858:	e9d2                	sd	s4,208(sp)
    8000585a:	e5d6                	sd	s5,200(sp)
    panic("unlink: writei");
    8000585c:	00003517          	auipc	a0,0x3
    80005860:	ddc50513          	addi	a0,a0,-548 # 80008638 <etext+0x638>
    80005864:	ffffb097          	auipc	ra,0xffffb
    80005868:	cfc080e7          	jalr	-772(ra) # 80000560 <panic>
    dp->nlink--;
    8000586c:	04a4d783          	lhu	a5,74(s1)
    80005870:	37fd                	addiw	a5,a5,-1
    80005872:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005876:	8526                	mv	a0,s1
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	ee2080e7          	jalr	-286(ra) # 8000375a <iupdate>
    80005880:	b725                	j	800057a8 <sys_unlink+0xe0>
    80005882:	790e                	ld	s2,224(sp)
  iunlockput(dp);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	206080e7          	jalr	518(ra) # 80003a8c <iunlockput>
  end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	9fc080e7          	jalr	-1540(ra) # 8000428a <end_op>
  return -1;
    80005896:	557d                	li	a0,-1
    80005898:	74ae                	ld	s1,232(sp)
}
    8000589a:	70ee                	ld	ra,248(sp)
    8000589c:	744e                	ld	s0,240(sp)
    8000589e:	6111                	addi	sp,sp,256
    800058a0:	8082                	ret
    return -1;
    800058a2:	557d                	li	a0,-1
    800058a4:	bfdd                	j	8000589a <sys_unlink+0x1d2>
    iunlockput(ip);
    800058a6:	854a                	mv	a0,s2
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	1e4080e7          	jalr	484(ra) # 80003a8c <iunlockput>
    goto bad;
    800058b0:	790e                	ld	s2,224(sp)
    800058b2:	69ee                	ld	s3,216(sp)
    800058b4:	6a4e                	ld	s4,208(sp)
    800058b6:	6aae                	ld	s5,200(sp)
    800058b8:	b7f1                	j	80005884 <sys_unlink+0x1bc>

00000000800058ba <sys_open>:

uint64
sys_open(void)
{
    800058ba:	7131                	addi	sp,sp,-192
    800058bc:	fd06                	sd	ra,184(sp)
    800058be:	f922                	sd	s0,176(sp)
    800058c0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058c2:	f4c40593          	addi	a1,s0,-180
    800058c6:	4505                	li	a0,1
    800058c8:	ffffd097          	auipc	ra,0xffffd
    800058cc:	35c080e7          	jalr	860(ra) # 80002c24 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058d0:	08000613          	li	a2,128
    800058d4:	f5040593          	addi	a1,s0,-176
    800058d8:	4501                	li	a0,0
    800058da:	ffffd097          	auipc	ra,0xffffd
    800058de:	38a080e7          	jalr	906(ra) # 80002c64 <argstr>
    800058e2:	87aa                	mv	a5,a0
    return -1;
    800058e4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058e6:	0a07cf63          	bltz	a5,800059a4 <sys_open+0xea>
    800058ea:	f526                	sd	s1,168(sp)

  begin_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	924080e7          	jalr	-1756(ra) # 80004210 <begin_op>

  if(omode & O_CREATE){
    800058f4:	f4c42783          	lw	a5,-180(s0)
    800058f8:	2007f793          	andi	a5,a5,512
    800058fc:	cfdd                	beqz	a5,800059ba <sys_open+0x100>
    ip = create(path, T_FILE, 0, 0);
    800058fe:	4681                	li	a3,0
    80005900:	4601                	li	a2,0
    80005902:	4589                	li	a1,2
    80005904:	f5040513          	addi	a0,s0,-176
    80005908:	00000097          	auipc	ra,0x0
    8000590c:	94c080e7          	jalr	-1716(ra) # 80005254 <create>
    80005910:	84aa                	mv	s1,a0
    if(ip == 0){
    80005912:	cd49                	beqz	a0,800059ac <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005914:	04449703          	lh	a4,68(s1)
    80005918:	478d                	li	a5,3
    8000591a:	00f71763          	bne	a4,a5,80005928 <sys_open+0x6e>
    8000591e:	0464d703          	lhu	a4,70(s1)
    80005922:	47a5                	li	a5,9
    80005924:	0ee7e263          	bltu	a5,a4,80005a08 <sys_open+0x14e>
    80005928:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	cfa080e7          	jalr	-774(ra) # 80004624 <filealloc>
    80005932:	892a                	mv	s2,a0
    80005934:	cd65                	beqz	a0,80005a2c <sys_open+0x172>
    80005936:	ed4e                	sd	s3,152(sp)
    80005938:	00000097          	auipc	ra,0x0
    8000593c:	8da080e7          	jalr	-1830(ra) # 80005212 <fdalloc>
    80005940:	89aa                	mv	s3,a0
    80005942:	0c054f63          	bltz	a0,80005a20 <sys_open+0x166>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005946:	04449703          	lh	a4,68(s1)
    8000594a:	478d                	li	a5,3
    8000594c:	0ef70d63          	beq	a4,a5,80005a46 <sys_open+0x18c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005950:	4789                	li	a5,2
    80005952:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005956:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000595a:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    8000595e:	f4c42783          	lw	a5,-180(s0)
    80005962:	0017f713          	andi	a4,a5,1
    80005966:	00174713          	xori	a4,a4,1
    8000596a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000596e:	0037f713          	andi	a4,a5,3
    80005972:	00e03733          	snez	a4,a4
    80005976:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000597a:	4007f793          	andi	a5,a5,1024
    8000597e:	c791                	beqz	a5,8000598a <sys_open+0xd0>
    80005980:	04449703          	lh	a4,68(s1)
    80005984:	4789                	li	a5,2
    80005986:	0cf70763          	beq	a4,a5,80005a54 <sys_open+0x19a>
    itrunc(ip);
  }

  iunlock(ip);
    8000598a:	8526                	mv	a0,s1
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	f60080e7          	jalr	-160(ra) # 800038ec <iunlock>
  end_op();
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	8f6080e7          	jalr	-1802(ra) # 8000428a <end_op>

  return fd;
    8000599c:	854e                	mv	a0,s3
    8000599e:	74aa                	ld	s1,168(sp)
    800059a0:	790a                	ld	s2,160(sp)
    800059a2:	69ea                	ld	s3,152(sp)
}
    800059a4:	70ea                	ld	ra,184(sp)
    800059a6:	744a                	ld	s0,176(sp)
    800059a8:	6129                	addi	sp,sp,192
    800059aa:	8082                	ret
      end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	8de080e7          	jalr	-1826(ra) # 8000428a <end_op>
      return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	74aa                	ld	s1,168(sp)
    800059b8:	b7f5                	j	800059a4 <sys_open+0xea>
    if((ip = namei(path)) == 0){
    800059ba:	f5040513          	addi	a0,s0,-176
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	64c080e7          	jalr	1612(ra) # 8000400a <namei>
    800059c6:	84aa                	mv	s1,a0
    800059c8:	c90d                	beqz	a0,800059fa <sys_open+0x140>
    ilock(ip);
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	e5c080e7          	jalr	-420(ra) # 80003826 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059d2:	04449703          	lh	a4,68(s1)
    800059d6:	4785                	li	a5,1
    800059d8:	f2f71ee3          	bne	a4,a5,80005914 <sys_open+0x5a>
    800059dc:	f4c42783          	lw	a5,-180(s0)
    800059e0:	d7a1                	beqz	a5,80005928 <sys_open+0x6e>
      iunlockput(ip);
    800059e2:	8526                	mv	a0,s1
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	0a8080e7          	jalr	168(ra) # 80003a8c <iunlockput>
      end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	89e080e7          	jalr	-1890(ra) # 8000428a <end_op>
      return -1;
    800059f4:	557d                	li	a0,-1
    800059f6:	74aa                	ld	s1,168(sp)
    800059f8:	b775                	j	800059a4 <sys_open+0xea>
      end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	890080e7          	jalr	-1904(ra) # 8000428a <end_op>
      return -1;
    80005a02:	557d                	li	a0,-1
    80005a04:	74aa                	ld	s1,168(sp)
    80005a06:	bf79                	j	800059a4 <sys_open+0xea>
    iunlockput(ip);
    80005a08:	8526                	mv	a0,s1
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	082080e7          	jalr	130(ra) # 80003a8c <iunlockput>
    end_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	878080e7          	jalr	-1928(ra) # 8000428a <end_op>
    return -1;
    80005a1a:	557d                	li	a0,-1
    80005a1c:	74aa                	ld	s1,168(sp)
    80005a1e:	b759                	j	800059a4 <sys_open+0xea>
      fileclose(f);
    80005a20:	854a                	mv	a0,s2
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	cbe080e7          	jalr	-834(ra) # 800046e0 <fileclose>
    80005a2a:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    80005a2c:	8526                	mv	a0,s1
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	05e080e7          	jalr	94(ra) # 80003a8c <iunlockput>
    end_op();
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	854080e7          	jalr	-1964(ra) # 8000428a <end_op>
    return -1;
    80005a3e:	557d                	li	a0,-1
    80005a40:	74aa                	ld	s1,168(sp)
    80005a42:	790a                	ld	s2,160(sp)
    80005a44:	b785                	j	800059a4 <sys_open+0xea>
    f->type = FD_DEVICE;
    80005a46:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005a4a:	04649783          	lh	a5,70(s1)
    80005a4e:	02f91223          	sh	a5,36(s2)
    80005a52:	b721                	j	8000595a <sys_open+0xa0>
    itrunc(ip);
    80005a54:	8526                	mv	a0,s1
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	ee2080e7          	jalr	-286(ra) # 80003938 <itrunc>
    80005a5e:	b735                	j	8000598a <sys_open+0xd0>

0000000080005a60 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a60:	7175                	addi	sp,sp,-144
    80005a62:	e506                	sd	ra,136(sp)
    80005a64:	e122                	sd	s0,128(sp)
    80005a66:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	7a8080e7          	jalr	1960(ra) # 80004210 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a70:	08000613          	li	a2,128
    80005a74:	f7040593          	addi	a1,s0,-144
    80005a78:	4501                	li	a0,0
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	1ea080e7          	jalr	490(ra) # 80002c64 <argstr>
    80005a82:	02054963          	bltz	a0,80005ab4 <sys_mkdir+0x54>
    80005a86:	4681                	li	a3,0
    80005a88:	4601                	li	a2,0
    80005a8a:	4585                	li	a1,1
    80005a8c:	f7040513          	addi	a0,s0,-144
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	7c4080e7          	jalr	1988(ra) # 80005254 <create>
    80005a98:	cd11                	beqz	a0,80005ab4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	ff2080e7          	jalr	-14(ra) # 80003a8c <iunlockput>
  end_op();
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	7e8080e7          	jalr	2024(ra) # 8000428a <end_op>
  return 0;
    80005aaa:	4501                	li	a0,0
}
    80005aac:	60aa                	ld	ra,136(sp)
    80005aae:	640a                	ld	s0,128(sp)
    80005ab0:	6149                	addi	sp,sp,144
    80005ab2:	8082                	ret
    end_op();
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	7d6080e7          	jalr	2006(ra) # 8000428a <end_op>
    return -1;
    80005abc:	557d                	li	a0,-1
    80005abe:	b7fd                	j	80005aac <sys_mkdir+0x4c>

0000000080005ac0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ac0:	7135                	addi	sp,sp,-160
    80005ac2:	ed06                	sd	ra,152(sp)
    80005ac4:	e922                	sd	s0,144(sp)
    80005ac6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	748080e7          	jalr	1864(ra) # 80004210 <begin_op>
  argint(1, &major);
    80005ad0:	f6c40593          	addi	a1,s0,-148
    80005ad4:	4505                	li	a0,1
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	14e080e7          	jalr	334(ra) # 80002c24 <argint>
  argint(2, &minor);
    80005ade:	f6840593          	addi	a1,s0,-152
    80005ae2:	4509                	li	a0,2
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	140080e7          	jalr	320(ra) # 80002c24 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aec:	08000613          	li	a2,128
    80005af0:	f7040593          	addi	a1,s0,-144
    80005af4:	4501                	li	a0,0
    80005af6:	ffffd097          	auipc	ra,0xffffd
    80005afa:	16e080e7          	jalr	366(ra) # 80002c64 <argstr>
    80005afe:	02054b63          	bltz	a0,80005b34 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b02:	f6841683          	lh	a3,-152(s0)
    80005b06:	f6c41603          	lh	a2,-148(s0)
    80005b0a:	458d                	li	a1,3
    80005b0c:	f7040513          	addi	a0,s0,-144
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	744080e7          	jalr	1860(ra) # 80005254 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b18:	cd11                	beqz	a0,80005b34 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	f72080e7          	jalr	-142(ra) # 80003a8c <iunlockput>
  end_op();
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	768080e7          	jalr	1896(ra) # 8000428a <end_op>
  return 0;
    80005b2a:	4501                	li	a0,0
}
    80005b2c:	60ea                	ld	ra,152(sp)
    80005b2e:	644a                	ld	s0,144(sp)
    80005b30:	610d                	addi	sp,sp,160
    80005b32:	8082                	ret
    end_op();
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	756080e7          	jalr	1878(ra) # 8000428a <end_op>
    return -1;
    80005b3c:	557d                	li	a0,-1
    80005b3e:	b7fd                	j	80005b2c <sys_mknod+0x6c>

0000000080005b40 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b40:	7135                	addi	sp,sp,-160
    80005b42:	ed06                	sd	ra,152(sp)
    80005b44:	e922                	sd	s0,144(sp)
    80005b46:	e14a                	sd	s2,128(sp)
    80005b48:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b4a:	ffffc097          	auipc	ra,0xffffc
    80005b4e:	f66080e7          	jalr	-154(ra) # 80001ab0 <myproc>
    80005b52:	892a                	mv	s2,a0
  
  begin_op();
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	6bc080e7          	jalr	1724(ra) # 80004210 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b5c:	08000613          	li	a2,128
    80005b60:	f6040593          	addi	a1,s0,-160
    80005b64:	4501                	li	a0,0
    80005b66:	ffffd097          	auipc	ra,0xffffd
    80005b6a:	0fe080e7          	jalr	254(ra) # 80002c64 <argstr>
    80005b6e:	04054d63          	bltz	a0,80005bc8 <sys_chdir+0x88>
    80005b72:	e526                	sd	s1,136(sp)
    80005b74:	f6040513          	addi	a0,s0,-160
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	492080e7          	jalr	1170(ra) # 8000400a <namei>
    80005b80:	84aa                	mv	s1,a0
    80005b82:	c131                	beqz	a0,80005bc6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	ca2080e7          	jalr	-862(ra) # 80003826 <ilock>
  if(ip->type != T_DIR){
    80005b8c:	04449703          	lh	a4,68(s1)
    80005b90:	4785                	li	a5,1
    80005b92:	04f71163          	bne	a4,a5,80005bd4 <sys_chdir+0x94>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b96:	8526                	mv	a0,s1
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	d54080e7          	jalr	-684(ra) # 800038ec <iunlock>
  iput(p->cwd);
    80005ba0:	15093503          	ld	a0,336(s2)
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	e40080e7          	jalr	-448(ra) # 800039e4 <iput>
  end_op();
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	6de080e7          	jalr	1758(ra) # 8000428a <end_op>
  p->cwd = ip;
    80005bb4:	14993823          	sd	s1,336(s2)
  return 0;
    80005bb8:	4501                	li	a0,0
    80005bba:	64aa                	ld	s1,136(sp)
}
    80005bbc:	60ea                	ld	ra,152(sp)
    80005bbe:	644a                	ld	s0,144(sp)
    80005bc0:	690a                	ld	s2,128(sp)
    80005bc2:	610d                	addi	sp,sp,160
    80005bc4:	8082                	ret
    80005bc6:	64aa                	ld	s1,136(sp)
    end_op();
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	6c2080e7          	jalr	1730(ra) # 8000428a <end_op>
    return -1;
    80005bd0:	557d                	li	a0,-1
    80005bd2:	b7ed                	j	80005bbc <sys_chdir+0x7c>
    iunlockput(ip);
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	eb6080e7          	jalr	-330(ra) # 80003a8c <iunlockput>
    end_op();
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	6ac080e7          	jalr	1708(ra) # 8000428a <end_op>
    return -1;
    80005be6:	557d                	li	a0,-1
    80005be8:	64aa                	ld	s1,136(sp)
    80005bea:	bfc9                	j	80005bbc <sys_chdir+0x7c>

0000000080005bec <sys_exec>:

uint64
sys_exec(void)
{
    80005bec:	7105                	addi	sp,sp,-480
    80005bee:	ef86                	sd	ra,472(sp)
    80005bf0:	eba2                	sd	s0,464(sp)
    80005bf2:	1380                	addi	s0,sp,480
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005bf4:	e2840593          	addi	a1,s0,-472
    80005bf8:	4505                	li	a0,1
    80005bfa:	ffffd097          	auipc	ra,0xffffd
    80005bfe:	04a080e7          	jalr	74(ra) # 80002c44 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c02:	08000613          	li	a2,128
    80005c06:	f3040593          	addi	a1,s0,-208
    80005c0a:	4501                	li	a0,0
    80005c0c:	ffffd097          	auipc	ra,0xffffd
    80005c10:	058080e7          	jalr	88(ra) # 80002c64 <argstr>
    80005c14:	87aa                	mv	a5,a0
    return -1;
    80005c16:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c18:	0e07ce63          	bltz	a5,80005d14 <sys_exec+0x128>
    80005c1c:	e7a6                	sd	s1,456(sp)
    80005c1e:	e3ca                	sd	s2,448(sp)
    80005c20:	ff4e                	sd	s3,440(sp)
    80005c22:	fb52                	sd	s4,432(sp)
    80005c24:	f756                	sd	s5,424(sp)
    80005c26:	f35a                	sd	s6,416(sp)
    80005c28:	ef5e                	sd	s7,408(sp)
  }
  memset(argv, 0, sizeof(argv));
    80005c2a:	e3040a13          	addi	s4,s0,-464
    80005c2e:	10000613          	li	a2,256
    80005c32:	4581                	li	a1,0
    80005c34:	8552                	mv	a0,s4
    80005c36:	ffffb097          	auipc	ra,0xffffb
    80005c3a:	148080e7          	jalr	328(ra) # 80000d7e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c3e:	84d2                	mv	s1,s4
  memset(argv, 0, sizeof(argv));
    80005c40:	89d2                	mv	s3,s4
    80005c42:	4901                	li	s2,0
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c44:	e2040a93          	addi	s5,s0,-480
      break;
    }
    argv[i] = kalloc();
    if(argv[i] == 0)
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c48:	6b05                	lui	s6,0x1
    if(i >= NELEM(argv)){
    80005c4a:	02000b93          	li	s7,32
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c4e:	00391513          	slli	a0,s2,0x3
    80005c52:	85d6                	mv	a1,s5
    80005c54:	e2843783          	ld	a5,-472(s0)
    80005c58:	953e                	add	a0,a0,a5
    80005c5a:	ffffd097          	auipc	ra,0xffffd
    80005c5e:	f2c080e7          	jalr	-212(ra) # 80002b86 <fetchaddr>
    80005c62:	02054a63          	bltz	a0,80005c96 <sys_exec+0xaa>
    if(uarg == 0){
    80005c66:	e2043783          	ld	a5,-480(s0)
    80005c6a:	cbb1                	beqz	a5,80005cbe <sys_exec+0xd2>
    argv[i] = kalloc();
    80005c6c:	ffffb097          	auipc	ra,0xffffb
    80005c70:	ede080e7          	jalr	-290(ra) # 80000b4a <kalloc>
    80005c74:	85aa                	mv	a1,a0
    80005c76:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c7a:	cd11                	beqz	a0,80005c96 <sys_exec+0xaa>
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c7c:	865a                	mv	a2,s6
    80005c7e:	e2043503          	ld	a0,-480(s0)
    80005c82:	ffffd097          	auipc	ra,0xffffd
    80005c86:	f56080e7          	jalr	-170(ra) # 80002bd8 <fetchstr>
    80005c8a:	00054663          	bltz	a0,80005c96 <sys_exec+0xaa>
    if(i >= NELEM(argv)){
    80005c8e:	0905                	addi	s2,s2,1
    80005c90:	09a1                	addi	s3,s3,8
    80005c92:	fb791ee3          	bne	s2,s7,80005c4e <sys_exec+0x62>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c96:	100a0a13          	addi	s4,s4,256
    80005c9a:	6088                	ld	a0,0(s1)
    80005c9c:	c525                	beqz	a0,80005d04 <sys_exec+0x118>
    kfree(argv[i]);
    80005c9e:	ffffb097          	auipc	ra,0xffffb
    80005ca2:	dae080e7          	jalr	-594(ra) # 80000a4c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca6:	04a1                	addi	s1,s1,8
    80005ca8:	ff4499e3          	bne	s1,s4,80005c9a <sys_exec+0xae>
  return -1;
    80005cac:	557d                	li	a0,-1
    80005cae:	64be                	ld	s1,456(sp)
    80005cb0:	691e                	ld	s2,448(sp)
    80005cb2:	79fa                	ld	s3,440(sp)
    80005cb4:	7a5a                	ld	s4,432(sp)
    80005cb6:	7aba                	ld	s5,424(sp)
    80005cb8:	7b1a                	ld	s6,416(sp)
    80005cba:	6bfa                	ld	s7,408(sp)
    80005cbc:	a8a1                	j	80005d14 <sys_exec+0x128>
      argv[i] = 0;
    80005cbe:	0009079b          	sext.w	a5,s2
    80005cc2:	e3040593          	addi	a1,s0,-464
    80005cc6:	078e                	slli	a5,a5,0x3
    80005cc8:	97ae                	add	a5,a5,a1
    80005cca:	0007b023          	sd	zero,0(a5)
  int ret = exec(path, argv);
    80005cce:	f3040513          	addi	a0,s0,-208
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	118080e7          	jalr	280(ra) # 80004dea <exec>
    80005cda:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cdc:	100a0a13          	addi	s4,s4,256
    80005ce0:	6088                	ld	a0,0(s1)
    80005ce2:	c901                	beqz	a0,80005cf2 <sys_exec+0x106>
    kfree(argv[i]);
    80005ce4:	ffffb097          	auipc	ra,0xffffb
    80005ce8:	d68080e7          	jalr	-664(ra) # 80000a4c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cec:	04a1                	addi	s1,s1,8
    80005cee:	ff4499e3          	bne	s1,s4,80005ce0 <sys_exec+0xf4>
  return ret;
    80005cf2:	854a                	mv	a0,s2
    80005cf4:	64be                	ld	s1,456(sp)
    80005cf6:	691e                	ld	s2,448(sp)
    80005cf8:	79fa                	ld	s3,440(sp)
    80005cfa:	7a5a                	ld	s4,432(sp)
    80005cfc:	7aba                	ld	s5,424(sp)
    80005cfe:	7b1a                	ld	s6,416(sp)
    80005d00:	6bfa                	ld	s7,408(sp)
    80005d02:	a809                	j	80005d14 <sys_exec+0x128>
  return -1;
    80005d04:	557d                	li	a0,-1
    80005d06:	64be                	ld	s1,456(sp)
    80005d08:	691e                	ld	s2,448(sp)
    80005d0a:	79fa                	ld	s3,440(sp)
    80005d0c:	7a5a                	ld	s4,432(sp)
    80005d0e:	7aba                	ld	s5,424(sp)
    80005d10:	7b1a                	ld	s6,416(sp)
    80005d12:	6bfa                	ld	s7,408(sp)
}
    80005d14:	60fe                	ld	ra,472(sp)
    80005d16:	645e                	ld	s0,464(sp)
    80005d18:	613d                	addi	sp,sp,480
    80005d1a:	8082                	ret

0000000080005d1c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d1c:	7139                	addi	sp,sp,-64
    80005d1e:	fc06                	sd	ra,56(sp)
    80005d20:	f822                	sd	s0,48(sp)
    80005d22:	f426                	sd	s1,40(sp)
    80005d24:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d26:	ffffc097          	auipc	ra,0xffffc
    80005d2a:	d8a080e7          	jalr	-630(ra) # 80001ab0 <myproc>
    80005d2e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d30:	fd840593          	addi	a1,s0,-40
    80005d34:	4501                	li	a0,0
    80005d36:	ffffd097          	auipc	ra,0xffffd
    80005d3a:	f0e080e7          	jalr	-242(ra) # 80002c44 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d3e:	fc840593          	addi	a1,s0,-56
    80005d42:	fd040513          	addi	a0,s0,-48
    80005d46:	fffff097          	auipc	ra,0xfffff
    80005d4a:	d0e080e7          	jalr	-754(ra) # 80004a54 <pipealloc>
    return -1;
    80005d4e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d50:	0c054463          	bltz	a0,80005e18 <sys_pipe+0xfc>
  fd0 = -1;
    80005d54:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d58:	fd043503          	ld	a0,-48(s0)
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	4b6080e7          	jalr	1206(ra) # 80005212 <fdalloc>
    80005d64:	fca42223          	sw	a0,-60(s0)
    80005d68:	08054b63          	bltz	a0,80005dfe <sys_pipe+0xe2>
    80005d6c:	fc843503          	ld	a0,-56(s0)
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	4a2080e7          	jalr	1186(ra) # 80005212 <fdalloc>
    80005d78:	fca42023          	sw	a0,-64(s0)
    80005d7c:	06054863          	bltz	a0,80005dec <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d80:	4691                	li	a3,4
    80005d82:	fc440613          	addi	a2,s0,-60
    80005d86:	fd843583          	ld	a1,-40(s0)
    80005d8a:	68a8                	ld	a0,80(s1)
    80005d8c:	ffffc097          	auipc	ra,0xffffc
    80005d90:	9cc080e7          	jalr	-1588(ra) # 80001758 <copyout>
    80005d94:	02054063          	bltz	a0,80005db4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d98:	4691                	li	a3,4
    80005d9a:	fc040613          	addi	a2,s0,-64
    80005d9e:	fd843583          	ld	a1,-40(s0)
    80005da2:	95b6                	add	a1,a1,a3
    80005da4:	68a8                	ld	a0,80(s1)
    80005da6:	ffffc097          	auipc	ra,0xffffc
    80005daa:	9b2080e7          	jalr	-1614(ra) # 80001758 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dae:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005db0:	06055463          	bgez	a0,80005e18 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005db4:	fc442783          	lw	a5,-60(s0)
    80005db8:	07e9                	addi	a5,a5,26
    80005dba:	078e                	slli	a5,a5,0x3
    80005dbc:	97a6                	add	a5,a5,s1
    80005dbe:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dc2:	fc042783          	lw	a5,-64(s0)
    80005dc6:	07e9                	addi	a5,a5,26
    80005dc8:	078e                	slli	a5,a5,0x3
    80005dca:	94be                	add	s1,s1,a5
    80005dcc:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dd0:	fd043503          	ld	a0,-48(s0)
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	90c080e7          	jalr	-1780(ra) # 800046e0 <fileclose>
    fileclose(wf);
    80005ddc:	fc843503          	ld	a0,-56(s0)
    80005de0:	fffff097          	auipc	ra,0xfffff
    80005de4:	900080e7          	jalr	-1792(ra) # 800046e0 <fileclose>
    return -1;
    80005de8:	57fd                	li	a5,-1
    80005dea:	a03d                	j	80005e18 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005dec:	fc442783          	lw	a5,-60(s0)
    80005df0:	0007c763          	bltz	a5,80005dfe <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005df4:	07e9                	addi	a5,a5,26
    80005df6:	078e                	slli	a5,a5,0x3
    80005df8:	97a6                	add	a5,a5,s1
    80005dfa:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005dfe:	fd043503          	ld	a0,-48(s0)
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	8de080e7          	jalr	-1826(ra) # 800046e0 <fileclose>
    fileclose(wf);
    80005e0a:	fc843503          	ld	a0,-56(s0)
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	8d2080e7          	jalr	-1838(ra) # 800046e0 <fileclose>
    return -1;
    80005e16:	57fd                	li	a5,-1
}
    80005e18:	853e                	mv	a0,a5
    80005e1a:	70e2                	ld	ra,56(sp)
    80005e1c:	7442                	ld	s0,48(sp)
    80005e1e:	74a2                	ld	s1,40(sp)
    80005e20:	6121                	addi	sp,sp,64
    80005e22:	8082                	ret
	...

0000000080005e30 <kernelvec>:
    80005e30:	7111                	addi	sp,sp,-256
    80005e32:	e006                	sd	ra,0(sp)
    80005e34:	e40a                	sd	sp,8(sp)
    80005e36:	e80e                	sd	gp,16(sp)
    80005e38:	ec12                	sd	tp,24(sp)
    80005e3a:	f016                	sd	t0,32(sp)
    80005e3c:	f41a                	sd	t1,40(sp)
    80005e3e:	f81e                	sd	t2,48(sp)
    80005e40:	fc22                	sd	s0,56(sp)
    80005e42:	e0a6                	sd	s1,64(sp)
    80005e44:	e4aa                	sd	a0,72(sp)
    80005e46:	e8ae                	sd	a1,80(sp)
    80005e48:	ecb2                	sd	a2,88(sp)
    80005e4a:	f0b6                	sd	a3,96(sp)
    80005e4c:	f4ba                	sd	a4,104(sp)
    80005e4e:	f8be                	sd	a5,112(sp)
    80005e50:	fcc2                	sd	a6,120(sp)
    80005e52:	e146                	sd	a7,128(sp)
    80005e54:	e54a                	sd	s2,136(sp)
    80005e56:	e94e                	sd	s3,144(sp)
    80005e58:	ed52                	sd	s4,152(sp)
    80005e5a:	f156                	sd	s5,160(sp)
    80005e5c:	f55a                	sd	s6,168(sp)
    80005e5e:	f95e                	sd	s7,176(sp)
    80005e60:	fd62                	sd	s8,184(sp)
    80005e62:	e1e6                	sd	s9,192(sp)
    80005e64:	e5ea                	sd	s10,200(sp)
    80005e66:	e9ee                	sd	s11,208(sp)
    80005e68:	edf2                	sd	t3,216(sp)
    80005e6a:	f1f6                	sd	t4,224(sp)
    80005e6c:	f5fa                	sd	t5,232(sp)
    80005e6e:	f9fe                	sd	t6,240(sp)
    80005e70:	be3fc0ef          	jal	80002a52 <kerneltrap>
    80005e74:	6082                	ld	ra,0(sp)
    80005e76:	6122                	ld	sp,8(sp)
    80005e78:	61c2                	ld	gp,16(sp)
    80005e7a:	7282                	ld	t0,32(sp)
    80005e7c:	7322                	ld	t1,40(sp)
    80005e7e:	73c2                	ld	t2,48(sp)
    80005e80:	7462                	ld	s0,56(sp)
    80005e82:	6486                	ld	s1,64(sp)
    80005e84:	6526                	ld	a0,72(sp)
    80005e86:	65c6                	ld	a1,80(sp)
    80005e88:	6666                	ld	a2,88(sp)
    80005e8a:	7686                	ld	a3,96(sp)
    80005e8c:	7726                	ld	a4,104(sp)
    80005e8e:	77c6                	ld	a5,112(sp)
    80005e90:	7866                	ld	a6,120(sp)
    80005e92:	688a                	ld	a7,128(sp)
    80005e94:	692a                	ld	s2,136(sp)
    80005e96:	69ca                	ld	s3,144(sp)
    80005e98:	6a6a                	ld	s4,152(sp)
    80005e9a:	7a8a                	ld	s5,160(sp)
    80005e9c:	7b2a                	ld	s6,168(sp)
    80005e9e:	7bca                	ld	s7,176(sp)
    80005ea0:	7c6a                	ld	s8,184(sp)
    80005ea2:	6c8e                	ld	s9,192(sp)
    80005ea4:	6d2e                	ld	s10,200(sp)
    80005ea6:	6dce                	ld	s11,208(sp)
    80005ea8:	6e6e                	ld	t3,216(sp)
    80005eaa:	7e8e                	ld	t4,224(sp)
    80005eac:	7f2e                	ld	t5,232(sp)
    80005eae:	7fce                	ld	t6,240(sp)
    80005eb0:	6111                	addi	sp,sp,256
    80005eb2:	10200073          	sret
    80005eb6:	00000013          	nop
    80005eba:	00000013          	nop
    80005ebe:	0001                	nop

0000000080005ec0 <timervec>:
    80005ec0:	34051573          	csrrw	a0,mscratch,a0
    80005ec4:	e10c                	sd	a1,0(a0)
    80005ec6:	e510                	sd	a2,8(a0)
    80005ec8:	e914                	sd	a3,16(a0)
    80005eca:	6d0c                	ld	a1,24(a0)
    80005ecc:	7110                	ld	a2,32(a0)
    80005ece:	6194                	ld	a3,0(a1)
    80005ed0:	96b2                	add	a3,a3,a2
    80005ed2:	e194                	sd	a3,0(a1)
    80005ed4:	4589                	li	a1,2
    80005ed6:	14459073          	csrw	sip,a1
    80005eda:	6914                	ld	a3,16(a0)
    80005edc:	6510                	ld	a2,8(a0)
    80005ede:	610c                	ld	a1,0(a0)
    80005ee0:	34051573          	csrrw	a0,mscratch,a0
    80005ee4:	30200073          	mret
	...

0000000080005eea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eea:	1141                	addi	sp,sp,-16
    80005eec:	e406                	sd	ra,8(sp)
    80005eee:	e022                	sd	s0,0(sp)
    80005ef0:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ef2:	0c000737          	lui	a4,0xc000
    80005ef6:	4785                	li	a5,1
    80005ef8:	d71c                	sw	a5,40(a4)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005efa:	c35c                	sw	a5,4(a4)
}
    80005efc:	60a2                	ld	ra,8(sp)
    80005efe:	6402                	ld	s0,0(sp)
    80005f00:	0141                	addi	sp,sp,16
    80005f02:	8082                	ret

0000000080005f04 <plicinithart>:

void
plicinithart(void)
{
    80005f04:	1141                	addi	sp,sp,-16
    80005f06:	e406                	sd	ra,8(sp)
    80005f08:	e022                	sd	s0,0(sp)
    80005f0a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f0c:	ffffc097          	auipc	ra,0xffffc
    80005f10:	b70080e7          	jalr	-1168(ra) # 80001a7c <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f14:	0085171b          	slliw	a4,a0,0x8
    80005f18:	0c0027b7          	lui	a5,0xc002
    80005f1c:	97ba                	add	a5,a5,a4
    80005f1e:	40200713          	li	a4,1026
    80005f22:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f26:	00d5151b          	slliw	a0,a0,0xd
    80005f2a:	0c2017b7          	lui	a5,0xc201
    80005f2e:	97aa                	add	a5,a5,a0
    80005f30:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f34:	60a2                	ld	ra,8(sp)
    80005f36:	6402                	ld	s0,0(sp)
    80005f38:	0141                	addi	sp,sp,16
    80005f3a:	8082                	ret

0000000080005f3c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f3c:	1141                	addi	sp,sp,-16
    80005f3e:	e406                	sd	ra,8(sp)
    80005f40:	e022                	sd	s0,0(sp)
    80005f42:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f44:	ffffc097          	auipc	ra,0xffffc
    80005f48:	b38080e7          	jalr	-1224(ra) # 80001a7c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f4c:	00d5151b          	slliw	a0,a0,0xd
    80005f50:	0c2017b7          	lui	a5,0xc201
    80005f54:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f56:	43c8                	lw	a0,4(a5)
    80005f58:	60a2                	ld	ra,8(sp)
    80005f5a:	6402                	ld	s0,0(sp)
    80005f5c:	0141                	addi	sp,sp,16
    80005f5e:	8082                	ret

0000000080005f60 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f60:	1101                	addi	sp,sp,-32
    80005f62:	ec06                	sd	ra,24(sp)
    80005f64:	e822                	sd	s0,16(sp)
    80005f66:	e426                	sd	s1,8(sp)
    80005f68:	1000                	addi	s0,sp,32
    80005f6a:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f6c:	ffffc097          	auipc	ra,0xffffc
    80005f70:	b10080e7          	jalr	-1264(ra) # 80001a7c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f74:	00d5179b          	slliw	a5,a0,0xd
    80005f78:	0c201737          	lui	a4,0xc201
    80005f7c:	97ba                	add	a5,a5,a4
    80005f7e:	c3c4                	sw	s1,4(a5)
}
    80005f80:	60e2                	ld	ra,24(sp)
    80005f82:	6442                	ld	s0,16(sp)
    80005f84:	64a2                	ld	s1,8(sp)
    80005f86:	6105                	addi	sp,sp,32
    80005f88:	8082                	ret

0000000080005f8a <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f8a:	1141                	addi	sp,sp,-16
    80005f8c:	e406                	sd	ra,8(sp)
    80005f8e:	e022                	sd	s0,0(sp)
    80005f90:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f92:	479d                	li	a5,7
    80005f94:	04a7cc63          	blt	a5,a0,80005fec <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f98:	0001c797          	auipc	a5,0x1c
    80005f9c:	c9878793          	addi	a5,a5,-872 # 80021c30 <disk>
    80005fa0:	97aa                	add	a5,a5,a0
    80005fa2:	0187c783          	lbu	a5,24(a5)
    80005fa6:	ebb9                	bnez	a5,80005ffc <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fa8:	00451693          	slli	a3,a0,0x4
    80005fac:	0001c797          	auipc	a5,0x1c
    80005fb0:	c8478793          	addi	a5,a5,-892 # 80021c30 <disk>
    80005fb4:	6398                	ld	a4,0(a5)
    80005fb6:	9736                	add	a4,a4,a3
    80005fb8:	00073023          	sd	zero,0(a4) # c201000 <_entry-0x73dff000>
  disk.desc[i].len = 0;
    80005fbc:	6398                	ld	a4,0(a5)
    80005fbe:	9736                	add	a4,a4,a3
    80005fc0:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fc4:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fc8:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fcc:	97aa                	add	a5,a5,a0
    80005fce:	4705                	li	a4,1
    80005fd0:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005fd4:	0001c517          	auipc	a0,0x1c
    80005fd8:	c7450513          	addi	a0,a0,-908 # 80021c48 <disk+0x18>
    80005fdc:	ffffc097          	auipc	ra,0xffffc
    80005fe0:	1e2080e7          	jalr	482(ra) # 800021be <wakeup>
}
    80005fe4:	60a2                	ld	ra,8(sp)
    80005fe6:	6402                	ld	s0,0(sp)
    80005fe8:	0141                	addi	sp,sp,16
    80005fea:	8082                	ret
    panic("free_desc 1");
    80005fec:	00002517          	auipc	a0,0x2
    80005ff0:	65c50513          	addi	a0,a0,1628 # 80008648 <etext+0x648>
    80005ff4:	ffffa097          	auipc	ra,0xffffa
    80005ff8:	56c080e7          	jalr	1388(ra) # 80000560 <panic>
    panic("free_desc 2");
    80005ffc:	00002517          	auipc	a0,0x2
    80006000:	65c50513          	addi	a0,a0,1628 # 80008658 <etext+0x658>
    80006004:	ffffa097          	auipc	ra,0xffffa
    80006008:	55c080e7          	jalr	1372(ra) # 80000560 <panic>

000000008000600c <virtio_disk_init>:
{
    8000600c:	1101                	addi	sp,sp,-32
    8000600e:	ec06                	sd	ra,24(sp)
    80006010:	e822                	sd	s0,16(sp)
    80006012:	e426                	sd	s1,8(sp)
    80006014:	e04a                	sd	s2,0(sp)
    80006016:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006018:	00002597          	auipc	a1,0x2
    8000601c:	65058593          	addi	a1,a1,1616 # 80008668 <etext+0x668>
    80006020:	0001c517          	auipc	a0,0x1c
    80006024:	d3850513          	addi	a0,a0,-712 # 80021d58 <disk+0x128>
    80006028:	ffffb097          	auipc	ra,0xffffb
    8000602c:	bca080e7          	jalr	-1078(ra) # 80000bf2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006030:	100017b7          	lui	a5,0x10001
    80006034:	4398                	lw	a4,0(a5)
    80006036:	2701                	sext.w	a4,a4
    80006038:	747277b7          	lui	a5,0x74727
    8000603c:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006040:	16f71463          	bne	a4,a5,800061a8 <virtio_disk_init+0x19c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006044:	100017b7          	lui	a5,0x10001
    80006048:	43dc                	lw	a5,4(a5)
    8000604a:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000604c:	4709                	li	a4,2
    8000604e:	14e79d63          	bne	a5,a4,800061a8 <virtio_disk_init+0x19c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006052:	100017b7          	lui	a5,0x10001
    80006056:	479c                	lw	a5,8(a5)
    80006058:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000605a:	14e79763          	bne	a5,a4,800061a8 <virtio_disk_init+0x19c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	47d8                	lw	a4,12(a5)
    80006064:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006066:	554d47b7          	lui	a5,0x554d4
    8000606a:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000606e:	12f71d63          	bne	a4,a5,800061a8 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006072:	100017b7          	lui	a5,0x10001
    80006076:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607a:	4705                	li	a4,1
    8000607c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	470d                	li	a4,3
    80006080:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006082:	10001737          	lui	a4,0x10001
    80006086:	4b18                	lw	a4,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006088:	c7ffe6b7          	lui	a3,0xc7ffe
    8000608c:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9ef>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006090:	8f75                	and	a4,a4,a3
    80006092:	100016b7          	lui	a3,0x10001
    80006096:	d298                	sw	a4,32(a3)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006098:	472d                	li	a4,11
    8000609a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000609c:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    800060a0:	439c                	lw	a5,0(a5)
    800060a2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800060a6:	8ba1                	andi	a5,a5,8
    800060a8:	10078863          	beqz	a5,800061b8 <virtio_disk_init+0x1ac>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060ac:	100017b7          	lui	a5,0x10001
    800060b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800060b4:	43fc                	lw	a5,68(a5)
    800060b6:	2781                	sext.w	a5,a5
    800060b8:	10079863          	bnez	a5,800061c8 <virtio_disk_init+0x1bc>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060bc:	100017b7          	lui	a5,0x10001
    800060c0:	5bdc                	lw	a5,52(a5)
    800060c2:	2781                	sext.w	a5,a5
  if(max == 0)
    800060c4:	10078a63          	beqz	a5,800061d8 <virtio_disk_init+0x1cc>
  if(max < NUM)
    800060c8:	471d                	li	a4,7
    800060ca:	10f77f63          	bgeu	a4,a5,800061e8 <virtio_disk_init+0x1dc>
  disk.desc = kalloc();
    800060ce:	ffffb097          	auipc	ra,0xffffb
    800060d2:	a7c080e7          	jalr	-1412(ra) # 80000b4a <kalloc>
    800060d6:	0001c497          	auipc	s1,0x1c
    800060da:	b5a48493          	addi	s1,s1,-1190 # 80021c30 <disk>
    800060de:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	a6a080e7          	jalr	-1430(ra) # 80000b4a <kalloc>
    800060e8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060ea:	ffffb097          	auipc	ra,0xffffb
    800060ee:	a60080e7          	jalr	-1440(ra) # 80000b4a <kalloc>
    800060f2:	87aa                	mv	a5,a0
    800060f4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060f6:	6088                	ld	a0,0(s1)
    800060f8:	10050063          	beqz	a0,800061f8 <virtio_disk_init+0x1ec>
    800060fc:	0001c717          	auipc	a4,0x1c
    80006100:	b3c73703          	ld	a4,-1220(a4) # 80021c38 <disk+0x8>
    80006104:	cb75                	beqz	a4,800061f8 <virtio_disk_init+0x1ec>
    80006106:	cbed                	beqz	a5,800061f8 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80006108:	6605                	lui	a2,0x1
    8000610a:	4581                	li	a1,0
    8000610c:	ffffb097          	auipc	ra,0xffffb
    80006110:	c72080e7          	jalr	-910(ra) # 80000d7e <memset>
  memset(disk.avail, 0, PGSIZE);
    80006114:	0001c497          	auipc	s1,0x1c
    80006118:	b1c48493          	addi	s1,s1,-1252 # 80021c30 <disk>
    8000611c:	6605                	lui	a2,0x1
    8000611e:	4581                	li	a1,0
    80006120:	6488                	ld	a0,8(s1)
    80006122:	ffffb097          	auipc	ra,0xffffb
    80006126:	c5c080e7          	jalr	-932(ra) # 80000d7e <memset>
  memset(disk.used, 0, PGSIZE);
    8000612a:	6605                	lui	a2,0x1
    8000612c:	4581                	li	a1,0
    8000612e:	6888                	ld	a0,16(s1)
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	c4e080e7          	jalr	-946(ra) # 80000d7e <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006138:	100017b7          	lui	a5,0x10001
    8000613c:	4721                	li	a4,8
    8000613e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006140:	4098                	lw	a4,0(s1)
    80006142:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006146:	40d8                	lw	a4,4(s1)
    80006148:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000614c:	649c                	ld	a5,8(s1)
    8000614e:	0007869b          	sext.w	a3,a5
    80006152:	10001737          	lui	a4,0x10001
    80006156:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    8000615a:	9781                	srai	a5,a5,0x20
    8000615c:	08f72a23          	sw	a5,148(a4)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006160:	689c                	ld	a5,16(s1)
    80006162:	0007869b          	sext.w	a3,a5
    80006166:	0ad72023          	sw	a3,160(a4)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    8000616a:	9781                	srai	a5,a5,0x20
    8000616c:	0af72223          	sw	a5,164(a4)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006170:	4785                	li	a5,1
    80006172:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80006174:	00f48c23          	sb	a5,24(s1)
    80006178:	00f48ca3          	sb	a5,25(s1)
    8000617c:	00f48d23          	sb	a5,26(s1)
    80006180:	00f48da3          	sb	a5,27(s1)
    80006184:	00f48e23          	sb	a5,28(s1)
    80006188:	00f48ea3          	sb	a5,29(s1)
    8000618c:	00f48f23          	sb	a5,30(s1)
    80006190:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006194:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006198:	07272823          	sw	s2,112(a4)
}
    8000619c:	60e2                	ld	ra,24(sp)
    8000619e:	6442                	ld	s0,16(sp)
    800061a0:	64a2                	ld	s1,8(sp)
    800061a2:	6902                	ld	s2,0(sp)
    800061a4:	6105                	addi	sp,sp,32
    800061a6:	8082                	ret
    panic("could not find virtio disk");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	4d050513          	addi	a0,a0,1232 # 80008678 <etext+0x678>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	3b0080e7          	jalr	944(ra) # 80000560 <panic>
    panic("virtio disk FEATURES_OK unset");
    800061b8:	00002517          	auipc	a0,0x2
    800061bc:	4e050513          	addi	a0,a0,1248 # 80008698 <etext+0x698>
    800061c0:	ffffa097          	auipc	ra,0xffffa
    800061c4:	3a0080e7          	jalr	928(ra) # 80000560 <panic>
    panic("virtio disk should not be ready");
    800061c8:	00002517          	auipc	a0,0x2
    800061cc:	4f050513          	addi	a0,a0,1264 # 800086b8 <etext+0x6b8>
    800061d0:	ffffa097          	auipc	ra,0xffffa
    800061d4:	390080e7          	jalr	912(ra) # 80000560 <panic>
    panic("virtio disk has no queue 0");
    800061d8:	00002517          	auipc	a0,0x2
    800061dc:	50050513          	addi	a0,a0,1280 # 800086d8 <etext+0x6d8>
    800061e0:	ffffa097          	auipc	ra,0xffffa
    800061e4:	380080e7          	jalr	896(ra) # 80000560 <panic>
    panic("virtio disk max queue too short");
    800061e8:	00002517          	auipc	a0,0x2
    800061ec:	51050513          	addi	a0,a0,1296 # 800086f8 <etext+0x6f8>
    800061f0:	ffffa097          	auipc	ra,0xffffa
    800061f4:	370080e7          	jalr	880(ra) # 80000560 <panic>
    panic("virtio disk kalloc");
    800061f8:	00002517          	auipc	a0,0x2
    800061fc:	52050513          	addi	a0,a0,1312 # 80008718 <etext+0x718>
    80006200:	ffffa097          	auipc	ra,0xffffa
    80006204:	360080e7          	jalr	864(ra) # 80000560 <panic>

0000000080006208 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006208:	711d                	addi	sp,sp,-96
    8000620a:	ec86                	sd	ra,88(sp)
    8000620c:	e8a2                	sd	s0,80(sp)
    8000620e:	e4a6                	sd	s1,72(sp)
    80006210:	e0ca                	sd	s2,64(sp)
    80006212:	fc4e                	sd	s3,56(sp)
    80006214:	f852                	sd	s4,48(sp)
    80006216:	f456                	sd	s5,40(sp)
    80006218:	f05a                	sd	s6,32(sp)
    8000621a:	ec5e                	sd	s7,24(sp)
    8000621c:	e862                	sd	s8,16(sp)
    8000621e:	1080                	addi	s0,sp,96
    80006220:	89aa                	mv	s3,a0
    80006222:	8b2e                	mv	s6,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006224:	00c52b83          	lw	s7,12(a0)
    80006228:	001b9b9b          	slliw	s7,s7,0x1
    8000622c:	1b82                	slli	s7,s7,0x20
    8000622e:	020bdb93          	srli	s7,s7,0x20

  acquire(&disk.vdisk_lock);
    80006232:	0001c517          	auipc	a0,0x1c
    80006236:	b2650513          	addi	a0,a0,-1242 # 80021d58 <disk+0x128>
    8000623a:	ffffb097          	auipc	ra,0xffffb
    8000623e:	a4c080e7          	jalr	-1460(ra) # 80000c86 <acquire>
  for(int i = 0; i < NUM; i++){
    80006242:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006244:	0001ca97          	auipc	s5,0x1c
    80006248:	9eca8a93          	addi	s5,s5,-1556 # 80021c30 <disk>
  for(int i = 0; i < 3; i++){
    8000624c:	4a0d                	li	s4,3
    idx[i] = alloc_desc();
    8000624e:	5c7d                	li	s8,-1
    80006250:	a885                	j	800062c0 <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006252:	00fa8733          	add	a4,s5,a5
    80006256:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000625a:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000625c:	0207c563          	bltz	a5,80006286 <virtio_disk_rw+0x7e>
  for(int i = 0; i < 3; i++){
    80006260:	2905                	addiw	s2,s2,1
    80006262:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80006264:	07490263          	beq	s2,s4,800062c8 <virtio_disk_rw+0xc0>
    idx[i] = alloc_desc();
    80006268:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000626a:	0001c717          	auipc	a4,0x1c
    8000626e:	9c670713          	addi	a4,a4,-1594 # 80021c30 <disk>
    80006272:	4781                	li	a5,0
    if(disk.free[i]){
    80006274:	01874683          	lbu	a3,24(a4)
    80006278:	fee9                	bnez	a3,80006252 <virtio_disk_rw+0x4a>
  for(int i = 0; i < NUM; i++){
    8000627a:	2785                	addiw	a5,a5,1
    8000627c:	0705                	addi	a4,a4,1
    8000627e:	fe979be3          	bne	a5,s1,80006274 <virtio_disk_rw+0x6c>
    idx[i] = alloc_desc();
    80006282:	0185a023          	sw	s8,0(a1)
      for(int j = 0; j < i; j++)
    80006286:	03205163          	blez	s2,800062a8 <virtio_disk_rw+0xa0>
        free_desc(idx[j]);
    8000628a:	fa042503          	lw	a0,-96(s0)
    8000628e:	00000097          	auipc	ra,0x0
    80006292:	cfc080e7          	jalr	-772(ra) # 80005f8a <free_desc>
      for(int j = 0; j < i; j++)
    80006296:	4785                	li	a5,1
    80006298:	0127d863          	bge	a5,s2,800062a8 <virtio_disk_rw+0xa0>
        free_desc(idx[j]);
    8000629c:	fa442503          	lw	a0,-92(s0)
    800062a0:	00000097          	auipc	ra,0x0
    800062a4:	cea080e7          	jalr	-790(ra) # 80005f8a <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062a8:	0001c597          	auipc	a1,0x1c
    800062ac:	ab058593          	addi	a1,a1,-1360 # 80021d58 <disk+0x128>
    800062b0:	0001c517          	auipc	a0,0x1c
    800062b4:	99850513          	addi	a0,a0,-1640 # 80021c48 <disk+0x18>
    800062b8:	ffffc097          	auipc	ra,0xffffc
    800062bc:	ea2080e7          	jalr	-350(ra) # 8000215a <sleep>
  for(int i = 0; i < 3; i++){
    800062c0:	fa040613          	addi	a2,s0,-96
    800062c4:	4901                	li	s2,0
    800062c6:	b74d                	j	80006268 <virtio_disk_rw+0x60>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c8:	fa042503          	lw	a0,-96(s0)
    800062cc:	00451693          	slli	a3,a0,0x4

  if(write)
    800062d0:	0001c797          	auipc	a5,0x1c
    800062d4:	96078793          	addi	a5,a5,-1696 # 80021c30 <disk>
    800062d8:	00a50713          	addi	a4,a0,10
    800062dc:	0712                	slli	a4,a4,0x4
    800062de:	973e                	add	a4,a4,a5
    800062e0:	01603633          	snez	a2,s6
    800062e4:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062e6:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800062ea:	01773823          	sd	s7,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062ee:	6398                	ld	a4,0(a5)
    800062f0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062f2:	0a868613          	addi	a2,a3,168 # 100010a8 <_entry-0x6fffef58>
    800062f6:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062f8:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062fa:	6390                	ld	a2,0(a5)
    800062fc:	00d605b3          	add	a1,a2,a3
    80006300:	4741                	li	a4,16
    80006302:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006304:	4805                	li	a6,1
    80006306:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    8000630a:	fa442703          	lw	a4,-92(s0)
    8000630e:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006312:	0712                	slli	a4,a4,0x4
    80006314:	963a                	add	a2,a2,a4
    80006316:	05898593          	addi	a1,s3,88
    8000631a:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000631c:	0007b883          	ld	a7,0(a5)
    80006320:	9746                	add	a4,a4,a7
    80006322:	40000613          	li	a2,1024
    80006326:	c710                	sw	a2,8(a4)
  if(write)
    80006328:	001b3613          	seqz	a2,s6
    8000632c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006330:	01066633          	or	a2,a2,a6
    80006334:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006338:	fa842583          	lw	a1,-88(s0)
    8000633c:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006340:	00250613          	addi	a2,a0,2
    80006344:	0612                	slli	a2,a2,0x4
    80006346:	963e                	add	a2,a2,a5
    80006348:	577d                	li	a4,-1
    8000634a:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000634e:	0592                	slli	a1,a1,0x4
    80006350:	98ae                	add	a7,a7,a1
    80006352:	03068713          	addi	a4,a3,48
    80006356:	973e                	add	a4,a4,a5
    80006358:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    8000635c:	6398                	ld	a4,0(a5)
    8000635e:	972e                	add	a4,a4,a1
    80006360:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006364:	4689                	li	a3,2
    80006366:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    8000636a:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000636e:	0109a223          	sw	a6,4(s3)
  disk.info[idx[0]].b = b;
    80006372:	01363423          	sd	s3,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006376:	6794                	ld	a3,8(a5)
    80006378:	0026d703          	lhu	a4,2(a3)
    8000637c:	8b1d                	andi	a4,a4,7
    8000637e:	0706                	slli	a4,a4,0x1
    80006380:	96ba                	add	a3,a3,a4
    80006382:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006386:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000638a:	6798                	ld	a4,8(a5)
    8000638c:	00275783          	lhu	a5,2(a4)
    80006390:	2785                	addiw	a5,a5,1
    80006392:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006396:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000639a:	100017b7          	lui	a5,0x10001
    8000639e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063a2:	0049a783          	lw	a5,4(s3)
    sleep(b, &disk.vdisk_lock);
    800063a6:	0001c917          	auipc	s2,0x1c
    800063aa:	9b290913          	addi	s2,s2,-1614 # 80021d58 <disk+0x128>
  while(b->disk == 1) {
    800063ae:	84c2                	mv	s1,a6
    800063b0:	01079c63          	bne	a5,a6,800063c8 <virtio_disk_rw+0x1c0>
    sleep(b, &disk.vdisk_lock);
    800063b4:	85ca                	mv	a1,s2
    800063b6:	854e                	mv	a0,s3
    800063b8:	ffffc097          	auipc	ra,0xffffc
    800063bc:	da2080e7          	jalr	-606(ra) # 8000215a <sleep>
  while(b->disk == 1) {
    800063c0:	0049a783          	lw	a5,4(s3)
    800063c4:	fe9788e3          	beq	a5,s1,800063b4 <virtio_disk_rw+0x1ac>
  }

  disk.info[idx[0]].b = 0;
    800063c8:	fa042903          	lw	s2,-96(s0)
    800063cc:	00290713          	addi	a4,s2,2
    800063d0:	0712                	slli	a4,a4,0x4
    800063d2:	0001c797          	auipc	a5,0x1c
    800063d6:	85e78793          	addi	a5,a5,-1954 # 80021c30 <disk>
    800063da:	97ba                	add	a5,a5,a4
    800063dc:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063e0:	0001c997          	auipc	s3,0x1c
    800063e4:	85098993          	addi	s3,s3,-1968 # 80021c30 <disk>
    800063e8:	00491713          	slli	a4,s2,0x4
    800063ec:	0009b783          	ld	a5,0(s3)
    800063f0:	97ba                	add	a5,a5,a4
    800063f2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063f6:	854a                	mv	a0,s2
    800063f8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063fc:	00000097          	auipc	ra,0x0
    80006400:	b8e080e7          	jalr	-1138(ra) # 80005f8a <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006404:	8885                	andi	s1,s1,1
    80006406:	f0ed                	bnez	s1,800063e8 <virtio_disk_rw+0x1e0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006408:	0001c517          	auipc	a0,0x1c
    8000640c:	95050513          	addi	a0,a0,-1712 # 80021d58 <disk+0x128>
    80006410:	ffffb097          	auipc	ra,0xffffb
    80006414:	926080e7          	jalr	-1754(ra) # 80000d36 <release>
}
    80006418:	60e6                	ld	ra,88(sp)
    8000641a:	6446                	ld	s0,80(sp)
    8000641c:	64a6                	ld	s1,72(sp)
    8000641e:	6906                	ld	s2,64(sp)
    80006420:	79e2                	ld	s3,56(sp)
    80006422:	7a42                	ld	s4,48(sp)
    80006424:	7aa2                	ld	s5,40(sp)
    80006426:	7b02                	ld	s6,32(sp)
    80006428:	6be2                	ld	s7,24(sp)
    8000642a:	6c42                	ld	s8,16(sp)
    8000642c:	6125                	addi	sp,sp,96
    8000642e:	8082                	ret

0000000080006430 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006430:	1101                	addi	sp,sp,-32
    80006432:	ec06                	sd	ra,24(sp)
    80006434:	e822                	sd	s0,16(sp)
    80006436:	e426                	sd	s1,8(sp)
    80006438:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000643a:	0001b497          	auipc	s1,0x1b
    8000643e:	7f648493          	addi	s1,s1,2038 # 80021c30 <disk>
    80006442:	0001c517          	auipc	a0,0x1c
    80006446:	91650513          	addi	a0,a0,-1770 # 80021d58 <disk+0x128>
    8000644a:	ffffb097          	auipc	ra,0xffffb
    8000644e:	83c080e7          	jalr	-1988(ra) # 80000c86 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006452:	100017b7          	lui	a5,0x10001
    80006456:	53bc                	lw	a5,96(a5)
    80006458:	8b8d                	andi	a5,a5,3
    8000645a:	10001737          	lui	a4,0x10001
    8000645e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006460:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006464:	689c                	ld	a5,16(s1)
    80006466:	0204d703          	lhu	a4,32(s1)
    8000646a:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    8000646e:	04f70863          	beq	a4,a5,800064be <virtio_disk_intr+0x8e>
    __sync_synchronize();
    80006472:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006476:	6898                	ld	a4,16(s1)
    80006478:	0204d783          	lhu	a5,32(s1)
    8000647c:	8b9d                	andi	a5,a5,7
    8000647e:	078e                	slli	a5,a5,0x3
    80006480:	97ba                	add	a5,a5,a4
    80006482:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006484:	00278713          	addi	a4,a5,2
    80006488:	0712                	slli	a4,a4,0x4
    8000648a:	9726                	add	a4,a4,s1
    8000648c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006490:	e721                	bnez	a4,800064d8 <virtio_disk_intr+0xa8>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006492:	0789                	addi	a5,a5,2
    80006494:	0792                	slli	a5,a5,0x4
    80006496:	97a6                	add	a5,a5,s1
    80006498:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000649a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000649e:	ffffc097          	auipc	ra,0xffffc
    800064a2:	d20080e7          	jalr	-736(ra) # 800021be <wakeup>

    disk.used_idx += 1;
    800064a6:	0204d783          	lhu	a5,32(s1)
    800064aa:	2785                	addiw	a5,a5,1
    800064ac:	17c2                	slli	a5,a5,0x30
    800064ae:	93c1                	srli	a5,a5,0x30
    800064b0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064b4:	6898                	ld	a4,16(s1)
    800064b6:	00275703          	lhu	a4,2(a4)
    800064ba:	faf71ce3          	bne	a4,a5,80006472 <virtio_disk_intr+0x42>
  }

  release(&disk.vdisk_lock);
    800064be:	0001c517          	auipc	a0,0x1c
    800064c2:	89a50513          	addi	a0,a0,-1894 # 80021d58 <disk+0x128>
    800064c6:	ffffb097          	auipc	ra,0xffffb
    800064ca:	870080e7          	jalr	-1936(ra) # 80000d36 <release>
}
    800064ce:	60e2                	ld	ra,24(sp)
    800064d0:	6442                	ld	s0,16(sp)
    800064d2:	64a2                	ld	s1,8(sp)
    800064d4:	6105                	addi	sp,sp,32
    800064d6:	8082                	ret
      panic("virtio_disk_intr status");
    800064d8:	00002517          	auipc	a0,0x2
    800064dc:	25850513          	addi	a0,a0,600 # 80008730 <etext+0x730>
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	080080e7          	jalr	128(ra) # 80000560 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
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
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
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
