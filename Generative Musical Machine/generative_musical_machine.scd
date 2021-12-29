


(
SynthDef(\help_mdapiano, { |out=0, freq=440, gate=1|
    var son = MdaPiano.ar(freq, gate, release: 0.9, stereo: 0.3, sustain: 0);
    DetectSilence.ar(son, 0.01, doneAction:2);
    Out.ar(out, son * 0.1);
}).add;
);

(

{ | atk = 0.01, dur = 0.15, freq = 50, amp=0.8 |
	BPF.ar(LFSaw.ar(freq), freq, 2, mul: EnvGen.kr( Env.perc( atk, dur-atk, amp, 6 ), doneAction: 2 )) ! 2;
}.asSynthDef.name_("bass").add;

{ | dur = 0.15, freq = 50, amp = 0.8, index = 10 |
	PMOsc.ar(freq, freq + 5, index, mul: amp * EnvGen.kr( Env.triangle( dur ), doneAction: 2 )) ! 2;
}.asSynthDef.name_("bazz").add;

);

(
SynthDef("pluck", {arg amp = 0.05, freq = 440, decay = 2, coef = 0.1;
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

);
(
SynthDef("sinplnk",{|freq| Out.ar([0,1], SinOsc.ar(freq) * EnvGen.kr(Env.perc, doneAction:2));}).add;
);

(
SynthDef(\saw, { |out=0, freq=440, gate = 1 |
    var env, son, filter;
	son = Saw.ar(freq, gate);
	// env = EnvGen.kr(Env.linen(attackTime:0, releaseTime:0.2, curve:-4), doneAction:2);
	env = EnvGen.kr( Env.perc( 0.06, 0.15, 1, 3), doneAction: 2 );
	filter = RLPF.ar(son, 1200, 0.6);
    DetectSilence.ar(filter, 0.01, doneAction:2);
	Out.ar(out, [filter * 0.1, filter * 0.1]);
}).add;
);

b = [\kick, \sd, \hh, \hH].collect{|val| Buffer.read(s,(val++".wav").resolveRelative) };


// a very simple sample-playing instrument.
SynthDef(\playBuf,
		{ |buffer, start = 0, dur = 0.25, amp = 0.7|
	var sig = PlayBuf.ar(1,buffer,startPos: start, loop: 0);
	var env = EnvGen.kr(Env.linen(0.01,dur,0.01,level:amp),doneAction:2);
	Out.ar(0,(sig*env) !2);
}
	).add;
Synth(\playBuf, [\buffer, b[0]]);


//bass duration generator
~gen_durs = {arg start;
	//rand for weighting
	var r = rrand(0.0,1.0);

	z = switch (start)
	{\whole} {

		if (r < 0.25, {~bass_durs.add(~dS.at(\whole));},
			{if (r < 0.5, {~gen_durs.value(\halfDot); ~gen_durs.value(\quarter);},
			{~gen_durs.value(\half); ~gen_durs.value(\half);});
			}
		);
	}
	{\halfDot} {

		if (r < 0.3, {~bass_durs.add(~dS.at(\halfDot));},
			{~gen_durs.value(\half); ~gen_durs.value(\quarter);}
		);
	}
	{\half} {
		if (r < 0.3, {~bass_durs.add(~dS.at(\half));},
			{~gen_durs.value(\quarter); ~gen_durs.value(\quarter);}
		);
	}
	{\quarterDot} {
		if (r < 0.3, {~bass_durs.add(~dS.at(\quarterDot));},
			{~gen_durs.value(\quarter); ~gen_durs.value(\eighth);}
		);
	}
	{\quarter} {
			if (r < 0.3, {~bass_durs.add(~dS.at(\quarter));},
			{~gen_durs.value(\eighth); ~gen_durs.value(\eighth);}
		);
	}
	{\eighth} {
		~bass_durs.add(~dS.at(\eighth));
	}



};


~gen_hats = {arg start;
	//rand for weighting
	var r = rrand(0.0,1.0);

	~hat_amps.add([0.25, 0.5, 0.75, 1.0].choose());
	z = switch (start)
	{\whole} {

		if (r < 0.25, {~hat_durs.add(~dS.at(\whole));},
			{if (r < 0.5, {~gen_hats.value(\halfDot); ~gen_hats.value(\quarter);},
			{~gen_hats.value(\half); ~gen_hats.value(\half);});
			}
		);
	}
	{\halfDot} {

		if (r < 0.3, {~hat_durs.add(~dS.at(\halfDot));},
			{~gen_hats.value(\half); ~gen_hats.value(\quarter);}
		);
	}
	{\half} {
		if (r < 0.3, {~hat_durs.add(~dS.at(\half));},
			{~gen_hats.value(\quarter); ~gen_hats.value(\quarter);}
		);
	}
	{\quarterDot} {
		if (r < 0.3, {~hat_durs.add(~dS.at(\quarterDot));},
			{~gen_hats.value(\quarter); ~gen_hats.value(\eighth);}
		);
	}
	{\quarter} {
			if (r < 0.3, {~hat_durs.add(~dS.at(\quarter));},
			{~gen_hats.value(\eighth); ~gen_hats.value(\eighth);}
		);
	}
	{\eighth} {
		~hat_durs.add(~dS.at(\eighth));
	}



};


~gen_bass = {arg root, cp, pattern, pitch, durs;
	pitch.clear();
	~duration = 0;
	//chord progression index
	~cpi = 0;

	~chord_prog_b = List[];
	~chord_prog_b.addAll(~degree_to_semis.value(cp));
	// ~chord_prog[2].postln;
	m = MarkovSet([
		[0, [0, 7, 12], [0.6, 0.2, 0.2]],
		[7, [0, 7, 12], [0.8, 0.1, 0.1]],
		[12, [0, 7, 12], [0.8, 0.1, 0.1]],
	]);
	m.makeSeeds;
	x = m.asStream;
	durs.size.do({arg i;
		var next;
		next = x.next;
		~duration = ~duration + (durs[i]);

		if (~duration > ~bar, {
				~cpi=~cpi+1;
				~duration = 0;});

		pitch.addAll(next + ~chord_prog_b[~cpi] + root);

		if (~duration >= ~bar, {
				~cpi=~cpi+1;
				~duration = 0;});


	});


};

~gen_lead_durs = {arg start;
	//rand for weighting
	var r = rrand(0.0,1.0);

	~lead_amps.add([0.2, 0.4, 0.5, 0.6, 0.8].choose());
	z = switch (start)
	{\whole} {

		if (r < 0.25, {~lead_durs.add(~dS.at(\whole));},
			{if (r < 0.5, {~gen_lead_durs.value(\halfDot); ~gen_lead_durs.value(\quarter);},
			{~gen_lead_durs.value(\half); ~gen_lead_durs.value(\half);});
			}
		);
	}
	{\halfDot} {

		if (r < 0.3, {~lead_durs.add(~dS.at(\halfDot));},
			{~gen_lead_durs.value(\half); ~gen_lead_durs.value(\quarter);}
		);
	}
	{\half} {
		if (r < 0.3, {~lead_durs.add(~dS.at(\half));},
			{~gen_lead_durs.value(\quarter); ~gen_lead_durs.value(\quarter);}
		);
	}
	{\quarterDot} {
		if (r < 0.3, {~lead_durs.add(~dS.at(\quarterDot));},
			{~gen_lead_durs.value(\quarter); ~gen_lead_durs.value(\eighth);}
		);
	}
	{\quarter} {
			if (r < 0.3, {~lead_durs.add(~dS.at(\quarter));},
			{~gen_lead_durs.value(\eighth); ~gen_lead_durs.value(\eighth);}
		);
	}
	{\eighth} {
		~lead_durs.add(~dS.at(\eighth));
	}



};


~gen_lead = {arg root, cp, pattern, pitch, durs;
	pitch.clear();
	~duration_l = 0;
	//chord progression index
	~cpi_l = 0;

	~chord_prog_l = List[];
	~chord_prog_l.addAll(~degree_to_semis.value(cp));
	// ~chord_prog[2].postln;
	f = MarkovSet([
		[0, [0, 4, 7, 9, 12], [0.3, 0.1,  0.2, 0.1, 0.2]],
		[4, [0, 4, 7, 9, 12], [0.2, 0.1,  0.3, 0.2, 0.1]],

		[7, [0, 4, 7, 9, 12], [0.4, 0.1,  0.2, 0.1, 0.1]],
		[9, [0, 4, 7, 9, 12], [0.2, 0.1,  0.2, 0.1, 0.2]],
		[12, [0, 4, 7, 9, 12], [0.4, 0.1,  0.2, 0.1, 0.1]],
	]);

	f.makeSeeds;
	y = f.asStream;
	durs.size.do({arg i;
		var next_l;
		next_l = x.next;
		~duration_l = ~duration_l + (durs[i]);

		if (~duration_l > ~bar, {
				~cpi_l=~cpi_l+1;
				~duration_l = 0;});

		pitch.addAll(next_l + ~chord_prog_l[~cpi_l] + root);

		if (~duration_l >= ~bar, {
				~cpi_l=~cpi_l+1;
				~duration_l = 0;});


	});


};

//scale degree to semitone
~degree_to_semis = {arg degree;
	Scale.major[degree - 1];
};

//get chord from degree
~get_chord = {arg degree;
	if (degree < 1, {"incorrect degree input".postln;});

	~chord = List[];
	~chord.add(Scale.major[0 + degree - 1]);
	~chord.add(Scale.major[2 + degree - 1]);
	~chord.add(Scale.major[4 + degree - 1]);
};


//degree starts with 1 as the tonic, get midi notes from degree
~get_midi_chord = {arg root, degree;
	~midi_chord = List[];
	~midi_chord = ~get_chord.value(degree) + root;

};

~random_chord = {arg root, degree;
	~midi_chord = List[];
	~midi_chord = ~get_chord.value(degree) + root;
	~possibles = List[];

	~possibles.addAll(~get_midi_chord.value(root - 12, degree));
	~possibles.addAll(~get_midi_chord.value(root, degree));
	~possibles.addAll(~get_midi_chord.value(root + 12, degree));
	~possibles = ~possibles.scramble;
	[~possibles[0], ~possibles[1], ~possibles[2], ~possibles[3], ~possibles[4]];
};



//normalize chord, so its in root position
~normalize = {arg chord;
	if(chord.size != 3, {"Incorrent chord size.".postln;},
		{
			if (chord[1] < chord[0], {chord[1] = chord[1] + 12;}, {chord[1] = chord[1];});
			if (chord[2] < chord[0], {chord[2] = chord[2] + 12;}, {chord[2] = chord[2];});
		}

)};

~get_cp = { arg root, prog;
	~out = List[];
	prog.do({arg item;

		~out.add(~random_chord.value(root, item));
	});

};

//generate chords and bass funciton
~gen = {arg root, res, kick_patt;

	~final = List[];
	~bass_line = List[];
	~bass_durs = List[];
	~kSym = List[]; // list for the kick drum
	~kDur = List[];
	~hat_durs = List[];
	~hat_amps = List[];
	~lead = List[];
	~lead_durs = List[];
	~lead_amps = List[];


	z = switch (kick_patt)
	{0} {~kSym = [\quarterDot, \eighth, \quarter, \quarter, \quarterDot, \eighth, \quarter, \quarter, \quarterDot, \eighth, \quarter, \quarter, \quarterDot, \eighth, \quarter, \quarter];}
	{1} {~kSym = [\halfDot, \quarter,
	\halfDot, \quarter,
	\halfDot, \quarter,
		\halfDot, \quarter];}
	{2} {~kSym = [\quarter, \quarter, \quarter, \quarter,
	\quarter, \quarter, \quarter, \quarter,
	\quarter, \quarter, \quarter, \quarter,
	\quarter, \quarter, \quarter, \quarter
	];}
	{3} {~kSym = [\halfDot, \quarter,
		\half, \quarterDot, \eighth,
		\halfDot, \quarter,
		\half, \quarterDot, \eighth];};


	//acceptable progressions
	~acc_progs = List[[1, 5, 6, 4], [1, 4, 5, 6], [2, 5, 1, 1], [1, 6, 4, 5], [1, 5, 3, 4], [2, 5, 1, 3]];

	//create kick duration
	~kSym.do({arg item; ~kDur.add(~dS.at(item))});

	//generate chord progression
	~chord_prog = List[];
	~chord_prog.addAll(~acc_progs.choose());
	res.addAll(~get_cp.value(root, ~chord_prog));
	~kSym.do({arg item; ~gen_durs.value(item);});
	~kSym.do({arg item; ~gen_hats.value(item);});
	~kSym.do({arg item; ~gen_lead_durs.value(item);});
	~gen_bass.value(root - 24, ~chord_prog, ~kSym, ~bass_line, ~bass_durs);
	~gen_lead.value(root, ~chord_prog, ~kSym, ~lead, ~lead_durs);

};


//USER INTERFACE:
//This is a simple, generative musical machine. All the user needs to do is choose a
//root note (first input) and a kick patter (third input), shown above.
//Tempo is adjustable below, but make sure to execute the code under it as well!

//Tempo in bpm
~t = 140;
~bar = 4*(60/~t);
~q_note = 60/~t;

//dictionary for note to time translation
~dS = Dictionary.newFrom(
	[\whole, 4*(60/~t), \halfDot, 3*(60/~t), \half, 2*(60/~t), \quarterDot, 1.5*(60/~t), \quarter, 60/~t, \eighthDot, 0.75*(60/~t), \eighth, 0.5*(60/~t)]);


//generate everything
~gen.value(62, ~final, 0);

//PLAY WITHOUT LEAD
Ppar([Pbind(\instrument, \help_mdapiano, \midinote, Pseq(~out, inf), \dur, ~bar),
	Pbind(\instrument, \playBuf, \dur, Pseq(~kDur, inf), \buffer, b[0], \amp, 1.0),
	Pbind(\instrument, \playBuf, \dur, Pseq(~hat_durs, inf), \buffer, b[2], \amp, Pseq(~hat_amps, inf)),
	Pbind(\instrument, \bass, \midinote, Pseq(~bass_line, inf), \dur, Pseq(~bass_durs, inf)),
]).play;

r = Recorder.new(s);
//PLAY WITH LEAD
Ppar([Pbind(\instrument, \help_mdapiano, \midinote, Pseq(~out, inf), \dur, ~bar),
	Pbind(\instrument, \playBuf, \dur, Pseq(~kDur, inf), \buffer, b[0], \amp, 1.0),
	Pbind(\instrument, \playBuf, \dur, Pseq(~hat_durs, inf), \buffer, b[2], \amp, Pseq(~hat_amps, inf)),
	Pbind(\instrument, \bass, \midinote, Pseq(~bass_line, inf), \dur, Pseq(~bass_durs, inf)),
	Pbind(\instrument, \sinplnk, \midinote, Pseq(~lead, inf), \dur, Pseq(~lead_durs, inf), \amp, Pseq(~lead_amps, inf))
]).play;

r.record(numChannels:2);
