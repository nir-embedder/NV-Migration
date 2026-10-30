004099d0  push     ebp
004099d1  mov      ebp, esp
004099d3  push     -1
004099d5  push     0x529d8c
004099da  mov      eax, dword ptr fs:[0]
004099e0  push     eax
004099e1  push     ecx
004099e2  push     esi
004099e3  push     edi
004099e4  mov      eax, dword ptr [0x588250]
004099e9  xor      eax, ebp
004099eb  push     eax
004099ec  lea      eax, [ebp - 0xc]
004099ef  mov      dword ptr fs:[0], eax
004099f5  mov      esi, ecx
004099f7  mov      dword ptr [ebp - 0x10], esi
004099fa  mov      dword ptr [esi], 0x53aa00
00409a00  mov      dword ptr [esi + 0x88], 0x12
00409a0a  call     0x418e64
00409a0f  xor      ecx, ecx
00409a11  xor      edi, edi
00409a13  cmp      eax, edi
00409a15  setne    cl
00409a18  cmp      ecx, edi
00409a1a  jne      0x409a26
00409a1c  push     0x80004005
00409a21  call     0x401080
00409a26  mov      edx, dword ptr [eax]
00409a28  mov      ecx, eax
00409a2a  mov      eax, dword ptr [edx + 0xc]
00409a2d  call     eax
00409a2f  add      eax, 0x10
00409a32  mov      dword ptr [esi + 0x98], eax
00409a38  lea      ecx, [esi + 0x9c]
00409a3e  mov      dword ptr [ebp - 4], edi
00409a41  call     0x413a00
00409a46  lea      ecx, [esi + 0xa8]
00409a4c  mov      byte ptr [ebp - 4], 1
00409a50  call     0x415c60
00409a55  push     edi
00409a56  mov      dword ptr [esi + 0xb0], edi
00409a5c  push     edi
00409a5d  push     edi
00409a5e  mov      dword ptr [esi + 0xb4], 0x53a994
00409a68  mov      dword ptr [esi + 0xb8], edi
00409a6e  mov      dword ptr [esi + 0xbc], 0xffffffff
00409a78  mov      dword ptr [esi + 0xc4], edi
00409a7e  call     dword ptr [0x538460] ; KERNEL32.dll!CreateMutexW
00409a84  mov      dword ptr [esi + 0xc0], eax
00409a8a  mov      dword ptr [esi + 0xcc], 1
00409a94  call     0x418e64
00409a99  cmp      eax, edi
00409a9b  jne      0x409aa7
00409a9d  push     0x80004005
00409aa2  call     0x401080
00409aa7  mov      edx, dword ptr [eax]
00409aa9  mov      ecx, eax
00409aab  mov      eax, dword ptr [edx + 0xc]
00409aae  call     eax
00409ab0  push     0x41
00409ab2  lea      ecx, [esi + 0x45]
00409ab5  add      eax, 0x10
00409ab8  push     0x61
00409aba  push     ecx
00409abb  mov      dword ptr [esi + 0xd0], eax
00409ac1  call     0x50c310
00409ac6  add      esp, 0xc
00409ac9  mov      eax, esi
00409acb  mov      ecx, dword ptr [ebp - 0xc]
00409ace  mov      dword ptr fs:[0], ecx
00409ad5  pop      ecx
00409ad6  pop      edi
00409ad7  pop      esi
00409ad8  mov      esp, ebp
00409ada  pop      ebp
00409adb  ret      
00409adc  int3     
00409add  int3     
00409ade  int3     
00409adf  int3     
