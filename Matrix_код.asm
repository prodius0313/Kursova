;Представити матрицю 3*3 як структуру ?з полями, 
;кожне з яких в?дпов?дає одному елементу.
;Реал?зовано додавання ? множення матриць, а також знаходження визначника
kEnter equ 0Dh   ;Коди клав?ш
KBSp   equ 08h
kSp    equ 20h

;Кл?к на будь-яку клав?шу
readkey macro
   xor ah,ah
   int 16h
endm
;Збереження рег?стр?в у стеку
SaveReg macro RegList
   irp reg,<RegList>
      push reg
   endm
endm
;В?дновлення рег?стр?в з? стеку
LoadReg macro RegList
   irp reg,<RegList>
      pop reg
   endm
endm

.286  ;Дозволяємо ?нструкц?ї 268

N = 3 ;Розм?рн?сть матриц?
Matrix struc ; описуємо шаблон структури
   e11 dw 0
   e12 dw 0
   e13 dw 0
   e21 dw 0
   e22 dw 0
   e23 dw 0
   e31 dw 0
   e32 dw 0
   e33 dw 0
Matrix ends

;СЕГМЕНТ ДАНИХ
data segment word 'data' use16
   a Matrix <>
   b Matrix <>  ;Задали 3 матриц?
   d Matrix <>

   InpM db 'Введення матриц?','$'
   InpEl db 'Введ?ть елемент','$'
   InpEnd db ']: ','$'
  
   RezAdd  db 'A+B:',10,13,'$'
   RezMul  db 'A*B:'
   CRLF    db 10,13,'$'
   DetermA db 'Визначник A: ','$'
   DetermB db 'Визначник B: ','$'
   Nam     db ?  ;?м'я матриц? (для введеня)
data ends

;СЕГМЕНТ СТЕКУ
stk segment stack
   db 100h dup (?)
stk ends

;СЕГМЕНТ КОДУ
text segment word 'code' use16
assume CS:text,ES:data,DS:data,SS:stk

;-------------ПРОЦЕДУРИ-------------------------
;ОЧИЩЕННЯ ЕКРАНУ
ClrScr proc
   SaveReg <ax,bx,cx,dx>  ;збер?гаємо рег?стри у стеку
   mov ah,02h
   xor bh,bh
   xor dx,dx
   int 10h  ;встановлюємо курсор у верхн?й л?вий кут
   mov ax,0920h
   mov bl,7
   mov cx,80*25  ;виводимо 2000 проб?л?в
   int 10h
   LoadReg <dx,cx,bx,ax>  ;завантажуємо рег?стри з? стеку
   ret
ClrScr endp

;ВИВ?Д СИМВОЛУ
OutputCh proc  ;в al - код символу
   SaveReg <ax,bx>
   mov ah,0Eh
   xor bh,bh
   int 10h
   LoadReg <bx,ax>
   ret
OutputCh endp
;Макрос виведення символу
OutCh macro ByteVar
   mov al,ByteVar
   call OutputCh
endm

;ВИВ?Д РЯДКА
OutputStr proc  ;в dx - адреса рядка
   push ax
   mov ah,09h
   int 21h
   pop ax
   ret
OutputStr endp

;ПЕРЕХ?Д НА НОВИЙ РЯДОК НА ЕКРАН?
ChangeLine proc
   push dx
   mov dx,offset CRLF
   call OutputStr
   pop dx
   ret
ChangeLine endp

;ВИВЕДЕННЯ Ц?ЛОГО ЧИСЛА З? ЗНАКОМ
InputBin proc  ;результат в ax
   SaveReg <bx,cx,dx,di,si,bp>
   xor ax,ax
   xor si,si
   mov bp,10  ;множимо на 10

StartPosition:
   xor di,di  ;число
   xor cl,cl  ;прапорець знаку
 
Nac:
   readkey
   cmp al,'9'
   ja Nac
   cmp al,'0'
   jb LessNumb

   mov bl,al  ;збережемо в al
   mov ax,di
   mul bp
   or dx,dx  ;якщо є переповнення
   jnz Nac  ;якщо є - вводимо дал?

   mov dl,bl
   sub dl,'0'
   xor dh,dh  ;dx = цифра
   add dx,ax
   jc Nac  ;якщо перенесення -> переповнення

   mov di,dx
   mov al,bl
   jmp short OutNextCh

PressMinus:
   or si,si
   jnz Nac  ;якщо не на початку рядка
   mov cl,1  ;встановлюємо прапорець в 1

OutNextCh:
   call OutputCh  ;виводимо м?нус на екран
   inc si
   jmp short Nac

PressBSp:
   or si,si
   jz Nac  ;якщо н?чого не ввели, то вводимо дал?
  
   mov ah,02h
   mov dl,kBSp
   int 21h
   mov dl,kSp
   int 21h
   mov dl,kBSp
   int 21h
   
   dec si
   or si,si  ;якщо стерли л?вий символ
   jz StartPosition  ;то все скидаємо на нуль
   xor dx,dx
   mov ax,di  ;?накше
   div bp   ;д?лимо на 10
   mov di,ax
   jmp short Nac

LessNumb:
   cmp al,'-'
   je PressMinus
   cmp al,kBSP
   je PressBSp
   cmp al,kEnter
   jne Nac

   or si,si  ;якщо н?чого не ввели
   jz Nac  ;то вводимо дал?

   mov ax,di
   or cl,cl  ;перев?ряємо знак
   jz EndInputBin
   neg ax
EndInputBin:
   call ChangeLine
   LoadReg <bp,si,di,dx,cx,bx>
   ret
InputBin endp

;ВИВЕДЕННЯ Ц?ЛОГО ЧИСЛА З? ЗНАКОМ
OutputBin proc   ;в ax - виведене число
   SaveReg <ax,bp,dx>
   cmp ax,0
   jge PositNumber

   push ax
   OutCh '-'
   pop ax
   neg ax

PositNumber:
   mov bp,10
   push bp   ;збер?гаємо ознаку к?нця числа
@@l:
   xor dx,dx
   div bp       ;д?лимо
   push  dx      ;Збер?гаємо цифру
   or ax,ax     ;залишився 0?
   jnz @@l      ;н? -> продовжуємо
   mov ah,02h   ;функц?я виведення символу
@@l2:
   pop dx       ;в?дновлюємо цифру
   cmp dx,10    ;д?йшли до к?нця -> вих?д
   je @@ex
   add dl,'0'   ;перетворюємо число у цифру
   int 21h      ;виводимо цифру на екран
   jmp short @@l2 ;? продовжуємо
@@ex:
   LoadReg <dx,bp,ax>
   ret
OutputBin endp

;ВВЕДЕННЯ МАТРИЦ?
InputMatrix proc            ;в bx - адреса матриц?
   pusha  ;????. ????????   ;в Nam - ?м'я матриц?

   mov dx,offset InpM
   call OutputStr
   OutCh ' '
   OutCh Nam
   call ChangeLine

   mov di,1  ;?н?ц?ал?зуємо л?чильник №1
   mov cx,N

InpCycle1:
   push cx
   mov si,1  ;?н?ц?ал?зуємо л?чильник №2
   mov cx,N

InpCycle2:
   mov dx,offset InpEl
   call OutputStr
   OutCh Nam
   OutCh '['
   mov ax,di
   call OutputBin  ;вводимо перший л?чильник
   OutCh ','
   mov ax,si
   call OutputBin  ;вводимо другий л?чильник
   mov dx,offset InpEnd
   call OutputStr
   call InputBin
   mov [bx],ax
   add bx,2        ;переходимо до наступного елементу
   inc si
   loop InpCycle2

   inc di
   pop cx
   loop InpCycle1
   popa  ;в?дновлюємо рег?стри
   ret
InputMatrix endp

;ВИВЕДЕННЯ МАТРИЦ? D
OutputC proc
   pusha  ;збер?гаємо рег?стри
   mov cx,N
   xor bx,bx
   xor di,di

Out1Cycl:
   push cx  ;збер?гаємо л?чильник зовн?шнього циклу
   mov cx,N

Out2Cycl:
   mov ax,word ptr d[di]
   call OutputBin  ;виводимо чергове число
   OutCh ' '       ;виводимо проб?л
   add di,2

   loop Out2Cycl

   mov dx,offset CRLF
   call OutputStr  ;переходимо на новий рядок
   pop cx  ;в?дновлюємо л?чильник зовн?шнього циклу

   loop Out1Cycl
   popa  ;в?дновлюємо рег?стри
   ret
OutputC endp

;ДОДАВАННЯ ДВОХ МАТРИЦЬ A + B = D
AddMatrix proc
   SaveReg <ax,cx,di>
   mov cx,N*N  ;множимо N^2 елемент?в
   xor di,di
AddCycle:
   mov ax,word ptr a[di]
   add ax,word ptr b[di]
   mov word ptr d[di],ax
   add di,2  ;переходимо до наступного елемента
   loop AddCycle
   LoadReg <di,cx,ax>
   ret
AddMatrix endp

;МНОЖЕННЯ ДВОХ МАТРИЦЬ A * B = D
MulMatrix proc
   pusha  ;збережемо рег?стр
   xor dl,dl  ;i=0
   mov cx,N   ;for  i=0 to N-1

m1:
   push cx 
   mov cx,N   ;for  j=0 to N-1
   xor dh,dh  ;j=0

m2:
   push cx
   xor ax,ax   
   mov bp,ax   ;sum=0
   mov cx,N    ;for  k=0 to N-1
   xor bl,bl   ;k=0

m3:
;виведення адреси a[i,k]
   mov al,dl  ;al=i
   mov bh,N
   mul bh     ;ax=i*N
   add al,bl  ;i*N+k
   adc ah,0   ;ax=i*N+k
   shl ax,1   ;*2, так як елементи структури типу dw 

   mov si,offset A  ;виконувана адреса матриц? A
   add si,ax        ;адреса елемента a[i,k] 
   mov ax,[si]      ;елемент a[i,k]
   mov di,ax        ;елемент a[i,k] збер?гаємо в di

;знаходження адреси a[k,j]
   mov al,bl   ;al=k
   mov bh,N
   mul bh      ;ax=k*N
   add al,dh   ;k*N+j
   adc ah,0    ;ax=k*N+j
   shl ax,1    ;*2, так як елементи структури типу dw

   mov si,offset B  ;виконувана адреса матриц? B
   add si,ax        ;адреса елементу B[k,j] 
   mov ax,[si]      ;елемент B[k,j]
   push dx
   imul di          ;ax=A[i,k]*B[k,j] 
   pop dx
   add bp,ax        ;sum=sum+A[i,k]*B[k,j] 

   inc bl           ;k=k+1
   loop m3          ;цикл по k

;знахоження адреси C[i,j] для запису в неї sum;
   mov al,dl      ;al=i
   mov bh,N
   mul bh         ;ax=i*N
   add al,dh      ;i*N+j
   adc ah,0       ;ax=i*N+j
   shl ax,1       ;*2, так як елементи структури типу dw 

   mov si,offset d  ;виконувана адреса матриц? D
   add si,ax       ;адреса елементу c[i,j] 
   mov ax,bp       ;sum в ax
   mov [si],ax     ;елемент a[i,j]

   inc dh         ;j=j+1
   pop cx
   loop m2        ;цикл по j

   inc dl         ;i=i+1
   pop cx
   loop m1        ;цикл по i

   popa  ;в?дновимо рег?стри
   ret       
MulMatrix endp

DetMatrix proc            ;в bx - адреса матриц?
   SaveReg <bx,cx,dx,di>  ;в ax - визначник
;Det=e11*(e22*e33 - e23*e32) - e12*(e21*e33 - e23*e31) + e13*(e21*e32 - e22*e31)
;1 ЧАСТИНА. CX = e11*(e22*e33 - e23*e32)
   mov ax,[bx].Matrix.e22
   imul [bx].Matrix.e33
   mov di,ax
   mov ax,[bx].Matrix.e23
   imul [bx].Matrix.e32
   sub di,ax
   mov ax,[bx].Matrix.e11
   imul di
   mov cx,ax
;2 ЧАСТИНА. CX = CX - e12*(e21*e33 - e23*e31)
   mov ax,[bx].Matrix.e21
   imul [bx].Matrix.e33
   mov di,ax
   mov ax,[bx].Matrix.e23
   imul [bx].Matrix.e31
   sub di,ax
   mov ax,[bx].Matrix.e12
   imul di
   sub cx,ax
;3 ЧАСТИНА. AX = CX + e13*(e21*e32 - e22*e31)
   mov ax,[bx].Matrix.e21
   imul [bx].Matrix.e32
   mov di,ax
   mov ax,[bx].Matrix.e22
   imul [bx].Matrix.e31
   sub di,ax
   mov ax,[bx].Matrix.e13
   imul di
   add ax,cx
   LoadReg <di,dx,cx,bx>
   ret
DetMatrix endp

;-------------ОСНОВНА ПРОГРАМА----------------
START:
   mov ax,data
   mov ds,ax  ;налаштуємо ds
   call clrscr
;вводимо матрицю A
   mov bx,offset A
   mov Nam,'A'
   call InputMatrix
;вводимо матрицю B
   mov bx,offset B
   mov Nam,'B'
   call InputMatrix
;рахуємо ? виводимо визначник матриц? A
   mov dx,offset DetermA
   call OutputStr
   mov bx,offset A
   call DetMatrix
   call OutputBin
   call ChangeLine
;рахуємо ? виводимо визначник матриц? B
   mov dx,offset DetermB
   call OutputStr
   mov bx,offset B
   call DetMatrix
   call OutputBin
   call ChangeLine
;рахуємо суму матриць ? виводимо на екран
   mov dx,offset RezAdd
   call OutputStr
   call AddMatrix
   call OutputC
;рахуємо добуток матриць ? виводимо на екран
   mov dx,offset RezMul
   call OutputStr
   call MulMatrix
   call OutputC

   readkey  ;чекаємо натискання клав?ш?
   mov ax,4c00h  ;виходимо
   int 21h
text ends
end START