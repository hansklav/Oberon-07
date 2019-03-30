MODULE Easter; (* IN V5 *)  (* hk  22-3-2016, 23-3-2019 *)
(* 
	Procedures to calculate and print a list of dates of 
	Western Christianity Easter and related days.
*)

	IMPORT In, Out := Out1;

	TYPE
		Date = RECORD
			day, month, year: INTEGER
		END;

	PROCEDURE EasterDate (year: INTEGER; VAR easter: Date);
	(*
		Gives the western Easter date of a year between 1583 and 2299 (Gregorian calender).
		After an algorithm by C.F. Gauss (1816).
	*)
		VAR
			a, b, c, d, e: INTEGER;
			M, N: INTEGER;
			marchDay, aprilDay: INTEGER;
	BEGIN
		ASSERT((year > 1582) & (year < 2300));
		a := year MOD 19;
		b := year MOD 4;
		c := year MOD 7;
		IF (year >= 1583) & (year <= 1699) THEN
			M := 22;  N := 2;
		ELSIF (year >= 1700) & (year <= 1799) THEN
			M := 23;  N := 3;
		ELSIF (year >= 1800) & (year <= 1899) THEN
			M := 23;  N := 4;
		ELSIF (year >= 1900) & (year <= 2099) THEN
			M := 24;  N := 5;
		ELSIF (year >= 2100) & (year <= 2199) THEN
			M := 24;  N := 6;
		ELSIF (year >= 2200) & (year <= 2299) THEN
			M := 25;  N := 7
		END;
		d := (19*a + M) MOD 30;
		e := (2*b + 4*c + 6*d + N) MOD 7;
		marchDay := 22 + d + e;
		aprilDay := d + e - 9;
		IF aprilDay = 26 THEN aprilDay := 19 END;
		IF (aprilDay = 25) & ((d = 28) & (a > 10)) THEN aprilDay := 18 END;
		easter.year := year;
		IF marchDay <= 31 THEN
			easter.month := 3;
			easter.day := marchDay
		ELSE
			easter.month := 4;
			easter.day := aprilDay
		END
	END EasterDate;
	
	PROCEDURE Day (d: Date): INTEGER;
	(* From module Dates of BlackBox Component Builder *)
		VAR y, m, n: INTEGER;
	BEGIN
		y := d.year; m := d.month - 3;
		IF m < 0 THEN INC(m, 12); DEC(y) END;
		n := y * 1461 DIV 4 + (m * 153 + 2) DIV 5 + d.day - 306;
		IF n > 577737 THEN n := n - (y DIV 100 * 3 - 5) DIV 4 END;
		RETURN n
	END Day;

	PROCEDURE DayToDate (n: INTEGER; VAR d: Date);
	(* From module Dates of BlackBox Component Builder *)
		VAR c, y, m: INTEGER;
	BEGIN
		IF n > 577737 THEN
			n := n * 4 + 1215; c := n DIV 146097; n := n MOD 146097 DIV 4
		ELSE
			n := n + 305; c := 0
		END;
		n := n * 4 + 3; y := n DIV 1461; n := n MOD 1461 DIV 4;
		n := n * 5 + 2; m := n DIV 153; n := n MOD 153 DIV 5;
		IF m > 9 THEN m := m - 12; INC(y) END;
		d.year := 100 * c + y;
		d.month := m + 3;
		d.day := n + 1
	END DayToDate;

	PROCEDURE PrintDates*;
		CONST 
			maxInterval = 380;  (* limit of System.Log *)
		VAR
			Easter, Carnival, Ascension, Pentecost: Date;
			y, year1, year2, carn, asc, pent: INTEGER;
			oneYear: BOOLEAN;
	BEGIN
		year1 := 0;  year2 := 0;  oneYear := FALSE;
		(* allow user to give a year or begin and end year *)
		In.Open;  In.Int(year1);  In.Int(year2);  
		IF ~ In.Done & (1583 <= year1) & (year1 <= 2299) THEN year2 := year1; oneYear := TRUE END;
		IF ~ oneYear & (~ In.Done OR (year1 < 1583) OR (year2 > 2299) OR (year1 > year2)) THEN
			Out.String("Give one year or two ascending years between 1583 and 2299"); Out.Ln
		ELSE
			IF year1 = year2 THEN oneYear := TRUE END;
			IF year2 - year1 > maxInterval THEN year2 := year1 + maxInterval END;
			Out.SetFont("Courier10.Fnt");
			Out.String("E a s t e r   &   o t h e r   d a t e s   ");
			Out.Int(year1, 0); IF ~ oneYear THEN Out.String("-"); Out.Int(year2, 0) END;  Out.Ln;
			Out.String("===================================================");  Out.Ln;
			Out.String("Year  Carnival    E a s t e r  Ascension  Pentecost");  Out.Ln;
			Out.String("===================================================");  Out.Ln;
			y := year1;
			REPEAT
				EasterDate(y, Easter);
				carn :=  Day(Easter) - 49;  DayToDate(carn, Carnival);
				asc := Day(Easter) + 39;  DayToDate(asc, Ascension);
				pent := Day(Easter) + 49;  DayToDate(pent, Pentecost);
				Out.Int(y, 0);  Out.String("  ");
				Out.Int(Carnival.day, 2);  Out.String(" ");
				IF Carnival.month = 2 THEN Out.String("February   ") ELSE Out.String("March      ") END;
				Out.Int(Easter.day, 2);  Out.String(" ");
				IF Easter.month = 3 THEN Out.String("March   ") ELSE Out.String("April   ") END;
				Out.Int(Ascension.day, 2);  Out.String(" ");
				IF Ascension.month = 5 THEN Out.String("May     ") ELSE Out.String("June    ") END;
				Out.Int(Pentecost.day, 2);  Out.String(" "); 
				IF Pentecost.month = 5 THEN Out.String("May") ELSE Out.String("June") END;
				Out.Ln;
				INC(y) 
			UNTIL y > year2
		END;
		Out.SetFont("Oberon10.Scn.Fnt")
	END PrintDates;

END Easter.

Easter.PrintDates 2019 2030
Easter.PrintDates ^
1500 1600
1583 1610
1583 2299
2000 4000
2050 2020
2020