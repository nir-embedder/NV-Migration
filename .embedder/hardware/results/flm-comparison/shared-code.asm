Identical KI/KJ PrgCode; image-local addresses, not runtime VAs.

FUNCTION Init symbol=0x1 code=0x0 size=0xcc
00000000  40f20020   movw     r0, #0x200
00000004  6ff0ff01   mvn      r1, #0xff
00000008  c4f20000   movt     r0, #0x4000
0000000c  5922       movs     r2, #0x59
0000000e  4250       str      r2, [r0, r1]
00000010  1622       movs     r2, #0x16
00000012  4250       str      r2, [r0, r1]
00000014  8822       movs     r2, #0x88
00000016  4250       str      r2, [r0, r1]
00000018  4158       ldr      r1, [r0, r1]
0000001a  0129       cmp      r1, #1
0000001c  54d1       bne      #0xc8
0000001e  016d       ldr      r1, [r0, #0x50]
00000020  c906       lsls     r1, r1, #0x1b
00000022  06d4       bmi      #0x32
00000024  0168       ldr      r1, [r0]
00000026  41f00401   orr      r1, r1, #4
0000002a  0160       str      r1, [r0]
0000002c  016d       ldr      r1, [r0, #0x50]
0000002e  c906       lsls     r1, r1, #0x1b
00000030  fcd5       bpl      #0x2c
00000032  0169       ldr      r1, [r0, #0x10]
00000034  01f00701   and      r1, r1, #7
00000038  0729       cmp      r1, #7
0000003a  03d0       beq      #0x44
0000003c  0169       ldr      r1, [r0, #0x10]
0000003e  41f00701   orr      r1, r1, #7
00000042  0161       str      r1, [r0, #0x10]
00000044  0021       movs     r1, #0
00000046  0162       str      r1, [r0, #0x20]
00000048  4168       ldr      r1, [r0, #4]
0000004a  44f20402   movw     r2, #0x4004
0000004e  1143       orrs     r1, r2
00000050  4160       str      r1, [r0, #4]
00000052  4cf20000   movw     r0, #0xc000
00000056  c4f20000   movt     r0, #0x4000
0000005a  e921       movs     r1, #0xe9
0000005c  0160       str      r1, [r0]
0000005e  0168       ldr      r1, [r0]
00000060  01f0a901   and      r1, r1, #0xa9
00000064  a929       cmp      r1, #0xa9
00000066  2fd1       bne      #0xc8
00000068  0221       movs     r1, #2
0000006a  c164       str      r1, [r0, #0x4c]
0000006c  4ff6fc70   movw     r0, #0xfffc
00000070  c4f20000   movt     r0, #0x4000
00000074  0068       ldr      r0, [r0]
00000076  20b3       cbz      r0, #0xc2
00000078  4ff20000   movw     r0, #0xf000
0000007c  c4f20000   movt     r0, #0x4000
00000080  4921       movs     r1, #0x49
00000082  0160       str      r1, [r0]
00000084  0168       ldr      r1, [r0]
00000086  01f00901   and      r1, r1, #9
0000008a  0929       cmp      r1, #9
0000008c  1cd1       bne      #0xc8
0000008e  016c       ldr      r1, [r0, #0x40]
00000090  0905       lsls     r1, r1, #0x14
00000092  14d5       bpl      #0xbe
00000094  3321       movs     r1, #0x33
00000096  c160       str      r1, [r0, #0xc]
00000098  4ef20001   movw     r1, #0xe000
0000009c  c0f62171   movt     r1, #0xf21
000000a0  4160       str      r1, [r0, #4]
000000a2  0121       movs     r1, #1
000000a4  0161       str      r1, [r0, #0x10]
000000a6  bff36f8f   isb      sy
000000aa  00bf       nop      
000000ac  016c       ldr      r1, [r0, #0x40]
000000ae  c907       lsls     r1, r1, #0x1f
000000b0  fcd1       bne      #0xac
000000b2  0168       ldr      r1, [r0]
000000b4  4a06       lsls     r2, r1, #0x19
000000b6  06d4       bmi      #0xc6
000000b8  016c       ldr      r1, [r0, #0x40]
000000ba  8905       lsls     r1, r1, #0x16
000000bc  fcd4       bmi      #0xb8
000000be  0221       movs     r1, #2
000000c0  c164       str      r1, [r0, #0x4c]
000000c2  0020       movs     r0, #0
000000c4  7047       bx       lr
000000c6  0160       str      r1, [r0]
000000c8  0120       movs     r0, #1
000000ca  7047       bx       lr

FUNCTION UnInit symbol=0xcd code=0xcc size=0x36
000000cc  4cf20000   movw     r0, #0xc000
000000d0  c4f20000   movt     r0, #0x4000
000000d4  016c       ldr      r1, [r0, #0x40]
000000d6  c907       lsls     r1, r1, #0x1f
000000d8  fcd1       bne      #0xd4
000000da  0021       movs     r1, #0
000000dc  0160       str      r1, [r0]
000000de  4ff6fc70   movw     r0, #0xfffc
000000e2  c4f20000   movt     r0, #0x4000
000000e6  0068       ldr      r0, [r0]
000000e8  48b1       cbz      r0, #0xfe
000000ea  4ff20000   movw     r0, #0xf000
000000ee  c4f20000   movt     r0, #0x4000
000000f2  00bf       nop      
000000f4  016c       ldr      r1, [r0, #0x40]
000000f6  c907       lsls     r1, r1, #0x1f
000000f8  fcd1       bne      #0xf4
000000fa  0021       movs     r1, #0
000000fc  0160       str      r1, [r0]
000000fe  0020       movs     r0, #0
00000100  7047       bx       lr

FUNCTION EraseSector symbol=0x103 code=0x102 size=0xba
00000102  4ff6fc71   movw     r1, #0xfffc
00000106  c4f20001   movt     r1, #0x4000
0000010a  0968       ldr      r1, [r1]
0000010c  40f2000c   movw     ip, #0
00000110  c0f6217c   movt     ip, #0xf21
00000114  61b1       cbz      r1, #0x130
00000116  4ff20002   movw     r2, #0xf000
0000011a  c4f20002   movt     r2, #0x4000
0000011e  126c       ldr      r2, [r2, #0x40]
00000120  0cf56043   add.w    r3, ip, #0xe000
00000124  1205       lsls     r2, r2, #0x14
00000126  5cbf       itt      pl
00000128  0023       movpl    r3, #0
0000012a  c0f62273   movtpl   r3, #0xf22
0000012e  00e0       b        #0x132
00000130  6346       mov      r3, ip
00000132  20f08052   bic      r2, r0, #0x10000000
00000136  9a42       cmp      r2, r3
00000138  18d2       bhs      #0x16c
0000013a  4ef20001   movw     r1, #0xe000
0000013e  cef6ff71   movt     r1, #0xefff
00000142  6245       cmp      r2, ip
00000144  1fd2       bhs      #0x186
00000146  0140       ands     r1, r0
00000148  4cf20000   movw     r0, #0xc000
0000014c  c4f20000   movt     r0, #0x4000
00000150  2222       movs     r2, #0x22
00000152  c260       str      r2, [r0, #0xc]
00000154  4160       str      r1, [r0, #4]
00000156  0021       movs     r1, #0
00000158  8160       str      r1, [r0, #8]
0000015a  0121       movs     r1, #1
0000015c  0161       str      r1, [r0, #0x10]
0000015e  bff36f8f   isb      sy
00000162  00bf       nop      
00000164  016c       ldr      r1, [r0, #0x40]
00000166  c907       lsls     r1, r1, #0x1f
00000168  fcd1       bne      #0x164
0000016a  20e0       b        #0x1ae
0000016c  b1fa81f0   clz      r0, r1
00000170  4ef2ff01   movw     r1, #0xe0ff
00000174  4009       lsrs     r0, r0, #5
00000176  c0f62171   movt     r1, #0xf21
0000017a  0023       movs     r3, #0
0000017c  8a42       cmp      r2, r1
0000017e  88bf       it       hi
00000180  0123       movhi    r3, #1
00000182  1843       orrs     r0, r3
00000184  7047       bx       lr
00000186  01f58051   add.w    r1, r1, #0x1000
0000018a  0140       ands     r1, r0
0000018c  4ff20000   movw     r0, #0xf000
00000190  c4f20000   movt     r0, #0x4000
00000194  2222       movs     r2, #0x22
00000196  c260       str      r2, [r0, #0xc]
00000198  4160       str      r1, [r0, #4]
0000019a  0021       movs     r1, #0
0000019c  8160       str      r1, [r0, #8]
0000019e  0121       movs     r1, #1
000001a0  0161       str      r1, [r0, #0x10]
000001a2  bff36f8f   isb      sy
000001a6  00bf       nop      
000001a8  016c       ldr      r1, [r0, #0x40]
000001aa  c907       lsls     r1, r1, #0x1f
000001ac  fcd1       bne      #0x1a8
000001ae  0168       ldr      r1, [r0]
000001b0  4a06       lsls     r2, r1, #0x19
000001b2  52bf       itee     pl
000001b4  0020       movpl    r0, #0
000001b6  0160       strmi    r1, [r0]
000001b8  0120       movmi    r0, #1
000001ba  7047       bx       lr

FUNCTION EraseSectorEx symbol=0x1bd code=0x1bc size=0xf8
000001bc  2de9f04d   push.w   {r4, r5, r6, r7, r8, sl, fp, lr}
000001c0  81b0       sub      sp, #4
000001c2  012a       cmp      r2, #1
000001c4  01d9       bls      #0x1ca
000001c6  0120       movs     r0, #1
000001c8  6de0       b        #0x2a6
000001ca  4ff6fc73   movw     r3, #0xfffc
000001ce  c4f20003   movt     r3, #0x4000
000001d2  1e68       ldr      r6, [r3]
000001d4  4ff20003   movw     r3, #0xf000
000001d8  0024       movs     r4, #0
000001da  c4f20003   movt     r3, #0x4000
000001de  c0f62174   movt     r4, #0xf21
000001e2  4eb1       cbz      r6, #0x1f8
000001e4  1f6c       ldr      r7, [r3, #0x40]
000001e6  04f5604a   add.w    sl, r4, #0xe000
000001ea  3f05       lsls     r7, r7, #0x14
000001ec  5cbf       itt      pl
000001ee  40f2000a   movwpl   sl, #0
000001f2  c0f6227a   movtpl   sl, #0xf22
000001f6  00e0       b        #0x1fa
000001f8  a246       mov      sl, r4
000001fa  002a       cmp      r2, #0
000001fc  1cbf       itt      ne
000001fe  4af60322   movwne   r2, #0xaa03
00000202  c0f25502   movtne   r2, #0x55
00000206  0029       cmp      r1, #0
00000208  3ed0       beq      #0x288
0000020a  0096       str      r6, [sp]
0000020c  4ef20006   movw     r6, #0xe000
00000210  cef6ff76   movt     r6, #0xefff
00000214  4cf20007   movw     r7, #0xc000
00000218  0025       movs     r5, #0
0000021a  c4f20007   movt     r7, #0x4000
0000021e  06f5805e   add.w    lr, r6, #0x1000
00000222  a346       mov      fp, r4
00000224  50f825c0   ldr.w    ip, [r0, r5, lsl #2]
00000228  2cf08058   bic      r8, ip, #0x10000000
0000022c  d045       cmp      r8, sl
0000022e  2dd2       bhs      #0x28c
00000230  a045       cmp      r8, r4
00000232  15d2       bhs      #0x260
00000234  4ef20004   movw     r4, #0xe000
00000238  cef6ff74   movt     r4, #0xefff
0000023c  0cea0406   and.w    r6, ip, r4
00000240  2224       movs     r4, #0x22
00000242  fc60       str      r4, [r7, #0xc]
00000244  7e60       str      r6, [r7, #4]
00000246  0126       movs     r6, #1
00000248  ba60       str      r2, [r7, #8]
0000024a  3e61       str      r6, [r7, #0x10]
0000024c  bff36f8f   isb      sy
00000250  3e6c       ldr      r6, [r7, #0x40]
00000252  f607       lsls     r6, r6, #0x1f
00000254  fcd1       bne      #0x250
00000256  3e68       ldr      r6, [r7]
00000258  7406       lsls     r4, r6, #0x19
0000025a  11d5       bpl      #0x280
0000025c  26e0       b        #0x2ac
0000025e  00bf       nop      
00000260  0cea0e06   and.w    r6, ip, lr
00000264  2224       movs     r4, #0x22
00000266  dc60       str      r4, [r3, #0xc]
00000268  5e60       str      r6, [r3, #4]
0000026a  0126       movs     r6, #1
0000026c  9a60       str      r2, [r3, #8]
0000026e  1e61       str      r6, [r3, #0x10]
00000270  bff36f8f   isb      sy
00000274  1e6c       ldr      r6, [r3, #0x40]
00000276  f607       lsls     r6, r6, #0x1f
00000278  fcd1       bne      #0x274
0000027a  1e68       ldr      r6, [r3]
0000027c  7406       lsls     r4, r6, #0x19
0000027e  17d4       bmi      #0x2b0
00000280  0135       adds     r5, #1
00000282  8d42       cmp      r5, r1
00000284  5c46       mov      r4, fp
00000286  cdd1       bne      #0x224
00000288  0020       movs     r0, #0
0000028a  0ce0       b        #0x2a6
0000028c  0098       ldr      r0, [sp]
0000028e  4ef2ff01   movw     r1, #0xe0ff
00000292  b0fa80f0   clz      r0, r0
00000296  4009       lsrs     r0, r0, #5
00000298  c0f62171   movt     r1, #0xf21
0000029c  0022       movs     r2, #0
0000029e  8845       cmp      r8, r1
000002a0  88bf       it       hi
000002a2  0122       movhi    r2, #1
000002a4  1043       orrs     r0, r2
000002a6  01b0       add      sp, #4
000002a8  bde8f08d   pop.w    {r4, r5, r6, r7, r8, sl, fp, pc}
000002ac  3e60       str      r6, [r7]
000002ae  8ae7       b        #0x1c6
000002b0  1e60       str      r6, [r3]
000002b2  88e7       b        #0x1c6

FUNCTION ProgramPage symbol=0x2b5 code=0x2b4 size=0x248
000002b4  f0b5       push     {r4, r5, r6, r7, lr}
000002b6  4ff6fc73   movw     r3, #0xfffc
000002ba  c4f20003   movt     r3, #0x4000
000002be  1d68       ldr      r5, [r3]
000002c0  0024       movs     r4, #0
000002c2  8446       mov      ip, r0
000002c4  c0f62174   movt     r4, #0xf21
000002c8  65b1       cbz      r5, #0x2e4
000002ca  4ff20000   movw     r0, #0xf000
000002ce  c4f20000   movt     r0, #0x4000
000002d2  036c       ldr      r3, [r0, #0x40]
000002d4  04f56040   add.w    r0, r4, #0xe000
000002d8  1b05       lsls     r3, r3, #0x14
000002da  5cbf       itt      pl
000002dc  0020       movpl    r0, #0
000002de  c0f62270   movtpl   r0, #0xf22
000002e2  00e0       b        #0x2e6
000002e4  2046       mov      r0, r4
000002e6  2cf08053   bic      r3, ip, #0x10000000
000002ea  8342       cmp      r3, r0
000002ec  69d2       bhs      #0x3c2
000002ee  5fea8c70   lsls.w   r0, ip, #0x1e
000002f2  40f00181   bne.w    #0x4f8
000002f6  c81c       adds     r0, r1, #3
000002f8  a342       cmp      r3, r4
000002fa  20f00301   bic      r1, r0, #3
000002fe  80f0d980   bhs.w    #0x4b4
00000302  ccf10000   rsb.w    r0, ip, #0
00000306  10f0070e   ands     lr, r0, #7
0000030a  4cf20000   movw     r0, #0xc000
0000030e  c4f20000   movt     r0, #0x4000
00000312  1ad0       beq      #0x34a
00000314  0cf00706   and      r6, ip, #7
00000318  9e1b       subs     r6, r3, r6
0000031a  6125       movs     r5, #0x61
0000031c  1468       ldr      r4, [r2]
0000031e  c560       str      r5, [r0, #0xc]
00000320  4660       str      r6, [r0, #4]
00000322  4ff0ff36   mov.w    r6, #-1
00000326  c0f88060   str.w    r6, [r0, #0x80]
0000032a  0126       movs     r6, #1
0000032c  c0f88440   str.w    r4, [r0, #0x84]
00000330  0661       str      r6, [r0, #0x10]
00000332  bff36f8f   isb      sy
00000336  00bf       nop      
00000338  066c       ldr      r6, [r0, #0x40]
0000033a  f607       lsls     r6, r6, #0x1f
0000033c  fcd1       bne      #0x338
0000033e  0668       ldr      r6, [r0]
00000340  7506       lsls     r5, r6, #0x19
00000342  00f1b580   bmi.w    #0x4b0
00000346  7344       add      r3, lr
00000348  7244       add      r2, lr
0000034a  a1eb0e0c   sub.w    ip, r1, lr
0000034e  2cf00704   bic      r4, ip, #7
00000352  dcb1       cbz      r4, #0x38c
00000354  4ff0610e   mov.w    lr, #0x61
00000358  0121       movs     r1, #1
0000035a  00bf       nop      
0000035c  d2e90065   ldrd     r6, r5, [r2]
00000360  c0f80ce0   str.w    lr, [r0, #0xc]
00000364  4360       str      r3, [r0, #4]
00000366  c0f88060   str.w    r6, [r0, #0x80]
0000036a  c0f88450   str.w    r5, [r0, #0x84]
0000036e  0161       str      r1, [r0, #0x10]
00000370  bff36f8f   isb      sy
00000374  056c       ldr      r5, [r0, #0x40]
00000376  ed07       lsls     r5, r5, #0x1f
00000378  fcd1       bne      #0x374
0000037a  0668       ldr      r6, [r0]
0000037c  7506       lsls     r5, r6, #0x19
0000037e  00f19780   bmi.w    #0x4b0
00000382  0833       adds     r3, #8
00000384  083c       subs     r4, #8
00000386  02f10802   add.w    r2, r2, #8
0000038a  e7d1       bne      #0x35c
0000038c  1cf00701   ands     r1, ip, #7
00000390  00f0ad80   beq.w    #0x4ee
00000394  1168       ldr      r1, [r2]
00000396  6122       movs     r2, #0x61
00000398  c260       str      r2, [r0, #0xc]
0000039a  4360       str      r3, [r0, #4]
0000039c  c0f88010   str.w    r1, [r0, #0x80]
000003a0  4ff0ff31   mov.w    r1, #-1
000003a4  c0f88410   str.w    r1, [r0, #0x84]
000003a8  0121       movs     r1, #1
000003aa  0161       str      r1, [r0, #0x10]
000003ac  bff36f8f   isb      sy
000003b0  016c       ldr      r1, [r0, #0x40]
000003b2  c907       lsls     r1, r1, #0x1f
000003b4  fcd1       bne      #0x3b0
000003b6  0168       ldr      r1, [r0]
000003b8  4a06       lsls     r2, r1, #0x19
000003ba  40f19880   bpl.w    #0x4ee
000003be  0160       str      r1, [r0]
000003c0  9ae0       b        #0x4f8
000003c2  4ef2ff00   movw     r0, #0xe0ff
000003c6  c0f62170   movt     r0, #0xf21
000003ca  8342       cmp      r3, r0
000003cc  4ff00100   mov.w    r0, #1
000003d0  00f28c80   bhi.w    #0x4ec
000003d4  002d       cmp      r5, #0
000003d6  00f08980   beq.w    #0x4ec
000003da  ccf10000   rsb.w    r0, ip, #0
000003de  00f0030c   and      ip, r0, #3
000003e2  8c45       cmp      ip, r1
000003e4  28bf       it       hs
000003e6  8c46       movhs    ip, r1
000003e8  4ff20000   movw     r0, #0xf000
000003ec  bcf1000f   cmp.w    ip, #0
000003f0  c4f20000   movt     r0, #0x4000
000003f4  1dd0       beq      #0x432
000003f6  4ff0310e   mov.w    lr, #0x31
000003fa  0124       movs     r4, #1
000003fc  6546       mov      r5, ip
000003fe  00bf       nop      
00000400  1678       ldrb     r6, [r2]
00000402  00bf       nop      
00000404  d0f84071   ldr.w    r7, [r0, #0x140]
00000408  7f00       lsls     r7, r7, #1
0000040a  fbd4       bmi      #0x404
0000040c  c0f80ce0   str.w    lr, [r0, #0xc]
00000410  4360       str      r3, [r0, #4]
00000412  8660       str      r6, [r0, #8]
00000414  0461       str      r4, [r0, #0x10]
00000416  bff36f8f   isb      sy
0000041a  00bf       nop      
0000041c  066c       ldr      r6, [r0, #0x40]
0000041e  f607       lsls     r6, r6, #0x1f
00000420  fcd1       bne      #0x41c
00000422  0668       ldr      r6, [r0]
00000424  7706       lsls     r7, r6, #0x19
00000426  43d4       bmi      #0x4b0
00000428  0133       adds     r3, #1
0000042a  013d       subs     r5, #1
0000042c  02f10102   add.w    r2, r2, #1
00000430  e6d1       bne      #0x400
00000432  a1eb0c0c   sub.w    ip, r1, ip
00000436  2cf00301   bic      r1, ip, #3
0000043a  e1b1       cbz      r1, #0x476
0000043c  4ff0320e   mov.w    lr, #0x32
00000440  0124       movs     r4, #1
00000442  00bf       nop      
00000444  1568       ldr      r5, [r2]
00000446  00bf       nop      
00000448  d0f84061   ldr.w    r6, [r0, #0x140]
0000044c  7600       lsls     r6, r6, #1
0000044e  fbd4       bmi      #0x448
00000450  c0f80ce0   str.w    lr, [r0, #0xc]
00000454  4360       str      r3, [r0, #4]
00000456  8560       str      r5, [r0, #8]
00000458  0461       str      r4, [r0, #0x10]
0000045a  bff36f8f   isb      sy
0000045e  00bf       nop      
00000460  056c       ldr      r5, [r0, #0x40]
00000462  ed07       lsls     r5, r5, #0x1f
00000464  fcd1       bne      #0x460
00000466  0568       ldr      r5, [r0]
00000468  6e06       lsls     r6, r5, #0x19
0000046a  42d4       bmi      #0x4f2
0000046c  0433       adds     r3, #4
0000046e  0439       subs     r1, #4
00000470  02f10402   add.w    r2, r2, #4
00000474  e6d1       bne      #0x444
00000476  1cf00301   ands     r1, ip, #3
0000047a  38d0       beq      #0x4ee
0000047c  3125       movs     r5, #0x31
0000047e  0124       movs     r4, #1
00000480  1678       ldrb     r6, [r2]
00000482  00bf       nop      
00000484  d0f84071   ldr.w    r7, [r0, #0x140]
00000488  7f00       lsls     r7, r7, #1
0000048a  fbd4       bmi      #0x484
0000048c  c560       str      r5, [r0, #0xc]
0000048e  4360       str      r3, [r0, #4]
00000490  8660       str      r6, [r0, #8]
00000492  0461       str      r4, [r0, #0x10]
00000494  bff36f8f   isb      sy
00000498  076c       ldr      r7, [r0, #0x40]
0000049a  ff07       lsls     r7, r7, #0x1f
0000049c  fcd1       bne      #0x498
0000049e  0668       ldr      r6, [r0]
000004a0  7706       lsls     r7, r6, #0x19
000004a2  05d4       bmi      #0x4b0
000004a4  0133       adds     r3, #1
000004a6  0139       subs     r1, #1
000004a8  02f10102   add.w    r2, r2, #1
000004ac  e8d1       bne      #0x480
000004ae  1ee0       b        #0x4ee
000004b0  0660       str      r6, [r0]
000004b2  21e0       b        #0x4f8
000004b4  d9b1       cbz      r1, #0x4ee
000004b6  4ff20005   movw     r5, #0xf000
000004ba  4ff0210c   mov.w    ip, #0x21
000004be  c4f20005   movt     r5, #0x4000
000004c2  0124       movs     r4, #1
000004c4  1068       ldr      r0, [r2]
000004c6  c5f80cc0   str.w    ip, [r5, #0xc]
000004ca  6b60       str      r3, [r5, #4]
000004cc  a860       str      r0, [r5, #8]
000004ce  2c61       str      r4, [r5, #0x10]
000004d0  bff36f8f   isb      sy
000004d4  286c       ldr      r0, [r5, #0x40]
000004d6  c007       lsls     r0, r0, #0x1f
000004d8  fcd1       bne      #0x4d4
000004da  2868       ldr      r0, [r5]
000004dc  4606       lsls     r6, r0, #0x19
000004de  0ad4       bmi      #0x4f6
000004e0  0433       adds     r3, #4
000004e2  0432       adds     r2, #4
000004e4  0439       subs     r1, #4
000004e6  4ff00000   mov.w    r0, #0
000004ea  ebd1       bne      #0x4c4
000004ec  f0bd       pop      {r4, r5, r6, r7, pc}
000004ee  0020       movs     r0, #0
000004f0  f0bd       pop      {r4, r5, r6, r7, pc}
000004f2  0560       str      r5, [r0]
000004f4  00e0       b        #0x4f8
000004f6  2860       str      r0, [r5]
000004f8  0120       movs     r0, #1
000004fa  f0bd       pop      {r4, r5, r6, r7, pc}

FUNCTION Verify symbol=0x4fd code=0x4fc size=0x10c
000004fc  70b5       push     {r4, r5, r6, lr}
000004fe  4ff6fc73   movw     r3, #0xfffc
00000502  c4f20003   movt     r3, #0x4000
00000506  d3f800e0   ldr.w    lr, [r3]
0000050a  40f2000c   movw     ip, #0
0000050e  bef1000f   cmp.w    lr, #0
00000512  c0f6217c   movt     ip, #0xf21
00000516  0cd0       beq      #0x532
00000518  4ff20003   movw     r3, #0xf000
0000051c  c4f20003   movt     r3, #0x4000
00000520  1b6c       ldr      r3, [r3, #0x40]
00000522  0cf56044   add.w    r4, ip, #0xe000
00000526  1b05       lsls     r3, r3, #0x14
00000528  5cbf       itt      pl
0000052a  0024       movpl    r4, #0
0000052c  c0f62274   movtpl   r4, #0xf22
00000530  00e0       b        #0x534
00000532  6446       mov      r4, ip
00000534  20f08053   bic      r3, r0, #0x10000000
00000538  a342       cmp      r3, r4
0000053a  28d2       bhs      #0x58e
0000053c  8507       lsls     r5, r0, #0x1e
0000053e  18bf       it       ne
00000540  70bd       popne    {r4, r5, r6, pc}
00000542  0331       adds     r1, #3
00000544  6345       cmp      r3, ip
00000546  21f0030c   bic      ip, r1, #3
0000054a  37d2       bhs      #0x5bc
0000054c  bcf1000f   cmp.w    ip, #0
00000550  56d0       beq      #0x600
00000552  4cf20001   movw     r1, #0xc000
00000556  4ff0000e   mov.w    lr, #0
0000055a  c4f20001   movt     r1, #0x4000
0000055e  0124       movs     r4, #1
00000560  c1f80ce0   str.w    lr, [r1, #0xc]
00000564  4b60       str      r3, [r1, #4]
00000566  0c61       str      r4, [r1, #0x10]
00000568  bff36f8f   isb      sy
0000056c  0d6c       ldr      r5, [r1, #0x40]
0000056e  ed07       lsls     r5, r5, #0x1f
00000570  fcd1       bne      #0x56c
00000572  0d68       ldr      r5, [r1]
00000574  6e06       lsls     r6, r5, #0x19
00000576  42d4       bmi      #0x5fe
00000578  8d68       ldr      r5, [r1, #8]
0000057a  1668       ldr      r6, [r2]
0000057c  b542       cmp      r5, r6
0000057e  3fd1       bne      #0x600
00000580  0433       adds     r3, #4
00000582  bcf1040c   subs.w   ip, ip, #4
00000586  02f10402   add.w    r2, r2, #4
0000058a  e9d1       bne      #0x560
0000058c  38e0       b        #0x600
0000058e  4ef2ff06   movw     r6, #0xe0ff
00000592  c0f62176   movt     r6, #0xf21
00000596  b342       cmp      r3, r6
00000598  32d8       bhi      #0x600
0000059a  bef1000f   cmp.w    lr, #0
0000059e  2fd0       beq      #0x600
000005a0  0346       mov      r3, r0
000005a2  69b3       cbz      r1, #0x600
000005a4  0346       mov      r3, r0
000005a6  00bf       nop      
000005a8  1e78       ldrb     r6, [r3]
000005aa  1578       ldrb     r5, [r2]
000005ac  ae42       cmp      r6, r5
000005ae  27d1       bne      #0x600
000005b0  0133       adds     r3, #1
000005b2  0139       subs     r1, #1
000005b4  02f10102   add.w    r2, r2, #1
000005b8  f6d1       bne      #0x5a8
000005ba  21e0       b        #0x600
000005bc  bcf1000f   cmp.w    ip, #0
000005c0  1ed0       beq      #0x600
000005c2  4ff20001   movw     r1, #0xf000
000005c6  4ff0000e   mov.w    lr, #0
000005ca  c4f20001   movt     r1, #0x4000
000005ce  0124       movs     r4, #1
000005d0  c1f80ce0   str.w    lr, [r1, #0xc]
000005d4  4b60       str      r3, [r1, #4]
000005d6  0c61       str      r4, [r1, #0x10]
000005d8  bff36f8f   isb      sy
000005dc  0d6c       ldr      r5, [r1, #0x40]
000005de  ed07       lsls     r5, r5, #0x1f
000005e0  fcd1       bne      #0x5dc
000005e2  0d68       ldr      r5, [r1]
000005e4  6e06       lsls     r6, r5, #0x19
000005e6  0ad4       bmi      #0x5fe
000005e8  8d68       ldr      r5, [r1, #8]
000005ea  1668       ldr      r6, [r2]
000005ec  b542       cmp      r5, r6
000005ee  07d1       bne      #0x600
000005f0  0433       adds     r3, #4
000005f2  bcf1040c   subs.w   ip, ip, #4
000005f6  02f10402   add.w    r2, r2, #4
000005fa  e9d1       bne      #0x5d0
000005fc  00e0       b        #0x600
000005fe  0d60       str      r5, [r1]
00000600  00f08050   and      r0, r0, #0x10000000
00000604  1843       orrs     r0, r3
00000606  70bd       pop      {r4, r5, r6, pc}
