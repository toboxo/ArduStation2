#define MAVLINK10  // Uncomment for MAVLINK 1.0, otherwise comment out for MAVLINK 0.9

#include <FastSerial.h>
#include <GCS_MAVLink.h>
#include <avr/pgmspace.h>
#include <LiquidCrystal.h>
#include <EEPROM.h>
#include <AP_EEPROMB.h>

#include <VarSpeedServo.h>
#include "parameter.h"

AP_EEPROMB ee;
#undef PROGMEM 
#define PROGMEM __attribute__(( section(".progmem.data") )) 

#undef PSTR 
#define PSTR(s) (__extension__({static const char __c[] PROGMEM = (s); &__c[0];})) 

#define SERIAL_BAUD 57600
#define BUZZERON // is the buzzer on?
FastSerialPort0(Serial);

// data streams active and rates
#define MAV_DATA_STREAM_POSITION_ACTIVE 1
#define MAV_DATA_STREAM_RAW_SENSORS_ACTIVE 1
#define MAV_DATA_STREAM_EXTENDED_STATUS_ACTIVE 1
#define MAV_DATA_STREAM_RAW_CONTROLLER_ACTIVE 1
#define MAV_DATA_STREAM_EXTRA1_ACTIVE 1
#define MAV_DATA_STREAM_EXTRA2_ACTIVE 1

// update rate is times per second (hz)
#define MAV_DATA_STREAM_POSITION_RATE 1
#define MAV_DATA_STREAM_RAW_SENSORS_RATE 1
#define MAV_DATA_STREAM_EXTENDED_STATUS_RATE 1
#define MAV_DATA_STREAM_RAW_CONTROLLER_RATE 1
#define MAV_DATA_STREAM_EXTRA1_RATE 1
#define MAV_DATA_STREAM_EXTRA2_RATE 1

#define GET_PARAMS_TIMEOUT 200 //(20 seconds)

// store strings in flash memory
#define MAIN_MENU 0
#define START_FEEDS 1
#define STOP_FEEDS 2
#define ANTS 3
#define ANT_TEST 4
#define GET_PARAMS 5
#define EDIT_VIEW_PARAMS 6
#define FLIGHT_DATA 7
#define INIT_EEPROM 8
#define SERIAL_DIAG 9
#define EDIT_PARAM 10
#define SAVE_PARAM 11 

#define APM_PARAMS 37   //Check in Params.pde that the set of APM parameters are numberd 0 to this number -1
#define ACM_PARAMS 48   //Check in Params.pde that the set of ACM parameters are number 0 to this number - 1

#define DIST_CONV 1.0   // For distance display in meters choose 0.0, for feet 3.2808

LiquidCrystal lcd(2, 3, 4, 5, 6, 7); //初始化LCD 234567

void lcd_print_P(const char *string)
{
	char c;
	while( (c = pgm_read_byte(string++)) )
		lcd.LiquidCrystal::write(c);
}

#define toRad(x) (x*PI)/180.0
#define toDeg(x) (x*180.0)/PI

unsigned long hb_timer;
unsigned long timer;

#define ALTITUDE_CHOICE 1			//选择GPS海拔高度或VFR HUD（来自气压）（0 = GPS, 1 = VFR HUD）
#define TILT_SPEED 0				//倾斜伺服速度（0 =旧模式（快速），1 =最慢的速度，255 =最快的速度）
#define PAN_SPEED 0					//水平伺服速度（0 =旧模式（快速），1 =最慢的速度，255 =最快的速度）
#define SERVO_MAX 2600				//舵机俯仰和滚转范围
#define SERVO_MIN 400
#define TEST_TILT 0					//测试倾斜最大和最小（校准）
#define TEST_PAN 0					//测试平台的最小和最大值（校准）
#define TEST_SOUTH 0				//测试南
VarSpeedServo Tilt;
VarSpeedServo Pan;
#define TILTLOW 591
#define TILTHIGH 2235
#define PANLOW  609					 
#define PANHIGH 2255
#define TILTREVERSE 0				// 倾斜反输出（0默认，1反向）
#define PANREVERSE 0				// 水平反向输出（0默认，1反向）
#define tilt_pos_upper_limit 140	//	倾斜最高极限（天线指向地平线）
#define tilt_pos_lower_limit 50		// 倾斜最低极限（天线指向天空）
int panLow = PANLOW;
int panHigh = PANHIGH;
int tiltLow = TILTLOW;
int tiltHigh = TILTHIGH;

//Servo变量
int pan_pos = 90;
int tilt_pos = 90;
int chg_angle = 0;
//int original_pan_pos = 90;
//int original_tilt_pos = 90;
//int original_chg_angle = 0;

byte param_rec[7];

float Latitude_Home=0;
float Longitud_Home=0;
int Altitude_Home = 0;
float Distance_Home=0;
float Distance3D_Home=0;
int Angle_Home=0;
int Constrain_Angle_Home = 0;
float Bearing_Home=0;
float SvBearingHome = 0;

float VoltWarn = 10.6;				//报警电压
float offset = 0;
//飞行数据
byte relAltitude = 0;				//如果为1显示当前GPS相对高度，0为GPS ALT海拔
float altitude=0.0;
float pitch=0;
float roll=0;
float yaw=0;
float longitude=0;
float latitude=0;
float latoffset = 0.0;
float altoffset = 100.0;
float velocity = 0;
int numSats=0;						//可用卫星数
float battery=0;					//电池电压
byte MakeNoise = 0;
int currentSMode=0;
int currentNMode=0;
int gpsfix=0;

//菜单数据
byte editServo = 0;					//0 水平 1倾斜天线 , 2编辑水平舵机-低, 3编辑水平舵机-高, 4编辑倾斜舵机-低, 5编辑倾斜舵机-高
byte menu=0;
byte subMenu=0;
byte currentOption=0;
byte lastOption=0;
int timeOut=0;
byte redraw=1;
byte waitingAck=0;
parameter editParm;
byte paramsRecv=0;
byte beat=0;
byte droneType = 1;					// 0 =不设置, 1 = APM, 2 = ACM  -可以从mavlink心跳读取,但是ACM返回0,不是2
byte autoPilot = 3;					// APM应该为3
uint8_t received_sysid=0;			// 心跳发送端系统ID
uint8_t received_compid=0;			// 心跳发送端组件ID
byte TOTAL_PARAMS = ACM_PARAMS;		// default total params to ACM set up

byte rng_bear_alg = 0;				// 0 =使用3DR算法，1＝使用杰姆斯丈夫的算法（在澳大利亚更精确）

long timeLastByte = 0;				//保存的最后一条消息字节接收时间而不是mavlink闲置，设置为0在闲置过程中，没有消息
long maxByteTime = 0;


byte numGoodHeartbeats = 0;			//检查三个有效的心跳并关闭mavlink类型错误


long lastByteTime = 0;				//保存从串口读取最后一个字节的时间
uint8_t byt[15];					//保存接收的字节数
uint8_t byt_Counter = 0;
uint8_t b_ct;
int byte_per_half_sec = 0;
int last_byte_per = 0;

//错误mavlink版本检测
byte wrongMavlinkState = 0;			//检查串口的数据，检测错误的mavlink版本，0状态意味mavlink头没有检测到，5状态表示接受了错误的mavlink格式
byte packetStartByte = 0;			//0x55 Mavlink 0.9, 0xFE Mavlink 1.0

byte LCDHEART[8] = {
	B00000,
	B01010,
	B11111,
	B11111,
	B01110,
	B00100,
	B00000,
	B00000,
};
byte LCDHOME[8] = {
	B10001,
	B01010,
	B00100,
	B01010,
	B10101,
	B00100,

	B01110,
	B00000,

};
byte LCDMOD[8] = {
	B00100,
	B00100,
	B11111,
	B11111,
	B00100,
	B00100,
	B01110,
	B00000,
};
byte LCDD[8] = {
	B00100,
	B01110,	
	B10101,
	B00100,	
	B00100,
	B10101,
	B01110,
	B00100,
};
byte LCDA[8] = {
	B00000,
	B00001,
	B00010,
	B00100,
	B01000,
	B10000,
	B11111,
	B00000,
};

byte LCDAT[8] = {
	B01000,
	B10100,
	B11101,
	B10100,
	B00000,
	B11101,
	B01000,
	B01000,
};
byte LCDSAT[8] = {
	B11111,
	B11111,
	B00100,
	B01110,
	B01110,
	B00100,
	B11111,
	B11111,
};
byte LCDAH[8] = {
	B01000,
	B10100,
	B11101,
	B10100,
	B00000,
	B10101,
	B11100,
	B10100,
};
byte LCDR[8] = {
	B11111,
	B10011,
	B10101,
	B10011,
	B10101,
	B10101,
	B11111, 
}; 
byte LCDBR[8] = {
	B11111,
	B10011,
	B10101,
	B10011,
	B10101,
	B10011,
	B11111, 
}; 
byte LCDY[8] = {
	B11111,	
	B10101,
	B10101,	
	B11011,
	B11011,
	B11011,
	B11111, 
}; 
byte LCDB[8] = {
	B01110,
	B11111,	
	B10001,
	B11111,	
	B10001,
	B11111,
	B10001,
	B11111,
}; 

void lcdPrintString(int stringId, const char *table[])
{
	char buffer[21];
	strcpy_P(buffer, (char*)pgm_read_word(&(table[stringId])));
	lcd.LiquidCrystal::print(buffer);
}

void setup()
{
	Serial.begin(SERIAL_BAUD);
	lcd.createChar(0, LCDHEART);
	lcd.createChar(1, LCDHOME);
	lcd.createChar(2, LCDMOD);




	Pan.attach(9,PANLOW,PANHIGH);			//PAN Servos
	Tilt.attach(10,TILTLOW,TILTHIGH);		//Tilt Elevator


	delay(4000);

	lcd.begin(20, 2);
	pinMode(8,OUTPUT);						//Pin mode as output to control buzzer (analog0)
	pinMode(11,OUTPUT);

	//按键上拉
	pinMode	(A0,INPUT);
	pinMode	(A1,INPUT);
	pinMode	(A2,INPUT);
	pinMode	(A3,INPUT);
	digitalWrite(A0,HIGH);
	digitalWrite(A1,HIGH);
	digitalWrite(A2,HIGH);
	digitalWrite(A3,HIGH);

	lcd.clear();
	lcd_print_P(PSTR("APM AT"));
	lcd.setCursor(8,0 );
#ifdef MAVLINK10
	lcd_print_P(PSTR("MAVLink1.0"));
#else // MAVLINK10
	lcd_print_P(PSTR("MAVLink0.9"));
#endif // MAVLINK10
	delay(2000);
	if (EEPROM_readRevision() != 0)
	{
		init_EEPROM();
		EEPROM_writeRevision();
	} 
	RestoreHomePosition(); 
	lcd.setCursor(0,1 );
	lcd_print_P(PSTR("Starting xbee..."));
	Serial.println("...");
	delay(2000);
}

void loop()
{
	//如果我们检测到错误的Mavlink版本，将显示"wrong version"，不处理菜单.

	if (numGoodHeartbeats<3) // Shut this test down when we get 3 good valid Mavlink heartbeats
	{
		if ( wrongMavlinkState==6)
		{
			lcd.clear();
			lcd_print_P(PSTR("Err:")); 
#ifdef MAVLINK10
			lcd_print_P(PSTR("Rec Mavlink 0.9"));
#else // MAVLINK10
			lcd_print_P(PSTR("Rec Mavlink 1.0"));
#endif // MAVLINK10
			lcd.setCursor(0,1);
			lcd.print(packetStartByte);
			while (1) // lock up the software with message on LCD
			{
			}
		}
	}

	//主菜单逻辑
	switch (menu)
	{
	case MAIN_MENU: // main menu
		{
			if (redraw == 1)
				main_menu();
			break;
		}
	case START_FEEDS: // start feeds
		{
			start_feeds();
			break;
		}
	case STOP_FEEDS: // stop feeds
		{
			stop_feeds();
			break;
		}  
	case ANTS: // ANTS  - replaced PIDS adjustment with set servo hard stop menu
		{
			if (redraw == 1)
				SetServoHardStop();
			break;
		}
	case ANT_TEST: //Antenna Test
		{
			if (redraw == 1)
				SetAntennaPosition();
			break;
		}
	case GET_PARAMS: // get params
		{
			get_params();
			//EEPROM_writeParamCount(totalParams);
			break;
		}
	case EDIT_VIEW_PARAMS: // view/edit params
		{
			if (redraw == 1)
				list_params();
			break; 
		}
	case FLIGHT_DATA: // flight data
		{
			flight_data();
			break;
		}    
	case INIT_EEPROM: // init eeprom
		{
			init_EEPROM();
			break;
		}
	case SERIAL_DIAG: // Serial port & parameter diagnostics
		{
			if (subMenu == 1) 
			{

				for (b_ct = 0; b_ct<15; b_ct++)
				{
					if (b_ct==0)
						lcd.setCursor(0,0);
					if (b_ct==7)
						lcd.setCursor(0,1);
					if (byt[b_ct]<16)
						lcd.print(0);
					lcd.print(byt[b_ct],HEX);
					lcd.print(" ");	
				}
			}
			else
			{
				lcd.setCursor(0,0);
				lcd_print_P(PSTR("ParamRec["));
				if (last_byte_per<10)
					lcd.print(" ");
				if (last_byte_per<100)
					lcd.print(" ");
				lcd.print(last_byte_per);
				lcd_print_P(PSTR("]"));

				lcd.setCursor(0,1);
				for (b_ct = 0; b_ct<7; b_ct++)			 
				{ 
					if (param_rec[b_ct] < 16)
						lcd.print(0);
					lcd.print(param_rec[b_ct],HEX);
					lcd.print(" ");	
				}
			}
			break;
		}

	case EDIT_PARAM:
		{
			if (redraw == 1)
				edit_params();
			break;
		}
	case SAVE_PARAM:
		{
			save_param();
			break; 
		}
	}
	if (millis() - hb_timer > 500)
	{
		hb_timer = millis();
		last_byte_per = byte_per_half_sec;
		byte_per_half_sec = 0;
		//    lcd.setCursor(0,3); // Diagnostic for Mavlink parser reset code
		//    lcd.print(maxByteTime);
		lcd.setCursor(19,3);
		if (beat == 1)
		{
			beat = 0;
			lcd.LiquidCrystal::write((uint8_t)0);
		}
		//	else
		//	lcd_print_P(PSTR(" "));
	}
	gcs_update();
	Check_Buttons(4);
}

void lcd_debug(char* msg)
{
	lcd.setCursor(0,0);
	lcd.print(msg);
}

void main_menu() //主菜单显示
{
	lcd.clear();
	if (currentOption < 4)
	{
		lcd.setCursor(1,0);
		lcd_print_P(PSTR("FeedsRun"));
		lcd.setCursor(11,0);
		lcd_print_P(PSTR("FeedsEnd"));
		lcd.setCursor(1,1);
		lcd_print_P(PSTR("AntStop"));
		lcd.setCursor(11,1);
		lcd_print_P(PSTR("AntTest"));
		lcd.setCursor(19,1); 
	}
	if (currentOption > 3 && currentOption < 8)
	{
		lcd.setCursor(1,0);
		lcd_print_P(PSTR("GetParams"));
		lcd.setCursor(11,0);
		lcd_print_P(PSTR("EV-Params"));
		lcd.setCursor(1,1);
		lcd_print_P(PSTR("FlightDat"));
		lcd.setCursor(11,1);
		lcd_print_P(PSTR("InitEPROM"));
	}
	if (currentOption >7 && currentOption<9)
	{ 
		lcd.setCursor(1,0);
		lcd_print_P(PSTR("Debug"));
	}

	switch (currentOption%4)
	{
	case 0:
		lcd.setCursor(0,0);
		break;
	case 1:
		lcd.setCursor(10,0);
		break;
	case 2:
		lcd.setCursor(0,1);
		break;
	case 3:
		lcd.setCursor(10,1);
		break;
	} 

	lcd.print("~");
	redraw = 0;  
}

//int availableMemory() {
//	int size = 2048;
//	byte *buf;
//	while ((buf = (byte *) malloc(--size)) == NULL);
//	free(buf);
//	return size;
//}
