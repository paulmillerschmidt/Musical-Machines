


s.boot;

//Pluck synthdef
(
SynthDef("pluck", {arg amp = 0.1, freq = 440, gate = 1, decay = 2, coef = 0.1;
	var env, snd;
	env = EnvGen.kr(Env.linen(0, decay, 0), gate, doneAction: 2);
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

//Piano synthdef
(
SynthDef(\help_mdapiano, { |out=0, freq=440, gate=1|
    var son = MdaPiano.ar(freq, gate, release: 0.9, stereo: 0.3, sustain: 0);
    DetectSilence.ar(son, 0.01, doneAction:2);
    Out.ar(out, son * 0.1);
}).add;
);




//degree starts with 1 as the tonic, get chord from degree
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

//normalize chord, so its in root position
~normalize = {arg chord;
	if(chord.size != 3, {"Incorrent chord size.".postln;},
		{
			if (chord[1] < chord[0], {chord[1] = chord[1] + 12;}, {chord[1] = chord[1];});
			if (chord[2] < chord[0], {chord[2] = chord[2] + 12;}, {chord[2] = chord[2];});
		}

)};

//get chord progression midi from root and roman numeral prog
~get_cp = { arg root, prog;
	~out = List[];
	prog.do({arg item;
		~out.add(~normalize.value(~get_midi_chord.value(root, item)));
	});
	~out;
};

//acceptable progressions
~acc_progs = List[[1, 5, 6, 4], [1, 4, 5, 6], [2, 5, 1, 1], [1, 6, 4, 5], [1, 5, 3, 4], [2, 5, 1, 3]];

//acceptable modulationss
~cg_mods = List[[1, 5, 2, 6], [1, 3, 6, 4]];
~cf_mods = List[[1, 4, 2, 5], [1, 6, 2, 5]];

~gc_mods = List[[1, 5, 6, 4], [1, 3, 4, 6]];
~fc_mods = List[[1, 4, 3, 5], [1, 5, 3, 6]];

//starting with F
~fg_mods = List[[1, 6, 3, 5], [1, 4, 5, 3]];
~gf_mods = List[[1, 6, 2, 4], [1, 5, 4, 2]];



//generate functions, generate progressions and modulations
~gen = {arg res, root;
	res.addAll(~get_cp.value(root, ~acc_progs.choose()));
};

~mod_c_g = {arg res;
	res.addAll(~get_cp.value(60, ~cg_mods.choose()));
};

~mod_c_f = {arg res;
	res.addAll(~get_cp.value(60, ~cf_mods.choose()));
};


~mod_g_c = {arg res;
	res.addAll(~get_cp.value(55, ~gc_mods.choose()));
};

~mod_f_c = {arg res;
	res.addAll(~get_cp.value(53, ~fc_mods.choose()));
};

~mod_f_g = {arg res;
	res.addAll(~get_cp.value(53, ~fg_mods.choose()));
};

~mod_g_f = {arg res;
	res.addAll(~get_cp.value(55, ~gf_mods.choose()));
};


//handle user input
~handle_input = {arg symbol_arr, final;
	symbol_arr.do({arg item, i;
		switch (item,
			\gen_c, {~gen.value(final, 60)},
			\gen_g, {~gen.value(final, 55)},
			\gen_f, {~gen.value(final, 53)},
			\mod_cg, {~mod_c_g.value(final)},
			\mod_cf, {~mod_c_f.value(final)},
			\mod_gc, {~mod_g_c.value(final)},
			\mod_gf, {~mod_g_f.value(final)},
			\mod_fc, {~mod_f_c.value(final)},
			\mod_fg, {~mod_f_g.value(final)},
			{"incorrect symbol input".postln;});
	});
};



//Transformations
~arp = {arg temp;
	~out = List[];
	temp.do({arg item, i;
		~out.addAll(temp[i]);
	});
	~out;
};

~bassify = {arg out;
	out.do({arg item, i;
		item.addFirst(item[0] - 12);
	});
};

~transpose = {arg out, semis;
	out.do({arg item, i;
		out[i] = item + semis;
	});
};

~octave = {arg out, octaves;
	out.do({arg item, i;
		out[i] = item + (12*octaves);
	});
};


~invert = {arg out, type;
	out.do({arg item, i;
		item[0] = item[0] + 12;
		if (type == 2,
			{item[1] = item[1] + 12;});

	});
};


//USER INTERFANCE - Run these to reset the key variables
~final = List[];
~dur = 1;
~instrument = \help_mdapiano;


//change the symbol array to choose what progressions you want!!
~user_input = List[\gen_c, \gen_c, \mod_cg, \gen_g, \gen_g, \mod_gf, \gen_f, \gen_f];
//run this line to set up the machine
~handle_input.value(~user_input, ~final);


//uncomment these transformations for some cool effects

//transposition: change the transpose value to decide how many semitones to transpose the progression
~transpose_val = 4;
~transpose.value(~final, ~transpose_val);

//Octave: transpose octaves up or down
~octave_val = -1;
~octave.value(~final, ~octave_val);

//Invert
~invert.value(~final, 2);

//bassify: adds a fun bass to the chord
~bassify.value(~final);

//PluckIt: changes instruments to a pluck
~instrument = \pluck;

//Arp: make an arpeggio out of the chords
~final = ~arp.value(~final);
~dur = 0.25;



//Run this line to hear our result!!
Pbind(\instrument, ~instrument, \midinote, Pseq(~final, 1), \dur, ~dur).play;
s.record;






