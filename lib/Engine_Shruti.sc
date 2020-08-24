//
// Adapted from https://sccode.org/1-51m
(
SynthDef(\shruti, {
    |out = 0, freq = 440, amp = 0.1, gate = 1, attack = 0.3, release = 0.3|
    var snd, blow, pwm;
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
    snd = snd * blow;
    Out.ar(out, Pan2.ar(snd, 0, amp));
}).add;

Pbind(
    \instrument, \reed,
    \amp, 0.1*(2**Pgauss(0, 0.1)),
    \dur, 5.0,
    \legato, 0.5,
    \root, 1,
    \attack, 2,
    \release, 3,
   \degree, Pseq([[-7, -3, 0, 2], [-7, -2, 0, 3], [-7, -1, 1, 4]].mirror1, inf)
  //\degree, Pseq([[-7], [-2], [-1], [4]].mirror1, inf)

).play;

)