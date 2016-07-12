#include <Arduino.h>
#include "sys_processor.h"
#include "hardware.h"

#include <TVout.h>
#include <fontALL.h>
#include <Keypad.h>

TVout TV;

const byte ROWS = 4; //four rows
const byte COLS = 4; //three columns
char keys[ROWS][COLS] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};
byte rowPins[ROWS] = {8+1,7+1,6+1,5+1};
byte colPins[COLS] = {4+1,3+1,2+1,1+1}; 

Keypad keypad = Keypad( makeKeymap(keys), rowPins, colPins, ROWS, COLS );

void setup()
{
	Serial.begin(9600);
	TV.begin(PAL,8,8);
  	CPUReset();
  	TV.tone(880,50);
}

unsigned long nextFrameTime = 0;

void loop()
{
    unsigned long frameRate = CPUExecuteInstruction();
    if (frameRate != 0) {
		while (millis() < nextFrameTime) {}
		nextFrameTime = nextFrameTime + 1000 / frameRate;
	}
	char key = keypad.getKey();
	//if (key) TV.println(key);
}
