package nah.sequence
{
    import fl.motion.easing.Sine;

    import com.flashdynamix.motion.TweensyZero;

    import flash.display.Sprite;
    import flash.events.Event;

    /**
     * @author mnem
     */
    public class BeansNode extends SequenceNode
    {
        protected static const LIFE:Number = 3;
        protected var beans:Vector.<Sprite>;

        public function BeansNode()
        {
            super(LIFE);

            beans = new Vector.<Sprite>();

            for(var i:int = 0; i < 20; i++)
            {
                beans.push(makeBean());
            }
        }

        protected function makeBean():Sprite
        {
            var bean:Sprite = new Sprite();

            bean.graphics.beginFill(0x452B11);
            bean.graphics.drawEllipse(-25, -15, 50, 30);
            bean.graphics.endFill();

            bean.graphics.beginFill(0xD18234);
            bean.graphics.drawEllipse(-25, -4, 50, 8);
            bean.graphics.endFill();

            return bean;
        }

        override protected function onAddedToStage(event:Event):void
        {
            var step:Number = (_canvas.stage.stageWidth - 128) / beans.length;
            for(var i:int = 0; i < beans.length; i++)
            {
                beans[i].x = 64 + i * step;
                beans[i].y = 0;

                _canvas.addChild(beans[i]);
                // Ph34r my line length
                var time:Number = (LIFE / 4) + (LIFE/4 * 4 * Math.random());
                TweensyZero.to(beans[i], {y:_canvas.stage.stageHeight + 50, rotation:720*Math.random()}, time, Sine.easeIn);
            }
        }
    }
}
