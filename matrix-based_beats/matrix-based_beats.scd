(

s.waitForBoot {


//Tempo, adjust tempo by changing the first number, DEFAULT: 100
t = TempoClock.default; // the default clock
t.tempo = 100/60; // 100 beats per second

//loading in our sounds...
b = [\kick, \sd, \hh, \rim, \perc].collect{|val| Buffer.read(s,(val++".wav").resolveRelative) };


//Initializing sample palying instrument
//Edit the 3rd argument of "PlayBuf.ar(2,buffer, 2, startPos: start, loop: 0);" to change
//the sample rate. DEFAULT: 1. If it's 2 it will be an octave up, if 0.5 an octave down.
SynthDef(\playBuf,
		{ |buffer, start = 0, dur = 0.25, amp = 1|
	var sig = PlayBuf.ar(2,buffer,1, startPos: start, loop: 0);
	var env = EnvGen.kr(Env.linen(0.01,dur,0.01,level:amp),doneAction:2);
	Out.ar(0,(sig*env) !2);
}
	).add;




	 //input spec

	 //functions
	 //evens, used for evens transformation
	e = {arg x;
	 	z = Array.newFrom(x);

	 	z.do({arg item, i;
	 		// [i, i % 2].postln;
	 		if (i % 2 == 1,
	 			{
	 			z[i] = Rest(0.25);},
	 		{})
	 	});
	 	z;
	 };

	 //odds, used for odds transformation
	 o = {arg x;
	 	z = Array.newFrom(x);
	 	z.do({arg item, i;
	 		// [i, i % 2].postln;
	 		if (i % 2 == 0,
	 			{
	 			z[i] = Rest(0.25);},
	 		{})
	 	});
	 	z;
	 };


	//double function, doubles second sound with first sound, adds second sound wherever first sound is in beat.
	 d = {arg a, x, y;
	 	z = Array.newFrom(a);
	 	z.do({arg item, i;
	 		if (z[i] == x,
	 			{z[i] = [x,y];},
	 		{});
	 	});
	 	z;
	 };



	 //shift function to not overwrite original pattern
	h = {arg x, y;
	 	z = Array.newFrom(x);
	 	z.shift(y);
	 };

//basic beat patterns, uncomment and fill last one for user input.
//DEFAULT PATTERN: Simple kick, hat, snare pattern
	// ~p = [\k, \h, \h, \h, \s, \h, \h, \h];


//Kick in snare pattern, try doubling the kick with a hat for a cool effect!
	// ~p = [\k, Rest(0.25),  [\k, \s],  Rest(0.25), \k,  Rest(0.25),  [\k, \s],  Rest(0.25)];

//Perc and rim pattern, sounds like a fun breakdown if you double to perc with a kick!
	// ~p = [\perc, \rim, \rim, \perc, \perc, \rim, \rim, \perc];


//Fun, groovy pattern
	~p = [\k, \h, \rim, \h, \s, \k, Rest(0.25), \h];

//Kick, perc and snare pattern
	// ~p = [\k, Rest(0.25), Rest(0.25), \perc, \s, Rest(0.25), \perc, Rest(0.25)];

//User beat pattern, make whatever you would like!
	//the options are \k, \h, \s, \perc, \rim and Rest(0.25), each beat consists of 8 sounds
	//~p = [];

//Four on the floor kick pattern
	// ~p = [\k, \k, \k, \k, \k, \k, \k, \k];





	//transformations
	 ~p_reverse = ~p.reverse();
	 //Transformation to replace first arg with second.
	 ~p_replaced = ~p.replace(\, \perc);
	 ~p_evens = e.value(~p);
	 ~p_odds = o.value(~p);
	 ~p_scrambled = ~p.scramble();
	 ~p_mirrored = ~p.mirror();

	 //Change \k and \h to decide which sounds you want to be doubled. The second will double the first.
	 ~p_doubled = d.value(~p, \k, \h);

	 //Shift pattern. Change the second arg to decide how much to shift the pattern by!
	 ~p_shifted = h.value(~p, 2);

	 //USER INPUT transformation: Edit this line to make your own pattern!
	~p_user_transformation = ~p_replaced.mirror();





//Uncomment whatever patterns you would like to add to the beat.
//If you only want to hear one pattern on repeat, comment out the rest.
	~input_spec = List[];
	// ~input_spec.addAll(~p);
	// ~input_spec.addAll(~p_reverse);
	// ~input_spec.addAll(~p_replaced);
	// ~input_spec.addAll(~p_evens);
	// ~input_spec.addAll(~p_odds);
	// ~input_spec.addAll(~p_mirrored);
	// ~input_spec.addAll(~p_scrambled);
	~input_spec.addAll(~p_doubled);
	// ~input_spec.addAll(~p_shifted);
	// ~input_spec.addAll(~p_user_transformation);
	~input_spec.postln;


//Arrays that will be filled with the pattern for each sound
~k = List[]; // list for the kick drum
~s = List[]; // list for the snare drums
~h = List[]; // list for the hi-hat
~rim = List[]; // list for rim shot
~perc = List[]; //list for perc hit

//Amplitude arrays, edit these as you please to create accents and texture.
//DEFAULT kick:
~k_amp = List[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
//User inputed kick amps
	// ~k_amp = List[1.0, 0.5, 1.0, 0.5, 1.0, 0.5, 1.0, 0.5];
//DEFAULT snare:
~s_amp = List[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
//User inputed snare amps
	// ~s_amp = List[0.75, 0.5, 0, 0.5, 0, 0.5, 1.0, 0.5];
//DEFAULT hat:
	// ~h_amp = List[0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
//User input hat amps, ON to show accents for basic beat
~h_amp = List[0.5, 0.25, 0.5, 0.75, 0.5, 0.25, 0.5, 0.75];
//DEFAULT rim:
~rim_amp = List[0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35];
//User input rim amp
	// ~rim_amp = List[0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35];
//DEFAULT perc:
~perc_amp = List[0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55];
//User input perc amp
	// ~perc_amp = List[0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55];



//function to check if sound is in list (for simultaneous sounds)
n = {arg x, y;
	var within = 0;

	x.do({arg item, i;
			if(x[i] == y,
				{within = 1;},
				{});
		});
	within;
	};

//Adding all the sounds to their respective arrays
~input_spec.size.do {|i|
	var curr = ~input_spec[i];

	if(~input_spec[i].class == Array,
	{
			if (n.value(~input_spec[i], \k) == 1, {~k.add(0.25)}, {~k.add(Rest(0.25))});
			if (n.value(~input_spec[i], \s) == 1, {~s.add(0.25)}, {~s.add(Rest(0.25))});
			if (n.value(~input_spec[i], \h) == 1, {~h.add(0.25)}, {~h.add(Rest(0.25))});
			if (n.value(~input_spec[i], \rim) == 1, {~rim.add(0.25)}, {~rim.add(Rest(0.25))});
			if (n.value(~input_spec[i], \perc) == 1, {~perc.add(0.25)}, {~perc.add(Rest(0.25))});
			},
	{
			if (curr == \k, {~k.add(0.25)}, {~k.add(Rest(0.25))});
			if (curr == \s, {~s.add(0.25)}, {~s.add(Rest(0.25))});
			if (curr == \h, {~h.add(0.25)}, {~h.add(Rest(0.25))});
			if (curr == \rim, {~rim.add(0.25)}, {~rim.add(Rest(0.25))});
			if (curr == \perc, {~perc.add(0.25)}, {~perc.add(Rest(0.25))});
		});
};


//uncomment if you want to see full sound arrays!

/*~k.postln; // the kick line -- feed to \kick
~s.postln;
~h.postln;
~rim.postln;
~perc.postln;*/




/* --- Pattern classes to play your beats --- */

	~kick = Pbind(\instrument, \playBuf, \dur, Pseq(~k, inf), \buffer, b[0], \amp, Pseq(~k_amp, inf));
	~snare = Pbind(\instrument, \playBuf, \dur, Pseq(~s, inf), \buffer, b[1], \amp, Pseq(~s_amp, inf));
	~hat = Pbind(\instrument, \playBuf, \dur, Pseq(~h, inf), \buffer, b[2], \amp, Pseq(~h_amp, inf));
	~rim = Pbind(\instrument, \playBuf, \dur, Pseq(~rim, inf), \buffer, b[3], \amp, Pseq(~rim_amp, inf));
	~perc = Pbind(\instrument, \playBuf, \dur, Pseq(~perc, inf), \buffer, b[4], \amp, Pseq(~perc_amp, inf));

	s.sync;

	//Everything is in place, now lets jam!
	Ppar([~kick, ~snare, ~hat, ~rim, ~perc], inf).play;
s.record(duration: 10);
}

)



