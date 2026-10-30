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
0040adbf  je       0x40ade8
0040adc1  push     1
0040adc3  push     0x2ee0
0040adc8  push     0xaa
0040adcd  push     0xaa
0040add2  push     0x61a80
0040add7  call     0x40a760
0040addc  test     eax, eax
0040adde  jne      0x40ae07
0040ade0  pop      edi
0040ade1  xor      eax, eax
0040ade3  pop      esi
0040ade4  pop      ebp
0040ade5  ret      8
0040ade8  push     0
0040adea  push     0x9c40
0040adef  push     0xaa
0040adf4  push     0xaa
0040adf9  push     0x61a80
0040adfe  call     0x40a760
0040ae03  test     eax, eax
0040ae05  je       0x40ade0
0040ae07  cmp      dword ptr [esi + 0x90], 5
0040ae0e  jne      0x40ae36
0040ae10  mov      ecx, esi
0040ae12  test     edi, edi
0040ae14  je       0x40ae1a
0040ae16  push     1
0040ae18  jmp      0x40ae1c
0040ae1a  push     0
0040ae1c  push     0
0040ae1e  push     0xaa
0040ae23  push     0x7812
0040ae28  push     0x3d090
0040ae2d  call     0x40a760
0040ae32  test     eax, eax
0040ae34  je       0x40ade0
0040ae36  mov      ecx, esi
0040ae38  call     0x40a6f0
0040ae3d  pop      edi
0040ae3e  pop      esi
0040ae3f  pop      ebp
0040ae40  ret      8
0040ae43  int3     
0040ae44  int3     
0040ae45  int3     
0040ae46  int3     
0040ae47  int3     
0040ae48  int3     
0040ae49  int3     
0040ae4a  int3     
0040ae4b  int3     
0040ae4c  int3     
0040ae4d  int3     
0040ae4e  int3     
0040ae4f  int3     
0040ae50  push     ebp
0040ae51  mov      ebp, esp
0040ae53  mov      ecx, dword ptr [ebp + 8]
0040ae56  xor      edx, edx
0040ae58  xor      eax, eax
0040ae5a  lea      ebx, [ebx]
0040ae60  cmp      dword ptr [eax + 0x582514], ecx
0040ae66  je       0x40ae77
0040ae68  add      eax, 0x1c
0040ae6b  inc      edx
0040ae6c  cmp      eax, 0x94c
0040ae71  jb       0x40ae60
0040ae73  xor      eax, eax
0040ae75  pop      ebp
0040ae76  ret      
0040ae77  mov      eax, dword ptr [ebp + 0xc]
0040ae7a  push     esi
0040ae7b  push     edi
0040ae7c  lea      esi, [edx*8]
0040ae83  sub      esi, edx
0040ae85  lea      esi, [esi*4 + 0x582500]
0040ae8c  mov      ecx, 7
0040ae91  mov      edi, eax
0040ae93  rep movsd dword ptr es:[edi], dword ptr [esi]
0040ae95  pop      edi
0040ae96  pop      esi
0040ae97  cmp      edx, 0x55
0040ae9a  jb       0x40ae9e
0040ae9c  xor      eax, eax
0040ae9e  pop      ebp
0040ae9f  ret      
0040aea0  push     ebp
0040aea1  mov      ebp, esp
0040aea3  mov      ecx, dword ptr [ebp + 0x14]
0040aea6  test     cl, cl
0040aea8  jne      0x40af01
0040aeaa  test     byte ptr [ebp + 8], 1
0040aeae  mov      edx, dword ptr [ebp + 0x18]
0040aeb1  push     esi
0040aeb2  jne      0x40aee6
0040aeb4  shr      ecx, 8
0040aeb7  add      ecx, 9
0040aeba  mov      eax, 1
0040aebf  shl      eax, cl
0040aec1  mov      ecx, dword ptr [ebp + 0x10]
0040aec4  dec      eax
0040aec5  not      eax
0040aec7  and      eax, dword ptr [ebp + 0xc]
0040aeca  and      eax, 0xffffff
0040aecf  cmp      eax, edx
0040aed1  jbe      0x40aee0
0040aed3  lea      esi, [ecx + edx]
0040aed6  cmp      eax, esi
0040aed8  ja       0x40aee0
0040aeda  sub      eax, edx
0040aedc  sub      ecx, eax
0040aede  jmp      0x40aeeb
0040aee0  mov      eax, ecx
0040aee2  sub      ecx, eax
0040aee4  jmp      0x40aeeb
0040aee6  mov      eax, dword ptr [ebp + 0x10]
0040aee9  xor      ecx, ecx
0040aeeb  mov      esi, dword ptr [ebp + 0x1c]
0040aeee  add      edx, eax
0040aef0  mov      dword ptr [esi], edx
0040aef2  mov      edx, dword ptr [ebp + 0x20]
0040aef5  mov      dword ptr [edx], eax
0040aef7  mov      eax, dword ptr [ebp + 0x24]
0040aefa  mov      dword ptr [eax], ecx
0040aefc  mov      al, 1
0040aefe  pop      esi
0040aeff  pop      ebp
0040af00  ret      
0040af01  xor      al, al
0040af03  pop      ebp
0040af04  ret      
0040af05  int3     
0040af06  int3     
0040af07  int3     
0040af08  int3     
0040af09  int3     
0040af0a  int3     
0040af0b  int3     
0040af0c  int3     
0040af0d  int3     
0040af0e  int3     
0040af0f  int3     
0040af10  push     ebp
0040af11  mov      ebp, esp
0040af13  sub      esp, 0x24
0040af16  mov      eax, dword ptr [0x588250]
0040af1b  xor      eax, ebp
0040af1d  mov      dword ptr [ebp - 4], eax
0040af20  mov      eax, dword ptr [ebp + 8]
0040af23  mov      dword ptr [ebp - 0x24], eax
0040af26  cmp      dword ptr [0x589a70], eax
0040af2c  jne      0x40af3e
0040af2e  mov      al, 1
0040af30  mov      ecx, dword ptr [ebp - 4]
0040af33  xor      ecx, ebp
0040af35  call     0x50bc27
0040af3a  mov      esp, ebp
0040af3c  pop      ebp
0040af3d  ret      
0040af3e  push     ebx
0040af3f  mov      ebx, dword ptr [0x53aa0c]
0040af45  push     esi
0040af46  mov      esi, dword ptr [0x53aa04]
0040af4c  push     edi
0040af4d  mov      edi, dword ptr [0x53aa08]
0040af53  push     0xa0
0040af58  push     0
0040af5a  push     0x589a70
0040af5f  call     0x50c310
0040af64  mov      al, byte ptr [0x53aa10]
0040af69  mov      ecx, dword ptr [0x582e70]
0040af6f  mov      dword ptr [0x589ab4], ebx
0040af75  mov      byte ptr [0x589ab8], al
0040af7a  xor      ebx, ebx
0040af7c  add      esp, 0xc
0040af7f  xor      eax, eax
0040af81  mov      dword ptr [0x589aac], esi
0040af87  mov      dword ptr [0x589ab0], edi
0040af8d  mov      dword ptr [0x589a84], ebx
0040af93  cmp      ecx, -1
0040af96  je       0x40afe1
0040af98  mov      edx, dword ptr [ebp - 0x24]
0040af9b  cmp      ecx, edx
0040af9d  je       0x40afb1
0040af9f  inc      eax
0040afa0  lea      ecx, [eax + eax*4]
0040afa3  mov      ecx, dword ptr [ecx*8 + 0x582e70]
0040afaa  cmp      ecx, -1
0040afad  jne      0x40af98
0040afaf  jmp      0x40afe4
0040afb1  lea      eax, [eax + eax*4]
0040afb4  add      eax, eax
0040afb6  add      eax, eax
0040afb8  mov      ecx, dword ptr [eax + eax + 0x582e74]
0040afbf  add      eax, eax
0040afc1  mov      dword ptr [0x589a74], ecx
0040afc7  lea      esi, [eax + 0x582e50]
0040afcd  mov      ecx, 8
0040afd2  mov      edi, 0x589aac
0040afd7  mov      dword ptr [0x589a70], edx
0040afdd  rep movsd dword ptr es:[edi], dword ptr [esi]
0040afdf  jmp      0x40afe4
0040afe1  mov      edx, dword ptr [ebp - 0x24]
0040afe4  xor      eax, eax
0040afe6  mov      dword ptr [ebp - 0x1c], eax
0040afe9  mov      dword ptr [ebp - 0x18], eax
0040afec  mov      dword ptr [ebp - 0x14], eax
0040afef  mov      dword ptr [ebp - 0x10], eax
0040aff2  mov      dword ptr [ebp - 0xc], eax
0040aff5  mov      dword ptr [ebp - 8], eax
0040aff8  lea      eax, [ebp - 0x20]
0040affb  push     eax
0040affc  push     edx
0040affd  mov      dword ptr [ebp - 0x20], ebx
0040b000  call     0x40ae50
0040b005  add      esp, 8
0040b008  test     eax, eax
0040b00a  jne      0x40b01f
0040b00c  pop      edi
0040b00d  pop      esi
0040b00e  xor      al, al
0040b010  pop      ebx
0040b011  mov      ecx, dword ptr [ebp - 4]
0040b014  xor      ecx, ebp
0040b016  call     0x50bc27
0040b01b  mov      esp, ebp
0040b01d  pop      ebp
0040b01e  ret      
0040b01f  mov      edx, dword ptr [ebp - 0x10]
0040b022  mov      eax, dword ptr [0x589a74]
0040b027  mov      ecx, dword ptr [ebp - 0x20]
0040b02a  mov      dword ptr [0x589aa4], edx
0040b030  xor      edx, edx
0040b032  cmp      eax, 0x44
0040b035  setne    dl
0040b038  mov      dword ptr [0x589a78], ecx
0040b03e  mov      dword ptr [0x589a94], ecx
0040b044  mov      ecx, dword ptr [ebp - 0x14]
0040b047  mov      dword ptr [0x589a98], ecx
0040b04d  mov      ecx, dword ptr [ebp - 0x1c]
0040b050  mov      dword ptr [0x589a9c], ecx
0040b056  dec      edx
0040b057  and      edx, 0x100000
0040b05d  mov      dword ptr [0x589a90], edx
0040b063  xor      edx, edx
0040b065  cmp      ecx, ebx
0040b067  setne    dl
0040b06a  mov      dword ptr [0x589a84], 2
0040b074  mov      esi, 0x100000
0040b079  mov      edi, 0x300000
0040b07e  mov      ecx, edx
0040b080  cmp      eax, 0x49
0040b083  je       0x40b0c0
0040b085  cmp      eax, 0x4a
0040b088  je       0x40b0c0
0040b08a  cmp      eax, 0x3d
0040b08d  je       0x40b0b8
0040b08f  cmp      eax, 0x40
0040b092  je       0x40b0b8
0040b094  cmp      eax, 0x42
0040b097  je       0x40b0b0
0040b099  cmp      eax, 0x43
0040b09c  je       0x40b0b0
0040b09e  cmp      eax, 0x44
0040b0a1  je       0x40b0a8
0040b0a3  cmp      eax, 0x4b
0040b0a6  jne      0x40b0d0
0040b0a8  or       ecx, 0x400
0040b0ae  jmp      0x40b0c6
0040b0b0  or       ecx, 0x300
0040b0b6  jmp      0x40b0c6
0040b0b8  or       ecx, 0x300
0040b0be  jmp      0x40b0d0
0040b0c0  or       ecx, 0x100
0040b0c6  mov      esi, 0xf100000
0040b0cb  mov      edi, 0xf300000
0040b0d0  mov      dword ptr [0x589a80], ecx
0040b0d6  mov      ecx, dword ptr [ebp - 4]
0040b0d9  mov      dword ptr [0x589aa8], edi
0040b0df  pop      edi
0040b0e0  mov      dword ptr [0x589aa0], esi
0040b0e6  pop      esi
0040b0e7  xor      ecx, ebp
0040b0e9  mov      al, 1
0040b0eb  pop      ebx
0040b0ec  call     0x50bc27
0040b0f1  mov      esp, ebp
0040b0f3  pop      ebp
0040b0f4  ret      
0040b0f5  int3     
0040b0f6  int3     
0040b0f7  int3     
0040b0f8  int3     
0040b0f9  int3     
0040b0fa  int3     
0040b0fb  int3     
0040b0fc  int3     
0040b0fd  int3     
0040b0fe  int3     
0040b0ff  int3     
0040b100  push     ebp
0040b101  mov      ebp, esp
0040b103  mov      eax, dword ptr [ebp + 8]
0040b106  sub      esp, 8
0040b109  cmp      dword ptr [0x589a70], eax
0040b10f  jne      0x40b12d
0040b111  mov      ecx, dword ptr [ebp + 0xc]
0040b114  cmp      dword ptr [0x589a88], ecx
0040b11a  jne      0x40b12d
0040b11c  mov      edx, dword ptr [ebp + 0x10]
0040b11f  cmp      dword ptr [0x589a8c], edx
0040b125  jne      0x40b12d
0040b127  mov      al, 1
0040b129  mov      esp, ebp
0040b12b  pop      ebp
0040b12c  ret      
0040b12d  push     ebx
0040b12e  push     esi
0040b12f  push     edi
0040b130  push     eax
0040b131  xor      ebx, ebx
0040b133  xor      esi, esi
0040b135  xor      edi, edi
0040b137  call     0x40af10
0040b13c  add      esp, 4
0040b13f  test     al, al
0040b141  je       0x40b155
0040b143  mov      ebx, dword ptr [0x589a84]
0040b149  mov      esi, dword ptr [0x589a78]
0040b14f  mov      edi, dword ptr [0x589a80]
0040b155  xor      eax, eax
0040b157  mov      dword ptr [ebp + 8], eax
0040b15a  mov      dword ptr [ebp - 4], eax
0040b15d  mov      dword ptr [ebp - 8], eax
0040b160  cmp      ebx, 2
0040b163  jne      0x40b1bc
0040b165  lea      eax, [ebp - 8]
0040b168  push     eax
0040b169  mov      eax, dword ptr [0x589a90]
0040b16e  lea      ecx, [ebp + 8]
0040b171  push     ecx
0040b172  lea      edx, [ebp - 4]
0040b175  push     edx
0040b176  push     eax
0040b177  push     edi
0040b178  mov      edi, dword ptr [ebp + 0xc]
0040b17b  push     esi
0040b17c  mov      esi, dword ptr [ebp + 0x10]
0040b17f  push     esi
0040b180  push     edi
0040b181  call     0x40aea0
0040b186  add      esp, 0x20
0040b189  test     al, al
0040b18b  je       0x40b1a7
0040b18d  mov      ecx, dword ptr [ebp + 8]
0040b190  mov      edx, dword ptr [ebp - 4]
0040b193  mov      eax, dword ptr [ebp - 8]
0040b196  mov      dword ptr [0x589a94], ecx
0040b19c  mov      dword ptr [0x589a98], edx
0040b1a2  mov      dword ptr [0x589a9c], eax
0040b1a7  mov      dword ptr [0x589a88], edi
0040b1ad  pop      edi
0040b1ae  mov      dword ptr [0x589a8c], esi
0040b1b4  pop      esi
0040b1b5  mov      al, 1
0040b1b7  pop      ebx
0040b1b8  mov      esp, ebp
0040b1ba  pop      ebp
0040b1bb  ret      
0040b1bc  pop      edi
0040b1bd  pop      esi
0040b1be  xor      al, al
0040b1c0  pop      ebx
0040b1c1  mov      esp, ebp
0040b1c3  pop      ebp
0040b1c4  ret      
0040b1c5  int3     
0040b1c6  int3     
0040b1c7  int3     
0040b1c8  int3     
0040b1c9  int3     
0040b1ca  int3     
0040b1cb  int3     
0040b1cc  int3     
0040b1cd  int3     
0040b1ce  int3     
0040b1cf  int3     
0040b1d0  push     ebp
0040b1d1  mov      ebp, esp
0040b1d3  mov      eax, dword ptr [ebp + 0x10]
0040b1d6  mov      ecx, dword ptr [ebp + 0xc]
0040b1d9  mov      edx, dword ptr [ebp + 8]
0040b1dc  push     eax
0040b1dd  push     ecx
0040b1de  push     edx
0040b1df  call     0x40b100
0040b1e4  mov      eax, dword ptr [0x589a80]
0040b1e9  add      esp, 0xc
0040b1ec  pop      ebp
0040b1ed  ret      
0040b1ee  int3     
0040b1ef  int3     
0040b1f0  mov      eax, dword ptr [0x589a74]
0040b1f5  ret      
0040b1f6  int3     
0040b1f7  int3     
0040b1f8  int3     
0040b1f9  int3     
0040b1fa  int3     
0040b1fb  int3     
0040b1fc  int3     
0040b1fd  int3     
0040b1fe  int3     
0040b1ff  int3     
0040b200  mov      eax, 0x53aa54
0040b205  ret      
0040b206  int3     
0040b207  int3     
0040b208  int3     
0040b209  int3     
0040b20a  int3     
0040b20b  int3     
0040b20c  int3     
0040b20d  int3     
0040b20e  int3     
0040b20f  int3     
0040b210  push     ebp
0040b211  mov      ebp, esp
0040b213  push     esi
0040b214  push     edi
0040b215  mov      edi, dword ptr [ebp + 8]
0040b218  push     edi
0040b219  mov      esi, ecx
0040b21b  call     0x409620
0040b220  lea      eax, [esi + 0xb8]
0040b226  push     eax
0040b227  push     0xc45
0040b22c  push     edi
0040b22d  call     0x4192fc
0040b232  lea      ecx, [esi + 0xbc]
0040b238  push     ecx
0040b239  push     0xbe7
0040b23e  push     edi
0040b23f  call     0x4192fc
0040b244  lea      edx, [esi + 0xc0]
0040b24a  push     edx
0040b24b  push     0xbfa
0040b250  push     edi
0040b251  call     0x4192fc
0040b256  lea      eax, [esi + 0xc4]
0040b25c  push     eax
0040b25d  push     0xbd9
0040b262  push     edi
0040b263  call     0x4192fc
0040b268  lea      ecx, [esi + 0xc8]
0040b26e  push     ecx
0040b26f  push     0x795
0040b274  push     edi
0040b275  call     0x419297
0040b27a  lea      edx, [esi + 0xcc]
0040b280  push     edx
0040b281  push     0xbf1
0040b286  push     edi
0040b287  call     0x419297
0040b28c  lea      eax, [esi + 0xd0]
0040b292  push     eax
0040b293  push     0xbf0
0040b298  push     edi
0040b299  call     0x419297
0040b29e  lea      ecx, [esi + 0xd4]
0040b2a4  push     ecx
0040b2a5  push     0xc1e
0040b2aa  push     edi
0040b2ab  call     0x419297
0040b2b0  lea      edx, [esi + 0xd8]
0040b2b6  push     edx
0040b2b7  push     0x691
0040b2bc  push     edi
0040b2bd  call     0x419297
0040b2c2  lea      eax, [esi + 0xdc]
0040b2c8  push     eax
0040b2c9  push     0x43b
0040b2ce  push     edi
0040b2cf  call     0x419297
0040b2d4  lea      ecx, [esi + 0xe0]
0040b2da  push     ecx
0040b2db  push     0x43c
0040b2e0  push     edi
0040b2e1  call     0x419297
0040b2e6  lea      edx, [esi + 0xe4]
0040b2ec  push     edx
0040b2ed  push     0x43d
0040b2f2  push     edi
0040b2f3  call     0x419297
0040b2f8  lea      eax, [esi + 0xe8]
0040b2fe  push     eax
0040b2ff  push     0x43e
0040b304  push     edi
0040b305  call     0x419297
0040b30a  lea      ecx, [esi + 0xec]
0040b310  push     ecx
0040b311  push     0x43f
0040b316  push     edi
0040b317  call     0x419297
0040b31c  lea      edx, [esi + 0xf0]
0040b322  push     edx
0040b323  push     0x692
0040b328  push     edi
0040b329  call     0x41954c
0040b32e  lea      eax, [esi + 0x170]
0040b334  push     eax
0040b335  push     0x693
0040b33a  push     edi
0040b33b  call     0x41954c
0040b340  lea      ecx, [esi + 0x1f0]
0040b346  push     ecx
0040b347  push     0x692
0040b34c  push     edi
0040b34d  call     0x419660
0040b352  lea      edx, [esi + 0x1f4]
0040b358  push     edx
0040b359  push     0x693
0040b35e  push     edi
0040b35f  .byte    0xe8
