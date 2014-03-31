#ifndef _VSARDUINO_H_
#define _VSARDUINO_H_
//Board = Arduino Pro or Pro Mini (5V, 16 MHz) w/ ATmega328
#define __AVR_ATmega328p__
#define __AVR_ATmega328P__
#define ARDUINO 105
#define ARDUINO_MAIN
#define __AVR__
#define __avr__
#define F_CPU 16000000L
#define __cplusplus
#define __inline__
#define __asm__(x)
#define __extension__
#define __ATTR_PURE__
#define __ATTR_CONST__
#define __inline__
#define __asm__ 
#define __volatile__

#define __builtin_va_list
#define __builtin_va_start
#define __builtin_va_end
#define __DOXYGEN__
#define __attribute__(x)
#define NOINLINE __attribute__((noinline))
#define prog_void
#define PGM_VOID_P int
            
typedef unsigned char byte;
extern "C" void __cxa_pure_virtual() {;}

void lcd_print_P(const char *string);
void lcdPrintString(int stringId, const char *table[]);
//
//
void lcd_debug(char* msg);
void main_menu();
void SaveHomePosition();
void RestoreHomePosition();
void clearline();
void SetAntennaPosition();
void SetServoHardStop();
void position_antenna();
unsigned char Button_0();
unsigned char Button_1();
unsigned char Button_2();
unsigned char Button_3();
byte Lock_Button(byte button, byte inLock[1], int time);
void updatepan();
void updatetilt();
void Check_Buttons(byte max_options);
void buzz(int time, int freq);
void EEPROM_writeRevision();
int EEPROM_readRevision();
int EEPROM_writeParameter(int ee, parameter& value);
int EEPROM_writeFloat(int ee, float& value);
int EEPROM_readParameter(int ee, parameter& value);
void init_EEPROM();
void flight_data();
float calc_bearing(float flat1, float flon1, float flat2, float flon2);
float calc_dist(float flat1, float flon1, float flat2, float flon2);
float to_float_6(long value);
float calc_bearing_alt(float flat1, float flon1, float flat2, float flon2);
float calc_dist_alt(float flat1, float flon1, float flat2, float flon2);
void gcs_handleMessage(mavlink_message_t* msg);
void gcs_handleMessage(mavlink_message_t* msg);
void send_message(mavlink_message_t* msg);
void gcs_update();
void start_feeds();
void stop_feeds();
int get_Param_Key(char *buffer, int index);
int find_param(const char* key);
void get_params();
void list_params();
void edit_params();
void save_param();

#include "D:\Program Files\Arduino105\hardware\arduino\cores\arduino\arduino.h"
#include "D:\Program Files\Arduino105\hardware\arduino\variants\standard\pins_arduino.h" 
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\ArduStation2.pde"
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\Antenna.pde"
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\Buttons.pde"
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\Buzzer.pde"
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\EEPROM.pde"
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\Flight_Data.pde"
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\GPS_MATH.pde"
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\MAVLink.pde"
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\Params.pde"
#include "F:\Users\ENWIN\Documents\GitHub\ArduStation2\parameter.h"
#endif
