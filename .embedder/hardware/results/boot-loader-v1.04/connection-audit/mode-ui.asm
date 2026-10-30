00404870  push     esi
00404871  push     edi
00404872  mov      edi, dword ptr [0x5388ac] ; USER32.dll!SendMessageW
00404878  push     0
0040487a  push     0
0040487c  mov      esi, ecx
0040487e  mov      eax, dword ptr [esi + 0xd8]
00404884  push     0x14b
00404889  push     eax
0040488a  call     edi
0040488c  mov      ecx, dword ptr [esi + 0xd8]
00404892  push     0x53991c
00404897  push     0
00404899  push     0x143
0040489e  push     ecx
0040489f  call     edi
004048a1  mov      edx, dword ptr [esi + 0xd8]
004048a7  push     0x539910
004048ac  push     0
004048ae  push     0x143
004048b3  push     edx
004048b4  call     edi
004048b6  mov      eax, dword ptr [esi + 0xd8]
004048bc  push     0x539908
004048c1  push     0
004048c3  push     0x143
004048c8  push     eax
004048c9  call     edi
004048cb  mov      ecx, dword ptr [esi + 0xd8]
004048d1  push     0x539900
004048d6  push     0
004048d8  push     0x143
004048dd  push     ecx
004048de  call     edi
004048e0  mov      edx, dword ptr [esi + 0xd8]
004048e6  push     0x5398f8
004048eb  push     0
004048ed  push     0x143
004048f2  push     edx
004048f3  call     edi
004048f5  mov      eax, dword ptr [esi + 0xd8]
004048fb  push     0
004048fd  push     0
004048ff  push     0x14e
00404904  push     eax
00404905  call     edi
00404907  mov      ecx, dword ptr [esi + 0x504]
0040490d  push     0
0040490f  push     0
00404911  push     0x14b
00404916  push     ecx
00404917  call     edi
00404919  mov      edx, dword ptr [esi + 0x504]
0040491f  push     0x5398e8
00404924  push     0
00404926  push     0x143
0040492b  push     edx
0040492c  call     edi
0040492e  mov      eax, dword ptr [esi + 0x504]
00404934  push     0x5398d8
00404939  push     0
0040493b  push     0x143
