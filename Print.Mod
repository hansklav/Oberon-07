MODULE Print; (* IN Oberon *) (* Hans Klaver, 09-May-1999 *)
(** A self-reproducing program.
    To execute mark this viewer with * and middle-click Print.Me **)
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


Source: [The ModulaTor, 1999)](https://www.modulaware.com/mdlt/mdlt78.htm)
