CC = gcc
CFLAGS = -Wall -Iinclude
SRC = src/main.c src/matrix.c src/vector.c
OUT = out
OBJ = $(patsubst src/%.c,$(OUT)/%.o,$(SRC))
TARGET = main

data_dir = data

all: $(TARGET)

$(OUT)/%.o: src/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(OUT)/*.o $(TARGET)

.PHONY: all clean
