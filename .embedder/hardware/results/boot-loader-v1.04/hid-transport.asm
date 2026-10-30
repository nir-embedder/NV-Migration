00413740  pop      esi
00413741  .byte    0xff
00413742  dec      dword ptr [ebx - 0x769b0bb3]
00413748  or       eax, 0
0041374d  pop      ecx
0041374e  pop      esi
0041374f  mov      esp, ebp
00413751  pop      ebp
00413752  ret      
00413753  int3     
00413754  int3     
00413755  int3     
00413756  int3     
00413757  int3     
00413758  int3     
00413759  int3     
0041375a  int3     
0041375b  int3     
0041375c  int3     
0041375d  int3     
0041375e  int3     
0041375f  int3     
00413760  push     ebp
00413761  mov      ebp, esp
00413763  push     esi
00413764  mov      esi, ecx
00413766  call     0x4136b0
0041376b  test     byte ptr [ebp + 8], 1
0041376f  je       0x41377a
00413771  push     esi
00413772  call     0x41774d
00413777  add      esp, 4
0041377a  mov      eax, esi
0041377c  pop      esi
0041377d  pop      ebp
0041377e  ret      4
00413781  int3     
00413782  int3     
00413783  int3     
00413784  int3     
00413785  int3     
00413786  int3     
00413787  int3     
00413788  int3     
00413789  int3     
0041378a  int3     
0041378b  int3     
0041378c  int3     
0041378d  int3     
0041378e  int3     
0041378f  int3     
00413790  push     esi
00413791  mov      esi, ecx
00413793  mov      ecx, dword ptr [esi + 0xd0]
00413799  lea      eax, [ecx - 1]
0041379c  push     edi
0041379d  mov      edi, dword ptr [esi + 0xb8]
004137a3  not      eax
004137a5  and      dword ptr [esi + 0xd4], eax
004137ab  mov      edx, dword ptr [esi + 0xd4]
004137b1  test     edi, edi
004137b3  je       0x413809
004137b5  cmp      dword ptr [esi + 0xdc], 0
004137bc  je       0x4137f5
004137be  cmp      dword ptr [esi + 0xe0], 0
004137c5  mov      eax, dword ptr [esi + 0xcc]
004137cb  je       0x4137cf
004137cd  shr      eax, 1
004137cf  add      eax, dword ptr [esi + 0xc8]
004137d5  sub      eax, ecx
004137d7  cmp      edx, eax
004137d9  jbe      0x4137e1
004137db  mov      dword ptr [esi + 0xd4], eax
004137e1  mov      eax, dword ptr [esi + 0xd8]
004137e7  cmp      dword ptr [esi + 0xd4], eax
004137ed  jae      0x4137f5
004137ef  mov      dword ptr [esi + 0xd4], eax
004137f5  test     edi, edi
004137f7  je       0x413809
004137f9  cmp      dword ptr [esi + 0xdc], 0
00413800  je       0x413809
00413802  mov      eax, 1
00413807  jmp      0x41380b
00413809  xor      eax, eax
0041380b  push     eax
0041380c  lea      ecx, [esi + 0x100]
00413812  call     0x41a294
00413817  cmp      dword ptr [esi + 0xb8], 0
0041381e  je       0x413830
00413820  cmp      dword ptr [esi + 0xdc], 0
00413827  je       0x413830
00413829  mov      eax, 1
0041382e  jmp      0x413832
00413830  xor      eax, eax
00413832  push     eax
00413833  push     0xc15
00413838  mov      ecx, esi
0041383a  call     0x41a01d
0041383f  mov      ecx, eax
00413841  call     0x41a294
00413846  cmp      dword ptr [esi + 0xb8], 0
0041384d  je       0x41385f
0041384f  cmp      dword ptr [esi + 0xdc], 0
00413856  je       0x41385f
00413858  mov      eax, 1
0041385d  jmp      0x413861
0041385f  xor      eax, eax
00413861  push     eax
00413862  push     0xc87
00413867  mov      ecx, esi
00413869  call     0x41a01d
0041386e  mov      ecx, eax
00413870  call     0x41a294
00413875  mov      ecx, dword ptr [esi + 0xb8]
0041387b  neg      ecx
0041387d  sbb      ecx, ecx
0041387f  and      ecx, 0xf0000000
00413885  add      ecx, 0x10000000
0041388b  or       ecx, dword ptr [esi + 0xd4]
00413891  lea      edx, [esi + 0x180]
00413897  push     ecx
00413898  push     0x539b74
0041389d  push     edx
0041389e  call     0x403880
004138a3  mov      eax, dword ptr [esi + 0x194]
004138a9  mov      ecx, eax
004138ab  mov      edx, eax
004138ad  and      eax, 0xf
004138b0  inc      eax
004138b1  imul     eax, dword ptr [esi + 0xf4]
004138b8  add      eax, dword ptr [esi + 0xec]
004138be  shr      ecx, 5
004138c1  shr      edx, 6
004138c4  push     eax
004138c5  not      ecx
004138c7  not      edx
004138c9  lea      eax, [esi + 0x184]
004138cf  and      ecx, 1
004138d2  and      edx, 1
004138d5  push     0x53a970
004138da  push     eax
004138db  mov      dword ptr [esi + 0xf8], ecx
004138e1  mov      dword ptr [esi + 0xfc], edx
004138e7  call     0x403880
004138ec  add      esp, 0x18
004138ef  push     0
004138f1  mov      ecx, esi
004138f3  call     0x41c6f3
004138f8  pop      edi
004138f9  pop      esi
004138fa  ret      
004138fb  int3     
004138fc  int3     
004138fd  int3     
004138fe  int3     
004138ff  int3     
00413900  push     esi
00413901  mov      esi, ecx
00413903  mov      eax, dword ptr [esi + 4]
00413906  test     eax, eax
00413908  je       0x41391a
0041390a  push     eax
0041390b  call     0x416d50 ; hid_close
00413910  add      esp, 4
00413913  mov      dword ptr [esi + 4], 0
0041391a  pop      esi
0041391b  ret      
0041391c  int3     
0041391d  int3     
0041391e  int3     
0041391f  int3     
00413920  push     ebp
00413921  mov      ebp, esp
00413923  sub      esp, 0x108
00413929  mov      eax, dword ptr [0x588250]
0041392e  xor      eax, ebp
00413930  mov      dword ptr [ebp - 4], eax
00413933  mov      edx, dword ptr [ebp + 0x14]
00413936  mov      eax, dword ptr [ebp + 8]
00413939  mov      ecx, dword ptr [ecx + 4]
0041393c  push     ebx
0041393d  mov      ebx, dword ptr [ebp + 0x10]
00413940  push     esi
00413941  push     edi
00413942  mov      edi, dword ptr [ebp + 0xc]
00413945  push     edx
00413946  mov      dword ptr [ebp - 0x108], eax
0041394c  push     edi
0041394d  lea      eax, [ebp - 0x104]
00413953  push     eax
00413954  push     ecx
00413955  call     0x416b40 ; hid_read_timeout
0041395a  dec      edi
0041395b  xor      edx, edx
0041395d  add      esp, 0x10
00413960  mov      esi, eax
00413962  cmp      esi, edi
00413964  sete     dl
00413967  mov      edi, edx
00413969  test     edi, edi
0041396b  je       0x413985
0041396d  mov      ecx, dword ptr [ebp - 0x108]
00413973  push     esi
00413974  lea      eax, [ebp - 0x104]
0041397a  push     eax
0041397b  inc      ecx
0041397c  push     ecx
0041397d  call     0x50ad10
00413982  add      esp, 0xc
00413985  mov      eax, edi
00413987  test     ebx, ebx
00413989  je       0x41398d
0041398b  mov      dword ptr [ebx], esi
0041398d  mov      ecx, dword ptr [ebp - 4]
00413990  pop      edi
00413991  pop      esi
00413992  xor      ecx, ebp
00413994  pop      ebx
00413995  call     0x50bc27
0041399a  mov      esp, ebp
0041399c  pop      ebp
0041399d  ret      0x10
004139a0  push     ebp
004139a1  mov      ebp, esp
004139a3  sub      esp, 0x104
004139a9  mov      eax, dword ptr [0x588250]
004139ae  xor      eax, ebp
004139b0  mov      dword ptr [ebp - 4], eax
004139b3  mov      eax, dword ptr [ebp + 8]
004139b6  push     esi
004139b7  mov      esi, dword ptr [ebp + 0xc]
004139ba  push     edi
004139bb  push     esi
004139bc  push     eax
004139bd  lea      eax, [ebp - 0x104]
004139c3  push     eax
004139c4  mov      edi, ecx
004139c6  call     0x50ad10
004139cb  mov      edx, dword ptr [edi + 4]
004139ce  push     esi
004139cf  lea      ecx, [ebp - 0x104]
004139d5  push     ecx
004139d6  push     edx
004139d7  call     0x416a80 ; hid_write
004139dc  xor      ecx, ecx
004139de  add      esp, 0x18
004139e1  cmp      eax, esi
004139e3  sete     cl
004139e6  pop      edi
004139e7  pop      esi
004139e8  mov      eax, ecx
004139ea  mov      ecx, dword ptr [ebp - 4]
004139ed  xor      ecx, ebp
004139ef  call     0x50bc27
004139f4  mov      esp, ebp
004139f6  pop      ebp
004139f7  ret      0x10
004139fa  int3     
004139fb  int3     
