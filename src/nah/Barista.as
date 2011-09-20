package nah
{
    import flash.events.MouseEvent;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.PixelSnapping;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.utils.getTimer;

    /**
     * Let's brew some coffee!
     */
    [SWF(backgroundColor="#FFFFFF", frameRate="30", width="512", height="512")]
    public class Barista extends Sprite
    {
        protected var liquid:Liquid;
        protected var cup:Bitmap;
        //
        protected var lastFrame:int;
        protected var frameTimeAcc:int;
        protected var frameTimeAccCount:int;

        public function Barista():void
        {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            liquid = new Liquid();

            cup = getCupFor(liquid.photo);

            cup.x = (stage.stageWidth - cup.width) / 2;
            cup.y = (stage.stageHeight - cup.height) / 2;

            addChild(cup);

            lastFrame = getTimer();

            addEventListener(Event.ENTER_FRAME, update);

            stage.addEventListener(MouseEvent.MOUSE_DOWN, mousedown);
            stage.addEventListener(MouseEvent.MOUSE_UP, mouseup);
        }

        protected function mousedown(event:MouseEvent):void
        {
            stage.addEventListener(MouseEvent.MOUSE_MOVE, mousemove);
        }

        protected function mouseup(event:MouseEvent):void
        {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, mousemove);
        }

        private function mousemove(event:MouseEvent):void
        {
            var x:int = event.stageX / stage.stageWidth * 63;
            var y:int = event.stageY / stage.stageHeight * 63;

            if(x < 0) x = 0;
            if(x > 63) x = 63;
            if(y < 0) x = 0;
            if(y > 63) x = 63;

            var i:int = x + 64 * y;

            trace(i);

            liquid.dens_prev[i] = 10;
        }

        protected function updateFPS():void
        {
            var now:int = getTimer();
            frameTimeAcc += now - lastFrame;
            lastFrame = now;

            if(++frameTimeAccCount > 60)
            {
                var fps:Number = 1000/(frameTimeAcc/frameTimeAccCount);
                trace("FPS: " + int(fps));
                frameTimeAcc = 0;
                frameTimeAccCount = 0;
            }
        }

        protected function update(event:Event):void
        {
            updateFPS();

            liquid.update();
            liquid.snapshot();
        }

        protected function getCupFor(coffee:BitmapData):Bitmap
        {
            var bitmap:Bitmap = new Bitmap(coffee, PixelSnapping.NEVER, true);
            bitmap.scaleX = int(stage.stageWidth / coffee.width);
            bitmap.scaleY = bitmap.scaleX;
            return bitmap;
        }
    } // End of class
} // End of package

