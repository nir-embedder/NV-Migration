
FUNCTION RANGE 0x40a810..0x40a89d (end exclusive)
0040a810 push     ebp
0040a811 mov      ebp, esp
0040a813 sub      esp, 0xc
0040a816 push     ebx
0040a817 push     esi
0040a818 mov      esi, 1
0040a81d push     edi
0040a81e mov      ebx, ecx
0040a820 mov      dword ptr [ebp - 4], esi
0040a823 call     0x40a6f0
0040a828 xor      edi, edi
0040a82a cmp      dword ptr [ebp + 0xc], edi
0040a82d jle      0x40a894
0040a82f nop      
0040a830 xor      eax, eax
0040a832 cmp      edi, 0x10
0040a835 jl       0x40a83c
0040a837 mov      eax, 0x10
0040a83c lea      esi, [eax + edi]
0040a83f push     0x14
0040a841 push     8
0040a843 add      esi, esi
0040a845 lea      ecx, [ebp - 0xc]
0040a848 push     ecx
0040a849 add      esi, esi
0040a84b lea      eax, [esi + 0xf300000]
0040a851 push     0xd2
0040a856 mov      ecx, ebx
0040a858 mov      dword ptr [ebp - 0xc], eax
0040a85b mov      dword ptr [ebp - 8], 4
0040a862 call     0x40a040
0040a867 test     eax, eax
0040a869 je       0x40a882
0040a86b add      esi, dword ptr [ebp + 8]
0040a86e push     0
0040a870 push     0x7530
0040a875 push     4
0040a877 push     esi
0040a878 mov      ecx, ebx
0040a87a call     0x4098d0
0040a87f and      dword ptr [ebp - 4], eax
0040a882 inc      edi
0040a883 cmp      edi, dword ptr [ebp + 0xc]
0040a886 jl       0x40a830
0040a888 mov      eax, dword ptr [ebp - 4]
0040a88b pop      edi
0040a88c pop      esi
0040a88d pop      ebx
0040a88e mov      esp, ebp
0040a890 pop      ebp
0040a891 ret      8
0040a894 pop      edi
0040a895 mov      eax, esi
0040a897 pop      esi
0040a898 pop      ebx
0040a899 mov      esp, ebp
0040a89b pop      ebp
0040a89c .byte    0xc2

FUNCTION RANGE 0x40a8a0..0x40a924 (end exclusive)
0040a8a0 push     ebp
0040a8a1 mov      ebp, esp
0040a8a3 sub      esp, 0xc
0040a8a6 push     ebx
0040a8a7 push     edi
0040a8a8 xor      edi, edi
0040a8aa mov      eax, 1
0040a8af mov      ebx, ecx
0040a8b1 mov      dword ptr [ebp - 4], eax
0040a8b4 cmp      dword ptr [ebp + 0xc], edi
0040a8b7 jle      0x40a91e
0040a8b9 push     esi
0040a8ba lea      ebx, [ebx]
0040a8c0 xor      eax, eax
0040a8c2 cmp      edi, 0x10
0040a8c5 jl       0x40a8cc
0040a8c7 mov      eax, 0x10
0040a8cc lea      esi, [eax + edi]
0040a8cf push     0x14
0040a8d1 push     8
0040a8d3 add      esi, esi
0040a8d5 lea      ecx, [ebp - 0xc]
0040a8d8 push     ecx
0040a8d9 add      esi, esi
0040a8db lea      eax, [esi + 0xf300000]
0040a8e1 push     0xd2
0040a8e6 mov      ecx, ebx
0040a8e8 mov      dword ptr [ebp - 0xc], eax
0040a8eb mov      dword ptr [ebp - 8], 8
0040a8f2 call     0x40a040
0040a8f7 test     eax, eax
0040a8f9 je       0x40a912
0040a8fb add      esi, dword ptr [ebp + 8]
0040a8fe push     0
0040a900 push     0x7530
0040a905 push     8
0040a907 push     esi
0040a908 mov      ecx, ebx
0040a90a call     0x4098d0
0040a90f and      dword ptr [ebp - 4], eax
0040a912 add      edi, 2
0040a915 cmp      edi, dword ptr [ebp + 0xc]
0040a918 jl       0x40a8c0
0040a91a mov      eax, dword ptr [ebp - 4]
0040a91d pop      esi
0040a91e pop      edi
0040a91f pop      ebx
0040a920 mov      esp, ebp
0040a922 pop      ebp
0040a923 .byte    0xc2

FUNCTION RANGE 0x4098d0..0x4099bc (end exclusive)
004098d0 push     ebp
004098d1 mov      ebp, esp
004098d3 push     esi
004098d4 mov      esi, ecx
004098d6 cmp      dword ptr [esi + 0xb0], 0
004098dd push     edi
004098de jne      0x4098f5
004098e0 push     0x5711e4
004098e5 lea      eax, [ebp + 0xc]
004098e8 push     eax
004098e9 mov      dword ptr [ebp + 0xc], 0x53a9a0
004098f0 call     0x50b72f
004098f5 mov      eax, dword ptr [esi + 0x90]
004098fb dec      eax
004098fc cmp      eax, 4
004098ff ja       0x409928
00409901 mov      edi, dword ptr [ebp + 0xc]
00409904 jmp      dword ptr [eax*4 + 0x4099bc]
0040990b mov      ecx, dword ptr [ebp + 0x10]
0040990e push     ecx
0040990f lea      edx, [ebp + 0x10]
00409912 push     edx
00409913 push     0x41
00409915 lea      eax, [esi + 4]
00409918 push     eax
00409919 lea      ecx, [esi + 0x9c]
0040991f call     0x413920
00409924 test     eax, eax
00409926 jne      0x409973
00409928 pop      edi
00409929 xor      eax, eax
0040992b pop      esi
0040992c pop      ebp
0040992d ret      0x10
00409930 mov      ecx, dword ptr [ebp + 0x10]
00409933 mov      eax, edi
00409935 neg      eax
00409937 push     ecx
00409938 sbb      eax, eax
0040993a lea      edx, [ebp + 0x10]
0040993d and      eax, 0x34
00409940 push     edx
00409941 add      eax, 0xc
00409944 push     eax
00409945 lea      ecx, [esi + 5]
00409948 push     ecx
00409949 lea      ecx, [esi + 0xa8]
0040994f call     0x415c90
00409954 jmp      0x409924
00409956 mov      edx, dword ptr [ebp + 0x10]
00409959 push     edx
0040995a lea      eax, [ebp + 0x10]
0040995d push     eax
0040995e push     0x41
00409960 lea      ecx, [esi + 4]
00409963 push     ecx
00409964 lea      ecx, [esi + 0x9c]
0040996a call     0x413920
0040996f test     eax, eax
00409971 je       0x409928
00409973 mov      eax, dword ptr [ebp + 0x10]
00409976 cmp      eax, 0xc
00409979 jb       0x409928
0040997b cmp      dword ptr [ebp + 0x14], 0
0040997f je       0x40998d
00409981 mov      edx, dword ptr [esi + 0x88]
00409987 dec      edx
00409988 cmp      dword ptr [esi + 9], edx
0040998b jne      0x409928
0040998d add      eax, -0xc
00409990 cmp      edi, eax
00409992 jbe      0x409996
00409994 mov      edi, eax
00409996 mov      eax, dword ptr [ebp + 8]
00409999 test     eax, eax
0040999b je       0x4099af
0040999d test     edi, edi
0040999f je       0x4099af
004099a1 push     edi
004099a2 add      esi, 0x11
004099a5 push     esi
004099a6 push     eax
004099a7 call     0x50ad10
004099ac add      esp, 0xc
004099af pop      edi
004099b0 mov      eax, 1
004099b5 pop      esi
004099b6 pop      ebp
004099b7 ret      0x10
004099ba mov      edi, edi

FUNCTION RANGE 0x413920..0x41399e (end exclusive)
00413920 push     ebp
00413921 mov      ebp, esp
00413923 sub      esp, 0x108
00413929 mov      eax, dword ptr [0x588250]
0041392e xor      eax, ebp
00413930 mov      dword ptr [ebp - 4], eax
00413933 mov      edx, dword ptr [ebp + 0x14]
00413936 mov      eax, dword ptr [ebp + 8]
00413939 mov      ecx, dword ptr [ecx + 4]
0041393c push     ebx
0041393d mov      ebx, dword ptr [ebp + 0x10]
00413940 push     esi
00413941 push     edi
00413942 mov      edi, dword ptr [ebp + 0xc]
00413945 push     edx
00413946 mov      dword ptr [ebp - 0x108], eax
0041394c push     edi
0041394d lea      eax, [ebp - 0x104]
00413953 push     eax
00413954 push     ecx
00413955 call     0x416b40
0041395a dec      edi
0041395b xor      edx, edx
0041395d add      esp, 0x10
00413960 mov      esi, eax
00413962 cmp      esi, edi
00413964 sete     dl
00413967 mov      edi, edx
00413969 test     edi, edi
0041396b je       0x413985
0041396d mov      ecx, dword ptr [ebp - 0x108]
00413973 push     esi
00413974 lea      eax, [ebp - 0x104]
0041397a push     eax
0041397b inc      ecx
0041397c push     ecx
0041397d call     0x50ad10
00413982 add      esp, 0xc
00413985 mov      eax, edi
00413987 test     ebx, ebx
00413989 je       0x41398d
0041398b mov      dword ptr [ebx], esi
0041398d mov      ecx, dword ptr [ebp - 4]
00413990 pop      edi
00413991 pop      esi
00413992 xor      ecx, ebp
00413994 pop      ebx
00413995 call     0x50bc27
0041399a mov      esp, ebp
0041399c pop      ebp
0041399d .byte    0xc2

FUNCTION RANGE 0x40a040..0x40a18b (end exclusive)
0040a040 push     ebp
0040a041 mov      ebp, esp
0040a043 sub      esp, 8
0040a046 push     ebx
0040a047 push     esi
0040a048 mov      esi, ecx
0040a04a xor      ebx, ebx
0040a04c push     edi
0040a04d cmp      dword ptr [esi + 0xb0], ebx
0040a053 jne      0x40a06a
0040a055 push     0x5711e4
0040a05a lea      eax, [ebp + 8]
0040a05d push     eax
0040a05e mov      dword ptr [ebp + 8], 0x53a9a0
0040a065 call     0x50b72f
0040a06a mov      edi, dword ptr [ebp + 0x10]
0040a06d cmp      edi, 0x38
0040a070 jbe      0x40a077
0040a072 mov      edi, 0x38
0040a077 push     0x41
0040a079 lea      eax, [esi + 4]
0040a07c push     ebx
0040a07d push     eax
0040a07e call     0x50c310
0040a083 mov      eax, dword ptr [ebp + 0xc]
0040a086 mov      ecx, dword ptr [ebp + 8]
0040a089 mov      edx, dword ptr [esi + 0x88]
0040a08f add      esp, 0xc
0040a092 mov      dword ptr [esi + 5], ecx
0040a095 mov      dword ptr [esi + 9], edx
0040a098 cmp      eax, ebx
0040a09a je       0x40a0ae
0040a09c cmp      edi, ebx
0040a09e jbe      0x40a0ae
0040a0a0 push     edi
0040a0a1 push     eax
0040a0a2 lea      eax, [esi + 0xd]
0040a0a5 push     eax
0040a0a6 call     0x50ad10
0040a0ab add      esp, 0xc
0040a0ae mov      dword ptr [ebp - 8], ebx
0040a0b1 mov      dword ptr [ebp + 0x10], ebx
0040a0b4 mov      dword ptr [ebp + 0xc], ebx
0040a0b7 mov      dword ptr [ebp - 4], ebx
0040a0ba lea      eax, [esi + 0xa]
0040a0bd mov      ecx, 0xf
0040a0c2 mov      dx, bx
0040a0c5 movzx    edi, byte ptr [eax - 1]
0040a0c9 add      dx, di
0040a0cc movzx    edi, byte ptr [eax]
0040a0cf add      word ptr [ebp - 4], di
0040a0d3 movzx    edi, byte ptr [eax + 1]
0040a0d7 add      word ptr [ebp + 0xc], di
0040a0db movzx    edi, byte ptr [eax + 2]
0040a0df add      word ptr [ebp + 0x10], di
0040a0e3 add      eax, 4
0040a0e6 dec      ecx
0040a0e7 jne      0x40a0c5
0040a0e9 mov      ecx, dword ptr [ebp + 0x10]
0040a0ec add      ecx, dword ptr [ebp + 0xc]
0040a0ef mov      word ptr [ebp - 8], dx
0040a0f3 add      ecx, dword ptr [ebp - 4]
0040a0f6 mov      eax, dword ptr [ebp - 8]
0040a0f9 add      eax, ecx
0040a0fb add      eax, dword ptr [ebp + 8]
0040a0fe xor      edi, edi
0040a100 mov      word ptr [esi + 0x8c], ax
0040a107 mov      word ptr [esi + 7], ax
0040a10b mov      eax, dword ptr [esi + 0x90]
0040a111 dec      eax
0040a112 cmp      eax, 4
0040a115 ja       0x40a17b
0040a117 jmp      dword ptr [eax*4 + 0x40a190]
0040a11e mov      edx, dword ptr [ebp + 0x14]
0040a121 push     edx
0040a122 lea      eax, [ebp + 0x14]
0040a125 push     eax
0040a126 jmp      0x40a154
0040a128 mov      ecx, dword ptr [ebp + 0x14]
0040a12b push     ecx
0040a12c lea      edx, [ebp + 0x14]
0040a12f push     edx
0040a130 push     0x40
0040a132 lea      eax, [esi + 5]
0040a135 push     eax
0040a136 lea      ecx, [esi + 0xa8]
0040a13c call     0x415d40
0040a141 jmp      0x40a165
0040a143 mov      ecx, dword ptr [ebp + 0x14]
0040a146 mov      al, byte ptr [esi + 0x90]
0040a14c push     ecx
0040a14d lea      edx, [ebp + 0x14]
0040a150 mov      byte ptr [esi + 6], al
0040a153 push     edx
0040a154 push     0x41
0040a156 lea      eax, [esi + 4]
0040a159 push     eax
0040a15a lea      ecx, [esi + 0x9c]
0040a160 call     0x4139a0
0040a165 mov      edi, eax
0040a167 test     edi, edi
0040a169 je       0x40a17b
0040a16b add      dword ptr [esi + 0x88], 2
0040a172 pop      edi
0040a173 pop      esi
0040a174 pop      ebx
0040a175 mov      esp, ebp
0040a177 pop      ebp
0040a178 ret      0x10
0040a17b mov      ecx, esi
0040a17d call     0x409e30
0040a182 mov      eax, edi
0040a184 pop      edi
0040a185 pop      esi
0040a186 pop      ebx
0040a187 mov      esp, ebp
0040a189 pop      ebp
0040a18a .byte    0xc2

FUNCTION RANGE 0x40a6f0..0x40a755 (end exclusive)
0040a6f0 push     esi
0040a6f1 push     edi
0040a6f2 mov      esi, ecx
0040a6f4 push     0x34
0040a6f6 lea      edi, [esi + 0xd4]
0040a6fc push     0
0040a6fe push     edi
0040a6ff call     0x50c310
0040a704 add      esp, 0xc
0040a707 push     0x14
0040a709 push     0
0040a70b push     0
0040a70d push     0xa0
0040a712 mov      ecx, esi
0040a714 call     0x40a040
0040a719 test     eax, eax
0040a71b je       0x40a750
0040a71d push     0
0040a71f push     0x1388
0040a724 push     0x34
0040a726 push     edi
0040a727 mov      ecx, esi
0040a729 call     0x4098d0
0040a72e test     eax, eax
0040a730 je       0x40a750
0040a732 cmp      dword ptr [esi + 0x104], 0x13572468
0040a73c jne      0x40a750
0040a73e pop      edi
0040a73f mov      dword ptr [esi + 0x88], 3
0040a749 mov      eax, 1
0040a74e pop      esi
0040a74f ret      
0040a750 pop      edi
0040a751 xor      eax, eax
0040a753 pop      esi
0040a754 ret      

FUNCTION RANGE 0x40a1b0..0x40a27d (end exclusive)
0040a1b0 push     ebp
0040a1b1 mov      ebp, esp
0040a1b3 push     ecx
0040a1b4 push     esi
0040a1b5 push     0x14
0040a1b7 push     4
0040a1b9 lea      eax, [ebp + 8]
0040a1bc push     eax
0040a1bd push     0xc1
0040a1c2 mov      esi, ecx
0040a1c4 call     0x40a040
0040a1c9 test     eax, eax
0040a1cb je       0x40a21c
0040a1cd cmp      dword ptr [esi + 0xb0], 0
0040a1d4 jne      0x40a1eb
0040a1d6 push     0x5711e4
0040a1db lea      ecx, [ebp - 4]
0040a1de push     ecx
0040a1df mov      dword ptr [ebp - 4], 0x53a9a0
0040a1e6 call     0x50b72f
0040a1eb mov      eax, dword ptr [esi + 0x90]
0040a1f1 dec      eax
0040a1f2 cmp      eax, 4
0040a1f5 ja       0x40a21c
0040a1f7 jmp      dword ptr [eax*4 + 0x40a280]
0040a1fe push     0x7530
0040a203 lea      edx, [ebp + 8]
0040a206 push     edx
0040a207 push     0x41
0040a209 lea      eax, [esi + 4]
0040a20c push     eax
0040a20d lea      ecx, [esi + 0x9c]
0040a213 call     0x413920
0040a218 test     eax, eax
0040a21a jne      0x40a25f
0040a21c xor      eax, eax
0040a21e pop      esi
0040a21f mov      esp, ebp
0040a221 pop      ebp
0040a222 ret      4
0040a225 push     0x7530
0040a22a lea      ecx, [ebp + 8]
0040a22d push     ecx
0040a22e push     0xc
0040a230 lea      edx, [esi + 5]
0040a233 push     edx
0040a234 lea      ecx, [esi + 0xa8]
0040a23a call     0x415c90
0040a23f jmp      0x40a218
0040a241 push     0x7530
0040a246 lea      eax, [ebp + 8]
0040a249 push     eax
0040a24a push     0x41
0040a24c lea      ecx, [esi + 4]
0040a24f push     ecx
0040a250 lea      ecx, [esi + 0x9c]
0040a256 call     0x413920
0040a25b test     eax, eax
0040a25d je       0x40a21c
0040a25f cmp      dword ptr [ebp + 8], 0xc
0040a263 jb       0x40a21c
0040a265 mov      edx, dword ptr [esi + 0x88]
0040a26b dec      edx
0040a26c cmp      dword ptr [esi + 9], edx
0040a26f jne      0x40a21c
0040a271 mov      eax, 1
0040a276 pop      esi
0040a277 mov      esp, ebp
0040a279 pop      ebp
0040a27a ret      4

FUNCTION RANGE 0x40a2a0..0x40a2c8 (end exclusive)
0040a2a0 push     ebp
0040a2a1 mov      ebp, esp
0040a2a3 sub      esp, 8
0040a2a6 mov      eax, dword ptr [ebp + 8]
0040a2a9 mov      edx, dword ptr [ebp + 0xc]
0040a2ac push     0x14
0040a2ae mov      dword ptr [ebp - 8], eax
0040a2b1 push     8
0040a2b3 lea      eax, [ebp - 8]
0040a2b6 push     eax
0040a2b7 push     0xb0
0040a2bc mov      dword ptr [ebp - 4], edx
0040a2bf call     0x40a040
0040a2c4 mov      esp, ebp
0040a2c6 pop      ebp
0040a2c7 .byte    0xc2
