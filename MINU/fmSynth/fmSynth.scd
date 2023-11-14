/* === MINU 2023: fmSynth === */
(

/* === data === */

var server = Server.default;
var guiNetAddr = NetAddr("127.0.0.1",8080);
var filter = 0;

var unixString = "open /Applications/open-stage-control.app --args " ++      // must check for equivalent DOS commands, correct path on Windows machines
"--send 127.0.0.1:% ".format( NetAddr.localAddr.port ) ++
"--load '%'".format( "fmSynthGUI.json".resolveRelative );

server.waitForBoot({

	/* === resources === */

	var indexBus = Bus.control(server,1).set(1);
	var modMultBus = Bus.control(server,1).set(1);
	var lagBus = Bus.control(server,1).set(1);
	var rqBus = Bus.control(server,1).set(1);

	var atkBus    = Bus.control(server,1).set(0);
	var rlsBus    = Bus.control(server,1).set(1);
	var atkCrvBus = Bus.control(server,1).set(0.5);
	var rlsCrvBus = Bus.control(server,1).set(0.5);
	var ampBus    = Bus.control(server,1).set(0);


	/* === synthDefs === */

	SynthDef(\fmPluckSynth,{
		var carFreq = \carFreq.kr(440);
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
		sig = Select.ar(\filter.kr(0),[sig,RLPF.ar(sig,sig.abs.linexp(0,1,20,20000).lag(\lag.kr(0.01)),\rq.kr(0.5))]);
		sig = sig* -18.dbamp;
		sig = LeakDC.ar(sig).tanh;
		sig = Splay.ar(sig,1,\amp.kr(-18.dbamp));
		Out.ar(\out.kr(0),sig)
	}).add;

	/* === OSC defs === */

	OSCdef(\index,{ |msg|
		var val = msg[1];
		// val = val.linlin(0,1,1,10).round;
		indexBus.set( val )

	},'/index');

	OSCdef(\modMult,{ |msg|
		var val = msg[1];
		val = val.linlin(0,1,1,16).round;
		modMultBus.set( val )

	},'/modMult');

	OSCdef(\filter,{ |msg|
		var val = msg[1].asInteger;
		filter = val

	},'/filter');

	OSCdef(\lag,{ |msg|
		var val = msg[1];
		val = val.linlin(0,1,1,0.01);
		lagBus.set( val )

	},'/filterKnobs/0');

	OSCdef(\rq,{ |msg|
		var val = msg[1];
		val = val.linlin(0,1,1,0.05);
		rqBus.set( val )

	},'/filterKnobs/1');

	OSCdef(\atkKnob,{ |msg|
		var val = msg[1];

		atkBus.set( val );

	},'/knobs/0');

	OSCdef(\rlsKnob,{ |msg|
		var val = msg[1];

		rlsBus.set( val );

	},'/knobs/1');

	OSCdef(\atkCrvKnob,{ |msg|
		var val = msg[1];

		atkCrvBus.set( val )

	},'/knobs/2');

	OSCdef(\rlsCrvKnob,{ |msg|
		var val = msg[1];

		rlsCrvBus.set( val )

	},'/knobs/3');


	OSCdef(\keyboard,{ |msg|
		var midiNote = msg[1].midicps;
		var velocity = msg[2];               // should this be \db.asSpec scaled?

		Synth(\fmPluckSynth,[\carFreq, midiNote,\filter, filter, \velocity,velocity])
		.map(
			\modMult,modMultBus,
			\index,indexBus,
			\lag,lagBus,
			\rq,rqBus,
			\atk,atkBus,
			\rls,rlsBus,
			\atkCrv,atkCrvBus,
			\rlsCrv,rlsCrvBus,
			\amp,ampBus
		)
	},'/keyboard');

	OSCdef(\amp,{ |msg|
		var amp = msg[1];
		amp = \db.asSpec.map(amp).dbamp;
		ampBus.set( amp )

	},'/amp');


	unixString.unixCmd;
	"\nfmSynth ready to go!".postln;
	"ipconfig getifaddr en0".unixCmd

})
)


a = {"ipconfig getifaddr en0".unixCmd.postln}

// sig = Select.ar(\filter.kr(2),[sig, RLPF.ar(sig,\fFreq.kr(440),\rq.kr(0.2) ), RLPF.ar(sig,sig.abs.linexp(0,1,20,20000).lag(0.01),\rq.kr(0.2)) ]);
