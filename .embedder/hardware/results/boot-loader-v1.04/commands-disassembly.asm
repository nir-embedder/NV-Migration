0040a2d0  push     ebp
0040a2d1  mov      ebp, esp
0040a2d3  sub      esp, 8
0040a2d6  push     esi
0040a2d7  push     0x14
0040a2d9  push     0
0040a2db  push     0
0040a2dd  push     0xc0
0040a2e2  mov      esi, ecx
0040a2e4  call     0x40a040
0040a2e9  test     eax, eax
0040a2eb  je       0x40a33c
0040a2ed  cmp      dword ptr [esi + 0xb0], 0
0040a2f4  jne      0x40a30b
0040a2f6  push     0x5711e4
0040a2fb  lea      eax, [ebp - 8]
0040a2fe  push     eax
0040a2ff  mov      dword ptr [ebp - 8], 0x53a9a0
0040a306  call     0x50b72f
0040a30b  mov      eax, dword ptr [esi + 0x90]
0040a311  dec      eax
0040a312  cmp      eax, 4
0040a315  ja       0x40a33c
0040a317  jmp      dword ptr [eax*4 + 0x40a39c]
0040a31e  push     0x7530
0040a323  lea      ecx, [ebp - 4]
0040a326  push     ecx
0040a327  push     0x41
0040a329  lea      edx, [esi + 4]
0040a32c  push     edx
0040a32d  lea      ecx, [esi + 0x9c]
0040a333  call     0x413920
0040a338  test     eax, eax
0040a33a  jne      0x40a37d
0040a33c  xor      eax, eax
0040a33e  pop      esi
0040a33f  mov      esp, ebp
0040a341  pop      ebp
0040a342  ret      
0040a343  push     0x7530
0040a348  lea      eax, [ebp - 4]
0040a34b  push     eax
0040a34c  push     0xc
0040a34e  lea      ecx, [esi + 5]
0040a351  push     ecx
0040a352  lea      ecx, [esi + 0xa8]
0040a358  call     0x415c90
0040a35d  jmp      0x40a338
0040a35f  push     0x7530
0040a364  lea      edx, [ebp - 4]
0040a367  push     edx
0040a368  push     0x41
0040a36a  lea      eax, [esi + 4]
0040a36d  push     eax
0040a36e  lea      ecx, [esi + 0x9c]
0040a374  call     0x413920
0040a379  test     eax, eax
0040a37b  je       0x40a33c
0040a37d  cmp      dword ptr [ebp - 4], 0xc
0040a381  jb       0x40a33c
0040a383  mov      ecx, dword ptr [esi + 0x88]
0040a389  dec      ecx
0040a38a  cmp      dword ptr [esi + 9], ecx
0040a38d  jne      0x40a33c
0040a38f  mov      eax, 1
0040a394  pop      esi
0040a395  mov      esp, ebp
0040a397  pop      ebp
0040a398  ret      
0040a399  lea      ecx, [ecx]
0040a39c  push     ds
0040a39d  mov      dword ptr [0xa3430040], eax
0040a3a2  inc      eax
0040a3a3  add      byte ptr [edi - 0x5d], bl
0040a3a6  inc      eax
0040a3a7  add      byte ptr [edi - 0x5d], bl
0040a3aa  inc      eax
0040a3ab  add      byte ptr [edi - 0x5d], bl
0040a3ae  inc      eax
0040a3af  add      byte ptr [ebp - 0x75], dl
0040a3b2  in       al, dx
0040a3b3  sub      esp, 8
0040a3b6  push     esi
0040a3b7  push     0x14
0040a3b9  push     0
0040a3bb  push     0
0040a3bd  push     0xe1
0040a3c2  mov      esi, ecx
0040a3c4  call     0x40a040
0040a3c9  test     eax, eax
0040a3cb  je       0x40a41c
0040a3cd  cmp      dword ptr [esi + 0xb0], 0
0040a3d4  jne      0x40a3eb
0040a3d6  push     0x5711e4
0040a3db  lea      eax, [ebp - 8]
0040a3de  push     eax
0040a3df  mov      dword ptr [ebp - 8], 0x53a9a0
0040a3e6  call     0x50b72f
0040a3eb  mov      eax, dword ptr [esi + 0x90]
0040a3f1  dec      eax
0040a3f2  cmp      eax, 4
0040a3f5  ja       0x40a41c
0040a3f7  jmp      dword ptr [eax*4 + 0x40a47c]
0040a3fe  push     0x7530
0040a403  lea      ecx, [ebp - 4]
0040a406  push     ecx
0040a407  push     0x41
0040a409  lea      edx, [esi + 4]
0040a40c  push     edx
0040a40d  lea      ecx, [esi + 0x9c]
0040a413  call     0x413920
0040a418  test     eax, eax
0040a41a  jne      0x40a45d
0040a41c  xor      eax, eax
0040a41e  pop      esi
0040a41f  mov      esp, ebp
0040a421  pop      ebp
0040a422  ret      
0040a423  push     0x7530
0040a428  lea      eax, [ebp - 4]
0040a42b  push     eax
0040a42c  push     0xc
0040a42e  lea      ecx, [esi + 5]
0040a431  push     ecx
0040a432  lea      ecx, [esi + 0xa8]
0040a438  call     0x415c90
0040a43d  jmp      0x40a418
0040a43f  push     0x7530
0040a444  lea      edx, [ebp - 4]
0040a447  push     edx
0040a448  push     0x41
0040a44a  lea      eax, [esi + 4]
0040a44d  push     eax
0040a44e  lea      ecx, [esi + 0x9c]
0040a454  call     0x413920
0040a459  test     eax, eax
0040a45b  je       0x40a41c
0040a45d  cmp      dword ptr [ebp - 4], 0xc
0040a461  jb       0x40a41c
0040a463  mov      ecx, dword ptr [esi + 0x88]
0040a469  dec      ecx
0040a46a  cmp      dword ptr [esi + 9], ecx
0040a46d  jne      0x40a41c
0040a46f  mov      eax, 1
0040a474  pop      esi
0040a475  mov      esp, ebp
0040a477  pop      ebp
0040a478  ret      
0040a479  lea      ecx, [ecx]
0040a47c  .byte    0xfe
0040a47d  mov      dword ptr [0xa4230040], eax
0040a482  inc      eax
0040a483  add      byte ptr [edi], bh
0040a485  movsb    byte ptr es:[edi], byte ptr [esi]
0040a486  inc      eax
0040a487  add      byte ptr [edi], bh
0040a489  movsb    byte ptr es:[edi], byte ptr [esi]
0040a48a  inc      eax
0040a48b  add      byte ptr [edi], bh
0040a48d  movsb    byte ptr es:[edi], byte ptr [esi]
0040a48e  inc      eax
0040a48f  add      byte ptr [ebp - 0x75], dl
0040a492  in       al, dx
0040a493  sub      esp, 0x40
0040a496  mov      eax, dword ptr [ebp + 8]
0040a499  push     esi
0040a49a  push     edi
0040a49b  push     0x38
0040a49d  mov      esi, ecx
0040a49f  lea      ecx, [ebp - 0x38]
0040a4a2  push     0
0040a4a4  push     ecx
0040a4a5  mov      edi, 1
0040a4aa  mov      dword ptr [ebp - 0x40], eax
0040a4ad  mov      dword ptr [ebp - 0x3c], 4
0040a4b4  call     0x50c310
0040a4b9  mov      edx, dword ptr [ebp + 0xc]
0040a4bc  add      esp, 0xc
0040a4bf  push     0x14
0040a4c1  push     0xc
0040a4c3  lea      eax, [ebp - 0x40]
0040a4c6  push     eax
0040a4c7  push     0xd1
0040a4cc  mov      ecx, esi
0040a4ce  mov      dword ptr [ebp - 0x38], edx
0040a4d1  call     0x40a040
0040a4d6  test     eax, eax
0040a4d8  je       0x40a534
0040a4da  cmp      dword ptr [esi + 0xb0], 0
0040a4e1  jne      0x40a4f8
0040a4e3  push     0x5711e4
0040a4e8  lea      ecx, [ebp + 0xc]
0040a4eb  push     ecx
0040a4ec  mov      dword ptr [ebp + 0xc], 0x53a9a0
0040a4f3  call     0x50b72f
0040a4f8  mov      eax, dword ptr [esi + 0x90]
0040a4fe  dec      eax
0040a4ff  cmp      eax, 4
0040a502  ja       0x40a529
0040a504  jmp      dword ptr [eax*4 + 0x40a5a0]
0040a50b  push     0x7530
0040a510  lea      edx, [ebp + 8]
0040a513  push     edx
0040a514  push     0x41
0040a516  lea      eax, [esi + 4]
0040a519  push     eax
0040a51a  lea      ecx, [esi + 0x9c]
0040a520  call     0x413920
0040a525  test     eax, eax
0040a527  jne      0x40a578
0040a529  xor      ecx, ecx
0040a52b  xor      eax, eax
0040a52d  test     eax, eax
0040a52f  setne    cl
0040a532  mov      edi, ecx
0040a534  mov      eax, edi
0040a536  pop      edi
0040a537  pop      esi
0040a538  mov      esp, ebp
0040a53a  pop      ebp
0040a53b  ret      8
0040a53e  push     0x7530
0040a543  lea      ecx, [ebp + 8]
0040a546  push     ecx
0040a547  push     0xc
0040a549  lea      edx, [esi + 5]
0040a54c  push     edx
0040a54d  lea      ecx, [esi + 0xa8]
0040a553  call     0x415c90
0040a558  jmp      0x40a525
0040a55a  push     0x7530
0040a55f  lea      eax, [ebp + 8]
0040a562  push     eax
0040a563  push     0x41
0040a565  lea      ecx, [esi + 4]
0040a568  push     ecx
0040a569  lea      ecx, [esi + 0x9c]
0040a56f  call     0x413920
0040a574  test     eax, eax
0040a576  je       0x40a529
0040a578  cmp      dword ptr [ebp + 8], 0xc
0040a57c  jb       0x40a529
0040a57e  mov      edx, dword ptr [esi + 0x88]
0040a584  dec      edx
0040a585  cmp      dword ptr [esi + 9], edx
0040a588  jne      0x40a529
0040a58a  mov      eax, edi
0040a58c  xor      ecx, ecx
0040a58e  test     eax, eax
0040a590  setne    cl
0040a593  mov      edi, ecx
0040a595  mov      eax, edi
0040a597  pop      edi
0040a598  pop      esi
0040a599  mov      esp, ebp
0040a59b  pop      ebp
0040a59c  ret      8
0040a59f  nop      
0040a5a0  or       esp, dword ptr [ebp - 0x5ac1ffc0]
0040a5a6  inc      eax
0040a5a7  add      byte ptr [edx - 0x5b], bl
0040a5aa  inc      eax
0040a5ab  add      byte ptr [edx - 0x5b], bl
0040a5ae  inc      eax
0040a5af  add      byte ptr [edx - 0x5b], bl
0040a5b2  inc      eax
0040a5b3  add      ah, cl
0040a5b5  int3     
0040a5b6  int3     
0040a5b7  int3     
0040a5b8  int3     
0040a5b9  int3     
0040a5ba  int3     
0040a5bb  int3     
0040a5bc  int3     
0040a5bd  int3     
0040a5be  int3     
0040a5bf  int3     
0040a5c0  push     ebp
0040a5c1  mov      ebp, esp
0040a5c3  sub      esp, 0x40
0040a5c6  mov      eax, dword ptr [ebp + 8]
0040a5c9  push     esi
0040a5ca  push     edi
0040a5cb  push     0x38
0040a5cd  mov      esi, ecx
0040a5cf  lea      ecx, [ebp - 0x38]
0040a5d2  push     0
0040a5d4  push     ecx
0040a5d5  mov      edi, 1
0040a5da  mov      dword ptr [ebp - 0x40], eax
0040a5dd  mov      dword ptr [ebp - 0x3c], 8
0040a5e4  call     0x50c310
0040a5e9  mov      edx, dword ptr [ebp + 0xc]
0040a5ec  mov      eax, dword ptr [ebp + 0x10]
0040a5ef  add      esp, 0xc
0040a5f2  push     0x14
0040a5f4  push     0x10
0040a5f6  lea      ecx, [ebp - 0x40]
0040a5f9  push     ecx
0040a5fa  push     0xd1
0040a5ff  mov      ecx, esi
0040a601  mov      dword ptr [ebp - 0x38], edx
0040a604  mov      dword ptr [ebp - 0x34], eax
0040a607  call     0x40a040
0040a60c  test     eax, eax
0040a60e  je       0x40a66a
0040a610  cmp      dword ptr [esi + 0xb0], 0
0040a617  jne      0x40a62e
0040a619  push     0x5711e4
0040a61e  lea      edx, [ebp + 0xc]
0040a621  push     edx
0040a622  mov      dword ptr [ebp + 0xc], 0x53a9a0
0040a629  call     0x50b72f
0040a62e  mov      eax, dword ptr [esi + 0x90]
0040a634  dec      eax
0040a635  cmp      eax, 4
0040a638  ja       0x40a65f
0040a63a  jmp      dword ptr [eax*4 + 0x40a6d8]
0040a641  push     0x7530
0040a646  lea      eax, [ebp + 8]
0040a649  push     eax
0040a64a  push     0x41
0040a64c  lea      ecx, [esi + 4]
0040a64f  push     ecx
0040a650  lea      ecx, [esi + 0x9c]
0040a656  call     0x413920
0040a65b  test     eax, eax
0040a65d  jne      0x40a6ae
0040a65f  xor      ecx, ecx
0040a661  xor      eax, eax
0040a663  test     eax, eax
0040a665  setne    cl
0040a668  mov      edi, ecx
0040a66a  mov      eax, edi
0040a66c  pop      edi
0040a66d  pop      esi
0040a66e  mov      esp, ebp
0040a670  pop      ebp
0040a671  ret      0xc
0040a674  push     0x7530
0040a679  lea      edx, [ebp + 8]
0040a67c  push     edx
0040a67d  push     0xc
0040a67f  lea      eax, [esi + 5]
0040a682  push     eax
0040a683  lea      ecx, [esi + 0xa8]
0040a689  call     0x415c90
0040a68e  jmp      0x40a65b
0040a690  push     0x7530
0040a695  lea      ecx, [ebp + 8]
0040a698  push     ecx
0040a699  push     0x41
0040a69b  lea      edx, [esi + 4]
0040a69e  push     edx
0040a69f  lea      ecx, [esi + 0x9c]
0040a6a5  call     0x413920
0040a6aa  test     eax, eax
0040a6ac  je       0x40a65f
0040a6ae  cmp      dword ptr [ebp + 8], 0xc
0040a6b2  jb       0x40a65f
0040a6b4  mov      eax, dword ptr [esi + 0x88]
0040a6ba  dec      eax
0040a6bb  cmp      dword ptr [esi + 9], eax
0040a6be  jne      0x40a65f
0040a6c0  mov      eax, edi
0040a6c2  xor      ecx, ecx
0040a6c4  test     eax, eax
0040a6c6  setne    cl
0040a6c9  mov      edi, ecx
0040a6cb  mov      eax, edi
0040a6cd  pop      edi
0040a6ce  pop      esi
0040a6cf  mov      esp, ebp
0040a6d1  pop      ebp
0040a6d2  ret      0xc
0040a6d5  lea      ecx, [ecx]
0040a6d8  inc      ecx
0040a6d9  cmpsb    byte ptr [esi], byte ptr es:[edi]
0040a6da  inc      eax
0040a6db  add      byte ptr [esi + 0x40], dh
0040a6df  add      byte ptr [eax - 0x6fffbf5a], dl
0040a6e5  cmpsb    byte ptr [esi], byte ptr es:[edi]
0040a6e6  inc      eax
0040a6e7  add      byte ptr [eax - 0x33ffbf5a], dl
0040a6ed  int3     
0040a6ee  int3     
0040a6ef  int3     
0040a6f0  push     esi
0040a6f1  push     edi
0040a6f2  mov      esi, ecx
0040a6f4  push     0x34
0040a6f6  lea      edi, [esi + 0xd4]
0040a6fc  push     0
0040a6fe  push     edi
0040a6ff  call     0x50c310
0040a704  add      esp, 0xc
0040a707  push     0x14
0040a709  push     0
0040a70b  push     0
0040a70d  push     0xa0
0040a712  mov      ecx, esi
0040a714  call     0x40a040
0040a719  test     eax, eax
0040a71b  je       0x40a750
0040a71d  push     0
0040a71f  push     0x1388
0040a724  push     0x34
0040a726  push     edi
0040a727  mov      ecx, esi
0040a729  call     0x4098d0
0040a72e  test     eax, eax
0040a730  je       0x40a750
0040a732  cmp      dword ptr [esi + 0x104], 0x13572468
0040a73c  jne      0x40a750
0040a73e  pop      edi
0040a73f  mov      dword ptr [esi + 0x88], 3
0040a749  mov      eax, 1
0040a74e  pop      esi
0040a74f  ret      
0040a750  pop      edi
0040a751  xor      eax, eax
0040a753  pop      esi
0040a754  ret      
0040a755  int3     
0040a756  int3     
0040a757  int3     
0040a758  int3     
0040a759  int3     
0040a75a  int3     
0040a75b  int3     
0040a75c  int3     
0040a75d  int3     
0040a75e  int3     
0040a75f  int3     
0040a760  push     ebp
0040a761  mov      ebp, esp
0040a763  sub      esp, 0x14
0040a766  mov      eax, dword ptr [ebp + 8]
0040a769  mov      edx, dword ptr [ebp + 0x14]
0040a76c  push     esi
0040a76d  push     edi
0040a76e  mov      edi, dword ptr [ebp + 0x10]
0040a771  mov      esi, ecx
0040a773  mov      ecx, dword ptr [ebp + 0xc]
0040a776  push     0x14
0040a778  mov      dword ptr [ebp - 0x10], ecx
0040a77b  push     0x14
0040a77d  lea      ecx, [ebp - 0x14]
0040a780  push     ecx
0040a781  mov      dword ptr [ebp - 0x14], eax
0040a784  mov      eax, dword ptr [ebp + 0x18]
0040a787  push     0x5a
0040a789  mov      ecx, esi
0040a78b  mov      dword ptr [ebp - 0xc], edi
0040a78e  mov      dword ptr [ebp - 8], edx
0040a791  mov      dword ptr [ebp - 4], eax
0040a794  call     0x40a040
0040a799  test     eax, eax
0040a79b  je       0x40a7c5
0040a79d  push     0
0040a79f  push     0x1388
0040a7a4  push     4
0040a7a6  lea      edx, [ebp + 8]
0040a7a9  push     edx
0040a7aa  mov      ecx, esi
0040a7ac  call     0x4098d0
0040a7b1  test     eax, eax
0040a7b3  je       0x40a7c5
0040a7b5  xor      eax, eax
0040a7b7  cmp      dword ptr [ebp + 8], edi
0040a7ba  pop      edi
0040a7bb  sete     al
0040a7be  pop      esi
0040a7bf  mov      esp, ebp
0040a7c1  pop      ebp
0040a7c2  ret      0x14
0040a7c5  pop      edi
0040a7c6  xor      eax, eax
0040a7c8  pop      esi
0040a7c9  mov      esp, ebp
0040a7cb  pop      ebp
0040a7cc  ret      0x14
0040a7cf  int3     
0040a7d0  push     ebp
0040a7d1  mov      ebp, esp
0040a7d3  push     esi
0040a7d4  mov      esi, ecx
0040a7d6  call     0x40a6f0
0040a7db  test     eax, eax
0040a7dd  je       0x40a805
0040a7df  mov      ecx, dword ptr [esi + 0xe8]
0040a7e5  mov      eax, dword ptr [ebp + 8]
0040a7e8  mov      dword ptr [eax], ecx
0040a7ea  mov      edx, dword ptr [esi + 0xec]
0040a7f0  mov      dword ptr [eax + 4], edx
0040a7f3  mov      ecx, dword ptr [esi + 0xf0]
0040a7f9  mov      dword ptr [eax + 8], ecx
0040a7fc  mov      edx, dword ptr [esi + 0xf4]
0040a802  mov      dword ptr [eax + 0xc], edx
0040a805  pop      esi
0040a806  pop      ebp
0040a807  ret      4
0040a80a  int3     
0040a80b  int3     
0040a80c  int3     
0040a80d  int3     
0040a80e  int3     
0040a80f  int3     
0040a810  push     ebp
0040a811  mov      ebp, esp
0040a813  sub      esp, 0xc
0040a816  push     ebx
0040a817  push     esi
0040a818  mov      esi, 1
0040a81d  push     edi
0040a81e  mov      ebx, ecx
0040a820  mov      dword ptr [ebp - 4], esi
0040a823  call     0x40a6f0
0040a828  xor      edi, edi
0040a82a  cmp      dword ptr [ebp + 0xc], edi
0040a82d  jle      0x40a894
0040a82f  nop      
0040a830  xor      eax, eax
0040a832  cmp      edi, 0x10
0040a835  jl       0x40a83c
0040a837  mov      eax, 0x10
0040a83c  lea      esi, [eax + edi]
0040a83f  push     0x14
0040a841  push     8
0040a843  add      esi, esi
0040a845  lea      ecx, [ebp - 0xc]
0040a848  push     ecx
0040a849  add      esi, esi
0040a84b  lea      eax, [esi + 0xf300000]
0040a851  push     0xd2
0040a856  mov      ecx, ebx
0040a858  mov      dword ptr [ebp - 0xc], eax
0040a85b  mov      dword ptr [ebp - 8], 4
0040a862  call     0x40a040
0040a867  test     eax, eax
0040a869  je       0x40a882
0040a86b  add      esi, dword ptr [ebp + 8]
0040a86e  push     0
0040a870  push     0x7530
0040a875  push     4
0040a877  push     esi
0040a878  mov      ecx, ebx
0040a87a  call     0x4098d0
0040a87f  and      dword ptr [ebp - 4], eax
0040a882  inc      edi
0040a883  cmp      edi, dword ptr [ebp + 0xc]
0040a886  jl       0x40a830
0040a888  mov      eax, dword ptr [ebp - 4]
0040a88b  pop      edi
0040a88c  pop      esi
0040a88d  pop      ebx
0040a88e  mov      esp, ebp
0040a890  pop      ebp
0040a891  ret      8
0040a894  pop      edi
0040a895  mov      eax, esi
0040a897  pop      esi
0040a898  pop      ebx
0040a899  mov      esp, ebp
0040a89b  pop      ebp
0040a89c  ret      8
0040a89f  int3     
0040a8a0  push     ebp
0040a8a1  mov      ebp, esp
0040a8a3  sub      esp, 0xc
0040a8a6  push     ebx
0040a8a7  push     edi
0040a8a8  xor      edi, edi
0040a8aa  mov      eax, 1
0040a8af  mov      ebx, ecx
0040a8b1  mov      dword ptr [ebp - 4], eax
0040a8b4  cmp      dword ptr [ebp + 0xc], edi
0040a8b7  jle      0x40a91e
0040a8b9  push     esi
0040a8ba  lea      ebx, [ebx]
0040a8c0  xor      eax, eax
0040a8c2  cmp      edi, 0x10
0040a8c5  jl       0x40a8cc
0040a8c7  mov      eax, 0x10
0040a8cc  lea      esi, [eax + edi]
0040a8cf  push     0x14
0040a8d1  push     8
0040a8d3  add      esi, esi
0040a8d5  lea      ecx, [ebp - 0xc]
0040a8d8  push     ecx
0040a8d9  add      esi, esi
0040a8db  lea      eax, [esi + 0xf300000]
0040a8e1  push     0xd2
0040a8e6  mov      ecx, ebx
0040a8e8  mov      dword ptr [ebp - 0xc], eax
0040a8eb  mov      dword ptr [ebp - 8], 8
0040a8f2  call     0x40a040
0040a8f7  test     eax, eax
0040a8f9  je       0x40a912
0040a8fb  add      esi, dword ptr [ebp + 8]
0040a8fe  push     0
0040a900  push     0x7530
0040a905  push     8
0040a907  push     esi
0040a908  mov      ecx, ebx
0040a90a  call     0x4098d0
0040a90f  and      dword ptr [ebp - 4], eax
0040a912  add      edi, 2
0040a915  cmp      edi, dword ptr [ebp + 0xc]
0040a918  jl       0x40a8c0
0040a91a  mov      eax, dword ptr [ebp - 4]
0040a91d  pop      esi
0040a91e  pop      edi
0040a91f  pop      ebx
0040a920  mov      esp, ebp
0040a922  pop      ebp
0040a923  ret      8
0040a926  int3     
0040a927  int3     
0040a928  int3     
0040a929  int3     
0040a92a  int3     
0040a92b  int3     
0040a92c  int3     
0040a92d  int3     
0040a92e  int3     
0040a92f  int3     
0040a930  push     ebp
0040a931  mov      ebp, esp
0040a933  sub      esp, 0x58
0040a936  mov      eax, dword ptr [0x588250]
0040a93b  xor      eax, ebp
0040a93d  mov      dword ptr [ebp - 4], eax
0040a940  mov      eax, dword ptr [ebp + 0xc]
0040a943  push     ebx
0040a944  push     esi
0040a945  mov      ebx, ecx
0040a947  mov      ecx, dword ptr [ebp + 0x10]
0040a94a  push     edi
0040a94b  mov      dword ptr [ebp - 0x50], eax
0040a94e  mov      dword ptr [ebp - 0x54], ecx
0040a951  xor      edi, edi
0040a953  mov      dword ptr [ebp - 0x48], 1
0040a95a  lea      ebx, [ebx]
0040a960  mov      esi, 0x38
0040a965  sub      esi, edi
0040a967  cmp      esi, 0x20
0040a96a  jb       0x40a971
0040a96c  mov      esi, 0x20
0040a971  mov      edx, dword ptr [ebp + 8]
0040a974  push     0x38
0040a976  lea      ecx, [ebp - 0x3c]
0040a979  lea      eax, [edi + edx]
0040a97c  push     0
0040a97e  push     ecx
0040a97f  mov      dword ptr [ebp - 0x44], eax
0040a982  mov      dword ptr [ebp - 0x40], esi
0040a985  call     0x50c310
0040a98a  mov      edx, dword ptr [ebp - 0x50]
0040a98d  push     esi
0040a98e  lea      eax, [edi + edx]
0040a991  push     eax
0040a992  lea      ecx, [ebp - 0x3c]
0040a995  push     ecx
0040a996  call     0x50ad10
0040a99b  add      esp, 0x18
0040a99e  push     0x14
0040a9a0  lea      edx, [esi + 0x10]
0040a9a3  push     edx
0040a9a4  lea      eax, [ebp - 0x44]
0040a9a7  push     eax
0040a9a8  push     0xd1
0040a9ad  mov      ecx, ebx
0040a9af  call     0x40a040
0040a9b4  test     eax, eax
0040a9b6  je       0x40aa02
0040a9b8  cmp      dword ptr [ebx + 0xb0], 0
0040a9bf  je       0x40aa8d
0040a9c5  mov      eax, dword ptr [ebx + 0x90]
0040a9cb  dec      eax
0040a9cc  cmp      eax, 4
0040a9cf  ja       0x40a9f6
0040a9d1  jmp      dword ptr [eax*4 + 0x40aaa4]
0040a9d8  push     0x7530
0040a9dd  lea      ecx, [ebp - 0x4c]
0040a9e0  push     ecx
0040a9e1  push     0x41
0040a9e3  lea      edx, [ebx + 4]
0040a9e6  push     edx
0040a9e7  lea      ecx, [ebx + 0x9c]
0040a9ed  call     0x413920
0040a9f2  test     eax, eax
0040a9f4  jne      0x40aa6d
0040a9f6  xor      eax, eax
0040a9f8  neg      eax
0040a9fa  sbb      eax, eax
0040a9fc  and      eax, dword ptr [ebp - 0x48]
0040a9ff  mov      dword ptr [ebp - 0x48], eax
0040aa02  add      edi, esi
0040aa04  cmp      edi, 0x38
0040aa07  jne      0x40a960
0040aa0d  cmp      dword ptr [ebp - 0x48], 0
0040aa11  je       0x40aa20
0040aa13  mov      esi, dword ptr [ebp - 0x50]
0040aa16  mov      edi, dword ptr [ebp - 0x54]
0040aa19  mov      ecx, 0xe
0040aa1e  rep movsd dword ptr es:[edi], dword ptr [esi]
0040aa20  mov      ecx, dword ptr [ebp - 4]
0040aa23  pop      edi
0040aa24  pop      esi
0040aa25  xor      ecx, ebp
0040aa27  pop      ebx
0040aa28  call     0x50bc27
0040aa2d  mov      esp, ebp
0040aa2f  pop      ebp
0040aa30  ret      0xc
0040aa33  push     0x7530
0040aa38  lea      eax, [ebp - 0x4c]
0040aa3b  push     eax
0040aa3c  push     0xc
0040aa3e  lea      ecx, [ebx + 5]
0040aa41  push     ecx
0040aa42  lea      ecx, [ebx + 0xa8]
0040aa48  call     0x415c90
0040aa4d  jmp      0x40a9f2
0040aa4f  push     0x7530
0040aa54  lea      edx, [ebp - 0x4c]
0040aa57  push     edx
0040aa58  push     0x41
0040aa5a  lea      eax, [ebx + 4]
0040aa5d  push     eax
0040aa5e  lea      ecx, [ebx + 0x9c]
0040aa64  call     0x413920
0040aa69  test     eax, eax
0040aa6b  je       0x40a9f6
0040aa6d  cmp      dword ptr [ebp - 0x4c], 0xc
0040aa71  jb       0x40a9f6
0040aa73  mov      ecx, dword ptr [ebx + 0x88]
0040aa79  dec      ecx
0040aa7a  cmp      dword ptr [ebx + 9], ecx
0040aa7d  jne      0x40a9f6
0040aa83  mov      eax, 1
0040aa88  jmp      0x40a9f8
0040aa8d  push     0x5711e4
0040aa92  lea      edx, [ebp - 0x58]
0040aa95  push     edx
0040aa96  mov      dword ptr [ebp - 0x58], 0x53a9a0
0040aa9d  call     0x50b72f
0040aaa2  mov      edi, edi
0040aaa4  fsubr    dword ptr [ecx - 0x55ccffc0]
0040aaaa  inc      eax
0040aaab  add      byte ptr [edi - 0x56], cl
0040aaae  inc      eax
0040aaaf  add      byte ptr [edi - 0x56], cl
0040aab2  inc      eax
0040aab3  add      byte ptr [edi - 0x56], cl
0040aab6  inc      eax
0040aab7  add      ah, cl
0040aab9  int3     
0040aaba  int3     
0040aabb  int3     
0040aabc  int3     
0040aabd  int3     
0040aabe  int3     
0040aabf  int3     
0040aac0  push     ebp
0040aac1  mov      ebp, esp
0040aac3  sub      esp, 0x44
0040aac6  mov      eax, dword ptr [0x588250]
0040aacb  xor      eax, ebp
0040aacd  mov      dword ptr [ebp - 4], eax
0040aad0  mov      eax, dword ptr [ebp + 8]
0040aad3  mov      edx, dword ptr [ebp + 0x14]
0040aad6  push     ebx
0040aad7  mov      ebx, dword ptr [ebp + 0x18]
0040aada  push     esi
0040aadb  push     edi
0040aadc  mov      esi, ecx
0040aade  mov      ecx, dword ptr [ebp + 0x10]
0040aae1  mov      edi, eax
0040aae3  sub      edi, ecx
0040aae5  add      edi, dword ptr [ebp + 0xc]
0040aae8  cmp      eax, ecx
0040aaea  jne      0x40abfa
0040aaf0  cmp      edi, 0x30
0040aaf3  jbe      0x40aafa
0040aaf5  mov      edi, 0x30
0040aafa  push     edi
0040aafb  mov      dword ptr [ebp - 0x3c], eax
0040aafe  mov      eax, dword ptr [ebp + 0xc]
0040ab01  push     edx
0040ab02  lea      ecx, [ebp - 0x34]
0040ab05  push     ecx
0040ab06  mov      dword ptr [ebp - 0x38], eax
0040ab09  call     0x50ad10
0040ab0e  add      esp, 0xc
0040ab11  push     0x7530
0040ab16  lea      edx, [edi + 8]
0040ab19  push     edx
0040ab1a  lea      eax, [ebp - 0x3c]
0040ab1d  push     eax
0040ab1e  push     0xd1
0040ab23  mov      ecx, esi
0040ab25  call     0x40a040
0040ab2a  test     eax, eax
0040ab2c  jne      0x40ab43
0040ab2e  pop      edi
0040ab2f  pop      esi
0040ab30  xor      eax, eax
0040ab32  pop      ebx
0040ab33  mov      ecx, dword ptr [ebp - 4]
0040ab36  xor      ecx, ebp
0040ab38  call     0x50bc27
0040ab3d  mov      esp, ebp
0040ab3f  pop      ebp
0040ab40  ret      0x14
0040ab43  cmp      dword ptr [esi + 0xb0], 0
0040ab4a  jne      0x40ab61
0040ab4c  push     0x5711e4
0040ab51  lea      ecx, [ebp - 0x44]
0040ab54  push     ecx
0040ab55  mov      dword ptr [ebp - 0x44], 0x53a9a0
0040ab5c  call     0x50b72f
0040ab61  mov      eax, dword ptr [esi + 0x90]
0040ab67  dec      eax
0040ab68  cmp      eax, 4
0040ab6b  ja       0x40ab2e
0040ab6d  jmp      dword ptr [eax*4 + 0x40acec]
0040ab74  push     0x7530
0040ab79  lea      edx, [ebp - 0x40]
0040ab7c  push     edx
0040ab7d  push     0x41
0040ab7f  lea      eax, [esi + 4]
0040ab82  push     eax
0040ab83  jmp      0x40abb0
0040ab85  push     0x7530
0040ab8a  lea      ecx, [ebp - 0x40]
0040ab8d  push     ecx
0040ab8e  push     0xc
0040ab90  lea      edx, [esi + 5]
0040ab93  push     edx
0040ab94  lea      ecx, [esi + 0xa8]
0040ab9a  call     0x415c90
0040ab9f  jmp      0x40abbb
0040aba1  push     0x7530
0040aba6  lea      eax, [ebp - 0x40]
0040aba9  push     eax
0040abaa  push     0x41
0040abac  lea      ecx, [esi + 4]
0040abaf  push     ecx
0040abb0  lea      ecx, [esi + 0x9c]
0040abb6  call     0x413920
0040abbb  test     eax, eax
0040abbd  je       0x40ab2e
0040abc3  cmp      dword ptr [ebp - 0x40], 0xc
0040abc7  jb       0x40ab2e
0040abcd  mov      edx, dword ptr [esi + 0x88]
0040abd3  dec      edx
0040abd4  cmp      dword ptr [esi + 9], edx
0040abd7  jne      0x40ab2e
0040abdd  cmp      dword ptr [esi + 0x90], 3
0040abe4  jne      0x40accb
0040abea  push     0xc8
0040abef  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
0040abf5  jmp      0x40accb
0040abfa  cmp      edi, 0x38
0040abfd  jbe      0x40ac04
0040abff  mov      edi, 0x38
0040ac04  push     edi
0040ac05  push     edx
0040ac06  lea      eax, [ebp - 0x3c]
0040ac09  push     eax
0040ac0a  call     0x50ad10
0040ac0f  add      esp, 0xc
0040ac12  push     0x7530
0040ac17  push     edi
0040ac18  lea      ecx, [ebp - 0x3c]
0040ac1b  push     ecx
0040ac1c  push     0
0040ac1e  mov      ecx, esi
0040ac20  call     0x40a040
0040ac25  test     eax, eax
0040ac27  je       0x40ab2e
0040ac2d  cmp      dword ptr [esi + 0xb0], 0
0040ac34  jne      0x40ac4b
0040ac36  push     0x5711e4
0040ac3b  lea      edx, [ebp - 0x44]
0040ac3e  push     edx
0040ac3f  mov      dword ptr [ebp - 0x44], 0x53a9a0
0040ac46  call     0x50b72f
0040ac4b  mov      eax, dword ptr [esi + 0x90]
0040ac51  dec      eax
0040ac52  cmp      eax, 4
0040ac55  ja       0x40ab2e
0040ac5b  jmp      dword ptr [eax*4 + 0x40ad00]
0040ac62  push     0x7530
0040ac67  lea      eax, [ebp - 0x40]
0040ac6a  push     eax
0040ac6b  push     0x41
0040ac6d  lea      ecx, [esi + 4]
0040ac70  push     ecx
0040ac71  jmp      0x40ac9e
0040ac73  push     0x7530
0040ac78  lea      edx, [ebp - 0x40]
0040ac7b  push     edx
0040ac7c  push     0xc
0040ac7e  lea      eax, [esi + 5]
0040ac81  push     eax
0040ac82  lea      ecx, [esi + 0xa8]
0040ac88  call     0x415c90
0040ac8d  jmp      0x40aca9
0040ac8f  push     0x7530
0040ac94  lea      ecx, [ebp - 0x40]
0040ac97  push     ecx
0040ac98  push     0x41
0040ac9a  lea      edx, [esi + 4]
0040ac9d  push     edx
0040ac9e  lea      ecx, [esi + 0x9c]
0040aca4  call     0x413920
0040aca9  test     eax, eax
0040acab  je       0x40ab2e
0040acb1  cmp      dword ptr [ebp - 0x40], 0xc
0040acb5  jb       0x40ab2e
0040acbb  mov      eax, dword ptr [esi + 0x88]
0040acc1  dec      eax
0040acc2  cmp      dword ptr [esi + 9], eax
0040acc5  jne      0x40ab2e
0040accb  test     ebx, ebx
0040accd  je       0x40acd1
0040accf  mov      dword ptr [ebx], edi
0040acd1  mov      ecx, dword ptr [ebp - 4]
0040acd4  pop      edi
0040acd5  pop      esi
0040acd6  xor      ecx, ebp
0040acd8  mov      eax, 1
0040acdd  pop      ebx
0040acde  call     0x50bc27
0040ace3  mov      esp, ebp
0040ace5  pop      ebp
0040ace6  ret      0x14
0040ace9  lea      ecx, [ecx]
0040acec  je       0x40ac99
0040acee  inc      eax
0040acef  add      byte ptr [ebp - 0x5effbf55], al
0040acf5  stosd    dword ptr es:[edi], eax
0040acf6  inc      eax
0040acf7  add      byte ptr [ecx - 0x5effbf55], ah
0040acfd  stosd    dword ptr es:[edi], eax
0040acfe  inc      eax
0040acff  add      byte ptr [edx - 0x54], ah
0040ad02  inc      eax
0040ad03  add      byte ptr [ebx - 0x54], dh
0040ad06  inc      eax
0040ad07  add      byte ptr [edi - 0x70ffbf54], cl
0040ad0d  lodsb    al, byte ptr [esi]
0040ad0e  inc      eax
0040ad0f  add      byte ptr [edi - 0x33ffbf54], cl
0040ad15  int3     
0040ad16  int3     
0040ad17  int3     
0040ad18  int3     
0040ad19  int3     
0040ad1a  int3     
0040ad1b  int3     
0040ad1c  int3     
0040ad1d  int3     
0040ad1e  int3     
0040ad1f  int3     
0040ad20  cmp      dword ptr [ecx + 0xcc], 1
0040ad27  jne      0x40ad2e
0040ad29  jmp      0x40a3b0
0040ad2e  xor      eax, eax
0040ad30  ret      
0040ad31  int3     
0040ad32  int3     
0040ad33  int3     
0040ad34  int3     
0040ad35  int3     
0040ad36  int3     
0040ad37  int3     
0040ad38  int3     
0040ad39  int3     
0040ad3a  int3     
0040ad3b  int3     
0040ad3c  int3     
0040ad3d  int3     
0040ad3e  int3     
0040ad3f  int3     
0040ad40  push     ebp
0040ad41  mov      ebp, esp
0040ad43  push     esi
0040ad44  mov      esi, ecx
0040ad46  mov      eax, dword ptr [esi + 0xcc]
0040ad4c  cmp      eax, 1
0040ad4f  je       0x40ad5d
0040ad51  cmp      eax, 2
0040ad54  je       0x40ad5d
0040ad56  xor      eax, eax
0040ad58  pop      esi
0040ad59  pop      ebp
0040ad5a  ret      8
0040ad5d  cmp      dword ptr [esi + 0x90], 3
0040ad64  push     edi
0040ad65  mov      edi, dword ptr [ebp + 8]
0040ad68  jne      0x40adb2
0040ad6a  test     edi, edi
0040ad6c  je       0x40ad93
0040ad6e  push     1
0040ad70  push     0xfa0
0040ad75  push     0x50505050
0040ad7a  push     0xa0a0a0a
0040ad7f  push     0xf4240
0040ad84  call     0x40a760
0040ad89  test     eax, eax
0040ad8b  jne      0x40adb2
0040ad8d  pop      edi
0040ad8e  pop      esi
0040ad8f  pop      ebp
0040ad90  ret      8
0040ad93  push     0
0040ad95  push     0x2ee0
0040ad9a  push     0x50505050
0040ad9f  push     0xa0a0a0a
0040ada4  push     0xf4240
0040ada9  call     0x40a760
0040adae  test     eax, eax
0040adb0  je       0x40ade0
0040adb2  cmp      dword ptr [esi + 0x90], 4
0040adb9  jne      0x40ae07
0040adbb  mov      ecx, esi
0040adbd  test     edi, edi
0040adbf  .byte    0x74
