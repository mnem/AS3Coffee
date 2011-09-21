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
    import nah.sequence.BeansNode;
    import nah.sequence.BrewNode;
    import nah.sequence.FireNode;
    import nah.sequence.PourShotsNode;
    import nah.sequence.SequenceNode;
    import nah.sequence.TextNode;
    import nah.sequence.WaterNode;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;

    /**
     * Let's brew some coffee!
     */
    [SWF(backgroundColor="#FFFFFF", frameRate="24", width="512", height="512")]
    public class Barista extends Sprite
    {
        protected var firstSlide:SequenceNode;

        public function Barista():void
        {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            setupSlides();
            stage.addChild(firstSlide.canvas);
            firstSlide.start();
        }

        protected function setupSlides():void
        {
            firstSlide = new TextNode("Coffee...", TextNode.HORIZONTAL_ALIGN_LEFT, TextNode.VERTICAL_ALIGN_TOP);

            firstSlide.setNext(new TextNode("...is LIFE", TextNode.HORIZONTAL_ALIGN_RIGHT, TextNode.VERTICAL_ALIGN_MIDDLE))
                .setNext(new TextNode("How to make:", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM))
                .setNext(new TextNode("take beans", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM))
                .setNext(new BeansNode())
                .setNext(new TextNode("some water", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM))
                .setNext(new WaterNode())
                .setNext(new TextNode("(but not frozen)", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM))
                .setNext(new TextNode("some fire", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM))
                .setNext(new FireNode())
                .setNext(new TextNode("brew", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_BOTTOM))
                .setNext(new BrewNode())
                .setNext(new PourShotsNode())
                .setNext(new TextNode("imbibe.", TextNode.HORIZONTAL_ALIGN_CENTER, TextNode.VERTICAL_ALIGN_MIDDLE, 0xF6CE30))
                .setTransitionTimes(0, 3);
        }
    }
}

