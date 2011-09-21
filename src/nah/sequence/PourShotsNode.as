/**
 * (c) Copyright 2011 David Wagner.
 *
 * Complain/commend: http://noiseandheat.com/
 *
 *
 * Licensed under the MIT license:
 *
 *     http://www.opensource.org/licenses/mit-license.php
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
package nah.sequence
{
    import com.flashdynamix.motion.TweensyZero;
    import fl.motion.easing.Quadratic;
    import flash.display.Bitmap;
    import flash.display.PixelSnapping;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import nah.liquid.Liquid;
    import nah.things.Throbber;




    public class PourShotsNode extends SequenceNode
    {
        protected var liquid:Liquid;
        protected var espresso:int = 0;
        protected var shots:Vector.<Throbber>;
        protected var text:TextNode;

        public function PourShotsNode()
        {
            super(2);

            shots = new Vector.<Throbber>(3, true);
            for (var i:int = 0; i < shots.length; i++)
            {
                shots[i] = new Throbber();
            }

            text = new TextNode("Pour...", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM, 0x431d00);
        }

        override protected function startLifeTimer():void
        {
            // We have to be manually terminated
        }

        protected function setupCup():void
        {
            liquid = new Liquid();

            var cup:Bitmap = new Bitmap(liquid.photo, PixelSnapping.NEVER, true);
            cup.scaleX = _canvas.stage.stageWidth / liquid.photo.width;
            cup.scaleY = cup.scaleX;
            cup.x = (_canvas.stage.stageWidth - cup.width) / 2;
            cup.y = (_canvas.stage.stageHeight - cup.height) / 2;
            _canvas.addChild(cup);

            _canvas.addEventListener(Event.ENTER_FRAME, enterFrame, false, 0, true);
        }

        protected function setupShots():void
        {
            var step:Number = _canvas.stage.stageWidth / (shots.length + 1);
            for (var i:int = 0; i < shots.length; i++)
            {
                shots[i].x = step * (i + 1);
                shots[i].y = -shots[i].height;
                _canvas.addChild(shots[i]);

                TweensyZero.to(shots[i], {y:shots[i].height * 1.5}, 0.5, Quadratic.easeOut);
            }
            updateThrobbing();
        }

        protected function updateThrobbing():void
        {
            var i:int;
            if (espresso > 0)
            {
                for (i = 0; i < shots.length; i++)
                {
                    shots[i].throbbing = false;
                }
            }
            else
            {
                // Start the first visible one throbbing
                for (i = 0; i < shots.length; i++)
                {
                    if (shots[i].visible)
                    {
                        if (!shots[i].throbbing)
                        {
                            shots[i].throbbing = true;
                            if (!shots[i].hasEventListener(MouseEvent.CLICK))
                            {
                                shots[i].addEventListener(MouseEvent.CLICK, pour);
                                shots[i].buttonMode = true;
                            }
                        }
                        return;
                    }
                }
                // None visible, next state
                super.startLifeTimer();

                // Cheat and make the stage brown so the next fade works
                // better
                var text:TextNode = new TextNode("", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_MIDDLE, 0xF6CE30, 0xff431d00);
                text.canvas.visible = true;
                _canvas.stage.addChildAt(text.canvas, 0);
            }
        }

        override protected function onAddedToStage(event:Event):void
        {
            setupCup();
            text.canvas.visible = true;
            _canvas.addChild(text.canvas);
            setupShots();
        }

        protected function enterFrame(event:Event):void
        {
            if (espresso > 0)
            {
                espresso--;
                if (espresso & 1)
                {
                    liquid.addCoffeeAt(43 + Math.random() * 15, 3 + Math.random() * 5, 10);
                    liquid.addCoffeeAt(43 + Math.random() * 15, 3 + Math.random() * 5, 10);
                    liquid.addCoffeeAt(43 + Math.random() * 15, 3 + Math.random() * 5, 10);
                    liquid.addCoffeeAt(43 + Math.random() * 15, 3 + Math.random() * 5, 10);
                    liquid.addCoffeeAt(43 + Math.random() * 15, 3 + Math.random() * 5, 10);
                }

                if (espresso == 0)
                {
                    updateThrobbing();
                }
            }

            liquid.update();
            liquid.snapshot();
        }

        protected function pour(event:MouseEvent):void
        {
            if (espresso <= 0)
            {
                var t:Throbber = Throbber(event.target);
                t.throbbing = false;
                t.removeEventListener(MouseEvent.CLICK, pour);
                espresso = 120;
                updateThrobbing();
                TweensyZero.to(t, {y:-t.height}, 0.5, null, 0, null, function():void
                {
                    t.visible = false;
                    t.parent.removeChild(t);
                });
            }
        }
    }
}
