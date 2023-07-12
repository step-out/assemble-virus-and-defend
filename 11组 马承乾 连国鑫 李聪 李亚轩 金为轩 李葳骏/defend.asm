assume cs:codesg

codesg segment
start: 
    mov ax, cs
    mov ds, ax;源段地址
    mov si, offset inject_start;源地址偏移

    mov ax, 0
    mov es, ax;目标段地址
    mov di, 200h;目标地址偏移
    
    mov cx, offset inject_end - offset inject_start;目标地址长度

    cld;设置传输方向为正
    rep movsb;ds:[si]->es:[di] 循环cx次
    mov ax,0
    mov es,ax
    mov ax,word ptr es:[4*21h]
    mov bx,word ptr es:[4*21h+2]
    mov word ptr es:[4*68h],ax
    mov word ptr es:[4*68h+2],bx;68和21有了相同功能

    mov word ptr es:[4*21h],200h
    mov word ptr es:[4*21h+2],0;设置新的21h

    mov ax, 4c00h
    int 68h
inject_start:
sti
    push bx
    pushf 

    mov bx,dx
    cmp word ptr [bx][6],6976h
    jne no_virus
    jmp inject_main;有毒

no_virus:
    popf
    pop bx

    int 68h
    iret;没毒，返回

    msg_ db 'Virus!But bye!',0ah,0dh,'$'
    dta_ db 02bh dup(0)
    filepath_ db '*.exe',0
    content_ db 30h dup(0)
    cover_ db 10h dup(0)
    
inject_main:
    ;不保存ax,bx什么的了，对有毒的，在中断里结束程序
    mov ax,0
    mov ds,ax 
    mov es,ax

    mov dx,200h+offset msg_-offset inject_start
    mov ah,9
    int 68h;输出提示

    mov dx,200h+offset dta_-offset inject_start
    mov ah,1ah
    int 68h;设置dta

    mov dx,200h+offset filepath_-offset inject_start
    mov cx,0
    mov ah,4eh
    int 68h;查第一个文件
    jnc kill_main;查到了，kill
    jmp no_file_;没查到

kill_main:

    mov dx,offset dta_-offset inject_start+200h
    add dx,1eh;移动30h，指向文件ASCIZ部分
    mov ax,3d02h
    int 68h;读写形式打开该文件

    ;移动指针到文件头
    mov bx,ax ;打开文件后，文件代号保留到了ax,但读文件参数时，文件代号须保存到BX中
    mov ax,4200h ;到文件头,al为0:表示从文件的头绝对位移
    mov cx,0
    mov dx,0 ;CX:DX=位移量，为0
    int 68h

    ;读入文件
    mov ah,3fh ;读文件头
    mov cx,30h ;读入的字符数
    mov dx,offset content_-offset inject_start+200h ;文件内容保存到content_
    mov si,dx ;si作为content首地址
    int 68h

    cmp word ptr [si],5a4dh ;检查是否是exe,老师发的pdf里面有，为exe文件的表示
    jne next_;不是，下一位

    cmp word ptr [si+2ah],4112h ;检查是否已被感染
    jne next_;不是，下一位

    ;多次覆盖把病毒消去
    ;计算病毒入口的地址,通过偏移地址寻找物理地址
    mov ax,word ptr[si+16h];cs
    mov dx,10h
    mul dx
    add ax,200h
    mov cx,word ptr[si+14h];ip
    add ax,cx
    mov cx,0
    mov dx,ax;dx=病毒段的cs*10h+ip+200，即病毒入口
    mov ax,4200h;文件指针从文件头跳转到病毒入口
    int 68h

    mov cx,20h
loop_:
    push cx
    mov dx, offset cover_-offset inject_start+200h; 写入0将病毒代码覆盖
    mov cx, 10h  ; 要写入的字节数————存疑
    mov ah, 40h ; 功能号为40h，表示写入文件
    int 68h
    pop cx
    loop loop_

    ;把被感染文件入口改了
    mov ax,word ptr[si+2eh]
    mov word ptr[si+14h],ax   ;将程序入口改回原入口
    mov word ptr[si+2ah],0000h      ;将病毒标志置0

    mov ax,4200h        ;定位到文件头
    mov cx,0
    mov dx,0
    int 68h
    mov dx,200h+offset content_-offset inject_start      ;将修改后的文件头重新写入
    mov cx,30h      ;位移量为文件头大小
    mov ah,40h      ;写文件操作
    int 68h
    
next_:

    mov ah,3eh ;关闭文件
    int 68h

    mov ah,4fh ;查找下一个文件 ;依据是dta
    int 68h
    jc no_file_;没有下一个，完事儿
    jmp kill_main;有下一个

no_file_:

    mov ax,4c00h
    int 68h;杀完结束

inject_end:
    nop

codesg ends
end start