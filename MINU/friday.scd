

b = Buffer.read(s,"/Users/mikemccormick/Desktop/GHOST samples/stereo/keys 13 copy 2.wav")
~violin = Buffer.read(s,"/Users/mikemccormick/Desktop/GHOST samples/stereo/ciaccona.aiff")
b.numChannels
b.bufnum


(
SynthDef(\newSynth,{
	var bufnum = \bufnum.kr();
	var sig = PlayBuf.ar(2,bufnum,BufRateScale.kr(bufnum) * \rate.kr(1),loop: 1);
	sig = (sig * \gain.kr(1)).tanh;
	sig = sig * \amp.kr(1);
	Out.ar(0,sig)
}).add
)

x = Synth(\newSynth,[\bufnum,b])
x.set(\rate,0.2,\gain,40.dbamp,\amp,-18.dbamp)
x.set(\bufnum,~violin,\rate,0.1)



(
OSCdef(\onOff,{ arg msg;
	var val = msg[1];

	if(val == 1,{
		~synth = Synth(\newSynth,[\bufnum,~violin])
	},{
		~synth.free
	})

},'/startStop');

OSCdef(\amp,{ arg msg;
	var val = msg[1];

	~synth.set(\amp,val)

},'/amp');

OSCdef(\gain,{ arg msg;
	var val = msg[1];
	val = val.linlin(0,1,1,100);

	~synth.set(\gain,val)

},'/gain');

OSCdef(\rate,{ arg msg;
	var val = msg[1];
	val = val.linexp(0,1,0.25,4);
	~synth.set(\rate,val)

},'/rate');
)














