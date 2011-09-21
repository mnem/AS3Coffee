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
    import flash.events.Event;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class TextNode extends SequenceNode
    {
        private static const GUTTER:int = 17;
        //
        public static const HORIZONTAL_ALIGN_LEFT:int = 0;
        public static const HORIZONTAL_ALIGN_CENTER:int = 1;
        public static const HORIZONTAL_ALIGN_RIGHT:int = 2;
        //
        public static const VERTICAL_ALIGN_TOP:int = 0;
        public static const VERTICAL_ALIGN_MIDDLE:int = 1;
        public static const VERTICAL_ALIGN_BOTTOM:int = 2;
        //
        protected var field:TextField;
        protected var horizontalAlign:int;
        protected var verticalAlign:int;
        protected var colour:uint;
        protected var backgroundColour:uint;

        public function TextNode(text:String, horizontalAlign:int, verticalAlign:int, colour:uint = 0x454242, backgroundColour:uint = 0xffffff):void
        {
            super(2);

            this.horizontalAlign = horizontalAlign;
            this.verticalAlign = verticalAlign;
            this.colour = colour;
            this.backgroundColour = backgroundColour;

            field = createTextField();
            field.text = text;
            field.visible = false;
            _canvas.addChild(field);
        }

        override protected function onAddedToStage(event:Event):void
        {
            if(backgroundColour >> 24 & 0xff != 0)
            {
                _canvas.graphics.beginFill(backgroundColour, (backgroundColour >> 24 & 0xff) / 255);
                _canvas.graphics.drawRect(0, 0, _canvas.stage.stageWidth, _canvas.stage.stageHeight);
                _canvas.graphics.endFill();
            }

            switch(verticalAlign)
            {
                case VERTICAL_ALIGN_MIDDLE:
                    field.y = (_canvas.stage.stageHeight - field.textHeight)/2;
                    break;
                case VERTICAL_ALIGN_BOTTOM:
                    field.y = _canvas.stage.stageHeight - field.textHeight - GUTTER;
                    break;
                case VERTICAL_ALIGN_TOP:
                default:
                    field.y = GUTTER;
                    break;
            }

            switch(horizontalAlign)
            {
                case HORIZONTAL_ALIGN_CENTER:
                    field.x = (_canvas.stage.stageWidth - field.textWidth)/2;
                    break;
                case HORIZONTAL_ALIGN_RIGHT:
                    field.x = _canvas.stage.stageWidth - field.textWidth - GUTTER;
                    break;
                case HORIZONTAL_ALIGN_LEFT:
                default:
                    field.x = GUTTER;
                    break;
            }
            field.visible = true;
        }

        protected function createTextField():TextField
        {
            var field:TextField = new TextField();

            field.selectable = false;
            field.autoSize = TextFieldAutoSize.LEFT;

            var format:TextFormat = field.defaultTextFormat;
            format.font = "_serif";
            format.size = 72;
            format.bold = true;
            format.color = colour;

            field.defaultTextFormat = format;

            return field;
        }

        public function toString():String
        {
            return "[TextNode '" + field.text + "']";
        }
    }
}
