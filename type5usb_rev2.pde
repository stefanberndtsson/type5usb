/*
  Reading a serial ASCII-encoded string.
 
  This sketch demonstrates the Serial parseInt() function.
  It looks for an ASCII string of comma-separated values.
  It parses them into ints, and uses those to fade an RGB LED.
 
  Circuit: Common-anode RGB LED wired like so:
  * Red cathode: digital pin 3
  * Green cathode: digital pin 5
  * blue cathode: digital pin 6
  * anode: +5V
 
  created 13 Apr 2012
  by Tom Igoe
 
  This example code is in the public domain.
*/
 
#include <usbportability.h>
#include <oddebug.h>
#include <usbconfig.h>
#include <usbdrv.h>
#include <UsbKeyboard.h>

int scancodes[128] = {
  0, // 0x00
  120, // STOP
  129, // 0x02 VOLUME DOWN
  121, // AGAIN
  128, // 0x04 VOLUME UP
  58, // F1
  59, // F2
  67, // F10
  60, // F3
  68, // F11
  61, // F4
  69, // F12
  62, // F5
  230, // 0x0D RALT
  63, // F6
  0, // 0x0F
  64, // F7
  65, // F8
  66, // F9
  226, // 0x13 LALT
  82, // 0x14 UP
  72, // PAUSE
  70, // PrScr
  71, // Scroll Lock
  80, // 0x18 LEFT
  163, // PROPS
  122, // UNDO
  81, // 0x1B DOWN
  79, // 0x1C RIGHT
  41, // ESC
  30, // 1
  31, // 2
  32, // 3
  33, // 4
  34, // 5
  35, // 6
  36, // 7
  37, // 8
  38, // 9
  39, // 0
  45, // -
  46, // =
  53, // `
  42, // BACKSPACE
  73, // 0x2C INSERT
  127, // VOLUME OFF (=?)
  84, // KP /
  85, // KP *
  102, // 0x30 POWER OFF
  119, // 0x31 FRONT (SELECT)
  99, // 0x32 KP DEL
  124, // COPY
  74, // 0x34 HOME
  43, // TAB
  20, // Q
  26, // W
  8, // E
  21, // R
  23, // T
  28, // Y
  24, // U
  12, // I
  18, // O
  19, // P
  47, // 0x40 [
  48, // 0x41 ]
  76, // 0x42 DELETE
  101, // 0x43 COMPOSE (APPLICATION/MENU)
  95, // 0x44 KP HOME
  96, // 0x45 KP UP
  97, // 0x46 KP PGUP
  86, // 0x47 KP -
  116, // 0x48 OPEN (EXECUTE)
  125, // 0x49 PASTE
  77, // 0x4A END
  0, // 0x4B
  224, // 0x4C LCTRL
  4, // A
  22, // S
  7, // D
  9, // F
  10, // G
  11, // H
  13, // J
  14, // K
  15, // L
  51, // 0x56 ;
  52, // 0x57 '
  49, // 0x58 (\)
  40, // 0x59 RETURN
  88, // 0x5A KP ENTER
  92, // 0x5B KP LEFT
  93, // 0x5C KP 5
  94, // 0x5D KP RIGHT
  98, // 0x5E KP INS
  126, // 0x5F FIND
  75, // 0x60 PGUP
  123, // 0x61 CUT
  83, // 0x62 NUMLOCK
  225, // 0x63 LSHIFT
  29, // Z
  27, // X
  6, // C
  25, // V
  5, // B
  17, // N
  16, // M
  54, // 0x6B ,
  55, // 0x6C .
  56, // 0x6D /
  229, // 0x6E RSHIFT
  0, // 0x6F (LINE FEED ??)
  89, // 0x70 KP END
  90, // 0x71 KP DOWN
  91, // 0x72 KP PGDOWN
  0, // 0x73
  0, // 0x74
  0, // 0x75
  117, // 0x76 HELP
  57, // 0x77 CAPSLOCK
  227, // 0x78 LMETA
  44, // 0x79 SPACE
  231, // 0x7A RMETA
  78, // 0x7B PGDOWN
  0, // 0x7C
  87, // 0x7D KP +
  0, // 0x7E
  0, // 0x7F
};

// If the timer isr is corrected
// to not take so long change this to 0.
#define BYPASS_TIMER_ISR 1
#define KEYDOWN 0
#define KEYUP 1

int LED_state = 0;
int modifier_value = 0x00;
int keystate = KEYUP;


const int hexdata[16] = {KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7,
                         KEY_8, KEY_9, KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F};

void send_hex(int value) {
  UsbKeyboard.sendKeyStroke(hexdata[(value>>4)&0xf]);
  UsbKeyboard.sendKeyStroke(hexdata[value&0xf]);
}

void toggle_LED_state(int bit) {
  if(LED_state&(1<<bit)) {
    LED_state &= ~(1<<bit);
  } else {
    LED_state |= (1<<bit);
  }

  Serial.write(0x0e);
  Serial.write(LED_state);
}

void setup() {
  // initialize serial:
  Serial.begin(1200);
  // make the pins outputs:
  pinMode(6, OUTPUT);
  digitalWrite(6, LOW);
  
#if BYPASS_TIMER_ISR
  // disable timer 0 overflow interrupt (used for millis)
  TIMSK0&=!(1<<TOIE0); // ++
#endif
}

#if BYPASS_TIMER_ISR
void delayMs(unsigned int ms) {
  /*
   */ 
  for (int i = 0; i < ms; i++) {
    delayMicroseconds(1000);
  }
}
#endif

void loop() {
  UsbKeyboard.update();
  // if there's any serial available, read it:
  while (Serial.available() > 0) {
    int value = Serial.read(); 

    keystate = (value > 0x7f) ? KEYUP : KEYDOWN;
    value &= 0x7f;

    if(scancodes[value] == 71 && keystate == KEYUP) { // ScrLock
      toggle_LED_state(2);
    }

    if(scancodes[value] == 83 && keystate == KEYUP) { // NumLock
      toggle_LED_state(0);
    }

    if(scancodes[value] == 57 && keystate == KEYUP) { // CapsLock
      toggle_LED_state(3);
    }

    if(scancodes[value] > 0xdf) { // Modifier
      if(keystate == KEYDOWN) {
	modifier_value |= 1<<(scancodes[value]&0x7);
	UsbKeyboard.sendModifiers(modifier_value);
      } else {
	modifier_value = modifier_value & ~(1<<(scancodes[value]&0x7));
	UsbKeyboard.sendModifiers(modifier_value);
      }
    } else if(value == 0x7f) {
      UsbKeyboard.clearKeys(modifier_value);
    } else if(scancodes[value] == 72) { // PAUSE
      if(keystate == KEYUP) { send_hex(LED_state); }
    } else {
      if(keystate == KEYDOWN) {
	UsbKeyboard.sendKeypress(scancodes[value], modifier_value);
      } else {
	UsbKeyboard.sendKeyrelease(scancodes[value], modifier_value);
      }
    }

    //UsbKeyboard.sendKeyStroke(KEY_B, MOD_GUI_LEFT);
      
    //    UsbKeyboard.sendKeyStroke(hexdata[(value>>4)&0xf]);
    //    UsbKeyboard.sendKeyStroke(hexdata[value&0xf]);
    //    UsbKeyboard.sendKeyStroke(KEY_ENTER);

#if BYPASS_TIMER_ISR  // check if timer isr fixed.
    delayMs(20);
#else
    delay(20);
#endif
  }
}

