00407370  inc      eax
00407371  add      byte ptr [edi], cl
00407373  test     dword ptr [ebp + 1], edx
00407376  add      byte ptr [eax], al
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
00407540  push     ebp
00407541  mov      ebp, esp
00407543  sub      esp, 0x228
00407549  mov      eax, dword ptr [0x588250]
0040754e  xor      eax, ebp
00407550  mov      dword ptr [ebp - 4], eax
00407553  push     ebx
00407554  mov      ebx, dword ptr [0x538510] ; SHELL32.dll!DragQueryFileW
0040755a  push     esi
0040755b  xor      eax, eax
0040755d  push     edi
0040755e  mov      edi, dword ptr [ebp + 8]
00407561  push     eax
00407562  push     eax
00407563  push     -1
00407565  push     edi
00407566  mov      esi, ecx
00407568  mov      dword ptr [ebp - 0x220], edi
0040756e  mov      dword ptr [ebp - 0x21c], eax
00407574  mov      dword ptr [ebp - 0x218], eax
0040757a  mov      dword ptr [ebp - 0x214], eax
00407580  mov      dword ptr [ebp - 0x210], eax
00407586  call     ebx
00407588  test     eax, eax
0040758a  je       0x40762f
00407590  cmp      dword ptr [esi + 0x1e4], 0x408540
0040759a  je       0x40762f
004075a0  lea      eax, [ebp - 0x228]
004075a6  push     eax
004075a7  push     edi
004075a8  call     dword ptr [0x53850c] ; SHELL32.dll!DragQueryPoint
004075ae  push     0x104
004075b3  lea      ecx, [ebp - 0x20c]
004075b9  push     ecx
004075ba  push     0
004075bc  push     edi
004075bd  call     ebx
004075bf  xor      ebx, ebx
004075c1  lea      edi, [esi + 0x740]
004075c7  mov      edx, dword ptr [edi]
004075c9  push     edx
004075ca  mov      ecx, esi
004075cc  call     0x41a01d
004075d1  mov      edx, dword ptr [eax + 0x20]
004075d4  lea      ecx, [ebp - 0x21c]
004075da  push     ecx
004075db  push     edx
004075dc  call     dword ptr [0x5388a0] ; USER32.dll!GetWindowRect
004075e2  lea      eax, [ebp - 0x21c]
004075e8  push     eax
004075e9  mov      ecx, esi
004075eb  call     0x421f6d
004075f0  mov      ecx, dword ptr [ebp - 0x224]
004075f6  mov      edx, dword ptr [ebp - 0x228]
004075fc  push     ecx
004075fd  push     edx
004075fe  lea      eax, [ebp - 0x21c]
00407604  push     eax
00407605  call     dword ptr [0x538888] ; USER32.dll!PtInRect
0040760b  test     eax, eax
0040760d  jne      0x40761a
0040760f  inc      ebx
00407610  add      edi, 0xc
00407613  cmp      ebx, 2
00407616  jl       0x4075c7
00407618  jmp      0x407629
0040761a  lea      ecx, [ebp - 0x20c]
