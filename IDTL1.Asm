;名称:ASM7.ASM
;功能:模拟异常和演示异常处理
;编译:TASM ASM7.ASM
;连接:TLINK ASM7.OBJ
format MZ
entry RCodeSeg:Start
;----------------------------------------------------------------------------
INCLUDE         '386SCD.INC'
include 		'macro\proc32.inc'
USE16
;----------------------------------------------------------------------------
SEGMENT GDTSeg                          ;全局描述符表数据段(16位)
;----------------------------------------------------------------------------
                ;全局描述符表GDT
LABEL GDT                BYTE
                ;空描述符
DUMMY           Desc    <>
                ;规范段描述符及选择子
Normal          Desc    <0ffffh,,,ATdw,,>
Normal_Sel      =       Normal-GDT
                ;视频缓冲区段描述符(DPL=3)及选择子
VideoBuf        Desc    <0ffffh,8000h,0bh,ATdw,,>
VideoBuf_Sel    =       VideoBuf-GDT
;----------------------------------------------------------------------------
LABEL EFFGDT             BYTE
                ;临时代码段描述符及选择子
TempCode        Desc    <0ffffh,TempCodeSeg,,ATCE,,>
TempCode_Sel    =       TempCode-GDT
                ;演示代码段描述符及选择子
DemoCode        Desc    <DemoCodeLen-1,DemoCodeSeg,,ATCE,,>
DemoCode_Sel    =       DemoCode-GDT
                ;演示任务局部描述符表段描述符及选择子
DemoLDT         Desc    <DemoLDTLen-1,DemoLDTSeg,,ATLDT,,>
DemoLDT_Sel     =       DemoLDT-GDT
                ;演示任务TSS段描述符及选择子
DemoTSS         Desc    <DemoTSSLen-1,DemoTSSSeg,,AT386TSS,,>
DemoTSS_Sel     =       DemoTSS-GDT
                ;缓冲数据段描述符及选择子
XBuffer         Desc    <BufferLen-1,BufferSeg,,ATdw,,>
XBuffer_Sel     =       XBuffer-GDT
                ;读键盘任务局部描述符表段描述符及选择子
GKeyLDT         Desc    <GKeyLDTLen-1,GKeyLDTSeg,,ATLDT,,>
GKeyLDT_Sel     =       GKeyLDT-GDT
                ;读键盘任务TSS段描述符及选择子
GKeyTSS         Desc    <GKeyTSSLen-1,GKeyTSSSeg,,AT386TSS,,>
GKeyTSS_Sel     =       GKeyTSS-GDT
                ;显示陷阱处理程序代码段描述符及选择子
EchoCode        Desc    <EchoCodeLen-1,EchoCodeSeg,,ATCE,,>
EchoCode_Sel    =       EchoCode-GDT
                ;显示出错码过程代码段描述符及选择子
SubCode         Desc    <SubCodeLen-1,SubCodeSeg,,ATCE,,>
SubCode_Sel     =       SubCode-GDT
                ;其它中断或异常处理程序代码段描述符及选择子
Other           Desc    <OtherCodeLen-1,OtherCodeSeg,,ATCE,,>
Other_Sel       =       Other-GDT
;----------------------------------------------------------------------------
GDTLen          =       $-GDT                     ;全局描述符表长度
GDNum           =       ($-EFFGDT)/8 ;(SIZE Desc)    ;需处理基地址的描述符个数
;----------------------------------------------------------------------------
                             ;全局描述符表段定义结束
USE16
;----------------------------------------------------------------------------
SEGMENT IDTSeg                            ;中断描述符表数据段(16位)
;----------------------------------------------------------------------------
LABEL IDT                BYTE                      ;中断描述符表
                ;0号陷阱门描述符(对应除法出错故障)
IDT0                Gate    <DivBegin,Divide_Sel,,AT386TGate,>
                ;从1--3的3个陷阱门描述符
                REPT    3 n
                {
IDT#n                Gate    <OtherBegin,Other_Sel,,AT386TGate,>
                }
                
                ;4号陷阱门描述符(对应溢出陷阱)
IDT4                Gate    <OFBegin,OF_Sel,,AT386TGate,>
                ;从5--0ah的的6个陷阱门描述符
                REPT    6 n:5
                {
IDT#n                Gate    <OtherBegin,Other_Sel,,AT386TGate,>
                }
                ;0bh号陷阱门描述符(对应段不存在故障)
IDT11                Gate    <SNPBegin,SNP_Sel,,AT386TGate,>
                ;0ch号陷阱门描述符(对应堆栈段故障)
IDT12                Gate    <SSEBegin,SSE_Sel,,AT386TGate,>
                ;0dh号陷阱门描述符(对应通用保护故障)
IDT13                Gate    <GPBegin,GP_Sel,,AT386TGate,>
                ;从0eh--0edh的240个陷阱门描述符
                REPT    240 n:14
                {
IDT#n                Gate    <OtherBegin,Other_Sel,,AT386TGate,>
                }
                ;对应0feh号陷阱门描述符(对应显示中断处理程序)
IDT254                Gate    <EchoBegin,EchoCode_Sel,,AT386TGate,>
                ;0ffh号任务门描述符(对应读键盘中断处理任务)
IDT255                Gate    <,GKeyTSS_Sel,,ATTaskGate,>
;----------------------------------------------------------------------------
IDTLen          =       $-IDT
;----------------------------------------------------------------------------
                              ;中断描述符表段定义结束
USE16
;----------------------------------------------------------------------------
;读键盘任务局部描述符表段
;----------------------------------------------------------------------------
SEGMENT GKeyLDTSeg
;----------------------------------------------------------------------------
LABEL GLDT               BYTE
                ;代码段描述符及选择子
GKeyCode        Desc    <0ffffh,GKeyCodeSeg,,ATCE,,>
GKeyCode_Sel    =       GKeyCode-GLDT+TIL
                ;堆栈段描述符及选择子
GKeyStack       Desc    <GKeyStackLen-1,GKeyStackSeg,,ATdwA,,>
GKeyStack_Sel   =       GKeyStack-GLDT+TIL
;----------------------------------------------------------------------------
GKeyLDNum       =       ($-GLDT)/8 ;(SIZE Desc)      ;需初始化基地址的描述符个数
GKeyLDTLen      =       $                         ;局部描述符表段长度
;----------------------------------------------------------------------------

USE16
;----------------------------------------------------------------------------
;读键盘任务TSS段
;----------------------------------------------------------------------------
SEGMENT GKeyTSSSeg
                dd      0                         ;链接字
                dd      ?                         ;0级堆栈指针
                dw      ?,?
                dd      ?                         ;1级堆栈指针
                dw      ?,?
                dd      ?                         ;2级堆栈指针
                dw      ?,?
                dd      0                         ;CR3
                dw      GKeyBegin,0               ;EIP
                dd      0                         ;EFLAGS
                dd      0                         ;EAX
                dd      0                         ;ECX
                dd      0                         ;EDX
                dd      0                         ;EBX
                dw      GKeyStackLen,0            ;ESP
                dd      0                         ;EBP
                dd      0                         ;ESI
                dd      0                         ;EDI
                dw      Normal_Sel,0              ;ES
                dw      GKeyCode_Sel,0            ;CS
                dw      GKeyStack_Sel,0           ;SS
                dw      Normal_Sel,0              ;DS
                dw      Normal_Sel,0              ;FS
                dw      Normal_Sel,0              ;GS
                dw      GKeyLDT_Sel,0             ;LDTR
                dw      0                         ;调试陷阱标志
                dw      $+2                       ;指向I/O许可位图的偏移
                db      0ffh                      ;I/O许可位图结束字节
GKeyTSSLen      =       $

USE16
;----------------------------------------------------------------------------
;读键盘任务堆栈段
;----------------------------------------------------------------------------
SEGMENT GKeyStackSeg
GKeyStackLen    =       1024
                db      GKeyStackLen DUP(0)

USE16
;----------------------------------------------------------------------------
;读键盘任务代码段
;----------------------------------------------------------------------------
SEGMENT GKeyCodeSeg

;----------------------------------------------------------------------------
proc GKeyBegin far
                push    ds
                push    es
                push    fs
                push    gs
                mov     ax,Normal_Sel
                mov     ss,ax                     ;准备转实方式
                mov     eax,cr0
                and     al,11111110b
                mov     cr0,eax                   ;转实方式
                JUMP16  <GKeyCodeSeg>,<GetKey>
GetKey:         mov     ax,RDataSeg               ;实方式
                mov     ds,ax
                mov     ebp,esp                   ;恢复实方式部分现场
                lss     sp,dwORD PTR SPVar
                lidt    [NORVIDTR]
                sti
                mov     dx,Mess
                mov     ah,9
                int     21h                       ;显示提示信息
GetKey1:        mov     ah,0
                int     16h                       ;读键盘
                cmp     al,'0'
                jz      GetKey2
                cmp     al,'4'
                jz      GetKey2
                and     al,11011111b              ;小写转大写
                cmp     al,'B'
                jb      GetKey1
                cmp     al,'D'
                ja      GetKey1                   ;只有[0,4,b,c,d]有效
GetKey2:        mov     dl,al
                mov     ah,2
                int     21h                       ;显示所按字符
                mov     ax,BufferSeg
                mov     es,ax
                mov     BYTE PTR es:KeyASCII,dl   ;保存到缓冲数据段
                cli                               ;准备返回保护方式
                lidt    [VIDTR]
                mov     eax,cr0
                or      al,1
                mov     cr0,eax
                JUMP16  <GKeyCode_Sel>,<GetKeyV>
GetKeyV:        mov     ax,GKeyStack_Sel          ;又进入保护方式
                mov     ss,ax
                mov     esp,ebp
                pop     gs
                pop     fs
                pop     es
                pop     ds
                iretd
                jmp     GKeyBegin
endp
;----------------------------------------------------------------------------
GKeyCodeLen     =       $

USE16
;----------------------------------------------------------------------------
;其它中断或异常处理程序的代码段
;----------------------------------------------------------------------------
SEGMENT OtherCodeSeg

;----------------------------------------------------------------------------
proc OtherBegin far
                mov     si,MessOther
                int     0feh                      ;显示提示信息
                mov     WORD PTR es:[0],ax
                jmp     $                         ;进入无限循环
endp
;----------------------------------------------------------------------------
OtherCodeLen    =       $

USE16
;----------------------------------------------------------------------------
;除法出错故障处理程序代码段
;----------------------------------------------------------------------------
SEGMENT DivCodeSeg

;----------------------------------------------------------------------------
proc DivBegin            far
                mov     si,OFFSET Mess0
                mov     di,0
                int     0feh                      ;显示提示信息
                shr     ax,1                      ;处理模拟的除法错误
                iretd                             ;返回
endp
;----------------------------------------------------------------------------
DivCodeLen      =       $

USE16
;----------------------------------------------------------------------------
;溢出陷阱处理程序代码段
;----------------------------------------------------------------------------
SEGMENT OFCodeSeg

;----------------------------------------------------------------------------
proc OFBegin             far
                mov     si,OFFSET Mess4
                mov     di,0
                int     0feh                      ;显示提示信息
                iretd                             ;返回
endp
;----------------------------------------------------------------------------
OFCodeLen       =       $

USE16
;----------------------------------------------------------------------------
;段不存在故障处理程序代码段
;----------------------------------------------------------------------------
SEGMENT SNPCodeSeg

;----------------------------------------------------------------------------
proc SNPBegin            far
                mov     si,OFFSET MessB
                mov     di,0
                int     0feh                      ;显示提示信息
                pop     eax                       ;弹出出错代码
                CALL16  SubCode_Sel,SubBegin      ;显示出错代码
                pop     eax
                add     eax,2                     ;按模拟的引起段不存在指令
                push    eax                       ;调整返回地址
                iretd
endp
;----------------------------------------------------------------------------
SNPCodeLen      =       $

USE16
;----------------------------------------------------------------------------
;堆栈段故障处理程序代码段
;----------------------------------------------------------------------------
SEGMENT SSECodeSeg

;----------------------------------------------------------------------------
proc SSEBegin            far
                mov     si,OFFSET MessC
                mov     di,0
                int     0feh                      ;显示提示信息
                pop     eax                       ;弹出出错代码
                CALL16  SubCode_Sel,SubBegin      ;显示出错代码
                pop     eax
                add     eax,4                     ;按模拟的引起堆栈段错误的
                push    eax                       ;指令调整返回地址
                iretd
endp
;----------------------------------------------------------------------------
SSECodeLen      =       $

USE16
;----------------------------------------------------------------------------
;通用保护故障处理程序代码段
;----------------------------------------------------------------------------
SEGMENT GPCodeSeg

;----------------------------------------------------------------------------
proc GPBegin             far
                push    ebp
                mov     ebp,esp
                push    eax
                push    esi
                push    edi                       ;保护现场
                mov     si,OFFSET MessD
                mov     di,0
                int     0feh                      ;显示提示信息
                mov     eax,[bp+4]                ;从堆栈中取出出错代码
                CALL16  SubCode_Sel,SubBegin      ;显示出错代码
                pop     edi
                pop     esi
                pop     eax                       ;恢复部分现场
                add     dwORD PTR [ebp+8],2       ;按模拟的故障指令调整返回
                pop     ebp                       ;地址
                add     esp,4                     ;废除堆栈中的出错代码
                iretd
endp

USE16
;----------------------------------------------------------------------------
;显示出错码过程代码段
;----------------------------------------------------------------------------
SEGMENT SubCodeSeg

;----------------------------------------------------------------------------
proc SubBegin                                      ;AX中含出错代码
                push    ax                        ;保护现场
                push    cx
                push    dx
                push    si
                push    di
                mov     si,ErrCode
                mov     dx,ax
                mov     cx,4
SubR1:          rol     dx,4                      ;把16位出错代码转换成4位
                mov     al,dl                     ;十六进制数的ASCII码并保存
                and     al,0fh
                add     al,30h
                cmp     al,'9'
                jbe     SubR2
                add     al,7
SubR2:          mov     [si],al
                inc     si
                loop    SubR1
                mov     si,ErrMess
                Mov     di,80*2                   ;从第二行行首开始
                int     0feh                      ;显示出错码
                pop     di                        ;恢复现场
                pop     si
                pop     dx
                pop     cx
                pop     ax
                retf                              ;返回
endp
;----------------------------------------------------------------------------
SubCodeLen      =       $

;----------------------------------------------------------------------------
GPCodeLen       =       $

USE16
;----------------------------------------------------------------------------
;实现显示的陷阱处理程序代码段
;入口参数--DS:SI指向显示信息串,ES:DI指向显示缓冲区
;----------------------------------------------------------------------------
SEGMENT EchoCodeSeg

;----------------------------------------------------------------------------
proc EchoBegin           far
                pushad                            ;保护现场
                cld
                mov     ah,7
                mov     al,20h
                mov     cx,80
                push    di
                rep     stosw                     ;清所在显示行
                pop     di
Echo1:          lodsb
                or      al,al
                jz      Echo2
                stosw                             ;显示指定信息串
                jmp     Echo1
Echo2:          popad                             ;恢复现场
                iretd
endp
;----------------------------------------------------------------------------
EchoCodeLen     =       $

USE16
;----------------------------------------------------------------------------
;缓冲区数据段
;----------------------------------------------------------------------------
SEGMENT BufferSeg
KeyASCII        db      ?
Buffer          db      128 DUP(?)
BufferLen       =       $

USE16
;----------------------------------------------------------------------------
;演示任务局部描述符表段
;----------------------------------------------------------------------------
SEGMENT DemoLDTSeg
;----------------------------------------------------------------------------
LABEL DLDT               BYTE
                ;演示任务TSS段作为数据段的描述符及选择子
ToDemoTSS       Desc    <DemoTSSLen-1,DemoTSSSeg,,ATdw,,>
ToDemoTSS_Sel   =       ToDemoTSS-DLDT+TIL
                ;演示任务堆栈段描述符及选择子
DemoStack       Desc    <DemoStackLen-1,DemoStackSeg,,ATdwA,,>
DemoStack_Sel   =       DemoStack-DLDT+TIL
                ;演示任务数据段描述符及选择子
DemoData        Desc    <DemoDataLen-1,DemoDataSeg,,ATdw,,>
DemoData_Sel    =       DemoData-DLDT+TIL
                ;除法出错故障处理程序代码段描述符及选择子
Divide          Desc    <DivCodeLen-1,DivCodeSeg,,ATCE,,>
Divide_Sel      =       Divide-DLDT+TIL
                ;溢出陷阱处理程序代码段描述符及选择子
OverFlow        Desc    <OFCodeLen-1,OFCodeSeg,,ATCE,,>
OF_Sel          =       OverFlow-DLDT+TIL
                ;段不存在故障处理程序代码段描述符及选择子
SNPCode         Desc    <SNPCodeLen-1,SNPCodeSeg,,ATCE,,>
SNP_Sel         =       SNPCode-DLDT+TIL
                ;堆栈段出错故障处理程序代码段描述符及选择子
SSECode         Desc    <SSECodeLen-1,SSECodeSeg,,ATCE,,>
SSE_Sel         =       SSECode-DLDT+TIL
                ;通用保护故障处理程序代码段描述符及选择子
GPCode          Desc    <GPCodeLen-1,GPCodeSeg,,ATCE,,>
GP_Sel          =       GPCode-DLDT+TIL
                ;为模拟段不存在故障而安排的数据段描述符及选择子
TestNPS         Desc    <0ffffh,,,ATdw-80h,,>
TestNPS_Sel     =       TestNPS-DLDT+TIL
;----------------------------------------------------------------------------
DemoLDNum       =       ($-DLDT)/8;(SIZE Desc)      ;LDT描述符个数
DemoLDTLen      =$
;----------------------------------------------------------------------------

USE16
;----------------------------------------------------------------------------
;演示任务TSS段
;----------------------------------------------------------------------------
SEGMENT DemoTSSSeg
DemoTaskSS      TSS     
                db      0ffh
DemoTSSLen      =       $

USE16
;----------------------------------------------------------------------------
;演示任务的堆栈段
;----------------------------------------------------------------------------
SEGMENT DemoStackSeg
DemoStackLen    =       1024
                db      DemoStackLen DUP(0)

USE16
;----------------------------------------------------------------------------
;演示任务的数据段
;----------------------------------------------------------------------------
SEGMENT DemoDataSeg
Mess0           db      'Divide Error (Exception 0)',0
Mess4           db      'Overflow (Exception 4)',0
MessB           db      'Segment Not Present (Exception 11)',0
MessC           db      'Stack Segment (Exception 12)',0
MessD           db      'General Protection (Exception 13)',0
MessOther       db      'Other Exception',0
ErrMess         db      'Error Code = '
ErrCode         db      4 DUP(0),'H',0
DemoDataLen     =       $

USE16
;----------------------------------------------------------------------------
;演示任务的代码段
;----------------------------------------------------------------------------
SEGMENT DemoCodeSeg

;----------------------------------------------------------------------------
proc DemoBegin           far
                mov     ax,DemoLDT_Sel
                lldt    ax                        ;装载LDTR
                mov     ax,DemoStack_Sel          ;置堆栈
                mov     ss,ax
                mov     esp,DemoStackLen
                mov     ax,ToDemoTSS_Sel
                mov     gs,ax                     ;把演示任务LDT选择子填入TSS
                mov     WORD [gs:DemoTaskSS.TRLDTR],DemoLDT_Sel
                mov     ax,DemoTSS_Sel
                ltr     ax                        ;装载TR
                mov     ax,DemoData_Sel
                mov     ds,ax                     ;装载其它数据段寄存器
                mov     ax,VideoBuf_Sel
                mov     es,ax
                mov     ax,XBuffer_Sel
                mov     fs,ax
                mov     ax,XBuffer_Sel
                mov     gs,ax
                int     0ffh                      ;接收要模拟的异常类型号
                mov     al,BYTE PTR fs:KeyASCII   ;按接收的字符模拟异常号
                cmp     al,'0'
                jnz     Demo4
                mov     ax,2000
                mov     cl,2                      ;模拟除法出错故障
                div     cl                        ;该指令长2字节
                jmp     Over
Demo4:          cmp     al,'4'
                jnz     Demo11
                mov     al,100
                add     al,50
                into                              ;模拟溢出陷阱
                JMP     Over
Demo11:         cmp     al,'B'
                jnz     Demo12
                mov     ax,TestNPS_Sel            ;模拟段不存在故障
                mov     gs,ax                     ;该指令长2字节
                JMP     Over
Demo12:         cmp     al,'C'
                jnz     Demo13
                mov     ebp,esp                   ;模拟堆栈出错故障
                mov     al,[ebp]                  ;该指令长4字节
                jmp     Over
Demo13:         mov     ax,DemoTSS_Sel            ;模拟通用保护故障
                mov     gs,ax                     ;该指令长2字节
Over:           ;转临时代码段
                JUMP16  TempCode_Sel,<ToDos>
endp
;----------------------------------------------------------------------------
DemoCodeLen     =       $

USE16
;----------------------------------------------------------------------------
SEGMENT TempCodeSeg                 ;临时任务的代码段

;----------------------------------------------------------------------------
proc Virtual1             far
                JUMP16  DemoCode_Sel,DemoBegin    ;转演示任务
ToDos:          mov     ax,Normal_Sel             ;恢复实方式段描述符高速缓存
                mov     ds,ax
                mov     es,ax
                mov     fs,ax
                mov     gs,ax
                mov     ss,ax
                mov     eax,cr0                   ;准备返回实模式
                and     al,11111110b
                mov     cr0,eax
                JUMP16  <RCodeSeg>,<Real>
endp
;----------------------------------------------------------------------------

USE16
;============================================================================
SEGMENT RDataSeg                 ;实方式数据段
VGDTR           PDesc   <GDTLen-1,>               ;GDT伪描述符
VIDTR           PDesc   <IDTLen-1,>               ;IDT伪描述符
NORVIDTR        PDesc   <3ffh,>                   ;用于保存原IDTR值
SPVar           dw      ?                         ;用于保存实方式下的SP
SSVar           dw      ?                         ;用于保存实方式下的SS
Mess            db      'Press a key[0,4,B,C,D]:$';提示信息


USE16
;----------------------------------------------------------------------------
SEGMENT RCodeSeg                 ;实方式代码段

;----------------------------------------------------------------------------
proc Start           
                mov     ax,RDataSeg
                mov     ds,ax
                cld
                call    InitGDT                   ;初始化全局描述符表GDT
                call    InitIDT                   ;初始化中断描述符表IDT
                mov     ax,GKeyLDTSeg
                mov     fs,ax
                mov     cx,GKeyLDNum
                mov     si,GLDT
                CALL    InitLDT
                mov     ax,DemoLDTSeg
                mov     fs,ax
                mov     cx,DemoLDNum
                mov     si,DLDT
                CALL    InitLDT
                mov     [SSVar],ss                  ;保存堆栈指针
                mov     [SPVar],sp
                lgdt    [VGDTR]           ;装载GDTR
                sidt    [NORVIDTR]        ;保存IDTR
                cli                               ;关中断
                lidt    [VIDTR]           ;装载IDTR
                mov     eax,cr0
                or      al,1
                mov     cr0,eax
                JUMP16  <TempCode_Sel>,<Virtual1>
Real:           mov     ax,RDataSeg
                mov     ds,ax
                lss     sp,dwORD PTR SPVar        ;又回到实方式
                lidt    [NORVIDTR]
                sti
                mov     ax,4c00h
                int     21h
endp
;----------------------------------------------------------------------------
proc InitGDT         
                push    ds
                mov     ax,GDTSeg
                mov     ds,ax
                mov     cx,GDNum
                mov     si,EFFGDT
InitG:          mov     ax,[si+2]
                movzx   eax,ax
                shl     eax,4
                shld    edx,eax,16
                mov     WORD [si+2],ax
                mov     BYTE [si+4],dl
                mov     BYTE [si+7],dh
                add     si,8;SIZE Desc
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
proc InitIDT         
                mov     bx,16
                mov     ax,IDTSeg
                mul     bx
                mov     WORD PTR VIDTR.Base,ax
                mov     WORD PTR VIDTR.Base+2,dx
                ret
endp
;----------------------------------------------------------------------------
;入口参数:FS:SI=第一个要初始化的描述符,CX=要初始化的描述符数
;----------------------------------------------------------------------------
proc InitLDT         
ILDT:           mov     ax,WORD [fs:si+2]
                movzx   eax,ax
                shl     eax,4
                shld    edx,eax,16
                mov     WORD [fs:si+2],ax
                mov     BYTE [fs:si+4],dl
                mov     BYTE [fs:si+7],dh
                add     si,8;SIZE Desc
                loop    ILDT
                ret
endp
;----------------------------------------------------------------------------

