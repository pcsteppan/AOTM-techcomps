class Vec2<T extends Number> {
  public T x;
  public T y;
  public final int WIDTH = 5690;
  
  Vec2(T px, T py){
    x = px;
    y = py;
  }
  
  Vec2(Vec2<T> toCopy){
    x = toCopy.x;
    y = toCopy.y;
  }
  
  public Vec2<T> add(Vec2<T> d) {
    if (d.x instanceof Float) {
        return new Vec2<T>((T)Float.valueOf(this.x.floatValue() + d.x.floatValue()), (T)Float.valueOf(this.y.floatValue() + d.y.floatValue()));
    } else if (d.x instanceof Integer) {
        return new Vec2<T>((T)Integer.valueOf(this.x.intValue() + d.x.intValue()), (T)Integer.valueOf(this.y.intValue() + d.y.intValue()));
    }
    throw new IllegalArgumentException();
  }
  
  public Vec2<T> sub(Vec2<T> d) {
    if (d.x instanceof Float) {
        return new Vec2<T>((T)Float.valueOf(this.x.floatValue() - d.x.floatValue()), (T)Float.valueOf(this.y.floatValue() - d.y.floatValue()));
    } else if (d.x instanceof Integer) {
        return new Vec2<T>((T)Integer.valueOf(this.x.intValue() - d.x.intValue()), (T)Integer.valueOf(this.y.intValue() - d.y.intValue()));
    }
    // you can add all types or throw an exception
    throw new IllegalArgumentException();
  }
  
  public Vec2<T> scale(float s) {
    //might not play well with scaling Vec2<Integer>s
    return new Vec2<T>((T)Float.valueOf(this.x.floatValue() * s), (T)Float.valueOf(this.y.floatValue() * s));
  }
  
  public int toInt(){
    return x.intValue() + (y.intValue()*WIDTH);
  }
  
  @Override
  public boolean equals(Object o) {
    if (o==this)
      return true;
    
    if(!(o instanceof Vec2))
      return false;
      
    Vec2<T> v = (Vec2<T>) o;
    
    return this.x.equals(v.x) && this.y.equals(v.y);
  }
  
  @Override int hashCode()
  {
    return (int)this.y * WIDTH + (int)this.x;
  }
  
  @Override
  public String toString(){
    return "x: " + this.x + ", y: " + this.y;
  }
}
