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
        protected var espresso:int = 0;

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

            pour();
            stage.addEventListener(MouseEvent.CLICK, click);
        }

        protected function click(event:MouseEvent):void
        {
            pour();
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

            if(espresso > 0)
            {
                espresso--;
                if(espresso & 1)
                {
                    liquid.addCoffeeAt(57, 3, 10);
                    liquid.addCoffeeAt(56, 4, 10);
                    liquid.addCoffeeAt(55, 5, 10);
                    liquid.addCoffeeAt(44, 6, 10);
                    liquid.addCoffeeAt(43, 7, 10);
                }
            }

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

        public function pour():void
        {
            if(espresso <= 0)
            {
               espresso = 90;
            }
        }
    } // End of class
} // End of package

