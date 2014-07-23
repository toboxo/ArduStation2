void buzz(int time, int freq)
{
  #ifdef BUZZERON
  cli();
  for(int c=0; c<time; c++)
  {
    digitalWrite(2,HIGH); 
    delayMicroseconds(freq);
    digitalWrite(2,LOW); 
    delayMicroseconds(freq);
  }
  sei();
  #endif
}

