 
package com.company.assembleegameclient.objects.particles {
import com.company.assembleegameclient.objects.GameObject;
import com.company.assembleegameclient.util.TextureRedrawer;
import com.company.util.AssetLibrary;
import com.company.util.ImageSet;

import flash.display.BitmapData;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.utils.Timer;

public class SpritesProjectEffect extends ParticleEffect {
      
      public static var images:Vector.<BitmapData>;
       
      
      public var start_:Point;
      
      public var end_:Point;
      
      public var objectId:uint;
      
      public var go:GameObject;
      
      private var innerRadius:Number;
      
      private var outerRadius:Number;
      
      private var radians:Number;
      
      private var particleScale:uint;
      
      private var timer:Timer;
      
      private var isDestroyed:Boolean = false;
      
      public function SpritesProjectEffect(param1:GameObject, param2:Number) {
         super();
         this.go = param1;
         if(param1.texture.height == 8) {
            this.innerRadius = 0;
            this.outerRadius = param2;
            this.particleScale = 50;
         } else {
            this.innerRadius = 0;
            this.outerRadius = param2;
            this.particleScale = 80;
         }
      }
      
      private function parseBitmapDataFromImageSet() : void {
         var _local1:uint = 0;
         images = new Vector.<BitmapData>();
         var _local3:ImageSet = AssetLibrary.getImageSet("lofiparticlesMusicNotes");
         var _local2:uint = 9;
         _local1 = 0;
         while(_local1 < _local2) {
            images.push(TextureRedrawer.redraw(_local3.images[_local1],this.particleScale,true,0xffcf40,true));
            _local1++;
         }
      }
      
      override public function update(param1:int, param2:int) : Boolean {
         if(this.isDestroyed) {
            return false;
         }
         if(!this.timer) {
            this.initialize();
         }
         x_ = this.go.x_;
         y_ = this.go.y_;
         return true;
      }
      
      private function initialize() : void {
         this.timer = new Timer(50,1);
         this.timer.addEventListener("timer",this.onTimer);
         this.timer.addEventListener("timerComplete",this.onTimerComplete);
         this.timer.start();
         this.parseBitmapDataFromImageSet();
      }
      
      private function onTimer(param1:TimerEvent) : void {
         var _local2:int = 0;
         var _local3:int = 0;
         if(map_) {
            _local2 = 8 + this.outerRadius * 2;
            _local3 = 0;
            while(_local3 < _local2) {
               this.radians = _local3 * 2 * 3.14159265358979 / _local2;
               this.start_ = new Point(this.go.x_ + Math.sin(this.radians) * this.innerRadius,this.go.y_ + Math.cos(this.radians) * this.innerRadius);
               this.end_ = new Point(this.go.x_ + Math.sin(this.radians) * this.outerRadius,this.go.y_ + Math.cos(this.radians) * this.outerRadius);
               map_.addObj(new NoteParticle(this.objectId,20,this.particleScale,this.start_,this.end_,this.radians,this.go,images),this.start_.x,this.start_.y);
               _local3++;
            }
         }
      }
      
      private function onTimerComplete(param1:TimerEvent) : void {
         this.destroy();
      }
      
      public function destroy() : void {
         if(this.timer) {
            this.timer.removeEventListener("timer",this.onTimer);
            this.timer.removeEventListener("timer",this.onTimerComplete);
            this.timer.stop();
            this.timer = null;
         }
         this.go = null;
         this.isDestroyed = true;
      }
      
      override public function removeFromMap() : void {
         this.destroy();
         super.removeFromMap();
      }
   }
}
