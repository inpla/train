CC      = gcc
CFLAGS  = -Wall -Winline -std=gnu99
LDFLAGS = 
LIBS    = 
INCLUDE = -I ./src
SRC_DIR = ./src
OBJ_DIR = ./build
TARGET  = train
OBJS    = $(OBJ_DIR)/train.tab.c $(OBJ_DIR)/ast.o  $(OBJ_DIR)/linenoise.o
DEPS	= $(SRC_DIR)/config.h


.PHONY: all

all: $(OBJ_DIR) $(TARGET) 

$(TARGET): $(OBJS) $(LIBS) $(DEPS)
	$(CC) $(CFLAGS) $(INCLUDE) $(MYOPTION) -o $@ $(OBJS) $(LDFLAGS) 

$(OBJ_DIR)/linenoise.o: $(SRC_DIR)/linenoise/linenoise.c
	@if [ ! -f $(SRC_DIR)/linenoise/linenoise.c.orig ]; then \
		patch --backup --version-control=simple --suffix=.orig $(SRC_DIR)/linenoise/linenoise.c $(SRC_DIR)/linenoise/linenoise-multiline.patch; \
	fi
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ -c $< 


$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c 
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ -c $< 

$(OBJ_DIR)/train.tab.c : $(SRC_DIR)/train.y $(OBJ_DIR)/lex.yy.c
	bison -o $@ $<

$(OBJ_DIR)/lex.yy.c : $(SRC_DIR)/lex.l
	flex -o $@ $^

$(OBJ_DIR):
	@if [ ! -d $(OBJ_DIR) ]; then \
		echo ";; mkdir $(OBJ_DIR)"; mkdir $(OBJ_DIR); \
	fi

clean:
	rm -f $(TARGET)* $(OBJ_DIR)/* *stackdump* *core*
	@if [ -f $(SRC_DIR)/linenoise/linenoise.c.orig ]; then \
		echo "mv -f $(SRC_DIR)/linenoise/linenoise.c.orig $(SRC_DIR)/linenoise/linenoise.c"; \
		mv -f $(SRC_DIR)/linenoise/linenoise.c.orig $(SRC_DIR)/linenoise/linenoise.c; \
	fi


thread: $(OBJS) $(LIBS)
	$(CC) $(CFLAGS) $(INCLUDE) $(MYOPTION) -DTHREAD -o $(TARGET) $(OBJS) $(LDFLAGS) -lpthread
