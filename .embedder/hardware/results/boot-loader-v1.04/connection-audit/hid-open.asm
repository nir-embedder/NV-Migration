00413c00  mov      ecx, esi
00413c02  call     0x405250
00413c07  mov      eax, esi
00413c09  mov      ecx, dword ptr [ebp - 0xc]
00413c0c  mov      dword ptr fs:[0], ecx
00413c13  pop      ecx
00413c14  pop      edi
00413c15  pop      esi
00413c16  mov      esp, ebp
00413c18  pop      ebp
00413c19  ret      4
00413c1c  int3     
00413c1d  int3     
00413c1e  int3     
00413c1f  int3     
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
00413d20  push     ebp
00413d21  mov      ebp, esp
00413d23  push     esi
00413d24  mov      esi, ecx
00413d26  cmp      dword ptr [esi + 4], 0
00413d2a  jne      0x413d42
00413d2c  mov      eax, dword ptr [ebp + 0x10]
00413d2f  mov      ecx, dword ptr [ebp + 0xc]
00413d32  mov      edx, dword ptr [ebp + 8]
00413d35  push     eax
00413d36  push     ecx
00413d37  push     edx
00413d38  mov      ecx, esi
00413d3a  call     0x413c20
00413d3f  mov      dword ptr [esi + 4], eax
00413d42  mov      eax, dword ptr [esi + 4]
00413d45  test     eax, eax
00413d47  je       0x413d54
00413d49  push     0
00413d4b  push     eax
00413d4c  call     0x416c80 ; hid_set_nonblocking
00413d51  add      esp, 8
00413d54  xor      eax, eax
00413d56  cmp      dword ptr [esi + 4], eax
00413d59  pop      esi
00413d5a  setne    al
00413d5d  pop      ebp
00413d5e  ret      0xc
00413d61  int3     
00413d62  int3     
00413d63  int3     
00413d64  int3     
00413d65  int3     
00413d66  int3     
00413d67  int3     
00413d68  int3     
00413d69  int3     
00413d6a  int3     
00413d6b  int3     
00413d6c  int3     
00413d6d  int3     
00413d6e  int3     
00413d6f  int3     
00413d70  ret      
00413d71  int3     
00413d72  int3     
00413d73  int3     
00413d74  int3     
00413d75  int3     
00413d76  int3     
00413d77  int3     
00413d78  int3     
00413d79  int3     
00413d7a  int3     
00413d7b  int3     
00413d7c  int3     
00413d7d  int3     
00413d7e  int3     
00413d7f  int3     
00413d80  push     ebp
00413d81  mov      ebp, esp
00413d83  push     esi
00413d84  mov      esi, ecx
00413d86  call     0x423de6
00413d8b  test     byte ptr [ebp + 8], 1
00413d8f  je       0x413d9a
00413d91  push     esi
00413d92  call     0x41774d
00413d97  add      esp, 4
00413d9a  mov      eax, esi
00413d9c  pop      esi
00413d9d  pop      ebp
00413d9e  ret      4
00413da1  int3     
00413da2  int3     
00413da3  int3     
00413da4  int3     
00413da5  int3     
00413da6  int3     
00413da7  int3     
00413da8  int3     
00413da9  int3     
00413daa  int3     
00413dab  int3     
00413dac  int3     
00413dad  int3     
00413dae  int3     
00413daf  int3     
00413db0  push     ebp
00413db1  mov      ebp, esp
00413db3  push     esi
00413db4  push     edi
00413db5  mov      edi, dword ptr [ebp + 8]
00413db8  mov      esi, ecx
00413dba  lea      eax, [esi + 0x94]
00413dc0  push     eax
00413dc1  push     0x448
00413dc6  push     edi
00413dc7  call     0x41954c
00413dcc  lea      ecx, [esi + 0x108]
00413dd2  push     ecx
00413dd3  push     0x447
00413dd8  push     edi
00413dd9  call     0x41954c
00413dde  lea      edx, [esi + 0x17c]
00413de4  push     edx
00413de5  push     0x442
00413dea  push     edi
00413deb  call     0x41954c
00413df0  add      esi, 0x1f0
00413df6  push     esi
00413df7  push     0x443
00413dfc  push     edi
00413dfd  call     0x4192fc
00413e02  pop      edi
00413e03  pop      esi
00413e04  pop      ebp
00413e05  ret      4
00413e08  int3     
00413e09  int3     
00413e0a  int3     
00413e0b  int3     
00413e0c  int3     
00413e0d  int3     
00413e0e  int3     
00413e0f  int3     
00413e10  push     ebx
00413e11  push     esi
00413e12  push     edi
00413e13  mov      esi, ecx
00413e15  call     0x4187eb
00413e1a  push     0x53d848
00413e1f  push     0x31
00413e21  push     0
00413e23  mov      ebx, dword ptr [0x5381b8] ; GDI32.dll!CreateFontW
00413e29  push     0
00413e2b  push     0
00413e2d  push     0
00413e2f  push     0
00413e31  push     0
00413e33  push     0
00413e35  push     0
00413e37  push     0
00413e39  push     0
00413e3b  push     0
00413e3d  push     0xb
00413e3f  lea      edi, [esi + 0x1f4]
00413e45  call     ebx
00413e47  push     eax
00413e48  mov      ecx, edi
00413e4a  call     0x42240c
00413e4f  test     eax, eax
00413e51  je       0x413e76
00413e53  test     edi, edi
00413e55  jne      0x413e65
00413e57  mov      eax, dword ptr [esi + 0x128]
00413e5d  push     1
00413e5f  push     edi
00413e60  push     0x30
00413e62  push     eax
00413e63  jmp      0x413ebc
00413e65  mov      edi, dword ptr [edi + 4]
00413e68  mov      eax, dword ptr [esi + 0x128]
00413e6e  push     1
00413e70  push     edi
00413e71  push     0x30
00413e73  push     eax
00413e74  jmp      0x413ebc
00413e76  push     0x53d834
00413e7b  push     0x31
00413e7d  push     0
00413e7f  push     0
00413e81  push     0
00413e83  push     0
00413e85  push     0
00413e87  push     0
00413e89  push     0
00413e8b  push     0
00413e8d  push     0
00413e8f  push     0
00413e91  push     0
00413e93  push     0xb
00413e95  lea      edi, [esi + 0x204]
00413e9b  call     ebx
00413e9d  push     eax
00413e9e  mov      ecx, edi
00413ea0  call     0x42240c
00413ea5  test     eax, eax
00413ea7  je       0x413ec2
00413ea9  test     edi, edi
00413eab  je       0x413eb0
00413ead  mov      edi, dword ptr [edi + 4]
00413eb0  mov      ecx, dword ptr [esi + 0x128]
00413eb6  push     1
00413eb8  push     edi
00413eb9  push     0x30
00413ebb  push     ecx
00413ebc  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
00413ec2  push     0
00413ec4  mov      ecx, esi
00413ec6  mov      dword ptr [esi + 0x1f0], 0
00413ed0  call     0x41c6f3
00413ed5  pop      edi
00413ed6  pop      esi
00413ed7  mov      eax, 1
00413edc  pop      ebx
00413edd  ret      
00413ede  int3     
00413edf  int3     
00413ee0  push     ebp
00413ee1  mov      ebp, esp
00413ee3  sub      esp, 0x54
00413ee6  mov      eax, dword ptr [0x588250]
00413eeb  xor      eax, ebp
00413eed  mov      dword ptr [ebp - 4], eax
00413ef0  push     esi
00413ef1  push     edi
00413ef2  mov      esi, ecx
00413ef4  call     0x41ce13
00413ef9  mov      ecx, dword ptr [esi + 0x20]
00413efc  lea      eax, [ebp - 0x40]
00413eff  xor      edi, edi
00413f01  push     eax
00413f02  push     ecx
00413f03  mov      dword ptr [ebp - 0x40], edi
00413f06  mov      dword ptr [ebp - 0x3c], edi
00413f09  mov      dword ptr [ebp - 0x38], edi
00413f0c  mov      dword ptr [ebp - 0x34], edi
00413f0f  call     dword ptr [0x53889c] ; USER32.dll!GetClientRect
00413f15  lea      edx, [ebp - 0x40]
00413f18  push     edx
00413f19  mov      ecx, esi
00413f1b  call     0x421fae
00413f20  lea      eax, [esi + 0x17c]
00413f26  cmp      eax, edi
00413f28  je       0x4140d8
00413f2e  cmp      dword ptr [eax + 0x20], edi
00413f31  je       0x4140d8
00413f37  mov      ecx, dword ptr [esi + 0x19c]
00413f3d  push     ebx
00413f3e  lea      eax, [ebp - 0x20]
00413f41  push     eax
00413f42  push     ecx
00413f43  mov      dword ptr [ebp - 0x20], edi
00413f46  mov      dword ptr [ebp - 0x1c], edi
00413f49  mov      dword ptr [ebp - 0x18], edi
00413f4c  mov      dword ptr [ebp - 0x14], edi
00413f4f  .byte    0xff
