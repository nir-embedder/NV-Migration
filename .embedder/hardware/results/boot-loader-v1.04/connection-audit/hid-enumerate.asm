00413c20  push     ebp
00413c21  mov      ebp, esp
00413c23  push     -1
00413c25  push     0x52a768
00413c2a  mov      eax, dword ptr fs:[0]
00413c30  push     eax
00413c31  push     ecx
00413c32  push     ebx
00413c33  push     esi
00413c34  push     edi
00413c35  mov      eax, dword ptr [0x588250]
00413c3a  xor      eax, ebp
00413c3c  push     eax
00413c3d  lea      eax, [ebp - 0xc]
00413c40  mov      dword ptr fs:[0], eax
00413c46  mov      edi, ecx
00413c48  mov      esi, dword ptr [ebp + 0xc]
00413c4b  mov      eax, dword ptr [ebp + 8]
00413c4e  push     esi
00413c4f  push     eax
00413c50  mov      dword ptr [ebp - 0x10], 0
00413c57  call     0x416f00 ; hid_enumerate
00413c5c  mov      ebx, eax
00413c5e  add      esp, 8
00413c61  test     ebx, ebx
00413c63  je       0x413c91
00413c65  mov      ecx, dword ptr [ebp + 0x10]
00413c68  jmp      0x413c70
00413c6a  lea      ebx, [ebx]
00413c70  mov      dx, word ptr [ebp + 8]
00413c74  cmp      word ptr [eax + 4], dx
00413c78  jne      0x413c8a
00413c7a  cmp      word ptr [eax + 6], si
00413c7e  jne      0x413c8a
00413c80  cmp      ecx, -1
00413c83  je       0x413cc0
00413c85  cmp      dword ptr [eax + 0x1c], ecx
00413c88  je       0x413cc0
00413c8a  mov      eax, dword ptr [eax + 0x20]
00413c8d  test     eax, eax
00413c8f  jne      0x413c70
00413c91  push     0
00413c93  lea      ecx, [edi + 8]
00413c96  push     0x5399ac
00413c9b  call     0x403180
00413ca0  push     ebx
00413ca1  call     0x416a30 ; hid_free_enumeration
00413ca6  mov      eax, dword ptr [ebp - 0x10]
00413ca9  add      esp, 4
00413cac  mov      ecx, dword ptr [ebp - 0xc]
00413caf  mov      dword ptr fs:[0], ecx
00413cb6  pop      ecx
00413cb7  pop      edi
00413cb8  pop      esi
00413cb9  pop      ebx
00413cba  mov      esp, ebp
00413cbc  pop      ebp
00413cbd  ret      0xc
00413cc0  mov      esi, dword ptr [eax]
00413cc2  test     esi, esi
00413cc4  je       0x413c91
00413cc6  push     esi
00413cc7  call     0x4173f0 ; hid_open_path
00413ccc  add      esp, 4
00413ccf  push     esi
00413cd0  lea      ecx, [ebp + 8]
00413cd3  mov      dword ptr [ebp - 0x10], eax
00413cd6  call     0x413b80
00413cdb  lea      ecx, [edi + 8]
00413cde  push     eax
00413cdf  mov      dword ptr [ebp - 4], 0
00413ce6  call     0x405a50
00413ceb  mov      eax, dword ptr [ebp + 8]
00413cee  add      eax, -0x10
00413cf1  mov      dword ptr [ebp - 4], 0xffffffff
00413cf8  lea      ecx, [eax + 0xc]
00413cfb  or       edx, 0xffffffff
00413cfe  lock xadd dword ptr [ecx], edx
00413d02  dec      edx
00413d03  test     edx, edx
00413d05  jg       0x413ca0
00413d07  mov      ecx, dword ptr [eax]
00413d09  mov      edx, dword ptr [ecx]
00413d0b  push     eax
00413d0c  mov      eax, dword ptr [edx + 4]
00413d0f  call     eax
00413d11  jmp      0x413ca0
00413d13  int3     
00413d14  int3     
00413d15  int3     
00413d16  int3     
00413d17  int3     
00413d18  int3     
00413d19  int3     
00413d1a  int3     
00413d1b  int3     
00413d1c  int3     
00413d1d  int3     
00413d1e  int3     
00413d1f  int3     
