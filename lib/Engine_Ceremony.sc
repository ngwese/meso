//
// Engine_Ceremony
//
// Based on the Tibetan prayer bells by wondersluyter.
// See: http://sccode.org/1-4VL
//
// TODO:
// - arrange a static set of synth voices at initialization
// - allow each voice to be placed in the stereo field
// - confirm/change such that re-triggering a voice excites the same resonators
//

Engine_Ceremony : CroneEngine {
  var <group;
  var <voices;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
    group = Group.tail(context.xg);
    voices = Dictionary.new;

    SynthDef(\prayer_bell, {
      arg outbus, t_trig = 1, singSwitch = 0, freq = 2434, amp = 0.5, decayScale = 1, lag = 10, i_doneAction = 0;

      var sig, input, first, freqScale, mallet, sing;

      freqScale = freq / 2434;
      freqScale = Lag3.kr(freqScale, lag);
      decayScale = Lag3.kr(decayScale, lag);

      mallet = LPF.ar(Trig.ar(t_trig, SampleDur.ir)!2, 10000 * freqScale) / 6.0; // reduce impulse to avoid distortion
      sing = LPF.ar(
        LPF.ar(
          {
            PinkNoise.ar * Integrator.kr(singSwitch * 0.001, 0.999).linexp(0, 1, 0.01, 1) * amp
          } ! 2,
          2434 * freqScale
        ) + Dust.ar(0.1), 10000 * freqScale
      ) * LFNoise1.kr(0.5).range(-45, -30).dbamp;
      input = mallet + (singSwitch.clip(0, 1) * sing);

      sig = DynKlank.ar(`[
        [
          (first = LFNoise1.kr(0.5).range(2424, 2444)) + Line.kr(20, 0, 0.5),
          first + LFNoise1.kr(0.5).range(1,3),
          LFNoise1.kr(1.5).range(5435, 5440) - Line.kr(35, 0, 1),
          LFNoise1.kr(1.5).range(5480, 5485) - Line.kr(10, 0, 0.5),
          LFNoise1.kr(2).range(8435, 8445) + Line.kr(15, 0, 0.05),
          LFNoise1.kr(2).range(8665, 8670),
          LFNoise1.kr(2).range(8704, 8709),
          LFNoise1.kr(2).range(8807, 8817),
          LFNoise1.kr(2).range(9570, 9607),
          LFNoise1.kr(2).range(10567, 10572) - Line.kr(20, 0, 0.05),
          LFNoise1.kr(2).range(10627, 10636) + Line.kr(35, 0, 0.05),
          LFNoise1.kr(2).range(14689, 14697) - Line.kr(10, 0, 0.05)
        ],
        [
          LFNoise1.kr(1).range(-10, -5).dbamp,
          LFNoise1.kr(1).range(-20, -10).dbamp,
          LFNoise1.kr(1).range(-12, -6).dbamp,
          LFNoise1.kr(1).range(-12, -6).dbamp,
          -20.dbamp,
          -20.dbamp,
          -20.dbamp,
          -25.dbamp,
          -10.dbamp,
          -20.dbamp,
          -20.dbamp,
          -25.dbamp
        ],
        [
          20 * freqScale.pow(0.2),
          20 * freqScale.pow(0.2),
          5,
          5,
          0.6,
          0.5,
          0.3,
          0.25,
          0.4,
          0.5,
          0.4,
          0.6
        ] * freqScale.reciprocal.pow(0.5)
      ], input, freqScale, 0, decayScale);
      FreeSelf.kr(DetectSilence.ar(sig, doneAction: i_doneAction));
      Out.ar(outbus, sig);
    }).add;

    context.server.sync;

    // voice control
    this.addCommand(\start, "iffffff", { arg msg;
      this.voiceAdd(id: msg[1],
                    hz: msg[2],
                    trig: msg[3],
                    amp: msg[4],
                    sing: msg[5],
                    lag: msg[6],
                    decayScale: msg[7]);
    });

    this.addCommand(\stop, "i", { arg msg;
      this.voiceRemove(msg[1]);
    });

    this.addCommand(\sing, "iff", { arg msg;
      this.voiceSing(id: msg[1], sing: msg[2], amp: msg[3]);
    });

    this.addCommand(\trig, "if", { arg msg;
      this.voiceTrig(id: msg[1], trig: msg[2]);
    });

    this.addCommand(\tune, "if", { arg msg;
      this.voiceTune(id: msg[1], tune: msg[2]);
    });


  }

  voiceAdd { arg id, hz, trig, amp = 0.5, sing = 0, lag = 10, decayScale = 1;
    var params = List.with(\out, context.out_b.index, \freq, hz, \trig, trig, \amp, amp, \singSwitch, sing, \lag, lag, \decayScale, decayScale);
    var existingVoice = voices[id];

    // if re-using id of an active voice, kil the voice
    // TODO: should this fade the voice out?
    if (existingVoice.notNil, {
      Post << "Killing voice [" << id << "]\n";
      NodeWatcher.unregister(existingVoice);
      existingVoice.free;
    });

    Post << "add[" << id << "] with " << params << "\n";

    voices.add(id -> Synth.new(\prayer_bell, params, group));
    NodeWatcher.register(voices[id]);
    voices[id].onFree({
      Post << "Removing voice [" << id << "]\n";
      voices.removeAt(id);
    });
  }

  voiceRemove { arg id;
    if (voices[id].notNil, {
      // cut amp, then DetectSilence will trigger the end condition
      voices[id].free;
      voices.removeAt(id);
    });
  }

  voiceSing { arg id, sing, amp = 0.5;
    var voice = voices[id];
    if (voice.notNil, {
      Post << "Setting [" << id << "] // " << voice << " sing = " << sing << "\n";
      voice.set(\sing, sing, \amp, amp);
    })
  }

  voiceTrig { arg id, trig;
    var voice = voices[id];
    if (voice.notNil, {
      Post << "Setting [" << id << "] // " << voice << " trig = " << trig << "\n";
      voice.set(\trig, trig);
    })
  }

  voiceTune { arg id, tune;
    var voice = voices[id];
    if (voice.notNil, {
      Post << "Setting [" << id << "] // " << voice << " tune = " << tune << "\n";
      voice.set(\freq, tune);
    })
  }

  free {
    group.free;
  }
}
