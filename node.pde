class Node {
  public final int WIDTH = 5690;
  public Integer id;
  
  public Vec2<Integer> coord;
  public Vec2<Float> normCoord;
  public Vec2<Float> normOffset;
  
  public boolean isExternal;
  public float exposure;
  
  public Node(Vec2<Integer> pCoord, int w, int h) {
    coord = new Vec2<Integer>(pCoord.x, pCoord.y);
    normCoord = new Vec2<Float>((float)pCoord.x / w, (float)pCoord.y / h);
    normOffset = new Vec2<Float>(0.,0.);
    id = pCoord.y*WIDTH+pCoord.x;
    isExternal = false;
    exposure = 0.;
    normOffset = new Vec2<Float>(0., 0.);
  }
  
  public Vec2<Float> getNormOffsetPosition() {
    //if (isExternal) return normCoord;
    //if (normOffset.x > 0.){
    //  System.out.println(normOffset.x);
    //}
    Vec2<Float> normOffsetPosition = normCoord.add(normOffset);
    normOffsetPosition.x = Math.min(1.0, Math.max(0.0, normOffsetPosition.x));
    normOffsetPosition.y = Math.min(1.0, Math.max(0.0, normOffsetPosition.y));
    return normOffsetPosition;
  }
  
  public Vec2<Float> getNormOffset() {
    return normOffset;
  }
  
  public void setNormOffset(Vec2<Float> f){
    normOffset = new Vec2<Float>(f);
    //normOffset.x = Math.max(0.0, Math.min(1.0, normOffset.x));
    //normOffset.y = Math.max(0.0, Math.min(1.0, normOffset.y));
  }
  
  public void draw(int w, int h) {
    pushStyle();
    strokeWeight(1);
    stroke(0);
    noFill();
    rectMode(CENTER);
    rect(getNormOffsetPosition().x*w, getNormOffsetPosition().y*h, 3, 3);
    popStyle();
  }
  
  //public void addNeighbor(Node n) {
  //  neighbors.add(n);
  //}
  @Override
  public boolean equals(Object o) {
    if (o==this)
      return true;
    
    if(!(o instanceof Node))
      return false;
    
    return this.id.equals(((Node) o).id);
  }
  
  @Override int hashCode()
  {
    return id;
  }
}
