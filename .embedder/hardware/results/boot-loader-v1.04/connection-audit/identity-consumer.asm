00407730  les      ecx, ptr [edx + edx*2]
00407733  push     0x66b
00407738  mov      ecx, esi
0040773a  call     0x41a09a
0040773f  mov      eax, dword ptr [ebp - 0x10]
00407742  add      eax, -0x10
00407745  mov      dword ptr [ebp - 4], 0xffffffff
0040774c  lea      ecx, [eax + 0xc]
0040774f  or       edx, 0xffffffff
00407752  lock xadd dword ptr [ecx], edx
00407756  dec      edx
00407757  test     edx, edx
00407759  jg       0x407765
0040775b  mov      ecx, dword ptr [eax]
0040775d  mov      edx, dword ptr [ecx]
0040775f  push     eax
00407760  mov      eax, dword ptr [edx + 4]
00407763  call     eax
00407765  mov      ecx, dword ptr [ebp - 0xc]
00407768  mov      dword ptr fs:[0], ecx
0040776f  pop      ecx
00407770  pop      edi
00407771  pop      esi
00407772  mov      esp, ebp
00407774  pop      ebp
00407775  ret      
00407776  int3     
00407777  int3     
00407778  int3     
00407779  int3     
0040777a  int3     
0040777b  int3     
0040777c  int3     
0040777d  int3     
0040777e  int3     
0040777f  int3     
00407780  push     ebp
00407781  mov      ebp, esp
00407783  push     -1
00407785  push     0x529b28
0040778a  mov      eax, dword ptr fs:[0]
00407790  push     eax
00407791  push     esi
00407792  push     edi
00407793  mov      eax, dword ptr [0x588250]
00407798  xor      eax, ebp
0040779a  push     eax
0040779b  lea      eax, [ebp - 0xc]
0040779e  mov      dword ptr fs:[0], eax
004077a4  mov      esi, ecx
004077a6  mov      edi, dword ptr [ebp + 0xc]
004077a9  lea      eax, [edi + 0x1c]
004077ac  push     eax
004077ad  lea      ecx, [ebp + 0xc]
004077b0  call     0x406cc0
004077b5  cmp      dword ptr [ebp + 8], 0x8004
004077bc  mov      dword ptr [ebp - 4], 0
004077c3  jne      0x407807
004077c5  cmp      dword ptr [edi + 4], 5
004077c9  jne      0x407807
004077cb  mov      eax, dword ptr [esi + 0x3b8]
004077d1  xor      ecx, ecx
004077d3  test     eax, eax
004077d5  setne    cl
004077d8  test     ecx, ecx
004077da  jne      0x4077e6
004077dc  push     0x80004005
004077e1  call     0x401080
004077e6  mov      ecx, dword ptr [ebp + 0xc]
004077e9  push     eax
004077ea  push     ecx
004077eb  call     0x50bf5e
004077f0  add      esp, 8
004077f3  test     eax, eax
004077f5  jne      0x407807
004077f7  push     0x408030
004077fc  lea      ecx, [esi + 0x1a8]
00407802  call     0x4081d0
00407807  mov      eax, dword ptr [ebp + 0xc]
0040780a  add      eax, -0x10
0040780d  mov      dword ptr [ebp - 4], 0xffffffff
00407814  lea      edx, [eax + 0xc]
00407817  or       ecx, 0xffffffff
0040781a  lock xadd dword ptr [edx], ecx
0040781e  dec      ecx
0040781f  test     ecx, ecx
00407821  jg       0x40782d
00407823  mov      ecx, dword ptr [eax]
00407825  mov      edx, dword ptr [ecx]
00407827  push     eax
00407828  mov      eax, dword ptr [edx + 4]
0040782b  call     eax
0040782d  mov      eax, 1
00407832  mov      ecx, dword ptr [ebp - 0xc]
00407835  mov      dword ptr fs:[0], ecx
0040783c  pop      ecx
0040783d  pop      edi
0040783e  pop      esi
0040783f  mov      esp, ebp
00407841  pop      ebp
00407842  ret      8
00407845  int3     
00407846  int3     
00407847  int3     
00407848  int3     
00407849  int3     
0040784a  int3     
0040784b  int3     
0040784c  int3     
0040784d  int3     
0040784e  int3     
0040784f  int3     
00407850  push     ebp
00407851  mov      ebp, esp
00407853  push     -1
00407855  push     0x529bfe
0040785a  mov      eax, dword ptr fs:[0]
00407860  push     eax
00407861  sub      esp, 0x138
00407867  mov      eax, dword ptr [0x588250]
0040786c  xor      eax, ebp
0040786e  mov      dword ptr [ebp - 0x10], eax
00407871  push     ebx
00407872  push     esi
00407873  push     edi
00407874  push     eax
00407875  lea      eax, [ebp - 0xc]
00407878  mov      dword ptr fs:[0], eax
0040787e  mov      esi, ecx
00407880  mov      ecx, dword ptr [esi + 0x2b4]
00407886  mov      edx, dword ptr [esi + 0x2ac]
0040788c  lea      eax, [esi + 0x204]
00407892  push     eax
00407893  mov      eax, dword ptr [esi + 0x1fc]
00407899  push     ecx
0040789a  push     edx
0040789b  push     eax
0040789c  lea      ecx, [esi + 0x1a8]
004078a2  call     0x4080f0
004078a7  push     0
004078a9  push     0x4f6
004078ae  mov      ecx, esi
004078b0  mov      bl, al
004078b2  call     0x414ca0
004078b7  push     0
004078b9  push     0x4bc
004078be  mov      ecx, esi
004078c0  call     0x414ca0
004078c5  push     0
004078c7  push     0x4bc
004078cc  mov      ecx, esi
004078ce  call     0x414cc0
004078d3  push     0x5399ac
004078d8  lea      ecx, [ebp - 0xa0]
004078de  call     0x406cc0
004078e3  push     0x589aac
004078e8  lea      ecx, [ebp - 0xa0]
004078ee  mov      dword ptr [ebp - 4], 0
004078f5  call     0x405250
004078fa  mov      ecx, dword ptr [ebp - 0xa0]
00407900  push     ecx
00407901  push     0x441
00407906  mov      ecx, esi
00407908  call     0x41a09a
0040790d  mov      edx, dword ptr [esi + 0x250]
00407913  push     edx
00407914  lea      eax, [ebp - 0xa0]
0040791a  push     0x53a248
0040791f  push     eax
00407920  call     0x403880
00407925  mov      ecx, dword ptr [ebp - 0xa0]
0040792b  add      esp, 0xc
0040792e  push     ecx
0040792f  push     0x665
00407934  mov      ecx, esi
00407936  call     0x41a09a
0040793b  mov      edx, dword ptr [esi + 0x254]
00407941  push     edx
00407942  lea      eax, [ebp - 0xa0]
00407948  push     0x53a248
0040794d  push     eax
0040794e  call     0x403880
00407953  mov      ecx, dword ptr [ebp - 0xa0]
00407959  add      esp, 0xc
0040795c  push     ecx
0040795d  push     0x667
00407962  mov      ecx, esi
00407964  call     0x41a09a
00407969  mov      edx, dword ptr [esi + 0x258]
0040796f  push     edx
00407970  lea      eax, [ebp - 0xa0]
00407976  push     0x53a248
0040797b  push     eax
0040797c  call     0x403880
00407981  mov      ecx, dword ptr [ebp - 0xa0]
00407987  add      esp, 0xc
0040798a  push     ecx
0040798b  push     0x669
00407990  mov      ecx, esi
00407992  call     0x41a09a
00407997  mov      edx, dword ptr [esi + 0x25c]
0040799d  push     edx
0040799e  lea      eax, [ebp - 0xa0]
004079a4  push     0x53a248
004079a9  push     eax
004079aa  call     0x403880
004079af  mov      ecx, dword ptr [ebp - 0xa0]
004079b5  add      esp, 0xc
004079b8  push     ecx
004079b9  push     0x66b
004079be  mov      ecx, esi
004079c0  call     0x41a09a
004079c5  push     1
004079c7  lea      ecx, [ebp - 0x144]
004079cd  push     2
004079cf  call     0x403af0
004079d4  test     bl, bl
004079d6  je       0x407caa
004079dc  mov      edx, dword ptr [esi + 0x2b4]
004079e2  push     edx
004079e3  lea      eax, [ebp - 0x80]
004079e6  push     eax
004079e7  mov      byte ptr [ebp - 4], 1
004079eb  call     0x406180
004079f0  mov      edi, eax
004079f2  mov      ecx, dword ptr [esi + 0x2a8]
004079f8  push     ecx
004079f9  lea      edx, [ebp - 0x64]
004079fc  push     edx
004079fd  mov      byte ptr [ebp - 4], 2
00407a01  call     0x406180
00407a06  mov      ebx, eax
00407a08  mov      eax, dword ptr [esi + 0x2a0]
00407a0e  push     eax
00407a0f  lea      ecx, [ebp - 0x9c]
00407a15  push     ecx
00407a16  mov      byte ptr [ebp - 4], 3
00407a1a  call     0x406180
00407a1f  .byte    0x83
