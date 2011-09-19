package nah
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.PixelSnapping;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;

    /**
     * Let's brew some coffee!
     *
     * All maths and physics merrily stolen from:
     *
     *    http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/GDC03.pdf
     */
    [SWF(backgroundColor="#FFFFFF", frameRate="31", width="512", height="512")]
    public class Barista extends Sprite
    {
        protected static const N:int = 62;
        protected static const SIZE:int = (N + 2) * (N + 2);
        //
        protected var u:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var v:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var u_prev:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var v_prev:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var dens:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var dens_prev:Vector.<Number> = new Vector.<Number>(SIZE, true);
        //
        protected var s:Vector.<Number> = new Vector.<Number>(SIZE, true);
        //
        protected var coffee:BitmapData;
        protected var cup:Bitmap;

        public function Barista():void
        {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            coffee = letThereBeUnformedCoffee();
            cup = getCupFor(coffee);

            cup.x = (stage.stageWidth - cup.width) / 2;
            cup.y = (stage.stageHeight - cup.height) / 2;

            addChild(cup);

            primeVector(u, function(k:int):Number
            {
                var length:Number = N + 2;
                var x:Number = k % length;

                return Math.sin(Math.PI * (x / length));
            });
            primeVector(u_prev, function(k:int):Number
            {
                return u[k];
            });
            primeVector(v, function(k:int):Number
            {
                return k - k;
            });
            primeVector(v_prev, function(k:int):Number
            {
                return v[k];
            });
            primeVector(dens, function(k:int):Number
            {
                var length:Number = N + 2;
                var x:Number = k % length;

                return Math.cos(Math.PI * (x / length));
            });
            primeVector(dens_prev, function(k:int):Number
            {
                return dens[k];
            });

            primeVector(s, function(k:int):Number
            {
                return k == IX(32, 32) ? 1 : 0;
            });

            addEventListener(Event.ENTER_FRAME, update);
        }

        protected function update(event:Event):void
        {
            vel_step(u, v, u_prev, v_prev, 0.5, 0.5);
            dens_step(dens, dens_prev, u, v, 0.5, 0.5);

            var min:Number = Number.MAX_VALUE;
            var max:Number = Number.MIN_VALUE;
            var s:String = "";

            coffee.lock();
            for (var j:int = 0; j < (N + 2); j++)
            {
                for (var i:int = 0; i < (N + 2); i++)
                {
                    var g:Number = dens[IX(i,j)];
                    if(g < min) min = g;
                    if(g > max) max = g;
                    var gi:int = int(Math.abs(g) *128) & 0xff;
                    s += g + " ";
                    coffee.setPixel(i, j, gi << 16 | gi << 8 | gi);
                }
                s += "\n";
            }
            coffee.unlock();

            //trace(s);
            trace("\n\nmin: " + min);
            trace("\n\nmax: " + max);

            //removeEventListener(Event.ENTER_FRAME, update);
        }

        protected function primeVector(vector:Vector.<Number>, primer:Function):void
        {
            var length:int = vector.length;
            for (var i:int = 0; i < length; i++)
            {
                vector[i] = primer(i);
            }
        }

        // TODO: inline this
        protected function IX(i:int, j:int):int
        {
            return i + ((N + 2) * j);
        }

        protected function letThereBeUnformedCoffee():BitmapData
        {
            return new BitmapData(N + 2, N + 2, false, 0x000000);
        }

        protected function getCupFor(coffee:BitmapData):Bitmap
        {
            var bitmap:Bitmap = new Bitmap(coffee, PixelSnapping.NEVER, true);
            bitmap.scaleX = int(stage.stageWidth / coffee.width);
            bitmap.scaleY = bitmap.scaleX;
            return bitmap;
        }

        protected function add_source(x:Vector.<Number>, source:Vector.<Number>, dt:Number):void
        {
            for (var i:int = 0; i < SIZE; i++)
            {
                x[i] += dt * source[i];
            }
        }

        protected function diffuse(b:int, x:Vector.<Number>, x0:Vector.<Number>, diff:Number, dt:Number):void
        {
            var a:Number = dt * diff * N * N;

            for ( var k:int = 0 ; k < 1/*20*/ ; k++ )
            {
                for ( var i:int = 1 ; i <= N ; i++ )
                {
                    for ( var j:int = 1 ; j <= N ; j++ )
                    {
                        x[IX(i, j)] = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) / (1 + 4 * a);
                    }
                }
                set_bnd(b, x);
            }
        }

        protected function set_bnd(b:int, x:Vector.<Number>):void
        {
            for ( var i:int = 1 ; i <= N ; i++ )
            {
                x[IX(0, i)] = b == 1 ? -x[IX(1, i)] : x[IX(1, i)];
                x[IX(N + 1, i)] = b == 1 ? -x[IX(N, i)] : x[IX(N, i)];
                x[IX(i, 0)] = b == 2 ? -x[IX(i, 1)] : x[IX(i, 1)];
                x[IX(i, N + 1)] = (b == 2) ? -x[IX(i, N)] : x[IX(i, N)];
            }

            x[IX(0, 0)] = 0.5 * (x[IX(1, 0)] + x[IX(0, 1)]);
            x[IX(0, N + 1)] = 0.5 * (x[IX(1, N + 1)] + x[IX(0, N)]);
            x[IX(N + 1, 0)] = 0.5 * (x[IX(N, 0)] + x[IX(N + 1, 1)]);
            x[IX(N + 1, N + 1)] = 0.5 * (x[IX(N, N + 1)] + x[IX(N + 1, N)]);
        }

        protected function advect(b:int, d:Vector.<Number>, d0:Vector.<Number>, u:Vector.<Number>, v:Vector.<Number>, dt:Number):void
        {
            var i:int;
            var j:int;
            var i0:int;
            var j0:int;
            var i1:int;
            var j1:int;

            var x:Number;
            var y:Number;
            var s0:Number;
            var t0:Number;
            var s1:Number;
            var t1:Number;
            var dt0:Number;

            dt0 = dt * N;

            for ( i = 1 ; i <= N ; i++ )
            {
                for ( j = 1 ; j <= N ; j++ )
                {
                    x = i - dt0 * u[IX(i, j)];
                    y = j - dt0 * v[IX(i, j)];

                    if (x < 0.5) x = 0.5;
                    if (x > N + 0.5) x = N + 0.5;

                    i0 = int(x);
                    i1 = i0 + 1;

                    if (y < 0.5) y = 0.5;
                    if (y > N + 0.5) y = N + 0.5;

                    j0 = int(y);
                    j1 = j0 + 1;

                    s1 = x - i0;
                    s0 = 1 - s1;

                    t1 = y - j0;
                    t0 = 1 - t1;

                    d[IX(i, j)] = s0 * (t0 * d0[IX(i0, j0)] + t1 * d0[IX(i0, j1)]) + s1 * (t0 * d0[IX(i1, j0)] + t1 * d0[IX(i1, j1)]);
                }
            }
            set_bnd(b, d);
        }

        protected function dens_step(x:Vector.<Number>, x0:Vector.<Number>, u:Vector.<Number>, v:Vector.<Number>, diff:Number, dt:Number):void
        {
            var tmp:Vector.<Number>;

            add_source(x, x0, dt);

            // SWAP ( x0, x );
            tmp = x0;
            x0 = x;
            x = tmp;
            diffuse(0, x, x0, diff, dt);

            // SWAP ( x0, x );
            tmp = x0;
            x0 = x;
            x = tmp;
            advect(0, x, x0, u, v, dt);
        }

        protected function vel_step(u:Vector.<Number>, v:Vector.<Number>, u0:Vector.<Number>, v0:Vector.<Number>, visc:Number, dt:Number):void
        {
            var tmp:Vector.<Number>;

            add_source(u, u0, dt);
            add_source(v, v0, dt);

            // SWAP ( u0, u );
            tmp = u0;
            u0 = u;
            u = tmp;
            diffuse(1, u, u0, visc, dt);

            // SWAP ( v0, v );
            tmp = v0;
            v0 = v;
            v = tmp;
            diffuse(2, v, v0, visc, dt);

            project(u, v, u0, v0);

            // SWAP ( u0, u );
            tmp = u0;
            u0 = u;
            u = tmp;
            // SWAP ( v0, v );
            tmp = v0;
            v0 = v;
            v = tmp;

            advect(1, u, u0, u0, v0, dt);
            advect(2, v, v0, u0, v0, dt);
            project(u, v, u0, v0);
        }

        protected function project(u:Vector.<Number>, v:Vector.<Number>, p:Vector.<Number>, div:Vector.<Number>):void
        {
            var i:int;
            var j:int;
            var k:int;

            var h:Number;
            h = 1.0 / N;

            for ( i = 1 ; i <= N ; i++ )
            {
                for ( j = 1 ; j <= N ; j++ )
                {
                    div[IX(i, j)] = -0.5 * h * (u[IX(i + 1, j)] - u[IX(i - 1, j)] + v[IX(i, j + 1)] - v[IX(i, j - 1)]);
                    p[IX(i, j)] = 0;
                }
            }

            set_bnd(0, div);
            set_bnd(0, p);

            for ( k = 0 ; k < 20 ; k++ )
            {
                for ( i = 1 ; i <= N ; i++ )
                {
                    for ( j = 1 ; j <= N ; j++ )
                    {
                        p[IX(i, j)] = (div[IX(i, j)] + p[IX(i - 1, j)] + p[IX(i + 1, j)] + p[IX(i, j - 1)] + p[IX(i, j + 1)]) / 4 ;
                    }
                }
                set_bnd(0, p);
            }
            for ( i = 1 ; i <= N ; i++ )
            {
                for ( j = 1 ; j <= N ; j++ )
                {
                    u[IX(i, j)] -= 0.5 * (p[IX(i + 1, j)] - p[IX(i - 1, j)]) / h;
                    v[IX(i, j)] -= 0.5 * (p[IX(i, j + 1)] - p[IX(i, j - 1)]) / h;
                }
            }
            set_bnd(1, u);
            set_bnd(2, v);
        }
        // End of class
    }
    // End of package
}
