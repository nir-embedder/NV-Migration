00407ee0  inc      edx
00407ee1  add      al, 0xff
00407ee3  sar      byte ptr [ecx], 1
00407ee5  pop      ebp
00407ee6  call     0x4dcb8b5d
00407eeb  aam      0x51
00407eed  call     0x41774d
00407ef2  add      esp, 4
00407ef5  xor      edi, edi
00407ef7  xor      edx, edx
00407ef9  cmp      dword ptr [ebp - 0x34], 0x10
00407efd  mov      dword ptr [ebp - 0x18], 7
00407f04  mov      dword ptr [ebp - 0x1c], edi
00407f07  mov      word ptr [ebp - 0x2c], dx
00407f0b  jb       0x407f19
00407f0d  mov      eax, dword ptr [ebp - 0x48]
00407f10  push     eax
00407f11  call     0x41774d
00407f16  add      esp, 4
00407f19  mov      dword ptr [ebp - 0x38], edi
00407f1c  lea      ecx, [ebp - 0x144]
00407f22  mov      dword ptr [ebp - 0x34], 0xf
00407f29  mov      byte ptr [ebp - 0x48], 0
00407f2d  mov      byte ptr [ebp - 4], 0
00407f31  call     0x402cc0
00407f36  call     0x40b1f0
00407f3b  mov      ecx, esi
00407f3d  cmp      eax, 0x44
00407f40  jne      0x407f49
00407f42  push     0x53a440
00407f47  jmp      0x407f4e
00407f49  push     0x539d64
00407f4e  push     0x4bd
00407f53  call     0x41a09a
00407f58  mov      ecx, dword ptr [esi + 0x20]
00407f5b  push     1
00407f5d  push     0
00407f5f  push     ecx
00407f60  call     dword ptr [0x538898] ; USER32.dll!InvalidateRect
00407f66  mov      eax, dword ptr [ebp - 0xa0]
00407f6c  add      eax, -0x10
00407f6f  mov      dword ptr [ebp - 4], 0xffffffff
00407f76  lea      edx, [eax + 0xc]
00407f79  or       ecx, 0xffffffff
00407f7c  lock xadd dword ptr [edx], ecx
00407f80  dec      ecx
00407f81  test     ecx, ecx
00407f83  jg       0x407f8f
00407f85  mov      ecx, dword ptr [eax]
00407f87  mov      edx, dword ptr [ecx]
00407f89  push     eax
00407f8a  mov      eax, dword ptr [edx + 4]
00407f8d  call     eax
00407f8f  mov      ecx, dword ptr [ebp - 0xc]
00407f92  mov      dword ptr fs:[0], ecx
00407f99  pop      ecx
00407f9a  pop      edi
00407f9b  pop      esi
00407f9c  pop      ebx
00407f9d  mov      ecx, dword ptr [ebp - 0x10]
00407fa0  xor      ecx, ebp
00407fa2  call     0x50bc27
00407fa7  mov      esp, ebp
00407fa9  pop      ebp
00407faa  ret      
00407fab  int3     
00407fac  int3     
00407fad  int3     
00407fae  int3     
00407faf  int3     
00407fb0  mov      eax, 0x53a258
00407fb5  ret      
00407fb6  int3     
00407fb7  int3     
00407fb8  int3     
00407fb9  int3     
00407fba  int3     
00407fbb  int3     
00407fbc  int3     
00407fbd  int3     
00407fbe  int3     
00407fbf  int3     
00407fc0  push     esi
00407fc1  mov      esi, ecx
00407fc3  mov      eax, dword ptr [esi + 0x3c]
00407fc6  test     eax, eax
00407fc8  je       0x407fdb
00407fca  lea      ebx, [ebx]
00407fd0  mov      ecx, esi
00407fd2  call     eax
00407fd4  mov      eax, dword ptr [esi + 0x3c]
00407fd7  test     eax, eax
00407fd9  jne      0x407fd0
00407fdb  xor      eax, eax
00407fdd  pop      esi
00407fde  ret      4
00407fe1  int3     
00407fe2  int3     
00407fe3  int3     
00407fe4  int3     
00407fe5  int3     
00407fe6  int3     
00407fe7  int3     
00407fe8  int3     
00407fe9  int3     
00407fea  int3     
00407feb  int3     
00407fec  int3     
00407fed  int3     
00407fee  int3     
00407fef  int3     
00407ff0  int3     
00407ff1  int3     
00407ff2  int3     
00407ff3  int3     
00407ff4  int3     
00407ff5  int3     
00407ff6  int3     
00407ff7  int3     
00407ff8  int3     
00407ff9  int3     
00407ffa  int3     
00407ffb  int3     
00407ffc  int3     
00407ffd  int3     
00407ffe  int3     
00407fff  int3     
00408000  push     esi
00408001  mov      esi, ecx
00408003  cmp      dword ptr [esi + 0x3c], 0x408000
0040800a  jne      0x408021
0040800c  push     edi
0040800d  mov      edi, dword ptr [0x538480] ; KERNEL32.dll!Sleep
00408013  push     0x64
00408015  call     edi
00408017  cmp      dword ptr [esi + 0x3c], 0x408000
0040801e  je       0x408013
00408020  pop      edi
00408021  pop      esi
00408022  ret      
00408023  int3     
00408024  int3     
00408025  int3     
00408026  int3     
00408027  int3     
00408028  int3     
00408029  int3     
0040802a  int3     
0040802b  int3     
0040802c  int3     
0040802d  int3     
0040802e  int3     
0040802f  int3     
00408030  push     ebx
00408031  push     esi
00408032  mov      esi, ecx
00408034  mov      ebx, 0x408030
00408039  cmp      dword ptr [esi + 0x3c], ebx
0040803c  jne      0x408082
0040803e  mov      eax, dword ptr [esi + 0x40]
00408041  test     eax, eax
00408043  je       0x408057
00408045  mov      eax, dword ptr [eax]
00408047  push     0
00408049  push     7
0040804b  push     0x8001
00408050  push     eax
00408051  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
00408057  lea      ecx, [esi + 0x140]
0040805d  call     0x409e30
00408062  mov      dword ptr [esi + 0x248], 0
0040806c  cmp      dword ptr [esi + 0x3c], ebx
0040806f  jne      0x408082
00408071  push     edi
00408072  mov      edi, dword ptr [0x538480] ; KERNEL32.dll!Sleep
00408078  push     0x64
0040807a  call     edi
0040807c  cmp      dword ptr [esi + 0x3c], ebx
0040807f  je       0x408078
00408081  pop      edi
00408082  pop      esi
00408083  pop      ebx
00408084  ret      
00408085  int3     
00408086  int3     
00408087  int3     
00408088  int3     
00408089  int3     
0040808a  int3     
0040808b  int3     
0040808c  int3     
0040808d  int3     
0040808e  int3     
0040808f  int3     
00408090  push     ebx
00408091  push     esi
00408092  mov      esi, ecx
00408094  mov      ebx, 0x408090
00408099  cmp      dword ptr [esi + 0x3c], ebx
0040809c  jne      0x4080cd
0040809e  mov      eax, dword ptr [esi + 0x40]
004080a1  test     eax, eax
004080a3  je       0x4080b7
004080a5  mov      eax, dword ptr [eax]
004080a7  push     3
004080a9  push     7
004080ab  push     0x8001
004080b0  push     eax
004080b1  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
004080b7  cmp      dword ptr [esi + 0x3c], ebx
004080ba  jne      0x4080cd
004080bc  push     edi
004080bd  mov      edi, dword ptr [0x538480] ; KERNEL32.dll!Sleep
004080c3  push     0x64
004080c5  call     edi
004080c7  cmp      dword ptr [esi + 0x3c], ebx
004080ca  je       0x4080c3
004080cc  pop      edi
004080cd  pop      esi
004080ce  pop      ebx
004080cf  ret      
004080d0  mov      eax, dword ptr [ecx + 0x48]
004080d3  push     -1
004080d5  push     eax
004080d6  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
004080dc  ret      
004080dd  int3     
004080de  int3     
004080df  int3     
004080e0  mov      eax, dword ptr [ecx + 0x48]
004080e3  push     eax
004080e4  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
004080ea  ret      
004080eb  int3     
004080ec  int3     
004080ed  int3     
004080ee  int3     
004080ef  int3     
004080f0  push     ebp
004080f1  mov      ebp, esp
004080f3  mov      eax, dword ptr [ebp + 0x14]
004080f6  mov      edx, dword ptr [eax]
004080f8  push     esi
004080f9  mov      esi, ecx
004080fb  mov      ecx, dword ptr [eax + 4]
004080fe  mov      eax, dword ptr [ebp + 8]
00408101  push     ecx
00408102  push     edx
00408103  push     eax
00408104  call     0x40b100
00408109  add      esp, 0xc
0040810c  test     al, al
0040810e  je       0x40815a
00408110  mov      ecx, dword ptr [0x589a94]
00408116  mov      dword ptr [esi + 0xf8], ecx
0040811c  mov      edx, dword ptr [0x589a98]
00408122  mov      dword ptr [esi + 0xfc], edx
00408128  mov      eax, dword ptr [0x589a9c]
0040812d  mov      dword ptr [esi + 0x100], eax
00408133  mov      ecx, dword ptr [0x589aa4]
00408139  mov      dword ptr [esi + 0x10c], ecx
0040813f  mov      edx, dword ptr [0x589aa0]
00408145  mov      dword ptr [esi + 0x108], edx
0040814b  mov      eax, dword ptr [0x589aa8]
00408150  mov      dword ptr [esi + 0x58], eax
00408153  mov      al, 1
00408155  pop      esi
00408156  pop      ebp
00408157  ret      0x10
0040815a  mov      ecx, dword ptr [0x589aa0]
00408160  mov      dword ptr [esi + 0x108], ecx
00408166  mov      edx, dword ptr [0x589aa8]
0040816c  mov      dword ptr [esi + 0x58], edx
0040816f  xor      al, al
00408171  pop      esi
00408172  pop      ebp
00408173  ret      0x10
00408176  int3     
00408177  int3     
00408178  int3     
00408179  int3     
0040817a  int3     
0040817b  int3     
0040817c  int3     
0040817d  int3     
0040817e  int3     
0040817f  int3     
00408180  push     ebp
00408181  mov      ebp, esp
00408183  sub      esp, 0x10
00408186  mov      eax, dword ptr [ebp + 8]
00408189  mov      ecx, dword ptr [eax + 0xc]
0040818c  push     ebx
0040818d  mov      ebx, dword ptr [eax + 8]
00408190  push     esi
00408191  mov      esi, dword ptr [eax]
00408193  push     edi
00408194  mov      edi, dword ptr [eax + 4]
00408197  push     0
00408199  push     1
0040819b  push     ecx
0040819c  mov      dword ptr [ebp - 4], ecx
0040819f  call     dword ptr [0x538474] ; KERNEL32.dll!ReleaseSemaphore
004081a5  push     0
004081a7  call     0x50c2a5
004081ac  push     eax
004081ad  call     0x50c2f6
004081b2  add      esp, 8
004081b5  push     ebx
004081b6  mov      ecx, edi
004081b8  call     esi
004081ba  pop      edi
004081bb  pop      esi
004081bc  pop      ebx
004081bd  mov      esp, ebp
004081bf  pop      ebp
004081c0  ret      
004081c1  int3     
004081c2  int3     
004081c3  int3     
004081c4  int3     
004081c5  int3     
004081c6  int3     
004081c7  int3     
004081c8  int3     
004081c9  int3     
004081ca  int3     
004081cb  int3     
004081cc  int3     
004081cd  int3     
004081ce  int3     
004081cf  int3     
004081d0  push     ebp
004081d1  mov      ebp, esp
004081d3  push     esi
004081d4  mov      esi, ecx
004081d6  mov      eax, dword ptr [esi + 0x48]
004081d9  push     -1
004081db  push     eax
004081dc  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
004081e2  mov      eax, dword ptr [esi + 0x3c]
004081e5  mov      dword ptr [esi + 0x44], eax
004081e8  test     eax, eax
004081ea  je       0x4081f2
004081ec  mov      ecx, dword ptr [ebp + 8]
004081ef  mov      dword ptr [esi + 0x3c], ecx
004081f2  mov      edx, dword ptr [esi + 0x48]
004081f5  push     edx
004081f6  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
004081fc  pop      esi
004081fd  pop      ebp
004081fe  ret      4
00408201  int3     
00408202  int3     
00408203  int3     
00408204  int3     
00408205  int3     
00408206  int3     
00408207  int3     
00408208  int3     
00408209  int3     
0040820a  int3     
0040820b  int3     
0040820c  int3     
0040820d  int3     
0040820e  int3     
0040820f  int3     
00408210  push     ebp
00408211  mov      ebp, esp
00408213  push     -1
00408215  push     0x529c30
0040821a  mov      eax, dword ptr fs:[0]
00408220  push     eax
00408221  sub      esp, 0xc
00408224  push     ebx
00408225  push     esi
00408226  push     edi
00408227  mov      eax, dword ptr [0x588250]
0040822c  xor      eax, ebp
0040822e  push     eax
0040822f  lea      eax, [ebp - 0xc]
00408232  mov      dword ptr fs:[0], eax
00408238  mov      dword ptr [ebp - 0x10], esp
0040823b  mov      esi, ecx
0040823d  mov      dword ptr [ebp - 0x14], esi
00408240  cmp      dword ptr [esi + 0x3c], 0x408210
00408247  jne      0x408420
0040824d  mov      eax, dword ptr [esi + 0x40]
00408250  test     eax, eax
00408252  je       0x408266
00408254  mov      eax, dword ptr [eax]
00408256  push     1
00408258  push     7
0040825a  push     0x8001
0040825f  push     eax
00408260  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
00408266  lea      ecx, [esi + 0x140]
0040826c  call     0x409e30
00408271  mov      dword ptr [ebp - 0x18], 0
00408278  mov      ebx, dword ptr [0x53846c] ; KERNEL32.dll!GetTickCount
0040827e  cmp      dword ptr [esi + 0x3c], 0x408210
00408285  jne      0x408420
0040828b  lea      ecx, [esi + 0x140]
00408291  call     0x409be0
00408296  test     al, al
00408298  je       0x408390
0040829e  mov      ecx, dword ptr [ebp - 0x18]
004082a1  mov      edx, dword ptr [esi + 0x114]
004082a7  push     ecx
004082a8  push     0xa
004082aa  push     edx
004082ab  lea      ecx, [esi + 0x140]
004082b1  mov      dword ptr [esi + 0x248], 2
004082bb  mov      dword ptr [ebp - 4], 0
004082c2  call     0x409f70
004082c7  test     eax, eax
004082c9  je       0x40835f
004082cf  push     0xa
004082d1  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
004082d7  push     0
004082d9  lea      ecx, [esi + 0x140]
004082df  call     0x409f40
004082e4  mov      dword ptr [ebp - 4], 0xffffffff
004082eb  cmp      dword ptr [esi + 0x3c], 0x408210
004082f2  jne      0x408420
004082f8  lea      ecx, [esi + 0x140]
004082fe  call     0x409be0
00408303  test     al, al
00408305  je       0x4083ec
0040830b  mov      dword ptr [esi + 0x248], 2
00408315  call     ebx
00408317  mov      eax, dword ptr [esi + 0x114]
0040831d  push     0x28
0040831f  push     eax
00408320  lea      ecx, [esi + 0x140]
00408326  mov      dword ptr [ebp - 4], 2
0040832d  call     0x40ad40
00408332  test     eax, eax
00408334  je       0x4082e4
00408336  mov      ecx, dword ptr [esi + 0x48]
00408339  push     -1
0040833b  push     ecx
0040833c  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00408342  mov      eax, dword ptr [esi + 0x3c]
00408345  mov      dword ptr [esi + 0x44], eax
00408348  test     eax, eax
0040834a  je       0x408353
0040834c  mov      dword ptr [esi + 0x3c], 0x408f40
00408353  mov      edx, dword ptr [esi + 0x48]
00408356  push     edx
00408357  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
0040835d  jmp      0x4082e4
0040835f  inc      dword ptr [ebp - 0x18]
00408362  mov      dword ptr [ebp - 4], 0xffffffff
00408369  jmp      0x40827e
0040836e  mov      ecx, dword ptr [ebp - 0x14]
00408371  push     0x408030
00408376  call     0x4081d0
0040837b  mov      dword ptr [ebp - 4], 0xffffffff
00408382  mov      eax, 0x408388
00408387  ret      
00408388  mov      esi, dword ptr [ebp - 0x14]
0040838b  jmp      0x408278
00408390  mov      dword ptr [esi + 0x248], 1
0040839a  call     ebx
0040839c  cmp      dword ptr [esi + 0x3c], 0x408210
004083a3  mov      edi, eax
004083a5  jne      0x408420
004083a7  call     ebx
004083a9  sub      eax, edi
004083ab  cmp      eax, 0x3e8
004083b0  ja       0x40827e
004083b6  cmp      dword ptr [esi + 0x3c], 0x408210
004083bd  je       0x4083a7
004083bf  jmp      0x40827e
004083c4  mov      ecx, dword ptr [ebp - 0x14]
004083c7  push     0x408030
004083cc  call     0x4081d0
004083d1  mov      dword ptr [ebp - 4], 0xffffffff
004083d8  mov      eax, 0x4083de
004083dd  ret      
004083de  mov      esi, dword ptr [ebp - 0x14]
004083e1  mov      ebx, dword ptr [0x53846c] ; KERNEL32.dll!GetTickCount
004083e7  jmp      0x4082eb
004083ec  mov      dword ptr [esi + 0x248], 1
004083f6  call     ebx
004083f8  cmp      dword ptr [esi + 0x3c], 0x408210
004083ff  mov      edi, eax
00408401  jne      0x408420
00408403  call     ebx
00408405  sub      eax, edi
00408407  cmp      eax, 0x3e8
0040840c  ja       0x4082eb
00408412  cmp      dword ptr [esi + 0x3c], 0x408210
00408419  je       0x408403
0040841b  jmp      0x4082eb
00408420  mov      ecx, dword ptr [ebp - 0xc]
00408423  mov      dword ptr fs:[0], ecx
0040842a  pop      ecx
0040842b  pop      edi
0040842c  pop      esi
0040842d  pop      ebx
0040842e  mov      esp, ebp
00408430  pop      ebp
00408431  ret      
00408432  int3     
00408433  int3     
00408434  int3     
00408435  int3     
00408436  int3     
00408437  int3     
00408438  int3     
00408439  int3     
0040843a  int3     
0040843b  int3     
0040843c  int3     
0040843d  int3     
0040843e  int3     
0040843f  int3     
00408440  push     esi
00408441  mov      esi, ecx
00408443  mov      eax, dword ptr [esi + 0xc]
00408446  test     eax, eax
00408448  je       0x408453
0040844a  push     eax
0040844b  call     0x41774d
00408450  add      esp, 4
00408453  mov      dword ptr [esi + 0xc], 0
0040845a  mov      dword ptr [esi + 0x10], 0
00408461  mov      dword ptr [esi + 0x14], 0
00408468  mov      esi, dword ptr [esi]
0040846a  sub      esi, 0x10
0040846d  lea      eax, [esi + 0xc]
00408470  or       ecx, 0xffffffff
00408473  lock xadd dword ptr [eax], ecx
00408477  dec      ecx
00408478  test     ecx, ecx
0040847a  jg       0x408486
0040847c  mov      ecx, dword ptr [esi]
0040847e  mov      edx, dword ptr [ecx]
00408480  mov      eax, dword ptr [edx + 4]
00408483  push     esi
00408484  call     eax
00408486  pop      esi
00408487  ret      
00408488  int3     
00408489  int3     
0040848a  int3     
0040848b  int3     
0040848c  int3     
0040848d  int3     
0040848e  int3     
0040848f  int3     
00408490  push     ebp
00408491  mov      ebp, esp
00408493  push     -1
00408495  push     0x529c66
0040849a  mov      eax, dword ptr fs:[0]
004084a0  push     eax
004084a1  push     ecx
004084a2  push     esi
004084a3  push     edi
004084a4  mov      eax, dword ptr [0x588250]
004084a9  xor      eax, ebp
004084ab  push     eax
004084ac  lea      eax, [ebp - 0xc]
004084af  mov      dword ptr fs:[0], eax
004084b5  mov      esi, ecx
004084b7  mov      dword ptr [ebp - 0x10], esi
004084ba  mov      dword ptr [esi], 0x53a4dc
004084c0  mov      eax, dword ptr [esi + 0x48]
004084c3  mov      edi, dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
004084c9  push     -1
004084cb  push     eax
004084cc  mov      dword ptr [ebp - 4], 0
004084d3  call     edi
004084d5  mov      eax, dword ptr [esi + 0x3c]
004084d8  mov      dword ptr [esi + 0x44], eax
004084db  test     eax, eax
004084dd  je       0x4084e6
004084df  mov      dword ptr [esi + 0x3c], 0
004084e6  mov      ecx, dword ptr [esi + 0x48]
004084e9  push     ecx
004084ea  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
004084f0  mov      edx, dword ptr [esi + 0x4c]
004084f3  mov      eax, dword ptr [edx + 0x2c]
004084f6  push     0x1388
004084fb  push     eax
004084fc  call     edi
004084fe  lea      ecx, [esi + 0x140]
00408504  call     0x409ae0
00408509  push     0x408440
0040850e  push     2
00408510  push     0x1c
00408512  add      esi, 4
00408515  push     esi
00408516  mov      dword ptr [ebp - 4], 0xffffffff
0040851d  call     0x50bc94
00408522  mov      ecx, dword ptr [ebp - 0xc]
00408525  mov      dword ptr fs:[0], ecx
0040852c  pop      ecx
0040852d  pop      edi
0040852e  pop      esi
0040852f  mov      esp, ebp
00408531  pop      ebp
00408532  ret      
00408533  int3     
00408534  int3     
00408535  int3     
00408536  int3     
00408537  int3     
00408538  int3     
00408539  int3     
0040853a  int3     
0040853b  int3     
0040853c  int3     
0040853d  int3     
0040853e  int3     
0040853f  int3     
00408540  push     ebp
00408541  mov      ebp, esp
00408543  push     -1
00408545  push     0x529ca8
0040854a  mov      eax, dword ptr fs:[0]
00408550  push     eax
00408551  sub      esp, 0x60
00408554  mov      eax, dword ptr [0x588250]
00408559  xor      eax, ebp
0040855b  mov      dword ptr [ebp - 0x14], eax
0040855e  push     ebx
0040855f  push     esi
00408560  push     edi
00408561  push     eax
00408562  lea      eax, [ebp - 0xc]
00408565  mov      dword ptr fs:[0], eax
0040856b  mov      dword ptr [ebp - 0x10], esp
0040856e  mov      ebx, ecx
00408570  cmp      dword ptr [ebx + 0x3c], 0x408540
00408577  mov      dword ptr [ebp - 0x6c], ebx
0040857a  jne      0x408865
00408580  xor      edi, edi
00408582  push     edi
00408583  mov      dword ptr [ebx + 0x248], edi
00408589  mov      dword ptr [ebp - 4], edi
0040858c  call     0x50c2a5
00408591  add      esp, 4
00408594  lea      ecx, [ebx + 0x140]
0040859a  mov      dword ptr [ebp - 0x60], eax
0040859d  mov      dword ptr [ebp - 0x5c], edx
004085a0  call     0x40a6f0
004085a5  cmp      eax, edi
004085a7  jne      0x4085c9
004085a9  mov      eax, dword ptr [ebx + 0x48]
004085ac  push     -1
004085ae  push     eax
004085af  mov      dword ptr [ebx + 0x248], 2
004085b9  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
004085bf  mov      eax, dword ptr [ebx + 0x3c]
004085c2  cmp      eax, edi
004085c4  jmp      0x408c43
004085c9  mov      eax, dword ptr [0x589a74]
004085ce  cmp      dword ptr [ebx + 0x124], edi
004085d4  je       0x408661
004085da  cmp      eax, 0x42
004085dd  je       0x408742
004085e3  cmp      eax, 0x43
004085e6  je       0x408742
004085ec  lea      ecx, [ebx + 0x140]
004085f2  call     0x40ad20
004085f7  cmp      eax, edi
004085f9  je       0x408727
004085ff  mov      eax, dword ptr [0x589a74]
00408604  cmp      eax, 0x3d
00408607  je       0x408713
0040860d  cmp      eax, 0x40
00408610  je       0x408713
00408616  call     0x40b1f0
0040861b  cmp      eax, 0x49
0040861e  je       0x4086fd
00408624  call     0x40b1f0
00408629  cmp      eax, 0x4a
0040862c  je       0x4086fd
00408632  call     0x40b1f0
00408637  cmp      eax, 0x4b
0040863a  je       0x4086fd
00408640  push     0xc8
00408645  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
0040864b  lea      eax, [ebx + 0x5c]
0040864e  push     0xe
00408650  push     eax
00408651  lea      ecx, [ebx + 0x140]
00408657  call     0x40a810
0040865c  mov      eax, dword ptr [0x589a74]
00408661  cmp      dword ptr [ebx + 0x120], 0
00408668  je       0x408a16
0040866e  cmp      eax, 0x44
00408671  je       0x4088ae
00408677  cmp      eax, 0x49
0040867a  je       0x4088ae
00408680  cmp      eax, 0x4a
00408683  je       0x4088ae
00408689  cmp      eax, 0x4b
0040868c  je       0x4088ae
00408692  mov      edx, dword ptr [ebx + 0x58]
00408695  lea      esi, [ebx + 0x5c]
00408698  push     esi
00408699  lea      edi, [ebx + 0xa8]
0040869f  push     edi
004086a0  push     edx
004086a1  lea      ecx, [ebx + 0x140]
004086a7  call     0x40a930
004086ac  push     0xc8
004086b1  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
004086b7  mov      eax, dword ptr [edi]
004086b9  cmp      eax, dword ptr [esi]
004086bb  jne      0x4086e2
004086bd  mov      ecx, dword ptr [ebx + 0xac]
004086c3  cmp      ecx, dword ptr [ebx + 0x60]
004086c6  jne      0x4086e2
004086c8  mov      edx, dword ptr [ebx + 0xb0]
004086ce  cmp      edx, dword ptr [ebx + 0x64]
004086d1  jne      0x4086e2
004086d3  mov      eax, dword ptr [ebx + 0xb4]
004086d9  cmp      eax, dword ptr [ebx + 0x68]
004086dc  je       0x408a0e
004086e2  push     0x408090
004086e7  mov      ecx, ebx
004086e9  mov      dword ptr [ebx + 0x248], 3
004086f3  call     0x4081d0
004086f8  jmp      0x408865
004086fd  lea      eax, [ebx + 0x5c]
00408700  push     0x13
00408702  push     eax
00408703  lea      ecx, [ebx + 0x140]
00408709  call     0x40a8a0
0040870e  jmp      0x40865c
00408713  lea      eax, [ebx + 0x5c]
00408716  push     eax
00408717  lea      ecx, [ebx + 0x140]
0040871d  call     0x40a7d0
00408722  jmp      0x40865c
00408727  push     0x408090
0040872c  mov      ecx, ebx
0040872e  mov      dword ptr [ebx + 0x248], 8
00408738  call     0x4081d0
0040873d  jmp      0x408865
00408742  mov      eax, dword ptr [ebx + 0x40]
00408745  cmp      eax, edi
00408747  je       0x40875a
00408749  mov      edx, dword ptr [eax]
0040874b  push     edi
0040874c  push     3
0040874e  push     0x8001
00408753  push     edx
00408754  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
0040875a  mov      eax, dword ptr [ebx + 0xf8]
00408760  mov      edi, dword ptr [ebx + 0x110]
00408766  add      edi, dword ptr [ebx + 0xf4]
0040876c  push     0x38
0040876e  lea      ecx, [ebp - 0x4c]
00408771  push     0xff
00408776  push     ecx
00408777  mov      dword ptr [ebp - 0x54], eax
0040877a  call     0x50c310
0040877f  add      esp, 0xc
00408782  xor      esi, esi
00408784  cmp      esi, dword ptr [ebp - 0x54]
00408787  jae      0x4087df
00408789  lea      edx, [ebp - 0x50]
0040878c  push     edx
0040878d  mov      edx, dword ptr [ebp - 0x54]
00408790  lea      eax, [ebp - 0x4c]
00408793  push     eax
00408794  lea      ecx, [esi + edi]
00408797  push     ecx
00408798  push     edx
00408799  push     edi
0040879a  lea      ecx, [ebx + 0x140]
004087a0  call     0x40aac0
004087a5  test     eax, eax
004087a7  jne      0x4087b8
004087a9  mov      dword ptr [ebx + 0x248], 8
004087b3  jmp      0x408c32
004087b8  mov      ecx, dword ptr [ebx + 0x40]
004087bb  add      esi, dword ptr [ebp - 0x50]
004087be  test     ecx, ecx
004087c0  je       0x408784
004087c2  mov      eax, esi
004087c4  imul     eax, eax, 0x64
004087c7  xor      edx, edx
004087c9  div      dword ptr [ebp - 0x54]
004087cc  mov      edx, dword ptr [ecx]
004087ce  push     eax
004087cf  push     3
004087d1  push     0x8001
004087d6  push     edx
004087d7  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
004087dd  jmp      0x408784
004087df  mov      eax, dword ptr [ebx + 0x40]
004087e2  test     eax, eax
004087e4  je       0x4087f8
004087e6  mov      eax, dword ptr [eax]
004087e8  push     0
004087ea  push     4
004087ec  push     0x8001
004087f1  push     eax
004087f2  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
004087f8  mov      ecx, dword ptr [ebx + 0x108]
004087fe  mov      edi, dword ptr [ebx + 0x10c]
00408804  mov      dword ptr [ebp - 0x50], ecx
00408807  mov      dword ptr [ebp - 0x54], edi
0040880a  xor      esi, esi
0040880c  cmp      esi, edi
0040880e  jae      0x40865c
00408814  lea      edx, [ebp - 0x58]
00408817  push     edx
00408818  lea      eax, [ebp - 0x4c]
0040881b  push     eax
0040881c  mov      eax, dword ptr [ebp - 0x50]
0040881f  lea      ecx, [esi + eax]
00408822  push     ecx
00408823  push     edi
00408824  push     eax
00408825  lea      ecx, [ebx + 0x140]
0040882b  call     0x40aac0
00408830  test     eax, eax
00408832  jne      0x408881
00408834  mov      dword ptr [ebx + 0x248], 8
0040883e  mov      edx, dword ptr [ebx + 0x48]
00408841  push     -1
00408843  push     edx
00408844  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
0040884a  mov      eax, dword ptr [ebx + 0x3c]
0040884d  mov      dword ptr [ebx + 0x44], eax
00408850  test     eax, eax
00408852  je       0x40885b
00408854  mov      dword ptr [ebx + 0x3c], 0x408090
0040885b  mov      eax, dword ptr [ebx + 0x48]
0040885e  push     eax
0040885f  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
00408865  mov      ecx, dword ptr [ebp - 0xc]
00408868  mov      dword ptr fs:[0], ecx
0040886f  pop      ecx
00408870  pop      edi
00408871  pop      esi
00408872  pop      ebx
00408873  mov      ecx, dword ptr [ebp - 0x14]
00408876  xor      ecx, ebp
00408878  call     0x50bc27
0040887d  mov      esp, ebp
0040887f  pop      ebp
00408880  ret      
00408881  mov      ecx, dword ptr [ebx + 0x40]
00408884  add      esi, dword ptr [ebp - 0x58]
00408887  test     ecx, ecx
00408889  je       0x40880c
0040888b  mov      eax, esi
0040888d  imul     eax, eax, 0x64
00408890  xor      edx, edx
00408892  div      dword ptr [ebp - 0x54]
00408895  mov      ecx, dword ptr [ecx]
00408897  push     eax
00408898  push     4
0040889a  push     0x8001
0040889f  push     ecx
004088a0  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
004088a6  mov      edi, dword ptr [ebp - 0x54]
004088a9  jmp      0x40880c
004088ae  xor      esi, esi
004088b0  mov      edi, 0xe
004088b5  mov      dword ptr [ebp - 0x58], esi
004088b8  mov      dword ptr [ebp - 0x54], edi
004088bb  cmp      eax, 0x49
004088be  je       0x408962
004088c4  cmp      eax, 0x4a
004088c7  je       0x408962
004088cd  cmp      eax, 0x4b
004088d0  je       0x408962
004088d6  cmp      esi, edi
004088d8  jge      0x408918
004088da  mov      eax, dword ptr [ebx + esi*4 + 0xa8]
004088e1  cmp      eax, dword ptr [ebx + esi*4 + 0x5c]
004088e5  je       0x408915
004088e7  mov      ecx, dword ptr [ebx + 0x58]
004088ea  lea      edx, [ecx + esi*4]
004088ed  push     eax
004088ee  push     edx
004088ef  lea      ecx, [ebx + 0x140]
004088f5  call     0x40a490
004088fa  test     eax, eax
004088fc  je       0x408915
004088fe  .byte    0x8b
004088ff  .byte    0x84
