



SinOsc.ar()

a=[0,1,2]
a.pyramid(3)


{PinkNoise.ar(0.1)!2}.play
x = { arg y =1; var mult = 10; y + 4 * mult }
x.value(5)

(
SynthDef(\minu,{
	arg freq = 440, amp = 0.1, gate = 1;
	var sig = SinOsc.ar(freq * LFNoise1.kr(0.01!16).range(-0.1.midiratio,0.1.midiratio)) * amp;
	// sig = sig * Env.perc().ar(Done.freeSelf);
	sig = sig * Env.asr().ar(Done.freeSelf,gate);
	// sig = sig.dup(46) * -18.dbamp;
	sig = Splay.ar(sig,);
	Out.ar(0,sig)
}).add
)

1.dup(2)
~minu = [0,1,2]

~mySynth = Synth(\minu,[\freq,300,\amp,-24.dbamp])
~mySynth.set(\gate,0)


Synth(\minu,[\freq,60.midicps])

300.rrand(1200)

{SinOsc.ar() * 0.5}.plot
Env.perc().plot

// this is a single line comment
/*
this is a
multi-line comment

*/

(
SynthDef(\fmSynth,{
	var carFreq = \carFreq.kr(440); // \argument syntax
	var modFreq = carFreq * \modMult.kr(1);
	var dev = modFreq * \index.kr(1);
	var sig = SinOsc.ar(carFreq + SinOsc.ar(modFreq, 0, dev));

	sig = sig * Env.perc(
		\atk.kr(0.01).linlin(0,1,0.01,3),
		\rls.kr(0.5).linlin(0,1,0.01,3),
		\velocity.kr(1),
		[
			\atkCrv.kr(0.3).linlin(0,1,-10,10),
			\rlsCrv.kr(0.3).linlin(0,1,-10,10)
		]
	).ar(2,\gate.kr(1));
	sig = Select.ar(\filter.kr(0).clip(0,1),[sig,RLPF.ar(sig,sig.abs.linexp(0,1,20,16000).lag(\lag.kr(0.01)),\rq.kr(0.5))]);
	sig = sig.clip2 * -15.dbamp;
	sig = LeakDC.ar(sig);
	sig = Splay.ar(sig,1,\amp.kr(-18.dbamp));
	Out.ar(\out.kr(0),sig)
}).add;

)

60.midicps
Synth(\fmSynth,[
	\carFreq,261.6255653006,
	\modMult,1,
])

(
Routine({
	s.record("~/Desktop/myRecording.wav",0,2);
	0.1.wait;
	~mySynth = Synth(\minu,[\freq,300,\amp,-24.dbamp]);
	2.wait;
	~mySynth.set(\freq,540,\amp,-18.dbamp);
	1.3.wait;
	~mySynth.set(\gate,0)
	1.wait;
	s.stopRecording()
}).play
)














