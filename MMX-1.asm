;
; MMX 寄存器测试的例子
; 
;

format PE GUI
include 'win32axp.inc'

entry start

section '.data' data readable writeable

TAP equ 1

  flags dd ?
  caption db '测试',0
  message db '这是一个测试',0
  input1  dq 1111,2222,3333,4444,5555,6666,7777,8888,9999,0000,0
  out1	  dd 10 dup(?)
  coeff1  dq 0000,9999,8888,7777,6666,5555,4444,3333,2222,1111,0
  count1		dw 10
  
section '.text' code readable writeable executable

start:
;	sub rsp,8*5
	invoke	GetModuleHandle,0
	invoke	MessageBox,0,message,caption,MB_ICONINFORMATION+MB_OK
;--------------------------------------------------------------------------	
	mov eax,1
	cpuid
	test edx,00800000h		;支持MMX[bit 23=1]
	jz exit
	test edx,002000000h		;支持SSE[bit 25=1]
	jz exit
	test edx,004000000h		;支持SSE2[bit 26=1]
	jz exit
	test ecx,000000001h		;支持SSE3[bit 0=1]
	jz exit
	test ecx,000000200h		;支持SSSE3[bit 9=1]
	jz exit
	test ecx,000080000h		;支持SSE4.1 [bit 19=1]
	jz exit
	test ecx,000100000h		;支持SSE4.2 [bit 20=1]
	jz exit
	stdcall  fir,input1,out1,coeff1,count1
	invoke	MessageBox,0,'sss',caption,MB_ICONINFORMATION+MB_OK
;--------------------------------------------------------------------------	
  exit:
	invoke	ExitProcess,0
proc fir input:dword,out:dword,coeff:dword,count:dword
	pxor xmm0, xmm0
	xor ecx, ecx
	mov eax,input1
	mov ebx,coeff1
inner_loop:
	movups xmm1,[eax+ecx]
	mulss xmm1,[ebx+4*ecx]
	addps xmm0, xmm1
	pxor xmm0, xmm0
	xor ecx, ecx
	mov eax,input1
	mov ebx,coeff1

	movups xmm1,[eax+ecx]			;
	movaps xmm3, xmm1
	mulss xmm1,[ebx+4*ecx]
	addps xmm0, xmm1
	movups xmm1,[eax+ecx+4]
	mulss xmm1,[ebx+4*ecx+16]
	addps xmm0, xmm1
	movups xmm2,[eax+ecx+16]
	movups xmm1, xmm2
	palignr xmm2, xmm3, 4
	mulss xmm2,[ebx+4*ecx+16]
	addps xmm0, xmm2
	movups xmm1,[eax+ecx+8]
	mulss xmm1,[ebx+4*ecx+32]
	addps xmm0, xmm1
	movups xmm2, xmm1
	palignr xmm2, xmm3, 8
	mulss xmm2,[ebx+4*ecx+32]
	addps xmm0, xmm2
	movups xmm1,[eax+ecx+12]
	mulss xmm1,[ebx+4*ecx+48]
	addps xmm0, xmm1
	add ecx, 16
	cmp ecx, 4*TAP
	jl inner_loop
	mov eax,out1
	movups [eax], xmm1
	
	pxor xmm0, xmm0
	xor ecx, ecx
	mov eax, input1
	mov ebx, coeff1
inner_loop1:
	movups xmm1, [eax+ecx]
	movups xmm3, xmm1
	mulss xmm1, [ebx+4*ecx]
	addps xmm0, xmm1
	
	movups xmm2, [eax+ecx+16]
	movups xmm1, xmm2
	palignr xmm2, xmm3, 4
	mulss xmm2, [ebx+4*ecx+16]
	addps xmm0, xmm2

	movups xmm2, xmm1
	palignr xmm2, xmm3, 8
	mulss xmm2, [ebx+4*ecx+32]
	addps xmm0, xmm2

	movups xmm2, xmm1
	palignr xmm2, xmm3, 12
	mulss xmm2, [ebx+4*ecx+48]
	addps xmm0, xmm2
	add ecx, 16
	cmp ecx, 4*TAP
	jl inner_loop1
	mov eax, out1
	movups [eax], xmm0
p_exit:
	ret
endp


section '.idata' import data readable writeable
        library kernel,'KERNEL32.DLL',\
                user,'USER32.DLL'

        import  kernel,\
                GetModuleHandle,'GetModuleHandleA',\
                ExitProcess,'ExitProcess'

        import  user,\
                MessageBox,'MessageBoxA',\
                wsprintf,'wsprintfA'
                   
