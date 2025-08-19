# Компилятор и флаги
ASM = nasm
ASMFLAGS = -f elf64
LD = ld

# Исходный файл и выходные имена
SRC = lab3.asm
OBJ = $(SRC:.asm=.o)  # lab3.asm → lab3.o
TARGET = lab3

# Правило по умолчанию
all: $(TARGET)

# Сборка .o из .asm
%.o: %.asm
	$(ASM) $(ASMFLAGS) $< -o $@

# Линковка
$(TARGET): $(OBJ)
	$(LD) $< -o $@

# Очистка
clean:
	rm -f $(OBJ) $(TARGET)

.PHONY: all clean
