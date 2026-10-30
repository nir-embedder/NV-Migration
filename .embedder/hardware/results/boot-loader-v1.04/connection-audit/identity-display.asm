004045b0  push     ebp
004045b1  mov      ebp, esp
004045b3  push     esi
004045b4  push     edi
004045b5  mov      edi, dword ptr [ebp + 8]
004045b8  push     edi
004045b9  push     0x3f9
004045be  mov      esi, ecx
004045c0  call     0x414cc0
004045c5  push     edi
004045c6  push     0x3f5
004045cb  mov      ecx, esi
004045cd  call     0x414cc0
004045d2  push     edi
004045d3  push     0x3f8
004045d8  mov      ecx, esi
004045da  call     0x414cc0
004045df  push     edi
004045e0  push     0x3f4
004045e5  mov      ecx, esi
004045e7  call     0x414cc0
004045ec  push     edi
004045ed  push     0x3fb
004045f2  mov      ecx, esi
004045f4  call     0x414cc0
004045f9  push     edi
004045fa  push     0x3f1
004045ff  mov      ecx, esi
00404601  call     0x414cc0
00404606  push     edi
00404607  push     0x42b
0040460c  mov      ecx, esi
0040460e  call     0x414cc0
00404613  push     edi
00404614  push     0x7d
00404616  mov      ecx, esi
00404618  call     0x414cc0
0040461d  push     edi
0040461e  push     0x81
00404623  mov      ecx, esi
00404625  call     0x414cc0
0040462a  push     edi
0040462b  push     0x83
00404630  mov      ecx, esi
00404632  call     0x414cc0
00404637  push     edi
00404638  push     0x3f2
0040463d  mov      ecx, esi
0040463f  call     0x414cc0
00404644  pop      edi
00404645  pop      esi
00404646  pop      ebp
00404647  ret      4
0040464a  int3     
0040464b  int3     
0040464c  int3     
0040464d  int3     
0040464e  int3     
0040464f  int3     
00404650  mov      eax, dword ptr [ecx]
00404652  jmp      dword ptr [eax + 0x1a4]
00404658  int3     
00404659  int3     
0040465a  int3     
0040465b  int3     
0040465c  int3     
0040465d  int3     
0040465e  int3     
0040465f  int3     
00404660  mov      eax, dword ptr [ecx]
00404662  jmp      dword ptr [eax + 0x188]
00404668  int3     
00404669  int3     
0040466a  int3     
0040466b  int3     
0040466c  int3     
0040466d  int3     
0040466e  int3     
0040466f  int3     
00404670  mov      eax, dword ptr [ecx]
00404672  jmp      dword ptr [eax + 0x198]
00404678  int3     
00404679  int3     
0040467a  int3     
0040467b  int3     
0040467c  int3     
0040467d  int3     
0040467e  int3     
0040467f  int3     
00404680  mov      eax, dword ptr [ecx]
00404682  jmp      dword ptr [eax + 0x19c]
00404688  int3     
00404689  int3     
0040468a  int3     
0040468b  int3     
0040468c  int3     
0040468d  int3     
0040468e  int3     
0040468f  int3     
00404690  mov      eax, dword ptr [ecx]
00404692  jmp      dword ptr [eax + 0x1a0]
00404698  int3     
00404699  int3     
0040469a  int3     
0040469b  int3     
0040469c  int3     
0040469d  int3     
0040469e  int3     
0040469f  int3     
004046a0  push     ebp
004046a1  mov      ebp, esp
004046a3  push     esi
004046a4  mov      esi, ecx
004046a6  call     0x4216a7
004046ab  movzx    ecx, word ptr [ebp + 8]
004046af  mov      eax, dword ptr [eax + 0xc]
004046b2  push     ecx
004046b3  push     eax
004046b4  call     dword ptr [0x5388b8] ; USER32.dll!LoadBitmapW
004046ba  push     eax
004046bb  mov      ecx, esi
004046bd  call     0x42240c
004046c2  pop      esi
004046c3  pop      ebp
004046c4  ret      4
004046c7  int3     
004046c8  int3     
004046c9  int3     
004046ca  int3     
004046cb  int3     
004046cc  int3     
004046cd  int3     
004046ce  int3     
004046cf  int3     
004046d0  push     ebp
004046d1  mov      ebp, esp
004046d3  mov      eax, dword ptr [ebp + 8]
004046d6  push     esi
004046d7  mov      esi, ecx
004046d9  test     eax, eax
004046db  jne      0x4046f1
004046dd  push     eax
004046de  call     dword ptr [0x5381c0] ; GDI32.dll!CreateCompatibleDC
004046e4  push     eax
004046e5  mov      ecx, esi
004046e7  call     0x422138
004046ec  pop      esi
004046ed  pop      ebp
004046ee  ret      4
004046f1  mov      eax, dword ptr [eax + 4]
004046f4  push     eax
004046f5  call     dword ptr [0x5381c0] ; GDI32.dll!CreateCompatibleDC
004046fb  push     eax
004046fc  mov      ecx, esi
004046fe  call     0x422138
00404703  pop      esi
00404704  pop      ebp
00404705  ret      4
00404708  int3     
00404709  int3     
0040470a  int3     
0040470b  int3     
0040470c  int3     
0040470d  int3     
0040470e  int3     
0040470f  int3     
00404710  push     ebp
00404711  mov      ebp, esp
00404713  mov      eax, dword ptr [ebp + 8]
00404716  mov      edx, dword ptr [eax + 4]
00404719  push     esi
0040471a  mov      esi, dword ptr [eax]
0040471c  push     edi
0040471d  mov      edi, dword ptr [ebp + 0xc]
00404720  push     edi
00404721  mov      edi, dword ptr [eax + 0xc]
00404724  mov      eax, dword ptr [eax + 8]
00404727  sub      edi, edx
00404729  push     edi
0040472a  sub      eax, esi
0040472c  push     eax
0040472d  push     edx
0040472e  push     esi
0040472f  call     0x41a212
00404734  pop      edi
00404735  pop      esi
00404736  pop      ebp
00404737  ret      8
0040473a  int3     
0040473b  int3     
0040473c  int3     
0040473d  int3     
0040473e  int3     
0040473f  int3     
00404740  push     ebp
00404741  mov      ebp, esp
00404743  push     esi
00404744  mov      esi, ecx
00404746  call     0x423587
0040474b  test     byte ptr [ebp + 8], 1
0040474f  je       0x40475a
00404751  push     esi
00404752  call     0x41774d
00404757  add      esp, 4
0040475a  mov      eax, esi
0040475c  pop      esi
0040475d  pop      ebp
0040475e  ret      4
00404761  int3     
00404762  int3     
00404763  int3     
00404764  int3     
00404765  int3     
00404766  int3     
00404767  int3     
00404768  int3     
00404769  int3     
0040476a  int3     
0040476b  int3     
0040476c  int3     
0040476d  int3     
0040476e  int3     
0040476f  int3     
00404770  push     ebp
00404771  mov      ebp, esp
00404773  push     esi
00404774  mov      esi, ecx
00404776  call     0x4236c5
0040477b  test     byte ptr [ebp + 8], 1
0040477f  je       0x40478a
00404781  push     esi
00404782  call     0x41774d
00404787  add      esp, 4
0040478a  mov      eax, esi
0040478c  pop      esi
0040478d  pop      ebp
0040478e  ret      4
00404791  int3     
00404792  int3     
00404793  int3     
00404794  int3     
00404795  int3     
00404796  int3     
00404797  int3     
00404798  int3     
00404799  int3     
0040479a  int3     
0040479b  int3     
0040479c  int3     
0040479d  int3     
0040479e  int3     
0040479f  int3     
004047a0  push     ebp
004047a1  mov      ebp, esp
004047a3  push     esi
004047a4  mov      esi, ecx
004047a6  call     0x423c59
004047ab  test     byte ptr [ebp + 8], 1
004047af  je       0x4047ba
004047b1  push     esi
004047b2  call     0x41774d
004047b7  add      esp, 4
004047ba  mov      eax, esi
004047bc  pop      esi
004047bd  pop      ebp
004047be  ret      4
004047c1  int3     
004047c2  int3     
004047c3  int3     
004047c4  int3     
004047c5  int3     
004047c6  int3     
004047c7  int3     
004047c8  int3     
004047c9  int3     
004047ca  int3     
004047cb  int3     
004047cc  int3     
004047cd  int3     
004047ce  int3     
004047cf  int3     
004047d0  push     ebp
004047d1  mov      ebp, esp
004047d3  push     esi
004047d4  mov      esi, ecx
004047d6  call     0x423d59
004047db  test     byte ptr [ebp + 8], 1
004047df  je       0x4047ea
004047e1  push     esi
004047e2  call     0x41774d
004047e7  add      esp, 4
004047ea  mov      eax, esi
004047ec  pop      esi
004047ed  pop      ebp
004047ee  ret      4
004047f1  int3     
004047f2  int3     
004047f3  int3     
004047f4  int3     
004047f5  int3     
004047f6  int3     
004047f7  int3     
004047f8  int3     
004047f9  int3     
004047fa  int3     
004047fb  int3     
004047fc  int3     
004047fd  int3     
004047fe  int3     
004047ff  int3     
00404800  push     ebp
00404801  mov      ebp, esp
00404803  push     ecx
00404804  push     ebx
00404805  push     esi
00404806  push     edi
00404807  push     0
00404809  push     0
0040480b  mov      ebx, ecx
0040480d  mov      eax, dword ptr [ebx + 0x66c]
00404813  push     0x130b
00404818  push     eax
00404819  call     dword ptr [0x5388ac] ; USER32.dll!SendMessageW
0040481f  mov      dword ptr [ebp - 4], eax
00404822  xor      esi, esi
00404824  lea      edi, [ebx + 0x734]
0040482a  lea      ebx, [ebx]
00404830  cmp      esi, eax
00404832  je       0x404840
00404834  mov      ecx, dword ptr [edi]
00404836  push     0
00404838  call     0x41a252
0040483d  mov      eax, dword ptr [ebp - 4]
00404840  inc      esi
00404841  add      edi, 4
00404844  cmp      esi, 2
00404847  jb       0x404830
00404849  mov      ecx, dword ptr [ebx + eax*4 + 0x734]
00404850  push     5
00404852  call     0x41a252
00404857  mov      eax, dword ptr [ebp + 0xc]
0040485a  pop      edi
0040485b  pop      esi
0040485c  pop      ebx
0040485d  test     eax, eax
0040485f  je       0x404867
00404861  mov      dword ptr [eax], 0
00404867  mov      esp, ebp
00404869  pop      ebp
0040486a  ret      8
0040486d  int3     
0040486e  int3     
0040486f  int3     
