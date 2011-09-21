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
    import fl.motion.easing.Linear;
    import com.flashdynamix.motion.TweensyZero;

    import flash.display.Sprite;
    import flash.events.Event;

    public class BrewNode extends SequenceNode
    {
        protected var duration:Number = 5;
        protected var face:Sprite;
        protected var minutehand:Sprite;
        protected var secondhand:Sprite;

        public function BrewNode()
        {
            super(duration);

            face = new Sprite();
            face.graphics.lineStyle(5);
            face.graphics.beginFill(0xffffff);
            face.graphics.drawCircle(0, 0, 128);
            face.graphics.endFill();
            _canvas.addChild(face);

            minutehand = new Sprite();
            minutehand.graphics.lineStyle(3);
            minutehand.graphics.lineTo(0, -90);
            _canvas.addChild(minutehand);

            secondhand = new Sprite();
            secondhand.graphics.lineStyle(1, 0xff0000);
            secondhand.graphics.lineTo(0, -110);
            _canvas.addChild(secondhand);
        }

        override protected function onAddedToStage(event:Event):void
        {
            face.x = _canvas.stage.stageWidth / 2;
            face.y = _canvas.stage.stageHeight / 2;
            minutehand.x = face.x;
            minutehand.y = face.y;
            secondhand.x = face.x;
            secondhand.y = face.y;

            TweensyZero.to(minutehand, {rotation:360/60*duration}, duration, Linear.easeInOut);
            TweensyZero.to(secondhand, {rotation:360*duration}, duration, Linear.easeInOut);
        }
    }
}
