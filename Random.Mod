MODULE Random;  (* Martin Reiser 1992 / Oberon microsystems 1995 / hk 2017, 2019 *)
(*
	Random Number Functions.
	Uses the multiplicative linear congruential algorithm by D.H. Lehmer, modified by Schrage.
	See page 9 of Reiser & Wirth, Programming in Oberon.
*)

	IMPORT Input,  (* only for Time(); in Project Oberon 2013 use 'Input := Kernel' *)
		Out, Math;

	VAR seed: INTEGER;  (* global variable *)

	PROCEDURE Uniform* (): REAL;
	(* Returns a uniformly distributed floating point value between 0.0 and 1.0 *)
		CONST a = 48271;  (* suggested by Joerg Straube: 48271 is prime, 16807 = 7^5 *)
			m = 2147483647;  q = m DIV a;  r = m MOD a;
	BEGIN
		seed := a * (seed MOD q) - r * (seed DIV q);
		IF seed <= 0 THEN seed := seed + m END;
		RETURN FLT(seed) * (1.0 / FLT(m))
	END Uniform;

	PROCEDURE Exp* (mu: REAL): REAL;
	(* Returns an exponentially distributed fp value with mean parameter mu *)
	BEGIN
		RETURN -Math.ln(Uniform()) / mu
	END Exp;

	PROCEDURE Int* (max: INTEGER): INTEGER;   (* hk 2017 *)
	(* Returns a random integer value between 0 and max, inclusive *)
	BEGIN
		RETURN FLOOR(FLT(max + 1) * Uniform() )
	END Int;

	PROCEDURE Range* (min, max: INTEGER): INTEGER;   (* hk 2017 *)
	(* Returns a random integer in the closed interval [min, max] *)
		VAR rn: INTEGER;
	BEGIN
		IF max <= min THEN
			Out.String("Invalid parameters in Random.Range"); Out.Ln
		ELSE
			rn := min + Int(max - min)
		END;
		RETURN rn
	END Range;

	PROCEDURE Randomize*;   (* hk 2017 *)
	BEGIN
		seed := Input.Time()
	END Randomize;

BEGIN
	Randomize  (* initial value of seed *)
END Random.
