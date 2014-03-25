void flight_data() // menu 1
{
	if (millis() - timer > 500)
	{
		timer = millis();

		switch (subMenu)
		{
		case 0:
			{

				lcd.createChar(3, LCDSAT);
				lcd.createChar(4, LCDAH);
				lcd.createChar(5, LCDAT);

				lcd.createChar(6, LCDR);
				lcd.createChar(7, LCDBR);
				lcd.createChar(8, LCDY);
				lcd.createChar(9, LCDB);

				lcd.clear();

				lcd.setCursor(0,0);
				lcd.write(4);
				lcd.print((altitude - Altitude_Home)* DIST_CONV);		//��Ը߶�
				lcd.setCursor(8,0);
				lcd.write(5);
				lcd.print(altitude * DIST_CONV );						//GPS�߶�
				lcd.setCursor(16,0);
				lcd.write(3);
				lcd.print(numSats);										//�ɼ�������
				lcd.setCursor(19,0); 
				lcd.print(gpsfix);										//��λ��ʽ

				lcd.setCursor(0,1); 
				lcd.write(6);
				lcd.print(roll,0);										//ROLL

				lcd.setCursor(5,1); 
				lcd.write(8);
				if (yaw < 0)
					yaw = yaw + 360;
				lcd.print(yaw,0);										//YAW

				lcd.setCursor(10,1); 
				lcd.write(7);
				lcd.print(Bearing_Home*2.0,0);							//��λ

				float form_bat = battery / 1000;
				if (form_bat>=10)
					lcd.setCursor(15,1);
				else
					lcd.setCursor(16,1);

				lcd.write(9); 		
				lcd.print(form_bat,1);									//��ǰ����

				if ((form_bat<VoltWarn)&& (form_bat>0.01))				//��ѹΪ0��û�д������źš�û��Xbee ��������ʾ
				{
					buzz(100,200);
				}

				break;
			}


		case 1:
			{
				Distance_Home=calc_dist(Latitude_Home, Longitud_Home, latitude, longitude);
				Distance3D_Home= sqrt((Distance_Home*Distance_Home)+((altitude-Altitude_Home)*(altitude-Altitude_Home)));

				lcd.clear();

				lcd.setCursor(0, 0);

				lcd_print_P(PSTR("D2D:"));
				lcd.print(Distance_Home * DIST_CONV);					//����

				lcd.setCursor(10,0);	

				lcd_print_P(PSTR("Angle:"));
				lcd.print(Angle_Home);									//�Ƕ�

				lcd.setCursor(0,1);	
				lcd_print_P(PSTR("D3D:"));
				lcd.print(Distance3D_Home * DIST_CONV);					//3D����

				lcd.setCursor(10,1);
				lcd_print_P(PSTR("Dir:"));
				lcd.print(SvBearingHome);

				//lcd_print_P(PSTR("Alg~"));							//�����㷨
				//lcd.print(rng_bear_alg);
				break;
			}

		case 2:
			{   

				lcd.createChar(1, LCDHOME);
				lcd.createChar(2, LCDMOD);

				lcd.clear();
				lcd.write(2);
				lcd.print(latitude,5);
				lcd.setCursor(10, 0);
				lcd.print(longitude,5);
				lcd.setCursor(0, 1);
				lcd_print_P(PSTR("~"));
				lcd.print(Latitude_Home,5);
				lcd.setCursor(10, 1);
				lcd.print(Longitud_Home,5);
				break;
			}
		case 3:

			lcd.createChar(9, LCDB);
			lcd.clear();
			lcd.setCursor(0,0);
			lcd.write(9);
			lcd_print_P(PSTR("BattV:"));
			float form_bat = battery / 1000;
			lcd.print(form_bat);	
			lcd_print_P(PSTR("V"));		
			lcd.setCursor(0,1);
			lcd_print_P(PSTR("~WarnV:"));
			lcd.print(VoltWarn);
			lcd_print_P(PSTR("V"));
			break;


		}
	}
}
