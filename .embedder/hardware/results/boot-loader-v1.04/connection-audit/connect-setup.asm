00405b60  .byte    0xf0
00405b61  mov      dword ptr [ebp - 4], 0xffffffff
00405b68  lea      edx, [eax + 0xc]
00405b6b  or       ecx, 0xffffffff
00405b6e  lock xadd dword ptr [edx], ecx
00405b72  dec      ecx
00405b73  test     ecx, ecx
00405b75  jg       0x405b81
00405b77  mov      ecx, dword ptr [eax]
00405b79  mov      edx, dword ptr [ecx]
00405b7b  push     eax
00405b7c  mov      eax, dword ptr [edx + 4]
00405b7f  call     eax
00405b81  mov      ecx, dword ptr [ebp - 0xc]
00405b84  mov      dword ptr fs:[0], ecx
00405b8b  pop      ecx
00405b8c  pop      esi
00405b8d  mov      esp, ebp
00405b8f  pop      ebp
00405b90  ret      
00405b91  int3     
00405b92  int3     
00405b93  int3     
00405b94  int3     
00405b95  int3     
00405b96  int3     
00405b97  int3     
00405b98  int3     
00405b99  int3     
00405b9a  int3     
00405b9b  int3     
00405b9c  int3     
00405b9d  int3     
00405b9e  int3     
00405b9f  int3     
00405ba0  push     ebp
00405ba1  mov      ebp, esp
00405ba3  push     -1
00405ba5  push     0x52981b
00405baa  mov      eax, dword ptr fs:[0]
00405bb0  push     eax
00405bb1  sub      esp, 0x410
00405bb7  mov      eax, dword ptr [0x588250]
00405bbc  xor      eax, ebp
00405bbe  mov      dword ptr [ebp - 0x14], eax
00405bc1  push     ebx
00405bc2  push     esi
00405bc3  push     edi
00405bc4  push     eax
00405bc5  lea      eax, [ebp - 0xc]
00405bc8  mov      dword ptr fs:[0], eax
00405bce  mov      dword ptr [ebp - 0x10], esp
00405bd1  mov      dword ptr [ecx], 0x539260
00405bd7  mov      dword ptr [ebp - 4], 0
00405bde  call     0x422466
00405be3  mov      ecx, dword ptr [ebp - 0xc]
00405be6  mov      dword ptr fs:[0], ecx
00405bed  pop      ecx
00405bee  pop      edi
00405bef  pop      esi
00405bf0  pop      ebx
00405bf1  mov      ecx, dword ptr [ebp - 0x14]
00405bf4  xor      ecx, ebp
00405bf6  call     0x50bc27
00405bfb  mov      esp, ebp
00405bfd  pop      ebp
00405bfe  ret      
00405bff  lea      ecx, [ebp - 0x418]
00405c05  call     0x402c50
00405c0a  mov      esi, dword ptr [ebp - 0x41c]
00405c10  mov      eax, dword ptr [esi]
00405c12  mov      edx, dword ptr [eax + 0xc]
00405c15  push     0
00405c17  push     0x200
00405c1c  lea      ecx, [ebp - 0x414]
00405c22  push     ecx
00405c23  mov      ecx, esi
00405c25  mov      byte ptr [ebp - 4], 2
00405c29  call     edx
00405c2b  test     eax, eax
00405c2d  je       0x405c58
00405c2f  lea      eax, [ebp - 0x414]
00405c35  push     eax
00405c36  push     0x52
00405c38  push     0x539bf8
00405c3d  push     0x539bb4
00405c42  lea      ecx, [ebp - 0x418]
00405c48  push     0x539b98
00405c4d  push     ecx
00405c4e  call     0x403880
00405c53  add      esp, 0x18
00405c56  jmp      0x405c78
00405c58  push     0x52
00405c5a  push     0x539bf8
00405c5f  push     0x539bb4
00405c64  lea      edx, [ebp - 0x418]
00405c6a  push     0x539b80
00405c6f  push     edx
00405c70  call     0x403880
00405c75  add      esp, 0x14
00405c78  mov      eax, dword ptr [ebp - 0x418]
00405c7e  push     0
00405c80  push     0
00405c82  push     eax
00405c83  call     0x424a1f
00405c88  lea      ecx, [ebp - 0x418]
00405c8e  mov      byte ptr [ebp - 4], 1
00405c92  call     0x4023e0
00405c97  mov      edx, dword ptr [esi]
00405c99  mov      eax, dword ptr [edx + 4]
00405c9c  push     1
00405c9e  mov      ecx, esi
00405ca0  call     eax
00405ca2  mov      eax, 0x405be3
00405ca7  ret      
00405ca8  int3     
00405ca9  int3     
00405caa  int3     
00405cab  int3     
00405cac  int3     
00405cad  int3     
00405cae  int3     
00405caf  int3     
00405cb0  mov      dword ptr [ecx], 0x539ca0
00405cb6  jmp      0x405ba0
00405cbb  int3     
00405cbc  int3     
00405cbd  int3     
00405cbe  int3     
00405cbf  int3     
00405cc0  push     ebp
00405cc1  mov      ebp, esp
00405cc3  push     -1
00405cc5  push     0x529860
00405cca  mov      eax, dword ptr fs:[0]
00405cd0  push     eax
00405cd1  push     ecx
00405cd2  push     esi
00405cd3  push     edi
00405cd4  mov      eax, dword ptr [0x588250]
00405cd9  xor      eax, ebp
00405cdb  push     eax
00405cdc  lea      eax, [ebp - 0xc]
00405cdf  mov      dword ptr fs:[0], eax
00405ce5  mov      esi, ecx
00405ce7  mov      eax, dword ptr [ebp + 0xc]
00405cea  add      eax, -0x10
00405ced  push     eax
00405cee  mov      dword ptr [ebp - 4], 0
00405cf5  call     0x4024d0
00405cfa  lea      edi, [eax + 0x10]
00405cfd  add      esp, 4
00405d00  mov      dword ptr [ebp - 0x10], edi
00405d03  mov      eax, dword ptr [ebp + 8]
00405d06  lea      edx, [ebp - 0x10]
00405d09  lea      ecx, [esi + 0x1d8]
00405d0f  push     edx
00405d10  mov      byte ptr [ebp - 4], 1
00405d14  mov      dword ptr [esi + 0x1d0], eax
00405d1a  call     0x405a50
00405d1f  mov      eax, dword ptr [ebp + 0x10]
00405d22  mov      dword ptr [esi + 0x208], eax
00405d28  lea      eax, [edi - 0x10]
00405d2b  mov      byte ptr [ebp - 4], 0
00405d2f  lea      ecx, [eax + 0xc]
00405d32  or       edx, 0xffffffff
00405d35  lock xadd dword ptr [ecx], edx
00405d39  dec      edx
00405d3a  test     edx, edx
00405d3c  jg       0x405d48
00405d3e  mov      ecx, dword ptr [eax]
00405d40  mov      edx, dword ptr [ecx]
00405d42  push     eax
00405d43  mov      eax, dword ptr [edx + 4]
00405d46  call     eax
00405d48  mov      eax, dword ptr [ebp + 0xc]
00405d4b  add      eax, -0x10
00405d4e  mov      dword ptr [ebp - 4], 0xffffffff
00405d55  lea      ecx, [eax + 0xc]
00405d58  or       edx, 0xffffffff
00405d5b  lock xadd dword ptr [ecx], edx
00405d5f  dec      edx
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
