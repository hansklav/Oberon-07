MODULE Hennessy;	 (* IN V5 *)																											
(*                                                                          Hennessy.Do
		Also known as the Stanford Benchmark Suite.

		This is a suite of benchmarks that are relatively short, both in program
		size and execution time. It requires no input, and prints the execution
		time for each program, using the system-dependent routine Getclock,
		below, to find out the current CPU time. It does a rudimentary check to
		make sure each program gets the right output. These programs were
		gathered by John Hennessy and modified by Peter Nye.
		
		Used in the '80s for comparison of the first (MIPS) RISC processors with 
		CISC processors, and still part of e.g. the LLVM test-suite.
		
		This Oberon-07 implementation was adapted from an Oberon (1990) version
		and a C source 'stanford.c', which can be found (March 2020) here:
		https://classes.engineering.wustl.edu/cse465/docs/BCCExamples/stanford.c
		https://github.com/hdantas/leon3-processor/blob/master/benchmarks/Stanford/stanford.c
		I could not find a copy of the original Pascal source on the web.
		
		* Oberon: J. Templ, 26.2.90 
		* Oberon-07: Hans Klaver, March 2020 (modifications by Joerg Straube, August Karlstrom and Chris Burrows)
		- Made a few corrections to get reference output according to the LLVM test-suite:
			 https://github.com/microsoft/test-suite/tree/master/SingleSource/Benchmarks/Stanford
		- Changed WHILE loops back to FOR loops where appropriate.
		- Added the CONST 'runs' and 'm'
		- Added a conditional clause and an extra 'reference output' to the Tree benchmark (procedure Trees)
		- Corrected the calculation of the 'Nonfloating-point composite': divisor = 8.0
		- Added geometric means as better summary statistics than the original 'composite' values.
		- Some more changes specific for Oberon System V5 (Kernel.Time, Out1.SetFont)
*)

	IMPORT 
		Kernel,  (* i.a. for Kernel.Time; in Oakwood compliant systems use Input.Time instead *)
		Oberon,  (* for Oberon.Collect in Trees *)
		Out := Out1,  (* for Out1.SetFont in Do *)
		Math;

	CONST
		(* Rand, Time, Do *)
		m = 65536;        (* modulus for Rand; generates the same list of random numbers as the C version *)
		runs = 2;            (* with m = 65536 the V5 heap can handle at most 2 runs of Tree in a row *)
		
	(* m = 65535;       (* modulus for Rand; generates a different list of random numbers than the C version *)
		runs = 7;    *)    (* with m = 65535 the V5 heap by chance can handle at least 7 runs of Tree in a row 
                                      Note: for fair running time comparisons between systems use the same modulus m ! *)

		bubblebase = 1.61;	(* weighing factors for the 'composite' summary values *)
		permbase = 1.75;
		queensbase = 1.83;
		towersbase = 2.39;
		quickbase = 1.92;
		intmmbase = 1.46;
		treebase =	2.5;
		mmbase = 0.0 (* 0.73 *);
		fpmmbase = 2.92;
		puzzlebase = 0.5;
		fftbase = 0.0 (* 1.11 *);
		fpfftbase = 4.44;

		perm = 1; towers = 2; queens = 3; intmm = 4; mm = 5; puzzle = 6; quick = 7; bubble = 8; trees = 9; fft = 10;
		
		(* Perm *)
		permrange = (*0..*) 10;

		(* Towers *)
		maxcells = 18;
		stackrange = (*0..*) 3;

		(* Intmm, Mm *)
		rowsize = 40;

		(* Puzzle *)
		size = 511;
		classmax = 3;
		typemax = 12;
		d = 8;

		(* Quick, Tree *)
		sortelements = 5000;

		(* Bubble *)
		srtelements = 500;

		(* FFT *)
		fftsize = 256;
		fftsize2 = 129;

	TYPE
		(* Tree *)
		node = POINTER TO nodeDesc;
		nodeDesc = RECORD
			left, right: node;
			val: INTEGER
		END;
	
		(* Towers *)
		element = RECORD
			discsize: INTEGER;
			next: INTEGER
		END ;
	
		(* Intmm, Mm *) 
		intmatrix = ARRAY rowsize + 1, rowsize + 1 OF INTEGER;
		realmatrix = ARRAY rowsize + 1, rowsize + 1 OF REAL;

		(* FFT *)
		complex = RECORD
			rp, ip: REAL
		END;
		carray = ARRAY fftsize + 1 OF complex;
		c2array = ARRAY fftsize2 + 1 OF complex;

		(* Time *)
		Proc = PROCEDURE(run: INTEGER);
	
	VAR
		(* Time, Do *)
		fixed, fixFloated, floated, pFixed, pFixfloated, pFloated: REAL;
		id: INTEGER;

		(* Rand, FFT *)
		seed: INTEGER;

		(* Perm *)
		permarray: ARRAY permrange + 1 OF INTEGER;
		pctr: INTEGER;

		(* Tree *)
		tree: node;
		treeRuns: INTEGER;

		(* Towers *)
		stack: ARRAY stackrange + 1 OF INTEGER;
		cellspace: ARRAY maxcells + 1 OF element;
		freelist: INTEGER;
		movesdone: INTEGER;

		(* Intmm, Mm *)
		ima, imb, imr: intmatrix;
		rma, rmb, rmr: realmatrix;

		(* Puzzle *)
		piececount: ARRAY classmax + 1 OF INTEGER;
		class, piecemax: ARRAY typemax + 1 OF INTEGER;
		puzzl: ARRAY size + 1 OF BOOLEAN;
		p: ARRAY typemax + 1, size + 1 OF BOOLEAN;
		n, kount: INTEGER;

		(* Bubble, Quick, Tree *)
		sortlist: ARRAY sortelements + 1 OF INTEGER;
		biggest, littlest,
		top: INTEGER;

		(* FFT *)
		z, w: carray;
		e: c2array;
		zr, zi: REAL;
	

	(* global procedures *)

	PROCEDURE Getclock (): INTEGER;
	(* System-dependent; in milliseconds *)
	BEGIN
		(* Oakwood compliant systems *)
	(* RETURN Input.Time() * 1000 DIV Input.TimeUnit *)
		(* Oberon V5 *)
		RETURN Kernel.Time()	(* gives milliseconds by definition *)
	END Getclock;
	
	PROCEDURE Initrand;
	BEGIN seed := 74755
	END Initrand;
	
	PROCEDURE Rand (): INTEGER;
	BEGIN
		seed := (seed * 1309 + 13849) MOD m  (* see above for two versions of constant m *)
		RETURN seed
	END Rand;


	(* Perm -- Permutation program, heavily recursive, written by Denny Brown   *)
	(*               Uses nearly 86600 calls of Permute for permutations of 7 digits 0-6 *)
	
	PROCEDURE Perm (run: INTEGER);
		VAR i: INTEGER;

		PROCEDURE Initialize;
			VAR i: INTEGER;
		BEGIN 
			FOR i := 1 TO 7 DO
				permarray[i] := i - 1
			END
		END Initialize;
	
		PROCEDURE Permute (n: INTEGER);
			VAR k: INTEGER;

			PROCEDURE Swap (VAR a,b: INTEGER);
				VAR t: INTEGER;
			BEGIN t := a;	 a := b;	b := t
			END Swap;

		BEGIN
			pctr := pctr + 1;
			IF n # 1 THEN
				Permute(n - 1);
				FOR k := n - 1 TO 1 BY -1 DO
					Swap (permarray[n], permarray[k]); 
					Permute (n - 1); 
					Swap (permarray[n], permarray[k])
				END
			END
		END Permute;

	BEGIN
		pctr := 0;
		FOR i := 1 TO 5 DO
			Initialize; 
			Permute(7)
		END;
		IF pctr # 43300 THEN Out.String(" Error in Perm."); Out.Ln END
	END Perm;


	(* Towers -- Program to solve the three Towers of Hanoi for 14 discs *)
	
	PROCEDURE Error (emsg: ARRAY OF CHAR);
	BEGIN
		Out.String(" Error in Towers: "); Out.String(emsg); Out.Ln; 
	END Error;

	PROCEDURE Makenull (s: INTEGER);
	BEGIN stack[s] := 0
	END Makenull;
	
	PROCEDURE Push(i, s: INTEGER);
		VAR localEl: INTEGER; errorFound: BOOLEAN;

		PROCEDURE Getelement (): INTEGER;
			VAR temp: INTEGER;
		BEGIN
			IF freelist > 0 THEN
				temp := freelist;
				freelist := cellspace[freelist].next
			ELSE
				Error("out of space		")
			END
			RETURN(temp)
		END Getelement;

	BEGIN
		errorFound := FALSE;
		IF stack[s] > 0 THEN
			IF cellspace[stack[s]].discsize <= i THEN
				errorFound := TRUE;
				Error("disc size error")
			END 
		END;
		IF ~ errorFound THEN
			localEl := Getelement();
			cellspace[localEl].next := stack[s];
			stack[s] := localEl;
			cellspace[localEl].discsize := i
		END
	END Push;
	
	PROCEDURE Pop (s: INTEGER): INTEGER;
		VAR temp, temp1: INTEGER;
	BEGIN
		temp1 := 0;
		IF stack[s] > 0 THEN
			temp1 := cellspace[stack[s]].discsize;
			temp := cellspace[stack[s]].next;
			cellspace[stack[s]].next := freelist;
			freelist := stack[s];
			stack[s] := temp
			ELSE
			Error("nothing to pop ")
		END
		RETURN temp1
	END Pop;

	PROCEDURE tower (i, j, k: INTEGER);
		VAR other: INTEGER;

		PROCEDURE Move (s1, s2: INTEGER);
		BEGIN
			Push(Pop(s1), s2);
			INC(movesdone)
		END Move;

	BEGIN
		IF k = 1 THEN
			Move(i, j);
		ELSE
			other := 6 - i - j;
			tower(i, other, k - 1);
			Move(i, j);
			tower(other, j, k - 1)
		END
	END tower;

	PROCEDURE Towers (run: INTEGER);
		VAR i: INTEGER;
	
		PROCEDURE Init (s, n: INTEGER);
			VAR discctr: INTEGER;
		BEGIN
			Makenull(s);
			FOR discctr := n TO 1 BY -1 DO
				Push (discctr, s)
			END
		END Init;

	BEGIN i := 1;
		WHILE i <= maxcells DO cellspace[i].next := i - 1; INC(i) END ;
		freelist := maxcells;
		Init(1, 14);
		Makenull(2);
		Makenull(3);
		movesdone := 0;
		tower(1, 2, 14);
		IF movesdone # 16383 THEN Out.String(" Error in Towers."); Out.Ln END
	END Towers;


	(* Queens -- The Eight Queens chess problem, solved 50 times. *)
	(*
		type
			 doubleboard =	 2..16;
			 doublenorm  =	 -7..7;
			 boardrange   =	 1..8;
			 aarray           =	 array [boardrange] of boolean;
			 barray           =	 array [doubleboard] of boolean;
			 carray           =	 array [doublenorm] of boolean;
			 xarray           =	 array [boardrange] of boardrange;
	*)

	PROCEDURE Queens (run: INTEGER);
		VAR i: INTEGER;

		PROCEDURE Doit;
			VAR i: INTEGER; q: BOOLEAN;
				a: ARRAY 9 OF BOOLEAN;
				b: ARRAY 17 OF BOOLEAN;
				c: ARRAY 15 OF BOOLEAN;
				x: ARRAY 9 OF INTEGER;

			PROCEDURE Try (i: INTEGER; VAR q: BOOLEAN; VAR a, b, c: ARRAY OF BOOLEAN; VAR x: ARRAY OF INTEGER);
				 VAR j: INTEGER;
			BEGIN
				j := 0;
				q := FALSE;
				WHILE ~ q & (j # 8) DO
					j := j + 1;
					q := FALSE;
					IF b[j] & a[i + j] & c[i - j + 7] THEN
						x[i] := j;
						b[j] := FALSE;
						a[i + j] := FALSE;
						c[i - j + 7] := FALSE;
						IF i < 8 THEN
							Try(i + 1, q, a, b, c, x);
							IF ~ q THEN
								b[j] := TRUE;
								a[i + j] := TRUE;
								c[i - j + 7] := TRUE
							END
						ELSE q := TRUE
						END
					END
				END
			END Try;

	BEGIN
		i := 0 - 7;
		WHILE i <= 16 DO
			IF (i >= 1) & (i <= 8) THEN a[i] := TRUE END;
			IF i >= 2 THEN b[i] := TRUE END;
			IF i <= 7 THEN c[i + 7] := TRUE END;
			INC(i)
		END;
		Try(1, q, b, a, c, x);
		IF ~ q THEN Out.String(" Error in Queens."); Out.Ln END
	END Doit;

	BEGIN
		FOR i := 1 TO 50 DO Doit END;
	(* Out.Int(run+1, 0); Out.Ln *)	 (* reference output *)
	END Queens;


	(* Intmm -- Multiplies two 40x40 integer matrices. *)

	PROCEDURE Intmm (run: INTEGER);
		VAR i, j: INTEGER;

		PROCEDURE Initmatrix (VAR m: intmatrix);
			VAR i, j, temp: INTEGER;
		BEGIN
			FOR i := 1 TO rowsize DO
				FOR j := 1 TO rowsize DO
					temp := Rand();
					m[i][j] := temp - (temp DIV 120) * 120 - 60
				END
			END
		END Initmatrix;

		PROCEDURE Innerproduct(VAR result: INTEGER; VAR a, b: intmatrix; row, column: INTEGER);
		(* computes the inner product of A[row,*] and B[*,column] *)
			VAR i: INTEGER;
		BEGIN
			 result := 0;
			FOR i := 1 TO rowsize DO
				result := result + a[row][i] * b[i][column]
			END
		END Innerproduct;

	BEGIN
		Initrand();
		Initmatrix(ima);
		Initmatrix(imb);
		FOR i := 1 TO rowsize DO
			FOR j := 1 TO rowsize DO
				Innerproduct(imr[i][j], ima, imb, i, j)
			END
		END;
	(* Out.Int(imr[run + 1][run + 1], 0); Out.Ln *)		(* reference output *)
	END Intmm;


	(* Mm -- Multiplies two 40x40 floating-point (REAL) matrices. *)

	PROCEDURE Mm (run: INTEGER);
		VAR i, j: INTEGER;

		PROCEDURE rInitmatrix (VAR m: realmatrix);
			VAR i, j, temp: INTEGER;
		BEGIN
			FOR i := 1 TO rowsize DO
				FOR j := 1 TO rowsize DO
					temp := Rand(); 
					m[i][j] := FLT(temp - (temp DIV 120) * 120 - 60) / 3.0
				END
			END
		END rInitmatrix;

		PROCEDURE rInnerproduct(VAR result: REAL; VAR a, b: realmatrix; row, column: INTEGER);
		(* computes the inner product of A[row,*] and B[*,column] *)
			VAR i: INTEGER;
		BEGIN
			result := 0.0;
			FOR i := 1 TO rowsize DO
				result := result + a[row][i] * b[i][column] 
		END
		END rInnerproduct;

	BEGIN
		Initrand(); 
		rInitmatrix(rma);
		rInitmatrix(rmb);
		FOR i := 1 TO rowsize DO
			FOR j := 1 TO rowsize DO
				rInnerproduct (rmr[i][j], rma, rmb, i, j)
			END
		END;
	(* Out.Real(rmr[run + 1][run + 1], 15); Out.Ln *)	 (* reference output *)
	END Mm;


(*
	Puzzle -- A compute-bound program from Forest Baskett.			
	Solves a 3D block packing problem invented by John Conway.
	A total of 18 pieces fill a cube 5 units on a side.
	There are thirteen pieces of size 1x2x4, three of 1x1x3,
	one of 1x2x2, and one of 2x2x2.
	Uses an exhaustive depth-first, recursive backtracking
	tree search, and stops after finding a first solution.
	It reports 'kount' (2005), the number of piece placement trials 
	that connect nodes. 
	See: Beeler, M., "Beyond the Baskett Benchmark", 
	Computer Architecture News, Vol. 1, No. 1. March 1986.
*)
	
	PROCEDURE Fit (i, j: INTEGER): BOOLEAN;
	(* August Karlstrom, Chris Burrows. April 2020 *)
		VAR k: INTEGER;
	BEGIN
		k := -1;
		REPEAT
			INC(k)
		UNTIL (k > piecemax[i]) OR p[i, k] & puzzl[j + k]
		RETURN k > piecemax[i]
	END Fit;
	
	PROCEDURE Place (i, j: INTEGER): INTEGER;
		VAR k: INTEGER;
	BEGIN
		FOR k := 0 TO piecemax[i] DO
			IF p[i][k] THEN puzzl[j + k] := TRUE END
		END;
		DEC(piececount[class[i]]);
		(* The following lines due to Jörg Straube *)
		k := j;
		WHILE (k <= size) & puzzl[k] DO INC(k) END;
		IF k > size THEN k := 0 END
		RETURN k
	END Place;

	PROCEDURE Remove (i, j: INTEGER);
		VAR k: INTEGER;
	BEGIN
		FOR k := 0 TO piecemax[i] DO
			IF p[i][k] THEN puzzl[j + k] := FALSE END
		END;
		INC(piececount[class[i]])
	END Remove;

	PROCEDURE Puzzle (run: INTEGER);
		VAR i, j, k, m: INTEGER;

		PROCEDURE Trial (j: INTEGER): BOOLEAN;
			VAR i, k: INTEGER; res: BOOLEAN;
		BEGIN i := 0; res := FALSE;
			INC(kount);
			WHILE (i <= typemax) & (res = FALSE) DO
				IF piececount[class[i]] # 0 THEN
					IF Fit(i, j) THEN
						k := Place(i, j);
						IF Trial(k) OR (k = 0) THEN res := TRUE
						ELSE Remove(i, j)
						END
					END
				END;
				INC(i)
			END
			RETURN res
		END Trial;

	BEGIN	 (* Puzzle *)
		FOR m := 0 TO size DO puzzl[m] := TRUE END;
		FOR i := 1 TO 5 DO
			FOR j := 1 TO 5 DO
				FOR k := 1 TO 5 DO puzzl[i + d * (j + d * k)] := FALSE END
			END
		END;

		FOR i := 0 TO typemax DO
			FOR m := 0 TO size DO p[i][m] := FALSE END
		END;

		FOR i := 0 TO 3 DO
			FOR j := 0 TO 1 DO
				FOR k := 0 TO 0 DO p[0][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[0] := 0;
		piecemax[0] := 3 + d * 1 + d * d * 0; 
		
		FOR i := 0 TO 1 DO
			FOR j := 0 TO 0 DO
				FOR k := 0 TO 3 DO p[1][i + d * (j + d * k)] := TRUE END
			END;
		END;
		class[1] := 0;
		piecemax[1] := 1 + d * 0 + d * d * 3;
		
		FOR i := 0 TO 0 DO
			FOR j := 0 TO 3 DO
				FOR k := 0 TO 1 DO p[2][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[2] := 0;
		piecemax[2] := 0 + d * 3 + d * d * 1;
		
		FOR i := 0 TO 1 DO
			FOR j := 0 TO 3 DO
				FOR k := 0 TO 0 DO p[3][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[2] := 0;
		piecemax[3] := 1 + d * 3 + d * d * 0;
		
		FOR i := 0 TO 3 DO
			FOR j := 0 TO 0 DO
				FOR k := 0 TO 1 DO p[4][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[4] := 0;
		piecemax[4] := 3 + d * 0 + d * d * 1;
		
		FOR i := 0 TO 0 DO
			FOR j := 0 TO 1 DO
				FOR k := 0 TO 3 DO p[5][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[5] := 0;
		piecemax[5] := 0 + d * 1 + d * d * 3;
		
		FOR i := 0 TO 2 DO
			FOR j := 0 TO 0 DO
				FOR k := 0 TO 0 DO p[6][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[6] := 1;
		piecemax[6] := 2 + d * 0 + d * d * 0;
		
		FOR i := 0 TO 0 DO
			FOR j := 0 TO 2 DO
				FOR k := 0 TO 0 DO p[7][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[7] := 1;
		piecemax[7] := 0 + d * 2 + d * d * 0;
		
		FOR i := 0 TO 0 DO
			FOR j := 0 TO 0 DO
				FOR k := 0 TO 2 DO p[8][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[8] := 1;
		piecemax[8] := 0 + d * 0 + d * d * 2; 
		
		FOR i := 0 TO 1 DO
			FOR j := 0 TO 1 DO
				FOR k := 0 TO 0 DO p[9][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[9] := 2;
		piecemax[9] := 1 + d * 1 + d * d * 0;
		
		FOR i := 0 TO 1 DO
			FOR j := 0 TO 0 DO
				FOR k := 0 TO 1 DO p[10][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[10] := 2;
		piecemax[10] := 1 + d * 0 + d * d * 1;
		
		FOR i := 0 TO 0 DO
			FOR j := 0 TO 1 DO
				FOR k := 0 TO 1 DO p[11][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[11] := 2;
		piecemax[11] := 0 + d * 1 + d * d * 1;
		
		FOR i := 0 TO 1 DO
			FOR j := 0 TO 1 DO
				FOR k := 0 TO 1 DO p[12][i + d * (j + d * k)] := TRUE END
			END
		END;
		class[12] := 3;
		piecemax[12] := 1 + d * 1 + d * d * 1;

		piececount[0] := 13;
		piececount[1] := 3;
		piececount[2] := 1;
		piececount[3] := 1;
		m := 1 + d * (1 + d * 1);
		kount := 0;
		IF Fit(0, m) THEN n := Place(0, m)
		ELSE Out.String("Error1 in Puzzle"); Out.Ln
		END;
		IF ~ Trial(n) THEN Out.String("Error2 in Puzzle."); Out.Ln
		ELSIF kount # 2005 THEN Out.String("Error3 in Puzzle."); Out.Ln
		END;
	(* Out.Int(n, 0); Out.Ln; Out.Int(kount, 0); Out.Ln *)	 (* reference output *)
	END Puzzle;


	(* Quick -- Sorts an array of 5000 integers using quicksort *)

	PROCEDURE Quick (run: INTEGER);

		PROCEDURE Initarr;
			VAR i, temp: INTEGER;
		BEGIN
			Initrand; 
			biggest := 0;	 littlest := 0; 
			FOR i := 1 TO sortelements DO
				temp := Rand(); 
				sortlist[i] := temp - (temp DIV 100000) * 100000 - 50000; 
				IF sortlist[i] > biggest THEN biggest := sortlist[i]
				ELSIF sortlist[i] < littlest THEN littlest := sortlist[i]
				END
			END 
		END Initarr;

		PROCEDURE Quicksort(VAR a: ARRAY OF INTEGER; l, r: INTEGER);
		(* quicksort the array A from start to finish *)
			VAR i, j, x, w: INTEGER;
		BEGIN
			i := l;	 j := r;
			x := a[(l + r) DIV 2];
			REPEAT
				WHILE a[i] < x DO i := i + 1 END;
				WHILE x < a[j] DO j := j - 1 END;
				IF i <= j THEN
					w := a[i];
					a[i] := a[j];
					a[j] := w;
					INC(i);	 DEC(j)	 (* i := i + 1;		j := j - 1 *)
				END;
			UNTIL i > j;
			IF l < j THEN Quicksort(a, l, j) END;
			IF i < r THEN Quicksort(a, i, r) END
		END Quicksort;

	BEGIN
		Initarr;
		Quicksort(sortlist, 1, sortelements);
		IF (sortlist[1] # littlest) OR (sortlist[sortelements] # biggest) THEN
			Out.String( " Error in Quick."); Out.Ln 
		END;
	(* Out.Int(sortlist[run + 1], 0);	 Out.Ln *)	(* reference output *)
	END Quick;


	(* Bubble -- Sorts an array of 500 integers using bubblesort *)

	PROCEDURE Bubble (run: INTEGER);
		VAR i, j: INTEGER;

		PROCEDURE bInitarr;
			VAR i, temp: INTEGER;
		BEGIN
			Initrand;
			biggest := 0;	 littlest := 0;
			FOR i := 1 TO srtelements DO
				temp := Rand();
				sortlist[i] := temp - (temp DIV 100000) * 100000 - 50000;
				IF sortlist[i] > biggest THEN biggest := sortlist[i]
				ELSIF sortlist[i] < littlest THEN littlest := sortlist[i]
				END
			END
		END bInitarr;

	BEGIN
		bInitarr;
		top := srtelements;
		WHILE top > 1 DO
			i := 1;
			WHILE i < top DO
				IF sortlist[i] > sortlist[i + 1] THEN
					j := sortlist[i];
					sortlist[i] := sortlist[i + 1];
					sortlist[i + 1] := j;
				END;
				INC(i)
			END;
			DEC(top)
		END;
		IF (sortlist[1] # littlest) OR (sortlist[srtelements] # biggest) THEN 
			Out.String("Error3 in Bubble."); Out.Ln
		END;
	(* Out.Int(sortlist[run + 1], 0); Out.Ln *)	 (* reference output *)
	END Bubble;


	(* Tree -- Sorts an array of 5000 integers using tree insertion sort *)

	PROCEDURE tInitarr;
		VAR i, temp: INTEGER;
	BEGIN
		Initrand;
		biggest := 0; littlest := 0;
		FOR i := 1 TO sortelements DO
			temp := Rand();
			sortlist[i] := temp - (temp DIV 100000) * 100000 - 50000;
			IF sortlist[i] > biggest THEN biggest := sortlist[i]
			ELSIF sortlist[i] < littlest THEN littlest := sortlist[i]
			END
		END
	END tInitarr;

	PROCEDURE CreateNode (VAR t: node; n: INTEGER);
	BEGIN
		NEW(t);
		t.left := NIL; t.right := NIL;
		t.val := n
	END CreateNode;

	PROCEDURE Insert(n: INTEGER; t: node);
	(* insert n into tree *)
	BEGIN
		IF n > t.val THEN
			IF t.left = NIL THEN CreateNode(t.left, n)
			ELSE Insert(n, t.left)
			END
		ELSIF n < t.val THEN
			IF t.right = NIL THEN CreateNode(t.right, n)
			ELSE Insert(n, t.right)
			END
		END
	END Insert;

	PROCEDURE Checktree(p: node): BOOLEAN;
	(* check by inorder traversal *)
		VAR result: BOOLEAN;
	BEGIN
		result := TRUE;
		IF p.left # NIL THEN
			IF p.left.val <= p.val THEN result := FALSE;
			ELSE result := Checktree(p.left) & result
			END
		END;
		IF	p.right # NIL THEN
			IF p.right.val >= p.val THEN result := FALSE;
			ELSE result := Checktree(p.right) & result
			END
		END;
		RETURN result
	END Checktree;

	PROCEDURE Trees (run: INTEGER);
		VAR i: INTEGER;
	BEGIN
		(* The IF clause and last line (thanks to Joerg Straube) are necessary to prevent heap overflow *)
		IF Kernel.heapLim - Kernel.heapOrg - Kernel.allocated > 160000 THEN 
			tInitarr;
			NEW(tree);
			tree.left := NIL; tree.right := NIL; tree.val := sortlist[1];
			FOR i := 2 TO sortelements DO
				Insert(sortlist[i], tree) 
			END;
			IF ~ Checktree(tree) THEN Out.String(" Error in Tree."); Out.Ln 
	 (* ELSE INC(treeRuns); Out.Ln; OutInt(treeRuns, 2) *)	(* reference output A; shows calls of Checktree *)
			END;
		END;
		tree := NIL; Oberon.Collect(0);	 (* (JS) tell the GC to start after Hennessy terminated *)
 (* Out.Int(sortlist[2 + run], 7); Out.Ln *)	(* reference output B; only shows correct initialization *)
	END Trees;
	
	
	(* FFT 'Oscar' -- A Fast Fourier Transform program *)

	PROCEDURE Cos (x: REAL): REAL;
	(* computes cos of x (x in radians) by an expansion *)
		VAR i, factor: INTEGER;
			result, power: REAL;
	BEGIN
		result := 1.0;	factor := 1;	power := x; 
		FOR i := 2 TO 10 DO
			factor := factor * i;	 power := power * x;
			IF i MOD 2 = 0 THEN
				IF i MOD 4 = 0 THEN 
					result := result + power/FLT(factor)
				ELSE 
					result := result - power/FLT(factor)
				END
			END
		END
		RETURN result
	END Cos;
	
	PROCEDURE Min0 ( arg1, arg2: INTEGER): INTEGER;
		VAR res: INTEGER;
	BEGIN
		IF arg1 < arg2 THEN 
			res := arg1
		ELSE 
			res := arg2
		END
		RETURN res
	END Min0;
	
	PROCEDURE Printcomplex (VAR z: ARRAY OF complex; start, finish, inc: INTEGER);
	(* Can be used to print the reference output *)
		VAR i: INTEGER;
	BEGIN
		Out.Ln; 
		i := start; 
		REPEAT
			Out.String("	"); Out.RealFix(z[i].rp, 9, 3); Out.RealFix(z[i].ip, 9, 3);
			INC(i, inc); 
			Out.String("	"); Out.RealFix(z[i].rp, 9, 3); Out.RealFix(z[i].ip, 9, 3); Out.Ln; 
			INC(i, inc)
		UNTIL ~ (i <= finish); 
	END Printcomplex;

	PROCEDURE Uniform11 (VAR (*in/out*) iy: INTEGER; VAR (*out*) yfl: REAL);
	BEGIN
		iy := (4855 * iy + 1731) MOD 8192;	(* 8192 is important to get the same output as C *)
		yfl := FLT(iy) / 8192.0
	END Uniform11;

	PROCEDURE Exptab (n: INTEGER; VAR e: c2array);
		VAR theta, divisor: REAL; h: ARRAY 26 OF REAL;
			i, j, k, l, m: INTEGER;
	BEGIN
		theta := 3.1415926536;
		divisor := 4.0; 
		FOR i := 1 TO 25 DO
			h[i] := 1.0 / (2.0 * Cos(theta / divisor));
			divisor := divisor + divisor
		END;
		m := n DIV 2;
		l := m DIV 2;
		j := 1;
		e[1].rp := 1.0;
		e[1].ip := 0.0;
		e[l + 1].rp := 0.0;
		e[l + 1].ip := 1.0;
		e[m + 1].rp := -1.0;
		e[m + 1].ip := 0.0;
		REPEAT
			i := l DIV 2;
			k := i;
			REPEAT
				e[k + 1].rp := h[j] * (e[k + i + 1].rp + e[k - i + 1].rp);
				e[k + 1].ip := h[j] * (e[k + i + 1].ip + e[k - i + 1].ip);
				INC(k, l)	 (* k := k + l *)
			UNTIL k > m;
			j := Min0(j + 1, 25);
			l := i
		UNTIL l <= 1
	END Exptab;

	PROCEDURE Fft( n: INTEGER; VAR z, w: carray; VAR e: c2array; sqrinv: REAL);
		VAR i, j, k, l, m, index: INTEGER;
	BEGIN
		m := n DIV 2 ;
		l := 1 ;
		REPEAT
			k := 0 ;
			j := l ;
			i := 1 ;
			REPEAT
				REPEAT
					w[i + k].rp := z[i].rp + z[m + i].rp ;
					w[i + k].ip := z[i].ip + z[m + i].ip ;
					w[i + j].rp := e[k + 1].rp * (z[i].rp - z[i + m].rp)
														- e[k + 1].ip * (z[i].ip - z[i + m].ip);
					w[i + j].ip := e[k + 1].rp * (z[i].ip - z[i + m].ip)
														+ e[k + 1].ip * (z[i].rp - z[i + m].rp);
					INC(i);
				UNTIL i > j;
				k := j;
				j := k + l;
			UNTIL j > m;
			(*z := w ;*) index := 1;
			REPEAT
				z[index] := w[index];
				INC(index)
			UNTIL index > n;
			INC(l, l)	 (* l := l + l *)
		UNTIL l > m;
		FOR i := 1 TO n DO
			z[i].rp :=	sqrinv * z[i].rp;
			z[i].ip := -sqrinv * z[i].ip
		END
	END Fft;
	
	PROCEDURE Oscar (run: INTEGER);
		VAR i: INTEGER;
	BEGIN
		Exptab(fftsize, e) ;
		seed := 5767; 
		FOR i := 1 TO fftsize DO
			Uniform11(seed, zr);
			Uniform11(seed, zi);
			z[i].rp := 20.0 * zr - 10.0;
			z[i].ip := 20.0 * zi - 10.0
		END;
		FOR i := 1 TO 20 DO Fft(fftsize, z, w, e, 0.0625) END;
	(* Printcomplex (z, 1, 256, 17) *)	 (* reference output *)
	END Oscar;
	
	
	(* Do -- main *)

	PROCEDURE WriteMillisec (t: INTEGER);
	BEGIN
		IF t = 0 THEN Out.String("< 0.5") ELSE Out.Int(t, 6) END
	END WriteMillisec;
	
	PROCEDURE Time (id: INTEGER; bench: ARRAY OF CHAR; p: Proc; base, fbase: REAL);
		VAR t, run: INTEGER; 
	BEGIN
		Out.String(bench);

		t := Getclock();
		FOR run := 0 TO runs - 1 DO p(run) END;
		t := Getclock() - t;
		
		(* write running time and average time per run of benchmark *)
		WriteMillisec(t); Out.String("   "); WriteMillisec(FLOOR( FLT(t)/FLT(runs) + 0.5 ) ); Out.Ln;

		(* for weighted arithmetic means, like in the C version *)
		fixed := fixed + FLT(t) * base;                                              (* nonfloating-point *)
		fixFloated := fixFloated + FLT(t) * fbase;  (* nonfloating-point + floating-point *)
		IF (id = mm) OR (id = fft) THEN
			(* floating-point only: Mm or FFT *) 
			floated := floated + FLT(t) * fbase         (* 'floated' redefined from C version! *)
		END;

		(* for geometric means use the products of the timings *)
		IF (id # mm) & (id # fft) THEN                                             (* nonfloating-point *)
			pFixed := pFixed * FLT(t)
		END;
		pFixfloated := pFixfloated * FLT(t);          (* nonfloating-point + floating-point *)
		IF (id = mm) OR (id = fft) THEN                                         (* only floating-point *)
			pFloated := pFloated * FLT(t)
		END
	END Time;
	

	PROCEDURE Do* ;
		VAR m, t0: INTEGER;

		PROCEDURE Power (x, y: REAL): REAL;
		(* Math in V5 has no power, so ... *)
		BEGIN
			RETURN Math.exp(y * Math.ln(x))
		END Power;

	BEGIN 
		fixed := 0.0;		fixFloated := 0.0;	 floated := 0.0;	
		pFixed := 1.0;	pFixfloated := 1.0;	 pFloated := 1.0;

		Out.SetFont("Courier10.Fnt");  (* for Oberon System only *)

		Out.String("Hennessy benchmarks (Oberon V5, "); 
		Out.Int(runs, 0); Out.String(" runs, ms)"); Out.Ln;
		Out.Int(runs, 11); Out.String(" runs   per run"); Out.Ln;
		t0 := Getclock();
		Time(perm, "Perm:    ", Perm, permbase, permbase);
		Time(towers, "Towers:  ", Towers, towersbase, towersbase);
		Time(queens,"Queens:  ", Queens, queensbase, queensbase);
		Time(intmm, "Intmm:   ", Intmm, intmmbase, intmmbase); 
		Time(mm, "Mm:      ", Mm, mmbase, fpmmbase);
		Time(puzzle, "Puzzle:  ", Puzzle, puzzlebase, puzzlebase);
		Time(quick, "Quick:   ", Quick, quickbase, quickbase);
		Time(bubble, "Bubble:  ", Bubble, bubblebase, bubblebase);
		Time(trees, "Tree:    ", Trees, treebase, treebase);
		Time(fft, "FFT:     ", Oscar, fftbase, fpfftbase);
		Out.String("  TOTAL  "); WriteMillisec(Getclock() - t0); Out.Ln;
		Out.Ln;

		(* The following lines assume 10 benchmarks. Two (Mm & FFT) use floating point *)

		Out.String("* Weighted arithmetic means (obsolete) *"); Out.Ln;
		m := FLOOR(fixed/8.0 + 0.5);	(* originally in C: divisor = 10.0 *)
		Out.String("Nonfloating-point composite         "); WriteMillisec(m); Out.Ln;		
		m := FLOOR(fixFloated/10.0 + 0.5);
		Out.String("Fl.-point + nonfl.-point composite  "); WriteMillisec(m); Out.Ln;
		m := FLOOR(floated/2.0 + 0.5);
		Out.String("Floating-point composite (Mm & FFT) "); WriteMillisec(m); Out.Ln;
		Out.Ln;
		Out.String("* Geometric means *"); Out.Ln;
		m := FLOOR(Power(pFixed, 0.125) + 0.5);      (* = 8th root *)
		Out.String("Nonfloating-point                   "); WriteMillisec(m); Out.Ln;
		m := FLOOR(Power(pFixfloated, 0.1) + 0.5);  (* = 10th root *)
		Out.String("Floating-point + nonfloating-point  "); WriteMillisec(m); Out.Ln;
		m := FLOOR(Power(pFloated, 0.5) + 0.5);      (* = 2nd root (sqrt) *)
		Out.String("Floating-point (Mm & FFT)           "); WriteMillisec(m); Out.Ln;

		Out.SetFont("Oberon10.Scn.Fnt")  (* for Oberon System only *)
	END Do;

END Hennessy.
