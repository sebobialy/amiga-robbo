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
	
	Teleporter1 = 100
	
	LaserRight = 200
	LaserDown = 201
	LaserLeft = 202
	LaserUp = 203
	
	CannonRight = 300
	CannonDown = 301
	CannonLeft = 302
	CannonUp = 303
	
	OwlRight = 400
	OwlDown = 401
	OwlLeft = 402
	OwlUp = 403

	CreatureRight = 410
	CreatureDown = 411
	CreatureLeft = 412
	CreatureUp = 413
	
	Void = 1000

atariToItem = {
	  ord(' ') : Item.Empty
	, 0xa0 : Item.Wall

	, ord('#') : Item.Box
	, ord('$') : Item.Screw
	, ord('!') : Item.Ammo
	, ord('@') : Item.Bomb
	, ord('|') : Item.Door
	, 0x12 : Item.Door     # horizontal door? Does seems to be different from vertical version
	, ord('%') : Item.Dust
	, ord('=') : Item.Key
	, ord('?') : Item.Suprise
	, 0x14 : Item.Exit

	, ord('1') : Item.Teleporter1
	
	, 0x27 : Item.LaserDown
	, ord('^') : Item.LaserUp

	, ord('>') : Item.CannonRight
	, 0x1d : Item.CannonDown
	
	, ord('A') : Item.OwlRight
	, ord('B') : Item.OwlDown
	, ord('C') : Item.OwlLeft
	, ord('D') : Item.OwlUp

	, ord('E') : Item.CreatureRight
	, ord('F') : Item.CreatureDown
	, ord('G') : Item.CreatureLeft
	, ord('H') : Item.CreatureUp
	
	, ord('*') : Item.Robbo
}

ItemToDump = {
	  Item.Empty : ' '
	, Item.Wall : '\u25A1'
	, Item.Robbo : '*'
	, Item.Screw : '$'
	, Item.Ammo : '!'
	, Item.Bomb : '@'
	, Item.Door : '|'
	, Item.Dust : '%'
	, Item.Box : '#'
	, Item.Key : '='
	, Item.Exit : '\u263C'
	, Item.Suprise : '?'
	, Item.CannonRight : '\u25B7'
	, Item.CannonDown : '\u25BD'
	, Item.CannonLeft : '\u25C1'
	, Item.CannonUp : '\u25B3'
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
	, Item.Teleporter1 : '1'


	, Item.Void : '.'
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
					item = Item.Void
				self.m_items[ y ].append( item )
	
	def getItem( self, x : int, y : int ):
		return self.m_items[ y ][ x ]
	
		
def getPlanets( file : atari_file.ExecutableFile ):
	ram = file.prepareRam()
	planets = []
	for i in range( 56 ):
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

dumpPlanet( getPlanets( atari_file.ExecutableFile( sys.argv[1] ) )[4] )
