import processing.video.*; //<>//

import java.util.*;

Movie shortMDancerClip;
Movie shortFDancerClip;

PImage mask;
PImage graphInputImage;
PImage dancerImage;
PImage dancerImageByItself;

PGraphics pgM;
PGraphics pgF;
PGraphics clearFBO;
PGraphics pgWireframe;
BlobInformation dancerImageInformation;
Graph graph;

color internalIntersect  = 0xFFFFFF00; // yellow
color internalVertical   = 0xFF00FF00; // green
color internalHorizontal = 0xFFFF0000; // red
  
color externalIntersect  = 0xFFFFFFFF; // white
color externalVertical   = 0xFF00FFFF; // cyan
color externalHorizontal = 0xFFFF00FF; // magenta  

void setup(){
  size(1422, 622);
  mask = loadImage("mask.png");
  graphInputImage = loadImage("nodeInputImage.png");
  graph = getGraphFromImageBFS(graphInputImage);
  dancerImage = loadImage("dancer.png");
  dancerImageByItself = loadImage("dancerImageByItself.png");
  
  shortMDancerClip = new Movie(this, "male_dancer_transparent_1.mp4");
  shortMDancerClip.loop();
  
  shortFDancerClip = new Movie(this, "female_dancer_video_c.mp4");
  shortFDancerClip.loop();
  
  pgF = createGraphics(1422,622);
  pgM = createGraphics(1422,622);
  pgWireframe = createGraphics(1422,622);
  clearFBO = createGraphics(1422,622);
  
  clearFBO.beginDraw();
  clearFBO.background(0xFF000000);
  clearFBO.endDraw();
  
  background(0x040109);
}

void draw(){
  pgM.beginDraw();
  pgM.clear();
  float videoscaleM = 0.65;
  // MORTAL ENGINE
  videoscaleM *= 0.85;
  pgM.image(shortMDancerClip, mouseX, height-(shortMDancerClip.height*videoscaleM), shortMDancerClip.width*videoscaleM, shortMDancerClip.height*videoscaleM);
  pgM.endDraw();
  
  pgF.beginDraw();
  pgF.clear();
  float videoscaleF = 1.0;
  // MORTALE ENGINE
  videoscaleF *= 0.75;
  pgF.image(shortFDancerClip, mouseX-(width/map(mouseY, 0, height, 2., 3.)), height-(shortFDancerClip.height*videoscaleF), shortFDancerClip.width*videoscaleF, shortFDancerClip.height*videoscaleF);
  pgF.endDraw();
  
  background(0xFF10061A);
  pgM.loadPixels();
  pgF.loadPixels();
  for(int i = 0; i < pgM.pixels.length; i++){
    pgM.pixels[i] = pgM.pixels[i] == 0xFF000000 ? 0x00000000 : pgM.pixels[i];
    pgF.pixels[i] = pgF.pixels[i] == 0xFF000000 ? 0x00000000 : pgF.pixels[i];
  }
  pgM.updatePixels();
  pgF.updatePixels();
  
  pgWireframe.beginDraw();
  //pgWireframe.tint(255,190);
  //pgWireframe.image(clearFBO, 0., 0.);
  //pgWireframe.noTint();
  pgWireframe.clear();
  graph.draw("EXPOSURE", pgM, pgF);
  pgWireframe.endDraw();
  
  image(pgWireframe, 0., 0.);
  image(pgM, 0., 0.);
  image(pgF, 0., 0.);
  image(mask, 0, 0, width, height);
}

void movieEvent(Movie m) {
  m.read();
}

Graph getGraphFromImageBFS(PImage img){
  Graph graph = new Graph();
  HashSet<Vec2<Integer>> visitedIndices = new HashSet<Vec2<Integer>>();
  LinkedList<Node> frontier = new LinkedList<Node>();
  
  Node currentNode;
  Vec2<Integer> currentIndex;
  
  // find top-left node and add it to frontier, graph, and its coord to visitied indices
  img.loadPixels();
  boolean firstNodeFound = false;
  for(int y = 0; y < img.height && !firstNodeFound; y++) {
    for(int x = 0; x < img.width && !firstNodeFound; x++) {
      if(isPixelInBounds(img, x, y) && isPixelInternalNode(img, x, y)){
        Node newNode = new Node(new Vec2<Integer>(x,y), img.width, img.height);
        graph.addNode(newNode);
        frontier.add(newNode);
        visitedIndices.add(newNode.coord);
        firstNodeFound = true;
      }
    }
  }
  
  while(!frontier.isEmpty()){
    // retrieves and removed from head of list
    currentNode = frontier.remove();
    currentIndex = new Vec2<Integer>(currentNode.coord);
    
    // traverse each cardinal direction
    Vec2<Integer>[] deltas = new Vec2[] {
      new Vec2<Integer>(0 , -1), // NORTH
      new Vec2<Integer>(1 , 0 ), // EAST
      new Vec2<Integer>(0 , 1 ), // SOUTH
      new Vec2<Integer>(-1, 0 ), // WEST
    };
    
    for(Vec2 delta : deltas) {
      boolean done = false;
      do {
        currentIndex = currentIndex.add(delta);
        // if out of bound or already visited, skip search and move onto next delta
        if(!isPixelInBounds(img, currentIndex.x, currentIndex.y)){
          currentIndex = new Vec2<Integer>(currentNode.coord);
          break;
        }
        
        boolean isInternalNode = isPixelInternalNode(img, currentIndex);
        boolean isExternalNode = isPixelExternalNode(img, currentIndex);
        
        if((isInternalNode || isExternalNode)) {
          if(visitedIndices.contains(currentIndex)){ // || nodes.containsKey(currentIndex)){
            graph.addEdge(currentNode, graph.getNode(currentIndex.toInt()));
          } else {
            Node newNode = new Node(new Vec2<Integer>(currentIndex), img.width, img.height);
            graph.addNode(newNode);
            graph.addEdge(newNode, currentNode);
            if(isInternalNode)
              frontier.add(newNode);
            visitedIndices.add(currentIndex);
          }
          currentIndex = new Vec2<Integer>(currentNode.coord);
          done = true;
        } else if (visitedIndices.contains(currentIndex)){
          currentIndex = new Vec2<Integer>(currentNode.coord);
          break;
        }
        visitedIndices.add(currentIndex);
      }
      while(!done);
    }
  }
  
  return graph;
}

boolean isPixelInternalNode(PImage img, int x, int y){
  // an internal node is yellow, and is bordered on the right or left by red, and is bordered on the top or bottom by green
  boolean n = isPixelInBounds(img, x  , y-1) && hex(img.pixels[linearIndexFrom2DIndex(x  , y-1, img.width)]).equals(hex(internalVertical));
  boolean e = isPixelInBounds(img, x+1, y  ) && hex(img.pixels[linearIndexFrom2DIndex(x+1, y  , img.width)]).equals(hex(internalHorizontal));
  boolean s = isPixelInBounds(img, x  , y+1) && hex(img.pixels[linearIndexFrom2DIndex(x  , y+1, img.width)]).equals(hex(internalVertical));
  boolean w = isPixelInBounds(img, x-1, y  ) && hex(img.pixels[linearIndexFrom2DIndex(x-1, y  , img.width)]).equals(hex(internalHorizontal));
  boolean c = isPixelInBounds(img, x  , y  ) && hex(img.pixels[linearIndexFrom2DIndex(x  , y  , img.width)]).equals(hex(internalIntersect));
  
  return (n || s) && (e || w) && c;
}

boolean isPixelInternalNode(PImage img, Vec2 v){
  return isPixelInternalNode(img, (int)v.x, (int)v.y);
}

boolean isPixelExternalNode(PImage img, int x, int y){
  // an external node is white, and is bordered on the right or left by magenta, and is bordered on the top or bottom by cyan
  //boolean n = isPixelInBounds(img, x  , y-1) && hex(img.pixels[linearIndexFrom2DIndex(x  , y-1, img.width)]).equals(hex(externalVertical));
  //boolean e = isPixelInBounds(img, x+1, y  ) && hex(img.pixels[linearIndexFrom2DIndex(x+1, y  , img.width)]).equals(hex(externalHorizontal));
  //boolean s = isPixelInBounds(img, x  , y+1) && hex(img.pixels[linearIndexFrom2DIndex(x  , y+1, img.width)]).equals(hex(externalVertical));
  //boolean w = isPixelInBounds(img, x-1, y  ) && hex(img.pixels[linearIndexFrom2DIndex(x-1, y  , img.width)]).equals(hex(externalHorizontal));
  boolean c = isPixelInBounds(img, x  , y  ) && hex(img.pixels[linearIndexFrom2DIndex(x  , y  , img.width)]).equals(hex(externalIntersect));
  
  //return (n || s) && (e || w) && c;
  return c;
}

boolean isPixelExternalNode(PImage img, Vec2 v){
  return isPixelExternalNode(img, (int)v.x, (int)v.y);
}

boolean isPixelInBounds(PImage img, int x, int y){
  return !(x < 0 || x >= img.width || y < 0 || y >= img.height);
}

int linearIndexFrom2DIndex(int x, int y, int w) {
  return y*w+x;
}
