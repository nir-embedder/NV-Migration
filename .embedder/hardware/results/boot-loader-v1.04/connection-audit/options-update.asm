00414ce0  push     ebp
00414ce1  mov      ebp, esp
00414ce3  cmp      byte ptr [ebp + 8], 0
00414ce7  push     esi
00414ce8  mov      esi, ecx
00414cea  lea      ecx, [esi + 0xb8]
00414cf0  je       0x414d0a
00414cf2  push     1
00414cf4  call     0x41a294
00414cf9  mov      eax, dword ptr [esi]
00414cfb  mov      edx, dword ptr [eax + 0x188]
00414d01  mov      ecx, esi
00414d03  call     edx
00414d05  pop      esi
00414d06  pop      ebp
00414d07  ret      4
00414d0a  push     0
00414d0c  call     0x41a294
00414d11  push     0
00414d13  lea      ecx, [esi + 0x12c]
00414d19  call     0x41a294
00414d1e  pop      esi
00414d1f  pop      ebp
00414d20  ret      4
00414d23  int3     
00414d24  int3     
00414d25  int3     
00414d26  int3     
00414d27  int3     
00414d28  int3     
00414d29  int3     
00414d2a  int3     
00414d2b  int3     
00414d2c  int3     
00414d2d  int3     
00414d2e  int3     
00414d2f  int3     
00414d30  push     ebp
00414d31  mov      ebp, esp
00414d33  pop      ebp
00414d34  jmp      0x41aca0
00414d39  int3     
00414d3a  int3     
00414d3b  int3     
00414d3c  int3     
00414d3d  int3     
00414d3e  int3     
00414d3f  int3     
00414d40  push     ebp
00414d41  mov      ebp, esp
00414d43  sub      esp, 0x4c
00414d46  mov      eax, dword ptr [0x588250]
00414d4b  xor      eax, ebp
00414d4d  mov      dword ptr [ebp - 4], eax
00414d50  push     ebx
00414d51  push     esi
00414d52  push     edi
00414d53  mov      esi, ecx
00414d55  call     0x41ce13
00414d5a  mov      eax, dword ptr [esi + 0x94]
00414d60  mov      ecx, dword ptr [esi + 0x98]
00414d66  xor      ebx, ebx
00414d68  push     ebx
00414d69  push     ebx
00414d6a  push     eax
00414d6b  push     ecx
00414d6c  mov      ecx, esi
00414d6e  mov      dword ptr [ebp - 0x14], ebx
00414d71  mov      dword ptr [ebp - 0x10], ebx
00414d74  mov      dword ptr [ebp - 0xc], ebx
00414d77  mov      dword ptr [ebp - 8], ebx
00414d7a  call     0x41c5ee
00414d7f  mov      eax, dword ptr [esi + 0x20]
00414d82  lea      edx, [ebp - 0x14]
00414d85  push     edx
00414d86  push     eax
00414d87  mov      dword ptr [esi + 0x98], ebx
00414d8d  mov      dword ptr [esi + 0x94], ebx
00414d93  call     dword ptr [0x5388a0] ; USER32.dll!GetWindowRect
00414d99  cmp      dword ptr [esi + 0xa0], ebx
00414d9f  jne      0x414e35
00414da5  xor      ecx, ecx
00414da7  xor      edi, edi
00414da9  mov      dword ptr [esi + 0xa4], ebx
00414daf  mov      eax, 0x66666667
00414db4  imul     ecx
00414db6  sar      edx, 2
00414db9  mov      dword ptr [ebp - 0x24], ecx
00414dbc  mov      eax, edx
00414dbe  push     1
00414dc0  lea      ecx, [ebp - 0x30]
00414dc3  shr      eax, 0x1f
00414dc6  push     ecx
00414dc7  add      eax, edx
00414dc9  push     1
00414dcb  mov      ecx, esi
00414dcd  mov      dword ptr [ebp - 0x30], 0x1c
00414dd4  mov      dword ptr [ebp - 0x2c], 0x17
00414ddb  mov      dword ptr [ebp - 0x28], ebx
00414dde  mov      dword ptr [ebp - 0x20], eax
00414de1  mov      dword ptr [ebp - 0x1c], ebx
00414de4  call     0x41ad17
00414de9  mov      eax, 0x66666667
00414dee  imul     edi
00414df0  sar      edx, 2
00414df3  mov      eax, edx
00414df5  push     1
00414df7  lea      ecx, [ebp - 0x4c]
00414dfa  shr      eax, 0x1f
00414dfd  push     ecx
00414dfe  add      eax, edx
00414e00  push     ebx
00414e01  mov      ecx, esi
00414e03  mov      dword ptr [ebp - 0x4c], 0x1c
00414e0a  mov      dword ptr [ebp - 0x48], 0x17
00414e11  mov      dword ptr [ebp - 0x44], ebx
00414e14  mov      dword ptr [ebp - 0x40], edi
00414e17  mov      dword ptr [ebp - 0x3c], eax
00414e1a  mov      dword ptr [ebp - 0x38], ebx
00414e1d  .byte    0xe8
00414e1e  cmc      
00414e1f  pop      esi
