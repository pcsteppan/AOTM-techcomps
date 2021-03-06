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
    } 
    
    public void addEdge(Node u, Node v){
        if(!(adj.containsKey(u) && adj.containsKey(v))) {
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
      if(!(nodes.containsKey(id)))
        return null;
      return nodes.get(id);
    }
    
    private String getEdgeAsString(Node u, Node v){
      return String.valueOf(Math.min(u.id, v.id)) + "-" + Math.max(u.id, v.id);
    }
    
    /**
    *  MODES: STANDARD, OFFSET, EXPOSURE, MORTAL_ENGINE
    */
    public void draw(String mode, PImage imageM, PImage imageF){
      imageM.loadPixels();
      imageF.loadPixels();
      BlobInformation displacementInformationM = new BlobInformation(imageM); //<>//
      BlobInformation displacementInformationF = new BlobInformation(imageF);
      float distanceBetweenCentersOfMass = displacementInformationM.centerOfMassNorm.x - displacementInformationF.centerOfMassNorm.x;
      float sinTime = sin(millis()/3000.);
      
      for(Integer id : nodes.keySet()){
        Node n = nodes.get(id);
        PImage image = n.normCoord.x < 0.5 ? imageF : imageM;
        BlobInformation displacementInformation = n.normCoord.x < 0.5 ? displacementInformationF : displacementInformationM; 
        if (mode.equals("OFFSET")){
          if(n.normCoord.x < displacementInformationF.centerOfMassNorm.x){
            n.normOffset = displacementInformationF.queryOffset(n.normCoord, 0.04);
          } else if ( n.normCoord.x > displacementInformationM.centerOfMassNorm.x) {
            n.normOffset = displacementInformationM.queryOffset(n.normCoord, 0.04);
          } else {
            Vec2<Float> m = displacementInformationM.queryOffset(n.normCoord, 0.02);
            float mxDiff = displacementInformationM.centerOfMassNorm.x - n.normCoord.x;
            Vec2<Float> f = displacementInformationF.queryOffset(n.normCoord, 0.02);
            float fxDiff = n.normCoord.x - displacementInformationF.centerOfMassNorm.x;
            n.normOffset.x = n.normOffset.x + m.x * (1 - mxDiff / distanceBetweenCentersOfMass) + f.x * (1 - fxDiff / distanceBetweenCentersOfMass);
            n.normOffset.x /= 2.;
            n.normOffset.y = n.normOffset.y + n.normCoord.x < 0.5 ? f.y : m.y;
            n.normOffset.y /= 2.;
          }
          
          float positiveDelta = 0.50;
          float delta;
          Vec2<Float> normOffsetPosition = n.normCoord;
          color pixel = image.pixels[(int)( ( (int)(normOffsetPosition.y*(image.height-1))*(image.width)) + (int)((normOffsetPosition.x*(image.width-1))) )];
          if(pixel != 0x00000000 && pixel != 0x00FFFFFF){
            delta = positiveDelta;
          } else {
            delta = n.exposure * -0.63;
            if(sin(n.normCoord.x + n.normCoord.y + millis()*0.0005) < -.940 && Math.random() > 0.98)
              delta += 0.25;
          }
          n.exposure = Math.max(0.0, Math.min(1.0, n.exposure + delta));
          //n.normOffset = displacementInformation.queryOffset(n.normCoord, 0.04);
        } else if (mode.equals("EXPOSURE")){
          float positiveDelta = 0.50;
          float delta;
          Vec2<Float> normOffsetPosition = n.getNormOffsetPosition();
          color pixel = image.pixels[(int)( ( (int)(normOffsetPosition.y*(image.height-1))*(image.width)) + (int)((normOffsetPosition.x*(image.width-1))) )];
          if(pixel != 0x00000000 && pixel != 0x00FFFFFF){
            delta = positiveDelta;
          } else {
            delta = n.exposure * -0.7;
            if(sin(n.normCoord.x + n.normCoord.y + millis()*0.0005) < -.940 && Math.random() > 0.98)
              delta += 0.25;
          }
          if(!Float.isNaN(displacementInformation.centerOfMass.x)){
            // OUTWARD
            Vec2<Float> difference = n.normCoord.sub(displacementInformation.centerOfMassNorm).scale(2*n.exposure); //<>//
            // INWARD
            //Vec2<Float> difference = displacementInformation.centerOfMassNorm.sub(n.normCoord).scale(0.06*n.exposure);
            n.setNormOffset(difference);
            n.exposure = Math.max(0.0, Math.min(1.0, n.exposure + delta));
          }
        } else if (mode.equals("MORTAL_ENGINE")){
          float positiveDelta = 1.;
          float negativeDelta = -0.0825;
          float delta;
          color pixel = image.pixels[(int)( ( (int)(n.normCoord.y*(image.height-1))*(image.width)) + (int)((n.normCoord.x*(image.width-1))) )];
          if(pixel != 0x00000000 && pixel != 0x00FFFFFF){
            delta = positiveDelta;
          } else {
            delta = negativeDelta;
          }
          n.exposure = Math.max(0.0, Math.min(1.0, n.exposure + delta));
        }
      }
      
      if(mode.equals("EXPOSURE") || mode.equals("MORTAL_ENGINE") || mode.equals("OFFSET")){
        for(Integer id: nodes.keySet()){
          Node n1 = nodes.get(id);
          float totalExposure = n1.exposure;
          Vec2<Float> avgNormOffset = n1.normOffset.scale(n1.exposure);
          int denominator = 1;
          for(Node n2: adj.get(n1)){
            totalExposure += n2.exposure;
            avgNormOffset = avgNormOffset.add(n2.normOffset.scale(n2.exposure));
            denominator++;
          }
          float exposure = totalExposure / (float) denominator;
          float shapingFunctionScalar = 0.45;
          if(mode.equals("MORTAL_ENGINE")){
            shapingFunctionScalar = 0.05;
          }
          // f(x) = x + 2s x (1-x)
          // needs to be replaced with correct shapingFunction
          exposure = exposure + shapingFunctionScalar * 2 * exposure * ( 1 - exposure );
          n1.exposure = exposure;
          avgNormOffset = avgNormOffset.scale(1. / (float) denominator);
          if(mode.equals("EXPOSURE") || mode.equals("MORTAL_ENGINE"))
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
      
      boolean MORTAL_ENGINE_FLAG = false;
      
      while(!frontier.isEmpty()){
        Node curr = frontier.remove();
        MORTAL_ENGINE_FLAG = !visited.contains(curr);
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
          pgWireframe.stroke(0xFF8899aa);
          
          if(mode.equals("OFFSET")){
            nPos = n.getNormOffsetPosition();
            currPos = curr.getNormOffsetPosition();
            if(neighbors.size() < 4){
              currPos = curr.normCoord;
            }
            if(adj.get(n).size() < 4){
              nPos = n.normCoord;
            }
          } else if (mode.equals("EXPOSURE")){ //<>//
            nPos = n.getNormOffsetPosition();
            currPos = curr.getNormOffsetPosition();
            if(neighbors.size() < 4){
              currPos = curr.normCoord;
            }
            if(adj.get(n).size() < 4){
              nPos = n.normCoord;
            }
          } else if (mode.equals("MORTAL_ENGINE")){
            n.normCoord = n.normCoord;
            currPos = curr.normCoord;
          }
          
          if(mode.equals("STANDARD")){
            pgWireframe.stroke(0xFFFFFFFF);
            pgWireframe.strokeWeight(1);
            pgWireframe.line(nPos.x*width,
              nPos.y*height,
              currPos.x*width,
              currPos.y*height);
          } else if (mode.equals("OFFSET")){
            pgWireframe.strokeWeight((1-curr.exposure)*2.5+1.25);
            color colorA = 0xFFd8b9b2;
            color colorB = lerpColor(0xFFf62147, 0xFF4ea2e3, 1-(currPos.x*2 - 0.5));
            pgWireframe.stroke(lerpColor(colorA, colorB, curr.exposure));
            pgWireframe.line(nPos.x*width,
              nPos.y*height,
              currPos.x*width,
              currPos.y*height);
          } else if (mode.equals("EXPOSURE")){
            color colorA = 0xFFd8b9b2;
            color colorB = lerpColor(0xFFf62147, 0xFF4ea2e3, 1-(currPos.x*2 - 0.5));
            pgWireframe.stroke(lerpColor(colorA, colorB, curr.exposure));
            
            pgWireframe.stroke(lerpColor(colorA, colorB, curr.exposure));
            pgWireframe.strokeWeight((curr.exposure*1.75+1.00));
            //stroke(map(curr.exposure, 0., 1., 90., 255.));
            pgWireframe.line(nPos.x*width,
              nPos.y*height,
              currPos.x*width,
              currPos.y*height);
          } //<>//
            
          if(visited.contains(n))
            continue;
          
          frontier.add(n);
        }
        if (mode.equals("MORTAL_ENGINE") && MORTAL_ENGINE_FLAG){
            int size = 8;
            color colorA = 0xFF7F8F97;
            color colorB = 0xFFC0F3F3;
            
            pgWireframe.stroke(lerpColor(colorA, colorB, curr.exposure*curr.exposure));
            pgWireframe.strokeWeight(map(curr.exposure,0.,1.,1.5,1.0));
            float lineScale = curr.exposure*2;
            float rot = map(sinTime, -1., 1., PI*.25, PI*-0.25);
            rot += map(curr.exposure, 0., 1., 0, PI*1.125);
            pgWireframe.pushStyle();
            //if(curr.exposure > 0.1)
              pgWireframe.blendMode(ADD);
            float p1x = curr.normCoord.x*width + cos(rot) * size * (lineScale+0.8);
            float p2x = curr.normCoord.x*width - cos(rot) * size * (lineScale+0.8);
            float p1y = curr.normCoord.y*height + sin(rot) * size * (lineScale+0.95);
            float p2y = curr.normCoord.y*height - sin(rot) * size * (lineScale+0.95);
            
            pgWireframe.line(p1x, p1y, p2x, p2y);
            pgWireframe.popStyle();
          }
      }
    }
}
