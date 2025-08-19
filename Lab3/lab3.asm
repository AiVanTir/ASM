; Определение констант для системных вызовов
%define SYS_READ   0   ; Чтение из файла
%define SYS_WRITE  1   ; Запись в файл
%define SYS_OPEN   2   ; Открытие файла
%define SYS_CLOSE  3   ; Закрытие файла
%define SYS_EXIT   60  ; Выход из программы

%define STDIN   0      ; Стандартный ввод
%define STDOUT  1      ; Стандартный вывод

%define BUF_SIZE 256   ; Размер буфера для чтения файла
%define MAX_WORD 64    ; Максимальная длина слова

section .bss  ; Секция неинициализированных данных
filename   resb 128    ; Буфер для имени файла
inputN     resb 8      ; Буфер для ввода числа N
buffer     resb BUF_SIZE ; Основной буфер для данных из файла
wordBuf    resb MAX_WORD ; Буфер для обработки отдельных слов
tempByte   resb 1      ; Временный байт для вывода символов
shiftN     resq 1      ; Переменная для хранения значения N (сдвиг)
fd         resq 1      ; Файловый дескриптор

section .text  ; Секция кода
global _start  ; Точка входа в программу

_start:
    ; === Ввод имени файла ===
    ; Вывод приглашения для ввода имени файла
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, msgFile
    mov rdx, msgFileLen
    syscall

    ; Чтение имени файла с STDIN
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, filename
    mov rdx, 128
    syscall
    ; Удаление символа новой строки из ввода
    dec rax
    mov byte [filename + rax], 0  ; Добавление null-terminator в конец строки

    ; === Ввод числа N ===
    ; Вывод приглашения для ввода N
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, msgN
    mov rdx, msgNLen
    syscall

    ; Чтение значения N
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, inputN
    mov rdx, 8
    syscall

    ; Преобразование строки в число
    call atoi
    mov [shiftN], rax  ; Сохранение значения N

    ; === Открытие файла ===
    mov rax, SYS_OPEN
    mov rdi, filename
    mov rsi, 0         ; Флаг O_RDONLY (только чтение)
    syscall
    ; Проверка на ошибку открытия (возвращаемое значение < 0)
    cmp rax, 0
    js exitError
    mov [fd], rax      ; Сохранение файлового дескриптора

; === Основной цикл чтения файла ===
; Читаем файл блоками по BUF_SIZE байт
read_loop:
    mov rax, SYS_READ
    mov rdi, [fd]      ; Файловый дескриптор
    mov rsi, buffer    ; Буфер для данных
    mov rdx, BUF_SIZE  ; Размер буфера
    syscall
    ; Проверка условий завершения (конец файла или ошибка)
    cmp rax, 0
    jle finish
    mov r13, rax       ; Сохраняем реальное количество прочитанных байт
    xor rbx, rbx       ; Индекс текущей позиции в буфере (сбрасываем в 0)

; === Цикл обработки буфера ===
; Разбираем буфер на слова и разделители
parse_loop:
    ; Проверка достижения конца буфера
    cmp rbx, r13
    jge read_loop      ; Если обработали весь буфер - читаем следующий блок
    
    ; Получаем текущий символ
    mov al, [buffer + rbx]
    ; Проверка на пробел
    cmp al, ' '
    je print_space
    ; Проверка на новую строку
    cmp al, 10
    je print_newline

    ; === Обработка слова ===
    ; Инициализация индекса для wordBuf
    xor rsi, rsi

; Чтение слова из буфера в wordBuf
read_word:
    ; Проверка выхода за границы буфера
    cmp rbx, r13
    jge word_done
    
    ; Получение текущего символа
    mov al, [buffer + rbx]
    ; Проверка разделителей (пробел или новая строка)
    cmp al, ' '
    je word_done
    cmp al, 10
    je word_done
    
    ; Сохранение символа в буфер слова
    mov [wordBuf + rsi], al
    inc rsi            ; Увеличиваем индекс в wordBuf
    inc rbx            ; Увеличиваем индекс в основном буфере
    
    ; Проверка на превышение максимальной длины слова
    cmp rsi, MAX_WORD
    je word_done
    jmp read_word

; === Обработка полностью прочитанного слова ===
word_done:
    mov r12, rsi         ; Сохраняем длину слова
    ; Проверка нулевой длины слова (на случай пустого слова)
    test r12, r12
    jz parse_loop        ; Если слово пустое - пропускаем обработку
    
    ; Вычисление реального сдвига (N mod длина_слова)
    mov rax, [shiftN]    ; Загружаем значение N
    xor rdx, rdx         ; Обнуляем rdx перед делением
    div r12              ; Делим rax (N) на r12 (длина слова)
    mov r8, rdx          ; Сохраняем остаток (реальный сдвиг)

    ; === Печать сдвинутого слова ===
    ; Печать части слова от сдвига до конца
    mov r9, r8           ; Начинаем с позиции сдвига
print_shifted1:
    ; Проверка достижения конца слова
    cmp r9, r12
    jge print_shifted2   ; Переходим ко второй части
    
    ; Печать текущего символа
    mov al, [wordBuf + r9]
    call putchar
    inc r9               ; Переходим к следующему символу
    jmp print_shifted1

; Печать части слова от начала до сдвига
print_shifted2:
    xor r9, r9           ; Начинаем с начала слова
print_shifted3:
    ; Проверка достижения позиции сдвига
    cmp r9, r8
    jge parse_loop       ; Завершаем обработку слова
    
    ; Печать текущего символа
    mov al, [wordBuf + r9]
    call putchar
    inc r9
    jmp print_shifted3

; === Обработка пробела ===
print_space:
    mov al, ' '
    call putchar
    inc rbx              ; Переходим к следующему символу
    jmp parse_loop       ; Возвращаемся к обработке буфера

; === Обработка новой строки ===
print_newline:
    mov al, 10           ; Код символа новой строки
    call putchar
    inc rbx
    jmp parse_loop       ; Возвращаемся к обработке буфера

; === Завершение работы программы ===
finish:
    ; Закрытие файла
    mov rax, SYS_CLOSE
    mov rdi, [fd]
    syscall

    ; Корректный выход из программы
    mov rax, SYS_EXIT
    xor rdi, rdi         ; Код возврата 0
    syscall

; === Обработка ошибки открытия файла ===
exitError:
    ; Вывод сообщения об ошибке
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, errMsg
    mov rdx, errMsgLen
    syscall
    
    ; Выход с кодом ошибки 1
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

; === Функция вывода символа ===
; Принимает символ в al, выводит его на STDOUT
putchar:
    mov [tempByte], al   ; Сохраняем символ во временный буфер
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, tempByte    ; Адрес временного буфера
    mov rdx, 1           ; Количество байт для вывода
    syscall
    ret

; === Функция преобразования строки в число (atoi) ===
; Преобразует строку в inputN в целое число, результат в rax
atoi:
    xor rax, rax        ; Обнуляем результат
    xor rcx, rcx        ; Индекс символа в строке (счетчик)
    
    ; Основной цикл обработки цифр
.next:
    ; Загрузка текущего символа (с нулевым расширением)
    movzx r10, byte [inputN + rcx]
    
    ; Проверка на символ новой строки (конец ввода)
    cmp r10, 10
    je .done
    
    ; Проверка, что символ является цифрой
    cmp r10, '0'
    jb .done            ; Если меньше '0' - завершаем
    cmp r10, '9'
    ja .done            ; Если больше '9' - завершаем
    
    ; Преобразование символа в цифру
    sub r10, '0'
    
    ; Умножение текущего результата на 10 и добавление новой цифры
    imul rax, 10
    add rax, r10
    
    ; Переход к следующему символу
    inc rcx
    jmp .next
    
.done:
    ret

; === Секция данных (строки сообщений) ===
section .data
msgFile db "Введите имя файла: ", 0
msgFileLen equ $ - msgFile

msgN db "Введите N для сдвига: ", 0
msgNLen equ $ - msgN

errMsg db "Ошибка при открытии файла", 10, 0
errMsgLen equ $ - errMsg
