MODULE Math;
(* hk 10 Aug. 2022	(32-bit version)                                                         *)
(* The missing (imho) arctan(x), and some additional constants and functions for convenience *)
(* Procedures sqrt, exp, ln, sin, cos already present in module Math by NW 12.10.2013        *)

	CONST
		pi* = 3.14159265358979323846;
		e* = 2.71828182845904523536;

	PROCEDURE power* (x, b: REAL): REAL;
	(** Returns x to the power b (x^b) *)
	BEGIN ASSERT(x > 0.0)
	RETURN exp(b * ln(x))
	END power;

	PROCEDURE log* (x, b: REAL): REAL;
	(** Returns the logarithm of x base b *)
	BEGIN ASSERT(x > 0.0)
	RETURN ln(x) / ln(b)
	END log;

	PROCEDURE tan* (x: REAL): REAL;
	(** Returns the tangent of x radians *)
	BEGIN
	RETURN sin(x) / cos(x)
	END tan;
  
	PROCEDURE arctan* (x: REAL): REAL;
	(** Returns the arctangent (inverse tangent) in radians of x *)
	(*	ETH Oberon, (C) 2001 ETH Zuerich Institut fuer Computersysteme *)
		CONST				 
			c51 =	 2.41421365738;     (* 1 + sqrt(2) *)
			c52 =	 4.14213567972E-1;  (* sqrt(2) - 1 *)
			s51 =	 1.57079637051;	    (* pi/2 *)
			s52 =	 7.85398185253E-1;  (* pi/4 *)
			p50 =	 6.36918878555;
			q50 =	 1.98769211769;
			q51 = -4.43698644638;
			q52 =	 8.60141944885;
		VAR y, yy, s: REAL;
	BEGIN
		y := ABS(x);  s := 0.0;
		IF y > c51 THEN y := -1.0/y;  s := s51
		ELSIF y > c52 THEN y := (y - 1.0) / (y + 1.0);  s := s52
		END;
		yy := y*y;
		y := p50 * y / (yy + q52 + q51 / (yy + q50)) + s;
		IF x < 0.0 THEN y := -y END
	RETURN y
	END arctan;

END Math.
