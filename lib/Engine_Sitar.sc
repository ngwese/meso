//
// Engine_Sitar
//
// An adaptation of https://sccode.org/1-57B#c765 for norns.
//
// Original code is based on a model by David Ronan
// http://issta.ie/wp-content/uploads/The-Physical-Modelling-of-a-Sitar.pdf
//
// Requires sc3-plugins.
//

Engine_Sitar : CroneEngine {
  var <pluckGroup;
  var <chikariGroup;
  var <tarafdarGroup;

  var <pluckBus;
  var <chikariBus;
  var <tarafdarBus;

  var <chikariFreqs;
  var <tarafdarFreqs;
  var <isTuned;

  // synth instances
  var <impulse;
  var <chikari;
  var <tarafdar;
  var <sitar;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		isTuned = false;

		// Single string of a sitar.
		SynthDef(\tar, {
			arg out = 0, in = 0, inscale = 1.0, freq = 440, bw = 1.03, amp = 0.5,
          pos = 0.1,
          hc1 = 1, hc3 = 30, hfreq = 3000,
          vc1 = 1, vc3 = 30, vfreq = 3000;

			var inp, jawari, snd;
			// Input audio -- may be a pluck impulse (chikari) or audio (tarafdar)
			inp = In.ar(in, 1) * inscale;
			// Jawari (bridge) simulation. This is the heart of Ronan's model.
			// Violins and guitars have vertical bridges. The jawari is flat, and this causes the tar to buzz against the jawari.
			// Physically, end of the string coming in contact the bridge causes the string to shorten.
			// We assume that the audio output is a reasonable approximation of how much contact the string has with the bridge.
			// So we shorten the DWG (by adjusting its frequency) according to its own audio output.
			jawari = LocalIn.ar(1);
			// Make the jawari control rate
			jawari = A2K.kr(jawari);
			// Make the jawari affect the freq exponentially
			jawari = jawari.linexp(-1, 1, bw.reciprocal, bw);
			// The string itself has horizontal and vertical planes, which we simulate with two different DWGPlucked instances
			snd = [
				DWGPlucked.ar(freq * jawari, pos: pos, c1: hc1, c3: hc3, inp: LPF.ar(inp, hfreq)),
				DWGPlucked.ar(freq * jawari, pos: pos, c1: vc1, c3: vc3, inp: LPF.ar(inp, vfreq))
			].sum;
			LocalOut.ar(snd);
			Out.ar(out, snd * amp);
		}).add;

		SynthDef(\pluck_impulse, {
			arg out = 0, t_trig = 0, amp = 0.3;
			Out.ar(out, PinkNoise.ar * EnvGen.kr(Env.perc(0.01, 0.02), t_trig) * amp);
		}).add;

		SynthDef(\sitar, {
			arg out = 0, chikari = 0, tarafdar = 0, dry = 0.5, wet = 0.5, amp = 0.5;
			var snd = In.ar(chikari, 1) * dry;
			var lfo;
			snd = snd + (In.ar(tarafdar, 1) * wet);
			// Dumb gourd model. I randomly picked lope only transitions to the release node when released. Examples are below. Tfreqs/bws/amps.
			// Please let me know if you have some estimates of the resonances of a real sitar gourd.
			snd = snd + BPF.ar(snd, [90, 132, 280], [1.3, 0.9, 1.4], [0.9, 0.6, 0.7]).sum;
			snd = Pan2.ar(GVerb.ar(0.3 * snd, roomsize:1, damping:0.7), 0, amp);
			Out.ar(out, snd);
		}).add;

		context.server.sync;

    // allocate tuning independent resources
    chikariBus = Bus.audio(context.server, 1); // summed out of chikari (plucked strings)
    tarafdarBus = Bus.audio(context.server, 1); // summed out of tarafdar (sympathetic strings)

    pluckGroup = Group.tail(context.xg);
    chikariGroup = Group.after(pluckGroup);
    tarafdarGroup = Group.after(chikariGroup);

    // allocate tunig independent synths
    sitar = Synth.after(tarafdarGroup, \sitar, [
      \chikari, chikariBus,
      \tarafdar, tarafdarBus,
      \dry, 1,
      \wet, 0.5,
      \amp, 0.8
    ]);

    // tunig commands
    this.addCommand(\beginTuning, "", {
      this.beginTuning();
    });

    this.addCommand(\addChikariFreq, "f", { arg msg;
      this.addChikariFreq(f: msg[1]);
    });

    this.addCommand(\addTarafdarFreq, "f", { arg msg;
      this.addTarafdarFreq(f: msg[1]);
    });

    this.addCommand(\endTuning, "", {
      this.endTuning();
    });

    // voice control
		this.addCommand(\pluck, "if", { arg msg;
      // Post << "pluck, msg: " << msg << "\n";
      this.pluck(chikariNum: msg[1], amp: msg[2]);
		});

    this.addCommand(\body, "fff", { arg msg;
      // adjust the chikari / tarafdar mix
      sitar.set(\amp, msg[1], \dry, msg[2], \wet, msg[3]);
    });

	}

  beginTuning {
    if (isTuned, {
      Post << "freeing existing nodes\n";
      // free synths, reclaim tunig dependent resources
      pluckGroup.freeAll;
      chikariGroup.freeAll;
      tarafdarGroup.freeAll;
      pluckBus.free;
    });
    isTuned = false;
    chikariFreqs = List.new;
    tarafdarFreqs = List.new;
  }

  addChikariFreq { arg f;
    chikariFreqs.add(f);
  }

  addTarafdarFreq { arg f;
    tarafdarFreqs.add(f);
  }

  endTuning {
    var numChikari = chikariFreqs.size;
    var numTarafdar = tarafdarFreqs.size;

    //Post << "chikariFreqs: " << chikariFreqs << "\n";
    //Post << "tarafdarFreqs: " << chikariFreqs << "\n";

    // alloc bus per string for impulse(s)
    pluckBus = Bus.audio(context.server, numChikari);

    // impulse generators
    impulse = numChikari.collect { arg i;
      Synth(\pluck_impulse, [
        \out, pluckBus.index + i,
        \num, i,
      ], pluckGroup);
    };

    // plucked strings
    chikari = numChikari.collect { arg i;
		  Synth(\tar, [
			  \in, pluckBus.index + i,
			  \out, chikariBus,
			  \freq, chikariFreqs[i],
        \bw, 1.08,
        \hc1, 4, \hc2, 50,
        \vc1, 3, \vc3, 30,
        \amp, 0.1
      ], chikariGroup);
	  };

    // sympathetic strings
    tarafdar = numTarafdar.collect { arg i;
    	Synth(\tar, [
        \in, chikariBus,
        \inscale, 0.1,
        \out, tarafdarBus,
        \freq, tarafdarFreqs[i] * 1.0.rand.linexp(0, 1, 0.99, 1.01),
        \pos, 0.4,
        \bw, 1.08,
        \hc1, 4, \hc2, 50,
        \vc1, 3, \vc3, 30,
        \amp, 0.1
		  ], tarafdarGroup);
    };

    // note: the sitar (body model) is created in alloc()
    isTuned = true;
  }

  pluck { arg chikariNum, amp = 0.3, bw = 1.08;
    chikari[chikariNum].set(\bw, bw);
    impulse[chikariNum].set(\t_trig, 1, \amp, amp);
  }

  free {
    sitar.free;
    pluckGroup.free;
    chikariGroup.free;
    tarafdarGroup.free;
  }
}
