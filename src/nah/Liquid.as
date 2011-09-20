package nah
{
    import flash.geom.Rectangle;
    import flash.display.BitmapData;
    /**
     * All maths and physics merrily stolen from:
     *
     *    http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/GDC03.pdf
     */
    public class Liquid
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
        public var dens_prev:Vector.<Number> = new Vector.<Number>(SIZE, true);
        //
        protected var _photo:BitmapData;

        public function Liquid():void
        {
            _photo = new BitmapData(N_PLUS_2, N_PLUS_2, false, 0x000000);

            primeVector(u, returnZero);
            primeVector(u_prev, returnZero);
            primeVector(v, returnZero);
            primeVector(v_prev, returnZero);
            primeVector(dens, returnZero);
            primeVector(dens_prev, returnZero);
        }

        protected function returnZero(...args):Number
        {
            return 0;
        }

        public function update():void
        {
            vel_step(u, v, u_prev, v_prev, 100, 1);
            dens_step(dens, dens_prev, u, v, 0.5, 1);
        }

        protected var r:Rectangle = new Rectangle(0, 0, N_PLUS_2, N_PLUS_2);
        protected var converted:Vector.<uint> = new Vector.<uint>(SIZE, true);
        public function snapshot():void
        {
            for(var i:int = 0; i < SIZE; i++)
            {
                var d:Number = dens[i];
                var c:int = 255 * d;
                if(c < 0 ) c = 0;
                if(c > 255 ) c = 255;
                converted[i] = c << 16 | c << 8 | c;
            }

            _photo.lock();
            _photo.setVector(r, converted);
            _photo.unlock();
        }

        protected function primeVector(vector:Vector.<Number>, primer:Function):void
        {
            var length:int = vector.length;
            for (var i:int = 0; i < length; i++)
            {
                vector[i] = primer(i);
            }
        }

        public function get photo():BitmapData
        {
            return _photo;
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
                j = 1;

                // 0
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                // 10
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                // 20
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                // 30
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                // 40
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                // 50
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                // 60
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
                x = i - dt0 * u[i + N_PLUS_2 * j]; y = j - dt0 * v[i + N_PLUS_2 * j]; if (x < 0.5) x = 0.5; if (x > N + 0.5) x = N + 0.5; i0 = int(x); i1 = i0 + 1; if (y < 0.5) y = 0.5; if (y > N + 0.5) y = N + 0.5; j0 = int(y); j1 = j0 + 1; s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1; d[i + N_PLUS_2 * j] = s0 * (t0 * d0[i0 + N_PLUS_2 * j0] + t1 * d0[i0 + N_PLUS_2 * j1]) + s1 * (t0 * d0[i1 + N_PLUS_2 * j0] + t1 * d0[i1 + N_PLUS_2 * j1]); j++;
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
            var a_div:Number = (1 + 4 * a);
            var n_plus_2:int = N_PLUS_2;
            var o :int = 1 + n_plus_2 * 1;

            for ( var i:int = 1 ; i <= N ; i++ )
            {
                // 0
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                // 10
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                // 20
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                // 30
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                // 40
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                // 50
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                // 60
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;
                x[o] = (x0[o] + a * (x[o-1] + x[o+1] + x[o-n_plus_2] + x[o+n_plus_2])) / a_div; o++;

                o += 2;
            }
            set_bnd(b, x);
        }

        protected function project(u:Vector.<Number>, v:Vector.<Number>, p:Vector.<Number>, div:Vector.<Number>):void
        {
            var i:int;
            var j:int;
            var n_plus_2:int = N_PLUS_2;
            var o :int;

            var h:Number;
            h = 1.0 / N;

            o = 1 + n_plus_2 * 1;
            for ( i = 1 ; i <= N ; i++ )
            {
                // 0
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                // 10
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                // 20
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                // 30
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                // 40
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                // 50
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                // 60
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;
                div[o] = -0.5 * h * (u[o+1] - u[o-1] + v[o+n_plus_2] - v[o-n_plus_2]); p[o] = 0; o++;

                o+=2;
            }

            set_bnd(0, div);
            set_bnd(0, p);

            o = 1 + n_plus_2 * 1;
            for ( i = 1 ; i <= N ; i++ )
            {
                // 0
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                // 10
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                // 20
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                // 30
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                // 40
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                // 50
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                // 60
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;
                p[o] = (div[o] + p[o-1] + p[o+1] + p[o-n_plus_2] + p[o+n_plus_2]) / 4 ; o++;

                o += 2;
            }
            set_bnd(0, p);

            o = 1 + n_plus_2 * 1;
            for ( i = 1 ; i <= N ; i++ )
            {
                // 0
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                // 10
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                // 20
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                // 30
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                // 40
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                // 50
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                // 60
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;
                u[o] -= 0.5 * (p[o+1] - p[o-1]) / h; v[o] -= 0.5 * (p[o+n_plus_2] - p[o-n_plus_2]) / h; o++;

                o+=2;
            }
            set_bnd(1, u);
            set_bnd(2, v);
        }
    }
}
