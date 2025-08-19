BITS 64
section .data

; 0ah - символ переноса строки
fileOpenMode: db "w", 0
inputMessageString: db "Enter x and accuracy separated by space", 0ah, 0
inputFormatString: db "%lf %lf", 0
invalidInputMessageString: db "Invalid input", 0ah, 0
resultOutputFormatString: db "Series:  %lf; Std: %lf", 0ah, 0
seriesMemberOutputFormatString: db "%d %lf", 0ah, 0

unableToOpenFileErrorMessage: db "Unable to open file", 0ah, 0
invalidArgsErrorMessage: db "Invalid args: output file expected", 0ah, 0

zero: dq 0.0
one: dq 1.0
nine: dq 9.0
negOne: dq -1.0
threeOverFour: dq 0.75

section .text
global main
extern fopen
extern fclose
extern printf
extern fprintf
extern scanf
extern sin

main:
    ; Создается stack-frame
    push rbp
    mov rbp, rsp
    sub rsp, 32 ; выделение памяти по лок переменные
    ; [rsp] - файл
    ; [rsp+8] - x
    ; [rsp+16] - точность
    ; [rsp+24] - временный буфер для результата вычисления фн-и calc

    mov qword[rsp], 0

    ; Считываем аргументы
    cmp rdi, 2 ; Первый арг - имя исп файла, 2 - имя файла для записи рез
    jne .invalidArgs
    ; открытие файла
    mov rdi, [rsi+8]
    mov rsi, fileOpenMode
    call fopen
    cmp rax, 0 ; проверка на то, что файл открылся
    je .unableToOpenFile
    mov [rsp], rax

    ; ввод параметров
    lea rdi, [rsp + 8]
    lea rsi, [rsp + 16]
    call readInput
    cmp rax, 0
    jne .exit

    ; вычисление значения функции
    movq xmm0, [rsp + 8]
    call calc
    movq [rsp + 24], xmm0 ; [rsp + 24] = рез вычисления библ. фн-и
    ; вычисление суммы ряда
    movq xmm0, [rsp + 8]
    movq xmm1, [rsp + 16]
    mov rdi, [rsp]
    call calcSeries       ; xmm0 = сумма ряды
    movq xmm1, [rsp + 24] ; xmm1 = рез вычисления библ. фн-и

    mov rax, 2 ; Кол-во аргументов с плав. точкой
    mov rdi, resultOutputFormatString
    call printf
    jmp .exit

; обработка ошибок
.invalidArgs:
    mov rax, 0
    mov rdi, invalidArgsErrorMessage
    call printf
    jmp .exit
.unableToOpenFile:
    mov rax, 0
    mov rdi, unableToOpenFileErrorMessage
    call printf
    jmp .exit

; выход
.exit:
    cmp qword[rsp], 0
    je .exit0
    mov rdi, [rsp]
    call fclose
.exit0:
    mov rax, 0
    leave
    ret


; rdi - адрес для сохр x
; rsi - адрес для сохр точности
; Возврат (rax) - 0-Ок, 1-Ошибка
readInput:
    push rbp
    mov rbp, rsp
    sub rsp, 16 ; Выдиление на стеке памяти под лок переменные
    ; сохраняем аргументы
    mov [rsp], rdi
    mov [rsp + 8], rsi

    ; при вызове фн-й с переменным кол-во аргументов (printf, scanf) в rax нужно передать кол-во арг с плав точкой
    mov rax, 0
    mov rdi, inputMessageString
    call printf

    mov rax, 0
    mov rdi, inputFormatString
    mov rsi, [rsp]
    mov rdx, [rsp + 8]
    call scanf
    cmp rax, 2
    jne .invalidInput

    ; Проверка на то, что точность > 0
    mov rax, [rsp + 8]
    movq xmm0, [rax]
    movq xmm1, [zero]
    ucomisd xmm0, xmm1
    jbe .invalidInput

    mov rax, 0
    leave
    ret
.invalidInput:
    mov rax, 0
    mov rdi, invalidInputMessageString
    call printf
    mov rax, 1
    leave
    ret

; Вычисления через библ функции
; xmm0 - x
; Возврат: xmm0
calc:
    sub rsp, 8 ; Выравнивание стека
    call sin         ; xmm0 = sin(x)
    movsd xmm1, xmm0 ; xmm1 = sin(x)
    mulsd xmm0, xmm1 ; xmm0 = sin(x)^2
    mulsd xmm0, xmm1 ; xmm0 = sin(x)^3
    add rsp, 8
    ret


; xmm0 - x
; xmm1 - точность
; rdi - файл
; Возврат: xmm0
calcSeries:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 24
    ; [rsp] - точность
    ; [rsp + 8] - буфер для члена ряда
    ; [rsp + 16] - файл
    ; Используем сохраняемые при вызове функций регистры для хранения некоторых значений
    ; rbx - сумма
    ; r12 - -x^2
    ; r13 - 3^2n
    ; r14 - (3/4)*(-1)^(n+1)*x^(2n+1) / (2n+1)!
    ; r15 - 2n+1
    movq [rsp], xmm1
    mov [rsp + 16], rdi

    mov rbx, 0
    mov r15, 1
    movq [rsp], xmm1

    movq xmm2, [zero]  ; xmm2 = 0
    subsd xmm2, xmm0   ; xmm2 = -x
    mulsd xmm2, xmm0   ; xmm2 = -x^2
    movq r12, xmm2     ; r12 = -x^2

    mov r13, [one]

    movq xmm2, [negOne]
    mulsd xmm2, xmm0    ; xmm2 = -x
    movq xmm3, [threeOverFour]
    mulsd xmm2, xmm3
    movq r14, xmm2      ; r14 = xmm2 = -3x/4

    mov r15, 1

.iter:
    movq xmm4, r14

    ; Домножение факториал в знам. на недостающие множ. (2n, 2n+1)
    inc r15 ; r15 = 2n
    cvtsi2sd xmm3, r15 ; xmm3 = 2n
    divsd xmm4, xmm3
    inc r15 ; r15 = 2n+1
    cvtsi2sd xmm3, r15
    divsd xmm4, xmm3

    movq xmm5, r12
    mulsd xmm4, xmm5 ; домножение на -x^2
    ; xmm4 = (-1)^(n+1)*x^(2n+1) / (2n+1)!
    movq r14, xmm4

    movq xmm6, r13
    movq xmm7, [nine]
    mulsd xmm6, xmm7
    movq r13, xmm6   ; xmm6 = r13 = 9^n

    movq xmm7, [one]
    subsd xmm6, xmm7 ; xmm6 = 3^(2n)-1

    mulsd xmm6, xmm4 ; xmm6 = член ряда
    movq [rsp + 8], xmm6

    ; увеличиваем общую сумму сумму
    movq xmm8, rbx
    addsd xmm8, xmm6
    movq rbx, xmm8

    ; вывод члена ряда в файл
    mov rax, 1          ; кол-во арг с плав точкой
    movsd xmm0, xmm6    ; член ряда
    mov rdi, [rsp + 16] ; файл
    mov rsi, seriesMemberOutputFormatString
    mov rdx, r15
    shr rdx, 1 ; делим 2n+1 на 2 для получения номера члена ряда
    call fprintf

    ; проверка на то, что член ряда больше точности
    movq xmm0, [rsp + 8] ; xmm0 = член ряда
    movq xmm1, [rsp]     ; xmm1 = точность
    ; т.к. надо сравнивать модуль сравниваем сначала член ряда, а потом -член рядв
    ucomisd xmm0, xmm1
    ja .iter
    movq xmm2, [zero]
    subsd xmm2, xmm0 ; xmm2 = -член ряда
    ucomisd xmm2, xmm1
    ja .iter


    movq xmm0, rbx

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

