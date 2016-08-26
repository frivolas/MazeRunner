// Let's write a depth-first, recursive bactracker algorithm to create a maze
// based on https://en.wikipedia.org/wiki/Maze_generation_algorithm
// and on https://www.youtube.com/watch?v=HyK_Q5rrcr4

import processing.pdf.*;

int w = 10;     // size of the cell in px
int border;
int cols,rows;  // to define the size of the maze
int startX, startY, endX, endY;
int lastIndex;
ArrayList grid;
ArrayList stack;
Cell current,top,right,bottom,left;
color cellColor = color(0,114,204,100);
color endColor = color(255,255,255);
color startColor = color(0,255,0);
color finishColor = color(255,0,0);
color highlightColor = color(255,255,255,100);


void setup(){
  //initialize the maze
  size(1700,1100);  // Spec the size of the maze
  background(0);    // black bg
  border = w/10;    // set the border around the highlighted cell (to be able to show the walls)
  // frameRate(10);

  //define the grid
  cols= floor(width/w);
  rows= floor(height/w);
  println("Painting a " + cols + " x " + rows + " Grid");
  // define the grid and stack ArrayLists
  grid = new ArrayList();
  stack = new ArrayList();
  // for each row, go through every column and add a cell to the grid
  for(int j=0; j<rows; j++){
    for(int i=0; i<cols; i++){
      Cell cell = new Cell(i,j);
      grid.add(cell);
    }
  }

  int startPos = defineStart();
  int finishPos = defineFinish();
  while(abs(finishPos-startPos) < grid.size()*.75) {
    finishPos = defineFinish();
  }
  println("Start cell: " + startPos + " | Finish Cell: " + finishPos);
  Cell theStart = (Cell) grid.get(startPos);
  Cell theFinish = (Cell) grid.get(finishPos);
  theStart.isStart = true;
  theFinish.isFinish = true;

  // Go to the first cell in the grid to start
  current = (Cell) grid.get(startPos);
}



void draw(){
  // Draw the grid
  for (int i =0; i<grid.size();i++){
    Cell each = (Cell) grid.get(i);
    each.show(false);
  }
  // Step 1 per wikipedia
  current.visited = true;
  current.highlight(highlightColor);
  Cell next = current.checkNeighbors();

  if(next != null){
    next.visited = true;
    // Step 2
    stack.add(current);
    // Step 3
    removeWalls(current,next);
    // Step 4
    current = next;
  }

  else if (stack.size() > 0) {
    int last = stack.size()-1;
    println("last=" + last + " Stack size=" + stack.size());
    stack.remove(last);
    // println("new stack length=" + stack.size());
    if(stack.size() > 0) {
      last = last-1;
      current = (Cell) stack.get(last);
      // println("current was assigned to last");
    }
  }
  else if (stack.size() == 0) {
    // The stack is empty and there's no more neigbors:
    // the maze is done!
    // Let's save it as a PDF
    beginRecord(PDF,"/Mazes/Maze-####.pdf");
    println("Saving PDF");
    for(int i = 0; i<grid.size();i++){
      Cell each = (Cell) grid.get(i);
      // Paint every generic cell with the reuglar color
      // but highlight the start and finish cells with
      // their respective colors
      if(each.isStart) {each.highlight(startColor);}          // Highlight the start cell
      else if (each.isFinish) {each.highlight(finishColor);}  // Highlight the finish cell
      else {each.show(true);}                                 // Just show every other cell
    }
    endRecord();
    println("Finished saving PDF");
    noLoop(); //stop the program. Nothing else to do.
    // exit();
  }
}



// Let's create a Cell object
class Cell{
  int j; // coordinate for rows
  int i; // coordinate for columns
  boolean[] walls = {true,true,true,true}; //top,right,bottom,left
  boolean visited = false;  // has this cell been visited before?
  boolean isStart = false;  // is this cell the start of the maze?
  boolean isFinish = false; // is this cell the finish of the maze?


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

        if(!theEnd){
          if(visited) {
            fill(cellColor);
          } else {
            fill(endColor);
          }
        }
        else {
          fill(endColor);
        }
        noStroke();
        rect(x,y,w,w);

        stroke(0);
        if(walls[0]) line(x,y,x+w,y);      //top
        if(walls[1]) line(x+w,y,x+w,y+w);  //right
        if(walls[2]) line(x+w,y+w,x,y+w);  //bottom
        if(walls[3]) line(x,y+w,x,y);      //left



        } // End of Show()

        void highlight(color theColor){
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
  int randoStart = floor(random(0,grid.size()));
  return randoStart;
}

int defineFinish(){
  int randoFinish = floor(random(0,grid.size()));
  return randoFinish;
}

//
// void showGoals(){
//   for(int i=0; i<grid.size(); i++){
//     Cell theCell = (Cell) grid.get(i);
//     if (theCell.isStart){
//       startX = theCell.i;
//       startY = theCell.j;
//     } else if (theCell.isFinish){
//       endX = theCell.i;
//       endX = theCell.j;
//     }
//   }
//   noStroke();
//   fill(0,255,0);
//   rect(startX,startY,w,w);
// }
