// Maze Generator
// by Oscar Frias (@_frix_) 2016
// www.oscarfrias.com
//
// Let's write a depth-first, recursive bactracker algorithm to create a maze
// based on https://en.wikipedia.org/wiki/Maze_generation_algorithm
// and especially on https://www.youtube.com/watch?v=HyK_Q5rrcr4
// Thanks Dan!
//
// This program will carve a maze, save it as both PDF and JSON.
// The JSON file will be used by a maze solving algorithm,
// the PDF will be opened in Acrobat Reader and sent it to your printer
// so you can solve it by hand right away.

// Libraries needed
import processing.pdf.*;
import java.io.FilenameFilter;

int wdInch = 17;
int htInch = 11;
int pxtoIn = 96;

// Some variables
int wd = wdInch*pxtoIn;                    // width of the maze in pixels
int ht = htInch*pxtoIn;                    // height of the maze in pixels
int w = 10;                       // size of the cell in px
int border;                       // spacing around the square that will be drawn for the start and finish cells so that the edges are not hidden
int cols,rows;                    // to define the size of the maze
int startX, startY, endX, endY;   // coordinates for the start and finish cells
int lastIndex;                    // to verify if the stack still contains something

// Arraylists to store the maze and the stack
ArrayList grid;
ArrayList stack;

// Cell objects
Cell current,top,right,bottom,left;

// Colors for the cells
color cellColor = color(0,114,204,100);         // color for the visited cells - cool blue
color endColor = color(255,255,255);            // color for when the maze is shown to be saved in the PDF - white
color startColor = color(0,255,0);              // color for the start cell - Green
color finishColor = color(255,0,0);             // color for the finish cell - Red
color stackColor = color(0,78,119,100);         // color for the cells in the stack - greenish blue
color highlightColor = color(255,255,255,100);  // color for highlighting the current cell - White with alpha

// Maze save path
String thePath = "/Mazes";  //Relative location for mazes under your sketch folder. change this to the location where you want the mazes saved.
// Acrobat reader path
String rdrLocation = "C:/Program Files (x86)/Adobe/Acrobat Reader DC/Reader/AcroRD32.exe";  //change this to the location where your acrobat reader is located
// Container for the maze PDF:
PGraphicsPDF pdfMaze;


// Settings is needed to be able to specify the size of the window with variables.
void settings(){
    size(wd,ht);  // Spec the size of the maze in px
}

void setup(){
  //initialize the maze
  smooth();
  background(0);    // black bg
  border = w/10;    // set the border around the highlighted cell (to be able to show the walls)

  //define the grid
  cols= floor(width/w);
  rows= floor(height/w);
  println("Painting a " + cols + " x " + rows + " Grid");

  // initialize the grid and stack ArrayLists
  grid = new ArrayList();
  stack = new ArrayList();

  // for each row, go through every column and add a cell to the grid
  for(int j=0; j<rows; j++){
    for(int i=0; i<cols; i++){
      Cell cell = new Cell(i,j);
      grid.add(cell);
    }
  }

  // Lets assign the start and finish cells
  int startPos = defineStart();   // Returns the first cell in the Grid
  int finishPos = defineFinish(); // Currently returns the last cell in the Grid, could be anything else

  // Make sure the finish is far from the start
  // while(abs(finishPos-startPos) < grid.size()*.95) {
  //   finishPos = defineFinish();
  // }

  println("Start cell: " + startPos + " | Finish Cell: " + finishPos);
  Cell theStart = (Cell) grid.get(startPos);
  Cell theFinish = (Cell) grid.get(finishPos);

  // Change the booleans of the start and finish cells
  theStart.isStart = true;
  theFinish.isFinish = true;

  // Go to the first cell in the grid to start
  current = theStart;
}



void draw(){
  // Draw the grid
  for (int i =0; i<grid.size();i++){
    Cell each = (Cell) grid.get(i);
    each.show(false);
  }
  // Step 1 per wikipedia:
  // Mark the current cell as visited, and highlight it with the visited color
  current.visited = true;
  current.highlight(highlightColor);
  // Now check if any of the neighbors is valid and assign it to "next"
  Cell next = current.checkNeighbors();

  // If there is a neighbor, mark that one as visited, add the current cell to
  // the stack, remove the walls between current and next,
  // and make "next" the current cell. This way we move along the grid.
  if(next != null){
    next.visited = true;          // Mark the neighbor as visited
    stack.add(current);           // we're moving out of the current cell, add it to the stack
    current.isInStack = true;     // Mark "current" boolean for in stack.
    removeWalls(current,next);    // remove the walls between current and next
    current = next;               // move to next
  }

  // If there are no neighbors, it means we reached a dead end, we gotta go back.
  // So, if the stack has something, go to the previous cell in the stack by
  // removing the las cell and making the new last cell the current one.
  else if (stack.size() > 0) {
    int last = stack.size()-1;                                // define the index for the last cell
    println("last=" + last + " Stack size=" + stack.size());  // print for debug
    Cell lastCell = (Cell) stack.get(last);                   // get the last cell
    lastCell.isInStack = false;                               // remove the in stack boolean
    stack.remove(last);                                       // remove the last cell
    // println("new stack length=" + stack.size());

    // We need to check if the stack still has anything before trying to make
    // the "last" cell the current one, or else there will be an error.
    if(stack.size() > 0) {
      last = last-1;
      current = (Cell) stack.get(last);
      // println("current was assigned to last");
    }
  }
  else if (stack.size() == 0) {
    // Otherwise, if the stack is empty and there's no more neigbors,
    // it means the maze is done!
    // Let's save it as a PDF

    // Assign a name to the PDF file
    String fileName = nameAMaze();

    // To save the maze we'll re-draw the grid
    // now with the walls as they ended up being after
    // carving the maze. And it's shown in white to be printer friendly

    // We open the PDF with PGraphics so we can specify the size of the PDF with the size of the script
    pdfMaze = (PGraphicsPDF) createGraphics (wd,ht,PDF,fileName);
    // Start recording
    beginRecord(pdfMaze);
    println("Saving PDF: " + fileName);
    // Draw the maze in the PDF
    for(int i = 0; i<grid.size();i++){
      Cell each = (Cell) grid.get(i);
      // Paint every generic cell with the reuglar color
      // but highlight the start and finish cells with
      // their respective colors
      if(each.isStart) {each.highlight(startColor);}          // Highlight the start cell
      else if (each.isFinish) {each.highlight(finishColor);}  // Highlight the finish cell
      else {each.show(true);}                                 // Just show every other cell
    }
    // Done, end recording the PDF
    endRecord();
    // Bluff about your awesomeness
    println("Finished saving PDF");
    println("Saving JSON file");
    // Now let's save the maze in a JSON file so it can be solved later
    saveJMaze();
    // And now, let's send the PDF maze to Acrobat reader and print it so you can solve it by hand
    println("Printing the Maze");
    printTheMaze(fileName);       // will open reader, load the maze, and print it skipping the print dialog. Check the function for more info
    println("Done. Ba-bye!");
    // We're done. Bye bye baby!
    // exit(); is important because we're using PGraphics
    exit();
  }
}



// Let's create a Cell object
class Cell{
  int j; // coordinate for rows
  int i; // coordinate for columns
  boolean[] walls = {true,true,true,true}; //top,right,bottom,left
  boolean visited = false;    // has this cell been visited before?
  boolean isStart = false;    // is this cell the start of the maze?
  boolean isFinish = false;   // is this cell the finish of the maze?
  boolean isInStack = false;  // is this cell part of the stack?

  // this is the constructor
  Cell(int col, int row){
    i = col;
    j = row;
  }

  // Calculate the index of the previous cell to find it in the ArrayList
  int index(int i, int j){
    if(i<0 || j<0 || i>cols-1 || j>rows-1){
      return -1; //will return an invalid index that will be caught by isNeighbor
    }
    return i+j*cols;
  }

  // This function checks if the cell exists in the array,
  // and catches Java's error if it doesn't, preventing the
  // program to halt.
  boolean isNeighbor(int theIndex){
    if(theIndex == -1) return false; // if it doesn't exists, then catch the error and return false
    else return true; // if it exists, then return true
  }

  Cell checkNeighbors(){
    ArrayList neighbors = new ArrayList();
    boolean[] exist = {false,false,false,false};  //top,right,bottom,left

    // Check if the cell exists or not
    exist[0] = isNeighbor(index(i,j-1)); //top
    exist[1] = isNeighbor(index(i+1,j)); //right
    exist[2] = isNeighbor(index(i,j+1)); //bottom
    exist[3] = isNeighbor(index(i-1,j)); //left

    // Now, if they exist, then check if they have been visited
    // if they haven't add them to the ArrayList neighbors
    if(exist[0]){ // check for the top neighbor
      Cell top = (Cell) grid.get(index(i,j-1));
      if(!top.visited){
        neighbors.add(top);
      }
    }
    if(exist[1]){  // check for the right neighbor
      Cell right = (Cell) grid.get(index(i+1,j));
      if(!right.visited){
        neighbors.add(right);
      }
    }
    if(exist[2]){  // check for the bottom neighbor
      Cell bottom = (Cell) grid.get(index(i,j+1));
      if(!bottom.visited){
        neighbors.add(bottom);
      }
    }
    if(exist[3]){  // check for the left neighbor
      Cell left = (Cell) grid.get(index(i-1,j));
      if(!left.visited){
        neighbors.add(left);
      }
    }

    // If the neighbors ArrayList has anything on it, return me a random neighbor
    if(neighbors.size() > 0){
      int r = floor(random(0,neighbors.size()));
      Cell theNeighbor = (Cell) neighbors.get(r);
      return theNeighbor;
      } else {
        return null; //There's nothing here.
      }

      } //end of checkNeighbors

      // This function will draw the edges of the cell
      void show(boolean theEnd){
        /*
        Each cell has the next coords:
        (x,y)  ________ (x+w,y)
              |        |
              |        |
              |________|
        (x,y+w)         (x+w,y+w)
        */

        int x = i*w;
        int y = j*w;

        // DEFINING COLORS:
        // If it's not the end yet, check if the cell has been visited or not
        // If it has been visited, check if it's in the stack or not.
        // If it's not in the stack, paint it with the color for visited cells
        // If it hasn't been visited, paint it white
        // If it's the end, we want to show the whole maze as white. So paint them all white.
        if(!theEnd){
          if(visited) {
            if (isInStack){ fill(stackColor);}
            else {fill(cellColor);}
            } else {
              fill(endColor);
            }
          }
        else {
          fill(endColor);
        }
        noStroke();
        rect(x,y,w,w);

        // Now, paint the walls in black
        stroke(0);
        if(walls[0]) line(x,y,x+w,y);      //top
        if(walls[1]) line(x+w,y,x+w,y+w);  //right
        if(walls[2]) line(x+w,y+w,x,y+w);  //bottom
        if(walls[3]) line(x,y+w,x,y);      //left

        } // End of Show()

        void highlight(color theColor){
          // Paint the cell, but leave a border of "border" thickness
          // so we paint a square of the whole cell size
          // then we overlay a smaller square
          // and then we paint the walls.
          // This will allow to the walls to be visible.
          int x = i*w;
          int y = j*w;

          fill(endColor);
          noStroke();
          rect(x,y,w,w);
          fill(theColor);
          noStroke();
          rect(x+border,y+border,w-(2*border),w-(2*border));
          stroke(0);
          if(walls[0]) line(x,y,x+w,y);      //top
          if(walls[1]) line(x+w,y,x+w,y+w);  //right
          if(walls[2]) line(x+w,y+w,x,y+w);  //bottom
          if(walls[3]) line(x,y+w,x,y);      //left
        }

} // end of class Cell


void removeWalls(Cell a, Cell b){
  // check where the next cell is
  // First, check on X
  int x = a.i-b.i;
  if(x == 1){             // if "next" is on the right:
    a.walls[3] = false;     // remove right wall of "current"
    b.walls[1] = false;     // remove left wall of "next"
  } else if (x == -1) {   // else, if "next" is on the left:
    a.walls[1] = false;   // remove left wall of "current"
    b.walls[3] = false;   // remove right wall of "next"
  }
  // Now, check on Y
  int y = a.j-b.j;
  if(y == 1){             // if "next" is on the top:
    a.walls[0] = false;     // remove top wall of "current"
    b.walls[2] = false;     // remove bottom wall of "next"
  } else if (y == -1) {   // else, if "next" is on the bottom:
    a.walls[2] = false;   // remove bottom wall of "current"
    b.walls[0] = false;   // remove top wall of "next"
  }

}// end of removeWalls




int defineStart(){
  int randoStart = 0;//floor(random(0,grid.size()));
  return randoStart;
}




int defineFinish(){
  int randoFinish = floor(grid.size()-1); //floor(random(0,grid.size()));
  return randoFinish;
}




String nameAMaze(){
  println("Naming the maze");
  File f = dataFile(sketchPath(thePath));
  String[] files = f.list();
  println("There are " + files.length + " Mazes in the folder");
  // printArray(fileNames);
  int fileIndex = files.length + 1;
  String theFile = "/Mazes/Maze-" + fileIndex + "-" + cols + "x" + rows + ".pdf";
  println("Maze name: " + theFile);
  return theFile;
}



void printTheMaze(String theMaze){
  // Lets print the maze silently (no annoying print dialog)
  // If your acrobat reader is not setup for "Auto Rotate Landscape/Portrait"
  // then Acrobat will most likely force the maze to be printed in a
  // portrait orientation. Acrobat is annoying in the sense that this settings
  // can only be changed in the registry (Windows).
  // No API support for this. No command line parameter...
  // So, if you need to (and know how without frying your computer),
  // Go "regedit" this key:
  // HKEY_CURRENT_USER\Software\Adobe>product<>version<\AVGeneral\bprintAutoRotate
  // and change the REG_DWORD Value to 1 for auto-rotate
  // If you don't want to (know how to) change your registry keys, then simply change the parameter
  // for quiet printing from "/t" to "/p" (launchThis[3]) to show the print dialog

  // Lets assemble the string of parameters (Acrobat, parameters, filename)
  // Each parameter needs to be in its own object, this is because of how launch() works
  String[] launchThis = new String[5];{
    launchThis[0] = rdrLocation;  // Where can I find Acrobat Reader?
    launchThis[1] = "/n";         // to open a new instance of reader even if another one is aleady open
    launchThis[2] = "/o";         // to skip the "open" dialog
    launchThis[3] = "/t";         // to print quietly (skip print dialog), otherwise "/p" to go through the print dialog
    launchThis[4] = sketchPath("") + theMaze;      // Get the maze file path
  }
  // show what got assembled for debug
  println("launching: " + launchThis[0] + " " + launchThis[1] + " " + launchThis[2] + " " + launchThis[3] + " " + launchThis[4]);
  // launch acrobat reader with the specified parameters
  launch(launchThis);
  // just bluff
  println("Should have launched, and printed!");
}