; ============================================
; edge_detect_asm.asm — реализация в NASM
; Назначение: выделение границ с помощью фильтра 3x3
; Ядро (kernel):
;  [ -1  -1  -1 ]
;  [ -1   8  -1 ]
;  [ -1  -1  -1 ]
; Репликация краёв (replicate padding)
;
; Вход:
;   rdi — указатель на input (uint8_t*)
;   rsi — указатель на output (uint8_t*)
;   rdx — ширина изображения (int width)
;   rcx — высота изображения (int height)
; ============================================

global edge_detect_asm
section .text

edge_detect_asm:
    ; Сохраняем используемые регистры
    push rbx
    push r12
    push r13
    push r14
    push r15

    xor r8, r8              ; r8 = y = 0 — начинаем с первой строки
.y_loop:
    cmp r8, rcx             ; если y >= height
    jge .done               ; завершить цикл по строкам

    xor r9, r9              ; r9 = x = 0 — начинаем с первого пикселя строки
.x_loop:
    cmp r9, rdx             ; если x >= width
    jge .next_y             ; перейти к следующей строке

    ; === Вычисляем координаты соседей с replicate padding ===

    ; r10 ← x-1
    mov r10, r9
    dec r10
    cmp r10, 0
    jge .px1
    xor r10, r10            ; если x-1 < 0 → r10 = 0
.px1:

    ; r11 ← x+1
    mov r11, r9
    inc r11
    cmp r11, rdx
    jl .px2done
    mov r11, rdx
    dec r11                 ; если x+1 >= width → r11 = width - 1
.px2done:

    ; r12 ← y-1
    mov r12, r8
    dec r12
    cmp r12, 0
    jge .py1
    xor r12, r12            ; если y-1 < 0 → r12 = 0
.py1:

    ; r13 ← y+1
    mov r13, r8
    inc r13
    cmp r13, rcx
    jl .py2done
    mov r13, rcx
    dec r13                 ; если y+1 >= height → r13 = height - 1
.py2done:

    ; === Применение ядра 3x3 ===
    ; Сумма будет храниться в r15d (32-битное целое)

    ; r15d ← 0
    xor r15d, r15d

    ; (y-1, x-1) * -1
    mov r14, r12
    imul r14, rdx
    add r14, r10
    movzx eax, byte [rdi + r14]
    imul eax, -1
    add r15d, eax

    ; (y-1, x) * -1
    mov r14, r12
    imul r14, rdx
    add r14, r9
    movzx eax, byte [rdi + r14]
    imul eax, -1
    add r15d, eax

    ; (y-1, x+1) * -1
    mov r14, r12
    imul r14, rdx
    add r14, r11
    movzx eax, byte [rdi + r14]
    imul eax, -1
    add r15d, eax

    ; (y, x-1) * -1
    mov r14, r8
    imul r14, rdx
    add r14, r10
    movzx eax, byte [rdi + r14]
    imul eax, -1
    add r15d, eax

    ; (y, x) * 8
    mov r14, r8
    imul r14, rdx
    add r14, r9
    movzx eax, byte [rdi + r14]
    imul eax, 8
    add r15d, eax

    ; (y, x+1) * -1
    mov r14, r8
    imul r14, rdx
    add r14, r11
    movzx eax, byte [rdi + r14]
    imul eax, -1
    add r15d, eax

    ; (y+1, x-1) * -1
    mov r14, r13
    imul r14, rdx
    add r14, r10
    movzx eax, byte [rdi + r14]
    imul eax, -1
    add r15d, eax

    ; (y+1, x) * -1
    mov r14, r13
    imul r14, rdx
    add r14, r9
    movzx eax, byte [rdi + r14]
    imul eax, -1
    add r15d, eax

    ; (y+1, x+1) * -1
    mov r14, r13
    imul r14, rdx
    add r14, r11
    movzx eax, byte [rdi + r14]
    imul eax, -1
    add r15d, eax

    ; === Ограничение значений: saturate r15d в диапазон [0, 255] ===
    cmp r15d, 0
    jge .check255
    xor r15d, r15d          ; если меньше 0 → 0
    jmp .store
.check255:
    cmp r15d, 255
    jle .store
    mov r15d, 255           ; если больше 255 → 255

.store:
    ; Сохраняем результат в выходной массив: output[y * width + x]
    mov r14, r8
    imul r14, rdx
    add r14, r9
    mov [rsi + r14], r15b   ; сохраняем только младший байт

    ; Следующий пиксель по x
    inc r9
    jmp .x_loop

.next_y:
    ; Следующая строка (y++)
    inc r8
    jmp .y_loop

.done:
    ; Восстанавливаем регистры
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret                     ; Возврат в C
