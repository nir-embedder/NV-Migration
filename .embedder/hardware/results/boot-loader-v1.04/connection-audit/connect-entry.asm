00405d60  test     edx, edx
00405d62  jg       0x405d6e
00405d64  mov      ecx, dword ptr [eax]
00405d66  mov      edx, dword ptr [ecx]
00405d68  push     eax
00405d69  mov      eax, dword ptr [edx + 4]
00405d6c  call     eax
00405d6e  mov      ecx, dword ptr [ebp - 0xc]
00405d71  mov      dword ptr fs:[0], ecx
00405d78  pop      ecx
00405d79  pop      edi
00405d7a  pop      esi
00405d7b  mov      esp, ebp
00405d7d  pop      ebp
00405d7e  ret      0xc
00405d81  int3     
00405d82  int3     
00405d83  int3     
00405d84  int3     
00405d85  int3     
00405d86  int3     
00405d87  int3     
00405d88  int3     
00405d89  int3     
00405d8a  int3     
00405d8b  int3     
00405d8c  int3     
00405d8d  int3     
00405d8e  int3     
00405d8f  int3     
00405d90  push     ebp
00405d91  mov      ebp, esp
00405d93  sub      esp, 0x18
00405d96  mov      eax, dword ptr [0x588250]
00405d9b  xor      eax, ebp
00405d9d  mov      dword ptr [ebp - 4], eax
00405da0  push     ebx
00405da1  push     esi
00405da2  mov      esi, ecx
00405da4  mov      eax, dword ptr [esi + 0x1e4]
00405daa  push     edi
00405dab  cmp      eax, 0x408030
00405db0  je       0x405dcb
00405db2  cmp      eax, 0x408000
00405db7  je       0x405dcb
00405db9  test     eax, eax
00405dbb  je       0x405e9b
00405dc1  push     0x408030
00405dc6  jmp      0x405e90
00405dcb  lea      ebx, [esi + 0x1a4]
00405dd1  push     ebx
00405dd2  lea      ecx, [esi + 0x12c]
00405dd8  call     0x41e7c7
00405ddd  mov      eax, dword ptr [esi + 0xd8]
00405de3  push     0
00405de5  push     0
00405de7  push     0x147
00405dec  push     eax
00405ded  mov      edi, 0x1c200
00405df2  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
00405df8  mov      ecx, dword ptr [esi + 0x504]
00405dfe  push     0
00405e00  push     0
00405e02  push     0x147
00405e07  push     ecx
00405e08  mov      dword ptr [ebp - 0x18], eax
00405e0b  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
00405e11  mov      ecx, dword ptr [ebp - 0x18]
00405e14  cmp      ecx, 1
00405e17  jne      0x405e37
00405e19  mov      dword ptr [ebp - 0x14], edi
00405e1c  mov      dword ptr [ebp - 0x10], 0x38400
00405e23  mov      dword ptr [ebp - 0xc], 0x70800
00405e2a  mov      dword ptr [ebp - 8], 0xe1000
00405e31  mov      edi, dword ptr [ebp + eax*4 - 0x14]
00405e35  jmp      0x405e45
00405e37  cmp      ecx, 4
00405e3a  jne      0x405e45
00405e3c  lea      edi, [eax + 1]
00405e3f  imul     edi, edi, 0x3d090
00405e45  mov      eax, dword ptr [ebx]
00405e47  push     edi
00405e48  push     ecx
00405e49  sub      eax, 0x10
00405e4c  mov      dword ptr [ebp - 0x18], esp
00405e4f  mov      edi, esp
00405e51  push     eax
00405e52  call     0x4024d0
00405e57  add      esp, 4
00405e5a  push     0
00405e5c  add      eax, 0x10
00405e5f  push     0
00405e61  mov      dword ptr [edi], eax
00405e63  mov      edx, dword ptr [esi + 0xd8]
00405e69  push     0x147
00405e6e  push     edx
00405e6f  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
00405e75  inc      eax
00405e76  push     eax
00405e77  lea      ecx, [esi + 0x1a8]
00405e7d  call     0x405cc0
00405e82  push     0
00405e84  mov      ecx, esi
00405e86  call     0x414ce0
00405e8b  push     0x408210
00405e90  lea      ecx, [esi + 0x1a8]
00405e96  call     0x4081d0
00405e9b  mov      ecx, dword ptr [ebp - 4]
00405e9e  pop      edi
00405e9f  pop      esi
00405ea0  xor      ecx, ebp
00405ea2  pop      ebx
00405ea3  call     0x50bc27
00405ea8  mov      esp, ebp
00405eaa  pop      ebp
00405eab  ret      
00405eac  int3     
00405ead  int3     
00405eae  int3     
00405eaf  int3     
00405eb0  int3     
00405eb1  int3     
00405eb2  int3     
00405eb3  int3     
00405eb4  int3     
00405eb5  int3     
00405eb6  int3     
00405eb7  int3     
00405eb8  int3     
00405eb9  int3     
00405eba  int3     
00405ebb  int3     
00405ebc  int3     
00405ebd  int3     
00405ebe  int3     
00405ebf  int3     
00405ec0  push     ebp
00405ec1  mov      ebp, esp
00405ec3  push     -1
00405ec5  push     0x5298a1
00405eca  mov      eax, dword ptr fs:[0]
00405ed0  push     eax
00405ed1  sub      esp, 0x100
00405ed7  mov      eax, dword ptr [0x588250]
00405edc  xor      eax, ebp
00405ede  mov      dword ptr [ebp - 0x10], eax
00405ee1  push     ebx
00405ee2  push     esi
00405ee3  push     edi
00405ee4  push     eax
00405ee5  lea      eax, [ebp - 0xc]
00405ee8  mov      dword ptr fs:[0], eax
00405eee  mov      esi, ecx
00405ef0  mov      eax, dword ptr [esi + 0x20]
00405ef3  push     eax
00405ef4  call     dword ptr [0x5388a4] ; USER32.dll!IsIconic
00405efa  push     esi
00405efb  test     eax, eax
00405efd  je       0x405f95
00405f03  lea      ecx, [ebp - 0xd8]
00405f09  call     0x4222f0
00405f0e  mov      ecx, dword ptr [ebp - 0xd4]
00405f14  mov      edx, dword ptr [esi + 0x20]
00405f17  xor      ebx, ebx
00405f19  push     ebx
00405f1a  push     ecx
00405f1b  push     0x27
00405f1d  push     edx
00405f1e  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
00405f24  mov      edi, dword ptr [0x53888c] ; USER32.dll!GetSystemMetrics
00405f2a  push     0xb
00405f2c  call     edi
00405f2e  push     0xc
00405f30  mov      dword ptr [ebp - 0xe4], eax
00405f36  call     edi
00405f38  mov      ecx, dword ptr [esi + 0x20]
00405f3b  mov      edi, eax
00405f3d  lea      eax, [ebp - 0x20]
00405f40  push     eax
00405f41  push     ecx
00405f42  mov      dword ptr [ebp - 0x20], ebx
00405f45  mov      dword ptr [ebp - 0x1c], ebx
00405f48  mov      dword ptr [ebp - 0x18], ebx
00405f4b  mov      dword ptr [ebp - 0x14], ebx
00405f4e  call     dword ptr [0x53889c] ; USER32.dll!GetClientRect
00405f54  mov      eax, dword ptr [ebp - 0x14]
00405f57  sub      eax, dword ptr [ebp - 0x1c]
00405f5a  mov      edx, dword ptr [esi + 0x754]
00405f60  sub      eax, edi
00405f62  inc      eax
00405f63  push     edx
00405f64  cdq      
00405f65  sub      eax, edx
00405f67  sar      eax, 1
00405f69  push     eax
00405f6a  mov      eax, dword ptr [ebp - 0x18]
00405f6d  sub      eax, dword ptr [ebp - 0x20]
00405f70  sub      eax, dword ptr [ebp - 0xe4]
00405f76  inc      eax
00405f77  cdq      
00405f78  sub      eax, edx
00405f7a  sar      eax, 1
00405f7c  push     eax
00405f7d  mov      eax, dword ptr [ebp - 0xd4]
00405f83  push     eax
00405f84  call     dword ptr [0x5388b4] ; USER32.dll!DrawIcon
00405f8a  lea      ecx, [ebp - 0xd8]
00405f90  jmp      0x4060b6
00405f95  lea      ecx, [ebp - 0x84]
00405f9b  call     0x4222f0
00405fa0  xor      ebx, ebx
00405fa2  lea      ecx, [ebp - 0xf4]
00405fa8  mov      dword ptr [ebp - 4], ebx
00405fab  call     0x421b03
00405fb0  mov      ecx, dword ptr [ebp - 0x80]
00405fb3  push     ecx
00405fb4  mov      byte ptr [ebp - 4], 1
00405fb8  call     dword ptr [0x5381c0] ; GDI32.dll!CreateCompatibleDC
00405fbe  push     eax
00405fbf  lea      ecx, [ebp - 0xf4]
00405fc5  call     0x422138
00405fca  mov      dword ptr [ebp - 0xdc], ebx
00405fd0  mov      dword ptr [ebp - 0xe0], 0x539ca0
00405fda  mov      byte ptr [ebp - 4], 2
00405fde  call     0x4216a7
00405fe3  mov      eax, dword ptr [eax + 0xc]
00405fe6  push     0x68
00405fe8  push     eax
00405fe9  call     dword ptr [0x5388b8] ; USER32.dll!LoadBitmapW
00405fef  push     eax
00405ff0  lea      ecx, [ebp - 0xe0]
00405ff6  call     0x42240c
00405ffb  mov      eax, dword ptr [ebp - 0xdc]
00406001  lea      edx, [ebp - 0x10c]
00406007  push     edx
00406008  push     0x18
0040600a  push     eax
0040600b  call     dword ptr [0x538144] ; GDI32.dll!GetObjectW
00406011  mov      ecx, dword ptr [ebp - 0xdc]
00406017  mov      edx, dword ptr [ebp - 0xf0]
0040601d  push     ecx
0040601e  push     edx
0040601f  call     0x42249d
00406024  mov      ecx, dword ptr [esi + 0x20]
00406027  mov      edi, eax
00406029  lea      eax, [ebp - 0x30]
0040602c  push     eax
0040602d  push     ecx
0040602e  mov      dword ptr [ebp - 0x30], ebx
00406031  mov      dword ptr [ebp - 0x2c], ebx
00406034  mov      dword ptr [ebp - 0x28], ebx
00406037  mov      dword ptr [ebp - 0x24], ebx
0040603a  call     dword ptr [0x53889c] ; USER32.dll!GetClientRect
00406040  mov      eax, dword ptr [ebp - 0x104]
00406046  mov      ecx, dword ptr [ebp - 0x108]
0040604c  mov      edx, dword ptr [ebp - 0xf0]
00406052  push     0xcc0020
00406057  push     eax
00406058  push     ecx
00406059  push     ebx
0040605a  push     ebx
0040605b  push     edx
0040605c  push     eax
0040605d  mov      eax, dword ptr [ebp - 0x80]
00406060  push     ecx
00406061  push     ebx
00406062  push     ebx
00406063  push     eax
00406064  call     dword ptr [0x5381bc] ; GDI32.dll!StretchBlt
0040606a  cmp      edi, ebx
0040606c  jne      0x406072
0040606e  xor      edi, edi
00406070  jmp      0x406075
00406072  mov      edi, dword ptr [edi + 4]
00406075  mov      ecx, dword ptr [ebp - 0xf0]
0040607b  push     edi
0040607c  push     ecx
0040607d  .byte    0xe8
0040607e  sbb      eax, esp
