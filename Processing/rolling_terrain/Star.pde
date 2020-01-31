/*
 *  Class representing a star object
 *
 *
*/

final int max_z = 600;  
final int max_x = 10000;
final int max_y = 10000;
final float maxspeed = 30;

class Star{
  float x,y,z;
   
  float init_speed = 30;
  float star_length = 10;
    
  float center_x = w/2;
  float center_y = h;//-h/5;
  float modx;
  
   
  float pz;
   
   void init(){
     x = random(-max_x/2,max_x/2);
     y = random(-max_y/2,max_y/2);
     init_speed = random(maxspeed/2,maxspeed);
     pz = z = 0; 
     star_length = 10;
     modx = 0;
   }
   
   Star(){
     this.init();
   }
 
   /*
    * Update star position
   */
   void update(float speed_multiplier){
     // Add a multiplier to the base speed
     float speed = init_speed * speed_multiplier;
     z += speed;
     // Shift stars to left or right to enhance moving effect
     x += int((x>0)?(speed/5):(-speed/5));
     
     star_length += speed/5;
     modx += (x>0)?(speed/15):(-speed/15);
     
     if(z>max_z || x > max_x || x < -max_x){
       this.init();
     }
   }
 
   /**
    * Draw Star and trail (line)
   */
   void show(){
     fill(255);
     noStroke();
     
     /*- Draw Star -----------------------------------------------------------------------------------*/
     pushMatrix(); 
     translate(x+center_x, y+ center_y, z);
     float size = map(z,0,max_z,0,10);
     sphere(size);
     popMatrix();
     stroke(255);
     
     /*- Draw Trail ----------------------------------------------------------------------------------*/
     line(x+center_x, y+ center_y, z, x+center_x-modx, y+ center_y, z>star_length?z-star_length:z);
     
   }
}
