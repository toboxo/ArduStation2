void SaveHomePosition() // Used to save lat/lon/altitude for tilt/pan computations
{
	Latitude_Home=latitude;
	Longitud_Home=longitude;
	Altitude_Home = altitude;
	eeprom_busy_wait();
	ee.write_float(0x00,Latitude_Home);
	eeprom_busy_wait();
	ee.write_float(0x04,Longitud_Home);
	eeprom_busy_wait();
	eeprom_write_dword((unsigned long*)0x08,(long)(Altitude_Home));

}

void RestoreHomePosition()
{
	eeprom_busy_wait();
	Latitude_Home=ee.read_float(0x00);
	eeprom_busy_wait();
	Longitud_Home=ee.read_float(0x04);
	eeprom_busy_wait();
	Altitude_Home=(long)eeprom_read_dword((unsigned long*)0x08);
	eeprom_busy_wait();
}
void clearline()
{
	lcd.setCursor(0,0);
	lcd_print_P(PSTR("                    "));
}
void SetAntennaPosition()
{


	if (pan_pos>180) 
		pan_pos=180;
	if (pan_pos < 0)
		pan_pos=0;
#if PANREVERSE == 0
	Pan.slowmove(180 - pan_pos,PAN_SPEED);
#else
	Pan.slowmove(pan_pos,PAN_SPEED);
#endif

#if TILTREVERSE == 0
	Tilt.slowmove(tilt_pos,TILT_SPEED);
#else
	Tilt.slowmove(tilt_pos_upper_limit+tilt_pos_lower_limit- tilt_pos,TILT_SPEED);
#endif 


	lcd.clear();
	if (editServo<2)
	{
		if (editServo==0)
			lcd_print_P(PSTR("~"));
		else 
			lcd_print_P(PSTR(" "));
		lcd_print_P(PSTR("Pan:"));
		lcd.print(pan_pos*2);
		lcd.setCursor(10,0);
		if (editServo==1)
			lcd_print_P(PSTR("~"));
		else 
			lcd_print_P(PSTR(" "));
		lcd_print_P(PSTR("Tilt:"));
		lcd.print(tilt_pos_upper_limit - tilt_pos);
		lcd.setCursor(0,1);
		lcd_print_P(PSTR("usec:"));
		lcd.print(map( pan_pos, 0,180,panLow,panHigh));
		lcd.setCursor(10,1);
		lcd_print_P(PSTR("usec:"));
		lcd.print(map( tilt_pos, 0,180,tiltLow,tiltHigh));
	}
	if (editServo==2||editServo==3)
	{
		lcd.clear();
		lcd_print_P(PSTR("Set Pan Low & High"));
		lcd.setCursor(0,1);
		if (editServo==2)
			lcd_print_P(PSTR("~L:"));
		else
			lcd_print_P(PSTR(" L:"));
		lcd.print(panLow);
		lcd.setCursor(10,1);
		if (editServo==3)
			lcd_print_P(PSTR("~H:"));
		else
			lcd_print_P(PSTR(" H:"));
		lcd.print(panHigh); 
	}
	if (editServo>3)
	{
		lcd.clear();
		lcd_print_P(PSTR("Set Tilt Low & High"));
		lcd.setCursor(0,1);
		if (editServo==4)
			lcd_print_P(PSTR("~L:"));
		else
			lcd_print_P(PSTR(" L:"));
		lcd.print(tiltLow);
		lcd.setCursor(10,1);
		if (editServo==5)
			lcd_print_P(PSTR("~H:"));
		else
			lcd_print_P(PSTR(" H:"));
		lcd.print(tiltHigh); 
	}
	redraw=0;   
}

//AntStop

void SetServoHardStop() 
{
	chg_angle=0;
	if (pan_pos>180) 
		pan_pos=180;
	if (pan_pos < 0)
		pan_pos=0;
	Pan.slowmove(pan_pos,PAN_SPEED);
	lcd.clear();

	if (subMenu==1)
		lcd_print_P(PSTR(" "));
	else
		lcd_print_P(PSTR("~"));

	lcd_print_P(PSTR("Pan:"));
	lcd.print(pan_pos);

	lcd.setCursor(10,0);

	if (subMenu==1)
		lcd_print_P(PSTR("~"));
	else
		lcd_print_P(PSTR(" "));
 
	lcd_print_P(PSTR("Tilt:"));
	lcd.print(tilt_pos);

	lcd.setCursor(0,1);
	lcd_print_P(PSTR("Compass="));
	lcd.print((180.0-pan_pos)*2.0);
	offset = pan_pos - 90.0;  
	redraw=0;   
}

void position_antenna()
{
	// Pick which algorithm to use
	if (rng_bear_alg == 0)
	{
		Distance_Home=calc_dist(Latitude_Home, Longitud_Home, latitude, longitude);
		Bearing_Home=calc_bearing(Latitude_Home, Longitud_Home, latitude, longitude);
	}
	else
	{
		Distance_Home=calc_dist_alt(Latitude_Home, Longitud_Home, latitude, longitude);
		Bearing_Home=calc_bearing_alt(Latitude_Home, Longitud_Home, latitude, longitude);
	}


	SvBearingHome=Bearing_Home;
	Angle_Home=ToDeg(atan((float)(altitude-Altitude_Home)/(float)Distance_Home));
#if PANREVERSE == 0 // Don't do following line if reversing servo
	Bearing_Home = 180-(Bearing_Home/2.0);
#endif    
	// Offset for servo limit 
	Bearing_Home = Bearing_Home + offset;
	if (Bearing_Home > 180.0)
		Bearing_Home = Bearing_Home - 180.0;
	else
	{
		if (Bearing_Home <0.0)
			Bearing_Home = Bearing_Home + 180.0;
	}
	Pan.slowmove(Bearing_Home,PAN_SPEED); //180-(Bearing_Home/2.0));
	Constrain_Angle_Home = constrain(Angle_Home,0,90);

#if TILTREVERSE == 0 // Don't do following line if reversing servo
	Constrain_Angle_Home = 90-Constrain_Angle_Home;
#endif

	int tilt_position;
	tilt_position = Constrain_Angle_Home + tilt_pos_lower_limit;

	if (tilt_position > tilt_pos_upper_limit) tilt_position = tilt_pos_upper_limit;

	if (tilt_position < tilt_pos_lower_limit) tilt_position = tilt_pos_lower_limit;

	Tilt.slowmove(tilt_position,TILT_SPEED);

}
