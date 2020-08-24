//
// Engine_Sitar
//
// A norns emulation of a shruti box.
//
// Adapted from https://sccode.org/1-51m
//

/*
~k = Shruti.define;

~b = Bus.control(s);
~x = Synth.new(\bellows, [\bus, ~b]);

~k.test(true, -6, 1, ~b);

~x.set(\amp, 1);
~x.set(\amp, 0);
*/

Shruti {
  *define {
    SynthDef(\reed, {
      arg out = 0, freq = 440, amp = 0.1, gate = 1, attack = 0.3, release = 0.3, bellowsBus = -1;
      var snd, blow, pwm, bellowsAmp;

      bellowsAmp = if(bellowsBus < 0, DC.kr(1), In.kr(bellowsBus));

      // pulse with modulating width
      pwm = 0.48 + LFNoise1.kr([Rand(0.04,0.07), Rand(0.04,0.08)], 0.1);
      snd = Pulse.ar((Rand(-0.03, 0.05) + freq.cpsmidi).midicps, pwm, 0.2);
      // add a little "grit" to the reed
      snd = Disintegrator.ar(snd, 0.5, 0.7);
      // a little ebb and flow in volume
      snd = snd * LFNoise2.kr(5, 0.05, 1);
      // use the same signal to control both the resonant freq and the amplitude
      blow = EnvGen.ar(Env.asr(attack, 1.0, release), gate, doneAction: 2);
      snd = snd + BPF.ar(snd, blow.linexp(0, 1, 2000, 2442), 0.3, 3);
      // boost the high end a bit to get a buzzier sound
      snd = BHiShelf.ar(snd, 1200, 1, 3);
      snd = snd * blow * bellowsAmp;
      Out.ar(out, Pan2.ar(snd, 0, amp));
    }).add;

    SynthDef(\bellows, {
      arg bus, amp = 0, time = 5, curve = 0, warp = 5;
      var snd = VarLag.kr(amp, time, curve, warp);
      snd = snd * LFNoise2.kr(0.4, 0.2, 1);
      Out.kr(bus, snd);
    }).add;
  }

  *test {
    arg chord = true, mtranspose = 0, legato = 0.5, bellowsBus = -1;

    Pbind(
      \instrument, \reed,
      \mtranspose, mtranspose,
      \amp, 0.1*(2**Pgauss(0, 0.1)),
      \bellowsBus, bellowsBus,
      \dur, 5.0,
      \legato, legato,
      \root, 1,
      \attack, 0.2,
      \release, 0.2,
      \degree, if (chord,
        { Pseq([[-7, -3, 0, 2], [-7, -2, 0, 3], [-7, -1, 1, 4]].mirror1, inf) },
        { Pseq([[-7], [-2], [-1], [4]].mirror1, inf) })
    ).play;
  }
}

Engine_Shruti : CroneEngine {
  var <reedGroup;
  var <bellows;
  var <bellowsBus;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    Shruti.define;
    context.server.sync;
    bellowsBus = Bus.control(context.server, 1);

  }

  free {
    reedGroup.free;
    bellows.free;
    bellowsBus.free;
  }
}