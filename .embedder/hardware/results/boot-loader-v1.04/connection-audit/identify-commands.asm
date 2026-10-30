0040a6f0  push     esi
0040a6f1  push     edi
0040a6f2  mov      esi, ecx
0040a6f4  push     0x34
0040a6f6  lea      edi, [esi + 0xd4]
0040a6fc  push     0
0040a6fe  push     edi
0040a6ff  call     0x50c310
0040a704  add      esp, 0xc
0040a707  push     0x14
0040a709  push     0
0040a70b  push     0
0040a70d  push     0xa0
0040a712  mov      ecx, esi
0040a714  call     0x40a040
0040a719  test     eax, eax
0040a71b  je       0x40a750
0040a71d  push     0
0040a71f  push     0x1388
0040a724  push     0x34
0040a726  push     edi
0040a727  mov      ecx, esi
0040a729  call     0x4098d0
0040a72e  test     eax, eax
0040a730  je       0x40a750
0040a732  cmp      dword ptr [esi + 0x104], 0x13572468
0040a73c  jne      0x40a750
0040a73e  pop      edi
0040a73f  mov      dword ptr [esi + 0x88], 3
0040a749  mov      eax, 1
0040a74e  pop      esi
0040a74f  ret      
0040a750  pop      edi
0040a751  xor      eax, eax
0040a753  pop      esi
0040a754  ret      
0040a755  int3     
0040a756  int3     
0040a757  int3     
0040a758  int3     
0040a759  int3     
0040a75a  int3     
0040a75b  int3     
0040a75c  int3     
0040a75d  int3     
0040a75e  int3     
0040a75f  int3     
0040a760  push     ebp
0040a761  mov      ebp, esp
0040a763  sub      esp, 0x14
0040a766  mov      eax, dword ptr [ebp + 8]
0040a769  mov      edx, dword ptr [ebp + 0x14]
0040a76c  push     esi
0040a76d  push     edi
0040a76e  mov      edi, dword ptr [ebp + 0x10]
0040a771  mov      esi, ecx
0040a773  mov      ecx, dword ptr [ebp + 0xc]
0040a776  push     0x14
0040a778  mov      dword ptr [ebp - 0x10], ecx
0040a77b  push     0x14
0040a77d  lea      ecx, [ebp - 0x14]
0040a780  push     ecx
0040a781  mov      dword ptr [ebp - 0x14], eax
0040a784  mov      eax, dword ptr [ebp + 0x18]
0040a787  push     0x5a
0040a789  mov      ecx, esi
0040a78b  mov      dword ptr [ebp - 0xc], edi
0040a78e  mov      dword ptr [ebp - 8], edx
0040a791  mov      dword ptr [ebp - 4], eax
0040a794  call     0x40a040
0040a799  test     eax, eax
0040a79b  je       0x40a7c5
0040a79d  push     0
0040a79f  push     0x1388
0040a7a4  push     4
0040a7a6  lea      edx, [ebp + 8]
0040a7a9  push     edx
0040a7aa  mov      ecx, esi
0040a7ac  call     0x4098d0
0040a7b1  test     eax, eax
0040a7b3  je       0x40a7c5
0040a7b5  xor      eax, eax
0040a7b7  cmp      dword ptr [ebp + 8], edi
0040a7ba  pop      edi
0040a7bb  sete     al
0040a7be  pop      esi
0040a7bf  mov      esp, ebp
0040a7c1  pop      ebp
0040a7c2  ret      0x14
0040a7c5  pop      edi
0040a7c6  xor      eax, eax
0040a7c8  pop      esi
0040a7c9  mov      esp, ebp
0040a7cb  pop      ebp
0040a7cc  ret      0x14
0040a7cf  int3     
0040a7d0  push     ebp
0040a7d1  mov      ebp, esp
0040a7d3  push     esi
0040a7d4  mov      esi, ecx
0040a7d6  call     0x40a6f0
0040a7db  test     eax, eax
0040a7dd  je       0x40a805
0040a7df  mov      ecx, dword ptr [esi + 0xe8]
0040a7e5  mov      eax, dword ptr [ebp + 8]
0040a7e8  mov      dword ptr [eax], ecx
0040a7ea  mov      edx, dword ptr [esi + 0xec]
0040a7f0  mov      dword ptr [eax + 4], edx
0040a7f3  mov      ecx, dword ptr [esi + 0xf0]
0040a7f9  mov      dword ptr [eax + 8], ecx
0040a7fc  mov      edx, dword ptr [esi + 0xf4]
0040a802  mov      dword ptr [eax + 0xc], edx
0040a805  pop      esi
0040a806  pop      ebp
0040a807  ret      4
0040a80a  int3     
0040a80b  int3     
0040a80c  int3     
0040a80d  int3     
0040a80e  int3     
0040a80f  int3     
0040a810  push     ebp
0040a811  mov      ebp, esp
0040a813  sub      esp, 0xc
0040a816  push     ebx
0040a817  push     esi
0040a818  mov      esi, 1
0040a81d  push     edi
0040a81e  mov      ebx, ecx
0040a820  mov      dword ptr [ebp - 4], esi
0040a823  call     0x40a6f0
0040a828  xor      edi, edi
0040a82a  cmp      dword ptr [ebp + 0xc], edi
0040a82d  jle      0x40a894
0040a82f  nop      
0040a830  xor      eax, eax
0040a832  cmp      edi, 0x10
0040a835  jl       0x40a83c
0040a837  mov      eax, 0x10
0040a83c  lea      esi, [eax + edi]
0040a83f  push     0x14
0040a841  push     8
0040a843  add      esi, esi
0040a845  lea      ecx, [ebp - 0xc]
0040a848  push     ecx
0040a849  add      esi, esi
0040a84b  lea      eax, [esi + 0xf300000]
0040a851  push     0xd2
0040a856  mov      ecx, ebx
0040a858  mov      dword ptr [ebp - 0xc], eax
0040a85b  mov      dword ptr [ebp - 8], 4
0040a862  call     0x40a040
0040a867  test     eax, eax
0040a869  je       0x40a882
0040a86b  add      esi, dword ptr [ebp + 8]
0040a86e  push     0
0040a870  push     0x7530
0040a875  push     4
0040a877  push     esi
0040a878  mov      ecx, ebx
0040a87a  call     0x4098d0
0040a87f  and      dword ptr [ebp - 4], eax
0040a882  inc      edi
0040a883  cmp      edi, dword ptr [ebp + 0xc]
0040a886  jl       0x40a830
0040a888  mov      eax, dword ptr [ebp - 4]
0040a88b  pop      edi
0040a88c  pop      esi
0040a88d  pop      ebx
0040a88e  mov      esp, ebp
0040a890  pop      ebp
0040a891  ret      8
0040a894  pop      edi
0040a895  mov      eax, esi
0040a897  pop      esi
0040a898  pop      ebx
0040a899  mov      esp, ebp
0040a89b  pop      ebp
0040a89c  ret      8
0040a89f  int3     
0040a8a0  push     ebp
0040a8a1  mov      ebp, esp
0040a8a3  sub      esp, 0xc
0040a8a6  push     ebx
0040a8a7  push     edi
0040a8a8  xor      edi, edi
0040a8aa  mov      eax, 1
0040a8af  mov      ebx, ecx
0040a8b1  mov      dword ptr [ebp - 4], eax
0040a8b4  cmp      dword ptr [ebp + 0xc], edi
0040a8b7  jle      0x40a91e
0040a8b9  push     esi
0040a8ba  lea      ebx, [ebx]
0040a8c0  xor      eax, eax
0040a8c2  cmp      edi, 0x10
0040a8c5  jl       0x40a8cc
0040a8c7  mov      eax, 0x10
0040a8cc  lea      esi, [eax + edi]
0040a8cf  push     0x14
0040a8d1  push     8
0040a8d3  add      esi, esi
0040a8d5  lea      ecx, [ebp - 0xc]
0040a8d8  push     ecx
0040a8d9  add      esi, esi
0040a8db  lea      eax, [esi + 0xf300000]
0040a8e1  push     0xd2
0040a8e6  mov      ecx, ebx
0040a8e8  mov      dword ptr [ebp - 0xc], eax
0040a8eb  mov      dword ptr [ebp - 8], 8
0040a8f2  call     0x40a040
0040a8f7  test     eax, eax
0040a8f9  je       0x40a912
0040a8fb  add      esi, dword ptr [ebp + 8]
0040a8fe  push     0
0040a900  push     0x7530
0040a905  push     8
0040a907  push     esi
0040a908  mov      ecx, ebx
0040a90a  call     0x4098d0
0040a90f  and      dword ptr [ebp - 4], eax
0040a912  add      edi, 2
0040a915  cmp      edi, dword ptr [ebp + 0xc]
0040a918  jl       0x40a8c0
0040a91a  mov      eax, dword ptr [ebp - 4]
0040a91d  pop      esi
0040a91e  pop      edi
0040a91f  pop      ebx
0040a920  mov      esp, ebp
0040a922  pop      ebp
0040a923  ret      8
0040a926  int3     
0040a927  int3     
0040a928  int3     
0040a929  int3     
0040a92a  int3     
0040a92b  int3     
0040a92c  int3     
0040a92d  int3     
0040a92e  int3     
0040a92f  int3     
