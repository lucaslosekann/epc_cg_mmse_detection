CC = nvcc
CFLAGS = -Iinclude -lm -arch=native
SRC = src/main.cu src/matrix.cu src/vector.cu src/cg.cu
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
