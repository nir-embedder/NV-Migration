00415de0  push     ebp
00415de1  mov      ebp, esp
00415de3  push     esi
00415de4  mov      esi, ecx
00415de6  mov      eax, dword ptr [esi + 4]
00415de9  push     edi
00415dea  push     eax
00415deb  call     dword ptr [0x538434] ; KERNEL32.dll!SetCommBreak
00415df1  mov      edi, dword ptr [0x538480] ; KERNEL32.dll!Sleep
00415df7  push     0xa
00415df9  call     edi
00415dfb  mov      ecx, dword ptr [esi + 4]
00415dfe  push     ecx
00415dff  call     dword ptr [0x538438] ; KERNEL32.dll!ClearCommBreak
00415e05  mov      edx, dword ptr [ebp + 8]
00415e08  push     edx
00415e09  call     edi
00415e0b  pop      edi
00415e0c  mov      eax, 1
00415e11  pop      esi
00415e12  pop      ebp
00415e13  ret      4
00415e16  int3     
00415e17  int3     
00415e18  int3     
00415e19  int3     
00415e1a  int3     
00415e1b  int3     
00415e1c  int3     
00415e1d  int3     
00415e1e  int3     
00415e1f  int3     
00415e20  push     esi
00415e21  mov      esi, ecx
00415e23  mov      eax, dword ptr [esi + 4]
00415e26  mov      dword ptr [esi], 0x53ddec
00415e2c  cmp      eax, -1
00415e2f  je       0x415e3f
00415e31  push     eax
00415e32  call     dword ptr [0x538468] ; KERNEL32.dll!CloseHandle
00415e38  mov      dword ptr [esi + 4], 0xffffffff
00415e3f  pop      esi
00415e40  ret      
00415e41  int3     
00415e42  int3     
00415e43  int3     
00415e44  int3     
00415e45  int3     
00415e46  int3     
00415e47  int3     
00415e48  int3     
00415e49  int3     
00415e4a  int3     
00415e4b  int3     
00415e4c  int3     
00415e4d  int3     
00415e4e  int3     
00415e4f  int3     
00415e50  push     ebp
00415e51  mov      ebp, esp
00415e53  push     esi
00415e54  mov      esi, ecx
00415e56  mov      eax, dword ptr [esi + 4]
00415e59  mov      dword ptr [esi], 0x53ddec
00415e5f  cmp      eax, -1
00415e62  je       0x415e72
00415e64  push     eax
00415e65  call     dword ptr [0x538468] ; KERNEL32.dll!CloseHandle
00415e6b  mov      dword ptr [esi + 4], 0xffffffff
00415e72  test     byte ptr [ebp + 8], 1
00415e76  je       0x415e81
00415e78  push     esi
00415e79  call     0x41774d
00415e7e  add      esp, 4
00415e81  mov      eax, esi
00415e83  pop      esi
00415e84  pop      ebp
00415e85  ret      4
00415e88  int3     
00415e89  int3     
00415e8a  int3     
00415e8b  int3     
00415e8c  int3     
00415e8d  int3     
00415e8e  int3     
00415e8f  int3     
