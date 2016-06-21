#include <Arduino.h>
#include "sys_processor.h"
#include "hardware.h"

#include <TVout.h>
#include <fontALL.h>

TVout TV;

void setup()
{
	Serial.begin(9600);
	TV.begin(PAL);
  	CPUReset();
}

unsigned long nextFrameTime = 0;

void loop()
{
	Serial.println("Hello world\n");
    unsigned long frameRate = CPUExecuteInstruction();
    if (frameRate != 0) {
		while (millis() < nextFrameTime) {}
		nextFrameTime = nextFrameTime + 1000 / frameRate;
	}
}
