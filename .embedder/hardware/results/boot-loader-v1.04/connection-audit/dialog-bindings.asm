00404280  test     byte ptr [ebx], dl
00404283  mov      esi, eax
00404285  test     esi, esi
00404287  je       0x4042b2
00404289  push     edi
0040428a  push     ebx
0040428b  call     dword ptr [0x53825c] ; KERNEL32.dll!SizeofResource
00404291  mov      ecx, dword ptr [ebp + 0x10]
00404294  add      eax, esi
00404296  and      ecx, 0xf
00404299  jbe      0x4042ae
0040429b  jmp      0x4042a0
0040429d  lea      ecx, [ecx]
004042a0  cmp      esi, eax
004042a2  jae      0x4042b2
004042a4  dec      ecx
004042a5  movzx    edx, word ptr [esi]
004042a8  lea      esi, [esi + edx*2 + 2]
004042ac  jne      0x4042a0
004042ae  cmp      esi, eax
004042b0  jb       0x4042b9
004042b2  pop      esi
004042b3  pop      edi
004042b4  xor      eax, eax
004042b6  pop      ebx
004042b7  pop      ebp
004042b8  ret      
004042b9  movzx    eax, word ptr [esi]
004042bc  neg      eax
004042be  sbb      eax, eax
004042c0  and      eax, esi
004042c2  pop      esi
004042c3  pop      edi
004042c4  pop      ebx
004042c5  pop      ebp
004042c6  ret      
004042c7  int3     
004042c8  int3     
004042c9  int3     
004042ca  int3     
004042cb  int3     
004042cc  int3     
004042cd  int3     
004042ce  int3     
004042cf  int3     
004042d0  push     ebp
004042d1  mov      ebp, esp
004042d3  push     esi
004042d4  mov      esi, dword ptr [ebp + 0xc]
004042d7  mov      eax, esi
004042d9  shr      eax, 4
004042dc  push     edi
004042dd  mov      edi, dword ptr [ebp + 8]
004042e0  inc      eax
004042e1  movzx    ecx, ax
004042e4  push     6
004042e6  push     ecx
004042e7  push     edi
004042e8  call     dword ptr [0x538494] ; KERNEL32.dll!FindResourceW
004042ee  test     eax, eax
004042f0  jne      0x4042f6
004042f2  pop      edi
004042f3  pop      esi
004042f4  pop      ebp
004042f5  ret      
004042f6  push     esi
004042f7  push     eax
004042f8  push     edi
004042f9  call     0x404260
004042fe  add      esp, 0xc
00404301  pop      edi
00404302  pop      esi
00404303  pop      ebp
00404304  ret      
00404305  int3     
00404306  int3     
00404307  int3     
00404308  int3     
00404309  int3     
0040430a  int3     
0040430b  int3     
0040430c  int3     
0040430d  int3     
0040430e  int3     
0040430f  int3     
00404310  push     ebp
00404311  mov      ebp, esp
00404313  push     esi
00404314  push     edi
00404315  mov      edi, dword ptr [ebp + 8]
00404318  push     edi
00404319  mov      esi, ecx
0040431b  call     0x409620
00404320  lea      eax, [esi + 0x64c]
00404326  push     eax
00404327  push     0x420
0040432c  push     edi
0040432d  call     0x41954c
00404332  lea      ecx, [esi + 0x3fc]
00404338  push     ecx
00404339  push     0x3f0
0040433e  push     edi
0040433f  call     0x41954c
00404344  lea      edx, [esi + 0x644]
0040434a  push     edx
0040434b  push     0x3fd
00404350  push     edi
00404351  call     0x419660
00404356  lea      eax, [esi + 0x470]
0040435c  push     eax
0040435d  push     0x492
00404362  push     edi
00404363  call     0x41954c
00404368  lea      ecx, [esi + 0x6c0]
0040436e  push     ecx
0040436f  push     0x3ee
00404374  push     edi
00404375  call     0x41954c
0040437a  lea      edx, [esi + 0x648]
00404380  push     edx
00404381  push     0x413
00404386  push     edi
00404387  call     0x419660
0040438c  lea      eax, [esi + 0x2bc]
00404392  push     eax
00404393  push     0x492
00404398  push     edi
00404399  call     0x419297
0040439e  lea      ecx, [esi + 0x2c0]
004043a4  push     ecx
004043a5  push     0x3f9
004043aa  push     edi
004043ab  call     0x419297
004043b0  lea      edx, [esi + 0x2c4]
004043b6  push     edx
004043b7  push     0x3f8
004043bc  push     edi
004043bd  call     0x419297
004043c2  lea      eax, [esi + 0x2c8]
004043c8  push     eax
004043c9  push     0x3fb
004043ce  push     edi
004043cf  call     0x419297
004043d4  lea      ecx, [esi + 0x2cc]
004043da  push     ecx
004043db  push     0x42b
004043e0  push     edi
004043e1  call     0x419297
004043e6  lea      edx, [esi + 0x2d0]
004043ec  push     edx
004043ed  push     0x7d
004043ef  push     edi
004043f0  call     0x419297
004043f5  lea      eax, [esi + 0x2d4]
004043fb  push     eax
004043fc  push     0x81
00404401  push     edi
00404402  call     0x419297
00404407  lea      ecx, [esi + 0x2d8]
0040440d  push     ecx
0040440e  push     0x83
00404413  push     edi
00404414  call     0x419297
00404419  lea      edx, [esi + 0x12c]
0040441f  push     edx
00404420  push     0x7c
00404422  push     edi
00404423  call     0x41954c
00404428  lea      eax, [esi + 0xb8]
0040442e  push     eax
0040442f  push     0x7b
00404431  push     edi
00404432  call     0x41954c
00404437  lea      ecx, [esi + 0x4e4]
0040443d  push     ecx
0040443e  push     0x7e
00404440  push     edi
00404441  call     0x41954c
00404446  lea      edx, [esi + 0x558]
0040444c  push     edx
0040444d  push     0x7f
0040444f  push     edi
00404450  call     0x41954c
00404455  add      esi, 0x5cc
0040445b  push     esi
0040445c  push     0x80
00404461  push     edi
00404462  call     0x41954c
00404467  pop      edi
00404468  pop      esi
00404469  pop      ebp
0040446a  ret      4
0040446d  int3     
0040446e  int3     
0040446f  int3     
00404470  push     ebp
00404471  mov      ebp, esp
00404473  mov      eax, dword ptr [ebp + 0x10]
00404476  push     ebx
00404477  mov      ebx, dword ptr [ebp + 0xc]
0040447a  push     esi
0040447b  push     edi
0040447c  mov      edi, dword ptr [ebp + 8]
0040447f  push     eax
00404480  push     ebx
00404481  push     edi
00404482  mov      esi, ecx
00404484  call     0x41d9a6
00404489  mov      ecx, ebx
0040448b  mov      dword ptr [ebp + 0x10], eax
0040448e  call     0x41a1ce
00404493  cmp      eax, 0x665
00404498  jg       0x404503
0040449a  je       0x4044cc
0040449c  cmp      eax, 0x3fd
004044a1  jne      0x40459e
004044a7  cmp      dword ptr [esi + 0x3f8], 0
004044ae  mov      edx, dword ptr [edi]
004044b0  mov      eax, dword ptr [edx + 0x30]
004044b3  mov      ecx, edi
004044b5  je       0x404597
004044bb  push     0x8000
004044c0  call     eax
004044c2  mov      eax, dword ptr [ebp + 0x10]
004044c5  pop      edi
004044c6  pop      esi
004044c7  pop      ebx
004044c8  pop      ebp
004044c9  ret      0xc
004044cc  cmp      dword ptr [esi + 0x3f8], 0
004044d3  je       0x40459e
004044d9  mov      ecx, dword ptr [esi + 0x250]
004044df  mov      edx, dword ptr [edi]
004044e1  cmp      ecx, dword ptr [esi + 0x204]
004044e7  mov      eax, dword ptr [edx + 0x30]
004044ea  mov      ecx, edi
004044ec  jne      0x404597
004044f2  push     0x8000
004044f7  call     eax
004044f9  mov      eax, dword ptr [ebp + 0x10]
004044fc  pop      edi
004044fd  pop      esi
004044fe  pop      ebx
004044ff  pop      ebp
00404500  ret      0xc
00404503  sub      eax, 0x667
00404508  je       0x404575
0040450a  sub      eax, 2
0040450d  je       0x404546
0040450f  sub      eax, 2
00404512  jne      0x40459e
00404518  cmp      dword ptr [esi + 0x3f8], eax
0040451e  je       0x40459e
00404520  mov      ecx, dword ptr [esi + 0x25c]
00404526  mov      edx, dword ptr [edi]
00404528  cmp      ecx, dword ptr [esi + 0x210]
0040452e  mov      eax, dword ptr [edx + 0x30]
00404531  mov      ecx, edi
00404533  jne      0x404597
00404535  push     0x8000
0040453a  call     eax
0040453c  mov      eax, dword ptr [ebp + 0x10]
0040453f  pop      edi
00404540  pop      esi
00404541  pop      ebx
00404542  pop      ebp
00404543  ret      0xc
00404546  cmp      dword ptr [esi + 0x3f8], 0
0040454d  je       0x40459e
0040454f  mov      ecx, dword ptr [esi + 0x258]
00404555  mov      edx, dword ptr [edi]
00404557  cmp      ecx, dword ptr [esi + 0x20c]
0040455d  mov      eax, dword ptr [edx + 0x30]
00404560  mov      ecx, edi
00404562  jne      0x404597
00404564  push     0x8000
00404569  call     eax
0040456b  mov      eax, dword ptr [ebp + 0x10]
0040456e  pop      edi
0040456f  pop      esi
00404570  pop      ebx
00404571  pop      ebp
00404572  ret      0xc
00404575  cmp      dword ptr [esi + 0x3f8], 0
0040457c  je       0x40459e
0040457e  mov      ecx, dword ptr [esi + 0x254]
00404584  mov      edx, dword ptr [edi]
00404586  cmp      ecx, dword ptr [esi + 0x208]
0040458c  mov      eax, dword ptr [edx + 0x30]
0040458f  mov      ecx, edi
00404591  je       0x4044bb
00404597  push     0xff
0040459c  call     eax
0040459e  mov      eax, dword ptr [ebp + 0x10]
004045a1  pop      edi
004045a2  pop      esi
004045a3  pop      ebx
004045a4  pop      ebp
004045a5  ret      0xc
004045a8  int3     
004045a9  int3     
004045aa  int3     
004045ab  int3     
004045ac  int3     
004045ad  int3     
004045ae  int3     
004045af  int3     
