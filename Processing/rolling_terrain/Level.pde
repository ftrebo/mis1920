/**
 * LEVEL LOGIC
 *
 * Class that deals with the level increase/decrease and
 * the related improvements in the quality of the generated
 * graphics.
 *
 * Author: Domenico Stefani, Franv
 * Date: 03/02/2020
 *
 */

final static int MAX_LEVEL = 50;    // Maximum level reachable
final static int LEVEL_INCREASE = 1; //  Increase step (upon hit)
final static int LEVEL_DECREASE = 1; //  Decrease step (upon miss)

static class Level{
  static int level = 0;
  static float _colorIntensity = 0;
  static boolean _drawStars = false;
  static boolean _drawSun = false;

  Level(){}

  static void hit(){
    if(level < MAX_LEVEL){
      level += LEVEL_INCREASE;
      
      _colorIntensity = map(level, 0, MAX_LEVEL, 0, 1);
      if (level >= 20) _drawStars = true;
      if (level >= 30) _drawSun = true;
    }
  }

  static void miss(){
    if(level > 0){
      level -= LEVEL_INCREASE;

      _colorIntensity = map(level, 0, MAX_LEVEL, 0, 1);
      if (level < 20) _drawStars = false;
      if (level < 30) _drawSun = false;
    }
  }
  
  static void miss(int howMany){
    for (int i=0; i<howMany; i++) 
      miss();
  }
  
  static float colorIntensity(){
    return _colorIntensity;
  }
  
  static boolean drawStars() {
    return _drawStars;
  }
  
  static boolean drawSun() {
    return _drawSun;
  }
}
