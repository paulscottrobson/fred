gcc -D INCLUDE_DEBUGGING_SUPPORT -I ./Framework -I ./ -I /usr/include/SDL2/ -fno-exceptions *.cpp Framework/*.cpp -L/usr/lib -lSDL2 -o fredii
