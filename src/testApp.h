#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"

#include "ofxQCAR.h"
#include "ofxAssimpModelLoader.h"
#include "ofxBullet.h"

#include "ofxOsc.h"

class testApp : public ofxQCAR_App {
	
public:
    void setup();
    void update();
    void draw();
    void exit();
	
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);
    
    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    
    //vuforial
    ofPoint touchPoint;
    ofImage cameraImage;
    int scaleExtTrack;
    
    //3d model overlay on physical block
    ofxAssimpModelLoader model;
    ofImage model_outline;
    
    //3d physics simulation
    ofxBulletWorldRigid			world;
    ofxBulletBox				ground;
    ofxBulletBox*				box[7];
    
    ofQuaternion q21;
    float cx21, cy21, cz21;
    
    //communication
    ofxOscReceiver receiver;
    float rot[3], gyro[3];
    int cnt_explode;
    int which_block;
};


