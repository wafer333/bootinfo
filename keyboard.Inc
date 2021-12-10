; 键盘定义宏文件
; keyboard.inc
;
; ascii 表定义
; x79 E2780 CPU 通过
; keyboard 字符映射
;
; by Y.W email:7535794@qq.com
; 为 nasm 编译器使用
;==============================

;
; 引用默认内存系统地址 
; 0024h~0027h  int 9h  键盘中断地址 
; 0058h~005Bh  int 16h 键盘中断地址
; 417h  1字节 第一个 键盘状态字 （略）
; 418h  1字节 第二个 键盘状态字 （略）
; 419h  1字节 按住ALT+数字（0-256）在此反应ascii内码，值是数字
; 41ah-41dh 36字节缓冲，41ah 首指针 41c 尾指针 值相等缓冲区满
; 41ah  字 键盘缓冲区首指针
; 41ch  字 键盘缓冲区尾指针
; 41eh  32字节 循环键盘缓冲区，保存键盘键入的字符到程序可以接收这些字符为止
; 480h	8字节 键盘缓冲首指针
; 482h  1字节 键盘缓冲尾指针
; 496h  1字节   键盘类型和方式
;	0  最后按键为E1隐含码
;	1  最后按键为E0隐含码
;	2  右Ctrl键按下
;	3  右Alt键按下
;	4  101/102键盘
;	5  Num Lock(读7位和4位,此灯亮)
;	6  字符ID已从最后位循环到第一位
;	7  读键盘ID
; 497h  1字节 键盘标志
;	0-2  键盘LED灯状态位
;	3  保留
;	4  收到消息
;	5  重发接收标志
;	6  方式指示器更新
;	7  键盘传送错误标志
; 4b4h  1字节 键盘NMI控制标志*
; 4b5h  1字节 键盘中断中标志*
; 4bah  1字节 最后的键盘扫描码*
; 4bbh  1字节 NMI缓冲头位置*
; 4bch  1字节 NMI缓冲头位置*
; 4bdh  16字节 NMI扫描码缓冲*
; * = 可变（E0 E1 是键盘的视窗启动键和扩展菜单键的扫描码）

extern special:byte

%ifndef _KEYBOARD_INC_
%define _KEYBOARD_INC_

%define 从键盘读字符 		_kb_readchr
%define 从键盘缓冲区读字符 	_kb_readachr
%define 取键盘状态字节 		_kb_getsta
%define 设置重复率 			_kb_resp
%define 设置键盘点击功能	_kb_clku
%define 字符及其扫描码进栈	_kb_chrscstk
%define 从扩展键盘读字符	_kb_lreadchr
%define 从扩展键盘缓冲区读字符 _kb_lreadachr
%define 取扩展键盘状态字节	_kb_lgetsta

;=============================================
; _kb_init _kbinput 模块使用参数，在文件外添加
; 在主文件中加入
;
; special	db	(?)
;

;INT 16H
;中断类型：BIOS中断
;中断功能：键盘I/O控制程序
;入口参数：AH=00H
;子 功 能：从键盘读字符
;调用参数：
;出口参数：AH=字符的扫描码
;          AL=字符的ASCII码
%macro _kb_readchr 0
mov ah,00h
int 16h
ret
%endmacro

;中断类型：BIOS中断
;中断功能：键盘I/O控制程序
;入口参数：AH=01H
;子 功 能：从键盘缓冲区读字符
;调用参数：
;出口参数：ZF=0时
;            AH=键盘的扫描码
;            AL=键盘的ASCII码
;          ZF=1表示缓冲区空，无字符输入
%macro _kb_readachr 0
mov ah,01h 
int 16h
ret
%endmacro

;中断类型：BIOS中断
;中断功能：键盘I/O控制程序
;入口参数：AH=02H
;子 功 能：取键盘状态字节
;调用参数：
;出口参数：AL=键盘状态字节
;注：可组合使用
%macro _kb_getsta 0
mov ah,02h
int 16h
ret
%endmacro

;中断类型：BIOS中断
;中断功能：键盘I/O控制程序
;入口参数：AH=03H
;子 功 能：设置重复率
;调用参数：BH=重复延迟
;          BL=重复率
;          对于PCjr：
;            AL=00H 表示装入缺省的速率和延迟
;            AL=01H 表示增加初始延迟
;            AL=02H 表示重复频率降低一半
;            AL=03H 表示增加延迟和降低一半重复频率
;            AL=04H 表示关闭键盘重复功能
;出口参数：无
%macro _kb_resp 0
mov ah,03h
int 16h
ret
%endmacro

;中断类型：BIOS中断
;中断功能：键盘I/O控制程序
;入口参数：AH=04H
;子 功 能：设置键盘点击功能
;调用参数：AL=00H表示关闭键盘点击功能
;          AL=01H表示打开键盘点击功能
;出口参数：无
%macro _kb_clku 0
mov ah,04h
int 16h
ret
%endmacro

;中断类型：BIOS中断
;中断功能：键盘I/O控制程序
;入口参数：AH=05H
;子 功 能：字符及其扫描码进栈
;调用参数：CH=字符的描述码
;          CL=字符的ASCII码
;出口参数：CF=1表示操作成功，AL=00H
;          CF=0表示操作失败，AL=01H
%macro _kb_chrscstk 0
mov ah,05h
int 16h
ret
%endmacro

;中断类型：BIOS中断
;中断功能：键盘I/O控制程序
;入口参数：AH=10H
;子 功 能：从扩展键盘读字符
;调用参数：
;出口参数：AH=字符的扫描码
;          AL=字符的ASCII码
;说    明：根据0000:0496H单元的内容判断扩展键盘是否有效
%macro _kb_lreadchr 0
mov ah,10h
int 16h
ret
%endmacro

;中断类型：BIOS中断
;中断功能：键盘I/O控制程序
;入口参数：AH=11H
;子 功 能：从扩展键盘缓冲区读字符
;调用参数：
;出口参数：ZF=0时
;            AH=键盘的扫描码
;            AL=键盘的ASCII码
;          ZF=1表示缓冲区空，无字符输入
%macro _kb_lreadachr 0
mov ah,11h
int 16h
ret
%endmacro

;中断类型：BIOS中断
;中断功能：键盘I/O控制程序
;入口参数：AH=12H
;子 功 能：取扩展键盘状态字节
;调用参数：
;出口参数：AL=扩展键盘状态字节，其各位为1时的含义如下：
%macro _kb_lgetsta 0 
mov ah,12h
int 16h
ret
%endmacro

;======================================================
; 从操作系统书上借过来改写的函数 作为 keyboard的函数库
;====================================================== 
;
; COUNT kb_init(VOID)
;
;	Initializes the system keyboard.
;
  
%macro _kb_init 0
		public _kb_init
		xor	al,al
		mov	special,al
		ret
%endmacro
;====================================================== 
;
; COUNT kb_input(VOID)
;
;	Returns a character from the system keyboard.
;
  
%macro _kb_input 0
		public _kb_input
		
		; Do a standard C entry
		push	bp
		mov	bp,sp

		; Test to see if last time we had a special character.
		; If so, just take it and run with it.
		mov	al,special
		or	al,al
		jnz	_kb_inp1

		; Use the BIOS for our input instead
		call _kb_readchr

		; Test if the BIOS returned a special character.
		; If it was, just save the top and send the null.
		or	al,al			; Bottom is null if special key
		jnz	_kb_inp1		; not, just return ascii part
		mov	special,ah	; save the special byte
		xor	ah,ah			; convert to a C int
		jmp	short _kb_inp2

_kb_inp1:	xor	ah,ah			; convert to a C int
		mov	special,ah	; clear the special byte

		; Standard C exit.
_kb_inp2:	pop	bp
		ret

%endmacro
;====================================================== 
%macro _kb_ndinput 0
		public	_kb_ndinput

		push	bp
		mov	bp,sp
		call _kb_readachr
		xor	ah,ah			; Zero register
		pop	bp
		ret
%endmacro
;====================================================== 
%macro _kb_data 0
		public	_kb_data

		push	bp
		mov	bp,sp
		call _kb_readachr
		jz	kbd1			; Jump if zero
		xor	ah,ah			; Zero register
		jmp	short kbd2		; (0030)
		nop
kbd1:
		mov	ax,0FFFFh
kbd2:
		pop	bp
		ret
%endmacro
;======================================================
;IMPORT CryptDuplicateHash, 16

%ifdef UNICODE
;%define BuildTrusteeWithName BuildTrusteeWithNameW
%define 中文键盘输入输出版本 _ChineseKbVer

%else   ;// ANSI
%define EnglishKbVer _EnglishKbVer
;%define AccessCheckByTypeResultListAndAuditAlarmByHandle AccessCheckByTypeResultListAndAuditAlarmByHandleA

%endif
%endif