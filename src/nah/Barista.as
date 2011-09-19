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
        protected static const N_PLUS_2:int = 64;
        protected static const SIZE:int = N_PLUS_2 * N_PLUS_2;
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
                var length:Number = N_PLUS_2;
                var x:Number = k % length;
                var y:Number = int(k / length);

                if(x > 16 && x < 48 && y > 16 && y < 48) return 10;

                return Math.sin(Math.PI * (x / length));
            });
            primeVector(u_prev, function(k:int):Number
            {
                return 0;//u[k];
            });
            primeVector(v, function(k:int):Number
            {
                var length:Number = N_PLUS_2;
                var x:Number = k % length;
                var y:Number = int(k / length);

                return Math.sin(Math.PI * (y / length));
            });
            primeVector(v_prev, function(k:int):Number
            {
                return v[k];
            });
            primeVector(dens, function(k:int):Number
            {
                var length:Number = N_PLUS_2;
                var x:Number = k % length;
                var y:Number = int(k / length);

                if(x < 16 || x > 48) return 0;
                if(y < 16 || y > 48) return 0;

                return Math.sin(Math.PI * (x / length));
            });
            primeVector(dens_prev, function(k:int):Number
            {
                return dens[k];
            });

            primeVector(s, function(k:int):Number
            {
                return k == (32 + (N_PLUS_2 * 32)) ? 1 : 0;
            });

            addEventListener(Event.ENTER_FRAME, update);
        }

        protected function update(event:Event):void
        {
            var dt:Number = 1;
            var viscosity:Number = 0.2;
            var diffusion:Number = 0.7;

            vel_step(u, v, u_prev, v_prev, viscosity, dt);
            dens_step(dens, dens_prev, u, v, diffusion, dt);

            var min:Number = Number.MAX_VALUE;
            var max:Number = Number.MIN_VALUE;
            var s:String = "";

            coffee.lock();
            for (var j:int = 0; j < N_PLUS_2; j++)
            {
                for (var i:int = 0; i < N_PLUS_2; i++)
                {
                    var g:Number = dens[i + (N_PLUS_2 * j)];
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

        protected function letThereBeUnformedCoffee():BitmapData
        {
            return new BitmapData(N_PLUS_2, N_PLUS_2, false, 0x000000);
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

        protected function set_bnd(b:int, x:Vector.<Number>):void
        {
            for ( var i:int = 1 ; i <= N ; i++ )
            {
                x[0 + (N_PLUS_2 * i)] = b == 1 ? -x[1 + (N_PLUS_2 * i)] : x[1 + (N_PLUS_2 * i)];
                x[(N+1) + (N_PLUS_2 * i)] = b == 1 ? -x[N + (N_PLUS_2 * i)] : x[N + (N_PLUS_2 * i)];
                x[i + (N_PLUS_2 * 0)] = b == 2 ? -x[i + (N_PLUS_2 * 1)] : x[i + (N_PLUS_2 * 1)];
                x[i + (N_PLUS_2 * (N+1))] = (b == 2) ? -x[i + (N_PLUS_2 * N)] : x[i + (N_PLUS_2 * N)];
            }

            x[0 + (N_PLUS_2 * 0)] = 0.5 * (x[1 + (N_PLUS_2 * 0)] + x[0 + (N_PLUS_2 * 1)]);
            x[0 + (N_PLUS_2 * (N+1))] = 0.5 * (x[1 + (N_PLUS_2 * (N+1))] + x[0 + (N_PLUS_2 * N)]);
            x[(N+1) + (N_PLUS_2 * 0)] = 0.5 * (x[N + (N_PLUS_2 * 0)] + x[(N+1) + (N_PLUS_2 * 1)]);
            x[(N+1) + (N_PLUS_2 * (N+1))] = 0.5 * (x[N + (N_PLUS_2 * (N+1))] + x[(N+1) + (N_PLUS_2 * N)]);
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
                    x = i - dt0 * u[i + N_PLUS_2 * j];
                    y = j - dt0 * v[i + N_PLUS_2 * j];

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

                    d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]);
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

        protected function diffuse(b:int, x:Vector.<Number>, x0:Vector.<Number>, diff:Number, dt:Number):void
        {
            var a:Number = dt * diff * N * N;

            //for ( var k:int = 0 ; k < 20 ; k++ )
            {
                for ( var i:int = 1 ; i <= N ; i++ )
                {
                    for ( var j:int = 1 ; j <= N ; j++ )
                    {
                        x[i + N_PLUS_2 * j] = (x0[i + N_PLUS_2 * j] + a * (x[(i-1) + N_PLUS_2 * j] + x[(i+1) + N_PLUS_2 * j] + x[i + N_PLUS_2 * (j-1)] + x[i + N_PLUS_2 * (j+1)])) / (1 + 4 * a);
                    }
                }
                set_bnd(b, x);
            }
        }

        protected function project(u:Vector.<Number>, v:Vector.<Number>, p:Vector.<Number>, div:Vector.<Number>):void
        {
            var i:int;
            var j:int;

            var h:Number;
            h = 1.0 / N;

            for ( i = 1 ; i <= N ; i++ )
            {
                for ( j = 1 ; j <= N ; j++ )
                {
                    div[i + N_PLUS_2 * j] = -0.5 * h * (u[(i+1) + N_PLUS_2 * j] - u[(i-1) + N_PLUS_2 * j] + v[i + N_PLUS_2 * (j+1)] - v[i + N_PLUS_2 * (j-1)]);
                    p[i + N_PLUS_2 * j] = 0;
                }
            }

            set_bnd(0, div);
            set_bnd(0, p);

            //for ( var k:int = 0 ; k < 20 ; k++ )
            {
                for ( i = 1 ; i <= N ; i++ )
                {
                    for ( j = 1 ; j <= N ; j++ )
                    {
                        p[i + N_PLUS_2 * j] = (div[i + N_PLUS_2 * j] + p[(i-1) + N_PLUS_2 * j] + p[(i+1) + N_PLUS_2 * j] + p[i + N_PLUS_2 * (j-1)] + p[i + N_PLUS_2 * (j+1)]) / 4 ;
                    }
                }
                set_bnd(0, p);
            }
            for ( i = 1 ; i <= N ; i++ )
            {
                for ( j = 1 ; j <= N ; j++ )
                {
                    u[i + N_PLUS_2 * j] -= 0.5 * (p[(i+1) + N_PLUS_2 * j] - p[(i-1) + N_PLUS_2 * j]) / h;
                    v[i + N_PLUS_2 * j] -= 0.5 * (p[i + N_PLUS_2 * (j+1)] - p[i + N_PLUS_2 * (j-1)]) / h;
                }
            }
            set_bnd(1, u);
            set_bnd(2, v);
        }
        // End of class
    }
    // End of package
}
