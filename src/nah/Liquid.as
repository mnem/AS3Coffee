package nah
{
    import flash.geom.Rectangle;
    import flash.display.BitmapData;
    /**
     * All maths and physics merrily stolen from:
     *
     *    http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/GDC03.pdf
     *    http://www.multires.caltech.edu/teaching/demos/java/stablefluids.htm
     */
    public class Liquid
    {
        protected static const N:int = 62;
        protected static const N_PLUS_2:int = 64;
        protected static const SIZE:int = N_PLUS_2 * N_PLUS_2;
        //
        protected var dt:Number = 0.2;
        protected var visc:Number = 0.0;
        protected var diff:Number = 0.0;
        //
        protected var tmp:Vector.<Number>;
        //
        protected var _u:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var _v:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var u_prev:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var v_prev:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var dens:Vector.<Number> = new Vector.<Number>(SIZE, true);
        public var dens_prev:Vector.<Number> = new Vector.<Number>(SIZE, true);
        protected var curl:Vector.<Number> = new Vector.<Number>(SIZE, true);
        //
        protected var _photo:BitmapData;

        public function Liquid():void
        {
            _photo = new BitmapData(N_PLUS_2, N_PLUS_2, false, 0x000000);

            zeroVector(_u);
            zeroVector(u_prev);
            zeroVector(_v);
            zeroVector(v_prev);
            zeroVector(dens);
            zeroVector(dens_prev);
            zeroVector(curl);
        }

        protected function zeroVector(vector:Vector.<Number>):void
        {
            var length:int = vector.length;
            for (var i:int = 0; i < length; i++)
            {
                vector[i] = 0;
            }
        }

        public function update():void
        {
            vel_step(visc, dt);
            dens_step(diff, dt);
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

        public function get photo():BitmapData
        {
            return _photo;
        }

        protected function add_source(x:Vector.<Number>, x0:Vector.<Number>, dt:Number):void
        {
            for (var i:int = 0; i < SIZE; i++)
            {
                x[i] += dt * x0[i];
            }
        }

        protected function buoyancy(buoy:Vector.<Number>):void
        {
            var Tamb:Number = 0;
            var a:Number = 0.000625;
            var b:Number = 0.025;
            var i:int;
            var j:int;

            // sum all temperatures
            for ( i = 1; i <= N; i++)
            {
                for (j = 1; j <= N; j++)
                {
                    Tamb += dens[i + N_PLUS_2 * j];
                }
            }

            // get average temperature
            Tamb /= (N * N);

            // for each cell compute buoyancy force
            for ( i = 1; i <= N; i++)
            {
                for ( j = 1; j <= N; j++)
                {
                    buoy[i + N_PLUS_2 * j] = a * dens[i + N_PLUS_2 * j] + -b * (dens[i + N_PLUS_2 * j] - Tamb);
                }
            }
        }

        protected function vorticityConfinement(vc_x:Vector.<Number>, vc_y:Vector.<Number>):void
        {
            var dw_dx:Number;
            var dw_dy:Number;
            var length:Number;
            var v:Number;
            var i:int;
            var j:int;
            var du_dy:Number;
            var dv_dx:Number;

            // Calculate magnitude of curl(u,v) for each cell. (|w|)
            for ( i = 1; i <= N; i++)
            {
                for ( j = 1; j <= N; j++)
                {
                    du_dy = (_u[i + N_PLUS_2 * (j + 1)] - _u[i + N_PLUS_2 * (j - 1)]) * 0.5;
                    dv_dx = (_v[(i + 1) + N_PLUS_2 * j] - _v[(i - 1) + N_PLUS_2 * j]) * 0.5;

                    curl[i + N_PLUS_2 * j] = Math.abs(du_dy - dv_dx);
                }
            }

            for ( i = 2; i < N; i++)
            {
                for ( j = 2; j < N; j++)
                {
                    // Find derivative of the magnitude (n = del |w|)
                    dw_dx = (curl[(i + 1) + N_PLUS_2 * j] - curl[(i - 1) + N_PLUS_2 * j]) * 0.5;
                    dw_dy = (curl[i + N_PLUS_2 * (j + 1)] - curl[i + N_PLUS_2 * (j - 1)]) * 0.5;

                    // Calculate vector length. (|n|)
                    // Add small factor to prevent divide by zeros.
                    length = Math.sqrt(dw_dx * dw_dx + dw_dy * dw_dy) + 0.000001;

                    // N = ( n/|n| )
                    dw_dx /= length;
                    dw_dy /= length;

                    du_dy = (_u[i + N_PLUS_2 * (j + 1)] - _u[i + N_PLUS_2 * (j - 1)]) * 0.5;
                    dv_dx = (_v[(i + 1) + N_PLUS_2 * j] - _v[(i - 1) + N_PLUS_2 * j]) * 0.5;
                    v = du_dy - dv_dx;

                    // N x w
                    vc_x[i + N_PLUS_2 * j] = dw_dy * -v;
                    vc_y[i + N_PLUS_2 * j] = dw_dx *  v;
                }
            }
        }


        protected function set_bnd(b:int, x:Vector.<Number>):void
        {
            for ( var i:int = 1 ; i <= N ; i++ )
            {
                x[0 + (N_PLUS_2 * i)] = b == 1 ? -x[1 + N_PLUS_2 * i] : x[1 + N_PLUS_2 * i];
                x[(N+1) + N_PLUS_2 * i] = b == 1 ? -x[N + N_PLUS_2 * i] : x[N + N_PLUS_2 * i];
                x[i + N_PLUS_2 * 0] = b == 2 ? -x[i + N_PLUS_2 * 1] : x[i + N_PLUS_2 * 1];
                x[i + N_PLUS_2 * (N+1)] = b == 2 ? -x[i + N_PLUS_2 * N] : x[i + N_PLUS_2 * N];
            }

            x[0 + N_PLUS_2 * 0] = 0.5 * (x[1 + N_PLUS_2 * 0] + x[0 + N_PLUS_2 * 1]);
            x[0 + N_PLUS_2 * (N+1)] = 0.5 * (x[1 + N_PLUS_2 * (N+1)] + x[0 + N_PLUS_2 * N]);
            x[(N+1) + N_PLUS_2 * 0] = 0.5 * (x[N + N_PLUS_2 * 0] + x[(N+1) + N_PLUS_2 * 1]);
            x[(N+1) + N_PLUS_2 * (N+1)] = 0.5 * (x[N + N_PLUS_2 * (N+1)] + x[(N+1) + N_PLUS_2 * N]);
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

        protected function dens_step(diff:Number, dt:Number):void
        {
            add_source(dens, dens_prev, dt);
            // SWAP ( x0, x );
            tmp = dens_prev;
            dens_prev = dens;
            dens = tmp;

            diffuse(0, dens, dens_prev, diff, dt);
            // SWAP ( x0, x );
            tmp = dens_prev;
            dens_prev = dens;
            dens = tmp;

            advect(0, dens, dens_prev, _u, _v, dt);

            zeroVector(dens_prev);
        }

        protected function vel_step(visc:Number, dt:Number):void
        {
            add_source(_u, u_prev, dt);
            add_source(_v, v_prev, dt);

            ///
            vorticityConfinement(u_prev, v_prev);
            add_source(_u, u_prev, dt);
            add_source(_v, v_prev, dt);

            buoyancy(v_prev);
            add_source(_v, v_prev, dt);
            ///

            // SWAP ( u0, u );
            tmp = u_prev;
            u_prev = _u;
            _u = tmp;
            diffuse(0, _u, u_prev, visc, dt);

            // SWAP ( v0, v );
            tmp = v_prev;
            v_prev = _v;
            _v = tmp;
            diffuse(0, _v, v_prev, visc, dt);

            project(_u, _v, u_prev, v_prev);

            // SWAP ( u0, u );
            tmp = u_prev;
            u_prev = _u;
            _u = tmp;
            // SWAP ( v0, v );
            tmp = v_prev;
            v_prev = _v;
            _v = tmp;

            advect(1, _u, u_prev, u_prev, v_prev, dt);
            advect(2, _v, v_prev, u_prev, v_prev, dt);

            project(_u, _v, u_prev, v_prev);

            zeroVector(u_prev);
            zeroVector(v_prev);
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
