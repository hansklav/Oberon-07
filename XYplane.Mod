MODULE XYplane (* IN V5 *);  (* M. Reiser 1992 / hk 2017, 2020 *)
(** 
	Pixel oriented graphics output on a Cartesian plane, with 
	origin in the lower left corner. Input from the keyboard.
	See pages  91, 100 & 311 of Reiser & Wirth, Programming in Oberon (1992)
*)

IMPORT Display, MenuViewers, Oberon, TextFrames, Input;

CONST 
	max = 15013;                 (* for a 753 x 638 user track monochrome bitmap of SETs *)
	maxSet = 31;                 (* size of SET is 32 bits *)
	closed = 0;  displayed = 2;  (* values for the viewer state *)
	black = Display.black;  white = Display.white;  replace = Display.replace;
	erase* = 0;  draw* = 1;      (* values for parameter mode in Dot *)

TYPE 
	XYframe = POINTER TO XYframeDesc;
	XYframeDesc = RECORD (Display.FrameDesc) END;

VAR 
	F: XYframe;  V: MenuViewers.Viewer;
	bitmap: ARRAY max OF SET;
	X*, Y*, W*, H*: INTEGER;

PROCEDURE Modify (F: XYframe; VAR M: MenuViewers.ModifyMsg);
BEGIN
	IF (M.id = MenuViewers.extend) & (M.dY > 0) THEN
		Display.ReplConst(black, F.X, F.Y + F.H, F.W, M.dY, replace)
	END;
	IF M.Y < F.Y THEN
		Display.ReplConst(black, F.X, M.Y, F.W, F.Y - M.Y, replace)
	END;
	X := F.X;  Y := M.Y;  W := F.W;  H := M.H
END Modify;

PROCEDURE Handle (F: Display.Frame; VAR M: Display.FrameMsg);
BEGIN                                           (* WITH statements eliminated,  hk 2017 *)
	CASE F OF XYframe:
		CASE M OF
			Oberon.InputMsg:
				IF M(Oberon.InputMsg).id = Oberon.track THEN
					Oberon.DrawMouseArrow(M(Oberon.InputMsg).X, M(Oberon.InputMsg).Y)  (* hk 2017 *)
				END 
		|  MenuViewers.ModifyMsg:
				Modify(F(XYframe), M(MenuViewers.ModifyMsg))
		END
	END
END Handle;

PROCEDURE Clear*;
VAR j: INTEGER;
BEGIN 
	Oberon.RemoveMarks(F.X, F.Y, F.W, F.H);                                    (* hk 2020 *)
	Display.ReplConst(black, F.X, F.Y, F.X + F.W, F.Y + F.H, replace);
	j := 0;  WHILE j < max DO bitmap[j] := {}; INC(j) END
END Clear;

PROCEDURE Open* ;
VAR menuF: TextFrames.Frame;  x, y: INTEGER;
BEGIN
	IF V.state # displayed THEN
(* 	Oberon.OpenTrack(Display.Left, 0);  *)
		Oberon.OpenTrack( 0, 0);                                                 (* hk 2017 *)
		menuF := TextFrames.NewMenu("XY Plane", "System.Close  XYplane.Clear  IFS.Draw");
		NEW(F);  F.handle := Handle;
		Oberon.AllocateUserViewer(Oberon.Par.vwr.X, x, y);                       (* hk 2017 *)
		V := MenuViewers.New(menuF, F, TextFrames.menuH, x, y)
	END;
	Clear 
END Open;

PROCEDURE Dot* (x, y, mode: INTEGER);
VAR k, i, j: INTEGER;
BEGIN  (* LONG eliminated *)
	IF (x >= F.X) & (x < F.X + F.W) & (y >= F.Y) & (y < F.Y + F.H) THEN
		k := (*LONG*)(y)*F.W + x;  i := k DIV maxSet;  j := k MOD maxSet;        (* hk 2017 *)
		IF mode = erase THEN       (* numeric case statement not implemented *)  (* hk 2017 *)
			Display.Dot(black, x, y, replace); EXCL(bitmap[i], j)
		ELSE
			Display.Dot(white, x, y, replace); INCL(bitmap[i], j)
		END
	END
END Dot;

PROCEDURE IsDot* (x, y: INTEGER): BOOLEAN;
VAR k, i, j: INTEGER;
	res: BOOLEAN;
BEGIN                                 (* LONG eliminated, only one RETURN *)  (* hk 2017*)
	IF (x >= F.X) & (x < F.X + F.W) & (y >= F.Y) & (y < F.Y + F.H) THEN
		k := (*LONG*)(y)*F.W + x;  i := k DIV maxSet;  j := k MOD maxSet;         (* hk 2017*)
		IF j IN bitmap[i] THEN res := TRUE  ELSE res := FALSE END
	ELSE res := FALSE
	END
	RETURN res
END IsDot;

PROCEDURE Key* (): CHAR;
VAR ch: CHAR;
BEGIN  ch := 0X;
	IF Input.Available() > 0 THEN  Input.Read(ch)  END;
	RETURN ch
END Key;

BEGIN  
	NEW(F);  F.H := 0;  NEW(V);  V.state := closed
END XYplane.


