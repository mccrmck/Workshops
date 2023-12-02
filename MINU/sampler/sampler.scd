/* === MINU 2023: sampler === */
(

var server = Server.default;
var guiNetAddr = NetAddr("127.0.0.1",8080);
var bufferDict = Dictionary();
var pbSynth;

var unixString = "open /Applications/open-stage-control.app --args " ++      // must check for equivalent DOS commands, correct path on Windows machines
"--send 127.0.0.1:% ".format( NetAddr.localAddr.port ) ++
"--load '%'".format( "samplerGUI.json".resolveRelative );

server.waitForBoot({
	var cond = CondVar();

	/* === resources === */

	// busses
	var bufnumBus    = Bus.control(server,1);
	var startEndBus  = Bus.control(server,2).setn([0,1]);
	var atkBus       = Bus.control(server,1).set(0.01);
	var rlsBus       = Bus.control(server,1).set(0.01);
	var rateBus      = Bus.control(server,1).set(1);
	var directionBus = Bus.control(server,1).set(1);
	var ampBus       = Bus.control(server,1).set(0);

	// load samples into buffers
	PathName("audio/".resolveRelative).entries.do({ |sample|
		var sampleKey = sample.fileNameWithoutExtension.asSymbol;

		fork{
			var waveData, buffer = Buffer.read(server,sample.fullPath,action:{ |buf| cond.signalOne });
			cond.wait{ buffer.numFrames.notNil };
			waveData  = FloatArray.newClear( buffer.numFrames * buffer.numChannels );
			SoundFile.use(buffer.path,{ |file| file.readData( waveData ) });
			waveData = waveData.resamp1(1000);                                                  // consider normalization, scaling, etc.
			bufferDict.put(sampleKey,(buffer: buffer, waveData: waveData));
		};
	});

	/* === synthDefs === */

	['mono','stereo'].do({ |key, index|

		var synthKey = (key ++ "SampleSynth").asSymbol;
		var numChannels = index + 1;

		SynthDef(synthKey,{
			var bufnum = \bufnum.kr();
			var frames = BufFrames.kr(bufnum);
			var pos = Phasor.ar(1,BufRateScale.kr(bufnum) * \rate.kr(1) * \direction.kr(1),\start.kr(0) * frames,\end.kr(1) * frames);
			var sig = BufRd.ar(numChannels, bufnum, pos);
			sig = Splay.ar(sig,1,\amp.kr(-18.dbamp));
			sig = sig * Env.asr(\atk.kr(0.01),1,\rls.kr(0.01),0).ar(2,\gate.kr(1));
			Out.ar(\out.kr(0),sig)
		}).add;
	});

	server.sync;

	/* === OSCdefs === */

	OSCdef(\startEnd,{ |msg|
		var start = msg[1];
		var end = msg[2];

		startEndBus.setn([start,end])

	},'/startEnd');

	OSCdef(\samples,{ |msg|
		var sampleKey = msg[1];
		var sampleInfo = bufferDict[sampleKey];

		bufnumBus.set( sampleInfo['buffer'].bufnum );
		guiNetAddr.sendMsg("/waveForm",*sampleInfo['waveData']);
		"sample: % loaded\n".format(sampleKey).postln;

	},'/samples');

	OSCdef(\atkKnob,{ |msg|
		var val = msg[1];
		val = val.linlin(0,1,0.001,10);

		atkBus.set( val );

	},'/knobs/0');

	OSCdef(\rlsKnob,{ |msg|
		var val = msg[1];
		val = val.linlin(0,1,0.001,10);

		rlsBus.set( val );

	},'/knobs/1');

	OSCdef(\rateKnob,{ |msg|
		var val = msg[1];
		val = val.linexp(0,1,0.25,4); // two octaves down, two octaves up

		rateBus.set( val )

	},'/knobs/2');

	OSCdef(\forwardsBackwards,{ |msg|
		var val = msg[1].asInteger;
		var direction = if(val == 1,{ -1 },{ 1 });

		directionBus.set( direction )

	},'/forwardsBackwards');

	OSCdef(\playStop,{ |msg|
		var val = msg[1].asInteger;
		var buffer = Buffer.cachedBufferAt(server,bufnumBus.getSynchronous);
		var synthKey = if(buffer.numChannels == 1,{ 'monoSampleSynth' },{ 'stereoSampleSynth' });

		if( val == 1,{
			pbSynth = Synth(synthKey,[\atk,atkBus.getSynchronous])
			.map(\bufnum,bufnumBus,\rate,rateBus,\direction,directionBus,\start,startEndBus.subBus(0),\end,startEndBus.subBus(1),\amp,ampBus)
		},{
			pbSynth.set(\gate,0,\rls,rlsBus.getSynchronous)
		})

	},'/playStop');

	OSCdef(\amp,{ |msg|
		var amp = msg[1];
		amp = \db.asSpec.map(amp).dbamp;
		ampBus.set( amp )

	},'/amp');

	OSCdef(\booted,{ |msg|
		guiNetAddr.sendMsg("/sampleList",*bufferDict.keys.asArray );
	},'/booted');

	server.sync;

	unixString.unixCmd;

	"\nsampler ready to go at:".postln;
	"ipconfig getifaddr en0".unixCmd
})
)