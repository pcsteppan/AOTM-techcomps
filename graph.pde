import java.util.*;
import java.util.function.Function;

  
// Bi-directional adjacency with adjacency lists
class Graph { 
    
    private HashMap<Integer, Node> nodes;
    private HashMap<Node, LinkedList<Node>> adj;
    
    public Graph() {
      nodes = new HashMap<Integer, Node>();
      adj = new HashMap<Node, LinkedList<Node>>();
    }
    
    // A utility function to add an edge in an 
    // undirected graph 
    public void addEdge(Vec2<Integer> u, Vec2<Integer> v){
        addEdge(nodes.get(u.toInt()), nodes.get(v.toInt()));
        //adj.get(nodes.get(u.toInt())).add(nodes.get(v.toInt())); 
        //adj.get(nodes.get(v.toInt())).add(nodes.get(u.toInt())); 
    } 
    
    public void addEdge(Node u, Node v){
        if(!(adj.containsKey(u))){
          System.out.println("Key not found for nodes: " + u.coord);
          return;
        } else if (!(adj.containsKey(v))) {
          System.out.println("Key not found for nodes: " + v.coord);
          return;
        }
        adj.get(u).add(v); 
        adj.get(v).add(u); 
    } 
    
    public void addNode(Node n) {
      nodes.put(n.id, n);
      adj.put(n, new LinkedList<Node>());
    }
    
    public Node getNode(int id) {
      if(!(nodes.containsKey(id))){
        System.out.println("No Node found with id:" + id);
        return null;
      }
      return nodes.get(id);
    }
    
    private String getEdgeAsString(Node u, Node v){
      return String.valueOf(Math.min(u.id, v.id)) + "-" + Math.max(u.id, v.id);
    }
    
    /**
    *  MODES: STANDARD, OFFSET
    */
    public void draw(String mode, PImage image){
      image.loadPixels(); //<>//
      BlobInformation displacementInformation = new BlobInformation(image);
      float noiseSeed = noise(millis()/2000.);
      float sinTime = sin(millis()/3000.);
      
      for(Integer id : nodes.keySet()){
        Node n = nodes.get(id);
        if (mode.equals("OFFSET")){
          // note: this might need to be edited with all the changes made to node for the EXPOSURE mode
          n.normOffset = displacementInformation.queryOffset(n.normCoord, 0.04);
        } else if (mode.equals("EXPOSURE")){
          float positiveDelta = 0.35;
          float negativeDelta = -0.0175;
          float delta;
          Vec2<Float> normOffsetPosition = n.getNormOffsetPosition();
          color pixel = image.pixels[(int)( ( (int)(normOffsetPosition.y*(image.height-1))*(image.width)) + (int)((normOffsetPosition.x*(image.width-1))) )];
          if(pixel != 0x00000000 && pixel != 0x00FFFFFF){
            delta = positiveDelta;
          } else {
            delta = negativeDelta;
          }
          Vec2<Float> difference = n.normCoord.sub(displacementInformation.centerOfMassNorm).scale(0.08*n.exposure);
          n.setNormOffset(n.normOffset.add(difference));
          n.exposure = Math.max(0.0, Math.min(1.0, n.exposure + delta));
        } else if (mode.equals("MORTAL_ENGINE")){
          float positiveDelta = 1.;
          float negativeDelta = -0.0695;
          float delta;
          color pixel = image.pixels[(int)( ( (int)(n.normCoord.y*(image.height-1))*(image.width)) + (int)((n.normCoord.x*(image.width-1))) )];
          if(pixel != 0x00000000 && pixel != 0x00FFFFFF){
            delta = positiveDelta;
          } else {
            delta = negativeDelta;
          }
          //Vec2<Float> difference = n.normCoord.sub(displacementInformation.centerOfMassNorm).scale(0.03*n.exposure);
          //n.setNormOffset(n.normOffset.add(difference));
          n.exposure = Math.max(0.0, Math.min(1.0, n.exposure + delta));
        }
      }
      
      if(mode.equals("EXPOSURE") || mode.equals("MORTAL_ENGINE")){
        for(Integer id: nodes.keySet()){
          Node n1 = nodes.get(id);
          float totalExposure = n1.exposure;
          //Vec2<Float> avgNormOffsetPosition = n1.normCoord.add(n1.normOffset.scale(n1.exposure));
          Vec2<Float> avgNormOffset = n1.normOffset.scale(n1.exposure);
          int denominator = 1;
          for(Node n2: adj.get(n1)){
            totalExposure += n2.exposure;
            //avgNormOffsetPosition = avgNormOffsetPosition.add(n2.normCoord.add(n2.normOffset.scale(n2.exposure)));
            avgNormOffset = avgNormOffset.add(n2.normOffset.scale(n2.exposure));
            denominator++;
          }
          n1.exposure = totalExposure / (float) denominator;
          avgNormOffset = avgNormOffset.scale(1. / (float) denominator);
          //Vec2<Float> newNormOffset = avgNormOffsetPosition.sub(n1.normCoord);
          //System.out.println(newNormOffset.x);
          //n1.setNormOffset(newNormOffset);
          n1.setNormOffset(avgNormOffset);
        }
      }
      
      //draw via ITERATIVE BFS
      HashSet<Node> visited = new HashSet<Node>();
      HashSet<String> drawnEdges = new HashSet<String>();
      LinkedList<Node> frontier = new LinkedList<Node>();
      
      //get a node to start from
      Node origin = nodes.values().iterator().next();
      frontier.add(origin);
      
      while(!frontier.isEmpty()){
        Node curr = frontier.remove();
        visited.add(curr);
        LinkedList<Node> neighbors = adj.get(curr);
        
        for(Node n : neighbors) {
          String edgeId = getEdgeAsString(n, curr);
          if(drawnEdges.contains(edgeId))
            continue;
          drawnEdges.add(edgeId);
          
          // implicity in STANDARD mode
          // STANDARD instantiated values
          Vec2<Float> nPos = n.normCoord; 
          Vec2<Float> currPos = curr.normCoord; 
          stroke(0xFF8899aa);
          
          if(mode.equals("OFFSET")){
            nPos = n.getNormOffsetPosition();
            currPos = curr.getNormOffsetPosition();
          } else if (mode.equals("EXPOSURE")){ //<>//
            nPos = n.getNormOffsetPosition();
            currPos = curr.getNormOffsetPosition();
          } else if (mode.equals("MORTAL_ENGINE")){
            currPos = curr.getNormOffsetPosition();
          }
          
          if(mode.equals("OFFSET")){
            stroke(map(curr.exposure, 0., 1., 90., 255.));
            line(nPos.x*width,
              nPos.y*height,
              currPos.x*width,
              currPos.y*height);
          } else if(mode.equals("EXPOSURE")){
            color colorA = 0xAA5050CC; // BLUE
            color colorB = 0xFFFF6666; // RED
            stroke(lerpColor(colorA, colorB, curr.exposure));
            //stroke(map(curr.exposure, 0., 1., 90., 255.));
            line(nPos.x*width,
              nPos.y*height,
              currPos.x*width,
              currPos.y*height);
          } else if (mode.equals("MORTAL_ENGINE")){
            int size = 11;
            color colorA = 0xFF6F7F87;
            color colorB = 0xFF90A3A3;
            stroke(lerpColor(colorA, colorB, curr.exposure*curr.exposure));
            strokeWeight(map(curr.exposure,0.,1.,0.95,0.7));
            float lineScale = curr.exposure*curr.exposure*4;
            float rot = map(sinTime, -1., 1., PI*.375, PI*-0.2);
            rot += map(curr.exposure, 0., 1., 0, PI*1.5);
            //float rot = map(curr.exposure+noiseSeed*0.3, 0., 1., PI*0.333, TWO_PI*0.825);
            pushStyle();
            blendMode(SCREEN);
            float p1x = currPos.x*width + cos(rot) * size * (lineScale+1);
            float p2x = currPos.x*width - cos(rot) * size * (lineScale+1);
            float p1y = currPos.y*height + sin(rot) * size * (lineScale+1);
            float p2y = currPos.y*height - sin(rot) * size * (lineScale+1);
            popStyle();
            line(p1x, p1y, p2x, p2y);
            //rot = map(curr.exposure+noiseSeed*0.3, 0., 1., PI*0.333, TWO_PI*0.825);
            //float p3x = currPos.x*width + cos(rot+PI/2.) * size * (curr.exposure+2);
            //float p4x = currPos.x*width - cos(rot+PI/2.) * size * (curr.exposure+2);
            //float p3y = currPos.y*height + sin(rot+PI/2.) * size * (curr.exposure+2);
            //float p4y = currPos.y*height - sin(rot+PI/2.) * size * (curr.exposure+2);
            //line(p3x,p3y,p4x,p4y);
          }
            
          //stroke(0xFFFF0000);
          //line(curr.normCoord.x*width,
          //  curr.normCoord.y*height,
          //  (curr.normCoord.x+curr.normOffset.x)*width,
          //  (curr.normCoord.y+curr.normOffset.y)*height);
            
          if(visited.contains(n))
            continue;
          
          frontier.add(n);
        }
      }
    }
    
    /* GRAPHS ARE TOO BIG TO USE DFS OR BFS, ITERATIVE SOLUTIONS BEST
    public void drawDispersion(){
      Node origin = nodes.values().iterator().next();
      LinkedList<Node> q = new LinkedList<Node>();
      q.add(origin);
      recursiveNodeVisitDispersion(
        new HashSet<Node>(),
        new HashSet<String>(),
        q
      );
    }
    
    
    public void recursiveNodeVisitDispersion(HashSet<Node> visited, HashSet<String> edgesDrawn, LinkedList<Node> q){
      if(q.isEmpty()){
        return;
      }
      
      Node n = q.pop();
      System.out.println(n.id);
      
      // down tree
      for(Node neighbor: adj.get(n)) {
        if(!visited.contains(neighbor)){
          visited.add(neighbor);
          //neighbor.updateDispersion();
          q.push(neighbor);
        }
      }
      
      recursiveNodeVisitDispersion(visited, edgesDrawn, q);
      
      // up tree
      // draw node
      rect(n.coord.x, n.coord.y, 5, 5);
      // draw edge
      for(Node neighbor: adj.get(n)) {
        String edge = getEdgeAsString(n, neighbor);
        if(!edgesDrawn.contains(edge)){
          edgesDrawn.add(edge);
          line(n.coord.x, n.coord.y, neighbor.coord.x, neighbor.coord.y);
        }
      }
      
      return;
    }
    */
    
    //// A utility function to print the adjacency list 
    //// representation of graph 
    //void printGraph(ArrayList<ArrayList<Integer> > adj){ 
    //    for (int i = 0; i < adj.size(); i++) { 
    //        System.out.println("\nAdjacency list of vertex" + i); 
    //        System.out.print("head"); 
    //        for (int j = 0; j < adj.get(i).size(); j++) { 
    //            System.out.print(" -> "+adj.get(i).get(j)); 
    //        } 
    //        System.out.println(); 
    //    } 
    //}
}
