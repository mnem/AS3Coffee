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
    import fl.motion.easing.Sine;

    import com.flashdynamix.motion.TweensyZero;

    import flash.display.Sprite;
    import flash.events.Event;

    public class BeansNode extends SequenceNode
    {
        protected static const LIFE:Number = 3;
        protected var beans:Vector.<Sprite>;

        public function BeansNode(quantity:int = 20):void
        {
            super(LIFE);

            beans = new Vector.<Sprite>();

            for(var i:int = 0; i < quantity; i++)
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
                beans[i].y = -beans[i].height * 2;

                _canvas.addChild(beans[i]);
                // Ph34r my line length
                var time:Number = (LIFE / 4) + (LIFE/4 * 4 * Math.random());
                TweensyZero.to(beans[i], {y:_canvas.stage.stageHeight + 50, rotation:720*Math.random()}, time, Sine.easeIn);
            }
        }
    }
}
