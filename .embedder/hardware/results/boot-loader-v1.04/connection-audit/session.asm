00409f40  push     ebp
00409f41  mov      ebp, esp
00409f43  cmp      dword ptr [ebp + 8], 0
00409f47  push     esi
00409f48  mov      esi, ecx
00409f4a  jne      0x409f55
00409f4c  cmp      dword ptr [esi + 0x90], 2
00409f53  jne      0x409f61
00409f55  call     0x409e30
00409f5a  mov      ecx, esi
00409f5c  call     0x409be0
00409f61  pop      esi
00409f62  pop      ebp
00409f63  ret      4
00409f66  int3     
00409f67  int3     
00409f68  int3     
00409f69  int3     
00409f6a  int3     
00409f6b  int3     
00409f6c  int3     
00409f6d  int3     
00409f6e  int3     
00409f6f  int3     
00409f70  push     ebp
00409f71  mov      ebp, esp
00409f73  push     esi
00409f74  mov      esi, ecx
00409f76  mov      eax, dword ptr [esi + 0xcc]
00409f7c  cmp      eax, 1
00409f7f  je       0x409f86
00409f81  cmp      eax, 2
00409f84  jne      0x409f8f
00409f86  cmp      dword ptr [esi + 0x90], 2
00409f8d  je       0x409f99
00409f8f  mov      eax, 1
00409f94  pop      esi
00409f95  pop      ebp
00409f96  ret      0xc
00409f99  cmp      dword ptr [esi + 0xb0], 0
00409fa0  jne      0x409fb7
00409fa2  push     0x5711e4
00409fa7  lea      eax, [ebp + 8]
00409faa  push     eax
00409fab  mov      dword ptr [ebp + 8], 0x53a9a0
00409fb2  call     0x50b72f
00409fb7  cmp      dword ptr [ebp + 8], 0
00409fbb  je       0x409fe7
00409fbd  mov      ecx, dword ptr [ebp + 0x10]
00409fc0  mov      eax, 0xaf286bcb
00409fc5  mul      ecx
00409fc7  mov      eax, ecx
00409fc9  sub      eax, edx
00409fcb  shr      eax, 1
00409fcd  add      eax, edx
00409fcf  shr      eax, 4
00409fd2  imul     eax, eax, 0x13
00409fd5  sub      ecx, eax
00409fd7  lea      ecx, [ecx + ecx*4 + 5]
00409fdb  push     ecx
00409fdc  lea      ecx, [esi + 0xa8]
00409fe2  call     0x415de0
00409fe7  push     ebx
00409fe8  mov      ebx, dword ptr [ebp + 0xc]
00409feb  push     edi
00409fec  push     ebx
00409fed  lea      edx, [ebp + 0x10]
00409ff0  push     edx
00409ff1  push     0x3e
00409ff3  lea      eax, [esi + 0x45]
00409ff6  lea      edi, [esi + 0xa8]
00409ffc  push     eax
00409ffd  mov      ecx, edi
00409fff  call     0x415d40
0040a004  test     eax, eax
0040a006  je       0x40a02f
0040a008  push     ebx
0040a009  lea      ecx, [ebp + 0x10]
0040a00c  push     ecx
0040a00d  push     1
0040a00f  add      esi, 4
0040a012  push     esi
0040a013  mov      ecx, edi
0040a015  call     0x415c90
0040a01a  test     eax, eax
0040a01c  je       0x40a036
0040a01e  cmp      byte ptr [esi], 0x41
0040a021  jne      0x40a036
0040a023  pop      edi
0040a024  pop      ebx
0040a025  mov      eax, 1
0040a02a  pop      esi
0040a02b  pop      ebp
0040a02c  ret      0xc
0040a02f  mov      ecx, esi
0040a031  call     0x409e30
0040a036  pop      edi
0040a037  pop      ebx
0040a038  xor      eax, eax
0040a03a  pop      esi
0040a03b  pop      ebp
0040a03c  ret      0xc
0040a03f  int3     
0040a040  push     ebp
0040a041  mov      ebp, esp
0040a043  sub      esp, 8
0040a046  push     ebx
0040a047  push     esi
0040a048  mov      esi, ecx
0040a04a  xor      ebx, ebx
0040a04c  push     edi
0040a04d  cmp      dword ptr [esi + 0xb0], ebx
0040a053  jne      0x40a06a
0040a055  push     0x5711e4
0040a05a  lea      eax, [ebp + 8]
0040a05d  push     eax
0040a05e  mov      dword ptr [ebp + 8], 0x53a9a0
0040a065  call     0x50b72f
0040a06a  mov      edi, dword ptr [ebp + 0x10]
0040a06d  cmp      edi, 0x38
0040a070  jbe      0x40a077
0040a072  mov      edi, 0x38
0040a077  push     0x41
0040a079  lea      eax, [esi + 4]
0040a07c  push     ebx
0040a07d  push     eax
0040a07e  call     0x50c310
0040a083  mov      eax, dword ptr [ebp + 0xc]
0040a086  mov      ecx, dword ptr [ebp + 8]
0040a089  mov      edx, dword ptr [esi + 0x88]
0040a08f  add      esp, 0xc
0040a092  mov      dword ptr [esi + 5], ecx
0040a095  mov      dword ptr [esi + 9], edx
0040a098  cmp      eax, ebx
0040a09a  je       0x40a0ae
0040a09c  cmp      edi, ebx
0040a09e  jbe      0x40a0ae
0040a0a0  push     edi
0040a0a1  push     eax
0040a0a2  lea      eax, [esi + 0xd]
0040a0a5  push     eax
0040a0a6  call     0x50ad10
0040a0ab  add      esp, 0xc
0040a0ae  mov      dword ptr [ebp - 8], ebx
0040a0b1  mov      dword ptr [ebp + 0x10], ebx
0040a0b4  mov      dword ptr [ebp + 0xc], ebx
0040a0b7  mov      dword ptr [ebp - 4], ebx
0040a0ba  lea      eax, [esi + 0xa]
0040a0bd  mov      ecx, 0xf
0040a0c2  mov      dx, bx
0040a0c5  movzx    edi, byte ptr [eax - 1]
0040a0c9  add      dx, di
0040a0cc  movzx    edi, byte ptr [eax]
0040a0cf  add      word ptr [ebp - 4], di
0040a0d3  movzx    edi, byte ptr [eax + 1]
0040a0d7  add      word ptr [ebp + 0xc], di
0040a0db  movzx    edi, byte ptr [eax + 2]
0040a0df  add      word ptr [ebp + 0x10], di
0040a0e3  add      eax, 4
0040a0e6  dec      ecx
0040a0e7  jne      0x40a0c5
0040a0e9  mov      ecx, dword ptr [ebp + 0x10]
0040a0ec  add      ecx, dword ptr [ebp + 0xc]
0040a0ef  mov      word ptr [ebp - 8], dx
0040a0f3  add      ecx, dword ptr [ebp - 4]
0040a0f6  mov      eax, dword ptr [ebp - 8]
0040a0f9  add      eax, ecx
0040a0fb  add      eax, dword ptr [ebp + 8]
0040a0fe  xor      edi, edi
0040a100  mov      word ptr [esi + 0x8c], ax
0040a107  mov      word ptr [esi + 7], ax
0040a10b  mov      eax, dword ptr [esi + 0x90]
0040a111  dec      eax
0040a112  cmp      eax, 4
0040a115  ja       0x40a17b
0040a117  jmp      dword ptr [eax*4 + 0x40a190]
0040a11e  mov      edx, dword ptr [ebp + 0x14]
0040a121  push     edx
0040a122  lea      eax, [ebp + 0x14]
0040a125  push     eax
0040a126  jmp      0x40a154
0040a128  mov      ecx, dword ptr [ebp + 0x14]
0040a12b  push     ecx
0040a12c  lea      edx, [ebp + 0x14]
0040a12f  push     edx
0040a130  push     0x40
0040a132  lea      eax, [esi + 5]
0040a135  push     eax
0040a136  lea      ecx, [esi + 0xa8]
0040a13c  call     0x415d40
0040a141  jmp      0x40a165
0040a143  mov      ecx, dword ptr [ebp + 0x14]
0040a146  mov      al, byte ptr [esi + 0x90]
0040a14c  push     ecx
0040a14d  lea      edx, [ebp + 0x14]
0040a150  mov      byte ptr [esi + 6], al
0040a153  push     edx
0040a154  push     0x41
0040a156  lea      eax, [esi + 4]
0040a159  push     eax
0040a15a  lea      ecx, [esi + 0x9c]
0040a160  call     0x4139a0
0040a165  mov      edi, eax
0040a167  test     edi, edi
0040a169  je       0x40a17b
0040a16b  add      dword ptr [esi + 0x88], 2
0040a172  pop      edi
0040a173  pop      esi
0040a174  pop      ebx
0040a175  mov      esp, ebp
0040a177  pop      ebp
0040a178  ret      0x10
0040a17b  mov      ecx, esi
0040a17d  call     0x409e30
0040a182  mov      eax, edi
0040a184  pop      edi
0040a185  pop      esi
0040a186  pop      ebx
0040a187  mov      esp, ebp
0040a189  pop      ebp
0040a18a  ret      0x10
0040a18d  lea      ecx, [ecx]
0040a190  push     ds
0040a191  mov      eax, dword ptr [0xa1280040]
0040a196  inc      eax
0040a197  add      byte ptr [ebx - 0x5f], al
0040a19a  inc      eax
0040a19b  add      byte ptr [ebx - 0x5f], al
0040a19e  inc      eax
0040a19f  add      byte ptr [ebx - 0x5f], al
0040a1a2  inc      eax
0040a1a3  add      ah, cl
0040a1a5  int3     
0040a1a6  int3     
0040a1a7  int3     
0040a1a8  int3     
0040a1a9  int3     
0040a1aa  int3     
0040a1ab  int3     
0040a1ac  int3     
0040a1ad  int3     
0040a1ae  int3     
0040a1af  int3     
0040a1b0  push     ebp
0040a1b1  mov      ebp, esp
0040a1b3  push     ecx
0040a1b4  push     esi
0040a1b5  push     0x14
0040a1b7  push     4
0040a1b9  lea      eax, [ebp + 8]
0040a1bc  push     eax
0040a1bd  push     0xc1
0040a1c2  mov      esi, ecx
0040a1c4  call     0x40a040
0040a1c9  test     eax, eax
0040a1cb  je       0x40a21c
0040a1cd  cmp      dword ptr [esi + 0xb0], 0
0040a1d4  jne      0x40a1eb
0040a1d6  push     0x5711e4
0040a1db  lea      ecx, [ebp - 4]
0040a1de  push     ecx
0040a1df  mov      dword ptr [ebp - 4], 0x53a9a0
0040a1e6  call     0x50b72f
0040a1eb  mov      eax, dword ptr [esi + 0x90]
0040a1f1  dec      eax
0040a1f2  cmp      eax, 4
0040a1f5  ja       0x40a21c
0040a1f7  jmp      dword ptr [eax*4 + 0x40a280]
0040a1fe  push     0x7530
0040a203  lea      edx, [ebp + 8]
0040a206  push     edx
0040a207  push     0x41
0040a209  lea      eax, [esi + 4]
0040a20c  push     eax
0040a20d  lea      ecx, [esi + 0x9c]
0040a213  call     0x413920
0040a218  test     eax, eax
0040a21a  jne      0x40a25f
0040a21c  xor      eax, eax
0040a21e  pop      esi
0040a21f  mov      esp, ebp
0040a221  pop      ebp
0040a222  ret      4
0040a225  push     0x7530
0040a22a  lea      ecx, [ebp + 8]
0040a22d  push     ecx
0040a22e  push     0xc
0040a230  lea      edx, [esi + 5]
0040a233  push     edx
0040a234  lea      ecx, [esi + 0xa8]
0040a23a  call     0x415c90
0040a23f  jmp      0x40a218
0040a241  push     0x7530
0040a246  lea      eax, [ebp + 8]
0040a249  push     eax
0040a24a  push     0x41
0040a24c  lea      ecx, [esi + 4]
0040a24f  push     ecx
0040a250  lea      ecx, [esi + 0x9c]
0040a256  call     0x413920
0040a25b  test     eax, eax
0040a25d  je       0x40a21c
0040a25f  cmp      dword ptr [ebp + 8], 0xc
0040a263  jb       0x40a21c
0040a265  mov      edx, dword ptr [esi + 0x88]
0040a26b  dec      edx
0040a26c  cmp      dword ptr [esi + 9], edx
0040a26f  jne      0x40a21c
0040a271  mov      eax, 1
0040a276  pop      esi
0040a277  mov      esp, ebp
0040a279  pop      ebp
0040a27a  ret      4
0040a27d  lea      ecx, [ecx]
0040a280  .byte    0xfe
0040a281  mov      eax, dword ptr [0xa2250040]
0040a286  inc      eax
0040a287  add      byte ptr [ecx - 0x5e], al
0040a28a  inc      eax
0040a28b  add      byte ptr [ecx - 0x5e], al
0040a28e  inc      eax
0040a28f  add      byte ptr [ecx - 0x5e], al
0040a292  inc      eax
0040a293  add      ah, cl
0040a295  int3     
0040a296  int3     
0040a297  int3     
0040a298  int3     
0040a299  int3     
0040a29a  int3     
0040a29b  int3     
0040a29c  int3     
0040a29d  int3     
0040a29e  int3     
0040a29f  int3     
0040a2a0  push     ebp
0040a2a1  mov      ebp, esp
0040a2a3  sub      esp, 8
0040a2a6  mov      eax, dword ptr [ebp + 8]
0040a2a9  mov      edx, dword ptr [ebp + 0xc]
0040a2ac  push     0x14
0040a2ae  mov      dword ptr [ebp - 8], eax
0040a2b1  push     8
0040a2b3  lea      eax, [ebp - 8]
0040a2b6  push     eax
0040a2b7  push     0xb0
0040a2bc  mov      dword ptr [ebp - 4], edx
0040a2bf  call     0x40a040
0040a2c4  mov      esp, ebp
0040a2c6  pop      ebp
0040a2c7  ret      8
0040a2ca  int3     
0040a2cb  int3     
0040a2cc  int3     
0040a2cd  int3     
0040a2ce  int3     
0040a2cf  int3     
