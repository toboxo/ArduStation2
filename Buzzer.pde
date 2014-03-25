void buzz(int time, int freq)
{
  #ifdef BUZZERON
  cli();
  for(int c=0; c<time; c++)
  {
    digitalWrite(8,HIGH); 
    delayMicroseconds(freq);
    digitalWrite(8,LOW); 
    delayMicroseconds(freq);
  }
  sei();
  #endif
}
