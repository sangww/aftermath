#include "testApp.h"

//#define RAMP_TEST

GLfloat lightOnePosition[] = {40.0, 40, 100.0, 0.0};
GLfloat lightOneColor[] = {0.99, 0.99, 0.99, 1.0};

GLfloat lightTwoPosition[] = {-40.0, 40, 100.0, 0.0};
GLfloat lightTwoColor[] = {0.99, 0.99, 0.99, 1.0};

static bool removeIfNull( ofxBulletBaseShape* bs ) {
    return bs == NULL;
}

void testApp::setup(){
    
    /*ofxqcar*/
	ofBackground(0);
    ofSetOrientation(OF_ORIENTATION_DEFAULT);\
    touchPoint.x = touchPoint.y = -1;
    scaleExtTrack = 3;

    ofxQCAR * qcar = ofxQCAR::getInstance();
    qcar->addTarget("blocks2.xml", "blocks2.xml");
    qcar->setMaxNumOfMarkers(7);
    
    qcar->autoFocusOn();
    qcar->setCameraPixelsFlag(true);
    qcar->setup();
    
    
    /*assimpmodel*/
    model_outline.loadImage("gear/gear_outline.png");
    
    ofDisableArbTex(); // we need GL_TEXTURE_2D for our models coords.
    ofEnableDepthTest();
    
    glShadeModel(GL_SMOOTH);
    ofPoint modelPosition(0, 0, 0);
    ofEnableSeparateSpecularLight();
    model.loadModel("gear/gear.3ds");
    model.setPosition(modelPosition.x, modelPosition.y, modelPosition.z);
    ofDisableSeparateSpecularLight();
    
    
    /*ofxbullet*/
    ofSetFrameRate(60);
    ofSetVerticalSync(true);
    
    world.setup();
    world.enableDebugDraw();
    world.setGravity(ofVec3f(0,10000,0));
    
    for(int i=0; i<7; i++){
        box[i] = NULL;
    }
    
#ifndef RAMP_TEST
    box[3] = new ofxBulletBox();
    box[3]->create(world.world, ofVec3f(0, -245, 0), 1.0, 490, 490, 490);
    box[3]->add();
#endif
    
    ground.create( world.world, ofVec3f(0., 0, 0.), 0., 10000.f, 10.f, 10000.f );
    ground.setProperties(.25, .95);
    ground.add();
    
    
    //communication
    receiver.setup(7777);
    cnt_explode = -1;
    
    which_block= 0;
}

//--------------------------------------------------------------
void testApp::update(){
    ofxQCAR::getInstance()->update();
    model.update();
    world.update();
    
    while(receiver.hasWaitingMessages()){
        // get the next message
        ofxOscMessage m;
        receiver.getNextMessage(&m);
        
        if(m.getAddress() == "/fourth"){
            float f = 0.5;
            
            float f0, f1, f2;
                f0 = m.getArgAsFloat(0);
                f1 = m.getArgAsFloat(1);
                f2 = m.getArgAsFloat(2);
            
            rot[0] = rot[0]*f +(1-f)*f0;
            rot[1] = rot[1]*f +(1-f)*f1;
            rot[2] = rot[2]*f +(1-f)*f2;
            gyro[0] = gyro[0]*f +(1-f)*m.getArgAsFloat(3);
            gyro[1] = gyro[1]*f +(1-f)*m.getArgAsFloat(4);
            gyro[2] = gyro[2]*f +(1-f)*m.getArgAsFloat(5);
            
#ifdef RAMP_TEST
            if(rot[2]<60.f){
                if(fabs(world.getGravity().y) >10 )
                    world.setGravity(ofVec3f(0, 0, 5000*cos(DEG_TO_RAD*rot[2])));
            }
            else if( fabs(world.getGravity().z) >10 )
                world.setGravity(ofVec3f(0, 10000, 0));
                
            cout<<world.getGravity()<<endl;
#endif
        }
        else if(m.getAddress() == "/fourth_put"){
            
            btTransform tr;
            tr.setOrigin(btVector3(cx21, -245+cy21, cz21));
            tr.setRotation(btQuaternion(btVector3(0,1,0), (DEG_TO_RAD)*q21.getEuler().y));
            
            
            if(box[0] == NULL){
                box[0] = new ofxBulletBox();
                box[0]->create(world.world, tr, .05, 490, 490, 490);
                box[0]->add();
            }
            else if(box[4]==NULL){
                box[4] = new ofxBulletBox();
                box[4]->create(world.world, tr, .05, 490, 490, 490);
                box[4]->add();
            }
            else if(box[6]==NULL){
                box[6] = new ofxBulletBox();
                box[6]->create(world.world, tr, .05, 490, 490, 490);
                box[6]->add();
            }
            else if(box[1]==NULL){
                box[1] = new ofxBulletBox();
                box[1]->create(world.world, tr, .05, 490, 490, 490);
                box[1]->add();
            }
            else{
                cnt_explode = 100;
            }
        }
        else if(m.getAddress() == "/fourth_ramp_put"){
            
            if(box[3]==NULL){
                box[3] = new ofxBulletBox();
                box[3]->create(world.world, ofVec3f(0, -245, 0), 1.0, 490, 490, 490);
                box[3]->add();
            }
        }
        else if(m.getAddress() == "/fourth_select"){
            
            which_block++;
        }
    }
    if(cnt_explode>0){
        cnt_explode--;
    }
    else if (cnt_explode==0){
        
        box[0]->remove();
        delete box[0];
        box[0] = NULL;
        
        cnt_explode=-1;
    }
}

//--------------------------------------------------------------
void testApp::draw(){
    
    ofxQCAR * qcar = ofxQCAR::getInstance();
    qcar->draw();
    
    bool bPressed;
    bPressed = touchPoint.x >= 0 && touchPoint.y >= 0;
    
    for(int i = 0; i<qcar->numOfMarkersFound(); i++) {

        ofDisableDepthTest();
        ofEnableBlendMode(OF_BLENDMODE_ALPHA);
        
        bool bInside = false;
        if(bPressed) {
            vector<ofPoint> markerPoly;
            markerPoly.push_back(qcar->getMarkerCorner((ofxQCAR_MarkerCorner)0, i));
            markerPoly.push_back(qcar->getMarkerCorner((ofxQCAR_MarkerCorner)1, i));
            markerPoly.push_back(qcar->getMarkerCorner((ofxQCAR_MarkerCorner)2, i));
            markerPoly.push_back(qcar->getMarkerCorner((ofxQCAR_MarkerCorner)3, i));
            bInside = ofInsidePoly(touchPoint, markerPoly);
        }
        
        
        qcar->begin(i);
        if(qcar->getMarkerName(i) == "wood"){
            /*
            //box outline
            ofSetColor(ofColor::gray);
            ofSetLineWidth(3);
            ofLine(-480, -340, 480, -340);
            ofLine(480, -340, 480, 340);
            ofLine(480, 340, -480, 340);
            ofLine(-480, 340, -480, -340);
            
            ofLine(-480, -340, -40, 480, -340, -40);
            ofLine(480, -340, -40, 480, 340, -40);
            ofLine(480, 340, -40, -480, 340, -40);
            ofLine(-480, 340, -40, -480, -340, -40);
            
            ofLine(-480, -340, 0, -480, -340, -40);
            ofLine(480, -340, 0, 480, -340, -40);
            ofLine(480, 340, 0, 480, 340, -40);
            ofLine(-480, 340, 0, -480, 340, -40);
            ofSetLineWidth(1);
            
            //model outline
            ofPushMatrix();
            ofSetColor(255, 255, 255, 100);
            model_outline.draw(0 - 156, 0 - 156, 312, 312);
            ofPopMatrix();
            
            //model outline 3d
            ofPushMatrix();
            ofTranslate(model.getPosition().x, model.getPosition().y, 0);
            ofRotate(90, 1, 0, 0);
            ofTranslate(-model.getPosition().x, -model.getPosition().y, 0);
            ofSetColor(255, 255, 255, 100);
            model.drawFaces();
            ofPopMatrix();
             */
        }
        
        else if(qcar->getMarkerName(i) == "t"){
            ofPushMatrix();
            
            //simulated model
            ofTranslate(0, 0, -250);
            
            /*
            //world cooordinate
            ofSetLineWidth(2);
            ofSetColor(ofColor::white);
            ofLine(0,0,400,0);
            ofSetColor(ofColor::white);
            ofLine(0,0,0,400);
            ofSetColor(ofColor::white);
            ofLine(0,0,0,0,0,400);
            */
            
            ofPushMatrix();
            ofRotate(-rot[0]+90, 0, 0, 1);
            ofRotate(rot[1], 1, 0, 0);
            ofRotate(rot[2]-90, 0, 1, 0);
            
            //rotation
            ofSetLineWidth(5);
            ofSetColor(ofColor::red);
            ofLine(0,0,600,0);
            ofPopMatrix();
            
            ofSetColor(0, 255, 0);
            ofLine(600, 0, 0, 600, 0, gyro[0]);
            ofLine(-600, 0, 0, -600, 0, -gyro[0]);
            ofLine(0, 600, 0, 0, 600, -gyro[1]);
            ofLine(0, -600, 0, 0, -600, +gyro[1]);
            
            ofSetColor(255, 255, 255);
            ofNoFill();
            ofSetLineWidth(1);
            ofCircle(0, 0, 600);
            ofFill();
            ofSetLineWidth(1);
            ofPopMatrix();
            
            
            
            
            ofPushMatrix();
            
            //simulated model
            ofTranslate(0, 250, -250);
            glEnable( GL_DEPTH_TEST );
            ofSetColor(0, 255, 0, 150);
            if(box[3]!=NULL)box[3]->draw();
            
            //world cooordinate
            ofSetLineWidth(5);
            ofSetColor(ofColor::red);
            ofLine(0,0,600,0);
            ofSetColor(ofColor::green);
            ofLine(0,0,0,600);
            ofSetColor(ofColor::blue);
            ofLine(0,0,0,0,0,600);
            ofSetColor(255, 255, 255);
            ofSetLineWidth(1);
            
            ofPopMatrix();
            
            
            
        }

        else{
            //box outline
            ofSetColor(ofColor::gray);
            ofSetLineWidth(3);
            ofLine(-250, -250, 250, -250);
            ofLine(250, -250, 250, 250);
            ofLine(250, 250, -250, 250);
            ofLine(-250, 250, -250, -250);
            
            ofLine(-250, -250, -500, 250, -250, -500);
            ofLine(250, -250, -500, 250, 250, -500);
            ofLine(250, 250, -500, -250, 250, -500);
            ofLine(-250, 250, -500, -250, -250, -500);
            
            ofLine(-250, -250, 0, -250, -250, -500);
            ofLine(250, -250, 0, 250, -250, -500);
            ofLine(250, 250, 0, 250, 250, -500);
            ofLine(-250, 250, 0, -250, 250, -500);
            
            //anchor box(3)
            if(qcar->getMarkerName(i)=="3"){
                /*
                //axes
                ofSetLineWidth(1);
                ofSetColor(ofColor::red);
                ofLine(0,0,300,0);
                ofSetColor(ofColor::green);
                ofLine(0,0,0,300);
                ofSetColor(ofColor::blue);
                ofLine(0,0,0,0,0,300);
                ofSetColor(255, 255, 255);
                */
                ofPushMatrix();
                
                //simulated model
                ofTranslate(0, 250, -250);
                glEnable( GL_DEPTH_TEST );
//#define ABSTRACT_OVERTIME
                int b[5] = {3,0,4,6,1};
                for(int j=0; j<5; j++){
                    if(j<=which_block || which_block==0)
                        ofSetColor(0, 255, 0, 150);
                    else
                        ofSetColor(255, 150, 0, 150);
                    if(box[b[j]] != NULL){
                        box[b[j]]->draw();
                    }
                }
#ifdef ABSTRACT_OVERTIME
                for(int j=0; j<7; j++){
                    if(j<2)
                        ofSetColor(0, 255, 0, 150);
                    else
                        ofSetColor(255, 0, 0, 150);
                    if(box[j] != NULL){
                        box[j]->draw();
                    }
                }
#endif
#ifdef ABSTRACT_OVERDECISION
                for(int j=0; j<7; j++){
                    if(j<2)
                        ofSetColor(0, 255, 0, 150);
                    else
                        ofSetColor(255, 0, 0, 150);
                    if(box[j] != NULL){
                        box[j]->draw();
                    }
                }
#endif
#ifdef REALTIME_SIM
                ofSetColor(0, 255, 0, 150);
                for(int j=0; j<7; j++){
                    if(box[j] != NULL){
                        box[j]->draw();
                    }
                }
#endif
                
                //world cooordinate
                ofSetLineWidth(5);
                ofSetColor(ofColor::red);
                ofLine(0,0,600,0);
                ofSetColor(ofColor::green);
                ofLine(0,0,0,600);
                ofSetColor(ofColor::blue);
                ofLine(0,0,0,0,0,600);
                ofSetColor(255, 255, 255);
                ofSetLineWidth(1);
                
                ofPopMatrix();
            }
            else if( (qcar->getMarkerName(i) == "0" && box[0]==NULL) ||
                   (qcar->getMarkerName(i) == "4" && box[4]==NULL)  ||
                   (qcar->getMarkerName(i) == "6" && box[6]==NULL)  ||
                   (qcar->getMarkerName(i) == "1" && box[1]==NULL)
                   )
                {
                    ofSetLineWidth(2);
                    ofSetColor(ofColor::red);
                    ofLine(0,0,300,0);
                    ofSetColor(ofColor::green);
                    ofLine(0,0,0,300);
                    ofSetColor(ofColor::blue);
                    ofLine(0,0,0,0,0,300);
                    ofSetColor(255, 255, 255);
                    ofSetLineWidth(1);
                    
                }
        }
        if(qcar->getMarkerName(i) == "3"){
            for(int j =0; j< qcar->numOfMarkersFound(); j++) {
                
                if( (qcar->getMarkerName(j) == "0" && box[0]==NULL) ||
                    (qcar->getMarkerName(j) == "4" && box[4]==NULL)  ||
                    (qcar->getMarkerName(j) == "6" && box[6]==NULL)  ||
                    (qcar->getMarkerName(j) == "1" && box[1]==NULL)
                    )
                {
                    //get translation
                    float x1r = qcar->getMarker(i).poseMatrixData[3];
                    float y1r = qcar->getMarker(i).poseMatrixData[7];
                    float z1r = qcar->getMarker(i).poseMatrixData[11];
                    
                    float x2r = qcar->getMarker(j).poseMatrixData[3];
                    float y2r = qcar->getMarker(j).poseMatrixData[7];
                    float z2r = qcar->getMarker(j).poseMatrixData[11];
                    
                    cx21 =  (x2r-x1r)*qcar->getMarker(i).poseMatrixData[0]
                    + (y2r-y1r)*qcar->getMarker(i).poseMatrixData[4]
                    + (z2r-z1r)*qcar->getMarker(i).poseMatrixData[8];
                    cy21 =  (x2r-x1r)*qcar->getMarker(i).poseMatrixData[1]
                    + (y2r-y1r)*qcar->getMarker(i).poseMatrixData[5]
                    + (z2r-z1r)*qcar->getMarker(i).poseMatrixData[9];
                    cz21 =  (x2r-x1r)*qcar->getMarker(i).poseMatrixData[2]
                    + (y2r-y1r)*qcar->getMarker(i).poseMatrixData[6]
                    + (z2r-z1r)*qcar->getMarker(i).poseMatrixData[10];
                    
                    //get rotation
                    ofQuaternion q1 = qcar->getMarker(i).modelViewMatrix.getRotate();
                    ofQuaternion q2 = qcar->getMarker(j).modelViewMatrix.getRotate();
                    q21 = q2/q1;
                    
                    //refine x,y
                    cx21 -= 250*sin(DEG_TO_RAD*q21.getEuler().y);
                    cz21 -= 250*(cos(DEG_TO_RAD*q21.getEuler().y)-1);
                    
                    
                    cout<<"- pp("<<cx21<<" "<<cy21<<" "<<cz21<<")"<<endl;
                    cout<<q21.getEuler().x<<" "<<q21.getEuler().y<<" "<<q21.getEuler().z<<endl;
                    cout<<ground.getRotationQuat().getEuler().x<<" "<<ground.getRotationQuat().getEuler().y<<" "<<ground.getRotationQuat().getEuler().z<<endl;
                }
            }
        }
        
        qcar->end();
    }
    
    ofDisableDepthTest();
    
    /**
     *  access to camera pixels.
     */
    ofSetColor(255);
    int cameraW = qcar->getCameraWidth();
    int cameraH = qcar->getCameraHeight();
    unsigned char * cameraPixels = qcar->getCameraPixels();
    if(cameraW > 0 && cameraH > 0 && cameraPixels != NULL) {
        if(cameraImage.isAllocated() == false ) {
            cameraImage.allocate(cameraW, cameraH, OF_IMAGE_GRAYSCALE);
        }
        cameraImage.setFromPixels(cameraPixels, cameraW, cameraH, OF_IMAGE_GRAYSCALE);
        if(qcar->getOrientation() == OFX_QCAR_ORIENTATION_PORTRAIT) {
            cameraImage.rotate90(1);
        } else if(qcar->getOrientation() == OFX_QCAR_ORIENTATION_LANDSCAPE) {
            cameraImage.mirror(true, true);
        }

        cameraW = cameraImage.getWidth() * 0.5;
        cameraH = cameraImage.getHeight() * 0.5;
        int cameraX = 0;
        int cameraY = ofGetHeight() - cameraH;
        cameraImage.draw(cameraX, cameraY, cameraW, cameraH);
        
        ofPushStyle();
        ofSetColor(ofColor::white);
        ofNoFill();
        ofSetLineWidth(3);
        ofRect(cameraX, cameraY, cameraW, cameraH);
        ofPopStyle();
    }
}

//--------------------------------------------------------------
void testApp::exit(){
    ofxQCAR::getInstance()->exit();
}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs & touch){
    touchPoint.set(touch.x, touch.y);
     ofxQCAR * qcar = ofxQCAR::getInstance();
    scaleExtTrack=20;
      qcar->startExtendedTracking();

}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs & touch){
    touchPoint.set(touch.x, touch.y);
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs & touch){
    touchPoint.set(-1, -1);
    ofxQCAR * qcar = ofxQCAR::getInstance();
    scaleExtTrack=3;
    qcar->stopExtendedTracking();
}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::lostFocus(){

}

//--------------------------------------------------------------
void testApp::gotFocus(){

}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){

}

