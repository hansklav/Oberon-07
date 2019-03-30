MODULE Print; (* IN Oberon *) (* Hans Klaver, 09-May-1999 *)
(** To execute mark this viewer with * and middle-click Print.Me **)
	IMPORT In, Out;

	PROCEDURE Me*;
		VAR ch: CHAR;
	BEGIN 
		In.Open;  
		In.Char(ch);
		WHILE In.Done DO
			Out.Char(ch);
			In.Char(ch)
		END
	END Me;

END Print.Me*
