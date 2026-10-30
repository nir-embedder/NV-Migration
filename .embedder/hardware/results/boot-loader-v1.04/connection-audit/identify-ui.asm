00406810  mov      byte ptr [ebx], dl
00406813  lea      ebx, [esi + 0x734]
00406819  mov      dword ptr [ebp - 0x44], 2
00406820  jmp      0x406824
00406822  xor      edi, edi
00406824  push     0x228
00406829  call     0x41771e
0040682e  add      esp, 4
00406831  mov      dword ptr [ebp - 0x58], eax
00406834  mov      dword ptr [ebp - 4], 2
0040683b  cmp      eax, edi
0040683d  je       0x406849
0040683f  push     edi
00406840  mov      ecx, eax
00406842  call     0x4142a0
00406847  mov      edi, eax
00406849  mov      edx, dword ptr [edi]
0040684b  lea      eax, [esi + 0x64c]
00406851  push     eax
00406852  mov      eax, dword ptr [edx + 0x160]
00406858  push     0x6c
0040685a  mov      ecx, edi
0040685c  mov      dword ptr [ebp - 4], 0xffffffff
00406863  call     eax
00406865  call     dword ptr [0x53848c] ; KERNEL32.dll!GetLastError
0040686b  mov      eax, dword ptr [ebp - 0x1c]
0040686e  mov      ecx, dword ptr [ebp - 0x14]
00406871  mov      edx, dword ptr [ebp - 0x18]
00406874  push     1
00406876  sub      ecx, eax
00406878  push     ecx
00406879  mov      ecx, dword ptr [ebp - 0x20]
0040687c  sub      edx, ecx
0040687e  push     edx
0040687f  push     eax
00406880  push     ecx
00406881  mov      ecx, edi
00406883  mov      dword ptr [ebx], edi
00406885  call     0x41a212
0040688a  mov      ecx, dword ptr [ebx]
0040688c  push     0
0040688e  call     0x41a252
00406893  add      ebx, 4
00406896  dec      dword ptr [ebp - 0x44]
00406899  jne      0x406822
0040689b  mov      ecx, dword ptr [esi + 0x734]
004068a1  push     5
004068a3  call     0x41a252
004068a8  mov      eax, dword ptr [esi + 0x6e0]
004068ae  push     0x640000
004068b3  push     0
004068b5  push     0x401
004068ba  push     eax
004068bb  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
004068c1  mov      ecx, dword ptr [esi + 0x3f8]
004068c7  push     ecx
004068c8  push     0x3f2
004068cd  mov      ecx, esi
004068cf  call     0x414cc0
004068d4  mov      edx, dword ptr [esi]
004068d6  mov      eax, dword ptr [edx + 0x18c]
004068dc  push     1
004068de  mov      ecx, esi
004068e0  call     eax
004068e2  push     0x539d64
004068e7  push     0x4bc
004068ec  mov      ecx, esi
004068ee  call     0x41a09a
004068f3  push     0x539d64
004068f8  push     0x4bd
004068fd  mov      ecx, esi
004068ff  call     0x41a09a
00406904  push     0x408030
00406909  lea      ecx, [esi + 0x1a8]
0040690f  call     0x4081d0
00406914  xor      eax, eax
00406916  mov      dword ptr [ebp - 0x3c], eax
00406919  mov      dword ptr [ebp - 0x34], eax
0040691c  mov      dword ptr [ebp - 0x30], eax
0040691f  mov      dword ptr [ebp - 0x2c], eax
00406922  mov      dword ptr [ebp - 0x28], eax
00406925  mov      dword ptr [ebp - 0x38], eax
00406928  mov      dword ptr [ebp - 0x24], eax
0040692b  mov      eax, 0x4d1e55b2
00406930  mov      dword ptr [ebp - 0x4c], 0x1100cb88
00406937  mov      ecx, dword ptr [ebp - 0x4c]
0040693a  mov      dword ptr [ebp - 0x34], eax
0040693d  mov      dword ptr [ebp - 0x50], 0x11cff16f
00406944  mov      eax, dword ptr [ebp - 0x50]
00406947  mov      dword ptr [ebp - 0x2c], ecx
0040694a  push     0
0040694c  lea      ecx, [ebp - 0x40]
0040694f  mov      dword ptr [ebp - 0x30], eax
00406952  mov      eax, dword ptr [esi + 0x20]
00406955  push     ecx
00406956  mov      dword ptr [ebp - 0x48], 0x30000011
0040695d  mov      edx, dword ptr [ebp - 0x48]
00406960  push     eax
00406961  mov      dword ptr [ebp - 0x40], 0x20
00406968  mov      dword ptr [ebp - 0x3c], 5
0040696f  mov      dword ptr [ebp - 0x28], edx
00406972  call     dword ptr [0x538890] ; USER32.dll!RegisterDeviceNotificationW
00406978  mov      dword ptr [esi + 0x758], eax
0040697e  mov      eax, 1
00406983  mov      ecx, dword ptr [ebp - 0xc]
00406986  mov      dword ptr fs:[0], ecx
0040698d  pop      ecx
0040698e  pop      edi
0040698f  pop      esi
00406990  pop      ebx
00406991  mov      ecx, dword ptr [ebp - 0x10]
00406994  xor      ecx, ebp
00406996  call     0x50bc27
0040699b  mov      esp, ebp
0040699d  pop      ebp
0040699e  ret      
0040699f  int3     
004069a0  push     ebp
004069a1  mov      ebp, esp
004069a3  push     -1
004069a5  push     0x5299e8
004069aa  mov      eax, dword ptr fs:[0]
004069b0  push     eax
004069b1  push     ebx
004069b2  push     esi
004069b3  push     edi
004069b4  mov      eax, dword ptr [0x588250]
004069b9  xor      eax, ebp
004069bb  push     eax
004069bc  lea      eax, [ebp - 0xc]
004069bf  mov      dword ptr fs:[0], eax
004069c5  mov      esi, ecx
004069c7  cmp      dword ptr [ebp + 8], 0x8001
004069ce  mov      edi, dword ptr [ebp + 0x10]
004069d1  jne      0x406c65
004069d7  mov      eax, dword ptr [ebp + 0xc]
004069da  cmp      eax, 7
004069dd  jne      0x406baf
004069e3  call     0x418e64
004069e8  xor      ecx, ecx
004069ea  test     eax, eax
004069ec  setne    cl
004069ef  test     ecx, ecx
004069f1  jne      0x4069fd
004069f3  push     0x80004005
004069f8  call     0x401080
004069fd  mov      edx, dword ptr [eax]
004069ff  mov      ecx, eax
00406a01  mov      eax, dword ptr [edx + 0xc]
00406a04  call     eax
00406a06  add      eax, 0x10
00406a09  mov      dword ptr [ebp + 0x10], eax
00406a0c  push     1
00406a0e  mov      ecx, esi
00406a10  mov      dword ptr [ebp - 4], 0
00406a17  call     0x41c6f3
00406a1c  push     0
00406a1e  push     0x5399ac
00406a23  lea      ecx, [esi + 0x648]
00406a29  call     0x403180
00406a2e  cmp      edi, 3
00406a31  ja       0x406b8f
00406a37  jmp      dword ptr [edi*4 + 0x406c8c]
00406a3e  push     1
00406a40  mov      ecx, esi
00406a42  call     0x414ce0
00406a47  push     0x539d78
00406a4c  lea      ecx, [esi + 0x644]
00406a52  call     0x403c70
00406a57  mov      eax, dword ptr [esi + 0x3f0]
00406a5d  sub      eax, 0
00406a60  je       0x406a76
00406a62  dec      eax
00406a63  je       0x406a6f
00406a65  dec      eax
00406a66  jne      0x406a86
00406a68  push     0x53a018
00406a6d  jmp      0x406a7b
00406a6f  push     0x539ff8
00406a74  jmp      0x406a7b
00406a76  push     0x539d78
00406a7b  lea      ecx, [esi + 0x644]
00406a81  call     0x403c70
00406a86  mov      edx, dword ptr [esi]
00406a88  mov      eax, dword ptr [edx + 0x190]
00406a8e  mov      ecx, esi
00406a90  call     eax
00406a92  jmp      0x406b8f
00406a97  push     0x539fbc
00406a9c  lea      ecx, [esi + 0x644]
00406aa2  call     0x403c70
00406aa7  push     0x539fa4
00406aac  jmp      0x406b84
00406ab1  push     0x539f68
00406ab6  jmp      0x406a9c
00406ab8  push     0x539f54
00406abd  lea      ecx, [esi + 0x644]
00406ac3  call     0x403c70
00406ac8  push     1
00406aca  mov      ecx, esi
00406acc  call     0x4045b0
00406ad1  mov      edx, dword ptr [esi]
00406ad3  mov      eax, dword ptr [edx + 0x194]
00406ad9  mov      ecx, esi
00406adb  call     eax
00406add  mov      eax, dword ptr [esi + 0x3f0]
00406ae3  add      eax, -3
00406ae6  cmp      eax, 5
00406ae9  ja       0x406b6f
00406aef  jmp      dword ptr [eax*4 + 0x406c9c]
00406af6  push     0
00406af8  push     0
00406afa  push     0x539f38
00406aff  call     0x424a1f
00406b04  jmp      0x406b7f
00406b06  push     0
00406b08  push     0
00406b0a  push     0x539f0c
00406b0f  call     0x424a1f
00406b14  jmp      0x406b7f
00406b16  push     0
00406b18  push     0
00406b1a  push     0x539ee4
00406b1f  call     0x424a1f
00406b24  jmp      0x406b7f
00406b26  push     0
00406b28  push     0
00406b2a  push     0x539ebc
00406b2f  call     0x424a1f
00406b34  jmp      0x406b7f
00406b36  push     0
00406b38  push     0
00406b3a  push     0x539e8c
00406b3f  call     0x424a1f
00406b44  jmp      0x406b7f
00406b46  mov      ecx, dword ptr [esi + 0x3f4]
00406b4c  push     ecx
00406b4d  lea      edx, [ebp + 0x10]
00406b50  push     0x539e48
00406b55  push     edx
00406b56  call     0x403880
00406b5b  mov      eax, dword ptr [ebp + 0x10]
00406b5e  add      esp, 0xc
00406b61  push     0
00406b63  push     0
00406b65  push     eax
00406b66  mov      ecx, esi
00406b68  call     0x41c44f
00406b6d  jmp      0x406b7f
00406b6f  push     0x5399ac
00406b74  lea      ecx, [esi + 0x648]
00406b7a  call     0x403c70
00406b7f  push     0x539e2c
00406b84  lea      ecx, [esi + 0x3fc]
00406b8a  call     0x41a187
00406b8f  xor      eax, eax
00406b91  cmp      edi, 3
00406b94  sete     al
00406b97  mov      ecx, esi
00406b99  push     eax
00406b9a  push     0x3f2
00406b9f  mov      dword ptr [esi + 0x3f8], eax
00406ba5  call     0x414cc0
00406baa  jmp      0x406c36
00406baf  cmp      eax, 3
00406bb2  jne      0x406bec
00406bb4  call     0x418e64
00406bb9  xor      ecx, ecx
00406bbb  test     eax, eax
00406bbd  setne    cl
00406bc0  test     ecx, ecx
00406bc2  jne      0x406bce
00406bc4  push     0x80004005
00406bc9  call     0x401080
00406bce  mov      edx, dword ptr [eax]
00406bd0  mov      ecx, eax
00406bd2  mov      eax, dword ptr [edx + 0xc]
00406bd5  call     eax
00406bd7  add      eax, 0x10
00406bda  mov      dword ptr [ebp + 0x10], eax
00406bdd  push     edi
00406bde  mov      dword ptr [ebp - 4], 1
00406be5  push     0x539e14
00406bea  jmp      0x406c06
00406bec  cmp      eax, 4
00406bef  jne      0x406c65
00406bf1  lea      ecx, [ebp + 0x10]
00406bf4  call     0x402c50
00406bf9  push     edi
00406bfa  mov      dword ptr [ebp - 4], 2
00406c01  push     0x539df8
00406c06  lea      ecx, [ebp + 0x10]
00406c09  push     ecx
00406c0a  call     0x403880
00406c0f  add      esp, 0xc
00406c12  lea      edx, [ebp + 0x10]
00406c15  push     edx
00406c16  lea      ecx, [esi + 0x648]
00406c1c  call     0x405a50
00406c21  mov      eax, dword ptr [esi + 0x6e0]
00406c27  push     0
00406c29  push     edi
00406c2a  push     0x402
00406c2f  push     eax
00406c30  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
00406c36  push     0
00406c38  mov      ecx, esi
00406c3a  call     0x41c6f3
00406c3f  mov      eax, dword ptr [ebp + 0x10]
00406c42  add      eax, -0x10
00406c45  mov      dword ptr [ebp - 4], 0xffffffff
00406c4c  lea      ecx, [eax + 0xc]
00406c4f  or       edx, 0xffffffff
00406c52  lock xadd dword ptr [ecx], edx
00406c56  dec      edx
00406c57  test     edx, edx
00406c59  jg       0x406c65
00406c5b  mov      ecx, dword ptr [eax]
00406c5d  mov      edx, dword ptr [ecx]
00406c5f  push     eax
00406c60  mov      eax, dword ptr [edx + 4]
00406c63  call     eax
00406c65  mov      ecx, dword ptr [ebp + 0xc]
00406c68  mov      edx, dword ptr [ebp + 8]
00406c6b  push     edi
00406c6c  push     ecx
00406c6d  push     edx
00406c6e  mov      ecx, esi
00406c70  call     0x414d30
00406c75  mov      ecx, dword ptr [ebp - 0xc]
00406c78  mov      dword ptr fs:[0], ecx
00406c7f  pop      ecx
00406c80  pop      edi
00406c81  pop      esi
00406c82  pop      ebx
00406c83  mov      esp, ebp
00406c85  pop      ebp
00406c86  ret      0xc
00406c89  lea      ecx, [ecx]
00406c8c  push     0x40
00406c8f  add      byte ptr [edi - 0x4effbf96], dl
00406c95  push     0x40
00406c97  add      byte ptr [eax + 0x600406a], bh
00406c9d  imul     eax, dword ptr [eax], 0x16
00406ca1  imul     eax, dword ptr [eax], 0x26
00406ca5  imul     eax, dword ptr [eax], 0x36
00406ca9  imul     eax, dword ptr [eax], 0x46
00406cad  imul     eax, dword ptr [eax], -0xa
00406cb1  push     0x40
00406cb3  add      ah, cl
00406cb5  int3     
00406cb6  int3     
00406cb7  int3     
00406cb8  int3     
00406cb9  int3     
00406cba  int3     
00406cbb  int3     
00406cbc  int3     
00406cbd  int3     
00406cbe  int3     
00406cbf  int3     
00406cc0  push     ebp
00406cc1  mov      ebp, esp
00406cc3  push     -1
00406cc5  push     0x529a18
00406cca  mov      eax, dword ptr fs:[0]
00406cd0  push     eax
00406cd1  push     ecx
00406cd2  push     esi
00406cd3  push     edi
00406cd4  mov      eax, dword ptr [0x588250]
00406cd9  xor      eax, ebp
00406cdb  push     eax
00406cdc  lea      eax, [ebp - 0xc]
00406cdf  mov      dword ptr fs:[0], eax
00406ce5  mov      edi, ecx
00406ce7  mov      dword ptr [ebp - 0x10], edi
00406cea  call     0x418e64
00406cef  xor      ecx, ecx
00406cf1  test     eax, eax
00406cf3  setne    cl
00406cf6  test     ecx, ecx
00406cf8  jne      0x406d04
00406cfa  push     0x80004005
00406cff  call     0x401080
00406d04  mov      edx, dword ptr [eax]
00406d06  mov      ecx, eax
00406d08  mov      eax, dword ptr [edx + 0xc]
00406d0b  call     eax
00406d0d  add      eax, 0x10
00406d10  mov      dword ptr [edi], eax
00406d12  mov      edx, dword ptr [ebp + 8]
00406d15  mov      dword ptr [ebp - 4], 0
00406d1c  test     edx, edx
00406d1e  je       0x406d40
00406d20  test     edx, 0xffff0000
00406d26  jne      0x406d44
00406d28  movzx    esi, dx
00406d2b  push     esi
00406d2c  call     0x424738
00406d31  test     eax, eax
00406d33  je       0x406d68
00406d35  push     esi
00406d36  push     eax
00406d37  mov      ecx, edi
00406d39  call     0x4052e0
00406d3e  jmp      0x406d68
00406d40  xor      eax, eax
00406d42  jmp      0x406d5f
00406d44  mov      eax, edx
00406d46  lea      esi, [eax + 2]
00406d49  lea      esp, [esp]
