00405020  add      byte ptr [eax], al
00405022  lea      edi, [esi + 0x734]
00405028  mov      ebx, 2
0040502d  lea      ecx, [ecx]
00405030  mov      ecx, dword ptr [edi]
00405032  test     ecx, ecx
00405034  je       0x40503d
00405036  mov      eax, dword ptr [ecx]
00405038  mov      edx, dword ptr [eax + 0x60]
0040503b  call     edx
0040503d  mov      ecx, dword ptr [edi]
0040503f  test     ecx, ecx
00405041  je       0x40504c
00405043  mov      eax, dword ptr [ecx]
00405045  mov      edx, dword ptr [eax + 4]
00405048  push     1
0040504a  call     edx
0040504c  mov      dword ptr [edi], 0
00405052  add      edi, 4
00405055  dec      ebx
00405056  jne      0x405030
00405058  mov      eax, dword ptr [esi + 0x758]
0040505e  test     eax, eax
00405060  je       0x40506f
00405062  push     eax
00405063  call     dword ptr [0x5388bc] ; USER32.dll!UnregisterDeviceNotification
00405069  mov      dword ptr [esi + 0x758], ebx
0040506f  lea      ecx, [esi + 0x6c0]
00405075  mov      byte ptr [ebp - 4], 0xa
00405079  call     0x423c59
0040507e  lea      ecx, [esi + 0x64c]
00405084  mov      byte ptr [ebp - 4], 9
00405088  call     0x423d59
0040508d  mov      eax, dword ptr [esi + 0x648]
00405093  sub      eax, 0x10
00405096  mov      byte ptr [ebp - 4], 8
0040509a  lea      ecx, [eax + 0xc]
0040509d  or       edx, 0xffffffff
004050a0  lock xadd dword ptr [ecx], edx
004050a4  dec      edx
004050a5  test     edx, edx
004050a7  jg       0x4050b3
004050a9  mov      ecx, dword ptr [eax]
004050ab  mov      edx, dword ptr [ecx]
004050ad  push     eax
004050ae  mov      eax, dword ptr [edx + 4]
004050b1  call     eax
004050b3  mov      eax, dword ptr [esi + 0x644]
004050b9  sub      eax, 0x10
004050bc  mov      byte ptr [ebp - 4], 7
004050c0  lea      ecx, [eax + 0xc]
004050c3  or       edx, 0xffffffff
004050c6  lock xadd dword ptr [ecx], edx
004050ca  dec      edx
004050cb  test     edx, edx
004050cd  jg       0x4050d9
004050cf  mov      ecx, dword ptr [eax]
004050d1  mov      edx, dword ptr [ecx]
004050d3  push     eax
004050d4  mov      eax, dword ptr [edx + 4]
004050d7  call     eax
004050d9  mov      eax, dword ptr [esi + 0x640]
004050df  sub      eax, 0x10
004050e2  mov      byte ptr [ebp - 4], 6
004050e6  lea      ecx, [eax + 0xc]
004050e9  or       edx, 0xffffffff
004050ec  lock xadd dword ptr [ecx], edx
004050f0  dec      edx
004050f1  test     edx, edx
004050f3  jg       0x4050ff
004050f5  mov      ecx, dword ptr [eax]
004050f7  mov      edx, dword ptr [ecx]
004050f9  push     eax
004050fa  mov      eax, dword ptr [edx + 4]
004050fd  call     eax
004050ff  lea      ecx, [esi + 0x5cc]
00405105  mov      byte ptr [ebp - 4], 5
00405109  call     0x4236c5
0040510e  lea      ecx, [esi + 0x558]
00405114  mov      byte ptr [ebp - 4], 4
00405118  call     0x4236c5
0040511d  lea      ecx, [esi + 0x4e4]
00405123  mov      byte ptr [ebp - 4], 3
00405127  call     0x4236c5
0040512c  lea      ecx, [esi + 0x470]
00405132  mov      byte ptr [ebp - 4], 2
00405136  call     0x423587
0040513b  lea      ecx, [esi + 0x3fc]
00405141  mov      byte ptr [ebp - 4], 1
00405145  call     0x423587
0040514a  lea      ecx, [esi + 0x1a8]
00405150  mov      byte ptr [ebp - 4], 0
00405154  call     0x408490
00405159  mov      ecx, esi
0040515b  mov      dword ptr [ebp - 4], 0xffffffff
00405162  call     0x4152f0
00405167  mov      ecx, dword ptr [ebp - 0xc]
0040516a  mov      dword ptr fs:[0], ecx
00405171  pop      ecx
00405172  pop      edi
00405173  pop      esi
00405174  pop      ebx
00405175  mov      esp, ebp
00405177  pop      ebp
00405178  ret      
00405179  int3     
0040517a  int3     
0040517b  int3     
0040517c  int3     
0040517d  int3     
0040517e  int3     
0040517f  int3     
00405180  sub      ecx, 0x1a8
00405186  jmp      0x405420
0040518b  int3     
0040518c  int3     
0040518d  int3     
0040518e  int3     
0040518f  int3     
00405190  push     ebp
00405191  mov      ebp, esp
00405193  push     -1
00405195  push     0x5297e8
0040519a  mov      eax, dword ptr fs:[0]
004051a0  push     eax
004051a1  push     ecx
004051a2  push     esi
004051a3  mov      eax, dword ptr [0x588250]
004051a8  xor      eax, ebp
004051aa  push     eax
004051ab  lea      eax, [ebp - 0xc]
004051ae  mov      dword ptr fs:[0], eax
004051b4  mov      esi, ecx
004051b6  mov      eax, dword ptr [0x589a90]
004051bb  mov      dword ptr [esi + 0x29c], eax
004051c1  call     0x418e64
004051c6  xor      ecx, ecx
004051c8  test     eax, eax
004051ca  setne    cl
004051cd  test     ecx, ecx
004051cf  jne      0x4051db
004051d1  push     0x80004005
004051d6  call     0x401080
004051db  mov      edx, dword ptr [eax]
004051dd  mov      ecx, eax
004051df  mov      eax, dword ptr [edx + 0xc]
004051e2  call     eax
004051e4  add      eax, 0x10
004051e7  mov      dword ptr [ebp - 0x10], eax
004051ea  lea      ecx, [ebp - 0x10]
004051ed  push     ecx
004051ee  push     0xc16
004051f3  mov      ecx, esi
004051f5  mov      dword ptr [ebp - 4], 0
004051fc  call     0x41ffb2
00405201  mov      edx, dword ptr [ebp - 0x10]
00405204  push     0x10
00405206  push     0
00405208  push     edx
00405209  call     0x50c1c5
0040520e  mov      eax, dword ptr [ebp - 0x10]
00405211  add      eax, -0x10
00405214  add      esp, 0xc
00405217  mov      dword ptr [ebp - 4], 0xffffffff
0040521e  lea      ecx, [eax + 0xc]
00405221  or       edx, 0xffffffff
00405224  lock xadd dword ptr [ecx], edx
00405228  dec      edx
00405229  test     edx, edx
0040522b  jg       0x405237
0040522d  mov      ecx, dword ptr [eax]
0040522f  mov      edx, dword ptr [ecx]
00405231  push     eax
00405232  mov      eax, dword ptr [edx + 4]
00405235  call     eax
00405237  mov      ecx, dword ptr [ebp - 0xc]
0040523a  mov      dword ptr fs:[0], ecx
00405241  pop      ecx
00405242  pop      esi
00405243  mov      esp, ebp
00405245  pop      ebp
00405246  ret      
00405247  int3     
00405248  int3     
00405249  int3     
0040524a  int3     
0040524b  int3     
0040524c  int3     
0040524d  int3     
0040524e  int3     
0040524f  int3     
00405250  push     ebp
00405251  mov      ebp, esp
00405253  push     ebx
00405254  mov      ebx, dword ptr [ebp + 8]
00405257  push     esi
00405258  push     edi
00405259  mov      edi, ecx
0040525b  test     ebx, ebx
0040525d  je       0x4052c8
0040525f  push     0
00405261  push     0
00405263  push     -1
00405265  push     ebx
00405266  push     0
00405268  push     3
0040526a  call     dword ptr [0x538490] ; KERNEL32.dll!MultiByteToWideChar
00405270  lea      esi, [eax - 1]
00405273  test     esi, esi
00405275  jle      0x4052c8
00405277  mov      eax, dword ptr [edi]
00405279  mov      edx, dword ptr [eax - 8]
0040527c  mov      ecx, 1
00405281  sub      ecx, dword ptr [eax - 4]
00405284  sub      edx, esi
00405286  or       ecx, edx
00405288  jge      0x405292
0040528a  push     esi
0040528b  mov      ecx, edi
0040528d  call     0x402470
00405292  mov      eax, dword ptr [edi]
00405294  push     esi
00405295  push     eax
00405296  push     -1
00405298  push     ebx
00405299  push     0
0040529b  push     3
0040529d  call     dword ptr [0x538490] ; KERNEL32.dll!MultiByteToWideChar
004052a3  mov      eax, dword ptr [edi]
004052a5  cmp      esi, dword ptr [eax - 8]
004052a8  jg       0x4052be
004052aa  mov      dword ptr [eax - 0xc], esi
004052ad  mov      ecx, dword ptr [edi]
004052af  xor      edx, edx
004052b1  mov      eax, edi
004052b3  pop      edi
004052b4  mov      word ptr [ecx + esi*2], dx
004052b8  pop      esi
004052b9  pop      ebx
004052ba  pop      ebp
004052bb  ret      4
004052be  push     0x80070057
004052c3  call     0x401080
004052c8  mov      ecx, edi
004052ca  call     0x402400
004052cf  mov      eax, edi
004052d1  pop      edi
004052d2  pop      esi
004052d3  pop      ebx
004052d4  pop      ebp
004052d5  ret      4
004052d8  int3     
004052d9  int3     
004052da  int3     
004052db  int3     
004052dc  int3     
004052dd  int3     
004052de  int3     
004052df  int3     
004052e0  push     ebp
004052e1  mov      ebp, esp
004052e3  push     ebx
004052e4  push     esi
004052e5  mov      esi, dword ptr [ebp + 0xc]
004052e8  mov      eax, esi
004052ea  shr      eax, 4
004052ed  push     edi
004052ee  mov      edi, dword ptr [ebp + 8]
004052f1  inc      eax
004052f2  mov      ebx, ecx
004052f4  movzx    ecx, ax
004052f7  push     6
004052f9  push     ecx
004052fa  push     edi
004052fb  call     dword ptr [0x538494] ; KERNEL32.dll!FindResourceW
00405301  test     eax, eax
00405303  je       0x405316
00405305  push     esi
00405306  push     eax
00405307  push     edi
00405308  call     0x404260
0040530d  mov      esi, eax
0040530f  add      esp, 0xc
00405312  test     esi, esi
00405314  jne      0x40531f
00405316  pop      edi
00405317  pop      esi
00405318  xor      eax, eax
0040531a  pop      ebx
0040531b  pop      ebp
0040531c  ret      8
0040531f  movzx    edi, word ptr [esi]
00405322  test     edi, edi
00405324  jns      0x405330
00405326  push     0x80070057
0040532b  call     0x401080
00405330  mov      eax, dword ptr [ebx]
00405332  mov      edx, 1
00405337  sub      edx, dword ptr [eax - 4]
0040533a  mov      eax, dword ptr [eax - 8]
0040533d  sub      eax, edi
0040533f  or       edx, eax
00405341  jge      0x40534b
00405343  push     edi
00405344  mov      ecx, ebx
00405346  call     0x402470
0040534b  movzx    eax, word ptr [esi]
0040534e  add      esi, 2
00405351  cmp      eax, -1
00405354  jne      0x405370
00405356  mov      eax, esi
00405358  lea      edx, [eax + 2]
0040535b  jmp      0x405360
0040535d  lea      ecx, [ecx]
00405360  mov      cx, word ptr [eax]
00405363  add      eax, 2
00405366  test     cx, cx
00405369  jne      0x405360
0040536b  sub      eax, edx
0040536d  sar      eax, 1
0040536f  inc      eax
00405370  push     eax
00405371  mov      eax, dword ptr [ebx]
00405373  push     esi
00405374  push     edi
00405375  push     eax
00405376  call     0x50bd5c
0040537b  add      esp, 0x10
0040537e  cmp      eax, 0x50
00405381  ja       0x405396
00405383  movzx    ecx, byte ptr [eax + 0x4053cc]
0040538a  jmp      dword ptr [ecx*4 + 0x4053bc]
00405391  call     0x4181e2
00405396  call     0x41821a
0040539b  mov      eax, dword ptr [ebx]
0040539d  cmp      edi, dword ptr [eax - 8]
004053a0  jg       0x405326
004053a2  mov      dword ptr [eax - 0xc], edi
004053a5  mov      edx, dword ptr [ebx]
004053a7  xor      eax, eax
004053a9  mov      word ptr [edx + edi*2], ax
004053ad  pop      edi
004053ae  pop      esi
004053af  mov      eax, 1
004053b4  pop      ebx
004053b5  pop      ebp
004053b6  ret      8
004053b9  lea      ecx, [ecx]
004053bc  wait     
004053bd  push     ebx
004053be  inc      eax
004053bf  add      byte ptr [ecx - 0x69ffbfad], dl
004053c5  push     ebx
004053c6  inc      eax
004053c7  add      byte ptr [esi + 0x4053], dl
004053cd  add      eax, dword ptr [ebx]
004053cf  add      eax, dword ptr [ebx]
004053d1  add      eax, dword ptr [ebx]
004053d3  add      eax, dword ptr [ebx]
004053d5  add      eax, dword ptr [ebx]
004053d7  add      eax, dword ptr [ecx]
004053d9  add      eax, dword ptr [ebx]
004053db  add      eax, dword ptr [ebx]
004053dd  add      eax, dword ptr [ebx]
004053df  add      eax, dword ptr [ebx]
004053e1  add      eax, dword ptr [edx]
004053e3  add      eax, dword ptr [ebx]
004053e5  add      eax, dword ptr [ebx]
004053e7  add      eax, dword ptr [ebx]
004053e9  add      eax, dword ptr [ebx]
004053eb  add      eax, dword ptr [ebx]
004053ed  add      eax, dword ptr [edx]
004053ef  add      eax, dword ptr [ebx]
004053f1  add      eax, dword ptr [ebx]
004053f3  add      eax, dword ptr [ebx]
004053f5  add      eax, dword ptr [ebx]
004053f7  add      eax, dword ptr [ebx]
004053f9  add      eax, dword ptr [ebx]
004053fb  add      eax, dword ptr [ebx]
004053fd  add      eax, dword ptr [ebx]
004053ff  add      eax, dword ptr [ebx]
00405401  add      eax, dword ptr [ebx]
00405403  add      eax, dword ptr [ebx]
00405405  add      eax, dword ptr [ebx]
00405407  add      eax, dword ptr [ebx]
00405409  add      eax, dword ptr [ebx]
0040540b  add      eax, dword ptr [ebx]
0040540d  add      eax, dword ptr [ebx]
0040540f  add      eax, dword ptr [ebx]
00405411  add      eax, dword ptr [ebx]
00405413  add      eax, dword ptr [ebx]
00405415  add      eax, dword ptr [ebx]
00405417  add      eax, dword ptr [ebx]
00405419  add      eax, dword ptr [ebx]
0040541b  add      eax, dword ptr [eax]
0040541d  int3     
0040541e  int3     
0040541f  int3     
00405420  push     ebp
00405421  mov      ebp, esp
00405423  push     esi
00405424  mov      esi, ecx
00405426  call     0x404fe0
0040542b  test     byte ptr [ebp + 8], 1
0040542f  je       0x40543a
00405431  push     esi
00405432  call     0x41774d
00405437  add      esp, 4
0040543a  mov      eax, esi
0040543c  pop      esi
0040543d  pop      ebp
0040543e  ret      4
00405441  int3     
00405442  int3     
00405443  int3     
00405444  int3     
00405445  int3     
00405446  int3     
00405447  int3     
00405448  int3     
00405449  int3     
0040544a  int3     
0040544b  int3     
0040544c  int3     
0040544d  int3     
0040544e  int3     
0040544f  int3     
00405450  push     ebp
00405451  mov      ebp, esp
00405453  push     -1
00405455  push     0x529776
0040545a  mov      eax, dword ptr fs:[0]
00405460  push     eax
00405461  mov      eax, 0x1e44
00405466  call     0x50c1e0
0040546b  mov      eax, dword ptr [0x588250]
00405470  xor      eax, ebp
00405472  mov      dword ptr [ebp - 0x10], eax
00405475  push     esi
00405476  push     eax
00405477  lea      eax, [ebp - 0xc]
0040547a  mov      dword ptr fs:[0], eax
00405480  mov      eax, dword ptr [ebp + 8]
00405483  and      eax, 0xfff0
00405488  mov      esi, ecx
0040548a  cmp      eax, 0x10
0040548d  jne      0x40552f
00405493  call     0x418e64
00405498  xor      ecx, ecx
0040549a  test     eax, eax
0040549c  setne    cl
0040549f  test     ecx, ecx
004054a1  jne      0x4054ad
004054a3  push     0x80004005
004054a8  call     0x401080
004054ad  mov      edx, dword ptr [eax]
004054af  mov      ecx, eax
004054b1  mov      eax, dword ptr [edx + 0xc]
004054b4  call     eax
004054b6  add      eax, 0x10
004054b9  mov      dword ptr [ebp - 0x1e50], eax
004054bf  lea      ecx, [ebp - 0x1e50]
004054c5  push     ecx
004054c6  mov      ecx, esi
004054c8  mov      dword ptr [ebp - 4], 0
004054cf  call     0x41e7c7
004054d4  lea      edx, [ebp - 0x1e50]
004054da  push     edx
004054db  lea      ecx, [ebp - 0x1e4c]
004054e1  call     0x403e20
004054e6  lea      ecx, [ebp - 0x1e4c]
004054ec  mov      byte ptr [ebp - 4], 1
004054f0  call     0x418afe
004054f5  lea      ecx, [ebp - 0x1e4c]
004054fb  mov      byte ptr [ebp - 4], 0
004054ff  call     0x4040f0
00405504  mov      eax, dword ptr [ebp - 0x1e50]
0040550a  add      eax, -0x10
0040550d  mov      dword ptr [ebp - 4], 0xffffffff
00405514  lea      ecx, [eax + 0xc]
00405517  or       edx, 0xffffffff
0040551a  lock xadd dword ptr [ecx], edx
0040551e  dec      edx
0040551f  test     edx, edx
00405521  jg       0x405534
00405523  mov      ecx, dword ptr [eax]
00405525  mov      edx, dword ptr [ecx]
00405527  push     eax
00405528  mov      eax, dword ptr [edx + 4]
0040552b  call     eax
0040552d  jmp      0x405534
0040552f  call     0x41ce13
00405534  mov      ecx, dword ptr [ebp - 0xc]
00405537  mov      dword ptr fs:[0], ecx
0040553e  pop      ecx
0040553f  pop      esi
00405540  mov      ecx, dword ptr [ebp - 0x10]
00405543  xor      ecx, ebp
00405545  call     0x50bc27
0040554a  mov      esp, ebp
0040554c  pop      ebp
0040554d  ret      8
00405550  push     ebp
00405551  mov      ebp, esp
00405553  push     ebx
00405554  mov      ebx, dword ptr [ebp + 0xc]
00405557  push     esi
00405558  mov      esi, ecx
0040555a  mov      ecx, dword ptr [ebp + 8]
0040555d  push     edi
0040555e  mov      edi, dword ptr [ecx + 0x10]
00405561  cmp      edi, ebx
00405563  jae      0x40556f
00405565  push     0x538de4
0040556a  call     0x528edb
0040556f  mov      eax, dword ptr [ebp + 0x10]
00405572  sub      edi, ebx
00405574  cmp      eax, edi
00405576  jae      0x40557a
00405578  mov      edi, eax
0040557a  cmp      esi, ecx
0040557c  jne      0x40559d
0040557e  push     -1
00405580  add      edi, ebx
00405582  push     edi
00405583  mov      ecx, esi
00405585  call     0x404f40
0040558a  push     ebx
0040558b  push     0
0040558d  mov      ecx, esi
0040558f  call     0x404f40
00405594  pop      edi
00405595  mov      eax, esi
00405597  pop      esi
00405598  pop      ebx
00405599  pop      ebp
0040559a  ret      0xc
0040559d  cmp      edi, 0x7ffffffe
004055a3  jbe      0x4055af
004055a5  push     0x538dfc
004055aa  call     0x528e8e
004055af  .byte    0x8b
