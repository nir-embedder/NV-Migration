00407a20  les      ebx, ptr [eax]
00407a22  push     edi
00407a23  push     0x53a4cc
00407a28  push     ebx
00407a29  push     0x53a4c0
00407a2e  push     eax
00407a2f  lea      edx, [ebp - 0x144]
00407a35  push     0x53a4b8
00407a3a  push     edx
00407a3b  mov      byte ptr [ebp - 4], 4
00407a3f  call     0x4034a0
00407a44  add      esp, 8
00407a47  push     eax
00407a48  call     0x405740
00407a4d  add      esp, 8
00407a50  push     eax
00407a51  call     0x4034a0
00407a56  add      esp, 8
00407a59  push     eax
00407a5a  call     0x405740
00407a5f  add      esp, 8
00407a62  push     eax
00407a63  call     0x4034a0
00407a68  add      esp, 8
00407a6b  push     eax
00407a6c  call     0x405740
00407a71  mov      edi, 0x10
00407a76  add      esp, 8
00407a79  cmp      dword ptr [ebp - 0x88], edi
00407a7f  jb       0x407a90
00407a81  mov      eax, dword ptr [ebp - 0x9c]
00407a87  push     eax
00407a88  call     0x41774d
00407a8d  add      esp, 4
00407a90  xor      ebx, ebx
00407a92  mov      dword ptr [ebp - 0x88], 0xf
00407a9c  mov      dword ptr [ebp - 0x8c], ebx
00407aa2  mov      byte ptr [ebp - 0x9c], bl
00407aa8  cmp      dword ptr [ebp - 0x50], edi
00407aab  jb       0x407ab9
00407aad  mov      ecx, dword ptr [ebp - 0x64]
00407ab0  push     ecx
00407ab1  call     0x41774d
00407ab6  add      esp, 4
00407ab9  mov      dword ptr [ebp - 0x50], 0xf
00407ac0  mov      dword ptr [ebp - 0x54], ebx
00407ac3  mov      byte ptr [ebp - 0x64], bl
00407ac6  mov      byte ptr [ebp - 4], 1
00407aca  cmp      dword ptr [ebp - 0x6c], edi
00407acd  jb       0x407adb
00407acf  mov      edx, dword ptr [ebp - 0x80]
00407ad2  push     edx
00407ad3  call     0x41774d
00407ad8  add      esp, 4
00407adb  lea      eax, [ebp - 0x48]
00407ade  push     eax
00407adf  lea      ecx, [ebp - 0x144]
00407ae5  call     0x403df0
00407aea  mov      edx, dword ptr [ebp - 0x34]
00407aed  mov      ecx, dword ptr [ebp - 0x48]
00407af0  mov      byte ptr [ebp - 4], 5
00407af4  mov      eax, ecx
00407af6  cmp      edx, edi
00407af8  jae      0x407afd
00407afa  lea      eax, [ebp - 0x48]
00407afd  add      eax, dword ptr [ebp - 0x38]
00407b00  cmp      edx, 0x10
00407b03  jae      0x407b08
00407b05  lea      ecx, [ebp - 0x48]
00407b08  xor      edx, edx
00407b0a  mov      word ptr [ebp - 0x2c], dx
00407b0e  mov      edx, dword ptr [ebp - 0xa4]
00407b14  push     edx
00407b15  push     eax
00407b16  push     ecx
00407b17  lea      ecx, [ebp - 0x2c]
00407b1a  mov      dword ptr [ebp - 0x18], 7
00407b21  mov      dword ptr [ebp - 0x1c], ebx
00407b24  call     0x403760
00407b29  mov      eax, dword ptr [ebp - 0x2c]
00407b2c  mov      edi, 8
00407b31  mov      byte ptr [ebp - 4], 6
00407b35  cmp      dword ptr [ebp - 0x18], edi
00407b38  jae      0x407b3d
00407b3a  lea      eax, [ebp - 0x2c]
00407b3d  push     eax
00407b3e  lea      ecx, [ebp - 0xa4]
00407b44  call     0x406cc0
00407b49  mov      byte ptr [ebp - 4], 7
00407b4d  call     0x418e64
00407b52  xor      ecx, ecx
00407b54  cmp      eax, ebx
00407b56  setne    cl
00407b59  cmp      ecx, ebx
00407b5b  jne      0x407b67
00407b5d  push     0x80004005
00407b62  call     0x401080
00407b67  mov      edx, dword ptr [eax]
00407b69  mov      ecx, eax
00407b6b  mov      eax, dword ptr [edx + 0xc]
00407b6e  call     eax
00407b70  add      eax, 0x10
00407b73  mov      dword ptr [ebp - 0xac], eax
00407b79  mov      ecx, dword ptr [ebp - 0xa4]
00407b7f  push     ecx
00407b80  lea      edx, [ebp - 0xac]
00407b86  push     0x53a478
00407b8b  push     edx
00407b8c  mov      byte ptr [ebp - 4], 8
00407b90  call     0x403880
00407b95  add      esp, 0xc
00407b98  call     0x418e64
00407b9d  xor      ecx, ecx
00407b9f  cmp      eax, ebx
00407ba1  setne    cl
00407ba4  cmp      ecx, ebx
00407ba6  jne      0x407bb2
00407ba8  push     0x80004005
00407bad  call     0x401080
00407bb2  mov      edx, dword ptr [eax]
00407bb4  mov      ecx, eax
00407bb6  mov      eax, dword ptr [edx + 0xc]
00407bb9  call     eax
00407bbb  add      eax, 0x10
00407bbe  mov      dword ptr [ebp - 0xa8], eax
00407bc4  mov      eax, dword ptr [ebp - 0x2c]
00407bc7  mov      byte ptr [ebp - 4], 9
00407bcb  cmp      dword ptr [ebp - 0x18], edi
00407bce  jae      0x407bd3
00407bd0  lea      eax, [ebp - 0x2c]
00407bd3  mov      ecx, dword ptr [esi + 0x1f8]
00407bd9  push     ecx
00407bda  push     eax
00407bdb  lea      edx, [ebp - 0xa8]
00407be1  push     0x53a454
00407be6  push     edx
00407be7  call     0x403880
00407bec  mov      edi, dword ptr [ebp - 0xa8]
00407bf2  add      esp, 0x10
00407bf5  push     edi
00407bf6  push     0x3ff
00407bfb  mov      ecx, esi
00407bfd  call     0x41a09a
00407c02  lea      eax, [edi - 0x10]
00407c05  mov      byte ptr [ebp - 4], 8
00407c09  lea      ecx, [eax + 0xc]
00407c0c  or       edx, 0xffffffff
00407c0f  lock xadd dword ptr [ecx], edx
00407c13  dec      edx
00407c14  test     edx, edx
00407c16  jg       0x407c22
00407c18  mov      ecx, dword ptr [eax]
00407c1a  mov      edx, dword ptr [ecx]
00407c1c  push     eax
00407c1d  mov      eax, dword ptr [edx + 4]
00407c20  call     eax
00407c22  mov      eax, dword ptr [ebp - 0xac]
00407c28  add      eax, -0x10
00407c2b  mov      byte ptr [ebp - 4], 7
00407c2f  lea      ecx, [eax + 0xc]
00407c32  or       edx, 0xffffffff
00407c35  lock xadd dword ptr [ecx], edx
00407c39  dec      edx
00407c3a  test     edx, edx
00407c3c  jg       0x407c48
00407c3e  mov      ecx, dword ptr [eax]
00407c40  mov      edx, dword ptr [ecx]
00407c42  push     eax
00407c43  mov      eax, dword ptr [edx + 4]
00407c46  call     eax
00407c48  mov      eax, dword ptr [ebp - 0xa4]
00407c4e  add      eax, -0x10
00407c51  mov      byte ptr [ebp - 4], 6
00407c55  lea      ecx, [eax + 0xc]
00407c58  or       edx, 0xffffffff
00407c5b  lock xadd dword ptr [ecx], edx
00407c5f  dec      edx
00407c60  test     edx, edx
00407c62  jg       0x407c6e
00407c64  mov      ecx, dword ptr [eax]
00407c66  mov      edx, dword ptr [ecx]
00407c68  push     eax
00407c69  mov      eax, dword ptr [edx + 4]
00407c6c  call     eax
00407c6e  cmp      dword ptr [ebp - 0x18], 8
00407c72  jb       0x407c80
00407c74  mov      ecx, dword ptr [ebp - 0x2c]
00407c77  push     ecx
00407c78  call     0x41774d
00407c7d  add      esp, 4
00407c80  xor      edx, edx
00407c82  cmp      dword ptr [ebp - 0x34], 0x10
00407c86  mov      dword ptr [ebp - 0x18], 7
00407c8d  mov      dword ptr [ebp - 0x1c], ebx
00407c90  mov      word ptr [ebp - 0x2c], dx
00407c94  jb       0x407ca2
00407c96  mov      eax, dword ptr [ebp - 0x48]
00407c99  push     eax
00407c9a  call     0x41774d
00407c9f  add      esp, 4
00407ca2  mov      dword ptr [ebp - 0x38], ebx
00407ca5  jmp      0x407f1c
00407caa  mov      ecx, dword ptr [esi + 0x2b4]
00407cb0  push     ecx
00407cb1  lea      edx, [ebp - 0x80]
00407cb4  mov      bl, 0xa
00407cb6  push     edx
00407cb7  mov      byte ptr [ebp - 4], bl
00407cba  call     0x406180
00407cbf  mov      edi, eax
00407cc1  mov      eax, dword ptr [esi + 0x2a0]
00407cc7  push     eax
00407cc8  lea      ecx, [ebp - 0x64]
00407ccb  push     ecx
00407ccc  mov      byte ptr [ebp - 4], 0xb
00407cd0  call     0x406180
00407cd5  add      esp, 0x10
00407cd8  push     edi
00407cd9  push     0x53a4cc
00407cde  push     eax
00407cdf  lea      edx, [ebp - 0x144]
00407ce5  push     0x53a4b8
00407cea  push     edx
00407ceb  mov      byte ptr [ebp - 4], 0xc
00407cef  call     0x4034a0
00407cf4  add      esp, 8
00407cf7  push     eax
00407cf8  call     0x405740
00407cfd  add      esp, 8
00407d00  push     eax
00407d01  call     0x4034a0
00407d06  add      esp, 8
00407d09  push     eax
00407d0a  call     0x405740
00407d0f  mov      edi, 0x10
00407d14  add      esp, 8
00407d17  cmp      dword ptr [ebp - 0x50], edi
00407d1a  jb       0x407d28
00407d1c  mov      eax, dword ptr [ebp - 0x64]
00407d1f  push     eax
00407d20  call     0x41774d
00407d25  add      esp, 4
00407d28  mov      dword ptr [ebp - 0x50], 0xf
00407d2f  mov      dword ptr [ebp - 0x54], 0
00407d36  mov      byte ptr [ebp - 0x64], 0
00407d3a  mov      byte ptr [ebp - 4], bl
00407d3d  cmp      dword ptr [ebp - 0x6c], edi
00407d40  jb       0x407d4e
00407d42  mov      ecx, dword ptr [ebp - 0x80]
00407d45  push     ecx
00407d46  call     0x41774d
00407d4b  add      esp, 4
00407d4e  lea      edx, [ebp - 0x48]
00407d51  push     edx
00407d52  lea      ecx, [ebp - 0x144]
00407d58  call     0x403df0
00407d5d  mov      edx, dword ptr [ebp - 0x34]
00407d60  mov      ecx, dword ptr [ebp - 0x48]
00407d63  mov      byte ptr [ebp - 4], 0xd
00407d67  mov      eax, ecx
00407d69  cmp      edx, edi
00407d6b  jae      0x407d70
00407d6d  lea      eax, [ebp - 0x48]
00407d70  add      eax, dword ptr [ebp - 0x38]
00407d73  cmp      edx, edi
00407d75  jae      0x407d7a
00407d77  lea      ecx, [ebp - 0x48]
00407d7a  xor      edx, edx
00407d7c  mov      word ptr [ebp - 0x2c], dx
00407d80  mov      edx, dword ptr [ebp - 0xa4]
00407d86  push     edx
00407d87  push     eax
00407d88  push     ecx
00407d89  lea      ecx, [ebp - 0x2c]
00407d8c  mov      dword ptr [ebp - 0x18], 7
00407d93  mov      dword ptr [ebp - 0x1c], 0
00407d9a  call     0x403760
00407d9f  mov      eax, dword ptr [ebp - 0x2c]
00407da2  mov      ebx, 8
00407da7  mov      byte ptr [ebp - 4], 0xe
00407dab  cmp      dword ptr [ebp - 0x18], ebx
00407dae  jae      0x407db3
00407db0  lea      eax, [ebp - 0x2c]
00407db3  push     eax
00407db4  lea      ecx, [ebp - 0xa8]
00407dba  call     0x406cc0
00407dbf  mov      byte ptr [ebp - 4], 0xf
00407dc3  call     0x418e64
00407dc8  xor      ecx, ecx
00407dca  test     eax, eax
00407dcc  setne    cl
00407dcf  test     ecx, ecx
00407dd1  jne      0x407ddd
00407dd3  push     0x80004005
00407dd8  call     0x401080
00407ddd  mov      edx, dword ptr [eax]
00407ddf  mov      ecx, eax
00407de1  mov      eax, dword ptr [edx + 0xc]
00407de4  call     eax
00407de6  add      eax, 0x10
00407de9  mov      dword ptr [ebp - 0xac], eax
00407def  mov      ecx, dword ptr [ebp - 0xa8]
00407df5  push     ecx
00407df6  lea      edx, [ebp - 0xac]
00407dfc  push     0x53a478
00407e01  push     edx
00407e02  mov      byte ptr [ebp - 4], 0x10
00407e06  call     0x403880
00407e0b  add      esp, 0xc
00407e0e  call     0x418e64
00407e13  xor      ecx, ecx
00407e15  test     eax, eax
00407e17  setne    cl
00407e1a  test     ecx, ecx
00407e1c  jne      0x407e28
00407e1e  push     0x80004005
00407e23  call     0x401080
00407e28  mov      edx, dword ptr [eax]
00407e2a  mov      ecx, eax
00407e2c  mov      eax, dword ptr [edx + 0xc]
00407e2f  call     eax
00407e31  add      eax, 0x10
00407e34  mov      dword ptr [ebp - 0xa4], eax
00407e3a  mov      eax, dword ptr [ebp - 0x2c]
00407e3d  mov      byte ptr [ebp - 4], 0x11
00407e41  cmp      dword ptr [ebp - 0x18], ebx
00407e44  jae      0x407e49
00407e46  lea      eax, [ebp - 0x2c]
00407e49  mov      ecx, dword ptr [esi + 0x1f8]
00407e4f  push     ecx
00407e50  push     eax
00407e51  lea      edx, [ebp - 0xa4]
00407e57  push     0x53a454
00407e5c  push     edx
00407e5d  call     0x403880
00407e62  mov      edi, dword ptr [ebp - 0xa4]
00407e68  add      esp, 0x10
00407e6b  push     edi
00407e6c  push     0x3ff
00407e71  mov      ecx, esi
00407e73  call     0x41a09a
00407e78  lea      eax, [edi - 0x10]
00407e7b  mov      byte ptr [ebp - 4], 0x10
00407e7f  lea      ecx, [eax + 0xc]
00407e82  or       edx, 0xffffffff
00407e85  lock xadd dword ptr [ecx], edx
00407e89  dec      edx
00407e8a  test     edx, edx
00407e8c  jg       0x407e98
00407e8e  mov      ecx, dword ptr [eax]
00407e90  mov      edx, dword ptr [ecx]
00407e92  push     eax
00407e93  mov      eax, dword ptr [edx + 4]
00407e96  call     eax
00407e98  mov      eax, dword ptr [ebp - 0xac]
00407e9e  add      eax, -0x10
00407ea1  mov      byte ptr [ebp - 4], 0xf
00407ea5  lea      ecx, [eax + 0xc]
00407ea8  or       edx, 0xffffffff
00407eab  lock xadd dword ptr [ecx], edx
00407eaf  dec      edx
00407eb0  test     edx, edx
00407eb2  jg       0x407ebe
00407eb4  mov      ecx, dword ptr [eax]
00407eb6  mov      edx, dword ptr [ecx]
00407eb8  push     eax
00407eb9  mov      eax, dword ptr [edx + 4]
00407ebc  call     eax
00407ebe  mov      eax, dword ptr [ebp - 0xa8]
00407ec4  add      eax, -0x10
00407ec7  mov      byte ptr [ebp - 4], 0xe
00407ecb  lea      ecx, [eax + 0xc]
00407ece  or       edx, 0xffffffff
00407ed1  lock xadd dword ptr [ecx], edx
00407ed5  dec      edx
00407ed6  test     edx, edx
00407ed8  jg       0x407ee4
00407eda  mov      ecx, dword ptr [eax]
00407edc  mov      edx, dword ptr [ecx]
00407ede  push     eax
00407edf  mov      eax, dword ptr [edx + 4]
00407ee2  call     eax
00407ee4  cmp      dword ptr [ebp - 0x18], ebx
00407ee7  jb       0x407ef5
00407ee9  mov      ecx, dword ptr [ebp - 0x2c]
00407eec  push     ecx
00407eed  call     0x41774d
00407ef2  add      esp, 4
00407ef5  xor      edi, edi
00407ef7  xor      edx, edx
00407ef9  cmp      dword ptr [ebp - 0x34], 0x10
00407efd  mov      dword ptr [ebp - 0x18], 7
00407f04  mov      dword ptr [ebp - 0x1c], edi
00407f07  mov      word ptr [ebp - 0x2c], dx
00407f0b  jb       0x407f19
00407f0d  mov      eax, dword ptr [ebp - 0x48]
00407f10  push     eax
00407f11  call     0x41774d
00407f16  add      esp, 4
00407f19  mov      dword ptr [ebp - 0x38], edi
00407f1c  lea      ecx, [ebp - 0x144]
00407f22  mov      dword ptr [ebp - 0x34], 0xf
00407f29  mov      byte ptr [ebp - 0x48], 0
00407f2d  mov      byte ptr [ebp - 4], 0
00407f31  call     0x402cc0
00407f36  call     0x40b1f0
00407f3b  mov      ecx, esi
00407f3d  cmp      eax, 0x44
00407f40  jne      0x407f49
00407f42  push     0x53a440
00407f47  jmp      0x407f4e
00407f49  push     0x539d64
00407f4e  push     0x4bd
00407f53  call     0x41a09a
00407f58  mov      ecx, dword ptr [esi + 0x20]
00407f5b  push     1
00407f5d  push     0
00407f5f  push     ecx
00407f60  call     dword ptr [0x538898] ; USER32.dll!InvalidateRect
00407f66  mov      eax, dword ptr [ebp - 0xa0]
00407f6c  add      eax, -0x10
00407f6f  mov      dword ptr [ebp - 4], 0xffffffff
00407f76  lea      edx, [eax + 0xc]
00407f79  or       ecx, 0xffffffff
00407f7c  lock xadd dword ptr [edx], ecx
00407f80  dec      ecx
00407f81  test     ecx, ecx
00407f83  jg       0x407f8f
00407f85  mov      ecx, dword ptr [eax]
00407f87  mov      edx, dword ptr [ecx]
00407f89  push     eax
00407f8a  mov      eax, dword ptr [edx + 4]
00407f8d  call     eax
00407f8f  mov      ecx, dword ptr [ebp - 0xc]
00407f92  mov      dword ptr fs:[0], ecx
00407f99  pop      ecx
00407f9a  pop      edi
00407f9b  pop      esi
00407f9c  pop      ebx
00407f9d  mov      ecx, dword ptr [ebp - 0x10]
00407fa0  xor      ecx, ebp
00407fa2  call     0x50bc27
00407fa7  mov      esp, ebp
00407fa9  pop      ebp
00407faa  ret      
00407fab  int3     
00407fac  int3     
00407fad  int3     
00407fae  int3     
00407faf  int3     
00407fb0  mov      eax, 0x53a258
00407fb5  ret      
00407fb6  int3     
00407fb7  int3     
00407fb8  int3     
00407fb9  int3     
00407fba  int3     
00407fbb  int3     
00407fbc  int3     
00407fbd  int3     
00407fbe  int3     
00407fbf  int3     
