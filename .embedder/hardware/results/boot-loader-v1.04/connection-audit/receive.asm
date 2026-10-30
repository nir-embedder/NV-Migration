004097d0  push     ebx
004097d1  add      bl, al
004097d3  int3     
004097d4  int3     
004097d5  int3     
004097d6  int3     
004097d7  int3     
004097d8  int3     
004097d9  int3     
004097da  int3     
004097db  int3     
004097dc  int3     
004097dd  int3     
004097de  int3     
004097df  int3     
004097e0  push     ebp
004097e1  mov      ebp, esp
004097e3  push     esi
004097e4  mov      esi, ecx
004097e6  cmp      dword ptr [esi + 8], 0
004097ea  mov      dword ptr [esi], 0x53a99c
004097f0  je       0x409800
004097f2  mov      eax, dword ptr [esi + 0xc]
004097f5  mov      ecx, dword ptr [esi + 4]
004097f8  push     eax
004097f9  call     0x409700
004097fe  jmp      0x409819
00409800  mov      eax, dword ptr [esi + 4]
00409803  dec      dword ptr [eax + 0x10]
00409806  jne      0x409819
00409808  mov      ecx, dword ptr [eax + 0xc]
0040980b  push     ecx
0040980c  mov      dword ptr [eax + 4], 0
00409813  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
00409819  test     byte ptr [ebp + 8], 1
0040981d  je       0x409828
0040981f  push     esi
00409820  call     0x41774d
00409825  add      esp, 4
00409828  mov      eax, esi
0040982a  pop      esi
0040982b  pop      ebp
0040982c  ret      4
0040982f  int3     
00409830  push     ebx
00409831  push     esi
00409832  mov      esi, ecx
00409834  cmp      dword ptr [esi + 0xb8], 0
0040983b  push     edi
0040983c  mov      edi, dword ptr [0x53845c] ; KERNEL32.dll!GetCurrentThreadId
00409842  mov      ebx, 1
00409847  je       0x409853
00409849  call     edi
0040984b  cmp      dword ptr [esi + 0xbc], eax
00409851  je       0x409870
00409853  mov      eax, dword ptr [esi + 0xc0]
00409859  push     -1
0040985b  push     eax
0040985c  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00409862  call     edi
00409864  mov      dword ptr [esi + 0xbc], eax
0040986a  mov      dword ptr [esi + 0xb8], ebx
00409870  add      dword ptr [esi + 0xc4], ebx
00409876  cmp      dword ptr [esi + 0xb0], 0
0040987d  mov      eax, dword ptr [esi + 0xc4]
00409883  setne    bl
00409886  dec      eax
00409887  mov      dword ptr [esi + 0xc4], eax
0040988d  jne      0x4098a6
0040988f  mov      ecx, dword ptr [esi + 0xc0]
00409895  push     ecx
00409896  mov      dword ptr [esi + 0xb8], 0
004098a0  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
004098a6  pop      edi
004098a7  pop      esi
004098a8  mov      al, bl
004098aa  pop      ebx
004098ab  ret      
004098ac  int3     
004098ad  int3     
004098ae  int3     
004098af  int3     
004098b0  push     ebp
004098b1  mov      ebp, esp
004098b3  mov      eax, dword ptr [ebp + 8]
004098b6  cmp      eax, 0xc
004098b9  jbe      0x4098c1
004098bb  xor      eax, eax
004098bd  pop      ebp
004098be  ret      4
004098c1  mov      eax, dword ptr [ecx + eax*4 + 0xd4]
004098c8  pop      ebp
004098c9  ret      4
004098cc  int3     
004098cd  int3     
004098ce  int3     
004098cf  int3     
004098d0  push     ebp
004098d1  mov      ebp, esp
004098d3  push     esi
004098d4  mov      esi, ecx
004098d6  cmp      dword ptr [esi + 0xb0], 0
004098dd  push     edi
004098de  jne      0x4098f5
004098e0  push     0x5711e4
004098e5  lea      eax, [ebp + 0xc]
004098e8  push     eax
004098e9  mov      dword ptr [ebp + 0xc], 0x53a9a0
004098f0  call     0x50b72f
004098f5  mov      eax, dword ptr [esi + 0x90]
004098fb  dec      eax
004098fc  cmp      eax, 4
004098ff  ja       0x409928
00409901  mov      edi, dword ptr [ebp + 0xc]
00409904  jmp      dword ptr [eax*4 + 0x4099bc]
0040990b  mov      ecx, dword ptr [ebp + 0x10]
0040990e  push     ecx
0040990f  lea      edx, [ebp + 0x10]
00409912  push     edx
00409913  push     0x41
00409915  lea      eax, [esi + 4]
00409918  push     eax
00409919  lea      ecx, [esi + 0x9c]
0040991f  call     0x413920
00409924  test     eax, eax
00409926  jne      0x409973
00409928  pop      edi
00409929  xor      eax, eax
0040992b  pop      esi
0040992c  pop      ebp
0040992d  ret      0x10
00409930  mov      ecx, dword ptr [ebp + 0x10]
00409933  mov      eax, edi
00409935  neg      eax
00409937  push     ecx
00409938  sbb      eax, eax
0040993a  lea      edx, [ebp + 0x10]
0040993d  and      eax, 0x34
00409940  push     edx
00409941  add      eax, 0xc
00409944  push     eax
00409945  lea      ecx, [esi + 5]
00409948  push     ecx
00409949  lea      ecx, [esi + 0xa8]
0040994f  call     0x415c90
00409954  jmp      0x409924
00409956  mov      edx, dword ptr [ebp + 0x10]
00409959  push     edx
0040995a  lea      eax, [ebp + 0x10]
0040995d  push     eax
0040995e  push     0x41
00409960  lea      ecx, [esi + 4]
00409963  push     ecx
00409964  lea      ecx, [esi + 0x9c]
0040996a  call     0x413920
0040996f  test     eax, eax
00409971  je       0x409928
00409973  mov      eax, dword ptr [ebp + 0x10]
00409976  cmp      eax, 0xc
00409979  jb       0x409928
0040997b  cmp      dword ptr [ebp + 0x14], 0
0040997f  je       0x40998d
00409981  mov      edx, dword ptr [esi + 0x88]
00409987  dec      edx
00409988  cmp      dword ptr [esi + 9], edx
0040998b  jne      0x409928
0040998d  add      eax, -0xc
00409990  cmp      edi, eax
00409992  jbe      0x409996
00409994  mov      edi, eax
00409996  mov      eax, dword ptr [ebp + 8]
00409999  test     eax, eax
0040999b  je       0x4099af
0040999d  test     edi, edi
0040999f  je       0x4099af
004099a1  push     edi
004099a2  add      esi, 0x11
004099a5  push     esi
004099a6  push     eax
004099a7  call     0x50ad10
004099ac  add      esp, 0xc
004099af  pop      edi
004099b0  mov      eax, 1
004099b5  pop      esi
004099b6  pop      ebp
004099b7  ret      0x10
004099ba  mov      edi, edi
004099bc  or       ebx, dword ptr [ecx - 0x66cfffc0]
004099c2  inc      eax
004099c3  add      byte ptr [esi - 0x67], dl
004099c6  inc      eax
004099c7  add      byte ptr [esi - 0x67], dl
004099ca  inc      eax
004099cb  add      byte ptr [esi - 0x67], dl
004099ce  inc      eax
004099cf  add      byte ptr [ebp - 0x75], dl
004099d2  in       al, dx
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
00409ae0  push     ebp
00409ae1  mov      ebp, esp
00409ae3  push     -1
00409ae5  push     0x529dcc
00409aea  mov      eax, dword ptr fs:[0]
00409af0  push     eax
00409af1  push     ecx
00409af2  push     esi
00409af3  mov      eax, dword ptr [0x588250]
00409af8  xor      eax, ebp
00409afa  push     eax
00409afb  lea      eax, [ebp - 0xc]
00409afe  mov      dword ptr fs:[0], eax
00409b04  mov      esi, ecx
00409b06  mov      dword ptr [ebp - 0x10], esi
00409b09  mov      dword ptr [esi], 0x53aa00
00409b0f  mov      eax, dword ptr [esi + 0xd0]
00409b15  sub      eax, 0x10
00409b18  mov      dword ptr [ebp - 4], 1
00409b1f  lea      ecx, [eax + 0xc]
00409b22  or       edx, 0xffffffff
00409b25  lock xadd dword ptr [ecx], edx
00409b29  dec      edx
00409b2a  test     edx, edx
00409b2c  jg       0x409b38
00409b2e  mov      ecx, dword ptr [eax]
00409b30  mov      edx, dword ptr [ecx]
00409b32  push     eax
00409b33  mov      eax, dword ptr [edx + 4]
00409b36  call     eax
00409b38  mov      ecx, dword ptr [esi + 0xc0]
00409b3e  push     ecx
00409b3f  mov      dword ptr [esi + 0xb4], 0x53a994
00409b49  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
00409b4f  lea      ecx, [esi + 0xa8]
00409b55  call     0x415e20
00409b5a  lea      ecx, [esi + 0x9c]
00409b60  mov      byte ptr [ebp - 4], 0
00409b64  call     0x413aa0
00409b69  mov      esi, dword ptr [esi + 0x98]
00409b6f  sub      esi, 0x10
00409b72  mov      dword ptr [ebp - 4], 0xffffffff
00409b79  lea      edx, [esi + 0xc]
00409b7c  or       eax, 0xffffffff
00409b7f  lock xadd dword ptr [edx], eax
00409b83  dec      eax
00409b84  test     eax, eax
00409b86  jg       0x409b92
00409b88  mov      ecx, dword ptr [esi]
00409b8a  mov      edx, dword ptr [ecx]
00409b8c  mov      eax, dword ptr [edx + 4]
00409b8f  push     esi
00409b90  call     eax
00409b92  mov      ecx, dword ptr [ebp - 0xc]
00409b95  mov      dword ptr fs:[0], ecx
00409b9c  pop      ecx
00409b9d  pop      esi
00409b9e  mov      esp, ebp
00409ba0  pop      ebp
00409ba1  ret      
00409ba2  int3     
00409ba3  int3     
00409ba4  int3     
00409ba5  int3     
00409ba6  int3     
00409ba7  int3     
00409ba8  int3     
00409ba9  int3     
00409baa  int3     
00409bab  int3     
00409bac  int3     
00409bad  int3     
00409bae  int3     
00409baf  int3     
00409bb0  push     ebp
00409bb1  mov      ebp, esp
00409bb3  push     esi
00409bb4  mov      esi, ecx
00409bb6  call     0x409ae0
00409bbb  test     byte ptr [ebp + 8], 1
00409bbf  je       0x409bca
00409bc1  push     esi
00409bc2  call     0x41774d
00409bc7  add      esp, 4
00409bca  mov      eax, esi
00409bcc  pop      esi
00409bcd  pop      ebp
00409bce  ret      4
00409bd1  int3     
00409bd2  int3     
00409bd3  int3     
00409bd4  int3     
00409bd5  int3     
00409bd6  int3     
00409bd7  int3     
00409bd8  int3     
00409bd9  int3     
00409bda  int3     
00409bdb  int3     
00409bdc  int3     
00409bdd  int3     
00409bde  int3     
00409bdf  int3     
