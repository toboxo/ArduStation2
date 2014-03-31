unsigned char Button_0()
{
	if (digitalRead(A0)==HIGH)
		return 0;
	delay(10);
	if (digitalRead(A0)==HIGH)
		return 0;
	return 1;
}

unsigned char Button_1()
{
	if (digitalRead(A1)==HIGH)
		return 0;
	delay(10);
	if (digitalRead(A1)==HIGH)
		return 0;
	return 1;
}

unsigned char Button_2()
{
	if (digitalRead(A2)==HIGH)
		return 0;
	delay(10);

	if (digitalRead(A2)==HIGH)
		return 0;
	return 1;
}

unsigned char Button_3()
{
	if (digitalRead(A3)==HIGH)
		return 0;
	delay(10);
	if (digitalRead(A3)==HIGH)
		return 0;
	return 1;
}



/*********************************************/
byte Lock_Button(byte button, byte inLock[1], int time)
{
	if(button == 1)
	{
		if(inLock[0] == 0)
		{
			inLock[0]=1;
			buzz(time,200);
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		inLock[0]=0;
		return 0; 
	}
}

void updatepan()
{
	Pan.attach(9,panLow,panHigh);
}

void updatetilt()
{
	Tilt.attach(10,tiltLow,tiltHigh);
}

void Check_Buttons(byte max_options) //Reading the buttons. 
{
	static byte lock[6];
	byte button_byte=0;

	if(Lock_Button(Button_0(), &lock[0], 200)) // UP
	{
		if (menu == MAIN_MENU)
		{
			if (currentOption > 0)
			{
				currentOption--;
				redraw = 1;
			}
		}
		else if ((menu==FLIGHT_DATA) && (subMenu==3))
		{
			if (VoltWarn<12.6)
			{
				VoltWarn+=0.1;
			}
		}
		else if ((menu==FLIGHT_DATA) && (subMenu==2))
		{
			SaveHomePosition();
		}
		else if (menu == EDIT_VIEW_PARAMS)
		{
			currentOption--;
			redraw = 1;
		}
		else if (menu == ANT_TEST)
		{    
			switch (editServo)
			{
			case 0:
				pan_pos+=5;
				break;
			case 1:
				tilt_pos+=5;
				if (tilt_pos > tilt_pos_upper_limit) 
					tilt_pos = tilt_pos_upper_limit;
				break;
			case 2:
				panLow+=5;
				if (panLow > SERVO_MAX)
					panLow = SERVO_MAX;
				updatepan();
				break;
			case 3:
				panHigh+=5;
				if (panHigh > SERVO_MAX)
					panHigh = SERVO_MAX;
				updatepan();
				break;
			case 4:
				tiltLow+=5;
				if (tiltLow > SERVO_MAX)
					tiltLow = SERVO_MAX;
				updatetilt();
				break;
			case 5:
				tiltHigh+=5;
				if (tiltHigh > SERVO_MAX)
					tiltHigh = SERVO_MAX;
				updatetilt();
				break;
			}
			redraw = 1;   
		}
		else if (menu == ANTS)		//ANTS
		{
			if (subMenu ==1)
				tilt_pos += 5;
			else
				pan_pos += 5;
			redraw = 1;
		}
		else if (menu == 10)
		{
			editParm.value += .01;
			redraw = 1;      
		}
	}
	if(Lock_Button(Button_3(), &lock[1], 200)) // BACK
	{
		if (menu == EDIT_VIEW_PARAMS)
			currentOption = lastOption;
		if (menu == FLIGHT_DATA || menu == ANTS || menu == GET_PARAMS || menu == EDIT_VIEW_PARAMS || menu==SERIAL_DIAG)
		{
			menu = MAIN_MENU;
			subMenu = 0;
		}
		else if (menu == ANT_TEST) 
		{
			menu = MAIN_MENU;
			subMenu = 0;
		}
		else if (menu == 10)
			menu = EDIT_VIEW_PARAMS;
		redraw = 1;
	}
	if(Lock_Button(Button_2(), &lock[3], 200)) // OK
	{
		if(menu == MAIN_MENU)
		{
			if (currentOption == 0) // start feeds
			{
				menu = START_FEEDS;
			}
			else if (currentOption == 1) // stop feeds
			{
				menu = STOP_FEEDS;
			}

			else if (currentOption == 2) // Antenna Stop
			{
				pan_pos = 90;
				tilt_pos = 90;
				menu = ANTS;
				subMenu = 0;
				redraw = 1;
			}
			else if (currentOption == 3) // Antenna Test
			{
				pan_pos = 90;
				tilt_pos = 90;
				menu = ANT_TEST;
				subMenu = 0;
				redraw = 1;
			}
			else if (currentOption == 4) // get_params
			{
				for (int i1 = 0; i1<7; i1++)
					param_rec[i1] = 0;
				menu = GET_PARAMS;
				paramsRecv = 0;
				timeOut = GET_PARAMS_TIMEOUT;
				redraw=1;
			}
			else if (currentOption == 5) // view/edit params
			{
				menu = EDIT_VIEW_PARAMS;
				subMenu = 0;
				lastOption = currentOption;
				currentOption = 0;        
				redraw = 1;
			}
			else if (currentOption == 6) // flight data
			{
				menu = FLIGHT_DATA;
				subMenu = 0;
				redraw = 1;
			}
			else if (currentOption == 7) // init_eeprom
			{
				menu = INIT_EEPROM;
				redraw = 1;
			}
			else if (currentOption==8) // Serial stat
			{
				menu = SERIAL_DIAG;
				redraw = 1;
				subMenu = 0;
				lcd.clear();
			}
		}
		else if (menu == EDIT_VIEW_PARAMS) // edit single param based on current option
		{
			menu = 10; // edit single param
			redraw = 1;
		}
		else if (menu == 10) // save parameter / wait for ack
		{
			menu = 11; // save single param
			waitingAck = 1;
			timeOut = 100;
			redraw = 1;
		}
		else if (menu==FLIGHT_DATA)
		{
			if (subMenu < 3) {
				redraw=1;
				subMenu++;
			}
			else
			{
				subMenu=0;
				redraw=1;
			}
		}
		else if (menu==ANTS)
		{
			subMenu = 1-subMenu;
			redraw = 1;
		}
		else if (menu == ANT_TEST)
		{
			editServo++;
			if (editServo>5)
				editServo =0;
			redraw = 1;
		}
		else if (menu==SERIAL_DIAG)
		{
			subMenu = 1-subMenu;
			lcd.clear();
			redraw = 1;
		}
	}
	if(Lock_Button(Button_1(), &lock[5], 200)) // DOWN
	{
		if (menu == MAIN_MENU)
		{
			if (currentOption < 8)
			{
				redraw = 1;
				currentOption++;
			}
		}
		else if ((menu==FLIGHT_DATA) && (subMenu==3))
		{

			if (VoltWarn>9.9)
			{
				VoltWarn-=0.1;
			}
		}
		else if ((menu==FLIGHT_DATA) && (subMenu==2))
		{
			SaveHomePosition();
		}
		else if (menu == EDIT_VIEW_PARAMS)
		{
			currentOption++;
			redraw = 1;
		}
		else if (menu == ANT_TEST)
		{
			switch (editServo)
			{
			case 0:
				pan_pos-=5;
				break;
			case 1:
				tilt_pos-=5;
				if (tilt_pos < tilt_pos_lower_limit) 
					tilt_pos = tilt_pos_lower_limit;
				break;
			case 2:
				panLow-=5;
				if (panLow < SERVO_MIN)
					panLow = SERVO_MIN;
				updatepan();
				break;
			case 3:
				panHigh-=5;
				if (panHigh < SERVO_MIN)
					panHigh = SERVO_MIN;
				updatepan();
				break;
			case 4:
				tiltLow-=5;
				if (tiltLow < SERVO_MIN)
					tiltLow = SERVO_MIN;
				updatetilt();
				break;
			case 5:
				tiltHigh-=5;
				if (tiltHigh < SERVO_MIN)
					tiltHigh = SERVO_MIN;
				updatetilt();
				break;
			}
			redraw = 1;
		}
		else if (menu == ANTS)
		{
			if (subMenu ==1)
				tilt_pos -= 5;
			else
				pan_pos -= 5;
			redraw = 1;
		}
		else if (menu == 10)
		{
			editParm.value -= .01;
			redraw = 1;      
		}
	} 
}
