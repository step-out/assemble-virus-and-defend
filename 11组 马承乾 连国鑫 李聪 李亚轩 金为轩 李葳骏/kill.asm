dseg segment
;定义内存空间
    virus_name db "The infected files are shown above.",13d,10d,'$' ;输出病毒文件名的提示信息
    filepath db "*.exe",0;通配符，查找exe文件
    dta db 02bh dup(0);初始化为0，用于存储上一个文件信息的数据块
    string db "I'm a virus!",13D,10D,'$'
    content db 30h dup(0) ;读取文件写入的缓冲区
    strs db "Antivirus successful!",13d,10d,'$';输出杀毒成功的信息
    kill_vir db 182h dup(0);覆盖病毒的0
    space db "      ",'$';格式符号
    no_file_info db "No EXE file is infected!",13d,10d,'$'
    flag db 0
dseg ends


CSEG segment
    assume cs:CSEG,ds:dseg
start: 
    mov ax,dseg
    mov ds,ax
    call kill;调用杀毒子程序

kill proc
    lea dx,dta ;初始化dta
    mov ah,1ah ;设置dta
    int 21h

    lea dx,filepath ;4e查找第一个文件,dx存储文件ASCIZ字符串
    mov cx,0;0表示普通文件
    mov ah,4eh
    int 21h
    jnc kill_process
    jmp no_file;c为1出错

kill_process:
    lea dx,dta ;文件名地址,dta存储着第一个文件的原始信息
    add dx,1eh;增加30个字节，指向文件名ASCIZ
    
    mov ax,3d02h ;打开文件,读写
    int 21h

    ;移动指针到文件头
    mov bx,ax ;打开文件后，文件代号保留到了ax,但读文件参数时，文件代号须保存到BX中
    mov ax,4200h ;到文件头,al为0:表示从文件的头绝对位移
    mov cx,0
    mov dx,0 ;CX:DX=位移量，为0
    int 21h

    ;读入文件
    mov ah,3fh ;读文件头
    mov cx,30h ;读入的字符数
    lea dx,content ;文件内容保存到content
    mov si,dx ;si作为content首地址
    int 21h
    push si

    cmp word ptr [si],5a4dh ;检查是否是exe,老师发的pdf里面有，为exe文件的表示
    jne transition

    cmp word ptr [si+2ah],4112h ;检查是否已被感染
    jne transition

    ;以下是被感染的情况
    inc flag;flag是感染了的文件的个数
    lea dx,space;输出病毒文件前空格
    mov ah,09h
    int 21h

    lea ax,dta      ; 初始化dta
    ADD AX, 21      ; 计算Attrib字段的地址
    ADD AX, 1       ; 计算Time字段的地址
    ADD AX, 2       ; 计算Date字段的地址
    ADD AX, 2       ; 计算Bytes字段的地址
    ADD AX, 4       ; 计算Name字段的地址
    ;综上，+30，指向ASCIZ
    mov si,ax
    ;因为文件名后面紧跟I'm a virus!
    ;所以通过 I' 作为文件名输出的截止标志
print_loop:
    mov dl,[si]
    cmp dl,0
    jz end_print
print_name:
    mov ah,02h
    int 21h
    inc si
    jmp print_loop
;综上，输出被感染的文件的文件名

;代码过长需要跳转过渡,无实际意义
transition:
    jmp next

;被感染的文件，跳到end_print，处理完毕以后再去next
;没被感染的文件，直接去往next
end_print:
;输出回车换行，结束输出
    mov dl,13d
    mov ah,02h
    int 21h

    mov dl,10d
    mov ah,02h
    int 21h
    pop si; si此时指向文件头
;先输出后处理，写入0覆盖病毒
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
    int 21h
    
    lea dx, kill_vir ; 写入0将病毒代码覆盖
    mov cx, 171h  ; 要写入的字节数————存疑
    mov ah, 40h ; 功能号为40h，表示写入文件
    int 21h

;修改文件头
    mov ax,word ptr[si+2eh]
    mov word ptr[si+14h],ax   ;将程序入口改回原入口
    mov word ptr[si+2ah],0000h      ;将病毒标志置0

    mov ax,4200h        ;定位到文件头
    mov cx,0
    mov dx,0
    int 21h
    lea dx,content      ;将修改后的文件头重新写入
    mov cx,30h      ;位移量为文件头大小
    mov ah,40h      ;写文件操作
    int 21h

next:
    mov ah,3eh ;关闭文件
    int 21h

    mov ah,4fh ;查找下一个文件 ;依据是dta
    int 21h
    jc exit_judge
    jmp kill_process

exit_judge:
    cmp flag,0
    jnz have_file
    jmp no_file

have_file:
    lea dx,virus_name;输出病毒文件名的提示信息
    mov ah,09h
    int 21h

    lea dx,strs ;输出杀毒成功的提示信息
    mov ah,09h
    int 21h
    mov ah,4ch
    int 21h
no_file:
    lea dx,no_file_info
    mov ah,09h
    int 21h
    mov ah,4ch
    int 21h
kill endp
CSEG ends
end start