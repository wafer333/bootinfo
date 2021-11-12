;名称:ASM6.ASM
;功能:演示中断处理的实现
;编译:FASM ASM6.ASM
;
format MZ
entry RCodeSeg:Start

;----------------------------------------------------------------------------
include 'macro\proc32.inc'
;include	'macro\struct.inc'
include	'386scd.inc'
;----------------------------------------------------------------------------

;部分常量定义
;----------------------------------------------------------------------------
EOICOM          =       20h                       ;外部中断处理结束命令
ICREGP          =       20h                       ;中断控制寄存器端口地址
IMREGP          =       21h                       ;中断屏蔽寄存器端口地址

use16
;----------------------------------------------------------------------------
segment GDTSeg     ;全局描述符表数据段(16位)
;----------------------------------------------------------------------------
                ;全局描述符表GDT
label GDT byte
                ;空描述符
DUMMY           Desc    <>
                ;规范段描述符
Normal          Desc    <0ffffh,,,ATDW,,>
                ;视频缓冲区段描述符(DPL=3)
VideoBuf        Desc    <0ffffh,8000h,0bh,ATDW,,>
;----------------------------------------------------------------------------
label EFFGDT byte
                ;临时代码段描述符
TempCode        Desc    <0ffffh,TempCodeSeg,,ATCE,,>
                ;演示代码段描述符
DemoCode        Desc    <DemoCodeLen-1,DemoCodeSeg,,ATCE,,>
                ;演示数据段描述符
DemoData        Desc    <DemoDataLen-1,DemoDataSeg,,ATDW,,>
                ;演示堆栈段描述符
DemoStack       Desc    <DemoStackLen-1,DemoStackSeg,,ATDWA,,>
                ;0feh号中断处理程序(显示程序)代码段描述符
EchoCode        Desc    <EchoCodeLen-1,EchoCodeSeg,,ATCE,,>
                ;0feh号中断处理程序(显示程序)数据段描述符
EchoData        Desc    <EchoDataLen-1,EchoDataSeg,,ATDW,,>
                ;8号中断处理程序代码段描述符
TICode          Desc    <TICodeLen-1,TICodeSeg,,ATCE,,>
                ;8号中断处理程序数据段描述符
TIData          Desc    <TIDataLen-1,TIDataSeg,,ATDW,,>
                ;其它中断或异常处理程序代码段描述符
Other           Desc    <OtherCodeLen-1,OtherCodeSeg,,ATCE,,>
;----------------------------------------------------------------------------
GDTLen          =       $-GDT                     ;全局描述符表长度
GDNum           =       ($-EFFGDT)/8; (Size Desc)    ;需特殊处理的描述符数
;----------------------------------------------------------------------------
Normal_Sel      =       Normal-GDT                ;规范段描述符选择子
Video_Sel       =       VideoBuf-GDT              ;视频缓冲区段描述符选择子
;----------------------------------------------------------------------------
TempCode_Sel    =       TempCode-GDT              ;临时代码段的选择子
DemoCode_Sel    =       DemoCode-GDT              ;演示代码段的选择子
DemoData_Sel    =       DemoData-GDT              ;演示数据段的选择子
DemoStack_Sel   =       DemoStack-GDT             ;演示堆栈段的选择子
EchoCode_Sel    =       EchoCode-GDT              ;0feh号中断程序代码段选择子
EchoData_Sel    =       EchoData-GDT              ;0feh号中断程序数据段选择子
TICode_Sel      =       TICode-GDT                ;8号中断程序代码段选择子
TIData_Sel      =       TIData-GDT                ;8号中断程序数据段选择子
Other_Sel       =       Other-GDT                 ;其它中断或异常代码段选择子
;----------------------------------------------------------------------------
			;全局描述符表段定义结束
;----------------------------------------------------------------------------

use16
segment IDTSeg     ;中断描述符表数据段(16位)
;----------------------------------------------------------------------------
label IDT	byte   ;中断描述符表
                ;0--7的8个陷阱门描述符
                rept    8 counter:0 
                {
IDT#counter    	Gate  <OtherBegin,Other_Sel,,AT386TGate,>
				}
            	;对应8号(时钟)中断处理程序的门描述符
IDT8            Gate  <TIBegin,TICode_Sel,,AT386IGate,>
                ;从9--0fdh的245个陷阱门描述符
                rept    245 counter:9
                {
IDT#counter     Gate <OtherBegin,Other_Sel,,AT386TGate,>
                }
                ;对应0feh号中断处理程序的陷阱门描述符
IDT254          Gate <EchoBegin,EchoCode_Sel,,AT386TGate,>
                ;对应0ffh号中断处理程序的陷阱门描述符
IDT255          Gate <OtherBegin,Other_Sel,,AT386TGate,>
;----------------------------------------------------------------------------
IDTLen          =       $-IDT
;----------------------------------------------------------------------------
;中断描述符表段定义结束
;----------------------------------------------------------------------------
;其它中断或异常处理程序的代码段
;----------------------------------------------------------------------------

use16
segment OtherCodeSeg
;----------------------------------------------------------------------------
proc OtherBegin far
                mov     ax,Video_Sel
                mov     es,ax
                mov     ah,17h                    ;在屏幕左上角显示兰底白字
                mov     al,'!'                    ;符号"!"
                mov     word [es:0],ax
                jmp     $                         ;无限循环
endp
;----------------------------------------------------------------------------
OtherCodeLen    =       $


;----------------------------------------------------------------------------
;8号中断处理程序的数据段
;----------------------------------------------------------------------------
use16
segment TIDataSeg
Count           DB      0                         ;中断发生的计数器
TIDataLen       =       $

;----------------------------------------------------------------------------
;8号中断处理程序的代码段
;----------------------------------------------------------------------------

use16
segment TICodeSeg
;----------------------------------------------------------------------------
proc TIBegin far
                push    eax                       ;保护现场
                push    ds
                push    fs
                push    gs
                mov     ax,TIData_Sel             ;置中断处理程序数据段
                mov     ds,ax
                mov     ax,EchoData_Sel           ;置显示过程数据段
                mov     fs,ax
                mov     ax,DemoData_Sel           ;置演示程序数据段
                mov     gs,ax
                cmp     Count,0
                jnz     TI2                       ;计数非0表示未到1秒
                mov     Count,18                  ;每秒约18次
                int     0feh                      ;调用0FEH号中断处理程序显示
                cmp     BYTE PTR fs:Mess,'0'
                jnz     TI1
                mov     BYTE PTR gs:Flag,1        ;显示符号'0'时置标记
TI1:            dec     BYTE PTR fs:Mess          ;调整显示符号
TI2:            dec     Count                     ;调整计数
                pop     gs                        ;恢复现场
                pop     fs
                pop     ds
                mov     al,EOICOM                 ;通知中断控制器中断处理结束
                out     ICREGP,al
                pop     eax
                iretd                             ;中断返回
endp

;----------------------------------------------------------------------------
TICodeLen       =       $
;----------------------------------------------------------------------------
;0FEH号中断处理程序数据段
;----------------------------------------------------------------------------

use16
segment EchoDataSeg
Mess            DB      '8',4eh
EchoDataLen     =       $

;----------------------------------------------------------------------------
;0FEH号中断处理程序(显示程序)的代码段
;----------------------------------------------------------------------------

segment EchoCodeSeg
;----------------------------------------------------------------------------
proc EchoBegin far
                push    ax                        ;保护现场
                push    ds
                push    es
                mov     ax,EchoData_Sel           ;置显示过程数据段
                mov     ds,ax
                mov     ax,Video_Sel              ;置视频缓冲区数据段
                mov     es,ax
                mov     ax,WORD PTR Mess
                mov     WORD [es:0],ax
                pop     es
                pop     ds
                pop     ax
                iretd
endp
;----------------------------------------------------------------------------
EchoCodeLen     =       $
;----------------------------------------------------------------------------
;演示任务的堆栈段
;----------------------------------------------------------------------------

use16
segment DemoStackSeg
DemoStackLen    =       1024
                DB      DemoStackLen DUP(0)
                
;----------------------------------------------------------------------------
;演示任务的数据段
;----------------------------------------------------------------------------

use16
segment DemoDataSeg
Flag            DB      0
DemoDataLen     =       $

;----------------------------------------------------------------------------
;演示任务的代码段
;----------------------------------------------------------------------------

use16
segment DemoCodeSeg
;----------------------------------------------------------------------------
proc DemoBegin far
                mov     ax,DemoStack_Sel          ;置堆栈
                mov     ss,ax
                mov     sp,DemoStackLen           ;置数据段
                mov     ax,DemoData_Sel
                mov     ds,ax
                mov     es,ax
                mov     fs,ax
                mov     gs,ax
                mov     al,11111110b              ;置中断屏蔽字
                out     IMREGP,al                 ;只开发时钟中断
                sti                               ;开中断
DemoConti:      cmp     BYTE PTR Flag,0           ;判标志
                jz      DemoConti                 ;直到不为0
                cli                               ;关中断
                ;转回临时代码段,准备回实方式
                JUMP16  <TempCode_Sel>,<ToDos>
endp
;----------------------------------------------------------------------------
DemoCodeLen     =       $
;----------------------------------------------------------------------------

use16
segment TempCodeSeg     ;临时任务的代码段
;----------------------------------------------------------------------------
proc Virtual1 far
                JUMP16  <DemoCode_Sel>,<DemoBegin>    ;转演示任务
ToDos:          mov     ax,Normal_Sel             ;恢复实方式段描述符高速缓存
                mov     ds,ax
                mov     es,ax
                mov     fs,ax
                mov     gs,ax
                mov     ss,ax
                mov     eax,cr0                   ;准备返回实模式
                and     al,11111110b
                mov     cr0,eax
                JMP   RCodeSeg:Real
endp

;----------------------------------------------------------------------------

;============================================================================
segment RDataSeg 					              ;实方式数据段
VGDTR           PDesc   <GDTLen-1,>               ;GDT伪描述符
VIDTR           PDesc   <IDTLen-1,>               ;IDT伪描述符
NORVIDTR        PDesc   <3ffh,>                   ;用于保存原IDTR值
SPVar           DW      ?                         ;用于保存实方式下的SP
SSVar           DW      ?                         ;用于保存实方式下的SS
IMaskRegV       DB      ?                         ;用于保存原中断屏蔽寄存器值
;----------------------------------------------------------------------------

use16
segment RCodeSeg				                  ;实方式代码段
;----------------------------------------------------------------------------
proc Start far
                mov     ax,RDataSeg
                mov     ds,ax
                cld
                call    InitGDT                   ;初始化全局描述符表GDT
                call    InitIDT                   ;初始化中断描述符表IDT
                mov     [SSVar],ss                  ;保存堆栈指针
                mov     [SPVar],sp
                sidt    [NORVIDTR]        ;保存IDTR
                in      al,IMREGP
                mov     BYTE PTR IMaskRegV,al
                lgdt    [VGDTR]           ;装载GDTR
                cli                               ;关中断
                lidt    [VIDTR]           ;装载IDTR
                mov     eax,cr0
                or      al,1
                mov     cr0,eax
                JUMP16  <TempCode_Sel>,<Virtual1>
Real:           mov     ax,RDataSeg
                mov     ds,ax
                lss     sp,DWORD PTR SPVar        ;又回到实方式
                lidt    [NORVIDTR]
                mov     al,IMaskRegV
                out     IMREGP,al
                sti
                mov     ax,4c00h
                int     21h
endp
;----------------------------------------------------------------------------


proc InitGDT far
                push    ds
                mov     ax,GDTSeg
                mov     ds,ax
                mov     cx,GDNum
                mov     si,EFFGDT
InitG:          mov     ax,[si+2]			;.BaseL
                movzx   eax,ax
                shl     eax,4
                shld    edx,eax,16
                mov     word [si+2],ax		;.BaseL
                mov     BYTE [si+4],dl		;.BaseM
                mov     BYTE [si+7],dh		;.BaseH
                add     si,8 				;SIZE Desc
                loop    InitG
                pop     ds
                mov     bx,16
                mov     ax,GDTSeg
                mul     bx
                mov     WORD PTR VGDTR.Base,ax
                mov     WORD PTR VGDTR.Base+2,dx
                ret
endp
;----------------------------------------------------------------------------

proc InitIDT far
                mov     bx,16
                mov     ax,IDTSeg
                mul     bx
                mov     WORD PTR VIDTR.Base,ax
                mov     WORD PTR VIDTR.Base+2,dx
                ret
endp
;----------------------------------------------------------------------------

