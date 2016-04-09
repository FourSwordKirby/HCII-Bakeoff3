import android.view.*;
import java.util.ArrayList;
import java.util.Collections;

int index = 0;

//your input code should modify these!!
float screenTransX = 0;
float screenTransY = 0;
float screenRotation = 0;
float screenZ = 200f;

int trialCount = 20; //this will be set higher for the bakeoff
float border = 0; //have some padding from the sides
int trialIndex = 0;
int errorCount = 0;  
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;

final int screenPPI = 445; //what is the DPI of the screen you are using
//Many phones listed here: https://en.wikipedia.org/wiki/Comparison_of_high-definition_smartphone_displays 

//Transformation params
float padding = 10f;
float dotRadius = 2f;
PVector oldDirection = new PVector();
boolean inRotationAction = false;
boolean inMoveAction = false;
boolean mouseOnDots = false;
boolean mouseOnMoveArea = false;
float additionalRotation = 0f;
float newScale = 1f;
float oldMouseX = 0f;
float oldMouseY = 0f;
PVector additionalMove = new PVector();
boolean mouseDown = false;

private class Target
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Target> targets = new ArrayList<Target>();

float inchesToPixels(float inch)
{
  return inch*screenPPI;
}

void setup() {
  //size does not let you use variables, so you have to manually compute this
  size(890, 1557); //set this, based on your sceen's PPI to be a 2x3.5" area.

  rectMode(CENTER);
  textFont(createFont("Arial", inchesToPixels(.15f))); //sets the font to Arial that is .3" tall
  textAlign(CENTER);

  //don't change this! 
  border = inchesToPixels(.2f); //padding of 0.2 inches

  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Target t = new Target();
    t.x = random(-width/2+border, width/2-border); //set a random x with some padding
    t.y = random(-height/2+border, height/2-border); //set a random y with some padding
    t.rotation = random(0, 360); //random rotation between 0 and 360
    t.z = ((i%20)+1)*inchesToPixels(.15f); //increasing size from .15 up to 3.0"
    targets.add(t);
    println("created target with " + t.x + "," + t.y + "," + t.rotation + "," + t.z);
  }

  Collections.shuffle(targets); // randomize the order of the button; don't change this.
}

void draw() {

  background(60); //background is dark grey
  fill(200);
  noStroke();

  if (startTime == 0)
    startTime = millis();

  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchesToPixels(.2f));
    text("User had " + errorCount + " error(s)", width/2, inchesToPixels(.2f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per target", width/2, inchesToPixels(.2f)*3);

    return;
  }

  //===========DRAW TARGET SQUARE=================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen

  Target t = targets.get(trialIndex);

  float scaledZ = t.z * newScale; //scaled square width

  translate(t.x, t.y); //center the drawing coordinates to the center of the screen
  translate(screenTransX, screenTransY); //center the drawing coordinates to the center of the screen
  translate(additionalMove.x, additionalMove.y);

  rotate(radians(t.rotation + additionalRotation));

  // apply the translations to the square for checking
  float oldZ = t.z;
  t.z = scaledZ;
  t.rotation += additionalRotation;
  t.x += additionalMove.x;
  t.y += additionalMove.y;
  
  colorSquare(Square.TARGET);
  rect(0, 0, scaledZ, scaledZ);
  
  // undo the translations
  t.z = oldZ;
  t.rotation -= additionalRotation;
  t.x -= additionalMove.x;
  t.y -= additionalMove.y;
  
  //==========DRAW TRANSFORMATION BOUNDARY==========
  DrawTransformationBoundary(t);//draw scaled square instead
  // draw center cross
  DrawCenterCross(15);

  popMatrix();

  //===========DRAW TARGETTING SQUARE=================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  rotate(radians(screenRotation));

  //custom shifts:
  //translate(screenTransX,screenTransY); //center the drawing coordinates to the center of the screen

  // apply the translations to the square for checking
  t.z = scaledZ;
  t.rotation += additionalRotation;
  t.x += additionalMove.x;
  t.y += additionalMove.y;
  
  colorSquare(Square.TARGETTING);
  rect(0, 0, screenZ, screenZ);
  
  // undo the translations
  t.z = oldZ;
  t.rotation -= additionalRotation;
  t.x -= additionalMove.x;
  t.y -= additionalMove.y;
  
  // draw center cross
  DrawCenterCross(15);

  popMatrix();
  
  // draw scale down button
  if(!userDone){
    fill(255);
    if(!inRotationAction && !inMoveAction && targets.get(trialIndex).z > 2*screenZ) {
      textAlign(RIGHT, BOTTOM);
      text("Scale down", width, height);
      fill(255,100);
      rect(width-inchesToPixels(.4f), height-inchesToPixels(.1f), inchesToPixels(.8f), inchesToPixels(.2f));
      if(!mouseDown && mousePressed && mouseX > width-inchesToPixels(.8f) && mouseY > height-inchesToPixels(.2f)) {
        ScaleTarget(targets.get(trialIndex), 0.5f);
        mouseDown = true;
      }
      textAlign(CENTER, CENTER);
    }
  }

  //scaffoldControlLogic(); //you are going to want to replace this!

  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchesToPixels(.5f));
}

void DrawTransformationBoundary(Target t)
{
  float scaledZ = t.z * newScale;
  float dotDist = scaledZ/2f+inchesToPixels(.2f);
  float dotSize = inchesToPixels(.15f);
  // 4 dots
  PVector d1 = transform(-dotDist, -dotDist, t.x+screenTransX+width/2+additionalMove.x, t.y+screenTransY+height/2+additionalMove.y, t.rotation);
  PVector d2 = transform(dotDist, -dotDist, t.x+screenTransX+width/2+additionalMove.x, t.y+screenTransY+height/2+additionalMove.y, t.rotation);
  PVector d3 = transform(-dotDist, dotDist, t.x+screenTransX+width/2+additionalMove.x, t.y+screenTransY+height/2+additionalMove.y, t.rotation);
  PVector d4 = transform(dotDist, dotDist, t.x+screenTransX+width/2+additionalMove.x, t.y+screenTransY+height/2+additionalMove.y, t.rotation);
  PVector center = new PVector(t.x+screenTransX+width/2+additionalMove.x, t.y+screenTransY+height/2+additionalMove.y);
  
  boolean mouseOnScaleDownButton = (
  mouseX > width-inchesToPixels(.8f) &&
  mouseY > height-inchesToPixels(.2f) &&
  t.z > 2*screenZ);
  mouseOnDots = (// mouse in rotating area
  dist(mouseX, mouseY, d1.x, d1.y) < dotSize ||
  dist(mouseX, mouseY, d2.x, d2.y) < dotSize ||
  dist(mouseX, mouseY, d3.x, d3.y) < dotSize ||
  dist(mouseX, mouseY, d4.x, d4.y) < dotSize) && !mouseOnScaleDownButton;
  mouseOnMoveArea = !mouseOnScaleDownButton;
  
  // dots color -- yellow when interacting, blue otherwise
  if(mouseOnDots && mousePressed)
    fill(255,255,0);
  else
    fill(100,100,255,128);
  if(mouseOnDots) {
    if(mousePressed){
      if(!inRotationAction) {
        inRotationAction = true;
        oldDirection.x = mouseX - center.x;
        oldDirection.y = mouseY - center.y;
      }
    }
  }
  else if(mouseOnMoveArea){
    if(mousePressed) {
      if(!inMoveAction) {
        inMoveAction = true;
        oldMouseX = mouseX;
        oldMouseY = mouseY;
      }
    }
  }
  
  if(inRotationAction) {
    PVector mpos = new PVector(mouseX - center.x, mouseY - center.y);
    additionalRotation = degrees(mpos.heading() - oldDirection.heading());
    newScale = Math.max((mpos.mag() - oldDirection.mag()) / (t.z / (float)Math.pow(2, .5)) + 1f, 0f);
  }
  else if(inMoveAction){ // move
    additionalMove.x = mouseX - oldMouseX;
    additionalMove.y = mouseY - oldMouseY;
  }
  
  /*stroke(128);
  line(-dotDist, -dotDist, dotDist, -dotDist);
  line(dotDist, -dotDist, dotDist, dotDist);
  line(dotDist, dotDist, -dotDist, dotDist);
  line(-dotDist, dotDist, -dotDist, -dotDist);
  noStroke();*/
  
  ellipse(-dotDist, -dotDist, dotSize, dotSize);
  ellipse(dotDist, -dotDist, dotSize, dotSize);
  ellipse(-dotDist, dotDist, dotSize, dotSize);
  ellipse(dotDist, dotDist, dotSize, dotSize);
}

void ScaleTarget(Target target, float scale) {
  if(scale != 1 && scale > 0) {
    target.z *= scale;
  }
}

//Calculate the transformed vector
PVector transform(float ox, float oy, float x, float y, float d)
{
  PVector v = new PVector();
  float r = radians(d);
  v.x = x + ox * cos(r) - oy * sin(r);
  v.y = y + ox * sin(r) + oy * cos(r);
  return v;
}

void DrawCenterCross(float size)
{
  stroke(255);
  line(-size, 0, size, 0);
  line(0, -size, 0, size);
  noStroke();
}

enum Square{TARGET, TARGETTING};

void colorSquare(Square square)
{
  if(square == Square.TARGET)
  {
    fill(255, 0, 0); //set color to semi translucent
    if(checkForSuccess())
    {
      fill(0, 255, 0);
    }
  }
  if(square == Square.TARGETTING)
  {
    fill(255, 128); //set color to semi translucent
    if(checkForSuccess())
    {
      fill(0, 255, 0);
    }
  }
}

/*void scaffoldControlLogic()
{
  //upper left corner, rotate counterclockwise
  text("CCW", inchesToPixels(.2f), inchesToPixels(.2f));
  if (mousePressed && dist(0, 0, mouseX, mouseY)<inchesToPixels(.5f))
    screenRotation--;

  //upper right corner, rotate clockwise
  text("CW", width-inchesToPixels(.2f), inchesToPixels(.2f));
  if (mousePressed && dist(width, 0, mouseX, mouseY)<inchesToPixels(.5f))
    screenRotation++;

  //lower left corner, decrease Z
  text("-", inchesToPixels(.2f), height-inchesToPixels(.2f));
  if (mousePressed && dist(0, height, mouseX, mouseY)<inchesToPixels(.5f))
    screenZ-=inchesToPixels(.02f);

  //lower right corner, increase Z
  text("+", width-inchesToPixels(.2f), height-inchesToPixels(.2f));
  if (mousePressed && dist(width, height, mouseX, mouseY)<inchesToPixels(.5f))
    screenZ+=inchesToPixels(.02f);

  //left middle, move left
  text("left", inchesToPixels(.2f), height/2);
  if (mousePressed && dist(0, height/2, mouseX, mouseY)<inchesToPixels(.5f))
    screenTransX-=inchesToPixels(.02f);
  ;

  text("right", width-inchesToPixels(.2f), height/2);
  if (mousePressed && dist(width, height/2, mouseX, mouseY)<inchesToPixels(.5f))
    screenTransX+=inchesToPixels(.02f);
  ;

  text("up", width/2, inchesToPixels(.2f));
  if (mousePressed && dist(width/2, 0, mouseX, mouseY)<inchesToPixels(.5f))
    screenTransY-=inchesToPixels(.02f);
  ;

  text("down", width/2, height-inchesToPixels(.2f));
  if (mousePressed && dist(width/2, height, mouseX, mouseY)<inchesToPixels(.5f))
    screenTransY+=inchesToPixels(.02f);
  ;
}*/

void keyPressed() { 
  if (key == CODED && keyCode == UP) {  
    System.out.print("bang");
  } 
  
  //Comment out this part when not using the android)
  if ( (key == CODED) && (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) && checkForSuccess()) {
    nextTrial();
    keyCode = 1;
  }
}

public void nextTrial()
{
  if (userDone==false && !checkForSuccess())
      errorCount++;

    //and move on to next trial
    trialIndex++;

    screenTransX = 0;
    screenTransY = 0;

    if (trialIndex==trialCount && userDone==false)
    {
      userDone = true;
      finishTime = millis();
    }
}

void mouseReleased()
{
  //check to see if user clicked middle of screen
  /*if (!inRotationAction && dist(width/2, height/2, mouseX, mouseY)<inchesToPixels(.5f))
  {
    if (userDone==false && !checkForSuccess())
      errorCount++;

    //and move on to next trial
    trialIndex++;

    screenTransX = 0;
    screenTransY = 0;

    if (trialIndex==trialCount && userDone==false)
    {
      userDone = true;
      finishTime = millis();
    }
  }*/
  
  // for transformation
  mouseDown = false;
  if(inRotationAction) {
    inRotationAction = false;
    oldDirection.x = 0;
    oldDirection.y = 0;
    targets.get(trialIndex).rotation += additionalRotation;
    targets.get(trialIndex).z *= newScale;
    additionalRotation = 0;
    newScale = 1;
  }
  if(inMoveAction) {
    inMoveAction = false;
    oldMouseX = 0f;
    oldMouseY = 0f;
    targets.get(trialIndex).x += additionalMove.x;
    targets.get(trialIndex).y += additionalMove.y;
    additionalMove.x = 0f;
    additionalMove.y = 0f;
  }
}

public boolean checkForSuccess()
{
	Target t = targets.get(trialIndex);	
	boolean closeDist = dist(t.x,t.y,-screenTransX,-screenTransY)<inchesToPixels(.05f); //has to be within .1"
    boolean closeRotation = calculateDifferenceBetweenAngles(t.rotation,screenRotation)<=5;
	boolean closeZ = abs(t.z - screenZ)<inchesToPixels(.05f); //has to be within .1"	
	println("Close Enough Distance: " + closeDist);
    println("Close Enough Rotation: " + closeRotation + "(dist="+calculateDifferenceBetweenAngles(t.rotation,screenRotation)+")");
	println("Close Enough Z: " + closeZ);
	
	return closeDist && closeRotation && closeZ;	
}

double calculateDifferenceBetweenAngles(float a1, float a2)
  {
     double diff=abs(a1-a2);
      diff%=90;
      if (diff>45)
        return 90-diff;
      else
        return diff;
 }