# Offline Capstone disassembly; FLM image offsets and runtime address for saved pyOCD layout.
# Source references are embedded DWARF line mappings, not recovered C source.
# Flash/M3351_AP_512.FLM SHA256 8729859484afaa838c46bc7094fdcd6f4f29f908cadac5b3d6d901cb6928d473
# code_base=0x200039f4, load_address=0x200039f0

Init: image 0x0000, Thumb symbol 0x0001, size 204
0000  200039f4  40f20020   movw      r0, #0x200 ; FlashPrg.c:L293
0004  200039f8  6ff0ff01   mvn       r1, #0xff
0008  200039fc  c4f20000   movt      r0, #0x4000
000c  20003a00  5922       movs      r2, #0x59
000e  20003a02  4250       str       r2, [r0, r1] ; FlashPrg.c:L295
0010  20003a04  1622       movs      r2, #0x16
0012  20003a06  4250       str       r2, [r0, r1] ; FlashPrg.c:L296
0014  20003a08  8822       movs      r2, #0x88
0016  20003a0a  4250       str       r2, [r0, r1] ; FlashPrg.c:L297
0018  20003a0c  4158       ldr       r1, [r0, r1] ; FlashPrg.c:L299
001a  20003a0e  0129       cmp       r1, #1 ; FlashPrg.c:L299
001c  20003a10  54d1       bne       #0xc8
001e  20003a12  016d       ldr       r1, [r0, #0x50] ; FlashPrg.c:L302
0020  20003a14  c906       lsls      r1, r1, #0x1b ; FlashPrg.c:L302
0022  20003a16  06d4       bmi       #0x32
0024  20003a18  0168       ldr       r1, [r0] ; FlashPrg.c:L304
0026  20003a1a  41f00401   orr       r1, r1, #4
002a  20003a1e  0160       str       r1, [r0]
002c  20003a20  016d       ldr       r1, [r0, #0x50] ; FlashPrg.c:L306
002e  20003a22  c906       lsls      r1, r1, #0x1b ; FlashPrg.c:L306
0030  20003a24  fcd5       bpl       #0x2c
0032  20003a26  0169       ldr       r1, [r0, #0x10] ; FlashPrg.c:L310
0034  20003a28  01f00701   and       r1, r1, #7 ; FlashPrg.c:L310
0038  20003a2c  0729       cmp       r1, #7 ; FlashPrg.c:L310
003a  20003a2e  03d0       beq       #0x44
003c  20003a30  0169       ldr       r1, [r0, #0x10] ; FlashPrg.c:L312
003e  20003a32  41f00701   orr       r1, r1, #7 ; FlashPrg.c:L312
0042  20003a36  0161       str       r1, [r0, #0x10] ; FlashPrg.c:L312
0044  20003a38  0021       movs      r1, #0 ; FlashPrg.c:L0
0046  20003a3a  0162       str       r1, [r0, #0x20] ; FlashPrg.c:L327
0048  20003a3c  4168       ldr       r1, [r0, #4] ; FlashPrg.c:L331
004a  20003a3e  44f20402   movw      r2, #0x4004
004e  20003a42  1143       orrs      r1, r2
0050  20003a44  4160       str       r1, [r0, #4]
0052  20003a46  4cf20000   movw      r0, #0xc000
0056  20003a4a  c4f20000   movt      r0, #0x4000
005a  20003a4e  e921       movs      r1, #0xe9
005c  20003a50  0160       str       r1, [r0] ; FlashPrg.c:L336
005e  20003a52  0168       ldr       r1, [r0] ; FlashPrg.c:L338
0060  20003a54  01f0a901   and       r1, r1, #0xa9 ; FlashPrg.c:L338
0064  20003a58  a929       cmp       r1, #0xa9 ; FlashPrg.c:L338
0066  20003a5a  2fd1       bne       #0xc8
0068  20003a5c  0221       movs      r1, #2 ; FlashPrg.c:L0
006a  20003a5e  c164       str       r1, [r0, #0x4c] ; FlashPrg.c:L342
006c  20003a60  4ff6fc70   movw      r0, #0xfffc
0070  20003a64  c4f20000   movt      r0, #0x4000
0074  20003a68  0068       ldr       r0, [r0] ; FlashPrg.c:L348
0076  20003a6a  20b3       cbz       r0, #0xc2 ; FlashPrg.c:L348
0078  20003a6c  4ff20000   movw      r0, #0xf000 ; FlashPrg.c:L0
007c  20003a70  c4f20000   movt      r0, #0x4000
0080  20003a74  4921       movs      r1, #0x49
0082  20003a76  0160       str       r1, [r0] ; FlashPrg.c:L350
0084  20003a78  0168       ldr       r1, [r0] ; FlashPrg.c:L352
0086  20003a7a  01f00901   and       r1, r1, #9 ; FlashPrg.c:L352
008a  20003a7e  0929       cmp       r1, #9 ; FlashPrg.c:L352
008c  20003a80  1cd1       bne       #0xc8
008e  20003a82  016c       ldr       r1, [r0, #0x40] ; FlashPrg.c:L355
0090  20003a84  0905       lsls      r1, r1, #0x14 ; FlashPrg.c:L355
0092  20003a86  14d5       bpl       #0xbe
0094  20003a88  3321       movs      r1, #0x33 ; FlashPrg.c:L0
0096  20003a8a  c160       str       r1, [r0, #0xc] ; FlashPrg.c:L217
0098  20003a8c  4ef20001   movw      r1, #0xe000
009c  20003a90  c0f62171   movt      r1, #0xf21
00a0  20003a94  4160       str       r1, [r0, #4] ; FlashPrg.c:L218
00a2  20003a96  0121       movs      r1, #1
00a4  20003a98  0161       str       r1, [r0, #0x10] ; FlashPrg.c:L219
00a6  20003a9a  bff36f8f   isb       sy ; FlashPrg.c:L220
00aa  20003a9e  00bf       nop       
00ac  20003aa0  016c       ldr       r1, [r0, #0x40] ; FlashPrg.c:L222
00ae  20003aa2  c907       lsls      r1, r1, #0x1f ; FlashPrg.c:L222
00b0  20003aa4  fcd1       bne       #0xac
00b2  20003aa6  0168       ldr       r1, [r0] ; FlashPrg.c:L224
00b4  20003aa8  4a06       lsls      r2, r1, #0x19 ; FlashPrg.c:L226
00b6  20003aaa  06d4       bmi       #0xc6
00b8  20003aac  016c       ldr       r1, [r0, #0x40] ; FlashPrg.c:L232
00ba  20003aae  8905       lsls      r1, r1, #0x16 ; FlashPrg.c:L232
00bc  20003ab0  fcd4       bmi       #0xb8
00be  20003ab2  0221       movs      r1, #2 ; FlashPrg.c:L0
00c0  20003ab4  c164       str       r1, [r0, #0x4c] ; FlashPrg.c:L363
00c2  20003ab6  0020       movs      r0, #0 ; FlashPrg.c:L0
00c4  20003ab8  7047       bx        lr ; FlashPrg.c:L371
00c6  20003aba  0160       str       r1, [r0] ; FlashPrg.c:L228
00c8  20003abc  0120       movs      r0, #1 ; FlashPrg.c:L0
00ca  20003abe  7047       bx        lr ; FlashPrg.c:L371

UnInit: image 0x00cc, Thumb symbol 0x00cd, size 54
00cc  20003ac0  4cf20000   movw      r0, #0xc000 ; FlashPrg.c:L380
00d0  20003ac4  c4f20000   movt      r0, #0x4000
00d4  20003ac8  016c       ldr       r1, [r0, #0x40] ; FlashPrg.c:L382
00d6  20003aca  c907       lsls      r1, r1, #0x1f ; FlashPrg.c:L382
00d8  20003acc  fcd1       bne       #0xd4
00da  20003ace  0021       movs      r1, #0 ; FlashPrg.c:L0
00dc  20003ad0  0160       str       r1, [r0] ; FlashPrg.c:L384
00de  20003ad2  4ff6fc70   movw      r0, #0xfffc
00e2  20003ad6  c4f20000   movt      r0, #0x4000
00e6  20003ada  0068       ldr       r0, [r0] ; FlashPrg.c:L387
00e8  20003adc  48b1       cbz       r0, #0xfe ; FlashPrg.c:L387
00ea  20003ade  4ff20000   movw      r0, #0xf000 ; FlashPrg.c:L0
00ee  20003ae2  c4f20000   movt      r0, #0x4000
00f2  20003ae6  00bf       nop       
00f4  20003ae8  016c       ldr       r1, [r0, #0x40] ; FlashPrg.c:L389
00f6  20003aea  c907       lsls      r1, r1, #0x1f ; FlashPrg.c:L389
00f8  20003aec  fcd1       bne       #0xf4
00fa  20003aee  0021       movs      r1, #0 ; FlashPrg.c:L0
00fc  20003af0  0160       str       r1, [r0] ; FlashPrg.c:L391
00fe  20003af2  0020       movs      r0, #0 ; FlashPrg.c:L395
0100  20003af4  7047       bx        lr

EraseSector: image 0x0102, Thumb symbol 0x0103, size 186
0102  20003af6  4ff6fc71   movw      r1, #0xfffc ; FlashPrg.c:L406
0106  20003afa  c4f20001   movt      r1, #0x4000
010a  20003afe  0968       ldr       r1, [r1] ; FlashPrg.c:L411
010c  20003b00  40f2000c   movw      ip, #0
0110  20003b04  c0f6217c   movt      ip, #0xf21
0114  20003b08  61b1       cbz       r1, #0x130 ; FlashPrg.c:L411
0116  20003b0a  4ff20002   movw      r2, #0xf000 ; FlashPrg.c:L0
011a  20003b0e  c4f20002   movt      r2, #0x4000
011e  20003b12  126c       ldr       r2, [r2, #0x40] ; FlashPrg.c:L415
0120  20003b14  0cf56043   add.w     r3, ip, #0xe000
0124  20003b18  1205       lsls      r2, r2, #0x14
0126  20003b1a  5cbf       itt       pl
0128  20003b1c  0023       movpl     r3, #0
012a  20003b1e  c0f62273   movtpl    r3, #0xf22
012e  20003b22  00e0       b         #0x132
0130  20003b24  6346       mov       r3, ip ; FlashPrg.c:L0
0132  20003b26  20f08052   bic       r2, r0, #0x10000000 ; FlashPrg.c:L426
0136  20003b2a  9a42       cmp       r2, r3 ; FlashPrg.c:L428
0138  20003b2c  18d2       bhs       #0x16c
013a  20003b2e  4ef20001   movw      r1, #0xe000 ; FlashPrg.c:L0
013e  20003b32  cef6ff71   movt      r1, #0xefff
0142  20003b36  6245       cmp       r2, ip ; FlashPrg.c:L430
0144  20003b38  1fd2       bhs       #0x186
0146  20003b3a  0140       ands      r1, r0 ; FlashPrg.c:L432
0148  20003b3c  4cf20000   movw      r0, #0xc000 ; FlashPrg.c:L0
014c  20003b40  c4f20000   movt      r0, #0x4000
0150  20003b44  2222       movs      r2, #0x22
0152  20003b46  c260       str       r2, [r0, #0xc] ; FlashPrg.c:L97
0154  20003b48  4160       str       r1, [r0, #4] ; FlashPrg.c:L98
0156  20003b4a  0021       movs      r1, #0
0158  20003b4c  8160       str       r1, [r0, #8] ; FlashPrg.c:L99
015a  20003b4e  0121       movs      r1, #1
015c  20003b50  0161       str       r1, [r0, #0x10] ; FlashPrg.c:L100
015e  20003b52  bff36f8f   isb       sy ; FlashPrg.c:L101
0162  20003b56  00bf       nop       
0164  20003b58  016c       ldr       r1, [r0, #0x40] ; FlashPrg.c:L103
0166  20003b5a  c907       lsls      r1, r1, #0x1f ; FlashPrg.c:L103
0168  20003b5c  fcd1       bne       #0x164
016a  20003b5e  20e0       b         #0x1ae
016c  20003b60  b1fa81f0   clz       r0, r1 ; FlashPrg.c:L411
0170  20003b64  4ef2ff01   movw      r1, #0xe0ff
0174  20003b68  4009       lsrs      r0, r0, #5
0176  20003b6a  c0f62171   movt      r1, #0xf21
017a  20003b6e  0023       movs      r3, #0
017c  20003b70  8a42       cmp       r2, r1 ; FlashPrg.c:L0
017e  20003b72  88bf       it        hi
0180  20003b74  0123       movhi     r3, #1
0182  20003b76  1843       orrs      r0, r3 ; FlashPrg.c:L445
0184  20003b78  7047       bx        lr ; FlashPrg.c:L467
0186  20003b7a  01f58051   add.w     r1, r1, #0x1000 ; FlashPrg.c:L439
018a  20003b7e  0140       ands      r1, r0
018c  20003b80  4ff20000   movw      r0, #0xf000 ; FlashPrg.c:L0
0190  20003b84  c4f20000   movt      r0, #0x4000
0194  20003b88  2222       movs      r2, #0x22
0196  20003b8a  c260       str       r2, [r0, #0xc] ; FlashPrg.c:L169
0198  20003b8c  4160       str       r1, [r0, #4] ; FlashPrg.c:L170
019a  20003b8e  0021       movs      r1, #0
019c  20003b90  8160       str       r1, [r0, #8] ; FlashPrg.c:L171
019e  20003b92  0121       movs      r1, #1
01a0  20003b94  0161       str       r1, [r0, #0x10] ; FlashPrg.c:L172
01a2  20003b96  bff36f8f   isb       sy ; FlashPrg.c:L173
01a6  20003b9a  00bf       nop       
01a8  20003b9c  016c       ldr       r1, [r0, #0x40] ; FlashPrg.c:L175
01aa  20003b9e  c907       lsls      r1, r1, #0x1f ; FlashPrg.c:L175
01ac  20003ba0  fcd1       bne       #0x1a8
01ae  20003ba2  0168       ldr       r1, [r0] ; FlashPrg.c:L0
01b0  20003ba4  4a06       lsls      r2, r1, #0x19
01b2  20003ba6  52bf       itee      pl
01b4  20003ba8  0020       movpl     r0, #0
01b6  20003baa  0160       strmi     r1, [r0]
01b8  20003bac  0120       movmi     r0, #1
01ba  20003bae  7047       bx        lr ; FlashPrg.c:L467

EraseSectorEx: image 0x01bc, Thumb symbol 0x01bd, size 248
01bc  20003bb0  2de9f04d   push.w    {r4, r5, r6, r7, r8, sl, fp, lr} ; FlashPrg.c:L479
01c0  20003bb4  81b0       sub       sp, #4
01c2  20003bb6  012a       cmp       r2, #1 ; FlashPrg.c:L486
01c4  20003bb8  01d9       bls       #0x1ca
01c6  20003bba  0120       movs      r0, #1 ; FlashPrg.c:L0
01c8  20003bbc  6de0       b         #0x2a6
01ca  20003bbe  4ff6fc73   movw      r3, #0xfffc
01ce  20003bc2  c4f20003   movt      r3, #0x4000
01d2  20003bc6  1e68       ldr       r6, [r3] ; FlashPrg.c:L489
01d4  20003bc8  4ff20003   movw      r3, #0xf000
01d8  20003bcc  0024       movs      r4, #0
01da  20003bce  c4f20003   movt      r3, #0x4000
01de  20003bd2  c0f62174   movt      r4, #0xf21
01e2  20003bd6  4eb1       cbz       r6, #0x1f8 ; FlashPrg.c:L489
01e4  20003bd8  1f6c       ldr       r7, [r3, #0x40] ; FlashPrg.c:L493
01e6  20003bda  04f5604a   add.w     sl, r4, #0xe000
01ea  20003bde  3f05       lsls      r7, r7, #0x14
01ec  20003be0  5cbf       itt       pl
01ee  20003be2  40f2000a   movwpl    sl, #0
01f2  20003be6  c0f6227a   movtpl    sl, #0xf22
01f6  20003bea  00e0       b         #0x1fa
01f8  20003bec  a246       mov       sl, r4 ; FlashPrg.c:L0
01fa  20003bee  002a       cmp       r2, #0 ; FlashPrg.c:L504
01fc  20003bf0  1cbf       itt       ne
01fe  20003bf2  4af60322   movwne    r2, #0xaa03
0202  20003bf6  c0f25502   movtne    r2, #0x55
0206  20003bfa  0029       cmp       r1, #0 ; FlashPrg.c:L506
0208  20003bfc  3ed0       beq       #0x288
020a  20003bfe  0096       str       r6, [sp] ; FlashPrg.c:L0
020c  20003c00  4ef20006   movw      r6, #0xe000
0210  20003c04  cef6ff76   movt      r6, #0xefff
0214  20003c08  4cf20007   movw      r7, #0xc000
0218  20003c0c  0025       movs      r5, #0
021a  20003c0e  c4f20007   movt      r7, #0x4000
021e  20003c12  06f5805e   add.w     lr, r6, #0x1000
0222  20003c16  a346       mov       fp, r4
0224  20003c18  50f825c0   ldr.w     ip, [r0, r5, lsl #2] ; FlashPrg.c:L508
0228  20003c1c  2cf08058   bic       r8, ip, #0x10000000 ; FlashPrg.c:L510
022c  20003c20  d045       cmp       r8, sl ; FlashPrg.c:L512
022e  20003c22  2dd2       bhs       #0x28c
0230  20003c24  a045       cmp       r8, r4 ; FlashPrg.c:L514
0232  20003c26  15d2       bhs       #0x260
0234  20003c28  4ef20004   movw      r4, #0xe000 ; FlashPrg.c:L516
0238  20003c2c  cef6ff74   movt      r4, #0xefff
023c  20003c30  0cea0406   and.w     r6, ip, r4
0240  20003c34  2224       movs      r4, #0x22 ; FlashPrg.c:L97
0242  20003c36  fc60       str       r4, [r7, #0xc]
0244  20003c38  7e60       str       r6, [r7, #4] ; FlashPrg.c:L98
0246  20003c3a  0126       movs      r6, #1 ; FlashPrg.c:L100
0248  20003c3c  ba60       str       r2, [r7, #8] ; FlashPrg.c:L99
024a  20003c3e  3e61       str       r6, [r7, #0x10] ; FlashPrg.c:L100
024c  20003c40  bff36f8f   isb       sy ; FlashPrg.c:L101
0250  20003c44  3e6c       ldr       r6, [r7, #0x40] ; FlashPrg.c:L103
0252  20003c46  f607       lsls      r6, r6, #0x1f ; FlashPrg.c:L103
0254  20003c48  fcd1       bne       #0x250
0256  20003c4a  3e68       ldr       r6, [r7] ; FlashPrg.c:L105
0258  20003c4c  7406       lsls      r4, r6, #0x19 ; FlashPrg.c:L107
025a  20003c4e  11d5       bpl       #0x280
025c  20003c50  26e0       b         #0x2ac
025e  20003c52  00bf       nop       
0260  20003c54  0cea0e06   and.w     r6, ip, lr ; FlashPrg.c:L525
0264  20003c58  2224       movs      r4, #0x22 ; FlashPrg.c:L169
0266  20003c5a  dc60       str       r4, [r3, #0xc]
0268  20003c5c  5e60       str       r6, [r3, #4] ; FlashPrg.c:L170
026a  20003c5e  0126       movs      r6, #1 ; FlashPrg.c:L172
026c  20003c60  9a60       str       r2, [r3, #8] ; FlashPrg.c:L171
026e  20003c62  1e61       str       r6, [r3, #0x10] ; FlashPrg.c:L172
0270  20003c64  bff36f8f   isb       sy ; FlashPrg.c:L173
0274  20003c68  1e6c       ldr       r6, [r3, #0x40] ; FlashPrg.c:L175
0276  20003c6a  f607       lsls      r6, r6, #0x1f ; FlashPrg.c:L175
0278  20003c6c  fcd1       bne       #0x274
027a  20003c6e  1e68       ldr       r6, [r3] ; FlashPrg.c:L177
027c  20003c70  7406       lsls      r4, r6, #0x19 ; FlashPrg.c:L179
027e  20003c72  17d4       bmi       #0x2b0
0280  20003c74  0135       adds      r5, #1 ; FlashPrg.c:L0
0282  20003c76  8d42       cmp       r5, r1 ; FlashPrg.c:L506
0284  20003c78  5c46       mov       r4, fp
0286  20003c7a  cdd1       bne       #0x224
0288  20003c7c  0020       movs      r0, #0 ; FlashPrg.c:L0
028a  20003c7e  0ce0       b         #0x2a6
028c  20003c80  0098       ldr       r0, [sp] ; FlashPrg.c:L489
028e  20003c82  4ef2ff01   movw      r1, #0xe0ff ; FlashPrg.c:L0
0292  20003c86  b0fa80f0   clz       r0, r0 ; FlashPrg.c:L489
0296  20003c8a  4009       lsrs      r0, r0, #5
0298  20003c8c  c0f62171   movt      r1, #0xf21
029c  20003c90  0022       movs      r2, #0
029e  20003c92  8845       cmp       r8, r1 ; FlashPrg.c:L0
02a0  20003c94  88bf       it        hi
02a2  20003c96  0122       movhi     r2, #1
02a4  20003c98  1043       orrs      r0, r2
02a6  20003c9a  01b0       add       sp, #4 ; FlashPrg.c:L564
02a8  20003c9c  bde8f08d   pop.w     {r4, r5, r6, r7, r8, sl, fp, pc}
02ac  20003ca0  3e60       str       r6, [r7] ; FlashPrg.c:L109
02ae  20003ca2  8ae7       b         #0x1c6
02b0  20003ca4  1e60       str       r6, [r3] ; FlashPrg.c:L181
02b2  20003ca6  88e7       b         #0x1c6

ProgramPage: image 0x02b4, Thumb symbol 0x02b5, size 584
02b4  20003ca8  f0b5       push      {r4, r5, r6, r7, lr} ; FlashPrg.c:L576
02b6  20003caa  4ff6fc73   movw      r3, #0xfffc
02ba  20003cae  c4f20003   movt      r3, #0x4000
02be  20003cb2  1d68       ldr       r5, [r3] ; FlashPrg.c:L582
02c0  20003cb4  0024       movs      r4, #0
02c2  20003cb6  8446       mov       ip, r0
02c4  20003cb8  c0f62174   movt      r4, #0xf21 ; FlashPrg.c:L0
02c8  20003cbc  65b1       cbz       r5, #0x2e4 ; FlashPrg.c:L582
02ca  20003cbe  4ff20000   movw      r0, #0xf000 ; FlashPrg.c:L0
02ce  20003cc2  c4f20000   movt      r0, #0x4000
02d2  20003cc6  036c       ldr       r3, [r0, #0x40] ; FlashPrg.c:L586
02d4  20003cc8  04f56040   add.w     r0, r4, #0xe000
02d8  20003ccc  1b05       lsls      r3, r3, #0x14
02da  20003cce  5cbf       itt       pl
02dc  20003cd0  0020       movpl     r0, #0
02de  20003cd2  c0f62270   movtpl    r0, #0xf22
02e2  20003cd6  00e0       b         #0x2e6
02e4  20003cd8  2046       mov       r0, r4 ; FlashPrg.c:L0
02e6  20003cda  2cf08053   bic       r3, ip, #0x10000000 ; FlashPrg.c:L597
02ea  20003cde  8342       cmp       r3, r0 ; FlashPrg.c:L599
02ec  20003ce0  69d2       bhs       #0x3c2
02ee  20003ce2  5fea8c70   lsls.w    r0, ip, #0x1e ; FlashPrg.c:L601
02f2  20003ce6  40f00181   bne.w     #0x4f8
02f6  20003cea  c81c       adds      r0, r1, #3 ; FlashPrg.c:L604
02f8  20003cec  a342       cmp       r3, r4 ; FlashPrg.c:L606
02fa  20003cee  20f00301   bic       r1, r0, #3 ; FlashPrg.c:L604
02fe  20003cf2  80f0d980   bhs.w     #0x4b4 ; FlashPrg.c:L606
0302  20003cf6  ccf10000   rsb.w     r0, ip, #0 ; FlashPrg.c:L610
0306  20003cfa  10f0070e   ands      lr, r0, #7 ; FlashPrg.c:L610
030a  20003cfe  4cf20000   movw      r0, #0xc000 ; FlashPrg.c:L0
030e  20003d02  c4f20000   movt      r0, #0x4000
0312  20003d06  1ad0       beq       #0x34a ; FlashPrg.c:L614
0314  20003d08  0cf00706   and       r6, ip, #7 ; FlashPrg.c:L608
0318  20003d0c  9e1b       subs      r6, r3, r6 ; FlashPrg.c:L616
031a  20003d0e  6125       movs      r5, #0x61
031c  20003d10  1468       ldr       r4, [r2] ; FlashPrg.c:L616
031e  20003d12  c560       str       r5, [r0, #0xc] ; FlashPrg.c:L120
0320  20003d14  4660       str       r6, [r0, #4] ; FlashPrg.c:L121
0322  20003d16  4ff0ff36   mov.w     r6, #-1
0326  20003d1a  c0f88060   str.w     r6, [r0, #0x80] ; FlashPrg.c:L122
032a  20003d1e  0126       movs      r6, #1
032c  20003d20  c0f88440   str.w     r4, [r0, #0x84] ; FlashPrg.c:L123
0330  20003d24  0661       str       r6, [r0, #0x10] ; FlashPrg.c:L124
0332  20003d26  bff36f8f   isb       sy ; FlashPrg.c:L125
0336  20003d2a  00bf       nop       
0338  20003d2c  066c       ldr       r6, [r0, #0x40] ; FlashPrg.c:L127
033a  20003d2e  f607       lsls      r6, r6, #0x1f ; FlashPrg.c:L127
033c  20003d30  fcd1       bne       #0x338
033e  20003d32  0668       ldr       r6, [r0] ; FlashPrg.c:L129
0340  20003d34  7506       lsls      r5, r6, #0x19 ; FlashPrg.c:L131
0342  20003d36  00f1b580   bmi.w     #0x4b0
0346  20003d3a  7344       add       r3, lr ; FlashPrg.c:L619
0348  20003d3c  7244       add       r2, lr ; FlashPrg.c:L620
034a  20003d3e  a1eb0e0c   sub.w     ip, r1, lr ; FlashPrg.c:L0
034e  20003d42  2cf00704   bic       r4, ip, #7
0352  20003d46  dcb1       cbz       r4, #0x38c ; FlashPrg.c:L623
0354  20003d48  4ff0610e   mov.w     lr, #0x61 ; FlashPrg.c:L0
0358  20003d4c  0121       movs      r1, #1
035a  20003d4e  00bf       nop       
035c  20003d50  d2e90065   ldrd      r6, r5, [r2] ; FlashPrg.c:L625
0360  20003d54  c0f80ce0   str.w     lr, [r0, #0xc] ; FlashPrg.c:L120
0364  20003d58  4360       str       r3, [r0, #4] ; FlashPrg.c:L121
0366  20003d5a  c0f88060   str.w     r6, [r0, #0x80] ; FlashPrg.c:L122
036a  20003d5e  c0f88450   str.w     r5, [r0, #0x84] ; FlashPrg.c:L123
036e  20003d62  0161       str       r1, [r0, #0x10] ; FlashPrg.c:L124
0370  20003d64  bff36f8f   isb       sy ; FlashPrg.c:L125
0374  20003d68  056c       ldr       r5, [r0, #0x40] ; FlashPrg.c:L127
0376  20003d6a  ed07       lsls      r5, r5, #0x1f ; FlashPrg.c:L127
0378  20003d6c  fcd1       bne       #0x374
037a  20003d6e  0668       ldr       r6, [r0] ; FlashPrg.c:L129
037c  20003d70  7506       lsls      r5, r6, #0x19 ; FlashPrg.c:L131
037e  20003d72  00f19780   bmi.w     #0x4b0
0382  20003d76  0833       adds      r3, #8 ; FlashPrg.c:L628
0384  20003d78  083c       subs      r4, #8 ; FlashPrg.c:L630
0386  20003d7a  02f10802   add.w     r2, r2, #8 ; FlashPrg.c:L629
038a  20003d7e  e7d1       bne       #0x35c ; FlashPrg.c:L623
038c  20003d80  1cf00701   ands      r1, ip, #7 ; FlashPrg.c:L0
0390  20003d84  00f0ad80   beq.w     #0x4ee ; FlashPrg.c:L633
0394  20003d88  1168       ldr       r1, [r2] ; FlashPrg.c:L635
0396  20003d8a  6122       movs      r2, #0x61 ; FlashPrg.c:L0
0398  20003d8c  c260       str       r2, [r0, #0xc] ; FlashPrg.c:L120
039a  20003d8e  4360       str       r3, [r0, #4] ; FlashPrg.c:L121
039c  20003d90  c0f88010   str.w     r1, [r0, #0x80] ; FlashPrg.c:L122
03a0  20003d94  4ff0ff31   mov.w     r1, #-1
03a4  20003d98  c0f88410   str.w     r1, [r0, #0x84] ; FlashPrg.c:L123
03a8  20003d9c  0121       movs      r1, #1
03aa  20003d9e  0161       str       r1, [r0, #0x10] ; FlashPrg.c:L124
03ac  20003da0  bff36f8f   isb       sy ; FlashPrg.c:L125
03b0  20003da4  016c       ldr       r1, [r0, #0x40] ; FlashPrg.c:L127
03b2  20003da6  c907       lsls      r1, r1, #0x1f ; FlashPrg.c:L127
03b4  20003da8  fcd1       bne       #0x3b0
03b6  20003daa  0168       ldr       r1, [r0] ; FlashPrg.c:L129
03b8  20003dac  4a06       lsls      r2, r1, #0x19 ; FlashPrg.c:L131
03ba  20003dae  40f19880   bpl.w     #0x4ee
03be  20003db2  0160       str       r1, [r0] ; FlashPrg.c:L133
03c0  20003db4  9ae0       b         #0x4f8
03c2  20003db6  4ef2ff00   movw      r0, #0xe0ff ; FlashPrg.c:L0
03c6  20003dba  c0f62170   movt      r0, #0xf21
03ca  20003dbe  8342       cmp       r3, r0 ; FlashPrg.c:L655
03cc  20003dc0  4ff00100   mov.w     r0, #1
03d0  20003dc4  00f28c80   bhi.w     #0x4ec
03d4  20003dc8  002d       cmp       r5, #0
03d6  20003dca  00f08980   beq.w     #0x4ec
03da  20003dce  ccf10000   rsb.w     r0, ip, #0 ; FlashPrg.c:L659
03de  20003dd2  00f0030c   and       ip, r0, #3 ; FlashPrg.c:L659
03e2  20003dd6  8c45       cmp       ip, r1 ; FlashPrg.c:L660
03e4  20003dd8  28bf       it        hs
03e6  20003dda  8c46       movhs     ip, r1
03e8  20003ddc  4ff20000   movw      r0, #0xf000 ; FlashPrg.c:L0
03ec  20003de0  bcf1000f   cmp.w     ip, #0 ; FlashPrg.c:L666
03f0  20003de4  c4f20000   movt      r0, #0x4000 ; FlashPrg.c:L0
03f4  20003de8  1dd0       beq       #0x432 ; FlashPrg.c:L666
03f6  20003dea  4ff0310e   mov.w     lr, #0x31 ; FlashPrg.c:L0
03fa  20003dee  0124       movs      r4, #1
03fc  20003df0  6546       mov       r5, ip
03fe  20003df2  00bf       nop       
0400  20003df4  1678       ldrb      r6, [r2] ; FlashPrg.c:L668
0402  20003df6  00bf       nop       
0404  20003df8  d0f84071   ldr.w     r7, [r0, #0x140] ; FlashPrg.c:L241
0408  20003dfc  7f00       lsls      r7, r7, #1 ; FlashPrg.c:L241
040a  20003dfe  fbd4       bmi       #0x404
040c  20003e00  c0f80ce0   str.w     lr, [r0, #0xc] ; FlashPrg.c:L243
0410  20003e04  4360       str       r3, [r0, #4] ; FlashPrg.c:L244
0412  20003e06  8660       str       r6, [r0, #8] ; FlashPrg.c:L245
0414  20003e08  0461       str       r4, [r0, #0x10] ; FlashPrg.c:L246
0416  20003e0a  bff36f8f   isb       sy ; FlashPrg.c:L247
041a  20003e0e  00bf       nop       
041c  20003e10  066c       ldr       r6, [r0, #0x40] ; FlashPrg.c:L249
041e  20003e12  f607       lsls      r6, r6, #0x1f ; FlashPrg.c:L249
0420  20003e14  fcd1       bne       #0x41c
0422  20003e16  0668       ldr       r6, [r0] ; FlashPrg.c:L251
0424  20003e18  7706       lsls      r7, r6, #0x19 ; FlashPrg.c:L253
0426  20003e1a  43d4       bmi       #0x4b0
0428  20003e1c  0133       adds      r3, #1 ; FlashPrg.c:L671
042a  20003e1e  013d       subs      r5, #1 ; FlashPrg.c:L673
042c  20003e20  02f10102   add.w     r2, r2, #1 ; FlashPrg.c:L672
0430  20003e24  e6d1       bne       #0x400 ; FlashPrg.c:L666
0432  20003e26  a1eb0c0c   sub.w     ip, r1, ip ; FlashPrg.c:L0
0436  20003e2a  2cf00301   bic       r1, ip, #3
043a  20003e2e  e1b1       cbz       r1, #0x476 ; FlashPrg.c:L676
043c  20003e30  4ff0320e   mov.w     lr, #0x32 ; FlashPrg.c:L0
0440  20003e34  0124       movs      r4, #1
0442  20003e36  00bf       nop       
0444  20003e38  1568       ldr       r5, [r2] ; FlashPrg.c:L678
0446  20003e3a  00bf       nop       
0448  20003e3c  d0f84061   ldr.w     r6, [r0, #0x140] ; FlashPrg.c:L241
044c  20003e40  7600       lsls      r6, r6, #1 ; FlashPrg.c:L241
044e  20003e42  fbd4       bmi       #0x448
0450  20003e44  c0f80ce0   str.w     lr, [r0, #0xc] ; FlashPrg.c:L243
0454  20003e48  4360       str       r3, [r0, #4] ; FlashPrg.c:L244
0456  20003e4a  8560       str       r5, [r0, #8] ; FlashPrg.c:L245
0458  20003e4c  0461       str       r4, [r0, #0x10] ; FlashPrg.c:L246
045a  20003e4e  bff36f8f   isb       sy ; FlashPrg.c:L247
045e  20003e52  00bf       nop       
0460  20003e54  056c       ldr       r5, [r0, #0x40] ; FlashPrg.c:L249
0462  20003e56  ed07       lsls      r5, r5, #0x1f ; FlashPrg.c:L249
0464  20003e58  fcd1       bne       #0x460
0466  20003e5a  0568       ldr       r5, [r0] ; FlashPrg.c:L251
0468  20003e5c  6e06       lsls      r6, r5, #0x19 ; FlashPrg.c:L253
046a  20003e5e  42d4       bmi       #0x4f2
046c  20003e60  0433       adds      r3, #4 ; FlashPrg.c:L681
046e  20003e62  0439       subs      r1, #4 ; FlashPrg.c:L683
0470  20003e64  02f10402   add.w     r2, r2, #4 ; FlashPrg.c:L682
0474  20003e68  e6d1       bne       #0x444 ; FlashPrg.c:L676
0476  20003e6a  1cf00301   ands      r1, ip, #3 ; FlashPrg.c:L0
047a  20003e6e  38d0       beq       #0x4ee ; FlashPrg.c:L686
047c  20003e70  3125       movs      r5, #0x31 ; FlashPrg.c:L0
047e  20003e72  0124       movs      r4, #1
0480  20003e74  1678       ldrb      r6, [r2] ; FlashPrg.c:L688
0482  20003e76  00bf       nop       
0484  20003e78  d0f84071   ldr.w     r7, [r0, #0x140] ; FlashPrg.c:L241
0488  20003e7c  7f00       lsls      r7, r7, #1 ; FlashPrg.c:L241
048a  20003e7e  fbd4       bmi       #0x484
048c  20003e80  c560       str       r5, [r0, #0xc] ; FlashPrg.c:L243
048e  20003e82  4360       str       r3, [r0, #4] ; FlashPrg.c:L244
0490  20003e84  8660       str       r6, [r0, #8] ; FlashPrg.c:L245
0492  20003e86  0461       str       r4, [r0, #0x10] ; FlashPrg.c:L246
0494  20003e88  bff36f8f   isb       sy ; FlashPrg.c:L247
0498  20003e8c  076c       ldr       r7, [r0, #0x40] ; FlashPrg.c:L249
049a  20003e8e  ff07       lsls      r7, r7, #0x1f ; FlashPrg.c:L249
049c  20003e90  fcd1       bne       #0x498
049e  20003e92  0668       ldr       r6, [r0] ; FlashPrg.c:L251
04a0  20003e94  7706       lsls      r7, r6, #0x19 ; FlashPrg.c:L253
04a2  20003e96  05d4       bmi       #0x4b0
04a4  20003e98  0133       adds      r3, #1 ; FlashPrg.c:L691
04a6  20003e9a  0139       subs      r1, #1 ; FlashPrg.c:L693
04a8  20003e9c  02f10102   add.w     r2, r2, #1 ; FlashPrg.c:L692
04ac  20003ea0  e8d1       bne       #0x480 ; FlashPrg.c:L686
04ae  20003ea2  1ee0       b         #0x4ee
04b0  20003ea4  0660       str       r6, [r0] ; FlashPrg.c:L0
04b2  20003ea6  21e0       b         #0x4f8
04b4  20003ea8  d9b1       cbz       r1, #0x4ee ; FlashPrg.c:L644
04b6  20003eaa  4ff20005   movw      r5, #0xf000 ; FlashPrg.c:L0
04ba  20003eae  4ff0210c   mov.w     ip, #0x21
04be  20003eb2  c4f20005   movt      r5, #0x4000
04c2  20003eb6  0124       movs      r4, #1
04c4  20003eb8  1068       ldr       r0, [r2] ; FlashPrg.c:L646
04c6  20003eba  c5f80cc0   str.w     ip, [r5, #0xc] ; FlashPrg.c:L169
04ca  20003ebe  6b60       str       r3, [r5, #4] ; FlashPrg.c:L170
04cc  20003ec0  a860       str       r0, [r5, #8] ; FlashPrg.c:L171
04ce  20003ec2  2c61       str       r4, [r5, #0x10] ; FlashPrg.c:L172
04d0  20003ec4  bff36f8f   isb       sy ; FlashPrg.c:L173
04d4  20003ec8  286c       ldr       r0, [r5, #0x40] ; FlashPrg.c:L175
04d6  20003eca  c007       lsls      r0, r0, #0x1f ; FlashPrg.c:L175
04d8  20003ecc  fcd1       bne       #0x4d4
04da  20003ece  2868       ldr       r0, [r5] ; FlashPrg.c:L177
04dc  20003ed0  4606       lsls      r6, r0, #0x19 ; FlashPrg.c:L179
04de  20003ed2  0ad4       bmi       #0x4f6
04e0  20003ed4  0433       adds      r3, #4 ; FlashPrg.c:L649
04e2  20003ed6  0432       adds      r2, #4 ; FlashPrg.c:L650
04e4  20003ed8  0439       subs      r1, #4 ; FlashPrg.c:L651
04e6  20003eda  4ff00000   mov.w     r0, #0 ; FlashPrg.c:L0
04ea  20003ede  ebd1       bne       #0x4c4 ; FlashPrg.c:L644
04ec  20003ee0  f0bd       pop       {r4, r5, r6, r7, pc} ; FlashPrg.c:L748
04ee  20003ee2  0020       movs      r0, #0 ; FlashPrg.c:L0
04f0  20003ee4  f0bd       pop       {r4, r5, r6, r7, pc} ; FlashPrg.c:L748
04f2  20003ee6  0560       str       r5, [r0] ; FlashPrg.c:L255
04f4  20003ee8  00e0       b         #0x4f8
04f6  20003eea  2860       str       r0, [r5] ; FlashPrg.c:L181
04f8  20003eec  0120       movs      r0, #1 ; FlashPrg.c:L0
04fa  20003eee  f0bd       pop       {r4, r5, r6, r7, pc} ; FlashPrg.c:L748

Verify: image 0x04fc, Thumb symbol 0x04fd, size 268
04fc  20003ef0  70b5       push      {r4, r5, r6, lr} ; FlashPrg.c:L760
04fe  20003ef2  4ff6fc73   movw      r3, #0xfffc
0502  20003ef6  c4f20003   movt      r3, #0x4000
0506  20003efa  d3f800e0   ldr.w     lr, [r3] ; FlashPrg.c:L766
050a  20003efe  40f2000c   movw      ip, #0
050e  20003f02  bef1000f   cmp.w     lr, #0 ; FlashPrg.c:L766
0512  20003f06  c0f6217c   movt      ip, #0xf21
0516  20003f0a  0cd0       beq       #0x532
0518  20003f0c  4ff20003   movw      r3, #0xf000 ; FlashPrg.c:L0
051c  20003f10  c4f20003   movt      r3, #0x4000
0520  20003f14  1b6c       ldr       r3, [r3, #0x40] ; FlashPrg.c:L770
0522  20003f16  0cf56044   add.w     r4, ip, #0xe000
0526  20003f1a  1b05       lsls      r3, r3, #0x14
0528  20003f1c  5cbf       itt       pl
052a  20003f1e  0024       movpl     r4, #0
052c  20003f20  c0f62274   movtpl    r4, #0xf22
0530  20003f24  00e0       b         #0x534
0532  20003f26  6446       mov       r4, ip ; FlashPrg.c:L0
0534  20003f28  20f08053   bic       r3, r0, #0x10000000 ; FlashPrg.c:L783
0538  20003f2c  a342       cmp       r3, r4 ; FlashPrg.c:L785
053a  20003f2e  28d2       bhs       #0x58e
053c  20003f30  8507       lsls      r5, r0, #0x1e ; FlashPrg.c:L789
053e  20003f32  18bf       it        ne ; FlashPrg.c:L880
0540  20003f34  70bd       popne     {r4, r5, r6, pc}
0542  20003f36  0331       adds      r1, #3 ; FlashPrg.c:L792
0544  20003f38  6345       cmp       r3, ip ; FlashPrg.c:L794
0546  20003f3a  21f0030c   bic       ip, r1, #3 ; FlashPrg.c:L792
054a  20003f3e  37d2       bhs       #0x5bc ; FlashPrg.c:L794
054c  20003f40  bcf1000f   cmp.w     ip, #0 ; FlashPrg.c:L796
0550  20003f44  56d0       beq       #0x600
0552  20003f46  4cf20001   movw      r1, #0xc000 ; FlashPrg.c:L0
0556  20003f4a  4ff0000e   mov.w     lr, #0
055a  20003f4e  c4f20001   movt      r1, #0x4000
055e  20003f52  0124       movs      r4, #1
0560  20003f54  c1f80ce0   str.w     lr, [r1, #0xc] ; FlashPrg.c:L144
0564  20003f58  4b60       str       r3, [r1, #4] ; FlashPrg.c:L145
0566  20003f5a  0c61       str       r4, [r1, #0x10] ; FlashPrg.c:L146
0568  20003f5c  bff36f8f   isb       sy ; FlashPrg.c:L147
056c  20003f60  0d6c       ldr       r5, [r1, #0x40] ; FlashPrg.c:L149
056e  20003f62  ed07       lsls      r5, r5, #0x1f ; FlashPrg.c:L149
0570  20003f64  fcd1       bne       #0x56c
0572  20003f66  0d68       ldr       r5, [r1] ; FlashPrg.c:L151
0574  20003f68  6e06       lsls      r6, r5, #0x19 ; FlashPrg.c:L153
0576  20003f6a  42d4       bmi       #0x5fe
0578  20003f6c  8d68       ldr       r5, [r1, #8] ; FlashPrg.c:L159
057a  20003f6e  1668       ldr       r6, [r2] ; FlashPrg.c:L801
057c  20003f70  b542       cmp       r5, r6 ; FlashPrg.c:L801
057e  20003f72  3fd1       bne       #0x600
0580  20003f74  0433       adds      r3, #4 ; FlashPrg.c:L804
0582  20003f76  bcf1040c   subs.w    ip, ip, #4 ; FlashPrg.c:L806
0586  20003f7a  02f10402   add.w     r2, r2, #4 ; FlashPrg.c:L805
058a  20003f7e  e9d1       bne       #0x560 ; FlashPrg.c:L796
058c  20003f80  38e0       b         #0x600
058e  20003f82  4ef2ff06   movw      r6, #0xe0ff ; FlashPrg.c:L0
0592  20003f86  c0f62176   movt      r6, #0xf21
0596  20003f8a  b342       cmp       r3, r6 ; FlashPrg.c:L825
0598  20003f8c  32d8       bhi       #0x600
059a  20003f8e  bef1000f   cmp.w     lr, #0
059e  20003f92  2fd0       beq       #0x600
05a0  20003f94  0346       mov       r3, r0 ; FlashPrg.c:L0
05a2  20003f96  69b3       cbz       r1, #0x600 ; FlashPrg.c:L831
05a4  20003f98  0346       mov       r3, r0 ; FlashPrg.c:L0
05a6  20003f9a  00bf       nop       
05a8  20003f9c  1e78       ldrb      r6, [r3] ; FlashPrg.c:L833
05aa  20003f9e  1578       ldrb      r5, [r2] ; FlashPrg.c:L836
05ac  20003fa0  ae42       cmp       r6, r5 ; FlashPrg.c:L836
05ae  20003fa2  27d1       bne       #0x600
05b0  20003fa4  0133       adds      r3, #1 ; FlashPrg.c:L839
05b2  20003fa6  0139       subs      r1, #1 ; FlashPrg.c:L841
05b4  20003fa8  02f10102   add.w     r2, r2, #1 ; FlashPrg.c:L840
05b8  20003fac  f6d1       bne       #0x5a8 ; FlashPrg.c:L831
05ba  20003fae  21e0       b         #0x600
05bc  20003fb0  bcf1000f   cmp.w     ip, #0 ; FlashPrg.c:L811
05c0  20003fb4  1ed0       beq       #0x600
05c2  20003fb6  4ff20001   movw      r1, #0xf000 ; FlashPrg.c:L0
05c6  20003fba  4ff0000e   mov.w     lr, #0
05ca  20003fbe  c4f20001   movt      r1, #0x4000
05ce  20003fc2  0124       movs      r4, #1
05d0  20003fc4  c1f80ce0   str.w     lr, [r1, #0xc] ; FlashPrg.c:L192
05d4  20003fc8  4b60       str       r3, [r1, #4] ; FlashPrg.c:L193
05d6  20003fca  0c61       str       r4, [r1, #0x10] ; FlashPrg.c:L194
05d8  20003fcc  bff36f8f   isb       sy ; FlashPrg.c:L195
05dc  20003fd0  0d6c       ldr       r5, [r1, #0x40] ; FlashPrg.c:L197
05de  20003fd2  ed07       lsls      r5, r5, #0x1f ; FlashPrg.c:L197
05e0  20003fd4  fcd1       bne       #0x5dc
05e2  20003fd6  0d68       ldr       r5, [r1] ; FlashPrg.c:L199
05e4  20003fd8  6e06       lsls      r6, r5, #0x19 ; FlashPrg.c:L201
05e6  20003fda  0ad4       bmi       #0x5fe
05e8  20003fdc  8d68       ldr       r5, [r1, #8] ; FlashPrg.c:L207
05ea  20003fde  1668       ldr       r6, [r2] ; FlashPrg.c:L816
05ec  20003fe0  b542       cmp       r5, r6 ; FlashPrg.c:L816
05ee  20003fe2  07d1       bne       #0x600
05f0  20003fe4  0433       adds      r3, #4 ; FlashPrg.c:L819
05f2  20003fe6  bcf1040c   subs.w    ip, ip, #4 ; FlashPrg.c:L821
05f6  20003fea  02f10402   add.w     r2, r2, #4 ; FlashPrg.c:L820
05fa  20003fee  e9d1       bne       #0x5d0 ; FlashPrg.c:L811
05fc  20003ff0  00e0       b         #0x600
05fe  20003ff2  0d60       str       r5, [r1] ; FlashPrg.c:L0
0600  20003ff4  00f08050   and       r0, r0, #0x10000000
0604  20003ff8  1843       orrs      r0, r3 ; FlashPrg.c:L879
0606  20003ffa  70bd       pop       {r4, r5, r6, pc} ; FlashPrg.c:L880
