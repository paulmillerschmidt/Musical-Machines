

//synth defs
(
SynthDef("pluck", {arg amp = 0.1, freq = 440, decay = 2, coef = 0.1;
	var env, snd;
	env = EnvGen.kr(Env.linen(0, decay, 0), doneAction: 2);
	snd = Pluck.ar(
		in: WhiteNoise.ar(amp),
		trig: Impulse.kr(0),
		maxdelaytime: 0.1,
		delaytime: freq.reciprocal,
		decaytime: decay,
		coef: coef);
	Out.ar(0, [snd, snd]);
}).add;

)



(
SynthDef(\saw, { |out=0, freq=440, gate = 1 |
    var env, son, filter;
	son = Saw.ar(freq, gate);
	// env = EnvGen.kr(Env.linen(attackTime:0, releaseTime:0.2, curve:-4), doneAction:2);
	env = EnvGen.kr(Env.linen(0, 2, 0), doneAction: 2);
	filter = RLPF.ar(son, 1200, 0.6);
    DetectSilence.ar(filter, 0.01, doneAction:2);
	Out.ar(out, [filter * 0.1, filter * 0.1]);
}).add;
)


(
SynthDef("sinplnk",{|freq| Out.ar([0,2], SinOsc.ar(freq) * EnvGen.kr(Env.perc, doneAction:2));}).add;
)





e = SimpleMIDIFile.read("988-aria.mid".resolveRelative);
e.p(\sinplnk).play;


//each section should be one minute
//bpm of 120, so each section should have 120 beats
//each section will have 8 measures, so 15beats per measure, or 15second measures
~sections = List[0, 1, 2];

n = e.generatePatternSeqs;

//pitch and duration array
~p = List[];
~d = List[];
~pitch_arrays = List[];
~duration_arrays = List[];



n.size.do { |i|

	//randomly add rests, add a rest 5% of the time
if ((rrand(0,20) <= 1), {
		~p.add(Rest());
		//add a duration for the rest at random from the midi
		~d.add(n[1].choose[1]);
	},
	{
		~p.add(n[1][i][0]);
		~d.add(n[1][i][1]);
		});
}





//training data
m = MarkovSet.fill(~p.size, Pseq(~p.asArray, inf));
o = MarkovSet.fill(~d.size, Pseq(~d.asArray, inf));
m.makeSeeds;
o.makeSeeds;

x = m.asStream;
q = o.asStream;


//arrays
~s1_I1_pitches = List[];
~s1_I1_durations = List[];
~s1_I1_amps = List[];

~s2_I1_pitches = List[];
~s2_I1_durations = List[];
~s2_I2_pitches = List[];

~s3_I1_pitches = List[];
~s3_I1_durations = List[];
~s3_I1_amps = List[];

~pitch_temp = List.new(100);
~duration_temp = List.new(100);
~amps_temp = List.new(100);

//Run this loop to generate our new data
~sections.do { |i|


	//section one
	if (i == 0, {
		//generate some pitch and duratino information, while duration is less than a bar
		//fill multiple measures worth, first section is 4

		6.do {

		//while we are still filling a measure, add
		while ({~duration_temp.sum < 15}, {
		~pitch_temp.add(x.next);
		~duration_temp.add(q.next);
		~amp = 127.30.rand.round();
		~amps_temp.add(~amp);
		});
		//add the last note
		~pitch_temp.add(x.next);
		~duration_temp.add(15 - ~duration_temp.sum);
		~amp = 127.30.rand.round();
		~amps_temp.add(~amp);
		//add all notes to section one informations
		~s1_I1_pitches.addAll(~pitch_temp);
		~s1_I1_durations.addAll(~duration_temp);
		~s1_I1_amps.addAll(~amps_temp);
		//clear temporaries
		~pitch_temp.clear();
		~duration_temp.clear();
		~amps_temp.clear();
		};

	});

	//section two
	if (i == 1, {

		//fill the first instrument
		4.do {

			//while we are still filling a measure, add
			while ({~duration_temp.sum < 15}, {
				~pitch_temp.add(x.next);
				~duration_temp.add(q.next);
			});
			//add the last note
			~pitch_temp.add(x.next);
			~duration_temp.add(15 - ~duration_temp.sum);
			//add all notes to section one informations
			~s2_I1_pitches.addAll(~pitch_temp);
			~s2_I1_durations.addAll(~duration_temp);
			//clear temporaries
			~pitch_temp.clear();
			~duration_temp.clear();

		};

		//fill the second instrument, go through the pitches of the first inst
		~s2_I1_pitches.size.do {

			//add more rests so the bass is more of a counterpoint
			if ((rrand(0,1) == 1), {
				~new_note = x.next - 12;
				~s2_I2_pitches.add(~new_note);},
				{
					~s2_I2_pitches.add(Rest());
			});

		};
	});

	//section three
	if (i == 2, {

		//new data set, reparameterize so we draw from only greater than C4
		~new_p = List[];
		~p.do { |i|
			if ((i >= 72), {
				~new_p.add(i)});
		};
		//set up markov chain
		t = MarkovSet.fill(~new_p.size, Pseq(~new_p.asArray, inf));
		t.makeSeeds;
		w = t.asStream;

		//last section we go double time
		8.do {

		//while we are still filling a measure, add
		while ({~duration_temp.sum < 7.5}, {
				// w.next.postln;
		~pitch_temp.add(w.next);

		~new_dur = q.next / 2;
		~duration_temp.add(~new_dur);
		~amp = 127.30.rand.round();
		~amps_temp.add(~amp);
		});
		//add the last note
		~pitch_temp.add(w.next);
		~duration_temp.add(7.5 - ~duration_temp.sum);
		~amp = 127.30.rand.round();
		~amps_temp.add(~amp);
		//add all notes to section one informations
		~s3_I1_pitches.addAll(~pitch_temp);
		~s3_I1_durations.addAll(~duration_temp);
		~s3_I1_amps.addAll(~amps_temp);
		//clear temporaries
		~pitch_temp.clear();
		~duration_temp.clear();
		~amps_temp.clear();



		};



	});


};

(
r = Recorder.new(s);
//play section one
Pbind(\instrument, \pluck, \midinote, Pseq(~s1_I1_pitches, 1), \dur, Pseq(~s1_I1_durations), \vel, Pseq(~s1_I1_amps, 1)).play;
r.record(numChannels:2);
)


(
r = Recorder.new(s);
//play section two
Ppar([Pbind(\instrument, \pluck, \midinote, Pseq(~s2_I1_pitches, 1), \dur, Pseq(~s2_I1_durations), \vel, 100), Pbind(\instrument, \sinplnk, \midinote, Pseq(~s2_I2_pitches, 1), \dur, Pseq(~s2_I1_durations), \vel, 5)]).play;
r.record(numChannels:2);
)

(
//play sections three
r = Recorder.new(s);
Ppar([Pbind(\instrument, \saw, \midinote, Pseq(~s3_I1_pitches, 1), \dur, Pseq(~s3_I1_durations), \vel, Pseq(~s3_I1_amps, 1)), Pbind(\instrument, \saw, \midinote, Pseq(~s3_I1_pitches - 12, 1), \dur, Pseq(~s3_I1_durations), \vel, Pseq(~s3_I1_amps, 1))]).play;

r.record(numChannels:2);
)



