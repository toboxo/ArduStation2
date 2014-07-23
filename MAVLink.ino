void gcs_handleMessage(mavlink_message_t* msg)
{
  switch (msg->msgid) {
    case MAVLINK_MSG_ID_HEARTBEAT:
    {
      if (numGoodHeartbeats < 3)
        numGoodHeartbeats++;
      mavlink_heartbeat_t packet;
      mavlink_msg_heartbeat_decode(msg, &packet);
      droneType = packet.type; // Don't pick up from the heartbeat now since there is some weirdness when the Planner is running
                                 // and ArduPlane is running (get packet with type = 1 and type =0 also - confused this logic) 
                                  
      autoPilot = packet.autopilot;
      if ((*msg).sysid != 0xff) // do not process mission planner heartbeats if we have two receiver xbees
      {
        received_sysid = (*msg).sysid; // save the sysid and compid of the received heartbeat for use in sending new messages
      
        received_compid = (*msg).compid;
      
#ifdef  MAVLINK10
        if (droneType == MAV_TYPE_FIXED_WING) {
#else // MAVLINK10
        if (droneType == MAV_FIXED_WING ) {
#endif // MAVLINK10

          TOTAL_PARAMS = APM_PARAMS;
          
#ifdef MAVLINK10
        } else if (droneType == MAV_TYPE_GENERIC) {
#else // MAVLINK10
        } else if (droneType == MAV_GENERIC) {
#endif // MAVLINK10

          TOTAL_PARAMS = ACM_PARAMS;
        } else {
          TOTAL_PARAMS = ACM_PARAMS;
        }
      }
      beat = 1;
      break;
    }
   case MAVLINK_MSG_ID_ATTITUDE:
    {
      // decode
      mavlink_attitude_t packet;
      mavlink_msg_attitude_decode(msg, &packet);
      pitch = toDeg(packet.pitch);
      yaw = toDeg(packet.yaw);
      roll = toDeg(packet.roll);
      break;
    }
#ifdef MAVLINK10
    case MAVLINK_MSG_ID_GPS_RAW_INT:
#else // MAVLINK10
    case MAVLINK_MSG_ID_GPS_RAW:
#endif // MAVLINK10

    {
      // decode

#ifdef MAVLINK10
      mavlink_gps_raw_int_t packet;
      mavlink_msg_gps_raw_int_decode(msg, &packet);
      velocity = packet.vel;
      latitude = packet.lat/1e7;
      latoffset += 0.5;
      latitude = latitude + .00001;
      longitude = packet.lon/1e7;
#if ALTITUDE_CHOICE == 0
      altitude = packet.alt/1000.0;
      altitude = altitude - latoffset + altoffset;
#endif
      numSats = packet.satellites_visible;
#else // MAVLINK10
      mavlink_gps_raw_t packet;
      mavlink_msg_gps_raw_decode(msg, &packet); 
      velocity = packet.v; 
      latitude = packet.lat;
      longitude = packet.lon; 
      altitude = packet.alt;   
#endif // MAVLINK10
      position_antenna();
      gpsfix = packet.fix_type;
      break;
    }
    case MAVLINK_MSG_ID_GPS_STATUS:
    {
      mavlink_gps_status_t packet;
      mavlink_msg_gps_status_decode(msg, &packet); 
#ifdef MAVLINK10      
 //     numSats = packet.satellites_visible;
#else
        numSats = packet.satellites_visible;
#endif
      break;
    }
    case MAVLINK_MSG_ID_RAW_PRESSURE:
    {
      // decode
      mavlink_raw_pressure_t packet;
      mavlink_msg_raw_pressure_decode(msg, &packet);
      break;
    }
    case MAVLINK_MSG_ID_SYS_STATUS:
    {

      mavlink_sys_status_t packet;
      mavlink_msg_sys_status_decode(msg, &packet);
#ifdef MAVLINK10
      battery=packet.voltage_battery; 
      if (battery < (12.4 * 1000.0))
         MakeNoise = 1;
      else
        MakeNoise = 0; 
#else // MAVLINK10
      currentSMode = packet.mode;
      currentNMode = packet.nav_mode;
      battery = packet.vbat;
#endif // MAVLINK10
      break;
    }
    case MAVLINK_MSG_ID_VFR_HUD:
    {
      mavlink_vfr_hud_t packet;
      mavlink_msg_vfr_hud_decode(msg, &packet);
#if ALTITUDE_CHOICE == 1
      altitude = packet.alt;
#endif
      break;
    }
    case MAVLINK_MSG_ID_PARAM_VALUE:
    {
      // decode
      mavlink_param_value_t packet;
      mavlink_msg_param_value_decode(msg, &packet);
      const char * key = (const char*) packet.param_id;
      char b[16];
      for (int i=0; i<16; i++)
         b[i] = key[i];
      b[15] = 0;
      int loc = find_param(b);

      if (loc != -1)
      {
        float value;
        parameter temp;
        //strcpy(temp.key, key);
        //temp.value = packet.param_value;
        value = packet.param_value;
        EEPROM_writeFloat((loc * sizeof(temp))+sizeof(temp.key), value);         
        //EEPROM_writeParameter((loc * sizeof(temp))+sizeof(temp.key), temp);         
        paramsRecv++;
        int bytval = loc / 8;
        int offset = loc - (bytval * 8);
        param_rec[bytval] = param_rec[bytval] | (1<<offset); 
      }
      if (waitingAck == 1)
      {        
        if (strcmp(key, editParm.key) == 0)
        {
          waitingAck = 0;
        }
      }
      //else
      //  timeOut = 100; // each time we get another parameter reset the timeout
      //redraw = 1;
      break;
    }
  }
}

void send_message(mavlink_message_t* msg)
{
  uint8_t buf[MAVLINK_MAX_PACKET_LEN];
  
//  Serial.write(MAVLINK_STX);
//  Serial.write(msg->len);
//  Serial.write(msg->seq);
//  Serial.write(msg->sysid);
//  Serial.write(msg->compid);
//  Serial.write(msg->msgid);
  uint16_t len = mavlink_msg_to_send_buffer(buf, msg);
  for(uint16_t i = 0; i < len; i++)
  {
    Serial.write(buf[i]);
  }
//  Serial.write(msg->ck_a);
//  Serial.write(msg->ck_b);
}

void gcs_update()
{
    // receive new packets
    mavlink_message_t msg;
    mavlink_status_t *status;

//    if (MakeNoise==1) 
//    {
//      buzz(200,200);
//    }
    // process received bytes
    while(Serial.available())
    {
        uint8_t c = Serial.read();
        byte_per_half_sec++;
        
        if (((millis() - lastByteTime) > 500) || (byt_Counter != 0))
        {
           byt[byt_Counter++] = c;
           if (byt_Counter == 15)
           {
              byt_Counter = 0;
              lastByteTime = millis();
           }
            // Large gap in read bytes, record byte 
        }
        // Have a byte - check if we are parsing, if we are there should not be a large time since last parsed byte
        // if there is too much time, we lost message bytes so abort the previous parse and start fresh on this new
        // message.
        status = mavlink_get_channel_status(0);
        if (status->parse_state != MAVLINK_PARSE_STATE_IDLE)
        {
           if (timeLastByte != 0)
             if ((millis() - timeLastByte) > maxByteTime)
               maxByteTime = millis()-timeLastByte;
           if ((millis() - timeLastByte) > 300)  // .3 seconds
           {
             timeLastByte = 0; // We're going back to idle since we're aborting
             status->parse_state = MAVLINK_PARSE_STATE_IDLE; // abort the parse - start fresh with the current received byte
           }
           else
              timeLastByte = millis(); // Update the time to that of the current byte
        }
       
        
        // Wrong Mavlink detector.  Separately parse messages with wrong packet start sign
        // Mavlink 1.0 expects first byte of 0xFE
        // Mavlink 0.9 expects first byte of 0x55

        // Look for 0x55 with right format - 0x55 0x03 0xignore 0xignore 0xignore 0x00    - Mavlink 0.9 heartbeat 
        // Look for 0xFE with right format - 0xFE 0x08 0xignore 0xignore 0xignore 0x00    - Mavlink 1.0 heartbeat
        switch (wrongMavlinkState)
        {
            case 0:
#ifdef MAVLINK10
               if (c== 0x55) {
#else // MAVLINK10
               if (c== 0xFE) {
#endif // MAVLINK10
                  packetStartByte = c;
                  wrongMavlinkState = 1;
               }
               break;
            
            case 1: 
#ifdef MAVLINK10
               if (c== 0x03)
#else // MAVLINK10
               if (c== 0x09)
#endif // MAVLINK10
                  wrongMavlinkState = 2;
               else 
               {
                  packetStartByte = 0;
                  wrongMavlinkState = 0;
               }
               break;
            case 2:
            case 3:
            case 4:
               wrongMavlinkState++;
               break;
               
            case 5:
               if (c == 0x00)
               {
                 wrongMavlinkState = 6;
               }
               else
               {
                  wrongMavlinkState = 0;
                  packetStartByte = 0;
               }
               break;
            }
        
                   
                 
        // Try to get a new message
        if(mavlink_parse_char(0, c, &msg, status)) gcs_handleMessage(&msg);
        // If time value is 0 we were in idle, check if not in idle and receiving message bytes
        if (timeLastByte == 0)
        {
          if (status->parse_state != MAVLINK_PARSE_STATE_IDLE) 
          {
            timeLastByte = millis(); // Save current time since start run - compared when receiving bytes
          } 
        }
    }
}

void start_feeds()
{
  lcd.clear();
  lcd_print_P(PSTR("Starting feeds!"));
  mavlink_message_t msg;
  mavlink_msg_request_data_stream_pack(127, 0, &msg, received_sysid, received_compid, MAV_DATA_STREAM_RAW_SENSORS, MAV_DATA_STREAM_RAW_SENSORS_RATE, MAV_DATA_STREAM_RAW_SENSORS_ACTIVE);
  send_message(&msg);
  delay(10);
//  mavlink_message_t msg3;
  mavlink_msg_request_data_stream_pack(127, 0, &msg, received_sysid, received_compid, MAV_DATA_STREAM_EXTENDED_STATUS, MAV_DATA_STREAM_EXTENDED_STATUS_RATE, MAV_DATA_STREAM_EXTENDED_STATUS_ACTIVE);
  send_message(&msg);
  delay(10);
//  mavlink_message_t msg4;
  mavlink_msg_request_data_stream_pack(127, 0, &msg, received_sysid, received_compid, MAV_DATA_STREAM_RAW_CONTROLLER, MAV_DATA_STREAM_RAW_CONTROLLER_RATE, MAV_DATA_STREAM_RAW_CONTROLLER_ACTIVE);
  send_message(&msg);
  delay(10);
//  mavlink_message_t msg1;
  mavlink_msg_request_data_stream_pack(127, 0, &msg, received_sysid, received_compid, MAV_DATA_STREAM_POSITION, MAV_DATA_STREAM_POSITION_RATE, MAV_DATA_STREAM_POSITION_ACTIVE);
  send_message(&msg);
  delay(10);
//  mavlink_message_t msg5;
  mavlink_msg_request_data_stream_pack(127, 0, &msg, received_sysid, received_compid, MAV_DATA_STREAM_EXTRA1, MAV_DATA_STREAM_EXTRA1_RATE, MAV_DATA_STREAM_EXTRA1_ACTIVE);
  send_message(&msg);
  delay(10);
  mavlink_msg_request_data_stream_pack(127, 0, &msg, received_sysid, received_compid, MAV_DATA_STREAM_EXTRA2, MAV_DATA_STREAM_EXTRA2_RATE, MAV_DATA_STREAM_EXTRA2_ACTIVE);  // Enable message for 3DR OSD
  send_message(&msg);

  delay(460);
  menu = MAIN_MENU;
  redraw = 1;
}

void stop_feeds()
{
  lcd.clear();
  lcd_print_P(PSTR("Stopping feeds!"));
  mavlink_message_t msg1;
  mavlink_msg_request_data_stream_pack(127, 0, &msg1, received_sysid, received_compid, MAV_DATA_STREAM_ALL, 0, 0);
  send_message(&msg1);
  delay(500);
  menu = MAIN_MENU;
  redraw = 1;
}

