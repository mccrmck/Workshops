/* === MINU 2023: fmSynth === */
(

// what does an fmSynth need?
// detune, unsion, filter, envelope
// switch between pluck and pad? (.perc and .asr)...check how actual synths do this!

// do we do FX? for both instruments?
// give this one a static filter and also a LPG? just 'cus it sounds so amazing...
// how do synths do this normally - individual filters/LPG or one for all voices?

// add lots of comments to this and the other file!!

/* === data === */

var server = Server.default;
var guiNetAddr = NetAddr("127.0.0.1",8080);
var synth = Array.newClear(128);
var pluck = true;

var unixString = "open /Applications/open-stage-control.app --args " ++      // must check for equivalent DOS commands, correct path on Windows machines
"--send 127.0.0.1:% ".format( NetAddr.localAddr.port ) ++
"--load '%'".format( "fmSynthGUI.json".resolveRelative );

server.waitForBoot({

	/* === resources === */


	/* === synthDefs === */

	SynthDef(\fmPluckSynth,{
		var freq = \freq.kr(60.midicps);
		var mod = SinOsc.ar(\modFreq.kr(1),mul: \index.kr(2));
		var car = LFSaw.ar(freq + mod);

		var sig = Splay.ar(car,1,\amp.kr(-18.dbamp));
		sig = sig * Env.perc(\atk.kr(0.01),\rls.kr(0.5),\velocity.kr(1),[\atkCrv.kr(-4),\rlsCrv.kr(-4)]).ar(2,\gate.kr(1));
		Out.ar(\out.kr(0),sig)
	}).add;


	SynthDef(\fmPadSynth,{
		var freq = \freq.kr(60.midicps);
		var mod = SinOsc.ar(\modFreq.kr(1),)
		var car = LFSaw.ar(freq,)

		sig = Splay.ar(sig,1,\amp.kr(-18.dbamp));
		sig = sig * Env.asr(\atk.kr(0.01),\velocity.kr(1),\rls.kr(0.5),[\atkCrv.kr(-4),\rlsCrv.kr(-4)]).ar(2,\gate.kr(1));
		Out.ar(\out.kr(0),sig)
	}).add;

	/* === OSC defs === */

	OSCdef(\midiToPitch,{ |msg|
		var midiNote = msg[1].midicps;
		var velocity = msg[2];               // should this be \db.asSpec scaled?

		// if(pluck == true,{
		Synth(\fmPluckSynth,[\freq, midiNote,\velocity,velocity])
		/*},{
		synth[midiNote] = Synth(\fmPadSynth,[])
		})*/

	},'/keyboard_1')

});

// unixString.unixCmd;
"fmSynth ready to go!".postln;
)

Env.perc(0.01, 0.1, 1, [-4,-4]).plot;

