# Create the object folder if it doesn't already exsist.
mkdir -p obj

# Convert the graphics data from PNG to something the GameBoy can use.
rgbgfx -c dmg=93 -o obj/BarrierTiles.bin src/BarrierTiles.png

# Assemble all the used files.
rgbasm -o obj/main.o src/main.asm
rgbasm -o obj/video.o src/video.asm
rgbasm -o obj/interpreter.o src/interpreter.asm

# Create the program folder if it doesn't already exsist.
mkdir -p bin

# Link them together.
rgblink -o bin/chip8.gb -m bin/chip.map -n bin/chip8.sym -p 0xFF -dt  obj/main.o obj/video.o obj/interpreter.o

# Make the ROM a proper GameBoy ROM.
rgbfix -vj -t CHIP-8 bin/chip8.gb