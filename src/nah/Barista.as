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
package nah
{
    import nah.liquid.Liquid;
    import nah.sequence.BeansNode;
    import nah.sequence.SequenceNode;
    import nah.sequence.TextNode;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.PixelSnapping;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.utils.getTimer;

    /**
     * Let's brew some coffee!
     */
    [SWF(backgroundColor="#FFFFFF", frameRate="24", width="512", height="512")]
    public class Barista extends Sprite
    {
        protected var liquid:Liquid;
        protected var cup:Bitmap;
        //
        protected var lastFrame:int;
        protected var frameTimeAcc:int;
        protected var frameTimeAccCount:int;
        protected var espresso:int = 0;
        //
        protected var firstSlide:SequenceNode;

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

            // pour();
            stage.addEventListener(MouseEvent.CLICK, click);

            setupSlides();
            stage.addChild(firstSlide.canvas);
            firstSlide.start();
        }

        protected function setupSlides():void
        {
            firstSlide = new TextNode("Coffee...", TextNode.HORIZONTAL_ALIGN_LEFT, TextNode.VERTICAL_ALIGN_TOP);

            firstSlide.setNext(new TextNode("...LIFE", TextNode.HORIZONTAL_ALIGN_RIGHT, TextNode.VERTICAL_ALIGN_MIDDLE))
                .setNext(new TextNode("How to brew", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM))
                .setNext(new TextNode("Some beans", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM))
                .setNext(new BeansNode())
                .setNext(new TextNode("MC", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_MIDDLE))
                .setNext(new TextNode("BC", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM))
                .setNext(new TextNode("TR", TextNode.HORIZONTAL_ALIGN_RIGHT, TextNode.VERTICAL_ALIGN_TOP))
                .setNext(new TextNode("MR", TextNode.HORIZONTAL_ALIGN_RIGHT, TextNode.VERTICAL_ALIGN_MIDDLE))
                .setNext(new TextNode("BR", TextNode.HORIZONTAL_ALIGN_RIGHT, TextNode.VERTICAL_ALIGN_BOTTOM));
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

            if (++frameTimeAccCount > 60)
            {
                var fps:Number = 1000 / (frameTimeAcc / frameTimeAccCount);
                trace("FPS: " + int(fps));
                frameTimeAcc = 0;
                frameTimeAccCount = 0;
            }
        }

        protected function update(event:Event):void
        {
            updateFPS();

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
            if (espresso <= 0)
            {
                espresso = 90;
            }
        }
    }
    // End of class
} // End of package

