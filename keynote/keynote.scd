(
var server = Server.default;
var guiNetAddr = NetAddr("localhost",8080);
var numMLPArgs = 33;
var mlpIndex = 4;

var unixString = "open /Applications/open-stage-control.app --args " ++
"--send 127.0.0.1:% ".format( NetAddr.localAddr.port ) ++
"--load '%'".format( "keynote.json".resolveRelative );

// server.options.device = "Dante Virtual Soundcard";

server.waitForBoot({

	var ampBus     = Bus.control(server).set(0);
	var inDataSet  = FluidDataSet(server);
	var outDataSet = FluidDataSet(server);
	var inValsBuf  = Buffer.alloc(server,2);
	var outValsBuf = Buffer.loadCollection(server,{rrand(0.0,1.0)} ! numMLPArgs);
	var folder = Platform.userExtensionDir +/+ "LisaColetteBysheim/neural/models/";
	var nn = PathName(folder).entries.collect({ |file,index|
		var mlp = FluidMLPRegressor(server);
		mlp.read(file.fullPath);
	});

	var predictPoints = {
		nn[mlpIndex].predictPoint(inValsBuf,outValsBuf,{

			outValsBuf.getn(0,numMLPArgs,{ |bufVals|
				guiNetAddr.sendMsg("/sliders",*bufVals)
			});
		});
	};

	var noiseSynth;

	SynthDef(\minuNoise,{
		var bufnum = \bufnum.kr;
		var val = FluidBufToKr.kr(bufnum,0,numMLPArgs);
		var sin = SinOsc.ar(val[1].linexp(0,1,1,12000),mul: val[2]);
		var saw = VarSaw.ar(val[3].linexp(0,1,1,12000),width: val[4], mul: val[5]);
		var square = LFPulse.ar(val[6].linexp(0,1,1,12000),width: val[7], mul: val[8] * 2,add:-1);
		var tri = LFTri.ar(val[9].linexp(0,1,1,12000), mul: val[10]);
		var osc = SelectX.ar(val[0].linlin(0,1,0,3),[sin,saw,square,tri]);
		var noise0 = SelectX.ar(val[11].linlin(0,1,0,2),[LFNoise0.ar(val[12].linlin(0,1,0.2,10)),LFNoise1.ar(val[13].linlin(0,1,0.2,10)),LFNoise2.ar(val[14].linlin(0,1,0.2,10))]);
		var noise1 = SelectX.ar(val[15].linlin(0,1,0,2),[LFNoise0.ar(val[16].linlin(0,1,0.2,10)),LFNoise1.ar(val[17].linlin(0,1,0.2,10)),LFNoise2.ar(val[18].linlin(0,1,0.2,10))]);
		var sig, sigL, sigR;

		var local = LocalIn.ar(2);

		sigL = VarSaw.ar(osc.linexp(-1,1,20,10000) * local[0].linlin(-1,1,0.01,200) + (val[19].linexp(0,1,80,2000) * noise0.range(1,val[20].linlin(0,1,2,10))),width:local[1].linlin(-1,1,0.01,0.8),mul: val[21]);
		sigL = RLPF.ar(sigL,val[22].linexp(0,1,20,20000),val[23].linlin(0,1,2.sqrt,0.01)).tanh;
		sigL = sigL + CombC.ar(sigL,0.25,val[24].linexp(0,1,0.01,0.25).lag(0.01),val[25]);

		sigR = VarSaw.ar(osc.linexp(-1,1,20,10000) * local[1].linlin(-1,1,0.01,200) + (val[26].linexp(0,1,80,2000) * noise1.range(1,val[27].linlin(0,1,2,10))),width:local[0].linlin(-1,1,0.01,0.8),mul: val[28]);
		sigR = RLPF.ar(sigR,val[29].linexp(0,1,20,20000),val[30].linlin(0,1,2.sqrt,0.01)).tanh;
		sigR = sigR + CombC.ar(sigR,0.25,val[31].linlin(0,1,0.01,0.25).lag(0.01),val[32]);

		sig = [sigL,sigR];
		LocalOut.ar(sig);
		sig = LeakDC.ar(sig).tanh * -6.dbamp;
		sig = MSMatrix.ar(sig);
		sig[1] = sig[1] * -3.dbamp;
		sig = MSMatrix.ar(sig);
		sig = Squish.ar(sig,sig,-12,0.01,0.1,3,0.04,3);
		sig = sig * Env.asr(\atk.kr(0.01),1,\rls.kr(1),\curve.kr(10)).ar(2,\gate.kr(1));
		Out.ar(\out.kr(), sig  * \amp.kr(0));
	}).add;

	server.sync;

	OSCdef(\sliders,{ |msg|
		var val = msg[1..];
		outValsBuf.setn(0,val);

	},'/sliders');

	OSCdef(\mlpSwitch,{ |msg|
		var val = msg[1];

		mlpIndex = val;
		predictPoints.value;
	},'/mlpSwitch');

	OSCdef(\noiseXY,{ |msg|
		var vals = msg[1..];

		inValsBuf.setn(0,vals);
		predictPoints.value;
	},'/noiseXY');

	OSCdef(\noiseamp,{ |msg|
		var val = msg[1];
		val = \db.asSpec.map(val).dbamp;

		ampBus.set( val )

	},'/noiseAmp');

	OSCdef(\startStop,{ |msg|
		var val = msg[1].asInteger;

		if( val == 1,{
			noiseSynth = Synth(\minuNoise,[\bufnum,outValsBuf]).map(\amp,ampBus)

		},{
			noiseSynth.release(1)
		})
	},'/startStop');

	OSCdef(\loadGUI,{ |msg|

		guiNetAddr.sendMsg("/numArgs",numMLPArgs);
		guiNetAddr.sendMsg("/mlpArray",*(0..(nn.size-1)));
		predictPoints.value

	},'/loaded');

	unixString.unixCmd;
	"ipconfig getifaddr en0".unixCmd
});
)
