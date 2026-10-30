00408540  push     ebp
00408541  mov      ebp, esp
00408543  push     -1
00408545  push     0x529ca8
0040854a  mov      eax, dword ptr fs:[0]
00408550  push     eax
00408551  sub      esp, 0x60
00408554  mov      eax, dword ptr [0x588250]
00408559  xor      eax, ebp
0040855b  mov      dword ptr [ebp - 0x14], eax
0040855e  push     ebx
0040855f  push     esi
00408560  push     edi
00408561  push     eax
00408562  lea      eax, [ebp - 0xc]
00408565  mov      dword ptr fs:[0], eax
0040856b  mov      dword ptr [ebp - 0x10], esp
0040856e  mov      ebx, ecx
00408570  cmp      dword ptr [ebx + 0x3c], 0x408540
00408577  mov      dword ptr [ebp - 0x6c], ebx
0040857a  jne      0x408865
00408580  xor      edi, edi
00408582  push     edi
00408583  mov      dword ptr [ebx + 0x248], edi
00408589  mov      dword ptr [ebp - 4], edi
0040858c  call     0x50c2a5
00408591  add      esp, 4
00408594  lea      ecx, [ebx + 0x140]
0040859a  mov      dword ptr [ebp - 0x60], eax
0040859d  mov      dword ptr [ebp - 0x5c], edx
004085a0  call     0x40a6f0
004085a5  cmp      eax, edi
004085a7  jne      0x4085c9
004085a9  mov      eax, dword ptr [ebx + 0x48]
004085ac  push     -1
004085ae  push     eax
004085af  mov      dword ptr [ebx + 0x248], 2
004085b9  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
004085bf  mov      eax, dword ptr [ebx + 0x3c]
004085c2  cmp      eax, edi
004085c4  jmp      0x408c43
004085c9  mov      eax, dword ptr [0x589a74]
004085ce  cmp      dword ptr [ebx + 0x124], edi
004085d4  je       0x408661
004085da  cmp      eax, 0x42
004085dd  je       0x408742
004085e3  cmp      eax, 0x43
004085e6  je       0x408742
004085ec  lea      ecx, [ebx + 0x140]
004085f2  call     0x40ad20
004085f7  cmp      eax, edi
004085f9  je       0x408727
004085ff  mov      eax, dword ptr [0x589a74]
00408604  cmp      eax, 0x3d
00408607  je       0x408713
0040860d  cmp      eax, 0x40
00408610  je       0x408713
00408616  call     0x40b1f0
0040861b  cmp      eax, 0x49
0040861e  je       0x4086fd
00408624  call     0x40b1f0
00408629  cmp      eax, 0x4a
0040862c  je       0x4086fd
00408632  call     0x40b1f0
00408637  cmp      eax, 0x4b
0040863a  je       0x4086fd
00408640  push     0xc8
00408645  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
0040864b  lea      eax, [ebx + 0x5c]
0040864e  push     0xe
00408650  push     eax
00408651  lea      ecx, [ebx + 0x140]
00408657  call     0x40a810
0040865c  mov      eax, dword ptr [0x589a74]
00408661  cmp      dword ptr [ebx + 0x120], 0
00408668  je       0x408a16
0040866e  cmp      eax, 0x44
00408671  je       0x4088ae
00408677  cmp      eax, 0x49
0040867a  je       0x4088ae
00408680  cmp      eax, 0x4a
00408683  je       0x4088ae
00408689  cmp      eax, 0x4b
0040868c  je       0x4088ae
00408692  mov      edx, dword ptr [ebx + 0x58]
00408695  lea      esi, [ebx + 0x5c]
00408698  push     esi
00408699  lea      edi, [ebx + 0xa8]
0040869f  push     edi
004086a0  push     edx
004086a1  lea      ecx, [ebx + 0x140]
004086a7  call     0x40a930
004086ac  push     0xc8
004086b1  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
004086b7  mov      eax, dword ptr [edi]
004086b9  cmp      eax, dword ptr [esi]
004086bb  jne      0x4086e2
004086bd  mov      ecx, dword ptr [ebx + 0xac]
004086c3  cmp      ecx, dword ptr [ebx + 0x60]
004086c6  jne      0x4086e2
004086c8  mov      edx, dword ptr [ebx + 0xb0]
004086ce  cmp      edx, dword ptr [ebx + 0x64]
004086d1  jne      0x4086e2
004086d3  mov      eax, dword ptr [ebx + 0xb4]
004086d9  cmp      eax, dword ptr [ebx + 0x68]
004086dc  je       0x408a0e
004086e2  push     0x408090
004086e7  mov      ecx, ebx
004086e9  mov      dword ptr [ebx + 0x248], 3
004086f3  call     0x4081d0
004086f8  jmp      0x408865
004086fd  lea      eax, [ebx + 0x5c]
00408700  push     0x13
00408702  push     eax
00408703  lea      ecx, [ebx + 0x140]
00408709  call     0x40a8a0
0040870e  jmp      0x40865c
00408713  lea      eax, [ebx + 0x5c]
00408716  push     eax
00408717  lea      ecx, [ebx + 0x140]
0040871d  call     0x40a7d0
00408722  jmp      0x40865c
00408727  push     0x408090
0040872c  mov      ecx, ebx
0040872e  mov      dword ptr [ebx + 0x248], 8
00408738  call     0x4081d0
0040873d  jmp      0x408865
00408742  mov      eax, dword ptr [ebx + 0x40]
00408745  cmp      eax, edi
00408747  je       0x40875a
00408749  mov      edx, dword ptr [eax]
0040874b  push     edi
0040874c  push     3
0040874e  push     0x8001
00408753  push     edx
00408754  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
0040875a  mov      eax, dword ptr [ebx + 0xf8]
00408760  mov      edi, dword ptr [ebx + 0x110]
00408766  add      edi, dword ptr [ebx + 0xf4]
0040876c  push     0x38
0040876e  lea      ecx, [ebp - 0x4c]
00408771  push     0xff
00408776  push     ecx
00408777  mov      dword ptr [ebp - 0x54], eax
0040877a  call     0x50c310
0040877f  add      esp, 0xc
00408782  xor      esi, esi
00408784  cmp      esi, dword ptr [ebp - 0x54]
00408787  jae      0x4087df
00408789  lea      edx, [ebp - 0x50]
0040878c  push     edx
0040878d  mov      edx, dword ptr [ebp - 0x54]
00408790  lea      eax, [ebp - 0x4c]
00408793  push     eax
00408794  lea      ecx, [esi + edi]
00408797  push     ecx
00408798  push     edx
00408799  push     edi
0040879a  lea      ecx, [ebx + 0x140]
004087a0  call     0x40aac0
004087a5  test     eax, eax
004087a7  jne      0x4087b8
004087a9  mov      dword ptr [ebx + 0x248], 8
004087b3  jmp      0x408c32
004087b8  mov      ecx, dword ptr [ebx + 0x40]
004087bb  add      esi, dword ptr [ebp - 0x50]
004087be  test     ecx, ecx
004087c0  je       0x408784
004087c2  mov      eax, esi
004087c4  imul     eax, eax, 0x64
004087c7  xor      edx, edx
004087c9  div      dword ptr [ebp - 0x54]
004087cc  mov      edx, dword ptr [ecx]
004087ce  push     eax
004087cf  push     3
004087d1  push     0x8001
004087d6  push     edx
004087d7  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
004087dd  jmp      0x408784
004087df  mov      eax, dword ptr [ebx + 0x40]
004087e2  test     eax, eax
004087e4  je       0x4087f8
004087e6  mov      eax, dword ptr [eax]
004087e8  push     0
004087ea  push     4
004087ec  push     0x8001
004087f1  push     eax
004087f2  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
004087f8  mov      ecx, dword ptr [ebx + 0x108]
004087fe  mov      edi, dword ptr [ebx + 0x10c]
00408804  mov      dword ptr [ebp - 0x50], ecx
00408807  mov      dword ptr [ebp - 0x54], edi
0040880a  xor      esi, esi
0040880c  cmp      esi, edi
0040880e  jae      0x40865c
00408814  lea      edx, [ebp - 0x58]
00408817  push     edx
00408818  lea      eax, [ebp - 0x4c]
0040881b  push     eax
0040881c  mov      eax, dword ptr [ebp - 0x50]
0040881f  lea      ecx, [esi + eax]
00408822  push     ecx
00408823  push     edi
00408824  push     eax
00408825  lea      ecx, [ebx + 0x140]
0040882b  call     0x40aac0
00408830  test     eax, eax
00408832  jne      0x408881
00408834  mov      dword ptr [ebx + 0x248], 8
0040883e  mov      edx, dword ptr [ebx + 0x48]
00408841  push     -1
00408843  push     edx
00408844  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
0040884a  mov      eax, dword ptr [ebx + 0x3c]
0040884d  mov      dword ptr [ebx + 0x44], eax
00408850  test     eax, eax
00408852  je       0x40885b
00408854  mov      dword ptr [ebx + 0x3c], 0x408090
0040885b  mov      eax, dword ptr [ebx + 0x48]
0040885e  push     eax
0040885f  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
00408865  mov      ecx, dword ptr [ebp - 0xc]
00408868  mov      dword ptr fs:[0], ecx
0040886f  pop      ecx
00408870  pop      edi
00408871  pop      esi
00408872  pop      ebx
00408873  mov      ecx, dword ptr [ebp - 0x14]
00408876  xor      ecx, ebp
00408878  call     0x50bc27
0040887d  mov      esp, ebp
0040887f  pop      ebp
00408880  ret      
00408881  mov      ecx, dword ptr [ebx + 0x40]
00408884  add      esi, dword ptr [ebp - 0x58]
00408887  test     ecx, ecx
00408889  je       0x40880c
0040888b  mov      eax, esi
0040888d  imul     eax, eax, 0x64
00408890  xor      edx, edx
00408892  div      dword ptr [ebp - 0x54]
00408895  mov      ecx, dword ptr [ecx]
00408897  push     eax
00408898  push     4
0040889a  push     0x8001
0040889f  push     ecx
004088a0  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
004088a6  mov      edi, dword ptr [ebp - 0x54]
004088a9  jmp      0x40880c
004088ae  xor      esi, esi
004088b0  mov      edi, 0xe
004088b5  mov      dword ptr [ebp - 0x58], esi
004088b8  mov      dword ptr [ebp - 0x54], edi
004088bb  cmp      eax, 0x49
004088be  je       0x408962
004088c4  cmp      eax, 0x4a
004088c7  je       0x408962
004088cd  cmp      eax, 0x4b
004088d0  je       0x408962
004088d6  cmp      esi, edi
004088d8  jge      0x408918
004088da  mov      eax, dword ptr [ebx + esi*4 + 0xa8]
004088e1  cmp      eax, dword ptr [ebx + esi*4 + 0x5c]
004088e5  je       0x408915
004088e7  mov      ecx, dword ptr [ebx + 0x58]
004088ea  lea      edx, [ecx + esi*4]
004088ed  push     eax
004088ee  push     edx
004088ef  lea      ecx, [ebx + 0x140]
004088f5  call     0x40a490
004088fa  test     eax, eax
004088fc  je       0x408915
004088fe  mov      eax, dword ptr [ebx + esi*4 + 0xa8]
00408905  mov      edx, 1
0040890a  mov      ecx, esi
0040890c  shl      edx, cl
0040890e  mov      dword ptr [ebx + esi*4 + 0x5c], eax
00408912  or       dword ptr [ebp - 0x58], edx
00408915  inc      esi
00408916  jmp      0x4088d6
00408918  mov      eax, dword ptr [ebp - 0x58]
0040891b  mov      edx, dword ptr [ebp - 0x54]
0040891e  lea      esi, [ebx + 0x5c]
00408921  lea      edi, [ebx + 0xa8]
00408927  mov      ecx, 0x13
0040892c  rep movsd dword ptr es:[edi], dword ptr [esi]
0040892e  xor      ecx, ecx
00408930  cmp      ecx, edx
00408932  jge      0x408a0e
00408938  mov      esi, dword ptr [ebx + ecx*4 + 0xa8]
0040893f  cmp      esi, dword ptr [ebx + ecx*4 + 0x5c]
00408943  je       0x40895f
00408945  mov      esi, 1
0040894a  shl      esi, cl
0040894c  test     eax, esi
0040894e  je       0x40895f
00408950  mov      dword ptr [ebx + 0x248], 3
0040895a  jmp      0x408c32
0040895f  inc      ecx
00408960  jmp      0x408930
00408962  mov      dword ptr [ebp - 0x54], 0x13
00408969  lea      esp, [esp]
00408970  cmp      esi, dword ptr [ebp - 0x54]
00408973  jge      0x4089d4
00408975  mov      edx, dword ptr [ebx + esi*4 + 0xa8]
0040897c  lea      edi, [esi + 1]
0040897f  or       eax, 0xffffffff
00408982  cmp      edi, dword ptr [ebp - 0x54]
00408985  jge      0x40898e
00408987  mov      eax, dword ptr [ebx + esi*4 + 0xac]
0040898e  xor      ecx, ecx
00408990  cmp      esi, 0x10
00408993  jl       0x40899a
00408995  mov      ecx, 0x40
0040899a  push     eax
0040899b  push     edx
0040899c  mov      edx, dword ptr [ebx + 0x58]
0040899f  lea      eax, [edx + esi*4]
004089a2  add      eax, ecx
004089a4  push     eax
004089a5  lea      ecx, [ebx + 0x140]
004089ab  call     0x40a5c0
004089b0  test     eax, eax
004089b2  je       0x4089cf
004089b4  mov      ecx, dword ptr [ebx + esi*4 + 0xa8]
004089bb  mov      dword ptr [ebx + esi*4 + 0x5c], ecx
004089bf  cmp      edi, dword ptr [ebp - 0x54]
004089c2  jge      0x4089cf
004089c4  mov      edx, dword ptr [ebx + esi*4 + 0xac]
004089cb  mov      dword ptr [ebx + esi*4 + 0x60], edx
004089cf  add      esi, 2
004089d2  jmp      0x408970
004089d4  lea      esi, [ebx + 0x5c]
004089d7  lea      edi, [ebx + 0xa8]
004089dd  mov      ecx, 0x13
004089e2  rep movsd dword ptr es:[edi], dword ptr [esi]
004089e4  xor      eax, eax
004089e6  mov      ecx, 0x13
004089eb  cmp      eax, ecx
004089ed  jge      0x408a0e
004089ef  mov      ecx, dword ptr [ebx + eax*4 + 0xa8]
004089f6  cmp      ecx, dword ptr [ebx + eax*4 + 0x5c]
004089fa  je       0x408a0b
004089fc  mov      dword ptr [ebx + 0x248], 3
00408a06  jmp      0x40883e
00408a0b  inc      eax
00408a0c  jmp      0x4089e6
00408a0e  push     0x14
00408a10  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
00408a16  cmp      dword ptr [ebx + 0x124], 0
00408a1d  jne      0x408a2c
00408a1f  cmp      dword ptr [ebx + 0x120], 0
00408a26  je       0x408aaf
00408a2c  cmp      dword ptr [ebx + 0x118], 0
00408a33  jne      0x408a3e
00408a35  cmp      dword ptr [ebx + 0x11c], 0
00408a3c  je       0x408aaf
00408a3e  mov      ecx, dword ptr [ebx + 0x60]
00408a41  mov      edx, dword ptr [ebx + 0x5c]
00408a44  mov      eax, dword ptr [ebx + 0x54]
00408a47  push     ecx
00408a48  push     edx
00408a49  push     eax
00408a4a  call     0x40b100
00408a4f  add      esp, 0xc
00408a52  test     al, al
00408a54  je       0x408a9b
00408a56  mov      eax, dword ptr [0x589a94]
00408a5b  mov      dword ptr [ebx + 0xf8], eax
00408a61  mov      ecx, dword ptr [0x589a98]
00408a67  mov      dword ptr [ebx + 0xfc], ecx
00408a6d  mov      edx, dword ptr [0x589a9c]
00408a73  mov      dword ptr [ebx + 0x100], edx
00408a79  mov      eax, dword ptr [0x589aa4]
00408a7e  mov      dword ptr [ebx + 0x10c], eax
00408a84  mov      ecx, dword ptr [0x589aa0]
00408a8a  mov      dword ptr [ebx + 0x108], ecx
00408a90  mov      edx, dword ptr [0x589aa8]
00408a96  mov      dword ptr [ebx + 0x58], edx
00408a99  jmp      0x408aaf
00408a9b  mov      eax, dword ptr [0x589aa0]
00408aa0  mov      dword ptr [ebx + 0x108], eax
00408aa6  mov      ecx, dword ptr [0x589aa8]
00408aac  mov      dword ptr [ebx + 0x58], ecx
00408aaf  cmp      dword ptr [ebx + 0x118], 0
00408ab6  je       0x408b93
00408abc  mov      eax, dword ptr [ebx + 0x10]
00408abf  mov      ecx, dword ptr [ebx + 0x14]
00408ac2  mov      edi, dword ptr [ebx + 0x110]
00408ac8  add      edi, dword ptr [ebx + 0xf4]
00408ace  mov      edx, dword ptr [ebx + 8]
00408ad1  sub      ecx, eax
00408ad3  xor      esi, esi
00408ad5  cmp      esi, ecx
00408ad7  sbb      ecx, ecx
00408ad9  and      ecx, eax
00408adb  mov      dword ptr [ebp - 0x54], edx
00408ade  mov      dword ptr [ebp - 0x58], ecx
00408ae1  cmp      dword ptr [ebx + 0xf8], edx
00408ae7  jae      0x408af8
00408ae9  mov      dword ptr [ebx + 0x248], 6
00408af3  jmp      0x40883e
00408af8  mov      eax, dword ptr [ebx + 0x40]
00408afb  test     eax, eax
00408afd  je       0x408b11
00408aff  mov      ecx, dword ptr [eax]
00408b01  push     0
00408b03  push     4
00408b05  push     0x8001
00408b0a  push     ecx
00408b0b  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
00408b11  xor      esi, esi
00408b13  cmp      esi, dword ptr [ebp - 0x54]
00408b16  jae      0x408b8b
00408b18  cmp      dword ptr [ebx + 0x3c], 0x408540
00408b1f  jne      0x408b8b
00408b21  mov      eax, dword ptr [ebp - 0x58]
00408b24  lea      edx, [ebp - 0x50]
00408b27  push     edx
00408b28  lea      ecx, [esi + eax]
00408b2b  mov      eax, dword ptr [ebp - 0x54]
00408b2e  push     ecx
00408b2f  lea      edx, [esi + edi]
00408b32  push     edx
00408b33  push     eax
00408b34  push     edi
00408b35  lea      ecx, [ebx + 0x140]
00408b3b  call     0x40aac0
00408b40  test     eax, eax
00408b42  jne      0x408b64
00408b44  mov      ecx, dword ptr [ebx + 0x48]
00408b47  push     -1
00408b49  push     ecx
00408b4a  mov      dword ptr [ebx + 0x248], 4
00408b54  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00408b5a  mov      eax, dword ptr [ebx + 0x3c]
00408b5d  test     eax, eax
00408b5f  jmp      0x408ebe
00408b64  mov      ecx, dword ptr [ebx + 0x40]
00408b67  add      esi, dword ptr [ebp - 0x50]
00408b6a  test     ecx, ecx
00408b6c  je       0x408b13
00408b6e  mov      eax, esi
00408b70  imul     eax, eax, 0x64
00408b73  xor      edx, edx
00408b75  div      dword ptr [ebp - 0x54]
00408b78  push     eax
00408b79  mov      eax, dword ptr [ecx]
00408b7b  push     4
00408b7d  push     0x8001
00408b82  push     eax
00408b83  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
00408b89  jmp      0x408b13
00408b8b  push     0x14
00408b8d  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
00408b93  cmp      dword ptr [ebx + 0x11c], 0
00408b9a  je       0x408c8d
00408ba0  mov      ecx, dword ptr [ebx + 0x108]
00408ba6  mov      eax, dword ptr [ebx + 0x2c]
00408ba9  mov      edx, dword ptr [ebx + 0x30]
00408bac  mov      edi, dword ptr [ebx + 0x24]
00408baf  mov      dword ptr [ebp - 0x50], ecx
00408bb2  xor      ecx, ecx
00408bb4  sub      edx, eax
00408bb6  cmp      ecx, edx
00408bb8  sbb      ecx, ecx
00408bba  and      ecx, eax
00408bbc  mov      dword ptr [ebp - 0x54], edi
00408bbf  mov      dword ptr [ebp - 0x58], ecx
00408bc2  cmp      dword ptr [ebx + 0x10c], edi
00408bc8  jb       0x408ae9
00408bce  mov      eax, dword ptr [ebx + 0x40]
00408bd1  test     eax, eax
00408bd3  je       0x408be7
00408bd5  mov      ecx, dword ptr [eax]
00408bd7  push     0
00408bd9  push     4
00408bdb  push     0x8001
00408be0  push     ecx
00408be1  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
00408be7  xor      esi, esi
00408be9  lea      esp, [esp]
00408bf0  cmp      esi, edi
00408bf2  jae      0x408c85
00408bf8  cmp      dword ptr [ebx + 0x3c], 0x408540
00408bff  jne      0x408c85
00408c05  mov      eax, dword ptr [ebp - 0x58]
00408c08  lea      ecx, [esi + eax]
00408c0b  mov      eax, dword ptr [ebp - 0x50]
00408c0e  lea      edx, [ebp - 0x64]
00408c11  push     edx
00408c12  push     ecx
00408c13  lea      edx, [esi + eax]
00408c16  push     edx
00408c17  push     edi
00408c18  push     eax
00408c19  lea      ecx, [ebx + 0x140]
00408c1f  call     0x40aac0
00408c24  test     eax, eax
00408c26  jne      0x408c58
00408c28  mov      dword ptr [ebx + 0x248], 5
00408c32  mov      eax, dword ptr [ebx + 0x48]
00408c35  push     -1
00408c37  push     eax
00408c38  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00408c3e  mov      eax, dword ptr [ebx + 0x3c]
00408c41  test     eax, eax
00408c43  mov      dword ptr [ebx + 0x44], eax
00408c46  je       0x408c4f
00408c48  mov      dword ptr [ebx + 0x3c], 0x408090
00408c4f  mov      ecx, dword ptr [ebx + 0x48]
00408c52  push     ecx
00408c53  jmp      0x40885f
00408c58  mov      ecx, dword ptr [ebx + 0x40]
00408c5b  add      esi, dword ptr [ebp - 0x64]
00408c5e  test     ecx, ecx
00408c60  je       0x408bf0
00408c62  mov      eax, esi
00408c64  imul     eax, eax, 0x64
00408c67  xor      edx, edx
00408c69  div      dword ptr [ebp - 0x54]
00408c6c  mov      edx, dword ptr [ecx]
00408c6e  push     eax
00408c6f  push     4
00408c71  push     0x8001
00408c76  push     edx
00408c77  call     dword ptr [0x538884] ; USER32.dll!PostMessageW
00408c7d  mov      edi, dword ptr [ebp - 0x54]
00408c80  jmp      0x408bf0
00408c85  push     0x14
00408c87  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
00408c8d  xor      esi, esi
00408c8f  cmp      dword ptr [ebx + 0x128], esi
00408c95  je       0x408d8e
00408c9b  mov      eax, dword ptr [ebx + 0x138]
00408ca1  cmp      eax, esi
00408ca3  je       0x408cb8
00408ca5  mov      ecx, dword ptr [ebx + 0x13c]
00408cab  push     ecx
00408cac  push     eax
00408cad  lea      ecx, [ebx + 0x140]
00408cb3  call     0x40a2a0
00408cb8  push     esi
00408cb9  mov      dword ptr [ebx + 0x248], esi
00408cbf  call     0x50c2a5
00408cc4  sub      eax, dword ptr [ebp - 0x60]
00408cc7  add      esp, 4
00408cca  mov      dword ptr [ebp - 0x64], edx
00408ccd  mov      dword ptr [ebx + 0x24c], eax
00408cd3  call     0x418e64
00408cd8  xor      ecx, ecx
00408cda  cmp      eax, esi
00408cdc  setne    cl
00408cdf  cmp      ecx, esi
00408ce1  jne      0x408ced
00408ce3  push     0x80004005
00408ce8  call     0x401080
00408ced  mov      edx, dword ptr [eax]
00408cef  mov      ecx, eax
00408cf1  mov      eax, dword ptr [edx + 0xc]
00408cf4  call     eax
00408cf6  add      eax, 0x10
00408cf9  mov      dword ptr [ebp - 0x50], eax
00408cfc  mov      ecx, dword ptr [ebx + 0x24c]
00408d02  push     ecx
00408d03  mov      byte ptr [ebp - 4], 1
00408d07  push     0x53a5c0
00408d0c  lea      edx, [ebp - 0x50]
00408d0f  push     edx
00408d10  call     0x403880
00408d15  add      esp, 0xc
00408d18  mov      eax, dword ptr [ebx + 0x40]
00408d1b  cmp      eax, esi
00408d1d  je       0x408d33
00408d1f  mov      ecx, dword ptr [ebp - 0x50]
00408d22  mov      edx, dword ptr [eax]
00408d24  push     0x40
00408d26  push     0x5399ac
00408d2b  push     ecx
00408d2c  push     edx
00408d2d  call     dword ptr [0x538880] ; USER32.dll!MessageBoxW
00408d33  push     0x14
00408d35  call     dword ptr [0x538480] ; KERNEL32.dll!Sleep
00408d3b  mov      eax, dword ptr [ebx + 0x48]
00408d3e  push     -1
00408d40  push     eax
00408d41  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00408d47  mov      eax, dword ptr [ebx + 0x3c]
00408d4a  mov      dword ptr [ebx + 0x44], eax
00408d4d  cmp      eax, esi
00408d4f  je       0x408d58
00408d51  mov      dword ptr [ebx + 0x3c], 0x408030
00408d58  mov      ecx, dword ptr [ebx + 0x48]
00408d5b  push     ecx
00408d5c  call     dword ptr [0x538478] ; KERNEL32.dll!ReleaseMutex
00408d62  mov      eax, dword ptr [ebp - 0x50]
00408d65  add      eax, -0x10
00408d68  mov      byte ptr [ebp - 4], 0
00408d6c  lea      edx, [eax + 0xc]
00408d6f  or       ecx, 0xffffffff
00408d72  lock xadd dword ptr [edx], ecx
00408d76  dec      ecx
00408d77  test     ecx, ecx
00408d79  jg       0x408865
00408d7f  mov      ecx, dword ptr [eax]
00408d81  mov      edx, dword ptr [ecx]
00408d83  push     eax
00408d84  mov      eax, dword ptr [edx + 4]
00408d87  call     eax
00408d89  jmp      0x408865
00408d8e  cmp      dword ptr [ebx + 0x130], esi
00408d94  je       0x408dfa
00408d96  lea      ecx, [ebx + 0x140]
00408d9c  call     0x40a2d0
00408da1  push     esi
00408da2  mov      dword ptr [ebx + 0x248], esi
00408da8  call     0x50c2a5
00408dad  sub      eax, dword ptr [ebp - 0x60]
00408db0  add      esp, 4
00408db3  mov      dword ptr [ebp - 0x64], edx
00408db6  mov      dword ptr [ebx + 0x24c], eax
00408dbc  call     0x418e64
00408dc1  xor      ecx, ecx
00408dc3  cmp      eax, esi
00408dc5  setne    cl
00408dc8  cmp      ecx, esi
00408dca  jne      0x408dd6
00408dcc  push     0x80004005
00408dd1  call     0x401080
00408dd6  mov      edx, dword ptr [eax]
00408dd8  mov      ecx, eax
00408dda  mov      eax, dword ptr [edx + 0xc]
00408ddd  call     eax
00408ddf  add      eax, 0x10
00408de2  mov      dword ptr [ebp - 0x50], eax
00408de5  mov      ecx, dword ptr [ebx + 0x24c]
00408deb  push     ecx
00408dec  mov      byte ptr [ebp - 4], 2
00408df0  push     0x53a588
00408df5  jmp      0x408d0c
00408dfa  cmp      dword ptr [ebx + 0x12c], esi
00408e00  je       0x408e84
00408e06  mov      ecx, dword ptr [ebx + 0x134]
00408e0c  push     ecx
00408e0d  lea      ecx, [ebx + 0x140]
00408e13  call     0x40a1b0
00408e18  push     esi
00408e19  mov      dword ptr [ebx + 0x248], esi
00408e1f  call     0x50c2a5
00408e24  sub      eax, dword ptr [ebp - 0x60]
00408e27  add      esp, 4
00408e2a  mov      dword ptr [ebp - 0x64], edx
00408e2d  mov      dword ptr [ebx + 0x24c], eax
00408e33  call     0x418e64
00408e38  xor      ecx, ecx
00408e3a  cmp      eax, esi
00408e3c  setne    cl
00408e3f  cmp      ecx, esi
00408e41  jne      0x408e4d
00408e43  push     0x80004005
00408e48  call     0x401080
00408e4d  mov      edx, dword ptr [eax]
00408e4f  mov      ecx, eax
00408e51  mov      eax, dword ptr [edx + 0xc]
00408e54  call     eax
00408e56  add      eax, 0x10
00408e59  mov      dword ptr [ebp - 0x50], eax
00408e5c  mov      ecx, dword ptr [ebx + 0x24c]
00408e62  mov      edx, dword ptr [ebx + 0x134]
00408e68  push     ecx
00408e69  push     edx
00408e6a  lea      eax, [ebp - 0x50]
00408e6d  push     0x53a508
00408e72  push     eax
00408e73  mov      byte ptr [ebp - 4], 3
00408e77  call     0x403880
00408e7c  add      esp, 0x10
00408e7f  jmp      0x408d18
00408e84  cmp      dword ptr [ebx + 0x3c], 0x408540
00408e8b  jne      0x408865
00408e91  push     esi
00408e92  call     0x50c2a5
00408e97  sub      eax, dword ptr [ebp - 0x60]
00408e9a  mov      ecx, dword ptr [ebx + 0x48]
00408e9d  add      esp, 4
00408ea0  push     -1
00408ea2  push     ecx
00408ea3  mov      dword ptr [ebx + 0x24c], eax
00408ea9  mov      dword ptr [ebx + 0x248], 7
00408eb3  call     dword ptr [0x53847c] ; KERNEL32.dll!WaitForSingleObject
00408eb9  mov      eax, dword ptr [ebx + 0x3c]
00408ebc  cmp      eax, esi
00408ebe  mov      dword ptr [ebx + 0x44], eax
00408ec1  je       0x408eca
00408ec3  mov      dword ptr [ebx + 0x3c], 0x408090
00408eca  mov      edx, dword ptr [ebx + 0x48]
00408ecd  push     edx
00408ece  jmp      0x40885f
00408ed3  mov      esi, dword ptr [ebp - 0x6c]
00408ed6  mov      eax, dword ptr [esi + 0x40]
00408ed9  test     eax, eax
00408edb  je       0x408eef
00408edd  mov      eax, dword ptr [eax]
00408edf  push     0x10
00408ee1  push     0
00408ee3  push     0x53a4e0
00408ee8  push     eax
00408ee9  call     dword ptr [0x538880] ; USER32.dll!MessageBoxW
00408eef  push     0x408030
00408ef4  mov      ecx, esi
00408ef6  call     0x4081d0
00408efb  mov      eax, 0x408865
00408f00  ret      
00408f01  int3     
00408f02  int3     
00408f03  int3     
00408f04  int3     
00408f05  int3     
00408f06  int3     
00408f07  int3     
00408f08  int3     
00408f09  int3     
00408f0a  int3     
00408f0b  int3     
00408f0c  int3     
00408f0d  int3     
00408f0e  int3     
00408f0f  int3     
00408f10  push     ebp
00408f11  mov      ebp, esp
00408f13  push     esi
00408f14  mov      esi, ecx
00408f16  call     0x408490
00408f1b  test     byte ptr [ebp + 8], 1
00408f1f  je       0x408f2a
00408f21  push     esi
00408f22  call     0x41774d
00408f27  add      esp, 4
00408f2a  mov      eax, esi
00408f2c  pop      esi
00408f2d  pop      ebp
00408f2e  ret      4
00408f31  int3     
00408f32  int3     
00408f33  int3     
00408f34  int3     
00408f35  int3     
00408f36  int3     
00408f37  int3     
00408f38  int3     
00408f39  int3     
00408f3a  int3     
00408f3b  int3     
00408f3c  int3     
00408f3d  int3     
00408f3e  int3     
00408f3f  int3     
