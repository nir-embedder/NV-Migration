00415e90  push     ebp
00415e91  mov      ebp, esp
00415e93  push     -1
00415e95  push     0x52a9c0
00415e9a  mov      eax, dword ptr fs:[0]
00415ea0  push     eax
00415ea1  sub      esp, 0x38
00415ea4  mov      eax, dword ptr [0x588250]
00415ea9  xor      eax, ebp
00415eab  mov      dword ptr [ebp - 0x10], eax
00415eae  push     ebx
00415eaf  push     esi
00415eb0  push     edi
00415eb1  push     eax
00415eb2  lea      eax, [ebp - 0xc]
00415eb5  mov      dword ptr fs:[0], eax
00415ebb  mov      esi, ecx
00415ebd  lea      eax, [ebp + 8]
00415ec0  push     eax
00415ec1  lea      ecx, [ebp - 0x44]
00415ec4  push     0x53ddf0
00415ec9  xor      ebx, ebx
00415ecb  push     ecx
00415ecc  mov      dword ptr [ebp - 4], ebx
00415ecf  call     0x4038a0
00415ed4  add      esp, 0xc
00415ed7  push     eax
00415ed8  lea      ecx, [ebp + 8]
00415edb  mov      byte ptr [ebp - 4], 1
00415edf  call     0x405a50
00415ee4  mov      eax, dword ptr [ebp - 0x44]
00415ee7  add      eax, -0x10
00415eea  or       edi, 0xffffffff
00415eed  mov      byte ptr [ebp - 4], bl
00415ef0  lea      edx, [eax + 0xc]
00415ef3  mov      ecx, edi
00415ef5  lock xadd dword ptr [edx], ecx
00415ef9  dec      ecx
00415efa  test     ecx, ecx
00415efc  jg       0x415f08
00415efe  mov      ecx, dword ptr [eax]
00415f00  mov      edx, dword ptr [ecx]
00415f02  push     eax
00415f03  mov      eax, dword ptr [edx + 4]
00415f06  call     eax
00415f08  mov      eax, dword ptr [esi + 4]
00415f0b  cmp      eax, edi
00415f0d  je       0x415f19
00415f0f  push     eax
00415f10  call     dword ptr [0x538468] ; KERNEL32.dll!CloseHandle
00415f16  mov      dword ptr [esi + 4], edi
00415f19  mov      ecx, dword ptr [ebp + 8]
00415f1c  push     ebx
00415f1d  push     0x40000080
00415f22  push     3
00415f24  push     ebx
00415f25  push     ebx
00415f26  push     0xc0000000
00415f2b  push     ecx
00415f2c  call     dword ptr [0x53841c] ; KERNEL32.dll!CreateFileW
00415f32  mov      dword ptr [esi + 4], eax
00415f35  cmp      eax, edi
00415f37  jne      0x415f5f
00415f39  mov      eax, dword ptr [ebp + 8]
00415f3c  add      eax, -0x10
00415f3f  mov      dword ptr [ebp - 4], edi
00415f42  lea      edx, [eax + 0xc]
00415f45  lock xadd dword ptr [edx], edi
00415f49  dec      edi
00415f4a  test     edi, edi
00415f4c  jg       0x415f58
00415f4e  mov      ecx, dword ptr [eax]
00415f50  mov      edx, dword ptr [ecx]
00415f52  push     eax
00415f53  mov      eax, dword ptr [edx + 4]
00415f56  call     eax
00415f58  xor      eax, eax
00415f5a  jmp      0x416024
00415f5f  xor      ecx, ecx
00415f61  mov      dword ptr [ebp - 0x38], ecx
00415f64  mov      dword ptr [ebp - 0x40], ecx
00415f67  mov      dword ptr [ebp - 0x3c], ecx
00415f6a  mov      dword ptr [ebp - 0x34], ecx
00415f6d  mov      dword ptr [ebp - 0x30], ecx
00415f70  lea      ecx, [ebp - 0x40]
00415f73  push     ecx
00415f74  push     eax
00415f75  mov      dword ptr [ebp - 0x38], 0x4e20
00415f7c  call     dword ptr [0x538420] ; KERNEL32.dll!SetCommTimeouts
00415f82  mov      ecx, 0x1c
00415f87  lea      eax, [ebp - 0x2c]
00415f8a  lea      ebx, [ebx]
00415f90  mov      byte ptr [eax], bl
00415f92  inc      eax
00415f93  dec      ecx
00415f94  jne      0x415f90
00415f96  mov      eax, dword ptr [esi + 4]
00415f99  lea      edx, [ebp - 0x2c]
00415f9c  push     edx
00415f9d  push     eax
00415f9e  mov      dword ptr [ebp - 0x2c], 0x1c
00415fa5  call     dword ptr [0x538424] ; KERNEL32.dll!GetCommState
00415fab  mov      edx, dword ptr [ebp - 0x24]
00415fae  mov      ecx, dword ptr [ebp + 0xc]
00415fb1  lea      eax, [ebp - 0x2c]
00415fb4  mov      dword ptr [ebp - 0x28], ecx
00415fb7  mov      ecx, dword ptr [esi + 4]
00415fba  and      edx, 0xffffffdd
00415fbd  push     eax
00415fbe  or       edx, 0x11
00415fc1  push     ecx
00415fc2  mov      word ptr [ebp - 0x1a], 8
00415fc8  mov      byte ptr [ebp - 0x18], bl
00415fcb  mov      dword ptr [ebp - 0x24], edx
00415fce  call     dword ptr [0x538428] ; KERNEL32.dll!SetCommState
00415fd4  mov      edx, dword ptr [esi + 4]
00415fd7  push     5
00415fd9  push     edx
00415fda  call     dword ptr [0x53842c] ; KERNEL32.dll!SetCommMask
00415fe0  mov      eax, dword ptr [esi + 4]
00415fe3  push     0x80
00415fe8  push     0x400
00415fed  push     eax
00415fee  call     dword ptr [0x538430] ; KERNEL32.dll!SetupComm
00415ff4  mov      ecx, dword ptr [esi + 4]
00415ff7  push     0xf
00415ff9  push     ecx
00415ffa  call     dword ptr [0x53843c] ; KERNEL32.dll!PurgeComm
00416000  mov      eax, dword ptr [ebp + 8]
00416003  add      eax, -0x10
00416006  mov      dword ptr [ebp - 4], edi
00416009  lea      edx, [eax + 0xc]
0041600c  lock xadd dword ptr [edx], edi
00416010  dec      edi
00416011  test     edi, edi
00416013  jg       0x41601f
00416015  mov      ecx, dword ptr [eax]
00416017  mov      edx, dword ptr [ecx]
00416019  push     eax
0041601a  mov      eax, dword ptr [edx + 4]
0041601d  call     eax
0041601f  mov      eax, 1
00416024  mov      ecx, dword ptr [ebp - 0xc]
00416027  mov      dword ptr fs:[0], ecx
0041602e  pop      ecx
0041602f  pop      edi
00416030  pop      esi
00416031  pop      ebx
00416032  mov      ecx, dword ptr [ebp - 0x10]
00416035  xor      ecx, ebp
00416037  call     0x50bc27
0041603c  mov      esp, ebp
0041603e  pop      ebp
0041603f  ret      8
00416042  int3     
00416043  int3     
00416044  int3     
00416045  int3     
00416046  int3     
00416047  int3     
00416048  int3     
00416049  int3     
0041604a  int3     
0041604b  int3     
0041604c  int3     
0041604d  int3     
0041604e  int3     
0041604f  int3     
00416050  mov      dword ptr [ecx], 0x53de04
00416056  jmp      0x423775
0041605b  int3     
0041605c  int3     
0041605d  int3     
0041605e  int3     
0041605f  int3     
00416060  mov      eax, dword ptr [ecx + 0x20]
00416063  push     0
00416065  push     0
00416067  push     0x31
00416069  push     eax
0041606a  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
00416070  push     eax
00416071  call     0x4223f8
00416076  ret      
00416077  int3     
00416078  int3     
00416079  int3     
0041607a  int3     
0041607b  int3     
0041607c  int3     
0041607d  int3     
0041607e  int3     
0041607f  int3     
00416080  push     ebp
00416081  mov      ebp, esp
00416083  mov      eax, dword ptr [ebp + 0xc]
00416086  push     esi
00416087  push     edi
00416088  mov      edi, dword ptr [0x5388ac] ; USER32.dll!SendMessageW
0041608e  mov      esi, ecx
00416090  mov      ecx, dword ptr [ebp + 8]
00416093  mov      edx, dword ptr [esi + 0x20]
00416096  push     eax
00416097  push     ecx
00416098  push     0xb1
0041609d  push     edx
0041609e  call     edi
004160a0  cmp      dword ptr [ebp + 0x10], 0
004160a4  jne      0x4160b5
004160a6  mov      eax, dword ptr [esi + 0x20]
004160a9  push     0
004160ab  push     0
004160ad  push     0xb7
004160b2  push     eax
004160b3  call     edi
004160b5  pop      edi
004160b6  pop      esi
004160b7  pop      ebp
004160b8  ret      0xc
004160bb  int3     
004160bc  int3     
004160bd  int3     
004160be  int3     
004160bf  int3     
004160c0  push     ebp
004160c1  mov      ebp, esp
004160c3  push     esi
004160c4  mov      esi, ecx
004160c6  call     0x41bf92
004160cb  mov      eax, dword ptr [ebp + 8]
004160ce  mov      ecx, dword ptr [ebp + 0xc]
004160d1  mov      dl, byte ptr [ebp + 0x10]
004160d4  mov      dword ptr [esi + 0x74], eax
004160d7  mov      al, byte ptr [ebp + 0x14]
004160da  mov      byte ptr [esi + 0x7d], al
004160dd  mov      dword ptr [esi], 0x53de04
004160e3  mov      dword ptr [esi + 0x78], ecx
004160e6  mov      byte ptr [esi + 0x7c], dl
004160e9  mov      eax, esi
004160eb  pop      esi
004160ec  pop      ebp
004160ed  ret      0x10
004160f0  push     ebp
004160f1  mov      ebp, esp
004160f3  push     esi
004160f4  mov      esi, ecx
004160f6  mov      dword ptr [esi], 0x53de04
004160fc  call     0x423775
00416101  test     byte ptr [ebp + 8], 1
00416105  je       0x416110
00416107  push     esi
00416108  call     0x41774d
0041610d  add      esp, 4
00416110  mov      eax, esi
00416112  pop      esi
00416113  pop      ebp
00416114  ret      4
00416117  int3     
00416118  int3     
00416119  int3     
0041611a  int3     
0041611b  int3     
0041611c  int3     
0041611d  int3     
0041611e  int3     
0041611f  int3     
00416120  push     ebp
00416121  mov      ebp, esp
00416123  sub      esp, 8
00416126  mov      eax, dword ptr [ebp + 0xc]
00416129  mov      eax, dword ptr [eax]
0041612b  lea      edx, [ebp - 8]
0041612e  push     edx
0041612f  mov      edx, dword ptr [eax - 0xc]
00416132  push     edx
00416133  push     eax
00416134  mov      eax, dword ptr [ecx + 8]
00416137  push     eax
00416138  call     dword ptr [0x5381b4] ; GDI32.dll!GetTextExtentPoint32W
0041613e  mov      eax, dword ptr [ebp + 8]
00416141  mov      ecx, dword ptr [ebp - 8]
00416144  mov      edx, dword ptr [ebp - 4]
00416147  mov      dword ptr [eax], ecx
00416149  mov      dword ptr [eax + 4], edx
0041614c  mov      esp, ebp
0041614e  pop      ebp
0041614f  ret      8
00416152  int3     
00416153  int3     
00416154  int3     
00416155  int3     
00416156  int3     
00416157  int3     
00416158  int3     
00416159  int3     
0041615a  int3     
0041615b  int3     
0041615c  int3     
0041615d  int3     
0041615e  int3     
0041615f  int3     
00416160  push     esi
00416161  push     edi
00416162  mov      edi, ecx
00416164  mov      eax, dword ptr [edi]
00416166  mov      esi, dword ptr [eax - 0xc]
00416169  test     esi, esi
0041616b  jns      0x416177
0041616d  push     0x80070057
00416172  call     0x401080
00416177  mov      edx, dword ptr [eax - 8]
0041617a  mov      ecx, 1
0041617f  sub      ecx, dword ptr [eax - 4]
00416182  sub      edx, esi
00416184  or       ecx, edx
00416186  jge      0x416190
00416188  push     esi
00416189  mov      ecx, edi
0041618b  call     0x402470
00416190  mov      ecx, dword ptr [edi]
00416192  lea      eax, [esi + 1]
00416195  push     eax
00416196  push     ecx
00416197  call     0x50d4c6
0041619c  mov      eax, dword ptr [edi]
0041619e  add      esp, 8
004161a1  cmp      esi, dword ptr [eax - 8]
004161a4  jg       0x41616d
004161a6  mov      dword ptr [eax - 0xc], esi
004161a9  mov      edx, dword ptr [edi]
004161ab  xor      eax, eax
004161ad  mov      word ptr [edx + esi*2], ax
004161b1  mov      eax, edi
004161b3  pop      edi
004161b4  pop      esi
004161b5  ret      
004161b6  int3     
004161b7  int3     
004161b8  int3     
004161b9  int3     
004161ba  int3     
004161bb  int3     
004161bc  int3     
004161bd  int3     
004161be  int3     
004161bf  int3     
004161c0  push     esi
004161c1  push     edi
004161c2  mov      edi, ecx
004161c4  mov      eax, dword ptr [edi]
004161c6  mov      esi, dword ptr [eax - 0xc]
004161c9  test     esi, esi
004161cb  jns      0x4161d7
004161cd  push     0x80070057
004161d2  call     0x401080
004161d7  mov      edx, dword ptr [eax - 8]
004161da  mov      ecx, 1
004161df  .byte    0x2b
