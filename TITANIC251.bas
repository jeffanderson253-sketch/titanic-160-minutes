' =====================================================================
'  TITANIC: 160 MINUTES  -  v2.5.1
'  A turn-based evacuation command game in QBASIC-style BASIC.
'  Target: QB64
'
'  Version 2.5.1 command-interface revision:
'   - Clean, redrawn command dashboard after every order
'   - Persistent LAST ORDER / RESULT feedback instead of scrolling clutter
'   - Crew-group command menus restored (officers, deckhands, stewards, etc.)
'   - Every order screen retains a complete live resource ledger
'   - Every menu states exact costs; loading previews exact steward outcomes
'   - Steward choices expanded: guide, calm, rebalance, or reserve for loading
'   - Rebalanced distress system with visible rescue-readiness progress
'   - Improved officer crowd control and useful-crew safeguards
'   - Fixed repeated pump/dynamo assignment and other resource exploits
'   - No fictional crowd of 200 people standing in Engineering
'   - Stronger warnings, full accounting, commendations and efficiency stats
'   - Completely rebuilt title, sinking and dawn artwork
' =====================================================================

DECLARE SUB InitGame ()
DECLARE SUB ShowStatus ()
DECLARE SUB ChooseDoctrine ()
DECLARE SUB RedrawCommand ()
DECLARE SUB ShowMainMenu ()
DECLARE SUB ShowAlerts ()
DECLARE SUB CrewScreen (t$)
DECLARE SUB MenuDeckhands ()
DECLARE SUB MenuOfficers ()
DECLARE SUB MenuStewards ()
DECLARE SUB MenuEngineers ()
DECLARE SUB MenuWireless ()
DECLARE SUB PrepareBoat ()
DECLARE SUB LoadBoat ()
DECLARE SUB LaunchBoat ()
DECLARE SUB SendBelow ()
DECLARE SUB MoveCrowd ()
DECLARE SUB Organize (who)
DECLARE SUB FireRockets (who)
DECLARE SUB ResolveTurn ()
DECLARE SUB FinalReport ()
DECLARE SUB ShowManual ()
DECLARE FUNCTION AskNum (p$, lo, hi)
DECLARE FUNCTION PickBoat (want, p$)
DECLARE FUNCTION CalcLoad (b, sw)
DECLARE FUNCTION CountBelow ()
DECLARE FUNCTION CountDeck ()
DECLARE FUNCTION CountDavit ()
DECLARE FUNCTION CountBoats (want)
DECLARE FUNCTION TimeStr$ ()
DECLARE FUNCTION DoctrineName$ ()
DECLARE FUNCTION BoatStateName$ (s)
DECLARE FUNCTION FloodName$ (f)
DECLARE FUNCTION PanicName$ (p)
DECLARE FUNCTION ZoneTag$ (i)
DECLARE FUNCTION Fit$ (s$, w)
DECLARE SUB ShowIntro ()
DECLARE SUB ShowTurnHeader ()
DECLARE SUB TurnFlavor ()
DECLARE SUB CommandPanel ()
DECLARE SUB ShowSinkingShip ()
DECLARE SUB ShowDawn ()
DECLARE SUB BigBanner (t$)
DECLARE SUB SectionHeader (t$)
DECLARE SUB HRule (c, ch$)
DECLARE SUB Meter (label$, amount, maxv, wid, mode)
DECLARE SUB ShipSilhouette ()
DECLARE SUB FloodCell (i)
DECLARE SUB BoxTop ()
DECLARE SUB BoxBot ()
DECLARE SUB BoxKV (label$, rest$, lc)
DECLARE SUB BoxWrap (label$, rest$, lc)
DECLARE SUB WaitKey ()
DECLARE SUB SetLast (act$, result$, clr)

' ------------------------- SHARED GAME STATE -------------------------
Dim Shared ZP(5), ZF(5), ZK(5), ZBLK(5)
Dim Shared ZN$(5)

Dim Shared BST(8), BLD(8)
Dim Shared BN$(8)

Dim Shared TOF, TDH, TST, TEN, TWO
Dim Shared AOF, ADH, AST, AEN, AWO
Dim Shared OFFNames$(4)

Dim Shared TURN, SAVED, CREWLOST, WIRE, RKT, SIGPTS, RKTTHIS
Dim Shared PWR, PWRFAILT, DOC, ENWD, URG, PUMPN, PWRM, OFUSED
Dim Shared LASTACT$, LASTOUT$, LASTCLR

' ------------------------------ SETUP --------------------------------
Randomize Timer
Width 80, 50
_Title "Titanic: 160 Minutes - Version 2.5.1"

' --------------------------- MASTER LOOP ------------------------------
Do
    InitGame
    ShowIntro

    For TURN = 1 To 16
        AOF = TOF: ADH = TDH: AST = TST
        If PWR = 1 Then AWO = TWO Else AWO = 0
        If ENWD = 0 Then AEN = TEN Else AEN = 0
        PUMPN = 0: PWRM = 0: OFUSED = 0: RKTTHIS = 0
        SetLast "Watch reset", "Crew availability refreshed for the next ten minutes.", 8

        done = 0
        Do
            RedrawCommand

            c = AskNum("Your order", 1, 9)

            Select Case c
                Case 1
                    ShowStatus
                Case 2
                    ChooseDoctrine
                Case 3
                    MenuDeckhands
                Case 4
                    MenuOfficers
                Case 5
                    MenuStewards
                Case 6
                    MenuEngineers
                Case 7
                    MenuWireless
                Case 8
                    ShowManual
                Case 9
                    ' Endgame guard: people sitting in boats never lowered
                    w = 0
                    For b = 1 To 8
                        If BST(b) = 1 And BLD(b) > 0 Then w = w + BLD(b)
                    Next b

                    If TURN >= 15 And w > 0 Then
                        Color 12: Print "  *** "; LTrim$(Str$(w)); " souls sit in boats still hanging at the davits! ***"
                        Color 7
                        y = AskNum("End the turn anyway? 1) Yes  2) No", 1, 2)
                        If y = 1 Then
                            done = 1
                        Else
                            SetLast "Confirm orders", "Turn held open: launch those loaded boats while time remains.", 14
                        End If
                    Else
                        done = 1
                    End If
            End Select
        Loop Until done = 1

        ResolveTurn

        Print
        If TURN < 16 Then
            Color 14: Print "  Press any key to plan the next 10 minutes..."
        Else
            Color 14: Print "  Press any key for the final reckoning..."
        End If
        Color 7
        WaitKey
    Next TURN

    FinalReport

    again = AskNum("Face the night again? 1) Yes  2) No", 1, 2)
Loop Until again = 2

Cls
Color 7
Print
Print "  The sea remembers. Goodbye."
Print
End

' =====================================================================
'  INITIAL STATE (reset for every new game)
' =====================================================================
Sub InitGame
    ZN$(1) = "Forward Lower Decks": ZN$(2) = "Midship Lower Decks"
    ZN$(3) = "Engineering": ZN$(4) = "Port Boat Deck": ZN$(5) = "Starboard Boat Deck"

    ' 2,200-soul evacuation pool. Engineering is a system zone, not a crowd.
    ZP(1) = 650: ZF(1) = 2: ZK(1) = 1: ZBLK(1) = 0
    ZP(2) = 950: ZF(2) = 0: ZK(2) = 0: ZBLK(2) = 0
    ZP(3) = 0: ZF(3) = 0: ZK(3) = 0: ZBLK(3) = 0
    ZP(4) = 300: ZF(4) = 0: ZK(4) = 0: ZBLK(4) = 0
    ZP(5) = 300: ZF(5) = 0: ZK(5) = 0: ZBLK(5) = 0

    For i = 1 To 4
        BN$(i) = "P" + LTrim$(Str$(i))
        BST(i) = 0: BLD(i) = 0
    Next i

    For i = 5 To 8
        BN$(i) = "S" + LTrim$(Str$(i - 4))
        BST(i) = 0: BLD(i) = 0
    Next i

    TOF = 4: TDH = 6: TST = 6: TEN = 5: TWO = 1
    OFFNames$(4) = "Murdoch"
    OFFNames$(3) = "Lightoller"
    OFFNames$(2) = "Moody"
    OFFNames$(1) = "Lowe"

    PWR = 1: DOC = 0: SAVED = 0: WIRE = 0: CREWLOST = 0
    ENWD = 0: URG = 0: PWRFAILT = 0: RKT = 0: SIGPTS = 0
End Sub

' =====================================================================
'  REFRESHED COMMAND VIEW
' =====================================================================
Sub RedrawCommand
    Cls
    ShowTurnHeader
    TurnFlavor
    CommandPanel
    ShowAlerts
    ShowMainMenu
End Sub

Sub CommandPanel
    Print
    BoxTop

    s$ = "Below " + LTrim$(Str$(CountBelow)) + "   On decks "
    s$ = s$ + LTrim$(Str$(CountDeck)) + "   In davits "
    s$ = s$ + LTrim$(Str$(CountDavit)) + "   Away " + LTrim$(Str$(SAVED))
    BoxKV "SOULS", s$, 15

    s$ = "Officers " + LTrim$(Str$(AOF)) + "   Deckhands "
    s$ = s$ + LTrim$(Str$(ADH)) + "   Stewards " + LTrim$(Str$(AST))
    s$ = s$ + "   Engineers " + LTrim$(Str$(AEN)) + "   Wireless " + LTrim$(Str$(AWO))
    BoxKV "CREW FREE", s$, 10

    s$ = "FWD[" + ZoneTag$(1) + "]  MID[" + ZoneTag$(2) + "]  ENG["
    s$ = s$ + ZoneTag$(3) + "]   Panic P:" + LTrim$(Str$(ZK(4)))
    s$ = s$ + " S:" + LTrim$(Str$(ZK(5)))
    If PWR = 1 Then s$ = s$ + "   POWER ON" Else s$ = s$ + "   POWER OUT"
    BoxKV "SHIP", s$, 14

    s$ = "Covered " + LTrim$(Str$(CountBoats(0))) + "   Ready "
    s$ = s$ + LTrim$(Str$(CountBoats(1))) + "   Away "
    s$ = s$ + LTrim$(Str$(CountBoats(2))) + "   Rescue readiness "
    s$ = s$ + LTrim$(Str$(SIGPTS)) + "/200"
    BoxKV "EVAC", s$, 11

    s$ = "Pumps " + LTrim$(Str$(PUMPN))
    If PWRM = 1 Then s$ = s$ + "   Dynamos TENDED" Else s$ = s$ + "   Dynamos idle"
    If PWR = 0 Then
        s$ = s$ + "   Wireless DEAD"
    ElseIf AWO = 0 Then
        s$ = s$ + "   Wireless SENT"
    Else
        s$ = s$ + "   Wireless idle"
    End If
    BoxKV "THIS TURN", s$, 12

    BoxKV "LAST ORDER", LASTACT$, 14
    BoxWrap "RESULT", LASTOUT$, LASTCLR
    BoxBot
End Sub

Sub ShowAlerts
    n = 0
    Color 12

    If ZF(1) >= 4 And ZP(1) > 0 Then
        Print "  ! FORWARD DECKS CRITICAL: "; ZP(1); " souls remain below."
        n = n + 1
    ElseIf ZF(2) >= 4 And ZP(2) > 0 Then
        Print "  ! MIDSHIP CRITICAL: "; ZP(2); " souls remain below."
        n = n + 1
    End If

    If TURN >= 12 And CountDavit > 0 Then
        Print "  ! DAVIT DANGER: "; CountDavit; " loaded souls are not yet saved."
        n = n + 1
    ElseIf TURN >= 12 And CountBoats(0) > 0 Then
        Print "  ! "; CountBoats(0); " boats are still covered with the bow going under."
        n = n + 1
    End If

    If n < 2 And PWR = 1 And AWO = 1 And SIGPTS < 100 Then
        Color 14
        Print "  ! Wireless is idle; early position reports build rescue readiness fastest."
        n = n + 1
    End If

    If n < 2 And DOC = 0 Then
        Color 14
        Print "  ! No evacuation doctrine has been issued."
        n = n + 1
    End If

    If n = 0 Then
        Color 8: Print "  Captain's eye: no new critical warning."
    End If
    Color 7
End Sub

Sub ShowMainMenu
    Print
    Color 15
    Print "   1) STATUS REPORT   ";: Color 8: Print "full ship inspection": Color 15
    Print "   2) SET DOCTRINE    ";: Color 8: Print DoctrineName$: Color 15
    Print "   3) DECKHAND ORDERS ";: Color 8: Print "prepare, launch, rockets": Color 15
    Print "   4) OFFICER ORDERS  ";: Color 8: Print "load boats, control crowds, rockets": Color 15
    Print "   5) STEWARD ORDERS  ";: Color 8: Print "guide, calm, redirect, assist loading": Color 15
    Print "   6) ENGINEER ORDERS ";: Color 8: Print "pumps, dynamos, withdrawal": Color 15
    Print "   7) WIRELESS ORDERS ";: Color 8: Print "CQD / SOS and position reports": Color 15
    Print "   8) FIELD MANUAL    ";: Color 8: Print "rules and exact effects"
    Color 14: Print "   9) CONFIRM ORDERS  ";: Color 7: Print "let ten minutes pass"
End Sub

' =====================================================================
'  CREW-GROUP ORDER SCREENS
' =====================================================================
Sub CrewScreen (t$)
    Cls
    ShowTurnHeader
    SectionHeader t$
    BoxTop

    s$ = "Officers " + LTrim$(Str$(AOF)) + "/" + LTrim$(Str$(TOF))
    s$ = s$ + "   Deckhands " + LTrim$(Str$(ADH)) + "/" + LTrim$(Str$(TDH))
    s$ = s$ + "   Stewards " + LTrim$(Str$(AST)) + "/" + LTrim$(Str$(TST))
    BoxKV "AVAILABLE", s$, 10

    s$ = "Engineers " + LTrim$(Str$(AEN)) + "/" + LTrim$(Str$(TEN))
    s$ = s$ + "   Wireless " + LTrim$(Str$(AWO)) + "/" + LTrim$(Str$(TWO))
    If ENWD = 1 Then s$ = s$ + "   ENGINEERS WITHDRAWN"
    BoxKV "", s$, 10

    s$ = "Pumps " + LTrim$(Str$(PUMPN))
    If PWRM = 1 Then s$ = s$ + "   Dynamos TENDED" Else s$ = s$ + "   Dynamos idle"
    If RKTTHIS = 1 Then s$ = s$ + "   Rockets FIRED" Else s$ = s$ + "   Rockets ready"
    If PWR = 0 Then
        s$ = s$ + "   Wireless DEAD"
    ElseIf AWO = 0 Then
        s$ = s$ + "   Wireless SENT"
    Else
        s$ = s$ + "   Wireless idle"
    End If
    BoxKV "COMMITTED", s$, 12

    s$ = "Below " + LTrim$(Str$(CountBelow)) + "   Deck P:" + LTrim$(Str$(ZP(4)))
    s$ = s$ + " S:" + LTrim$(Str$(ZP(5))) + "   Davits " + LTrim$(Str$(CountDavit))
    s$ = s$ + "   Safe " + LTrim$(Str$(SAVED))
    BoxKV "SOULS", s$, 15
    BoxBot
End Sub

Sub MenuDeckhands
    CrewScreen "DECKHAND ORDERS"
    Color 7: Print "  Covered boats: "; CountBoats(0); "   Prepared: "; CountBoats(1);
    Print "   Away: "; CountBoats(2)
    If URG = 0 Then Color 14: Print "  First rocket volley also adds +15 loading urgency and +1 panic on both decks."
    Print
    Color 15: Print "  1) Prepare a boat       ";: Color 8: Print "COST 2 deckhands; uncover and swing out": Color 15
    Print "  2) Launch a boat        ";: Color 8: Print "COST 2 deckhands; only then are occupants safe": Color 15
    Print "  3) Fire rocket volley   ";: Color 8: Print "COST 1 deckhand; readiness +5; once per turn": Color 15
    Print "  0) Return to command board"
    Color 7

    c = AskNum("Deckhand order", 0, 3)
    Select Case c
        Case 1: PrepareBoat
        Case 2: LaunchBoat
        Case 3: FireRockets 2
    End Select
End Sub

Sub MenuOfficers
    CrewScreen "OFFICER ORDERS"
    Color 7: Print "  Ready boats: "; CountBoats(1); "   Port panic: "; ZK(4); "/5   Starboard panic: "; ZK(5); "/5"
    If URG = 0 Then Color 14: Print "  First rocket volley also adds +15 loading urgency and +1 panic on both decks."
    Print
    Color 15: Print "  1) Load a boat          ";: Color 8: Print "COST 1 officer; optional steward assistance": Color 15
    Print "  2) Restore crowd order  ";: Color 8: Print "COST 1 officer; panic -2 on one deck": Color 15
    Print "  3) Fire rocket volley   ";: Color 8: Print "COST 1 officer; readiness +5; once per turn": Color 15
    Print "  0) Return to command board"
    Color 7

    c = AskNum("Officer order", 0, 3)
    Select Case c
        Case 1: LoadBoat
        Case 2: Organize 1
        Case 3: FireRockets 1
    End Select
End Sub

Sub MenuStewards
    CrewScreen "STEWARD ORDERS"
    Color 7: Print "  Below: FWD "; ZP(1); " ("; FloodName$(ZF(1)); ")   MID "; ZP(2); " ("; FloodName$(ZF(2)); ")"
    Print "  Decks: Port "; ZP(4); " / panic "; ZK(4); "   Starboard "; ZP(5); " / panic "; ZK(5)
    Print
    Color 15: Print "  1) Guide people up      ";: Color 8: Print "COST 1+ stewards; up to 80 each; flood risk": Color 15
    Print "  2) Restore crowd order  ";: Color 8: Print "COST 1 steward; panic -1 on one deck": Color 15
    Print "  3) Redirect deck crowd  ";: Color 8: Print "COST 1 steward; move up to 100 between sides": Color 15
    Print "  0) Return to command board"
    Color 14: Print "  Reserve is also a choice: each steward assisting an officer adds +25 loading."
    Color 7

    c = AskNum("Steward order", 0, 3)
    Select Case c
        Case 1: SendBelow
        Case 2: Organize 2
        Case 3: MoveCrowd
    End Select
End Sub

Sub MenuEngineers
    CrewScreen "ENGINEER ORDERS"
    Color 7: Print "  Flooding: FWD "; ZF(1); "/5   MID "; ZF(2); "/5   ENG "; ZF(3); "/5   ";
    If PWR = 1 Then Color 10: Print "POWER ON" Else Color 12: Print "POWER OUT"
    Color 7
    If TURN <= 6 Then
        Color 8: Print "  Current pump effect: 4-5 stop the rise; 2-3 can hold on even turns."
    ElseIf TURN <= 10 Then
        Color 8: Print "  Current pump effect: weakened; 2-5 can hold only on even turns."
    Else
        Color 12: Print "  Current pump effect: none. The sea is beyond the pumps."
    End If
    Print
    Color 15: Print "  1) Run pumps            ";: Color 8: Print "COST 2-5 engineers; effect shown above": Color 15
    Print "  2) Tend dynamos         ";: Color 8: Print "COST 2 engineers; protects power this turn": Color 15
    Print "  3) Withdraw engineers   ";: Color 8: Print "COST all future engineering actions; permanent": Color 15
    Print "  0) Return to command board"
    Color 7

    c = AskNum("Engineer order", 0, 3)
    If c = 0 Then Exit Sub

    If ENWD = 1 Then
        SetLast "Engineer order", "The engineers have already withdrawn from below.", 12
        Exit Sub
    End If

    Select Case c
        Case 1
            If PUMPN > 0 Then
                SetLast "Run pumps", "Pump crews are already assigned this turn.", 14
                Exit Sub
            End If
            If AEN < 2 Then
                SetLast "Run pumps", "At least 2 free engineers are required.", 12
                Exit Sub
            End If
            n = AskNum("Engineers on pumps", 2, AEN)
            AEN = AEN - n
            PUMPN = n
            If TURN > 10 Then
                SetLast "Run pumps", "Crew committed, but the pumps can no longer check the sea.", 14
            Else
                SetLast "Run pumps", LTrim$(Str$(n)) + " engineers assigned to fight the flooding.", 10
            End If

        Case 2
            If PWR = 0 Then
                SetLast "Tend dynamos", "Too late: the electrical system has already failed.", 12
                Exit Sub
            End If
            If PWRM = 1 Then
                SetLast "Tend dynamos", "The dynamos are already tended this turn.", 14
                Exit Sub
            End If
            If AEN < 2 Then
                SetLast "Tend dynamos", "Two free engineers are required.", 12
                Exit Sub
            End If
            AEN = AEN - 2: PWRM = 1
            SetLast "Tend dynamos", "Two engineers assigned; lights and wireless are protected.", 10

        Case 3
            If PUMPN > 0 Or PWRM = 1 Then
                SetLast "Withdraw engineers", "They cannot withdraw after receiving orders this turn.", 12
                Exit Sub
            End If
            y = AskNum("Withdraw for good? 1) Yes  2) No", 1, 2)
            If y = 1 Then
                ENWD = 1: AEN = 0
                SetLast "Withdraw engineers", "The black gang comes up; no more engineering actions.", 14
            End If
    End Select
End Sub

Sub MenuWireless
    CrewScreen "WIRELESS ORDERS"
    gain = 23 - TURN
    If gain < 5 Then gain = 5
    If WIRE = 0 Then gain = gain + 25

    Color 7: Print "  Rescue readiness: ";
    Meter "", SIGPTS, 200, 30, 1
    Print " "; SIGPTS; "/200"
    Print "  Wireless turns sent: "; WIRE; "   Value of a transmission now: +"; gain
    Print
    Color 15: Print "  1) Send CQD / SOS traffic  ";: Color 8: Print "COST 1 wireless operator; readiness +"; gain
    Color 15: Print "  0) Return to command board"
    Color 7

    c = AskNum("Wireless order", 0, 1)
    If c = 0 Then Exit Sub

    If AWO < 1 Then
        SetLast "Wireless distress", "Phillips is already transmitting this turn.", 14
    ElseIf PWR = 0 Then
        SetLast "Wireless distress", "No power: the wireless set is dead.", 12
    Else
        AWO = 0: WIRE = WIRE + 1
        SIGPTS = SIGPTS + gain
        If SIGPTS > 200 Then SIGPTS = 200

        Select Case WIRE
            Case 1
                SetLast "CQD position report", "Position acknowledged; rescue readiness +" + LTrim$(Str$(gain)) + ".", 10
            Case 2
                SetLast "CQD / SOS repeated", "More ships receive the call; readiness +" + LTrim$(Str$(gain)) + ".", 10
            Case 3
                SetLast "Carpathia contact", "Carpathia answers, 'Coming hard'; readiness +" + LTrim$(Str$(gain)) + ".", 11
            Case Else
                SetLast "Wireless update", "Phillips keeps the ether alive; readiness +" + LTrim$(Str$(gain)) + ".", 10
        End Select
    End If
End Sub

' =====================================================================
'  STATUS DISPLAY
' =====================================================================
Sub ShowStatus
    Cls
    BigBanner "SHIP STATUS - " + TimeStr$
    ShipSilhouette

    SectionHeader "HULL FLOODING"
    Color 8: Print "  Zone                    Flood meter            Souls      Condition"
    Color 7

    For i = 1 To 3
        If ZBLK(i) = 1 Then
            Color 12
        Else
            Color 15
        End If

        Print "  "; Fit$(ZN$(i), 22); " ";
        Meter "", ZF(i), 5, 18, 0
        If i = 3 Then
            Color 8: Print "  SYSTEM   ";
        Else
            Color 7: Print "  "; Fit$(LTrim$(Str$(ZP(i))), 8); " ";
        End If

        If ZBLK(i) = 1 Then
            If i = 3 Then
                Color 12: Print "FLOODED OUT"
            Else
                Color 12: Print "BLOCKED / TRAPPED"
            End If
        Else
            Color 7: Print FloodName$(ZF(i))
        End If
    Next i

    SectionHeader "BOAT DECK CROWDS"
    Color 8: Print "  Deck                    Crowd                  Panic"
    Color 7

    For i = 4 To 5
        Color 15: Print "  "; Fit$(ZN$(i), 22); " ";
        Meter "", ZP(i), 1200, 18, 2
        Print "  ";
        Meter "", ZK(i), 5, 10, 0
        Color 7: Print "  "; PanicName$(ZK(i))
    Next i

    SectionHeader "LIFEBOATS"
    Color 8: Print "  Port side                                   Starboard side"
    Color 7

    For r = 1 To 4
        b = r
        Color 15: Print "  "; BN$(b); " ";
        Color 7: Print "["; Fit$(BoatStateName$(BST(b)), 8); "] ";
        Meter "", BLD(b), 150, 10, 1
        Color 7: Print " "; Fit$(LTrim$(Str$(BLD(b))) + "/150", 8); "  ";

        b = r + 4
        Color 15: Print BN$(b); " ";
        Color 7: Print "["; Fit$(BoatStateName$(BST(b)), 8); "] ";
        Meter "", BLD(b), 150, 10, 1
        Color 7: Print " "; Fit$(LTrim$(Str$(BLD(b))) + "/150", 8)
    Next r

    SectionHeader "COMMAND SNAPSHOT"
    Color 10: Print "  Saved in launched boats: "; SAVED; Tab(45); "Wireless turns: "; WIRE
    Color 11: Print "  Rescue readiness:        "; SIGPTS; "/200"; Tab(45); "Rocket volleys: "; RKT

    If PWR = 1 Then
        Color 10: Print "  Power: ON";
    Else
        Color 12: Print "  Power: FAILED";
    End If

    Color 7: Print Tab(45); "Loaded in davits: "; CountDavit

    Color 7: Print "  Doctrine: "; DoctrineName$

    If ENWD = 1 Then
        Color 12: Print "  Engineers withdrawn from below."
    Else
        Color 7: Print "  Engineers still below unless assigned or withdrawn."
    End If

    Color 8: Print "  Crew available now: Officers"; AOF; " Deckhands"; ADH; " Stewards"; AST; " Engineers"; AEN; " Wireless"; AWO
    Color 7
    Print
    Color 14: Print "  Press any key to return to the command board..."
    Color 7
    WaitKey
End Sub

' =====================================================================
'  DOCTRINE
' =====================================================================
Sub ChooseDoctrine
    If DOC > 0 Then
        SetLast "Set doctrine", "Already fixed: " + DoctrineName$ + ".", 14
        Exit Sub
    End If

    Cls
    ShowTurnHeader
    SectionHeader "EVACUATION DOCTRINE"
    Print
    Color 15: Print "  Choose your evacuation doctrine (permanent):"
    Color 7
    Print "  1) Calm Evacuation   ";: Color 8: Print "- panic grows slower, early loading -10": Color 7
    Print "  2) Full Urgency      ";: Color 8: Print "- loading +15, panic grows faster": Color 7
    Print "  3) Families Together ";: Color 8: Print "- fewer refuse to board (min 40), loading -10": Color 7
    Print "  4) Fill Every Seat   ";: Color 8: Print "- loading +20, panic +1 if <2 officers act": Color 7
    Print "  0) Decide later"

    d = AskNum("Doctrine", 0, 4)
    If d = 0 Then Exit Sub

    DOC = d
    SetLast "Set doctrine", DoctrineName$ + " is now the permanent standing order.", 10
End Sub

Sub PrepareBoat
    If ADH < 2 Then
        SetLast "Prepare boat", "Two free deckhands are required.", 12
        Exit Sub
    End If

    b = PickBoat(0, "Prepare which boat")
    If b <= 0 Then
        If b = -1 Then SetLast "Prepare boat", "No covered boats remain.", 14
        Exit Sub
    End If

    ADH = ADH - 2
    BST(b) = 1
    SetLast "Prepare " + BN$(b), "Boat uncovered, plug checked and swung outboard.", 10
End Sub

Sub LaunchBoat
    If ADH < 2 Then
        SetLast "Launch boat", "Two free deckhands are required.", 12
        Exit Sub
    End If

    b = PickBoat(1, "Launch which boat")
    If b <= 0 Then
        If b = -1 Then SetLast "Launch boat", "No prepared boats are at the davits.", 14
        Exit Sub
    End If

    If BLD(b) < 40 Then
        If BLD(b) = 0 Then
            Color 12: Print "  "; BN$(b); " is EMPTY. Those 150 seats would be gone forever."
        Else
            Color 14: Print "  "; BN$(b); " carries only "; LTrim$(Str$(BLD(b))); " of 150. Seats lowered away are lost."
        End If
        Color 7

        y = AskNum("Lower it anyway? 1) Yes  2) No", 1, 2)
        If y = 2 Then
            SetLast "Launch " + BN$(b), "Launch cancelled; the boat remains in its davits.", 8
            Exit Sub
        End If
    End If

    ADH = ADH - 2
    BST(b) = 2
    SAVED = SAVED + BLD(b)

    SetLast "Launch " + BN$(b), LTrim$(Str$(BLD(b))) + " souls lowered away and counted safe.", 11
End Sub

Sub LoadBoat
    If AOF < 1 Then
        SetLast "Load boat", "No officer is free to supervise boarding.", 12
        Exit Sub
    End If

    b = PickBoat(1, "Load which boat")
    If b <= 0 Then
        If b = -1 Then SetLast "Load boat", "No prepared boats are available.", 14
        Exit Sub
    End If

    If BLD(b) >= 150 Then
        SetLast "Load " + BN$(b), "That boat is already filled to capacity.", 14
        Exit Sub
    End If

    If b <= 4 Then dk = 4 Else dk = 5

    If ZP(dk) = 0 Then
        SetLast "Load " + BN$(b), "No one is waiting on that side of the boat deck.", 12
        Exit Sub
    End If

    sw = 0
    If AST > 0 Then
        Print
        Color 15: Print "  COMMITMENT PREVIEW FOR "; BN$(b); ":"
        Color 8: Print "  Cost is always 1 officer. Choose optional steward assistance below."
        Color 7
        For i = 0 To AST
            pv = CalcLoad(b, i)
            Print "    "; i; " steward(s) used  ->  boards "; pv; "  ->  boat reaches "; BLD(b) + pv; "/150";
            If i > 0 Then
                If CalcLoad(b, i) = CalcLoad(b, i - 1) Then Color 14: Print "  REDUNDANT";
            End If
            Print
            Color 7
        Next i
        sw = AskNum("Stewards to assist", 0, AST)
    Else
        Color 8: Print "  No stewards are free. Officer acting alone will board "; CalcLoad(b, 0); "."
        Color 7
    End If

    requested = sw

    ' Do not consume stewards who would add no one because the boat or deck
    ' is already near empty/full. This removes a punishing input trap.
    Do While sw > 0
        If CalcLoad(b, sw - 1) = CalcLoad(b, sw) Then
            sw = sw - 1
        Else
            Exit Do
        End If
    Loop

    L = CalcLoad(b, sw)
    If L <= 0 Then
        SetLast "Load " + BN$(b), "The crowd is in chaos; no one reaches the boat.", 12
        Exit Sub
    End If

    OFNAME$ = OFFNames$(AOF)
    AOF = AOF - 1
    OFUSED = OFUSED + 1
    AST = AST - sw

    BLD(b) = BLD(b) + L
    ZP(dk) = ZP(dk) - L

    out$ = "Officer " + OFNAME$ + " boards " + LTrim$(Str$(L))
    out$ = out$ + "; " + LTrim$(Str$(BLD(b))) + "/150 now aboard."
    If requested > sw Then out$ = out$ + " Redundant stewards kept free."
    SetLast "Load " + BN$(b), out$, 10
End Sub

Function CalcLoad (b, sw)
    If b <= 4 Then dk = 4 Else dk = 5
    L = 40 + 25 * sw
    pk = ZK(dk)

    If pk >= 2 And pk <= 3 Then L = L + 20
    If pk >= 4 Then L = L - 20
    If DOC = 1 And TURN <= 5 Then L = L - 10
    If DOC = 2 Then L = L + 15
    If DOC = 3 Then L = L - 10
    If DOC = 4 Then L = L + 20
    If URG = 1 Then L = L + 15

    mn = 20
    If DOC = 3 Then mn = 40
    If pk = 5 And DOC <> 3 Then mn = 0
    If L < mn Then L = mn
    If L > 150 - BLD(b) Then L = 150 - BLD(b)
    If L > ZP(dk) Then L = ZP(dk)
    If L < 0 Then L = 0
    CalcLoad = L
End Function

Sub SendBelow
    If AST < 1 Then
        SetLast "Guide passengers", "No steward is free to go below.", 12
        Exit Sub
    End If

    Print
    Color 8
    Print "  Below decks:  1) "; Fit$(ZN$(1), 20); LTrim$(Str$(ZP(1))); " people, "; FloodName$(ZF(1))
    Print "                2) "; Fit$(ZN$(2), 20); LTrim$(Str$(ZP(2))); " people, "; FloodName$(ZF(2))
    Color 7

    src = AskNum("Guide passengers up from which zone", 1, 2)

    If ZBLK(src) = 1 Then
        SetLast "Guide passengers", ZN$(src) + " is flooded out and unreachable.", 12
        Exit Sub
    End If

    If ZP(src) = 0 Then
        SetLast "Guide passengers", "No one remains in " + ZN$(src) + ".", 14
        Exit Sub
    End If

    If ZF(src) >= 3 Then
        Color 12: Print "  The water down there is dangerous. Stewards may not come back."
        Color 7
    End If

    side = AskNum("Lead them to: 1) Port deck  2) Starboard deck", 1, 2)
    dk = 3 + side

    maxn = Int((ZP(src) + 79) / 80)
    If maxn > AST Then maxn = AST

    risk = 0
    If ZF(src) = 3 Then risk = 10
    If ZF(src) >= 4 Then risk = 30
    Print
    Color 15: Print "  COMMITMENT PREVIEW:"
    Color 8: Print "  Cost: 1 steward each. Available: "; AST; ". Maximum useful here: "; maxn; "."
    Print "  Effect: up to 80 people guided per steward to the "; ZN$(dk); "."
    If risk > 0 Then
        Color 12: Print "  Risk: each steward has a "; risk; "% chance of being lost before returning."
    Else
        Color 10: Print "  Risk: no steward-loss roll at the present flood level."
    End If
    Color 7
    n = AskNum("How many stewards", 1, maxn)

    AST = AST - n
    moved = 0
    lostn = 0

    For i = 1 To n
        risk = 0
        If ZF(src) = 3 Then risk = .1
        If ZF(src) >= 4 Then risk = .3

        If Rnd < risk Then
            TST = TST - 1
            CREWLOST = CREWLOST + 1
            lostn = lostn + 1
        Else
            m = 80
            If m > ZP(src) Then m = ZP(src)
            ZP(src) = ZP(src) - m
            ZP(dk) = ZP(dk) + m
            moved = moved + m
        End If
    Next i

    If lostn > 0 Then
        out$ = LTrim$(Str$(moved)) + " brought up; " + LTrim$(Str$(lostn))
        out$ = out$ + " steward(s) lost in the flooding."
        SetLast "Guide passengers", out$, 12
    Else
        SetLast "Guide passengers", LTrim$(Str$(moved)) + " brought safely to the " + ZN$(dk) + ".", 10
    End If
End Sub

Sub MoveCrowd
    If AST < 1 Then
        SetLast "Redirect deck crowd", "No steward is free.", 12
        Exit Sub
    End If

    Print
    Color 7: Print "  Port deck: "; ZP(4); " waiting   Starboard deck: "; ZP(5); " waiting"
    Color 8: Print "  COST 1 steward. EFFECT: move up to 100 waiting people between sides."
    Color 7
    side = AskNum("Move people FROM: 1) Port  2) Starboard", 1, 2)
    src = 3 + side
    If src = 4 Then dst = 5 Else dst = 4

    If ZP(src) <= 0 Then
        SetLast "Redirect deck crowd", "No one is waiting on the selected side; no steward spent.", 14
        Exit Sub
    End If

    maxn = ZP(src)
    If maxn > 100 Then maxn = 100
    n = AskNum("How many people to redirect", 1, maxn)

    AST = AST - 1
    ZP(src) = ZP(src) - n
    ZP(dst) = ZP(dst) + n
    SetLast "Redirect deck crowd", LTrim$(Str$(n)) + " moved across; 1 steward committed.", 10
End Sub

' =====================================================================
'  SHARED ACTIONS
' =====================================================================
Sub Organize (who)
    If who = 1 And AOF < 1 Then
        SetLast "Control crowd", "No officer is free.", 12
        Exit Sub
    End If

    If who = 2 And AST < 1 Then
        SetLast "Control crowd", "No steward is free.", 12
        Exit Sub
    End If

    d = AskNum("Calm which deck: 1) Port  2) Starboard", 1, 2)
    dk = 3 + d

    If ZK(dk) = 0 Then
        SetLast "Control crowd", "That deck is already calm; no crew member was spent.", 14
        Exit Sub
    End If

    n$ = "A steward"

    If who = 1 Then
        n$ = "Officer " + OFFNames$(AOF)
        AOF = AOF - 1
        OFUSED = OFUSED + 1
        drop = 2
    Else
        drop = 1
    End If

    If who = 2 Then AST = AST - 1

    ZK(dk) = ZK(dk) - drop
    If ZK(dk) < 0 Then ZK(dk) = 0

    SetLast "Control crowd", n$ + " restores order; panic now " + LTrim$(Str$(ZK(dk))) + "/5.", 10
End Sub

Sub FireRockets (who)
    If RKTTHIS = 1 Then
        SetLast "Fire rockets", "A rocket volley has already been fired this turn.", 14
        Exit Sub
    End If

    If who = 1 And AOF < 1 Then
        SetLast "Fire rockets", "No officer is free.", 12
        Exit Sub
    End If

    If who = 2 And ADH < 1 Then
        SetLast "Fire rockets", "No deckhand is free.", 12
        Exit Sub
    End If

    n$ = "A deckhand"

    If who = 1 Then
        n$ = "Officer " + OFFNames$(AOF)
        AOF = AOF - 1
        OFUSED = OFUSED + 1
    End If

    If who = 2 Then ADH = ADH - 1

    RKT = RKT + 1: RKTTHIS = 1
    SIGPTS = SIGPTS + 5
    If SIGPTS > 200 Then SIGPTS = 200

    If URG = 0 Then
        URG = 1
        If ZK(4) < 5 Then ZK(4) = ZK(4) + 1
        If ZK(5) < 5 Then ZK(5) = ZK(5) + 1
        SetLast "Fire first rocket volley", n$ + " reveals the emergency; readiness +5, panic +1.", 14
    Else
        SetLast "Fire rocket volley", "Lookouts may see the white bursts; rescue readiness +5.", 10
    End If
End Sub

' =====================================================================
'  DISASTER PROGRESSION
' =====================================================================
Sub ResolveTurn
    Cls
    ShowTurnHeader
    BigBanner "ORDER RESOLUTION"
    Color 8: Print "  "; String$(74, Chr$(196))
    Color 11: Print "  The orders are carried out. Ten minutes pass..."
    Color 8: Print "  "; String$(74, Chr$(196))
    Color 7

    n = PUMPN + 2 * PWRM

    If n > 0 And ZF(3) >= 4 Then
        For i = 1 To n
            If Rnd < .25 And TEN > 0 Then
                TEN = TEN - 1
                CREWLOST = CREWLOST + 1
                Color 12: Print "  *** An engineer is lost below. ***"
                Color 7
            End If
        Next i
    End If

    f1 = ZF(1)
    f2 = ZF(2)
    of1 = ZF(1): of2 = ZF(2): of3 = ZF(3)
    eff = PUMPN

    If TURN > 6 And eff > 3 Then eff = 3
    If TURN > 10 Then eff = 0

    grow = 1

    If eff >= 4 Then grow = 0
    If eff >= 2 And eff < 4 And (TURN Mod 2) = 0 Then grow = 0

    If grow = 1 Then
        If ZF(1) < 5 Then ZF(1) = ZF(1) + 1
        If f1 >= 5 And ZF(2) < 5 Then ZF(2) = ZF(2) + 1
        If f2 >= 5 And ZF(3) < 5 Then ZF(3) = ZF(3) + 1
    End If

    ' --- narrate what the sea did ---
    If ZF(1) > of1 Or ZF(2) > of2 Or ZF(3) > of3 Then
        Color 14: Print "  The sea gains ground:";
        If ZF(1) > of1 Then Print " FWD now "; FloodName$(ZF(1)); ".";
        If ZF(2) > of2 Then Print " MID now "; FloodName$(ZF(2)); ".";
        If ZF(3) > of3 Then Print " ENG now "; FloodName$(ZF(3)); ".";
        Print
        Color 7
        If PUMPN > 0 Then
            Color 8: Print "  The pumps slow the water but cannot stop it."
            Color 7
        End If
    Else
        If PUMPN > 0 Then
            Color 10: Print "  The pumps hold. No ground lost to the sea this turn."
            Color 7
        End If
    End If

    For i = 1 To 3
        If ZF(i) = 5 And ZBLK(i) = 0 Then
            ZBLK(i) = 1
            Color 12: Print "  *** "; ZN$(i); " is flooded out and BLOCKED. ***"
            If ZP(i) > 0 Then Print "      "; ZP(i); " souls are trapped inside."
            Color 7
        End If
    Next i

    If PWR = 1 Then
        If ZF(3) >= 5 Or (ZF(3) >= 3 And PWRM = 0) Then
            PWR = 0
            PWRFAILT = TURN
            Color 12: Print "  *** THE LIGHTS FLICKER AND DIE. The wireless falls silent. ***"
            Color 7
        End If
    End If

    k = 3
    If DOC = 1 Then k = 4
    If DOC = 2 Then k = 2

    pgrow = 0

    If (TURN Mod k) = 0 Then pgrow = pgrow + 1
    If PWR = 0 Then pgrow = pgrow + 1
    If DOC = 4 And OFUSED < 2 Then pgrow = pgrow + 1

    If pgrow > 0 Then
        For i = 4 To 5
            ZK(i) = ZK(i) + pgrow
            If ZK(i) > 5 Then ZK(i) = 5
        Next i

        Color 14: Print "  The crowds grow more restless. (Panic +"; LTrim$(Str$(pgrow)); ")"
        Color 7
    End If

    Color 12
    If ZF(1) >= 4 And ZP(1) > 0 Then Print "  Water is climbing fast in the Forward decks!"
    If ZF(2) >= 4 And ZP(2) > 0 Then Print "  Midship compartments are going under!"
    If ZF(3) >= 3 And PWR = 1 Then Print "  The engine room is taking water. Power is at risk."
    If TURN = 12 Then Print "  *** The bow is well down. Perhaps 40 minutes remain. ***"
    If TURN = 15 Then Print "  *** Ten minutes remain. The next turn is your last. ***"
    Color 7

    ' --- endgame davit warning ---
    If TURN >= 13 Then
        w = 0
        For b = 1 To 8
            If BST(b) = 1 And BLD(b) > 0 Then w = w + BLD(b)
        Next b

        If w > 0 Then
            Color 12: Print "  *** "; w; " souls are sitting in boats not yet lowered! ***"
            Color 7
        End If
    End If

    SectionHeader "END OF WATCH"
    Color 7: Print "  Below decks: "; CountBelow; "   Boat decks: "; CountDeck;
    Print "   Loaded in davits: "; CountDavit; "   Saved: "; SAVED
    If PWR = 1 Then Color 10 Else Color 12
    Print "  Power: ";
    If PWR = 1 Then Print "ON"; Else Print "OUT";
    Color 7: Print "   Rescue readiness: "; SIGPTS; "/200   Panic P:"; ZK(4); " S:"; ZK(5)
    Color 7
End Sub

' =====================================================================
'  SCORING
' =====================================================================
Sub FinalReport
    Cls
    Print
    ShowSinkingShip

    Color 11: Print "  "; String$(74, Chr$(205))
    Color 15: Print "      2:20 AM. THE TITANIC SLIPS BENEATH THE SEA."
    Color 11: Print "  "; String$(74, Chr$(205))
    Color 7

    ' --- accounting ---
    nl = 0: unl = 0

    For b = 1 To 8
        If BST(b) = 2 Then
            nl = nl + 1
        Else
            unl = unl + BLD(b)
        End If
    Next b

    trapped = 0: below = 0
    For i = 1 To 2
        If ZBLK(i) = 1 Then trapped = trapped + ZP(i) Else below = below + ZP(i)
    Next i

    deck = ZP(4) + ZP(5)

    resc = SIGPTS
    If resc > 200 Then resc = 200
    If resc > deck + unl Then resc = deck + unl

    tot = SAVED + resc
    If tot > 2200 Then tot = 2200

    SectionHeader "THE RECKONING"
    Color 7: Print "    Saved in the lifeboats:       "; SAVED
    Color 7: Print "    Pulled alive from the sea:    "; resc;
    Color 8: Print "  (rescue readiness "; LTrim$(Str$(SIGPTS)); "/200)"
    Print
    Color 10: Print "    TOTAL SAVED:                  "; tot
    Color 12: Print "    TOTAL LOST:                   "; 2200 - tot
    Print
    Color 8: Print "    Souls, saved vs lost:  ";
    Meter "", tot, 2200, 40, 1
    Print

    SectionHeader "WHERE THOSE LEFT ABOARD WERE AT 2:20"
    If trapped > 0 Then Color 12: Print "    Trapped in flooded compartments:  "; trapped
    If below > 0 Then Color 7: Print "    Still below decks at the end:      "; below
    If deck > 0 Then Color 7: Print "    On the boat decks, into the sea:   "; deck
    If unl > 0 Then Color 12: Print "    In boats NEVER LAUNCHED:           "; unl
    If trapped = 0 And below = 0 And deck = 0 And unl = 0 Then
        Color 10: Print "    Every soul who could reach a boat was in one."
    End If
    If resc > 0 Then
        Color 8: Print "    ("; LTrim$(Str$(resc)); " of those reaching the water were recovered alive.)"
    End If
    Color 7

    SectionHeader "THE LOG"
    If nl > 0 Then util = Int((SAVED / (nl * 150)) * 100 + .5) Else util = 0
    crewfinal = CREWLOST
    If ENWD = 0 Then crewfinal = crewfinal + TEN

    Color 8: Print "    Boats launched: "; nl; "/8   Seat use: "; util; "%   Wireless turns: "; WIRE; "   Rockets: "; RKT
    Color 8: Print "    Operational crew lost below: "; crewfinal

    If PWRFAILT > 0 Then
        Color 8: Print "    Power failed on turn: "; PWRFAILT
    Else
        Color 8: Print "    Power held to the end."
    End If
    Print

    Color 14: Print "  Press any key for the rescue ship's report..."
    Color 7
    WaitKey

    Cls
    ShowDawn

    SectionHeader "AGAINST HISTORY"
    Color 7: Print "    In 1912:  705 saved   ";
    Meter "", 705, 2200, 30, 1
    Print
    Color 15: Print "    You:     "; Fit$(LTrim$(Str$(tot)), 4); " saved   ";
    Meter "", tot, 2200, 30, 1
    Print

    Color 11: Print "  "; String$(74, Chr$(205))
    Color 14: Print "    COMMAND RATING: ";
    Select Case tot
        Case Is < 706
            Print "WORSE THAN HISTORY"
        Case 706 To 899
            Print "A HARD-WON IMPROVEMENT"
        Case 900 To 1049
            Print "STRONG COMMAND"
        Case 1050 To 1199
            Print "EXCELLENT COMMAND"
        Case 1200 To 1349
            Print "MASTERFUL COMMAND"
        Case Else
            Print "A NEAR-PERFECT EVACUATION"
    End Select
    Color 11: Print "  "; String$(74, Chr$(205))
    Color 7

    SectionHeader "COMMENDATIONS"
    awards = 0
    If nl = 8 Then Color 10: Print "    * ALL BOATS AWAY";: Color 8: Print " - every hull cleared the davits": awards = awards + 1
    If util >= 90 And nl > 0 Then Color 10: Print "    * EVERY SEAT COUNTS";: Color 8: Print " - launched boats averaged 90%+ full": awards = awards + 1
    If PWRFAILT = 0 Then Color 10: Print "    * LIGHTS TO THE END";: Color 8: Print " - power held until the sinking": awards = awards + 1
    If WIRE >= 3 Then Color 10: Print "    * ANSWERED ON THE ETHER";: Color 8: Print " - firm contact made with Carpathia": awards = awards + 1
    If crewfinal = 0 Then Color 10: Print "    * NO HAND ABANDONED";: Color 8: Print " - operational crew survived below": awards = awards + 1
    If awards = 0 Then Color 8: Print "    No special commendations entered in the log."

    Print
    If tot >= 900 Then
        Color 7: Print "   4:10 AM. The Carpathia works through the ice field, and finds"
        Print "   the boats heavy in the water. Your name will be spoken with honor."
    ElseIf tot >= 750 Then
        Color 7: Print "   4:10 AM. The Carpathia finds the boats scattered on a calm sea."
        Print "   More came home than history allowed. It is something."
    Else
        Color 8: Print "   4:10 AM. The Carpathia finds too few boats, riding too light."
        Print "   The inquiry will have questions."
    End If
    Color 7
    Print
End Sub

' =====================================================================
'  INPUT HELPERS
' =====================================================================
Function AskNum (p$, lo, hi)
    Do
        Print
        Color 11: Print "  " + Chr$(175) + " ";
        Color 15: Print p$; " ["; LTrim$(Str$(lo)); "-"; LTrim$(Str$(hi)); "]: ";
        Color 7
        Line Input "", a$
        a$ = LTrim$(RTrim$(a$))

        ok = 0
        If Len(a$) > 0 Then
            ok = 1
            For i = 1 To Len(a$)
                c$ = Mid$(a$, i, 1)
                If c$ < "0" Or c$ > "9" Then ok = 0
            Next i
        End If

        If ok = 1 Then
            v = Val(a$)
            If v >= lo And v <= hi And v = Int(v) Then
                AskNum = v
                Exit Function
            End If
        End If

        Color 12: Print "     (Enter a number from "; LTrim$(Str$(lo)); " to "; LTrim$(Str$(hi)); ".)"
        Color 7
    Loop
End Function

' Lists boats currently in state 'want' (0=covered, 1=ready) and asks
' the player to choose one. Returns the boat index, 0 for cancel,
' or -1 if none were eligible.
Function PickBoat (want, p$)
    n = 0
    Print
    If want = 0 Then
        Color 8: Print "  Covered boats:  ";
    Else
        Color 8: Print "  Ready at davits:  ";
    End If

    For b = 1 To 8
        If BST(b) = want Then
            n = n + 1
            Color 15: Print BN$(b);
            Color 8: Print "("; LTrim$(Str$(b)); ")";
            If want = 1 Then
                Color 7: Print " "; LTrim$(Str$(BLD(b))); "/150";
            End If
            Print "  ";
        End If
    Next b
    Print
    Color 7

    If n = 0 Then
        Color 14: Print "  None available.": Color 7
        PickBoat = -1
        Exit Function
    End If

    Do
        b = AskNum(p$ + " (0 cancels)", 0, 8)

        If b = 0 Then
            PickBoat = 0
            Exit Function
        End If

        If BST(b) = want Then
            PickBoat = b
            Exit Function
        End If

        Color 12: Print "  "; BN$(b); " is not eligible.": Color 7
    Loop
End Function

Function CountBelow
    CountBelow = ZP(1) + ZP(2)
End Function

Function CountDeck
    CountDeck = ZP(4) + ZP(5)
End Function

Function CountDavit
    n = 0
    For b = 1 To 8
        If BST(b) = 1 Then n = n + BLD(b)
    Next b
    CountDavit = n
End Function

Function CountBoats (want)
    n = 0
    For b = 1 To 8
        If BST(b) = want Then n = n + 1
    Next b
    CountBoats = n
End Function

Sub SetLast (act$, result$, clr)
    LASTACT$ = act$
    LASTOUT$ = result$
    LASTCLR = clr
End Sub

Sub WaitKey
    _KeyClear
    Do: _Limit 60: Loop While InKey$ = ""
End Sub

' =====================================================================
'  CLOCK
' =====================================================================
Function TimeStr$
    t = 23 * 60 + 40 + (TURN - 1) * 10
    h = Int(t / 60) Mod 24
    m = t Mod 60

    ap$ = " AM"
    hh = h

    If h >= 12 Then ap$ = " PM"
    If h > 12 Then hh = h - 12
    If h = 0 Then hh = 12

    m$ = LTrim$(Str$(m))
    If Len(m$) < 2 Then m$ = "0" + m$

    ans$ = LTrim$(Str$(hh)) + ":" + m$ + ap$
    If Len(ans$) < 8 Then ans$ = " " + ans$
    TimeStr$ = ans$
End Function

' =====================================================================
'  INTRO / MANUAL
' =====================================================================
Sub ShowIntro
    Cls
    Print
    Color 8
    Print "       .          *              .          *              .         *"
    Print "  *          .           *              .          *             ."
    Print "                       (          (          (          ("
    Print "                        )          )          )          )"
    Color 7
    Print "                       ||         ||         ||         ||"
    Print "                      _||_       _||_       _||_       _||_"
    Color 14
    Print "                     /____\     /____\     /____\     /____\"
    Color 15
    Print "            ________|____|_____|____|_____|____|_____|____|________"
    Print "       ____/  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _   \____"
    Print "   ___/______________________________________________________________\___"
    Print "  /  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o     \"
    Color 14: Print " /____ R  M  S _____ T  I  T  A  N  I  C _______________________________\"
    Color 15: Print " \______________________________________________________________________/-'"
    Color 11
    Print " ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ /\ ~"
    Color 15
    Print "                                                               ___/  \___"

    BigBanner "T I T A N I C :  1 6 0  M I N U T E S  -  2.5.1"

    Color 7
    Print "   11:40 PM, April 14, 1912. The ship has struck ice."
    Print "   She will sink at 2:20 AM. That is arithmetic, not opinion."
    Print
    Print "   2,200 souls aboard. 1,200 lifeboat seats. Sixteen turns of ten minutes."
    Color 15: Print "   Your crew:  ";
    Color 7: Print "4 officers, 6 deckhands, 6 stewards, 5 engineers, 1 wireless man."
    Print
    Print "   PREPARE the boats. Bring people UP. LOAD every seat. LAUNCH in time."
    Print "   Hold the flooding. Keep the lights alive. Put your position on the air."
    Print
    Color 12: Print "   The ship is lost. Your decisions determine how many people are not."
    Color 11: Print "   "; String$(74, Chr$(196))
    Color 7
    Print "   Press any key to assume command..."

    WaitKey
End Sub

Sub ShowManual
    Cls
    Print
    BigBanner "FIELD MANUAL - PAGE 1 OF 2"

    SectionHeader "ISSUING ORDERS"
    Color 7
    Print "   Commands are organized by crew group. Every order screen keeps the full"
    Print "   live crew ledger visible and states its cost before you commit."
    Print "   After an order, the command board is redrawn with its exact result."

    SectionHeader "THE BOAT PIPELINE"
    Color 7
    Print "   PREPARE (2 deckhands)  ->  LOAD (1 officer)  ->  LAUNCH (2 deckhands)"
    Print "   Each boat holds 150. Loading a boat does NOT save anyone -"
    Color 12: Print "   only a LAUNCHED boat counts. Boats in the davits go down with her."
    Color 7

    SectionHeader "LOADING A BOAT"
    Print "   Base 40 per officer, +25 per assisting steward."
    Print "   Moderate panic (2-3) speeds boarding +20; high panic (4+) slows it -20."
    Print "   The first rocket volley adds urgency (+15 loading) but raises panic."
    Print "   Before commitment, a preview lists the exact result for every possible"
    Print "   number of assisting stewards. Redundant stewards are kept free."

    SectionHeader "BELOW DECKS"
    Print "   1,600 people start below. Stewards bring up 80 each per trip."
    Print "   Flooding runs FORWARD -> MIDSHIP -> ENGINEERING. A zone that fills"
    Print "   completely is BLOCKED: everyone still inside is trapped."
    Color 12: Print "   Stewards can drown in waist-deep water or worse."
    Color 7: Print "   A steward may instead calm one deck (-1 panic), redirect up to 100"
    Print "   waiting people between sides, or remain free to assist boat loading."

    SectionHeader "THE SEA AND THE PUMPS"
    Print "   The water rises every turn. 4+ engineers on pumps can stop it cold"
    Print "   early on; 2-3 slow it to every other turn. Pumps weaken after"
    Print "   the first hour and are useless past 1:20 AM."

    Print
    Color 14: Print "  Press any key for page 2..."
    Color 7
    WaitKey

    Cls
    Print
    BigBanner "FIELD MANUAL - PAGE 2 OF 2"

    SectionHeader "POWER AND DISTRESS"
    Color 7
    Print "   If Engineering reaches waist-deep flooding without tended dynamos,"
    Print "   the lights and wireless fail. Darkness also raises panic every turn."
    Print "   Wireless calls add RESCUE READINESS; early reports are worth more."
    Print "   The first valid position is especially valuable. Rocket volleys add 5."
    Print "   Readiness becomes water rescues at the end, capped at 200 and by the"
    Print "   number of people who actually reach the water."

    SectionHeader "PANIC AND CONTROL"
    Print "   Panic normally rises every third turn. Calm Evacuation slows it; Full"
    Print "   Urgency accelerates it. Darkness and neglected Fill Every Seat orders"
    Print "   can add more. An officer reduces panic by 2; a steward reduces it by 1."

    SectionHeader "THE FOUR DOCTRINES"
    Print "   CALM: slower panic; -10 loading through turn 5."
    Print "   URGENCY: +15 loading; panic rises every second turn."
    Print "   FAMILIES: -10 loading, but even chaos preserves a 40-person minimum."
    Print "   EVERY SEAT: +20 loading; panic +1 if fewer than 2 officers act."

    SectionHeader "WHAT COUNTS"
    Color 12: Print "   People in loaded boats are not saved until the boat is launched."
    Color 7: Print "   The final report compares you with the historical 705 survivors."
    Print "   The practical ceiling is 1,400: all 1,200 seats plus 200 water rescues."

    Print
    Color 14: Print "  Press any key to return to the command board..."
    Color 7
    WaitKey
End Sub

' =====================================================================
'  VISUAL HELPERS
' =====================================================================
Sub ShowTurnHeader
    Print
    Color 11: Print "  "; Chr$(201); String$(74, Chr$(205)); Chr$(187)

    Color 11: Print "  "; Chr$(186);
    Color 15: Print " TURN"; Fit$(Str$(TURN), 3); " OF 16";
    Color 14: Print Space$(10); TimeStr$; Space$(10);
    Color 12: Print "MINUTES LEFT: "; Fit$(Str$(170 - TURN * 10), 4);
    Color 11: Print Space$(14); Chr$(186)

    Color 11: Print "  "; Chr$(186);
    Color 8: Print " Progress ";
    Meter "", TURN - 1, 16, 40, 1
    Color 11: Print Space$(22); Chr$(186)

    If PWR = 0 Then
        Color 11: Print "  "; Chr$(186);
        Color 12: Print Fit$(" *** THE SHIP IS DARK. The wireless is dead. ***", 74);
        Color 11: Print Chr$(186)
    End If

    Color 11: Print "  "; Chr$(200); String$(74, Chr$(205)); Chr$(188)
    Color 7
End Sub

Sub TurnFlavor
    Select Case TURN
        Case 1: f$ = "Ice litters the forward well deck. Below, stokers race rising water."
        Case 2: f$ = "The mail room is awash. Clerks drag sodden sacks up the stairs."
        Case 3: f$ = "Thomas Andrews gives her an hour and a half. Perhaps two."
        Case 4: f$ = "Capt. Smith: 'Get the boats ready. Women and children first.'"
        Case 5: f$ = "Stewards pound on cabin doors. Many passengers refuse to believe."
        Case 6: f$ = "Somewhere aft, the band begins to play. Ragtime, brightly."
        Case 7: f$ = "A steamer's lights stand motionless on the northern horizon."
        Case 8: f$ = "The bow is noticeably down. Water climbs the forward stairways."
        Case 9: f$ = "The orchestra moves up to the boat deck and plays on."
        Case 10: f$ = "The distant lights still refuse to answer. The cold deepens."
        Case 11: f$ = "A dull roar below - the sea claiming the forward holds."
        Case 12: f$ = "The forecastle head is nearly awash. The list grows."
        Case 13: f$ = "Deck chairs slide. Passengers cling to the high-side rail."
        Case 14: f$ = "Green water rolls over the bow. The stern begins to lift."
        Case 15: f$ = "It is hard to stand. Everything loose goes clattering forward."
        Case Else: f$ = "Minutes now. Anything still aboard is going down with her."
    End Select

    Color 3: Print "   SHIP'S LOG: ";
    Color 8: Print f$
    Color 7
End Sub

Sub ShowSinkingShip
    Color 8
    Print "       *          .            *          .           *         ."
    Print "  .          *          .            .         *          .          *"
    Color 7
    Print "                                                      )       )"
    Print "                                                     (       ("
    Print "                                                      |       |"
    Print "                                                     _|_     _|_"
    Color 14: Print "                                                    /___\   /___\"
    Color 15
    Print "                                             _______|___|___|___|_"
    Print "                                        ____/  o  o  o  o  o  o   \"
    Print "                                   ____/ o  o  o  o  o  o           |"
    Print "                              ____/   R M S  T I T A N I C          |"
    Print "                         ____/_____________________________________.'"
    Color 11
    Print " ~ ~ ~ ~ ~ ~ ~ ~ ~ ~/ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~"
    Color 7

    ' one boat on the water for every boat that got away
    n = 0
    For b = 1 To 8
        If BST(b) = 2 Then n = n + 1
    Next b

    If n > 0 Then
        Print "     ";
        For i = 1 To n
            Color 15: Print "<==>";
            Color 11: Print " ~ ~ ";
        Next i
        Print
        Color 7
    End If
End Sub

Sub ShowDawn
    Print
    Color 8
    Print "  .              .                    DAWN                    ."
    Print "                              ("
    Print "                               )"
    Color 7: Print "                               |              |"
    Print "                              _|_          ___|___"
    Color 14: Print "                             /___\        /_______\"
    Color 15
    Print "                     ________|___|________|_______|_____"
    Print "                ____/  o  o  o  o  R M S  C A R P A T H I A \____"
    Print "               /________________________________________________\"
    Print "               \________________________________________________/"
    Color 11
    Print " ~ <==> ~ ~ <==> ~ ~ ~ <==> ~ ~ \__________________/ ~ ~ <==> ~ ~ <==> ~"
    Color 7
End Sub

Sub BigBanner (t$)
    Print
    w = Len(t$) + 4
    pad = (80 - w) \ 2
    Color 11
    Print Space$(pad); Chr$(201); String$(w, Chr$(205)); Chr$(187)
    Print Space$(pad); Chr$(186);
    Color 15: Print "  "; t$; "  ";
    Color 11: Print Chr$(186)
    Print Space$(pad); Chr$(200); String$(w, Chr$(205)); Chr$(188)
    Color 7
    Print
End Sub

Sub SectionHeader (t$)
    Print
    Color 11: Print "  "; Chr$(204); String$(3, Chr$(205));
    Color 15: Print " "; t$; " ";
    Color 11: Print String$(68 - Len(t$), Chr$(205)); Chr$(185)
    Color 7
End Sub

Sub HRule (c, ch$)
    Color c
    If ch$ = "=" Then ch$ = Chr$(205)
    If ch$ = "-" Then ch$ = Chr$(196)
    Print "  "; String$(76, ch$)
    Color 7
End Sub

Sub BoxTop
    Color 11: Print "  "; Chr$(218); String$(74, Chr$(196)); Chr$(191)
    Color 7
End Sub

Sub BoxBot
    Color 11: Print "  "; Chr$(192); String$(74, Chr$(196)); Chr$(217)
    Color 7
End Sub

Sub BoxKV (label$, rest$, lc)
    Color 11: Print "  "; Chr$(179);
    Color lc: Print " "; Fit$(label$, 9);
    Color 7: Print Fit$(rest$, 64);
    Color 11: Print Chr$(179)
    Color 7
End Sub

Sub BoxWrap (label$, rest$, lc)
    If Len(rest$) <= 64 Then
        BoxKV label$, rest$, lc
        Exit Sub
    End If

    cut = 64
    Do While cut > 1 And Mid$(rest$, cut, 1) <> " "
        cut = cut - 1
    Loop
    If cut < 2 Then cut = 64

    BoxKV label$, Left$(rest$, cut), lc
    BoxKV "", LTrim$(Mid$(rest$, cut + 1)), lc
End Sub

Sub ShipSilhouette
    Print
    Color 8
    Print "                     ||          ||          ||          ||"
    Print "                    _||_        _||_        _||_        _||_"
    Color 14: Print "                   /____\      /____\      /____\      /____\"
    Color 7
    Print "   BOW      ___----|____|------|____|------|____|------|____|----___  STERN"
    Color 15
    Print "        ___/ o  o  o  o  o  R M S  T I T A N I C  o  o  o  o \___"
    Print "       /__________________________________________________________\"
    Color 11
    Print "  ~ ~ /_______FWD________/________MID________/________ENG________\ ~ ~ ~ ~"
    Color 7
    Print Space$(12);
    FloodCell 1
    Print Space$(8);
    FloodCell 2
    Print Space$(8);
    FloodCell 3
    Print
    Color 7
    Print
End Sub

' Prints a fixed-width (9 char) flood readout so the row stays aligned.
Sub FloodCell (i)
    If ZBLK(i) = 1 Then
        Color 12: Print "[BLOCKED]";
    Else
        Select Case ZF(i)
            Case 0, 1
                Color 10
            Case 2, 3
                Color 14
            Case Else
                Color 12
        End Select

        Print "[F"; LTrim$(Str$(ZF(i))); "/5]   ";
    End If

    Color 7
End Sub

Sub Meter (label$, amount, maxv, wid, mode)
    If label$ <> "" Then Print Fit$(label$, 18); " ";

    v = amount
    If v < 0 Then v = 0
    If v > maxv Then v = maxv
    If maxv <= 0 Then maxv = 1

    bars = Int((v / maxv) * wid + .5)

    If bars < 0 Then bars = 0
    If bars > wid Then bars = wid

    pct = v / maxv
    Color 8: Print "[";

    If mode = 0 Then
        If pct < .4 Then Color 10 Else If pct < .8 Then Color 14 Else Color 12
    ElseIf mode = 1 Then
        If pct < .35 Then Color 8 Else If pct < .85 Then Color 11 Else Color 10
    Else
        Color 11
    End If

    If bars > 0 Then Print String$(bars, Chr$(219));
    Color 8
    If wid - bars > 0 Then Print String$(wid - bars, Chr$(176));
    Print "]";
    Color 7
End Sub

Function Fit$ (s$, w)
    t$ = s$
    If Len(t$) > w Then t$ = Left$(t$, w)
    Fit$ = t$ + Space$(w - Len(t$))
End Function

Function ZoneTag$ (i)
    If ZBLK(i) = 1 Then
        ZoneTag$ = "LOST"
    Else
        ZoneTag$ = LTrim$(Str$(ZF(i))) + "/5"
    End If
End Function

Function DoctrineName$
    Select Case DOC
        Case 0: DoctrineName$ = "No doctrine"
        Case 1: DoctrineName$ = "Calm Evacuation"
        Case 2: DoctrineName$ = "Full Urgency"
        Case 3: DoctrineName$ = "Families Together"
        Case 4: DoctrineName$ = "Fill Every Seat"
        Case Else: DoctrineName$ = "Unknown"
    End Select
End Function

Function BoatStateName$ (s)
    Select Case s
        Case 0: BoatStateName$ = "Covered"
        Case 1: BoatStateName$ = "Ready"
        Case 2: BoatStateName$ = "Away"
        Case Else: BoatStateName$ = "Unknown"
    End Select
End Function

Function FloodName$ (f)
    Select Case f
        Case 0: FloodName$ = "Dry"
        Case 1: FloodName$ = "Seeping"
        Case 2: FloodName$ = "Taking water"
        Case 3: FloodName$ = "Waist deep"
        Case 4: FloodName$ = "Critical"
        Case Else: FloodName$ = "Flooded"
    End Select
End Function

Function PanicName$ (p)
    Select Case p
        Case 0: PanicName$ = "Calm"
        Case 1: PanicName$ = "Uneasy"
        Case 2: PanicName$ = "Restless"
        Case 3: PanicName$ = "Frightened"
        Case 4: PanicName$ = "Near riot"
        Case Else: PanicName$ = "Chaos"
    End Select
End Function

