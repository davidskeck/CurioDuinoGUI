/* 
 * David Keck
 * CurioDuinoGUI.pde
 * Graphical interface for operations of 
 * the CurioDuino Autonomous robot project.
 * More information can be found here:
 * davidskeck.wordpress.com
 * or here http://github.com/davidskeck/CurioDuinoGUI
 */
 
import processing.serial.*;

// 1 for windows, 0 for mac bluetooth, 3 mac usb
final int PORT_NUMBER = 0;

// Number of samples in average
final int SAMPLE_SIZE = 150;

// Create object from Serial class
Serial port;

// Check for start button
boolean isStarted = false;

// Check for when to draw
boolean draw = false;

// Data from battery calculation
int batteryReading;

// Time measurements
long timeAtLink, timeSinceLink;

// Speed changer
final int SPEED_ONE = 75;
final int SPEED_TWO = 125;
final int SPEED_THREE = 175;
boolean buttonOne = true;
boolean buttonTwo = false;
boolean buttonThree = false;

// Edge sensors
boolean leftEdgeDetected = false;
boolean rightEdgeDetected = false;

// Obstacle sensors
boolean leftObstacleDetected = false;
boolean middleObstacleDetected = false;
boolean rightObstacleDetected = false;

// Motor variables
boolean leftForward = false;
boolean rightForward = false;

// Key input
boolean spacebar = false;
boolean keyOne = false;
boolean keyTwo = false;
boolean keyThree = false;

// Store battery averages
float[] batteryData = new float[SAMPLE_SIZE];
float batteryTotal = 0;
int batteryI = 0, batteryCnt = 0;

// Store time averages
long[] timeData = new long[SAMPLE_SIZE];
long timeTotal = 0;
int timeI = 0, timeCnt = 0;

// Make a font object
PFont font;

// Make an image object
PImage CurioDuinoImage;

float getCircularBatteryAverage(float inVal)
{
  // Subtract oldest value from total
  batteryTotal -= batteryData[batteryI];
  
  // Replace old value with latest reading
  batteryData[batteryI] = inVal;
  
  // Increase total by latest reading
  batteryTotal += inVal;
  
  // Set index to compensate for number of values
  batteryI = ++batteryI % batteryData.length;
  
  // Increase counter if necessary
  if(batteryCnt < batteryData.length)
  {
    batteryCnt++;
  }
  
  return batteryTotal/batteryCnt;
}

long getCircularTimeAverage(long inVal)
{
  // Subtract oldest value from total
  timeTotal -= timeData[timeI];
  
  // Replace old value with latest reading
  timeData[timeI] = inVal;
  
  // Increase total by latest reading
  timeTotal += inVal;
  
  // Set index to compensate for number of values
  timeI = ++timeI % timeData.length;
  
  // Increase counter if necessary
  if(timeCnt < timeData.length)
  {
    timeCnt++;
  }
  
  return timeTotal/timeCnt;
}

void drawBattery()
{
  // Calculate battery percentage
  float percentage = batteryReading/720.0;
  
  percentage = getCircularBatteryAverage(percentage);
  
  if (percentage > 1.0)
  {
    percentage = 1;
  }
  
  else if (percentage < 0.0)
  {
    return;
  }
    
  // This rectangle is under the string
  fill(200);
  stroke(1);
  rect(289, 161, 95, 28);
  
  // This rectangle is under the percentage bar
  rect(150, 112, 563, 24);
  
  // Fill bar color depends on percent
  // Gradient from green to red
  float redFader = map(percentage, 1.0, .5, 0, 255);
  float greenFader = map(percentage, .5, 0, 255, 0);
  fill(redFader, greenFader, 0);
  
  // Draw the bar
  rect(153, 115, (557*percentage), 18);
  
  // Draw the string
  fill(0);
  text(nf(percentage*100, 3, 2), 293, 182);
}

void drawCommStatus()
{
  // This circle is under the indicator LED
  noStroke();
  fill(200);
  ellipse(990, 124, 26, 26);
  
  // This rectangle is under the string
  stroke(1);
  fill(200);
  rect(304, 211, 80, 28);
  
  // Calculate time since last data link
  timeSinceLink = millis();
  timeSinceLink = getCircularTimeAverage(timeSinceLink -= timeAtLink);
  
  // From zero to one second, change color
  float greenFader = map(timeSinceLink, 500, 1000, 255, 0);
  float redFader = map(timeSinceLink, 0, 500, 0, 255);
  
  // Draw the LED
  fill(redFader, greenFader, 0);
  ellipse(990, 124, 20, 20);
  
  // Draw the string
  fill(redFader, 0, 0);
  if(timeSinceLink < 9000)
  {
    text(nf(timeSinceLink/1000.0, 1, 3), 308, 233);
  }
  else
  {
    text("LOST", 314, 233);
  }
}

void drawObstacleStatus()
{
  // These are the rectangles under the strings
  stroke(1);
  fill(200);
  rect(334, 261, 50, 28);
  rect(334, 311, 50, 28);
  rect(334, 361, 50, 28);
  
  // Set fill
  fill(0);
  
  // Draw the strings
  if(leftObstacleDetected)
  {
    fill(180, 0, 0);
    text("YES", 338, 282);
    
    fill(255, 0, 0, 190);
    // Indication on CurioDuino
    beginShape();
    vertex(856, 500);
    vertex(888, 500);
    vertex(868, 600);
    vertex(836, 600);
    endShape(CLOSE);
  }
  else
  {
    fill(0);
    text("NO", 345, 282);
    
    fill(0, 255, 0, 125);
    // Indication on CurioDuino
    beginShape();
    vertex(856, 500);
    vertex(888, 500);
    vertex(868, 600);
    vertex(836, 600);
    endShape(CLOSE);
  }
    
  if(middleObstacleDetected)
  {
    fill(180, 0, 0);
    text("YES", 338, 332);
    
    fill(255, 0, 0, 190);
    // Indication on CurioDuino
    beginShape();
    vertex(688, 500);
    vertex(723, 500);
    vertex(723, 600);
    vertex(688, 600);
    endShape(CLOSE);
  }
  else
  {
    fill(0);
    text("NO", 345, 332);
    
    fill(0, 255, 0, 125);
    // Indication on CurioDuino
    beginShape();
    vertex(688, 500);
    vertex(723, 500);
    vertex(723, 600);
    vertex(688, 600);
    endShape(CLOSE);
  }
  
  if(rightObstacleDetected)
  {
    fill(180, 0, 0);
    text("YES", 338, 382);
    
    fill(255, 0, 0, 190);
    // Indication on CurioDuino
    beginShape();
    vertex(534, 500);
    vertex(574, 500);
    vertex(588, 600);
    vertex(554, 600);
    endShape(CLOSE);
  }
  else
  {
    fill(0);
    text("NO", 345, 382);
    
    fill(0, 255, 0, 125);
    // Indication on CurioDuino
    beginShape();
    vertex(534, 500);
    vertex(574, 500);
    vertex(588, 600);
    vertex(554, 600);
    endShape(CLOSE);
  }
}

void drawEdgeStatus()
{
  // These are the rectangles under the strings
  stroke(1);
  fill(200);
  rect(334, 411, 50, 28);
  rect(334, 461, 50, 28);
  
  // This is the rectangle under CurioDuino
  noStroke();
  fill(189);
  rect(440, 280, 542, 470);
  
  // Reset stroke width
  stroke(1);
  
  // Draw the strings
  if(leftEdgeDetected)
  {
    fill(180, 0, 0);
    text("YES", 338, 432);
    
    fill(255, 0, 0, 195);
    // Indication under CurioDuino
    beginShape();
    vertex(822, 608);
    vertex(711, 608);
    vertex(711, 725);
    vertex(947, 725);
    endShape(CLOSE);
  }
  else
  {
    fill(0);
    text("NO", 345, 432);
    
    fill(0, 255, 0, 145);
    // Indication under CurioDuino
    beginShape();
    vertex(822, 608);
    vertex(711, 608);
    vertex(711, 725);
    vertex(947, 725);
    endShape(CLOSE);
  }
  
  if(rightEdgeDetected)
  {
    fill(180, 0, 0);
    text("YES", 338, 482);
    
    fill(255, 0, 0, 195);
    // Indication under CurioDuino
    beginShape();
    vertex(711, 608);
    vertex(600, 608);
    vertex(475, 725);
    vertex(711, 725);
    endShape(CLOSE);
  }
  else
  {
    fill(0);
    text("NO", 345, 482);
    
    fill(0, 255, 0, 145);
    // Indication under CurioDuino
    beginShape();
    vertex(711, 608);
    vertex(600, 608);
    vertex(475, 725);
    vertex(711, 725);
    endShape(CLOSE);
  }
}

void drawCurioDuinoImage()
{
  image(CurioDuinoImage, 460, 300);
}

void drawMovementStatus()
{
  // This is the rectangle under the string
  stroke(1);
  fill(200);
  rect(276, 511, 108, 28);
  
  // Set fill for text
  fill(0);
  
  // Set fill and weight for line
  stroke(255, 255, 0);
  strokeWeight(5);
  
  if (leftForward && rightForward && isStarted)
  {
    text("FORWARD", 280, 532);
    drawArrow(553, 370, 100, 106);
    drawArrow(873, 370, 100, 73);
  }
  else if (leftForward && !rightForward)
  {
    text("R-TURN", 287, 532);
    drawArrow(523, 470, 100, 288);
    drawArrow(873, 370, 100, 73);
  }
  else if (!leftForward && rightForward)
  {
    text("L-TURN", 287, 532);
    drawArrow(553, 370, 100, 106);
    drawArrow(903, 470, 100, 253);
  }
  else if (!leftForward && !rightForward && isStarted)
  {
    text("REVERSE", 280, 532);
    strokeWeight(5);
    drawArrow(523, 470, 100, 288);
    drawArrow(903, 470, 100, 253);
  }
  else
  {
    text("STOPPED", 280, 532);
  }
  strokeWeight(1);
  stroke(0);
}

void setup()
{ 
  size(1024,768);
  
  // Pick a font
  font = loadFont("Monospaced.plain-48.vlw");
  textFont(font);
  
  // Pick an image
  CurioDuinoImage = loadImage("CurioDuinoPicture.png");
  
  // Background color
  background(240);
  
  // Main rectangle
  fill(189);
  rect(6, 100, 1010, 661, 9);

  // Button rectangle
  fill(0, 255, 0);
  rect(20, 550, 364, 200);
  
  // Speed selector buttons
  rect(530, 205, 40, 40);
  fill(200);
  rect(640, 205, 80, 40);
  rect(790, 205, 120, 40);
  
  // Print out labels
  fill(0);
  textSize(54);
  text("Start", 120, 660);
  text(">", 536, 241);
  text(">>", 650, 241);
  text(">>>", 805, 241);
  textSize(48);
  text("CurioDuino Mission Control", 145, 60);
  textSize(24);
  text("Battery%: ", 20, 131);
  text("Comm. link status ", 728, 131);
  text("Avg battery %: ", 20, 181);
  text("Time(s) since link: ", 20, 231);
  text("L obstacle detected: ", 20, 281);
  text("M obstacle detected: ", 20, 331);
  text("R obstacle detected: ", 20, 381);
  text("L edge detected: ", 20, 431);
  text("R edge detected: ", 20, 481);
  text("Movement status: " , 20, 531);
  text("Speed selector: ", 610, 181);
  
  try
  {
    String arduinoPort = Serial.list()[PORT_NUMBER];
    port = new Serial(this, arduinoPort, 9600);
    port.bufferUntil('\n');
  }
  catch (Exception E)
  {
    // Couldn't open port, show message box and close program
    javax.swing.JOptionPane.showMessageDialog(null, "Port could not be opened.",
    "Serial port connection error", 0);
    exit();
  }
}

void draw()
{
  if (draw)
  {
    // Draw dynamic indicators
    drawBattery();
    drawCommStatus();
    drawEdgeStatus();
    drawCurioDuinoImage();
    drawObstacleStatus();
    drawMovementStatus();
  }
}

void serialEvent(Serial port)
{
  // Required to make sure the
  // entire data packet has been
  // sent and recieved
  if (port.available() < 27)
  {
    port.clear();
    return;
  }
  
  // Get the time immediately after data has arrived
  timeAtLink = millis();
  
  // Read serial data in
  String data = (port.readString());
  
  int index = 0, index2 = 0;
  index = data.indexOf("LE");
  
  leftEdgeDetected = boolean(int(data.substring(0,index)));
  
  index2 = data.indexOf("RE");
  rightEdgeDetected = boolean(int(data.substring(index+2, index2)));
  
  index = data.indexOf("B");
  batteryReading = int(data.substring(index2+2, index));
  
  index2 = data.indexOf("LO");
  leftObstacleDetected = boolean(int(data.substring(index+1, index2)));
  
  index = data.indexOf("MO");
  middleObstacleDetected = boolean(int(data.substring(index2+2, index)));
  
  index2 = data.indexOf("RO");
  rightObstacleDetected = boolean(int(data.substring(index+2, index2)));
  
  index = data.indexOf("LF");
  leftForward = boolean(int(data.substring(index2+2, index)));
  
  index2 = data.indexOf("RF");
  rightForward = boolean(int(data.substring(index+2, index2)));
}

void mousePressed() 
{
  // Start/stop button coordinates
  if (((mouseX > 20) && (mouseX < 20 + 364) && (mouseY > 550) && (mouseY < 550 + 200))) 
  {
    // if mouse clicked inside square
    isStarted = !isStarted;
    draw = true;
        
    // Send signal to CurioDuino
    port.write(int(isStarted));
    
    stroke(1);
    
    // Check status to determine button display type
    if(isStarted)
    {
      fill(255, 0, 0);
      rect(20, 550, 364, 200);
      textSize(54);
      fill(0);
      text("Stop", 134, 660);
    }
    else
    {
      fill(0, 255, 0);
      rect(20, 550, 364, 200);
      fill(0);
      textSize(54);
      text("Start", 120, 660);
    }
  }
  
  if ((buttonOne == false) && ((mouseX > 530) && (mouseX < 530 + 40) && (mouseY > 205) && (mouseY < 205 + 40))) 
  {
    buttonOne = true;
    buttonTwo = false;
    buttonThree = false;
    
    port.write(SPEED_ONE);
    
    // Speed selector one
    fill(0, 255, 0);
    rect(530, 205, 40, 40);
    
    fill(200);
    rect(640, 205, 80, 40);
    rect(790, 205, 120, 40);
    
    fill(0);
    textSize(54);
    text(">", 536, 241);
    text(">>", 650, 241);
    text(">>>", 805, 241);
  }
  
  if ((buttonTwo == false) && ((mouseX > 640) && (mouseX < 640 + 80) && (mouseY > 205) && (mouseY < 205 + 40))) 
  {
    buttonOne = false;
    buttonTwo = true;
    buttonThree = false;
    
    port.write(SPEED_TWO);
    
    // Speed selector one
    fill(255, 255, 0);
    rect(640, 205, 80, 40);
    
    fill(200);
    rect(530, 205, 40, 40);
    rect(790, 205, 120, 40);
    
    fill(0);
    textSize(54);
    text(">", 536, 241);
    text(">>", 650, 241);
    text(">>>", 805, 241);
  }
  
  if ((buttonThree == false) && ((mouseX > 790) && (mouseX < 790 + 120) && (mouseY > 205) && (mouseY < 205 + 40))) 
  {
    buttonOne = false;
    buttonTwo = false;
    buttonThree = true;
    
    port.write(SPEED_THREE);
    
    // Speed selector one
    fill(255, 0, 0);
    rect(790, 205, 120, 40);
    
    fill(200);
    rect(530, 205, 40, 40);
    rect(640, 205, 80, 40);

    
    fill(0);
    textSize(54);
    text(">", 536, 241);
    text(">>", 650, 241);
    text(">>>", 805, 241);
  }
  
  textSize(24);
}

void drawArrow(int cx, int cy, int len, float angle)
{
  pushMatrix();
  translate(cx, cy);
  rotate(radians(angle));
  line(0,0,len, 0);
  line(len, 0, len - 12, -12);
  line(len, 0, len - 12, 12);
  popMatrix();
}

void keyPressed() 
{
  // Spacebar
  if (key == 32) 
  {
    spacebar = true;
    startButton();
  }
  
  // 1
  else if (key == 49)
  {
    keyOne = true;
    speedOne();
  }
  
  // 2
  else if (key == 50)
  {
    keyTwo = true;
    speedTwo();
  }
  
  // 3
  else if (key == 51)
  {
    keyThree = true;
    speedThree();
  }
}

void startButton()
{
  // Start/stop button coordinates
  if (spacebar) 
  {
    // if mouse clicked inside square
    isStarted = !isStarted;
    draw = true;
        
    // Send signal to CurioDuino
    port.write(int(isStarted));
    
    stroke(1);
    
    // Check status to determine button display type
    if(isStarted)
    {
      fill(255, 0, 0);
      rect(20, 550, 364, 200);
      textSize(54);
      fill(0);
      text("Stop", 134, 660);
    }
    else
    {
      fill(0, 255, 0);
      rect(20, 550, 364, 200);
      fill(0);
      textSize(54);
      text("Start", 120, 660);
    }
    
    // Handle keyboard shortcut boolean
    spacebar = false;
    
    textSize(24);
  }
}

void speedOne()
{
  if (keyOne) 
    {
      buttonOne = true;
      buttonTwo = false;
      buttonThree = false;
      
      port.write(SPEED_ONE);
      
      // Speed selector one
      fill(0, 255, 0);
      rect(530, 205, 40, 40);
      
      fill(200);
      rect(640, 205, 80, 40);
      rect(790, 205, 120, 40);
      
      fill(0);
      textSize(54);
      text(">", 536, 241);
      text(">>", 650, 241);
      text(">>>", 805, 241);
      
      // Handle keyboard shortcut boolean
      keyOne = false;
      
      textSize(24);
    }
}
  
void speedTwo()
{
  if (keyTwo) 
  {
    buttonOne = false;
    buttonTwo = true;
    buttonThree = false;
    
    port.write(SPEED_TWO);
    
    // Speed selector one
    fill(255, 255, 0);
    rect(640, 205, 80, 40);
    
    fill(200);
    rect(530, 205, 40, 40);
    rect(790, 205, 120, 40);
    
    fill(0);
    textSize(54);
    text(">", 536, 241);
    text(">>", 650, 241);
    text(">>>", 805, 241);
    
    // Handle keyboard shortcut boolean
    keyTwo = false;
    
    textSize(24);
  }
}

void speedThree()
{
  if (keyThree) 
  {
    buttonOne = false;
    buttonTwo = false;
    buttonThree = true;
    
    port.write(SPEED_THREE);
    
    // Speed selector one
    fill(255, 0, 0);
    rect(790, 205, 120, 40);
    
    fill(200);
    rect(530, 205, 40, 40);
    rect(640, 205, 80, 40);

    
    fill(0);
    textSize(54);
    text(">", 536, 241);
    text(">>", 650, 241);
    text(">>>", 805, 241);
    
    // Handle keyboard shortcut boolean
    keyThree = false;
    
    textSize(24);
  }
}

