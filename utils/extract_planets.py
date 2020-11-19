import atari_file
import io
import array
import sys
from enum import Enum

class Item( Enum ):
	Empty = 0
	Wall = 1
	Robbo = 2
	Screw = 3
	Ammo = 4
	Bomb = 5
	Door = 6
	Key = 7
	Suprise = 8
	Exit = 9
	Box = 10
	Dust = 11
	OneUp = 12
	WallAlternate = 13
	BoxOnWheels = 14
	
	MagnetLeft = 20
	MagnetRight = 21
	
	Teleporter0 = 100
	Teleporter1 = 101
	Teleporter2 = 102
	Teleporter3 = 103
	Teleporter4 = 104
	Teleporter5 = 105
	Teleporter6 = 106
	Teleporter7 = 107
	Teleporter8 = 108
	Teleporter9 = 109
	
	LaserRight = 200
	LaserDown = 201
	LaserLeft = 202
	LaserUp = 203
	
	CannonRight = 300
	CannonDown = 301
	CannonLeft = 302
	CannonUp = 303
	RotatingCannon1 = 304
	RotatingCannon2 = 305
	
	DustCannonRight = 308
	DustCannonLeft = 309
	DustCannonDown = 310
	DustCannonUp = 311
	
	MovingCannonLeft = 312
	MovingCannonRight = 313
	
	OwlRight = 400
	OwlDown = 401
	OwlLeft = 402
	OwlUp = 403

	CreatureRight = 410
	CreatureDown = 411
	CreatureLeft = 412
	CreatureUp = 413
	
	BirdLeft = 420
	BirdRight = 421
	BirdDown = 422
	BirdUp = 423
	
	BirdUnknown1 = 425
	
	Eyes = 500
	
	BeltStart = 600
	Belt = 601
	BeltEnd = 602
	
	Void = 1000
	Error = 2000

atariToItem = {
	  ord(' ') : Item.Empty
	, 0xa0 : Item.Wall
	, 0x5c : Item.WallAlternate

	, ord('#') : Item.Box
	, 0x06 : Item.BoxOnWheels
	, ord('$') : Item.Screw
	, ord('!') : Item.Ammo
	, ord('@') : Item.Bomb
	, ord('|') : Item.Door
	, 0x12 : Item.Door     # horizontal door? Does seems to be different from vertical version
	, ord('%') : Item.Dust
	, ord('=') : Item.Key
	, ord('?') : Item.Suprise
	, 0x14 : Item.Exit
	, ord('+') : Item.OneUp
	, 0x13 : Item.Void
	, ord('(') : Item.MagnetRight
	, ord(')') : Item.MagnetLeft

	, ord('0') : Item.Teleporter0
	, ord('1') : Item.Teleporter1
	, ord('2') : Item.Teleporter2
	, ord('3') : Item.Teleporter3
	, ord('4') : Item.Teleporter4
	, ord('5') : Item.Teleporter5
	, ord('6') : Item.Teleporter6
	, ord('7') : Item.Teleporter7
	, ord('8') : Item.Teleporter8
	, ord('9') : Item.Teleporter9
	
	, 0x27 : Item.LaserDown
	, ord('^') : Item.LaserUp
	, ord('<') : Item.LaserLeft
	, ord('>') : Item.LaserRight

	, 0x1c : Item.CannonUp
	, 0x1f : Item.CannonRight
	, 0x1e : Item.CannonLeft
	, 0x1d : Item.CannonDown
	, ord('-') : Item.RotatingCannon1
	, ord(',') : Item.RotatingCannon2
	
	, 0x01 : Item.DustCannonRight
	, 0x04 : Item.DustCannonLeft
	, 0x17 : Item.DustCannonDown
	, 0x18 : Item.DustCannonUp
	
	, 0x0e : Item.MovingCannonLeft
	, 0x0d : Item.MovingCannonRight
	
	, ord('A') : Item.OwlRight
	, ord('B') : Item.OwlDown
	, ord('C') : Item.OwlLeft
	, ord('D') : Item.OwlUp

	, ord('E') : Item.CreatureRight
	, ord('F') : Item.CreatureDown
	, ord('G') : Item.CreatureLeft
	, ord('H') : Item.CreatureUp
	
	, ord( 'I') : Item.BirdLeft
	, ord( 'J') : Item.BirdRight
	, ord( 'L' ) : Item.BirdDown
	, ord( 'K' ) : Item.BirdUp
	
	, ord( 'M' ) : Item.BirdUnknown1
	
	, ord('&') : Item.Eyes
	
	, ord('*') : Item.Robbo
	
	, 0x11 : Item.BeltStart
	, 0x0f : Item.Belt
	, 0x05 : Item.BeltEnd
}

ItemToDump = {
	  Item.Empty : ' '
	, Item.Wall : '\u25A1'
	, Item.WallAlternate : '\u25A0'
	, Item.Robbo : '*'
	, Item.Screw : '$'
	, Item.Ammo : '!'
	, Item.Bomb : '@'
	, Item.Door : '|'
	, Item.Dust : '%'
	, Item.Box : '#'
	, Item.BoxOnWheels : '#'
	, Item.Key : '='
	, Item.Exit : '\u263C'
	, Item.Suprise : '?'
	, Item.OneUp : '+'
	, Item.MagnetLeft : ')'
	, Item.MagnetRight : '('
	, Item.CannonRight : '\u25B7'
	, Item.CannonDown : '\u25BD'
	, Item.CannonLeft : '\u25C1'
	, Item.CannonUp : '\u25B3'
	, Item.RotatingCannon1 : '\u25C7'
	, Item.RotatingCannon2 : '\u25C7'
	, Item.DustCannonRight : '>'
	, Item.DustCannonLeft : '<'
	, Item.DustCannonDown : 'v'
	, Item.DustCannonUp : '^'
	, Item.MovingCannonLeft : '^'
	, Item.MovingCannonRight : '^'
	, Item.LaserRight : '\u25B6'
	, Item.LaserDown : '\u25BC'
	, Item.LaserLeft : '\u25C0'
	, Item.LaserUp : '\u25B2'
	, Item.OwlRight : 'A'
	, Item.OwlDown : 'B'
	, Item.OwlLeft : 'C'
	, Item.OwlUp : 'D'
	, Item.CreatureRight : 'E'
	, Item.CreatureDown : 'F'
	, Item.CreatureLeft : 'G'
	, Item.CreatureUp : 'H'
	, Item.BirdLeft : 'I'
	, Item.BirdRight : 'J'
	, Item.BirdDown : 'L'
	, Item.BirdUp : 'K'
	, Item.BirdUnknown1 : 'M'
	, Item.Eyes : '&'
	, Item.Teleporter0 : '0'
	, Item.Teleporter1 : '1'
	, Item.Teleporter2 : '2'
	, Item.Teleporter3 : '3'
	, Item.Teleporter4 : '4'
	, Item.Teleporter5 : '5'
	, Item.Teleporter6 : '6'
	, Item.Teleporter7 : '7'
	, Item.Teleporter8 : '8'
	, Item.Teleporter9 : '9'

	, Item.BeltStart : '{'
	, Item.Belt : '-'
	, Item.BeltEnd : '}'

	, Item.Void : '.'
	, Item.Error : 'X'
}

class Planet:
	def __init__( self, data : bytearray ):
		self.m_items=[]
		for y in range( 31 ):
			self.m_items.append( [] )
			for x in range( 16 ):
				try:
					item = atariToItem[ data[ x + 16*y ] ]
				except KeyError:
					raise
					item = Item.Error
				self.m_items[ y ].append( item )
	
	def getItem( self, x : int, y : int ):
		return self.m_items[ y ][ x ]
	
		
def getPlanets( file : atari_file.ExecutableFile ):
	ram = file.prepareRam()
	planets = []
	for i in range( 56 ):
		print ( i )
		planetData = ram[0x3800 + i * 0x200 : 0x3800 + (i+1) * 0x200 ] 
		planets.append( Planet( planetData ) )
	return planets
	
def dumpPlanet( planet : Planet ):
	for y in range( 31 ):
		for x in range( 16 ):
			c = ItemToDump[ planet.getItem( x, y ) ]
			print( c, end ='' )
		print( )
	
		
if __name__ == "__main__":
	if len( sys.argv ) != 2:
		raise RuntimeError( "Expected a file name" )

#dumpPlanet( getPlanets( atari_file.ExecutableFile( sys.argv[1] ) )[49] )

i = 0
planets = getPlanets( atari_file.ExecutableFile( sys.argv[1] ) )
for planet in planets:
	print ( i )
	dumpPlanet( planet )
