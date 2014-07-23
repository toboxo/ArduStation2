/*************************************************************************
 * //Function to calculate the course between two waypoints
 * //I'm using the real formulas--no lookup table fakes!
 *************************************************************************/

float calc_bearing(float flat1, float flon1, float flat2, float flon2)
{
  float calc;
  float bear_calc;

  float x = 69.1 * (flat2 - flat1); 
  float y = 69.1 * (flon2 - flon1) * cos(flat1/57.3);
 
  calc=atan2(y,x);

  bear_calc= degrees(calc);

  if(bear_calc<=1){
    bear_calc=360+bear_calc; 
  }
  return bear_calc;
}
/*************************************************************************
 * //Function to calculate the distance between two waypoints
 * //I'm using  a really good approach
 *************************************************************************/
float calc_dist(float flat1, float flon1, float flat2, float flon2)
{
 float x = 69.1 * (flat2 - flat1); 
 float y = 69.1 * (flon2 - flon1) * cos(flat1/57.3);
 
 return (float)sqrt((float)(x*x) + (float)(y*y))*1609.344; 
}

float to_float_6(long value) 
{
  return (float)value/(float)1000000;
}

// Distance/bearing algorithm provided by James Masterman

float calc_bearing_alt(float flat1, float flon1, float flat2, float flon2)
{
float dLat = radians(flat2-flat1);
float dLon = radians(flon2-flon1);
float lat1 = radians(flat1);
float lat2 = radians(flat2);
float y = sin(dLon) * cos(lat2);
float x = cos(lat1)*sin(lat2) - sin(lat1)*cos(lat2)*cos(dLon);
float brng = degrees(atan2(y, x));
if(brng < 0.0f){
brng = 360.0f+brng;
}
return brng;
}
float calc_dist_alt(float flat1, float flon1, float flat2, float flon2)
{
float EarthsRadius = 6371.0f; // km
float dLat = radians(flat2-flat1);
float dLon = radians(flon2-flon1);
float lat1 = radians(flat1);
float lat2 = radians(flat2);
float a = sin(dLat/2.0f) * sin(dLat/2.0f) + sin(dLon/2.0f) * sin(dLon/2.0f) * cos(lat1) * cos(lat2);
float c = 2.0f * atan2(sqrt(a), sqrt(1.0f-a));
float d = EarthsRadius * c;
return d*1000.0;
}

