00408f40  push     ebp
00408f41  mov      ebp, esp
00408f43  push     -1
00408f45  push     0x529cd0
00408f4a  mov      eax, dword ptr fs:[0]
00408f50  push     eax
00408f51  sub      esp, 0xc
00408f54  push     ebx
00408f55  push     esi
00408f56  push     edi
00408f57  mov      eax, dword ptr [0x588250]
00408f5c  xor      eax, ebp
00408f5e  push     eax
00408f5f  lea      eax, [ebp - 0xc]
00408f62  mov      dword ptr fs:[0], eax
00408f68  mov      dword ptr [ebp - 0x10], esp
00408f6b  mov      ebx, ecx
00408f6d  mov      dword ptr [ebp - 0x18], ebx
00408f70  cmp      dword ptr [ebx + 0x3c], 0x408f40
00408f77  jne      0x409191
00408f7d  mov      eax, dword ptr [ebx + 0x40]
00408f80  test     eax, eax
00408f82  je       0x408f96
00408f84  mov      eax, dword ptr [eax]
00408f86  push     2
00408f88  push     7
00408f8a  push     0x8001
00408f8f  push     eax
00408f90  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
00408f96  mov      dword ptr [ebp - 4], 0
00408f9d  lea      ecx, [ecx]
00408fa0  cmp      dword ptr [ebx + 0x3c], 0x408f40
00408fa7  jne      0x409191
00408fad  lea      ecx, [ebx + 0x140]
00408fb3  call     0x409830
00408fb8  test     al, al
00408fba  je       0x409152
00408fc0  push     0
00408fc2  lea      ecx, [ebx + 0x140]
00408fc8  call     0x409f40
00408fcd  push     0
00408fcf  lea      ecx, [ebx + 0x140]
00408fd5  call     0x4098b0
00408fda  push     1
00408fdc  lea      ecx, [ebx + 0x140]
00408fe2  mov      dword ptr [ebx + 0x54], eax
00408fe5  call     0x4098b0
00408fea  push     2
00408fec  lea      ecx, [ebx + 0x140]
00408ff2  mov      dword ptr [ebx + 0x50], eax
00408ff5  call     0x4098b0
00408ffa  push     3
00408ffc  lea      ecx, [ebx + 0x140]
00409002  mov      dword ptr [ebx + 0x104], eax
00409008  call     0x4098b0
0040900d  push     5
0040900f  lea      ecx, [ebx + 0x140]
00409015  mov      dword ptr [ebx + 0x10c], eax
0040901b  call     0x4098b0
00409020  push     6
00409022  lea      ecx, [ebx + 0x140]
00409028  mov      dword ptr [ebx + 0x5c], eax
0040902b  call     0x4098b0
00409030  push     7
00409032  lea      ecx, [ebx + 0x140]
00409038  mov      dword ptr [ebx + 0x60], eax
0040903b  call     0x4098b0
00409040  push     8
00409042  lea      ecx, [ebx + 0x140]
00409048  mov      dword ptr [ebx + 0x64], eax
0040904b  call     0x4098b0
00409050  mov      dword ptr [ebx + 0x68], eax
00409053  call     0x40b1f0
00409058  cmp      eax, 0x3d
0040905b  je       0x4090dc
00409061  call     0x40b1f0
00409066  cmp      eax, 0x40
00409069  je       0x4090dc
0040906b  xor      esi, esi
0040906d  mov      dword ptr [ebp - 0x14], 3
00409074  call     0x40b1f0
00409079  cmp      eax, 0x49
0040907c  je       0x4090b7
0040907e  call     0x40b1f0
00409083  cmp      eax, 0x4a
00409086  je       0x4090b7
00409088  call     0x40b1f0
0040908d  cmp      eax, 0x4b
00409090  je       0x4090b7
00409092  test     esi, esi
00409094  jne      0x4090dc
00409096  cmp      dword ptr [ebp - 0x14], esi
00409099  jle      0x4090dc
0040909b  mov      eax, 0xe
004090a0  push     eax
004090a1  lea      eax, [ebx + 0x5c]
004090a4  push     eax
004090a5  lea      ecx, [ebx + 0x140]
004090ab  call     0x40a810
004090b0  dec      dword ptr [ebp - 0x14]
004090b3  mov      esi, eax
004090b5  jmp      0x409092
004090b7  test     esi, esi
004090b9  jne      0x4090dc
004090bb  cmp      dword ptr [ebp - 0x14], esi
004090be  jle      0x4090dc
004090c0  mov      eax, 0x13
004090c5  push     eax
004090c6  lea      eax, [ebx + 0x5c]
004090c9  push     eax
004090ca  lea      ecx, [ebx + 0x140]
004090d0  call     0x40a8a0
004090d5  dec      dword ptr [ebp - 0x14]
004090d8  mov      esi, eax
004090da  jmp      0x4090b7
004090dc  cmp      dword ptr [ebx + 0x40], 0
004090e0  lea      edi, [ebx + 0xa8]
004090e6  mov      ecx, 0x13
004090eb  lea      esi, [ebx + 0x5c]
004090ee  rep movsd dword ptr es:[edi], dword ptr [esi]
004090f0  mov      dword ptr [ebx + 0x248], 0
004090fa  push     -1
004090fc  je       0x409128
004090fe  mov      ecx, dword ptr [ebx + 0x48]
00409101  push     ecx
00409102  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00409108  mov      eax, dword ptr [ebx + 0x3c]
0040910b  mov      dword ptr [ebx + 0x44], eax
0040910e  test     eax, eax
00409110  je       0x409119
00409112  mov      dword ptr [ebx + 0x3c], 0x408090
00409119  mov      edx, dword ptr [ebx + 0x48]
0040911c  push     edx
0040911d  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
00409123  jmp      0x408fa0
00409128  mov      eax, dword ptr [ebx + 0x48]
0040912b  push     eax
0040912c  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00409132  mov      eax, dword ptr [ebx + 0x3c]
00409135  mov      dword ptr [ebx + 0x44], eax
00409138  test     eax, eax
0040913a  je       0x409143
0040913c  mov      dword ptr [ebx + 0x3c], 0x408540
00409143  mov      ecx, dword ptr [ebx + 0x48]
00409146  push     ecx
00409147  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
0040914d  jmp      0x408fa0
00409152  mov      edx, dword ptr [ebx + 0x48]
00409155  push     -1
00409157  push     edx
00409158  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
0040915e  mov      eax, dword ptr [ebx + 0x3c]
00409161  mov      dword ptr [ebx + 0x44], eax
00409164  test     eax, eax
00409166  je       0x40916f
00409168  mov      dword ptr [ebx + 0x3c], 0x408210
0040916f  mov      eax, dword ptr [ebx + 0x48]
00409172  push     eax
00409173  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
00409179  jmp      0x408fa0
0040917e  mov      ecx, dword ptr [ebp - 0x18]
00409181  push     0x408030
00409186  call     0x4081d0
0040918b  mov      eax, 0x409191
00409190  ret      
00409191  mov      ecx, dword ptr [ebp - 0xc]
00409194  mov      dword ptr fs:[0], ecx
0040919b  pop      ecx
0040919c  pop      edi
0040919d  pop      esi
0040919e  pop      ebx
0040919f  mov      esp, ebp
004091a1  pop      ebp
004091a2  ret      
004091a3  int3     
004091a4  int3     
004091a5  int3     
004091a6  int3     
004091a7  int3     
004091a8  int3     
004091a9  int3     
004091aa  int3     
004091ab  int3     
004091ac  int3     
004091ad  int3     
004091ae  int3     
004091af  int3     
004091b0  push     esi
004091b1  push     0x5399ac
004091b6  mov      esi, ecx
004091b8  call     0x406cc0
004091bd  xor      eax, eax
004091bf  mov      dword ptr [esi + 4], eax
004091c2  xor      ecx, ecx
004091c4  mov      word ptr [esi + 8], cx
004091c8  mov      dword ptr [esi + 0xc], eax
004091cb  mov      dword ptr [esi + 0x10], eax
004091ce  mov      dword ptr [esi + 0x14], eax
004091d1  mov      eax, esi
004091d3  pop      esi
004091d4  ret      
004091d5  int3     
004091d6  int3     
004091d7  int3     
004091d8  int3     
004091d9  int3     
004091da  int3     
004091db  int3     
004091dc  int3     
004091dd  int3     
004091de  int3     
004091df  int3     
004091e0  push     ebp
004091e1  mov      ebp, esp
004091e3  push     -1
004091e5  push     0x529d14
004091ea  mov      eax, dword ptr fs:[0]
004091f0  push     eax
004091f1  sub      esp, 0x14
004091f4  push     ebx
004091f5  push     esi
004091f6  push     edi
004091f7  mov      eax, dword ptr [0x588250]
004091fc  xor      eax, ebp
004091fe  push     eax
004091ff  lea      eax, [ebp - 0xc]
00409202  mov      dword ptr fs:[0], eax
00409208  mov      esi, ecx
0040920a  mov      dword ptr [ebp - 0x10], esi
0040920d  push     0x408440
00409212  push     0x4091b0
00409217  push     2
00409219  push     0x1c
0040921b  lea      eax, [esi + 4]
0040921e  push     eax
0040921f  mov      dword ptr [esi], 0x53a4dc
00409225  call     0x50bcf7
0040922a  xor      ebx, ebx
0040922c  mov      edi, 1
00409231  lea      ecx, [esi + 0x140]
00409237  mov      dword ptr [ebp - 4], ebx
0040923a  mov      dword ptr [esi + 0x114], edi
00409240  mov      dword ptr [esi + 0x118], ebx
00409246  mov      dword ptr [esi + 0x11c], ebx
0040924c  mov      dword ptr [esi + 0x120], ebx
00409252  mov      dword ptr [esi + 0x124], ebx
00409258  mov      dword ptr [esi + 0x128], ebx
0040925e  mov      dword ptr [esi + 0x12c], ebx
00409264  mov      dword ptr [esi + 0x130], ebx
0040926a  mov      dword ptr [esi + 0x134], ebx
00409270  mov      dword ptr [esi + 0x138], edi
00409276  mov      dword ptr [esi + 0x13c], ebx
0040927c  call     0x4099d0
00409281  mov      ecx, dword ptr [ebp + 8]
00409284  push     ebx
00409285  push     ebx
00409286  push     ebx
00409287  mov      byte ptr [ebp - 4], 1
0040928b  mov      dword ptr [esi + 0x40], ecx
0040928e  call     dword ptr [0x538460] ; KERNEL32.dll!CreateMutexW
00409294  push     ebx
00409295  push     edi
00409296  mov      dword ptr [esi + 0x48], eax
00409299  mov      eax, 0x408000
0040929e  push     ebx
0040929f  push     ebx
004092a0  mov      dword ptr [esi + 0x3c], eax
004092a3  mov      dword ptr [esi + 0x44], eax
004092a6  mov      dword ptr [ebp - 0x20], 0x407fc0
004092ad  mov      dword ptr [ebp - 0x1c], esi
004092b0  mov      dword ptr [ebp - 0x18], ebx
004092b3  mov      dword ptr [ebp - 0x14], ebx
004092b6  call     dword ptr [0x538464] ; KERNEL32.dll!CreateSemaphoreW
004092bc  push     ebx
004092bd  push     4
004092bf  push     ebx
004092c0  push     ebx
004092c1  lea      edx, [ebp - 0x20]
004092c4  push     edx
004092c5  push     0x408180
004092ca  mov      dword ptr [ebp - 0x14], eax
004092cd  call     0x426d62
004092d2  mov      dword ptr [ebp + 8], eax
004092d5  mov      dword ptr [eax + 0x28], ebx
004092d8  mov      eax, dword ptr [eax + 0x2c]
004092db  push     eax
004092dc  call     dword ptr [0x538470] ; KERNEL32.dll!ResumeThread
004092e2  mov      ecx, dword ptr [ebp - 0x14]
004092e5  or       edi, 0xffffffff
004092e8  push     edi
004092e9  push     ecx
004092ea  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
004092f0  mov      edx, dword ptr [ebp - 0x14]
004092f3  push     edx
004092f4  call     dword ptr [0x538468] ; KERNEL32.dll!CloseHandle
004092fa  mov      eax, dword ptr [ebp + 8]
004092fd  mov      dword ptr [esi + 0x4c], eax
00409300  mov      dword ptr [esi + 0x5c], edi
00409303  mov      dword ptr [esi + 0x60], edi
00409306  mov      dword ptr [esi + 0x64], edi
00409309  mov      dword ptr [esi + 0x68], edi
0040930c  mov      dword ptr [esi + 0x6c], edi
0040930f  mov      dword ptr [esi + 0x70], edi
00409312  mov      dword ptr [esi + 0x74], edi
00409315  mov      dword ptr [esi + 0x78], edi
00409318  mov      dword ptr [esi + 0x7c], edi
0040931b  mov      dword ptr [esi + 0x80], edi
00409321  mov      dword ptr [esi + 0x84], edi
00409327  mov      dword ptr [esi + 0x88], edi
0040932d  mov      dword ptr [esi + 0x8c], edi
00409333  mov      dword ptr [esi + 0x90], edi
00409339  mov      dword ptr [esi + 0x94], edi
0040933f  mov      dword ptr [esi + 0x98], edi
00409345  mov      dword ptr [esi + 0x9c], edi
0040934b  mov      dword ptr [esi + 0xa0], edi
00409351  mov      dword ptr [esi + 0xa4], edi
00409357  mov      dword ptr [esi + 0xa8], edi
0040935d  mov      dword ptr [esi + 0xac], edi
00409363  mov      dword ptr [esi + 0xb0], edi
00409369  mov      dword ptr [esi + 0xb4], edi
0040936f  mov      dword ptr [esi + 0xb8], edi
00409375  mov      dword ptr [esi + 0xbc], edi
0040937b  mov      dword ptr [esi + 0xc0], edi
00409381  mov      dword ptr [esi + 0xc4], edi
00409387  mov      dword ptr [esi + 0xc8], edi
0040938d  mov      dword ptr [esi + 0xcc], edi
00409393  mov      dword ptr [esi + 0xd0], edi
00409399  mov      dword ptr [esi + 0xd4], edi
0040939f  mov      dword ptr [esi + 0xd8], edi
004093a5  mov      dword ptr [esi + 0xdc], edi
004093ab  mov      dword ptr [esi + 0xe0], edi
004093b1  mov      dword ptr [esi + 0xe4], edi
004093b7  mov      dword ptr [esi + 0xe8], edi
004093bd  mov      dword ptr [esi + 0xec], edi
004093c3  mov      dword ptr [esi + 0xf0], edi
004093c9  mov      dword ptr [esi + 0xf4], ebx
004093cf  mov      dword ptr [esi + 0xf8], ebx
004093d5  mov      dword ptr [esi + 0xfc], ebx
004093db  mov      dword ptr [esi + 0x100], ebx
004093e1  mov      dword ptr [esi + 0x104], ebx
004093e7  mov      dword ptr [esi + 0x108], ebx
004093ed  mov      dword ptr [esi + 0x10c], ebx
004093f3  mov      dword ptr [esi + 0x110], ebx
004093f9  mov      dword ptr [eax + 0x28], 1
00409400  mov      dword ptr [esi + 0x248], ebx
00409406  mov      eax, esi
00409408  mov      ecx, dword ptr [ebp - 0xc]
0040940b  mov      dword ptr fs:[0], ecx
00409412  pop      ecx
00409413  pop      edi
00409414  pop      esi
00409415  pop      ebx
00409416  mov      esp, ebp
00409418  pop      ebp
00409419  ret      4
0040941c  int3     
0040941d  int3     
0040941e  int3     
0040941f  int3     
00409420  push     ebp
00409421  mov      ebp, esp
00409423  push     -1
00409425  push     0x529d3b
0040942a  mov      eax, dword ptr fs:[0]
00409430  push     eax
00409431  sub      esp, 0x760
00409437  mov      eax, dword ptr [0x588250]
0040943c  xor      eax, ebp
0040943e  mov      dword ptr [ebp - 0x10], eax
00409441  push     esi
00409442  push     eax
00409443  lea      eax, [ebp - 0xc]
00409446  mov      dword ptr fs:[0], eax
0040944c  mov      esi, ecx
0040944e  call     0x427aec
00409453  call     0x428c92
00409458  push     0x53a76c
0040945d  mov      ecx, esi
0040945f  call     0x427df2
00409464  push     0
00409466  push     0x1423
0040946b  lea      ecx, [ebp - 0x76c]
00409471  call     0x4063f0
00409476  lea      ecx, [ebp - 0x76c]
0040947c  mov      dword ptr [ebp - 4], 0
00409483  call     0x418afe
00409488  lea      ecx, [ebp - 0x76c]
0040948e  mov      dword ptr [ebp - 4], 0xffffffff
00409495  call     0x404fe0
0040949a  xor      eax, eax
0040949c  mov      ecx, dword ptr [ebp - 0xc]
0040949f  mov      dword ptr fs:[0], ecx
004094a6  pop      ecx
004094a7  pop      esi
004094a8  mov      ecx, dword ptr [ebp - 0x10]
004094ab  xor      ecx, ebp
004094ad  call     0x50bc27
004094b2  mov      esp, ebp
004094b4  pop      ebp
004094b5  ret      
004094b6  int3     
004094b7  int3     
004094b8  int3     
004094b9  int3     
004094ba  int3     
004094bb  int3     
004094bc  int3     
004094bd  int3     
004094be  int3     
004094bf  int3     
004094c0  mov      eax, dword ptr [ecx + 0xac]
004094c6  and      eax, 1
004094c9  ret      
004094ca  int3     
004094cb  int3     
004094cc  int3     
004094cd  int3     
004094ce  int3     
004094cf  int3     
004094d0  mov      eax, dword ptr [ecx + 0xac]
004094d6  and      eax, 2
004094d9  ret      
004094da  int3     
004094db  int3     
004094dc  int3     
004094dd  int3     
004094de  int3     
004094df  int3     
004094e0  mov      eax, dword ptr [ecx + 0xac]
004094e6  and      eax, 4
004094e9  ret      
004094ea  int3     
004094eb  int3     
004094ec  int3     
004094ed  int3     
004094ee  int3     
004094ef  int3     
004094f0  mov      eax, dword ptr [ecx + 0xac]
004094f6  and      eax, 8
004094f9  ret      
004094fa  int3     
004094fb  int3     
004094fc  int3     
004094fd  int3     
004094fe  int3     
004094ff  int3     
00409500  mov      eax, dword ptr [ecx + 0xac]
00409506  and      eax, 0x10
00409509  ret      
0040950a  int3     
0040950b  int3     
0040950c  int3     
0040950d  int3     
0040950e  int3     
0040950f  int3     
00409510  mov      eax, dword ptr [ecx + 0xac]
00409516  and      eax, 0x20
00409519  ret      
0040951a  int3     
0040951b  int3     
0040951c  int3     
0040951d  int3     
0040951e  int3     
0040951f  int3     
00409520  mov      eax, 0x1388
00409525  ret      
00409526  int3     
00409527  int3     
00409528  int3     
00409529  int3     
0040952a  int3     
0040952b  int3     
0040952c  int3     
0040952d  int3     
0040952e  int3     
0040952f  int3     
