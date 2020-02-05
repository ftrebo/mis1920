int cols, rows;
int scl = 80;
int w = 2600;
int h = 1600;


float spsize = 1;
int level = 0;
float theta;

int meshFreedom = 20;

float flying = 0;

float[][] terrain;

void setup() {
  frameRate(15);
  size(1000, 600, P3D);
  cols = w / scl;
  rows = h/ scl;
  terrain = new float[cols][rows];
}


void draw() {
  flying -= 0.1;

  float yoff = flying;
  for (int y = 0; y < rows; y++) {
    float xoff = 0;
    for (int x = 0; x < cols; x++) {
      terrain[x][y] = map(noise(xoff, yoff), 0, 1, -meshFreedom, meshFreedom);
      xoff += 0.2;
    }
    yoff += 0.2;
  }



  background(0);
  stroke(255);
  noFill();

  strokeWeight(1);  

  pushMatrix();
  translate(width/2, height/2);
  //rotateX(PI/3);
  translate(-w/2, -h/2,-400);
  for (int y = 0; y < rows-1; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x = 0; x < cols; x++) {
      if (level == 0) fill(map(terrain[x][y],-80,80,0,80));
      else if (level < 15) fill(0,10,map(terrain[x][y],-80,80,0,255));
      else {
        float max = map(terrain[x][y],-80,80,0,255);
        fill(random(0,max),random(0,max),random(0,max));
      }
      vertex(x*scl, y*scl, terrain[x][y]);
      vertex(x*scl, (y+1)*scl, terrain[x][y+1]);
      //rect(x*scl, y*scl, scl, scl);
    }
    endShape();
  }
  popMatrix();
  
  
  if (level >= 10) {
    pushMatrix();
    fill(255,0,0);
    translate(width/2, height/2, -400);
    spsize += map(random(1,10),1,10,-2,+2);
    sphere((level-5) * 30 + spsize);
    popMatrix();
  }
  
  if (level >= 5) {
    strokeWeight(4); 
    pushMatrix();
    translate(width/4,height);
    line(0,0,0,-200);
    translate(0,-200);
    branch(200);
    popMatrix();
    pushMatrix();
    translate(3*width/4,height);
    line(0,0,0,-200);
    translate(0,-200);
    branch(200);
    popMatrix();
  }
  
  fill(255);
  textSize(26);
  text(level,20,30);
}

void levelUp() {
  if (level < 15) level += 1;
  if (level < 10) theta = radians((level-5)*4);
  if (meshFreedom <= 80) meshFreedom += 20;
}

void mouseClicked() {
  levelUp();
}

void branch(float h) {
  // Each branch will be 2/3rds the size of the previous one
  h *= 0.66;
  if (h > 2) {
    pushMatrix();
    rotate(theta);
    line(0, 0, 0, -h);
    translate(0, -h);
    branch(h);
    popMatrix();
    
    pushMatrix();
    rotate(-theta);
    line(0, 0, 0, -h);
    translate(0, -h);
    branch(h);
    popMatrix();
  }
}
