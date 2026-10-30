00407190  sal      al, 0xc6
00407193  inc      ebp
00407194  cld      
00407195  add      eax, 0x830c508d
0040719a  leave    
0040719b  push     eax
0040719d  xadd     dword ptr [edx], ecx
004071a0  dec      ecx
004071a1  test     ecx, ecx
004071a3  jg       0x4071af
004071a5  mov      ecx, dword ptr [eax]
004071a7  mov      edx, dword ptr [ecx]
004071a9  push     eax
004071aa  mov      eax, dword ptr [edx + 4]
004071ad  call     eax
004071af  mov      ecx, dword ptr [ebx + 0x66c]
004071b5  push     0
004071b7  push     edi
004071b8  push     0x130c
004071bd  push     ecx
004071be  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
004071c4  push     0
004071c6  push     0
004071c8  mov      ecx, ebx
004071ca  call     0x404800
004071cf  mov      eax, dword ptr [ebp - 0x588]
004071d5  add      eax, -0x10
004071d8  mov      byte ptr [ebp - 4], 4
004071dc  lea      edx, [eax + 0xc]
004071df  or       ecx, 0xffffffff
004071e2  lock xadd dword ptr [edx], ecx
004071e6  dec      ecx
004071e7  test     ecx, ecx
004071e9  jg       0x4071f5
004071eb  mov      ecx, dword ptr [eax]
004071ed  mov      edx, dword ptr [ecx]
004071ef  push     eax
004071f0  mov      eax, dword ptr [edx + 4]
004071f3  call     eax
004071f5  mov      eax, dword ptr [ebp - 0x58c]
004071fb  add      eax, -0x10
004071fe  mov      byte ptr [ebp - 4], 1
00407202  lea      ecx, [eax + 0xc]
00407205  or       edx, 0xffffffff
00407208  lock xadd dword ptr [ecx], edx
0040720c  dec      edx
0040720d  test     edx, edx
0040720f  jg       0x40721b
00407211  mov      ecx, dword ptr [eax]
00407213  mov      edx, dword ptr [ecx]
00407215  push     eax
00407216  mov      eax, dword ptr [edx + 4]
00407219  call     eax
0040721b  lea      ecx, [ebp - 0x57c]
00407221  mov      byte ptr [ebp - 4], 0
00407225  call     0x4251e5
0040722a  mov      eax, dword ptr [ebp - 0x584]
00407230  add      eax, -0x10
00407233  mov      dword ptr [ebp - 4], 0xffffffff
0040723a  lea      ecx, [eax + 0xc]
0040723d  or       edx, 0xffffffff
00407240  lock xadd dword ptr [ecx], edx
00407244  dec      edx
00407245  test     edx, edx
00407247  jg       0x407253
00407249  mov      ecx, dword ptr [eax]
0040724b  mov      edx, dword ptr [ecx]
0040724d  push     eax
0040724e  mov      eax, dword ptr [edx + 4]
00407251  call     eax
00407253  mov      ecx, dword ptr [ebp - 0xc]
00407256  mov      dword ptr fs:[0], ecx
0040725d  pop      ecx
0040725e  pop      edi
0040725f  pop      esi
00407260  pop      ebx
00407261  mov      ecx, dword ptr [ebp - 0x10]
00407264  xor      ecx, ebp
00407266  call     0x50bc27
0040726b  mov      esp, ebp
0040726d  pop      ebp
0040726e  ret      8
00407271  int3     
00407272  int3     
00407273  int3     
00407274  int3     
00407275  int3     
00407276  int3     
00407277  int3     
00407278  int3     
00407279  int3     
0040727a  int3     
0040727b  int3     
0040727c  int3     
0040727d  int3     
0040727e  int3     
0040727f  int3     
00407280  push     esi
00407281  mov      esi, ecx
00407283  call     0x41cdd5
00407288  movzx    edx, word ptr [eax + 8]
0040728c  xor      eax, eax
0040728e  lea      ecx, [esi + 0x73c]
00407294  cmp      edx, dword ptr [ecx]
00407296  je       0x4072a3
00407298  inc      eax
00407299  add      ecx, 0xc
0040729c  cmp      eax, 2
0040729f  jl       0x407294
004072a1  pop      esi
004072a2  ret      
004072a3  push     0
004072a5  push     eax
004072a6  mov      ecx, esi
004072a8  call     0x406d80
004072ad  pop      esi
004072ae  ret      
004072af  int3     
004072b0  push     ebp
004072b1  mov      ebp, esp
004072b3  push     -1
004072b5  push     0x529ad0
004072ba  mov      eax, dword ptr fs:[0]
004072c0  push     eax
004072c1  sub      esp, 8
004072c4  push     esi
004072c5  push     edi
004072c6  mov      eax, dword ptr [0x588250]
004072cb  xor      eax, ebp
004072cd  push     eax
004072ce  lea      eax, [ebp - 0xc]
004072d1  mov      dword ptr fs:[0], eax
004072d7  mov      esi, ecx
004072d9  push     1
004072db  call     0x41c6f3
004072e0  cmp      dword ptr [esi + 0x2c0], 0
004072e7  jne      0x407340
004072e9  cmp      dword ptr [esi + 0x2c4], 0
004072f0  jne      0x407340
004072f2  cmp      dword ptr [esi + 0x2c8], 0
004072f9  jne      0x407340
004072fb  cmp      dword ptr [esi + 0x2cc], 0
00407302  jne      0x407340
00407304  cmp      dword ptr [esi + 0x2d0], 0
0040730b  jne      0x407340
0040730d  cmp      dword ptr [esi + 0x2d4], 0
00407314  jne      0x407340
00407316  cmp      dword ptr [esi + 0x2d8], 0
0040731d  jne      0x407340
0040731f  push     0x10
00407321  push     0
00407323  push     0x53a214
00407328  mov      ecx, esi
0040732a  call     0x41c44f
0040732f  mov      ecx, dword ptr [ebp - 0xc]
00407332  mov      dword ptr fs:[0], ecx
00407339  pop      ecx
0040733a  pop      edi
0040733b  pop      esi
0040733c  mov      esp, ebp
0040733e  pop      ebp
0040733f  ret      
00407340  push     0
00407342  mov      ecx, esi
00407344  call     0x4045b0
00407349  push     0x5399ac
0040734e  lea      ecx, [ebp - 0x10]
00407351  call     0x406cc0
00407356  lea      ecx, [esi + 0x1a8]
0040735c  mov      dword ptr [ebp - 4], 0
00407363  call     0x4080d0
00407368  cmp      dword ptr [esi + 0x1e4], 0x408090
00407372  jne      0x4074cd
00407378  mov      eax, dword ptr [ebp - 0x10]
0040737b  cmp      dword ptr [eax - 0xc], 0
0040737f  jne      0x4073a0
00407381  cmp      dword ptr [esi + 0x2c0], 0
00407388  je       0x4073a0
0040738a  cmp      dword ptr [esi + 0x1b0], 0
00407391  jne      0x4073a0
00407393  push     0x53a1c0
00407398  lea      ecx, [ebp - 0x10]
0040739b  call     0x403c70
004073a0  mov      ecx, dword ptr [ebp - 0x10]
004073a3  cmp      dword ptr [ecx - 0xc], 0
004073a7  jne      0x4073c8
004073a9  cmp      dword ptr [esi + 0x2c4], 0
004073b0  je       0x4073c8
004073b2  cmp      dword ptr [esi + 0x1cc], 0
004073b9  jne      0x4073c8
004073bb  push     0x53a168
004073c0  lea      ecx, [ebp - 0x10]
004073c3  call     0x403c70
004073c8  mov      ecx, esi
004073ca  call     0x405190
004073cf  cmp      dword ptr [esi + 0x2d4], 0
004073d6  je       0x4073eb
004073d8  push     1
004073da  push     0
004073dc  push     0x7f
004073de  mov      ecx, esi
004073e0  call     0x41a070
004073e5  mov      dword ptr [esi + 0x2dc], eax
004073eb  cmp      dword ptr [esi + 0x2d0], 0
004073f2  je       0x4074b2
004073f8  mov      edx, dword ptr [esi + 0x5ec]
004073fe  push     0
00407400  push     0
00407402  push     0x147
00407407  push     edx
00407408  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
0040740e  mov      ecx, eax
00407410  mov      edx, 1
00407415  shl      edx, cl
00407417  mov      dword ptr [esi + 0x2e0], edx
0040741d  call     0x418e64
00407422  xor      ecx, ecx
00407424  test     eax, eax
00407426  setne    cl
00407429  test     ecx, ecx
0040742b  jne      0x407437
0040742d  push     0x80004005
00407432  call     0x401080
00407437  mov      edx, dword ptr [eax]
00407439  mov      ecx, eax
0040743b  mov      eax, dword ptr [edx + 0xc]
0040743e  call     eax
00407440  add      eax, 0x10
00407443  mov      dword ptr [ebp - 0x14], eax
00407446  lea      ecx, [ebp - 0x14]
00407449  push     ecx
0040744a  push     0x4bd
0040744f  mov      ecx, esi
00407451  mov      byte ptr [ebp - 4], 1
00407455  call     0x41ffb2
0040745a  mov      edx, dword ptr [ebp - 0x14]
0040745d  push     0x10
0040745f  push     0
00407461  push     edx
00407462  call     0x50c1c5
00407467  push     eax
00407468  mov      dword ptr [esi + 0x2e4], eax
0040746e  lea      eax, [ebp - 0x14]
00407471  push     0x539b74
00407476  push     eax
00407477  call     0x403880
0040747c  mov      ecx, dword ptr [ebp - 0x14]
0040747f  add      esp, 0x18
00407482  push     ecx
00407483  push     0x4bd
00407488  mov      ecx, esi
0040748a  call     0x41a09a
0040748f  mov      eax, dword ptr [ebp - 0x14]
00407492  add      eax, -0x10
00407495  mov      byte ptr [ebp - 4], 0
00407499  lea      edx, [eax + 0xc]
0040749c  or       ecx, 0xffffffff
0040749f  lock xadd dword ptr [edx], ecx
004074a3  dec      ecx
004074a4  test     ecx, ecx
004074a6  jg       0x4074b2
004074a8  mov      ecx, dword ptr [eax]
004074aa  mov      edx, dword ptr [ecx]
004074ac  push     eax
004074ad  mov      eax, dword ptr [edx + 4]
004074b0  call     eax
004074b2  mov      ecx, dword ptr [ebp - 0x10]
004074b5  cmp      dword ptr [ecx - 0xc], 0
004074b9  jne      0x4074dc
004074bb  push     0x408540
004074c0  lea      ecx, [esi + 0x1a8]
004074c6  call     0x4081d0
004074cb  jmp      0x4074dc
004074cd  push     0x1e
004074cf  push     0x53a128
004074d4  lea      ecx, [ebp - 0x10]
004074d7  call     0x403180
004074dc  mov      eax, dword ptr [ebp - 0x10]
004074df  cmp      dword ptr [eax - 0xc], 0
004074e3  je       0x4074fa
004074e5  push     0x10
004074e7  push     0
004074e9  push     eax
004074ea  mov      ecx, esi
004074ec  call     0x41c44f
004074f1  push     1
004074f3  mov      ecx, esi
004074f5  call     0x4045b0
004074fa  lea      ecx, [esi + 0x1a8]
00407500  call     0x4080e0
00407505  mov      eax, dword ptr [ebp - 0x10]
00407508  add      eax, -0x10
0040750b  mov      dword ptr [ebp - 4], 0xffffffff
00407512  lea      edx, [eax + 0xc]
00407515  or       ecx, 0xffffffff
00407518  lock xadd dword ptr [edx], ecx
0040751c  dec      ecx
0040751d  test     ecx, ecx
0040751f  jg       0x40752b
00407521  mov      ecx, dword ptr [eax]
00407523  mov      edx, dword ptr [ecx]
00407525  push     eax
00407526  mov      eax, dword ptr [edx + 4]
00407529  call     eax
0040752b  mov      ecx, dword ptr [ebp - 0xc]
0040752e  mov      dword ptr fs:[0], ecx
00407535  pop      ecx
00407536  pop      edi
00407537  pop      esi
00407538  mov      esp, ebp
0040753a  pop      ebp
0040753b  ret      
0040753c  int3     
0040753d  int3     
0040753e  int3     
0040753f  int3     
