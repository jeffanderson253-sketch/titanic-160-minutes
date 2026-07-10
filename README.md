TITANIC: 160 MINUTES

Titanic: 160 Minutes is a turn-based command game made in QB64-style BASIC.
You take command immediately after Titanic strikes the iceberg at 11:40 PM
and have sixteen ten-minute turns to bring as many of 2,200 people through
the evacuation as possible.

The ship will sink at 2:20 AM. Your job is not to save the ship; it is to
save lives.


RUNNING THE GAME

WINDOWS EXE

Run TITANIC25.EXE by double-clicking it. No installation, account, or
internet connection is required.

IMPORTANT: THE EXE IS NOT A VIRUS

TITANIC25.EXE is the compiled Windows build of this game. It is not a virus,
an installer, or bundled software package.

Because it is a small, unsigned hobby-game executable, Windows SmartScreen or
some antivirus software may show a reputation-based warning. That warning does
NOT mean the file is malware; it means Microsoft has not established a broad
download reputation for it. TITANIC25.bas is included so the game can be
inspected or compiled yourself in QB64.

As with any downloaded executable, only run a copy obtained from the intended
release/source. If you would rather not run an EXE, use the source-file method
below.

RUN FROM SOURCE WITH QB64

1. Install QB64 from https://qb64.com/
2. Open TITANIC25.bas.
3. Press F5 to run, or compile it from QB64 to make your own executable.


HOW TO PLAY

Enter the number for an order, then follow the on-screen prompts. Every order
takes place during the current ten-minute turn; crew availability resets at the
start of the next turn.

Commands are organized by crew group:

DECKHANDS
  Prepare boats, launch boats, and fire rockets.

OFFICERS
  Load boats, restore order, and fire rockets.

STEWARDS
  Guide people up from below, calm a deck, redirect crowds between port and
  starboard, or remain free to help load boats.

ENGINEERS
  Run pumps, maintain the dynamos, or withdraw from below.

WIRELESS
  Send CQD/SOS traffic and build rescue readiness.

The command board redraws after each action. It shows the crew still
available, work already committed this turn, ship condition, boat state, and
the result of your last order.


CORE RULES

- Boats must be PREPARED, LOADED, then LAUNCHED. People in a loaded boat are
  not safe until it is lowered away.
- Each boat holds 150 people. There are eight boats: 1,200 seats total.
- Stewards bring up to 80 people each from the lower decks, but deep
  floodwater can kill them.
- Officers can use free stewards to load boats faster. The game previews the
  exact result before you commit them.
- Panic affects loading. Officers reduce it by two points; stewards reduce it
  by one.
- The first rocket volley makes the emergency clear and speeds loading, but it
  also raises panic.
- Pumps buy time early. The dynamos matter once Engineering begins to flood.
- Early wireless transmissions are worth more than late ones. Rescue readiness
  can recover up to 200 people from the water at the end.


SCORING

The historical disaster left about 705 survivors. In this game, the practical
maximum is 1,400: all 1,200 lifeboat seats filled and launched, plus 200
recovered from the water.

The game is intentionally simplified rather than a literal reconstruction of
every historical detail. It is a command-and-resource-management game built
around the central tragedy: every available minute and every crew assignment
matters.


FILES

TITANIC251.EXE   Compiled Windows game
TITANIC251.bas   Complete QB64 source code
README.txt      This guide
