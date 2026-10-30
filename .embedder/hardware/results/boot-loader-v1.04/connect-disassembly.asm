00409be0  push     ebp
00409be1  mov      ebp, esp
00409be3  push     -1
00409be5  push     0x529e08
00409bea  mov      eax, dword ptr fs:[0]
00409bf0  push     eax
00409bf1  sub      esp, 0x18
00409bf4  push     ebx
00409bf5  push     esi
00409bf6  push     edi
00409bf7  mov      eax, dword ptr [0x588250]
00409bfc  xor      eax, ebp
00409bfe  push     eax
00409bff  lea      eax, [ebp - 0xc]
00409c02  mov      dword ptr fs:[0], eax
00409c08  mov      esi, ecx
00409c0a  xor      ebx, ebx
00409c0c  cmp      dword ptr [esi + 0xb0], ebx
00409c12  jne      0x409dd6
00409c18  push     ebx
00409c19  lea      ecx, [esi + 0xd0]
00409c1f  push     0x5399ac
00409c24  mov      dword ptr [esi + 0x94], ebx
00409c2a  call     0x403180
00409c2f  lea      edi, [esi + 0xb4]
00409c35  mov      dword ptr [ebp - 0x24], 0x53a99c
00409c3c  mov      dword ptr [ebp - 0x20], edi
00409c3f  mov      dword ptr [ebp - 0x1c], ebx
00409c42  cmp      dword ptr [edi + 4], ebx
00409c45  je       0x409c52
00409c47  call     dword ptr [0x53845c] ; KERNEL32.dll!GetCurrentThreadId
00409c4d  cmp      dword ptr [edi + 8], eax
00409c50  je       0x409c6e
00409c52  mov      eax, dword ptr [edi + 0xc]
00409c55  push     -1
00409c57  push     eax
00409c58  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00409c5e  call     dword ptr [0x53845c] ; KERNEL32.dll!GetCurrentThreadId
00409c64  mov      dword ptr [edi + 8], eax
00409c67  mov      dword ptr [edi + 4], 1
00409c6e  inc      dword ptr [edi + 0x10]
00409c71  mov      eax, dword ptr [esi + 0x90]
00409c77  dec      eax
00409c78  mov      dword ptr [ebp - 4], ebx
00409c7b  cmp      eax, 4
00409c7e  ja       0x409dea
00409c84  jmp      dword ptr [eax*4 + 0x409e10]
00409c8b  push     -1
00409c8d  push     0x2000
00409c92  push     0x416
00409c97  lea      ecx, [esi + 0x9c]
00409c9d  call     0x413d20
00409ca2  test     eax, eax
00409ca4  je       0x409cb2
00409ca6  mov      dword ptr [esi + 0x94], 0x2000
00409cb0  jmp      0x409cd7
00409cb2  push     -1
00409cb4  push     0x200c
00409cb9  push     0x416
00409cbe  lea      ecx, [esi + 0x9c]
00409cc4  call     0x413d20
00409cc9  test     eax, eax
00409ccb  je       0x409d35
00409ccd  mov      dword ptr [esi + 0x94], 0x200c
00409cd7  lea      ecx, [ebp - 0x10]
00409cda  push     ecx
00409cdb  lea      ecx, [esi + 0x9c]
00409ce1  call     0x413b50
00409ce6  push     eax
00409ce7  lea      ecx, [esi + 0xd0]
00409ced  mov      byte ptr [ebp - 4], 1
00409cf1  call     0x405a50
00409cf6  lea      ecx, [ebp - 0x10]
00409cf9  jmp      0x409dbf
00409cfe  mov      edx, dword ptr [esi + 0xc8]
00409d04  mov      eax, dword ptr [esi + 0x98]
00409d0a  push     edx
00409d0b  push     ecx
00409d0c  sub      eax, 0x10
00409d0f  mov      dword ptr [ebp - 0x14], esp
00409d12  mov      edi, esp
00409d14  push     eax
00409d15  call     0x4024d0
00409d1a  add      eax, 0x10
00409d1d  add      esp, 4
00409d20  lea      ecx, [esi + 0xa8]
00409d26  mov      dword ptr [edi], eax
00409d28  call     0x415e90
00409d2d  cmp      eax, ebx
00409d2f  jne      0x409dc4
00409d35  lea      ecx, [ebp - 0x24]
00409d38  call     0x4097a0
00409d3d  xor      al, al
00409d3f  mov      ecx, dword ptr [ebp - 0xc]
00409d42  mov      dword ptr fs:[0], ecx
00409d49  pop      ecx
00409d4a  pop      edi
00409d4b  pop      esi
00409d4c  pop      ebx
00409d4d  mov      esp, ebp
00409d4f  pop      ebp
00409d50  ret      
00409d51  push     4
00409d53  push     0x200a
00409d58  push     0x416
00409d5d  lea      ecx, [esi + 0x9c]
00409d63  call     0x413d20
00409d68  test     eax, eax
00409d6a  je       0x409d78
00409d6c  mov      dword ptr [esi + 0x94], 0x200a
00409d76  jmp      0x409d9d
00409d78  push     4
00409d7a  push     0x2007
00409d7f  push     0x416
00409d84  lea      ecx, [esi + 0x9c]
00409d8a  call     0x413d20
00409d8f  test     eax, eax
00409d91  je       0x409d35
00409d93  mov      dword ptr [esi + 0x94], 0x2007
00409d9d  lea      eax, [ebp - 0x14]
00409da0  push     eax
00409da1  lea      ecx, [esi + 0x9c]
00409da7  call     0x413b50
00409dac  push     eax
00409dad  lea      ecx, [esi + 0xd0]
00409db3  mov      byte ptr [ebp - 4], 2
00409db7  call     0x405a50
00409dbc  lea      ecx, [ebp - 0x14]
00409dbf  call     0x4023e0
00409dc4  lea      ecx, [ebp - 0x24]
00409dc7  mov      dword ptr [esi + 0xb0], 1
00409dd1  call     0x4097a0
00409dd6  mov      al, 1
00409dd8  mov      ecx, dword ptr [ebp - 0xc]
00409ddb  mov      dword ptr fs:[0], ecx
00409de2  pop      ecx
00409de3  pop      edi
00409de4  pop      esi
00409de5  pop      ebx
00409de6  mov      esp, ebp
00409de8  pop      ebp
00409de9  ret      
00409dea  dec      dword ptr [edi + 0x10]
00409ded  jne      0x409dfc
00409def  mov      ecx, dword ptr [edi + 0xc]
00409df2  push     ecx
00409df3  mov      dword ptr [edi + 4], ebx
00409df6  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
00409dfc  xor      al, al
00409dfe  mov      ecx, dword ptr [ebp - 0xc]
00409e01  mov      dword ptr fs:[0], ecx
00409e08  pop      ecx
00409e09  pop      edi
00409e0a  pop      esi
00409e0b  pop      ebx
00409e0c  mov      esp, ebp
00409e0e  pop      ebp
00409e0f  ret      
00409e10  mov      ebx, dword ptr [eax + eax*2 + 0x409cfe00]
00409e17  add      byte ptr [ecx - 0x63], dl
00409e1a  inc      eax
00409e1b  add      byte ptr [ecx - 0x63], dl
00409e1e  inc      eax
00409e1f  add      byte ptr [ecx - 0x63], dl
00409e22  inc      eax
00409e23  add      ah, cl
00409e25  int3     
00409e26  int3     
00409e27  int3     
00409e28  int3     
00409e29  int3     
00409e2a  int3     
00409e2b  int3     
00409e2c  int3     
00409e2d  int3     
00409e2e  int3     
00409e2f  int3     
00409e30  push     ebp
00409e31  mov      ebp, esp
00409e33  push     -1
00409e35  push     0x529e38
00409e3a  mov      eax, dword ptr fs:[0]
00409e40  push     eax
00409e41  sub      esp, 0x10
00409e44  push     ebx
00409e45  push     esi
00409e46  push     edi
00409e47  mov      eax, dword ptr [0x588250]
00409e4c  xor      eax, ebp
00409e4e  push     eax
00409e4f  lea      eax, [ebp - 0xc]
00409e52  mov      dword ptr fs:[0], eax
00409e58  mov      edi, ecx
00409e5a  push     0
00409e5c  lea      ecx, [edi + 0xd0]
00409e62  push     0x5399ac
00409e67  call     0x403180
00409e6c  cmp      dword ptr [edi + 0xb8], 0
00409e73  mov      ebx, dword ptr [0x53845c] ; KERNEL32.dll!GetCurrentThreadId
00409e79  lea      esi, [edi + 0xb4]
00409e7f  mov      dword ptr [ebp - 0x1c], 0x53a99c
00409e86  mov      dword ptr [ebp - 0x18], esi
00409e89  mov      dword ptr [ebp - 0x14], 0
00409e90  je       0x409e99
00409e92  call     ebx
00409e94  cmp      dword ptr [esi + 8], eax
00409e97  je       0x409eb1
00409e99  mov      eax, dword ptr [esi + 0xc]
00409e9c  push     -1
00409e9e  push     eax
00409e9f  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00409ea5  call     ebx
00409ea7  mov      dword ptr [esi + 8], eax
00409eaa  mov      dword ptr [esi + 4], 1
00409eb1  inc      dword ptr [esi + 0x10]
00409eb4  xor      ebx, ebx
00409eb6  mov      dword ptr [ebp - 4], ebx
00409eb9  cmp      dword ptr [edi + 0xb0], ebx
00409ebf  jne      0x409ecc
00409ec1  dec      dword ptr [esi + 0x10]
00409ec4  jne      0x409f0f
00409ec6  mov      ecx, dword ptr [esi + 0xc]
00409ec9  push     ecx
00409eca  jmp      0x409f06
00409ecc  mov      eax, dword ptr [edi + 0x90]
00409ed2  dec      eax
00409ed3  mov      dword ptr [edi + 0xb0], ebx
00409ed9  cmp      eax, 4
00409edc  ja       0x409efd
00409ede  jmp      dword ptr [eax*4 + 0x409f24]
00409ee5  lea      ecx, [edi + 0xa8]
00409eeb  call     0x415c70
00409ef0  jmp      0x409efd
00409ef2  lea      ecx, [edi + 0x9c]
00409ef8  call     0x413900
00409efd  dec      dword ptr [esi + 0x10]
00409f00  jne      0x409f0f
00409f02  mov      edx, dword ptr [esi + 0xc]
00409f05  push     edx
00409f06  mov      dword ptr [esi + 4], ebx
00409f09  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
00409f0f  mov      ecx, dword ptr [ebp - 0xc]
00409f12  mov      dword ptr fs:[0], ecx
00409f19  pop      ecx
00409f1a  pop      edi
00409f1b  pop      esi
00409f1c  pop      ebx
00409f1d  mov      esp, ebp
00409f1f  pop      ebp
00409f20  ret      
00409f21  lea      ecx, [ecx]
00409f24  sahf     
00409f26  inc      eax
00409f27  add      ch, ah
00409f29  sahf     
00409f2a  inc      eax
00409f2b  add      dl, dh
00409f2d  sahf     
00409f2e  inc      eax
00409f2f  add      dl, dh
00409f31  sahf     
00409f32  inc      eax
00409f33  add      dl, dh
00409f35  sahf     
00409f36  inc      eax
00409f37  add      ah, cl
00409f39  int3     
00409f3a  int3     
00409f3b  int3     
00409f3c  int3     
00409f3d  int3     
00409f3e  int3     
00409f3f  int3     
