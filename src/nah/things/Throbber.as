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
package nah.things
{
    import fl.motion.easing.Quadratic;

    import com.flashdynamix.motion.TweensyZero;

    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class Throbber extends Sprite
    {
        protected var button:Sprite;
        protected var text:TextField;
        protected var _throbbing:Boolean = false;
        protected var throbCount:int;

        public function Throbber()
        {
            mouseChildren = false;

            button = createButton();

            addChild(button);

            text = new TextField();
            text.autoSize = TextFieldAutoSize.LEFT;
            text.wordWrap = false;
            text.selectable = false;
            var tf:TextFormat = text.defaultTextFormat;
            tf.font = "_sans";
            tf.size = 12;
            tf.color = 0x431d00;
            text.defaultTextFormat = tf;

            text.text = "PRESS";
            text.x = -text.textWidth / 2;
            text.y = -text.textHeight / 2;
            text.visible = false;

            addChild(text);
        }

        protected function createButton():Sprite
        {
            var b:Sprite = new Sprite();

            b.graphics.beginFill(0x6E5C15);
            b.graphics.drawCircle(-4, 4, 32);
            b.graphics.endFill();

            b.graphics.beginFill(0xF6CE30);
            b.graphics.drawCircle(0, 0, 32);
            b.graphics.endFill();

            return b;
        }

        protected function inflate():void
        {
            TweensyZero.to(button, {scaleX:1.2, scaleY:1.2}, 0.2, Quadratic.easeOut, 0, null, deflate);
            TweensyZero.to(text, {alpha:0.0}, 0.2, Quadratic.easeOut);
        }

        protected function deflate(repeat:Boolean = true):void
        {
            TweensyZero.to(button, {scaleX:1.0, scaleY:1.0}, 0.2, Quadratic.easeOut, 0, null, repeat ? inflate : null);
            TweensyZero.to(text, {alpha:1.0}, 0.2, Quadratic.easeOut);
            throbCount++;
            if(throbCount == 10)
            {
                text.visible = true;
            }
        }

        public function get throbbing():Boolean
        {
            return _throbbing;
        }

        public function set throbbing(throbbing:Boolean):void
        {
            if(throbbing == _throbbing)
            {
                return;
            }

            text.visible = false;
            throbCount = 0;
            _throbbing = throbbing;
            deflate(_throbbing);
        }
    }
}
