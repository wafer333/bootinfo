 ;           .P    rYYrYYYi      eY  YeYYeYeYYY   .. .P.       Pr  .    .ePPPPePePPPPe     rrriYYe       iP       P        P                           
 ;         eePPePr ..PPiiiPP    rP.  ..PP...rPe   ePePPeePPeePPPPePP    Pi    .P     YP    iiiPr..  .    YP    ..YPi  YYYYePYYYYY  .PPPPYiP    PP      
 ;         ..YP..    Pr   YP   .P.     PY   Pi        . .  .            PririirPriiiiYP    YrYPeYY  PPPe rP    YePPe. rriirPriirr    rP  iPP  PPP      
 ;           .P     Pe    PP   Pi Pi   Pi  PP.i     P  eP .PPYYrrYYi    Priii.rPi.iiiYP    .. Pi i    .i rP       P        P         rP  rPrPPPYP      
 ;        iPePPPPP ir   eeY   PPrPe    P.  i.rPi   .P. eP    . . ...    Pr    .P     YP    ee P  P       rP      .P   eYeePPeYYP.    iP  iP YP iP      
 ;         i .P     YePPPeY     PP    iPPi   eP     P  YP  rrrrrrYY      rYYYrYPYrYYYi     eP P  P  PPei rP       Pre ie.     PP                       
 ;         P  Prri PY     PP   YP     Pe PP iP       ..YY .YrirYYi     YYrii.irPrii.irYY   Pe P  P    iY iP    .rPPY.  ePr   PP                        
 ;        .P  Pir. P.     rP  YPerYi  P.  YPP       PeYrPPYrYPYrYPi    ii..YPYiPiiPPr.ii   PY P  P  .    YP    eYiP      YPYPi                         
 ;        rP. P    Pe.....PP     ..  YP   ePPY     rP   Pr   P   PP       YPi  P   YPi     P. P. P rPPPPePPer     P      iPPPr                         
 ;        PYPPP.   .ePPPPPY   Yiiiri Pr ePY  PPi   YP   Pe  iP.  PP    .PPe   .P     PPi  .P  P. P.      rP      YP   rPPe   YPe.                      
 ;       .e  iYPPPPeYYYYYYer  YYrrrr.e .Y     rY  ePPPPPPPPPPPPPPPPP  .PY     .P      iP  .Y  e  Y       iP    iPP.  YPi       ee                      

;-----------------------------------------------
; 开机测试程序
; 测试时钟中断
; 应用于U盘启动，测试用BOSCH
;                           by Pierre
; 编辑器是RADAsm       字体 FixedSyS 字号 小四
;-----------------------------------------------

format binary as 'img'
org 7c00h
;测试代码开始
;读时间
start:
;	mov ax,cs
;	mov ds,ax
;	mov es,ax
;	xor ecx,ecx

;	mov al,00
;	out 71,al
;	in al,70
;	mov di,data1
;	stosb 
;	mov al,02
;	out 71,al
;	in al,70
;	mov [di+1],al

	mov ah,0
	mov al,13h
	int 10h

screen:	
	mov si,data2
	mov al,byte [si]	
	call write
	jz write_done
	jmp screen
write_done:
	xor	ah,ah			;暂停键功能
	int	16h				;BIOS键盘中断		
	loop write_done
	
write:
	mov	ah,0eh			;字符终端显示输出功能函数号
	mov bx,0003h		;显示属性 (weird...)

.more:
	lodsb				;读到al一个字节
	or	al,al
	jz	.done
	int	10h				;BIOS显示中断
	jmp	.more			;重复.more这段代码

.done:
	retn
	
	
data1	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
data2	db 'Super blue fruit tech',0dh,0ah,0

		rb 7C00h+512-2-$	;fill up to the boot record signature
		db 055h,0AAh		;the signature itself
