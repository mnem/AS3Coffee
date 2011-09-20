package nah
{
    import flash.geom.Rectangle;
    import flash.display.BitmapData;
    /**
     * All maths and physics merrily stolen from:
     *
     *    http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/GDC03.pdf
     *    http://www.multires.caltech.edu/teaching/demos/java/stablefluids.htm
     *
     *  WARNING: Here be dragons. Or, at least, horrible huge chunks of
     *  unrolled loops.
     */
    public class Liquid
    {
        private static const CLUT:Vector.<uint> = Vector.<uint>([
            0xffffff,    0xfefefe,    0xfdfdfd,    0xfcfcfc,    0xfcfbfb,    0xfbfafa,    0xfaf9f9,    0xf9f8f8,
            0xf9f7f7,    0xf8f7f6,    0xf7f6f5,    0xf6f5f4,    0xf6f4f3,    0xf5f3f2,    0xf4f2f1,    0xf3f1f0,
            0xf3f0ef,    0xf2efee,    0xf1efed,    0xf1eeec,    0xf0edeb,    0xefecea,    0xeeebe9,    0xeeeae8,
            0xede9e7,    0xece8e6,    0xebe8e5,    0xebe7e4,    0xeae6e3,    0xe9e5e2,    0xe8e4e1,    0xe8e3e0,
            0xe7e2df,    0xe6e1de,    0xe6e0dd,    0xe5e0dc,    0xe4dfdb,    0xe3deda,    0xe3ddd9,    0xe2dcd8,
            0xe1dbd7,    0xe0dad6,    0xe0d9d5,    0xdfd9d4,    0xded8d3,    0xddd7d2,    0xddd6d1,    0xdcd5d0,
            0xdbd4cf,    0xdbd3ce,    0xdad2cd,    0xd9d1cc,    0xd8d1cb,    0xd8d0ca,    0xd7cfc9,    0xd6cec8,
            0xd5cdc7,    0xd5ccc6,    0xd4cbc5,    0xd3cac4,    0xd2cac3,    0xd2c9c2,    0xd1c8c1,    0xd0c7c0,
            0xd0c6bf,    0xcfc5be,    0xcec4bd,    0xcdc3bc,    0xcdc2bb,    0xccc2ba,    0xcbc1b9,    0xcac0b8,
            0xcabfb7,    0xc9beb6,    0xc8bdb5,    0xc7bcb4,    0xc7bbb3,    0xc6bbb2,    0xc5bab1,    0xc4b9b0,
            0xc4b8af,    0xc3b7ae,    0xc2b6ad,    0xc2b5ac,    0xc1b4ab,    0xc0b3aa,    0xbfb3a9,    0xbfb2a8,
            0xbeb1a7,    0xbdb0a6,    0xbcafa5,    0xbcaea4,    0xbbada3,    0xbaaca2,    0xb9aca1,    0xb9aba0,
            0xb8aa9f,    0xb7a99e,    0xb7a89d,    0xb6a79c,    0xb5a69b,    0xb4a59a,    0xb4a499,    0xb3a498,
            0xb2a397,    0xb1a296,    0xb1a195,    0xb0a094,    0xaf9f93,    0xae9e92,    0xae9d91,    0xad9d90,
            0xac9c8f,    0xac9b8e,    0xab9a8d,    0xaa998c,    0xa9988b,    0xa9978a,    0xa89689,    0xa79588,
            0xa69587,    0xa69486,    0xa59385,    0xa49284,    0xa39183,    0xa39082,    0xa28f81,    0xa18e80,
            0xa18e7f,    0xa08d7e,    0x9f8c7d,    0x9e8b7c,    0x9e8a7b,    0x9d897a,    0x9c8879,    0x9b8778,
            0x9b8677,    0x9a8676,    0x998575,    0x988474,    0x988373,    0x978272,    0x968171,    0x958070,
            0x957f6f,    0x947e6e,    0x937e6d,    0x937d6c,    0x927c6b,    0x917b6a,    0x907a69,    0x907968,
            0x8f7867,    0x8e7766,    0x8d7765,    0x8d7664,    0x8c7563,    0x8b7462,    0x8a7361,    0x8a7260,
            0x89715f,    0x88705e,    0x886f5d,    0x876f5c,    0x866e5b,    0x856d5a,    0x856c59,    0x846b58,
            0x836a57,    0x826956,    0x826855,    0x816854,    0x806753,    0x7f6652,    0x7f6551,    0x7e6450,
            0x7d634f,    0x7d624e,    0x7c614d,    0x7b604c,    0x7a604b,    0x7a5f4a,    0x795e49,    0x785d48,
            0x775c47,    0x775b46,    0x765a45,    0x755944,    0x745943,    0x745842,    0x735741,    0x725640,
            0x72553f,    0x71543e,    0x70533d,    0x6f523c,    0x6f513b,    0x6e513a,    0x6d5039,    0x6c4f38,
            0x6c4e37,    0x6b4d36,    0x6a4c35,    0x694b34,    0x694a33,    0x684a32,    0x674931,    0x664830,
            0x66472f,    0x65462e,    0x64452d,    0x64442c,    0x63432b,    0x62422a,    0x614229,    0x614128,
            0x604027,    0x5f3f26,    0x5e3e25,    0x5e3d24,    0x5d3c23,    0x5c3b22,    0x5b3b21,    0x5b3a20,
            0x5a391f,    0x59381e,    0x59371d,    0x58361c,    0x57351b,    0x56341a,    0x563319,    0x553318,
            0x543217,    0x533116,    0x533015,    0x522f14,    0x512e13,    0x502d12,    0x502c11,    0x4f2c10,
            0x4e2b0f,    0x4e2a0e,    0x4d290d,    0x4c280c,    0x4b270b,    0x4b260a,    0x4a2509,    0x492408,
            0x482407,    0x482306,    0x472205,    0x462104,    0x452003,    0x451f02,    0x441e01,    0x431d00
        ]);
        //
        protected static const N:int = 62;
        protected static const N_PLUS_2:int = 64;
        protected static const SIZE:int = N_PLUS_2 * N_PLUS_2;
        //
        protected var dt:Number = 0.5;
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
        protected var dens_prev:Vector.<Number> = new Vector.<Number>(SIZE, true);
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

        public function addCoffeeAt(x:int, y:int, ml:Number):void
        {
            // Invert it
            x = (N_PLUS_2-1) - x;
            y = (N_PLUS_2-1) - y;

            //
            if(x < 0) x = 0;
            if(x > (N_PLUS_2-1)) x = N_PLUS_2-1;
            if(y < 0) y = 0;
            if(y > (N_PLUS_2-1)) y = N_PLUS_2-1;

            dens_prev[x + N_PLUS_2 * y] += ml;

            u_prev[x + N_PLUS_2 * y] =  10;
            v_prev[x + N_PLUS_2 * y] = -20;
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
            var j:int = 0;
            for(var i:int = SIZE-1; i >= 0; i--)
            {
                var c:int = 255 * dens[i];
                if(c < 0 ) c = 0;
                if(c > 255 ) c = 255;
                converted[j++] = CLUT[c];
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
