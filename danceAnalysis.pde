class BlobInformation{
  Vec2<Float> centerOfMass;
  Vec2<Float> centerOfMassNorm;
  int[] topDown;
  int[] bottomUp;
  int[] LR;
  int[] RL;
  
  BlobInformation(PImage img){
    topDown = new int[img.width];
    bottomUp = new int[img.width];
    LR = new int[img.height];
    RL = new int[img.height];
    
    centerOfMass = new Vec2<Float>(0.,0.);
    
    img.loadPixels();
    int totalPixelsInMass = 0;
    for(int y = 0; y < img.height; y++){
      for(int x = 0; x < img.width; x++){
        if(img.pixels[y*img.width+x]!=0x00000000 && img.pixels[y*img.width+x]!=0x00FFFFFF){
          
          totalPixelsInMass++;
          centerOfMass = centerOfMass.add(new Vec2<Float>((float)x,(float)y));
          
          RL[y] = x;
          
          if(LR[y] == 0){
            LR[y] = x;
          }
          
          bottomUp[x] = y;
          
          if(topDown[x] == 0){
            topDown[x] = y;
          }
          
        }
      }
    }
    centerOfMass = new Vec2<Float>(centerOfMass.x / (float)totalPixelsInMass, centerOfMass.y / (float)totalPixelsInMass);
    centerOfMassNorm = new Vec2<Float>(centerOfMass.x / (float)topDown.length, centerOfMass.y / (float)LR.length);
  }
  
  // p represents a percentage of the normalized space to query the real space displacement, to average a range of the displacement array rather than only one pixel
  public Vec2<Float> queryOffset(Vec2<Float> v, float p){
    Vec2<Float> difference = new Vec2<Float>(v.x-centerOfMassNorm.x,v.y-centerOfMassNorm.y);
    Vec2<Float> offset = new Vec2<Float>(0.,0.);
    
    // x is negative means v is to the west of center
    // x is positive means v is to the east of center
    // y is negative means v is to the north of center
    // y is positive means v is to the south of center
    
    int queryLowerLimit = (int)((v.y-p/2)*LR.length);
    queryLowerLimit = Math.max(0, queryLowerLimit);
    int queryUpperLimit = (int)((v.y+p/2)*LR.length);
    queryUpperLimit = Math.min(LR.length-1, queryUpperLimit);
    int totalDisplacementFromCenter = 0;
    int averagingQuotient = 0;
    for(int i = queryLowerLimit; i < queryUpperLimit; i++) {
      if(difference.x <= 0){
        if(LR[i] > 0){
          averagingQuotient++;
          totalDisplacementFromCenter += (int) (LR[i] - centerOfMass.x);
        } else {
          averagingQuotient++;
          totalDisplacementFromCenter += 0;
        }
      } else {
        if(RL[i] > 0){
          averagingQuotient++;
          totalDisplacementFromCenter += (int) (RL[i] - centerOfMass.x);
        } else {
          averagingQuotient++;
          totalDisplacementFromCenter += 0;
        }
      }
    }
    totalDisplacementFromCenter = (int)((float) totalDisplacementFromCenter / (float)(averagingQuotient));
    offset.x = totalDisplacementFromCenter / (float) topDown.length;
    

    queryLowerLimit = (int)((v.x-p/2)*topDown.length);
    queryLowerLimit = Math.max(0, queryLowerLimit);
    queryUpperLimit = (int)((v.x+p/2)*topDown.length);
    queryUpperLimit = Math.min(topDown.length-1, queryUpperLimit);
    totalDisplacementFromCenter = 0;
    averagingQuotient = 0;
    for(int i = queryLowerLimit; i < queryUpperLimit; i++) {
      if(difference.y <= 0){
        if(topDown[i] > 0){
          averagingQuotient++;
          totalDisplacementFromCenter += (int) (topDown[i] - centerOfMass.y);
        } else {
          averagingQuotient++;
          totalDisplacementFromCenter += 0;
        }
      } else {
        if(bottomUp[i] > 0){
          averagingQuotient++;
          totalDisplacementFromCenter += (int) (bottomUp[i] - centerOfMass.y);
        } else {
          averagingQuotient++;
          totalDisplacementFromCenter += 0;
        }
      }
    }
    totalDisplacementFromCenter = (int)((float) totalDisplacementFromCenter / (float)(averagingQuotient));
    offset.y = totalDisplacementFromCenter / (float) topDown.length;
    //return offset;
    
    float distanceModifier = dist(0.,0.,difference.x,difference.y);
    distanceModifier = 1 - distanceModifier;
    distanceModifier *= distanceModifier;
    offset.x *= distanceModifier;
    offset.y *= distanceModifier;
    return offset;
    //return new Vec2<Float>(0.,0.);
  }
  
  @Override
  public String toString() {
    return topDown.toString();
  }
}
