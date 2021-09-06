
data segment
_title db 'CMOS Reader ver 1.00',0dh,0ah,
'Author Jacky fu',0dh,0ah,
'Base CMOS Buffer',0dh,0ah,
' 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F',0dh,0ah,
' -----------------------------------------------',0dh,0ah,'$'
counter db 00h
_high db 'High CMOS Buffer',0dh,0ah,'$'
data ends

code segment
assume cs:code,ds:data,es:data
start:
mov ax,data		; 数据段定义
mov ds,ax
xor ax,ax

lea dx,_title		;显示程序提示
mov ah,09h
int 21h

mov cx,00h
loop2:
mov dl,cl
call printdl
mov dl,':'
mov ah,02h
int 21h
call fun2
inc cx
cmp cl,10h
jl loop2

lea dx,_high
mov ah,09h
int 21h

mov cx,00h
mov counter,00h
loop3:
mov dl,cl
call printdl
mov dl,':'
mov ah,02h
int 21h
call fun3
inc cx
cmp cl,10h
jl loop3


mov ah,4ch
int 21h

fun4 proc near
push dx
push ax

mov dx,72h
mov al,counter
out dx,al
mov dx,73h
in al,dx
mov dl,al
call printdl
add counter,1

pop dx
pop ax
ret
fun4 endp

fun3 proc near
push cx
push dx
push ax
mov cl,00h
loop4:
call fun4
inc cl
cmp cl,10h
jl loop4
mov dl,0dh
mov ah,02h
int 21h
mov dl,0ah
int 21h
pop ax
pop dx
pop cx
ret
fun3 endp

fun2 proc near
push cx
push dx
push ax
mov cl,00h
loop1:
call fun1
inc cl
cmp cl,10h
jl loop1
mov dl,0dh
mov ah,02h
int 21h
mov dl,0ah
int 21h
pop ax
pop dx
pop cx
ret
fun2 endp

fun1 proc near
push dx
push ax

mov dx,70h
mov al,counter
out dx,al
mov dx,71h
in al,dx
mov dl,al
call printdl
add counter,1

pop dx
pop ax
ret
fun1 endp

;input dl such as xxh,out put as xxh
printdl proc near
push ax
push cx

mov al,dl
mov cl,04h
sar dl,cl
and dl,0fh
call printdlhalf

mov dl,al
and dl,0fh
call printdlhalf

mov dl,' '
mov ah,02h
int 21h

pop cx
pop ax
ret
printdl endp

printdlhalf proc near
push ax
cmp dl,09h
ja largerthan9
add dl,30h
jmp print
largerthan9:
add dl,37h
print:
mov ah,02h
int 21h
pop ax
ret
printdlhalf endp
code ends

end start
