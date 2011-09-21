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
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;

    /**
     * Basic bit of a sequence
     */
    public class SequenceNode
    {
        protected var _next:SequenceNode;
        protected var _canvas:Sprite;
        protected var lifeTimer:Timer;

        public function SequenceNode(lifeSpan:Number = 1):void
        {
            this._next = next;
            _canvas = new Sprite();
            _canvas.visible = false;
            _canvas.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
            _canvas.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage, false, 0, true);

            lifeTimer = new Timer(1000 * lifeSpan, 0);
            lifeTimer.addEventListener(TimerEvent.TIMER, onLifeTimer, false, 0, true);
        }

        protected function onLifeTimer(event:TimerEvent):void
        {
            lifeTimer.stop();
            finished();
        }

        protected function onAddedToStage(event:Event):void
        {
        }

        protected function onRemovedFromStage(event:Event):void
        {
        }

        public function start(previous:SequenceNode = null):void
        {
            trace("< Stopping " + previous == null ? "null" : previous);
            trace("> Starting " + this);

            _canvas.alpha = 0;
            _canvas.visible = true;

            if(previous != null)
            {
                if(previous.canvas.parent == null)
                {
                    throw new Error("The previous sequence wasn't attached to the stage. I don't know what to do. I'm lost. Help. Help.");
                }

                previous.canvas.parent.addChild(_canvas);
                TweensyZero.to(previous.canvas, {alpha:0}, 0.5, null, 0, null, function():void {previous.canvas.parent.removeChild(previous.canvas);});
            }

            TweensyZero.to(_canvas, {alpha:1}, 0.5, null, 0, null, lifeTimer.start);
        }

        protected function finished():void
        {
            if (_next != null)
            {
                _next.start(this);
            }
        }

        public function get canvas():Sprite
        {
            return _canvas;
        }

        public function get next():SequenceNode
        {
            return _next;
        }

        public function setNext(next:SequenceNode):SequenceNode
        {
            _next = next;
            return _next;
        }
    }
}
