// This sketch accompanies the MazeGenerator.pde master sketch
// it contains the functions that save the Maze as a JSON file
//
// By Oscar Frias (@_frix_) 2016
// www.oscarfrias.com
//
// What are we saving here?
// We're saving all the grid ArrayList, which is an array of Cell objects
// Each Cell has:
// walls{} array of booleans
// neighbors ArrayList of booleans
// visited boolean
// isStart boolean
// isFinish boolean
// i and j ints
//
// We don't need to save the neigbors, since they're only used to carve the maze.
// A solving maze will look at the "walls" array and decide from there.
// "visited" is also not necessary as it's only needed to carve the maze.
// i and j are needed as they are the coordinates of the cell
//
// So, the JSONObject cell, will have the following fields:
// i, j               (to locate the cell)
// walls{}            (to solve the maze)
// isStart, isFinish  (to know where to start and where to finish)
//
// The solver algorithm will have to create the Cell class again,
// so it may be worth it to pull that code out into its own sketch.
// It will also have to create a GRID ArrayList and fill it with the info pulled
// from the JSON Maze file. Then solve it.

JSONArray jMazeInfo;    // Array containing basic maze info: rows, cols
JSONArray jGrid;        // This is the array of jCells, the grid
JSONObject jCell;       // will be filled with each cell's info
JSONObject jMazeData;   // for the maze data

void saveJMaze(){
  // initialize our JSON Arrays
  jMazeInfo = new JSONArray();
  jGrid = new JSONArray();
  jMazeData = new JSONObject();

  jMazeData.setInt("width", wd);
  jMazeData.setInt("height", ht);
  jMazeData.setInt("cols", cols);
  jMazeData.setInt("rows", rows);
  jMazeData.setInt("cellsize", w);

  jMazeInfo.setJSONObject(0,jMazeData);

  jGrid.append(jMazeInfo);

  for(int i=0; i<grid.size();i++){
    // Initialize our JSON objects
    jCell = new JSONObject();
    // create a temp Cell object filled with the (i) element
    // of the grid ArrayList to pull all its data
    Cell tempJCell = (Cell) grid.get(i);
    // Fill the jCell object:
    jCell.setInt("id", i);
    jCell.setInt("i", tempJCell.i);
    jCell.setInt("j", tempJCell.j);
    jCell.setBoolean("isStart", tempJCell.isStart);
    jCell.setBoolean("isFinish", tempJCell.isFinish);

    jCell.setBoolean("wall0", tempJCell.walls[0]);
    jCell.setBoolean("wall1", tempJCell.walls[1]);
    jCell.setBoolean("wall2", tempJCell.walls[2]);
    jCell.setBoolean("wall3", tempJCell.walls[3]);

    // Save the object into the JSON Array
    jGrid.setJSONObject(i+1,jCell);
  }
  // Add the maze info to the JSON file

  // Save the array into a JSON file
  println("The maze is in a JSON array, saving the file now...");
  saveJSONArray(jGrid, "data/test.json");
  println("JSON file saved.");
}
