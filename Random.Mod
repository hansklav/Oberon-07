MODULE Random;  (* Martin Reiser 1992 / Oberon microsystems 1995 / hk 2017, 2019, 2023 *)
(*
	Random Number Functions.
	Uses the multiplicative linear congruential algorithm by D.H. Lehmer, modified by Schrage.
	See page 9 of Reiser & Wirth, Programming in Oberon.
*)

	IMPORT Input,  (* only for Time(); in Project Oberon 2013 use 'Input := Kernel' or 'Input := Oberon' *)
		Out, Math;

	VAR seed: INTEGER;  (* global variable *)

	PROCEDURE Uniform*( ): REAL;
	(* Returns a uniformly distributed floating point value in the half open interval [0.0 and 1.0) *)
		CONST a = 48271;  (* suggested by Joerg Straube: 48271 is prime, 16807 = 7^5 *)
			m = 2147483647;  (* 2^31 - 1 *)
			q = m DIV a;  r = m MOD a;
	BEGIN
		seed := a * (seed MOD q) - r * (seed DIV q);
		IF seed <= 0 THEN seed := seed + m END
		RETURN FLT(seed) * (1.0 / FLT(m))
	END Uniform;

	PROCEDURE Exp*(mu: REAL): REAL;
	(* Returns an exponentially distributed fp value with mean parameter mu *)
	BEGIN
		RETURN -Math.ln(Uniform()) / mu
	END Exp;

	PROCEDURE Range* (length: INTEGER): INTEGER;   (* hk 2023 *)
	(* Returns a random integer N such that 0 <= N <= (length - 1) *)
	BEGIN
		RETURN FLOOR(FLT(length) * Uniform() )
	END Range;

	PROCEDURE Int* (min, max: INTEGER): INTEGER;   (* hk 2023 *)
	(* Returns a random integer N such that min <= N <= max *)
		VAR rn: INTEGER;
	BEGIN
		IF max <= min THEN
			Out.String("Invalid parameters in Random.Int"); Out.Ln
		ELSE
			rn := min + Range(max - min + 1)
		END
	RETURN rn
	END Int;

	PROCEDURE InitSeed* (s: INTEGER);  (* hk 2023 *)
	(* If you initialize with the same seed s before calling one of the above functions
	   then the same random number sequence will be produced repeatedly *)
	BEGIN
		IF s = 0 THEN seed := 1 ELSE seed := s END
	END InitSeed;

	PROCEDURE Randomize*;   (* hk 2017 *)
	BEGIN
		seed := Input.Time()
	END Randomize;

BEGIN
	Randomize  (* initial value of seed *)
END Random.
