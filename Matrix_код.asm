;�।�⠢�� ������ 3*3 � �������� ?� ���ﬨ, 
;����� � 直� �?����?��� ������ ��������.
;����?������ ��������� ? �������� ������, � ⠪�� ���室����� �����筨��
kEnter equ 0Dh   ;���� ����?�
KBSp   equ 08h
kSp    equ 20h

;��?� �� ���-�� ����?��
readkey macro
   xor ah,ah
   int 16h
endm
;���०���� ॣ?���?� � �⥪�
SaveReg macro RegList
   irp reg,<RegList>
      push reg
   endm
endm
;�?��������� ॣ?���?� �? �⥪�
LoadReg macro RegList
   irp reg,<RegList>
      pop reg
   endm
endm

.286  ;�������� ?������?� 268

N = 3 ;����?�?��� �����?
Matrix struc ; ������ 蠡��� �������
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

;������� �����
data segment word 'data' use16
   a Matrix <>
   b Matrix <>  ;������ 3 �����?
   d Matrix <>

   InpM db '�������� �����?','$'
   InpEl db '����?�� �������','$'
   InpEnd db ']: ','$'
  
   RezAdd  db 'A+B:',10,13,'$'
   RezMul  db 'A*B:'
   CRLF    db 10,13,'$'
   DetermA db '�����筨� A: ','$'
   DetermB db '�����筨� B: ','$'
   Nam     db ?  ;?�'� �����? (��� �������)
data ends

;������� �����
stk segment stack
   db 100h dup (?)
stk ends

;������� ����
text segment word 'code' use16
assume CS:text,ES:data,DS:data,SS:stk

;-------------���������-------------------------
;�������� ������
ClrScr proc
   SaveReg <ax,bx,cx,dx>  ;����?��� ॣ?��� � �⥪�
   mov ah,02h
   xor bh,bh
   xor dx,dx
   int 10h  ;��⠭����� ����� � ����?� �?��� ���
   mov ax,0920h
   mov bl,7
   mov cx,80*25  ;�������� 2000 �஡?�?�
   int 10h
   LoadReg <dx,cx,bx,ax>  ;�����⠦�� ॣ?��� �? �⥪�
   ret
ClrScr endp

;���?� �������
OutputCh proc  ;� al - ��� ᨬ����
   SaveReg <ax,bx>
   mov ah,0Eh
   xor bh,bh
   int 10h
   LoadReg <bx,ax>
   ret
OutputCh endp
;����� ��������� ᨬ����
OutCh macro ByteVar
   mov al,ByteVar
   call OutputCh
endm

;���?� �����
OutputStr proc  ;� dx - ���� �浪�
   push ax
   mov ah,09h
   int 21h
   pop ax
   ret
OutputStr endp

;�����?� �� ����� ����� �� �����?
ChangeLine proc
   push dx
   mov dx,offset CRLF
   call OutputStr
   pop dx
   ret
ChangeLine endp

;��������� �?���� ����� �? ������
InputBin proc  ;१���� � ax
   SaveReg <bx,cx,dx,di,si,bp>
   xor ax,ax
   xor si,si
   mov bp,10  ;������� �� 10

StartPosition:
   xor di,di  ;�᫮
   xor cl,cl  ;�࠯���� �����
 
Nac:
   readkey
   cmp al,'9'
   ja Nac
   cmp al,'0'
   jb LessNumb

   mov bl,al  ;���०��� � al
   mov ax,di
   mul bp
   or dx,dx  ;�� � ��९�������
   jnz Nac  ;�� � - ������� ���?

   mov dl,bl
   sub dl,'0'
   xor dh,dh  ;dx = ���
   add dx,ax
   jc Nac  ;�� ��७�ᥭ�� -> ��९�������

   mov di,dx
   mov al,bl
   jmp short OutNextCh

PressMinus:
   or si,si
   jnz Nac  ;�� �� �� ����� �浪�
   mov cl,1  ;��⠭����� �࠯���� � 1

OutNextCh:
   call OutputCh  ;�������� �?��� �� ��࠭
   inc si
   jmp short Nac

PressBSp:
   or si,si
   jz Nac  ;�� �?箣� �� �����, � ������� ���?
  
   mov ah,02h
   mov dl,kBSp
   int 21h
   mov dl,kSp
   int 21h
   mov dl,kBSp
   int 21h
   
   dec si
   or si,si  ;�� ��૨ �?��� ᨬ���
   jz StartPosition  ;� �� ᪨��� �� ���
   xor dx,dx
   mov ax,di  ;?����
   div bp   ;�?���� �� 10
   mov di,ax
   jmp short Nac

LessNumb:
   cmp al,'-'
   je PressMinus
   cmp al,kBSP
   je PressBSp
   cmp al,kEnter
   jne Nac

   or si,si  ;�� �?箣� �� �����
   jz Nac  ;� ������� ���?

   mov ax,di
   or cl,cl  ;��ॢ?��� ����
   jz EndInputBin
   neg ax
EndInputBin:
   call ChangeLine
   LoadReg <bp,si,di,dx,cx,bx>
   ret
InputBin endp

;��������� �?���� ����� �? ������
OutputBin proc   ;� ax - �������� �᫮
   SaveReg <ax,bp,dx>
   cmp ax,0
   jge PositNumber

   push ax
   OutCh '-'
   pop ax
   neg ax

PositNumber:
   mov bp,10
   push bp   ;����?��� ������ �?��� �᫠
@@l:
   xor dx,dx
   div bp       ;�?����
   push  dx      ;����?��� ����
   or ax,ax     ;����訢�� 0?
   jnz @@l      ;�? -> �த�����
   mov ah,02h   ;�㭪�?� ��������� ᨬ����
@@l2:
   pop dx       ;�?������� ����
   cmp dx,10    ;�?�諨 �� �?��� -> ���?�
   je @@ex
   add dl,'0'   ;���⢮��� �᫮ � ����
   int 21h      ;�������� ���� �� ��࠭
   jmp short @@l2 ;? �த�����
@@ex:
   LoadReg <dx,bp,ax>
   ret
OutputBin endp

;�������� ������?
InputMatrix proc            ;� bx - ���� �����?
   pusha  ;????. ????????   ;� Nam - ?�'� �����?

   mov dx,offset InpM
   call OutputStr
   OutCh ' '
   OutCh Nam
   call ChangeLine

   mov di,1  ;?�?�?��?��� �?稫쭨� �1
   mov cx,N

InpCycle1:
   push cx
   mov si,1  ;?�?�?��?��� �?稫쭨� �2
   mov cx,N

InpCycle2:
   mov dx,offset InpEl
   call OutputStr
   OutCh Nam
   OutCh '['
   mov ax,di
   call OutputBin  ;������� ���訩 �?稫쭨�
   OutCh ','
   mov ax,si
   call OutputBin  ;������� ��㣨� �?稫쭨�
   mov dx,offset InpEnd
   call OutputStr
   call InputBin
   mov [bx],ax
   add bx,2        ;���室��� �� ����㯭��� ��������
   inc si
   loop InpCycle2

   inc di
   pop cx
   loop InpCycle1
   popa  ;�?������� ॣ?���
   ret
InputMatrix endp

;��������� ������? D
OutputC proc
   pusha  ;����?��� ॣ?���
   mov cx,N
   xor bx,bx
   xor di,di

Out1Cycl:
   push cx  ;����?��� �?稫쭨� ����?�쮣� 横��
   mov cx,N

Out2Cycl:
   mov ax,word ptr d[di]
   call OutputBin  ;�������� �࣮�� �᫮
   OutCh ' '       ;�������� �஡?�
   add di,2

   loop Out2Cycl

   mov dx,offset CRLF
   call OutputStr  ;���室��� �� ����� �冷�
   pop cx  ;�?������� �?稫쭨� ����?�쮣� 横��

   loop Out1Cycl
   popa  ;�?������� ॣ?���
   ret
OutputC endp

;��������� ���� ������� A + B = D
AddMatrix proc
   SaveReg <ax,cx,di>
   mov cx,N*N  ;������� N^2 �������?�
   xor di,di
AddCycle:
   mov ax,word ptr a[di]
   add ax,word ptr b[di]
   mov word ptr d[di],ax
   add di,2  ;���室��� �� ����㯭��� �������
   loop AddCycle
   LoadReg <di,cx,ax>
   ret
AddMatrix endp

;�������� ���� ������� A * B = D
MulMatrix proc
   pusha  ;���०��� ॣ?���
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
;��������� ���� a[i,k]
   mov al,dl  ;al=i
   mov bh,N
   mul bh     ;ax=i*N
   add al,bl  ;i*N+k
   adc ah,0   ;ax=i*N+k
   shl ax,1   ;*2, ⠪ � ������� ������� ⨯� dw 

   mov si,offset A  ;�����㢠�� ���� �����? A
   add si,ax        ;���� ������� a[i,k] 
   mov ax,[si]      ;������� a[i,k]
   mov di,ax        ;������� a[i,k] ����?��� � di

;���室����� ���� a[k,j]
   mov al,bl   ;al=k
   mov bh,N
   mul bh      ;ax=k*N
   add al,dh   ;k*N+j
   adc ah,0    ;ax=k*N+j
   shl ax,1    ;*2, ⠪ � ������� ������� ⨯� dw

   mov si,offset B  ;�����㢠�� ���� �����? B
   add si,ax        ;���� �������� B[k,j] 
   mov ax,[si]      ;������� B[k,j]
   push dx
   imul di          ;ax=A[i,k]*B[k,j] 
   pop dx
   add bp,ax        ;sum=sum+A[i,k]*B[k,j] 

   inc bl           ;k=k+1
   loop m3          ;横� �� k

;���宦���� ���� C[i,j] ��� ������ � ��� sum;
   mov al,dl      ;al=i
   mov bh,N
   mul bh         ;ax=i*N
   add al,dh      ;i*N+j
   adc ah,0       ;ax=i*N+j
   shl ax,1       ;*2, ⠪ � ������� ������� ⨯� dw 

   mov si,offset d  ;�����㢠�� ���� �����? D
   add si,ax       ;���� �������� c[i,j] 
   mov ax,bp       ;sum � ax
   mov [si],ax     ;������� a[i,j]

   inc dh         ;j=j+1
   pop cx
   loop m2        ;横� �� j

   inc dl         ;i=i+1
   pop cx
   loop m1        ;横� �� i

   popa  ;�?������� ॣ?���
   ret       
MulMatrix endp

DetMatrix proc            ;� bx - ���� �����?
   SaveReg <bx,cx,dx,di>  ;� ax - �����筨�
;Det=e11*(e22*e33 - e23*e32) - e12*(e21*e33 - e23*e31) + e13*(e21*e32 - e22*e31)
;1 �������. CX = e11*(e22*e33 - e23*e32)
   mov ax,[bx].Matrix.e22
   imul [bx].Matrix.e33
   mov di,ax
   mov ax,[bx].Matrix.e23
   imul [bx].Matrix.e32
   sub di,ax
   mov ax,[bx].Matrix.e11
   imul di
   mov cx,ax
;2 �������. CX = CX - e12*(e21*e33 - e23*e31)
   mov ax,[bx].Matrix.e21
   imul [bx].Matrix.e33
   mov di,ax
   mov ax,[bx].Matrix.e23
   imul [bx].Matrix.e31
   sub di,ax
   mov ax,[bx].Matrix.e12
   imul di
   sub cx,ax
;3 �������. AX = CX + e13*(e21*e32 - e22*e31)
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

;-------------������� ��������----------------
START:
   mov ax,data
   mov ds,ax  ;�������� ds
   call clrscr
;������� ������ A
   mov bx,offset A
   mov Nam,'A'
   call InputMatrix
;������� ������ B
   mov bx,offset B
   mov Nam,'B'
   call InputMatrix
;���� ? �������� �����筨� �����? A
   mov dx,offset DetermA
   call OutputStr
   mov bx,offset A
   call DetMatrix
   call OutputBin
   call ChangeLine
;���� ? �������� �����筨� �����? B
   mov dx,offset DetermB
   call OutputStr
   mov bx,offset B
   call DetMatrix
   call OutputBin
   call ChangeLine
;���� ��� ������ ? �������� �� ��࠭
   mov dx,offset RezAdd
   call OutputStr
   call AddMatrix
   call OutputC
;���� ����⮪ ������ ? �������� �� ��࠭
   mov dx,offset RezMul
   call OutputStr
   call MulMatrix
   call OutputC

   readkey  ;祪�� ���᪠��� ����?�?
   mov ax,4c00h  ;��室���
   int 21h
text ends
end START