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
    import flash.display.Sprite;

    public class FireNode extends BeansNode
    {
        public function FireNode(quantity:int = 20):void
        {
            super(quantity);
        }

        override protected function makeBean():Sprite
        {
            var fire:Sprite = new Sprite();

            fire.graphics.beginFill(0xE10900, 0.75);
            fire.graphics.drawTriangles(Vector.<Number>([0, -30,  30, 30,  -30, 30]));
            fire.graphics.endFill();

            fire.graphics.beginFill(0xF9CD40, 0.75);
            fire.graphics.drawTriangles(Vector.<Number>([0, 0,  10, 30, - 10, 30]));
            fire.graphics.endFill();

            return fire;
        }
    }
}
