import atari_file
import planets
import io
import array
import sys

ItemToDump = {
	  planets.Item.Empty : ' '
	, planets.Item.Wall : '\u25A1'
	, planets.Item.WallAlternate : '\u25A0'
	, planets.Item.Robbo : '*'
	, planets.Item.Screw : '$'
	, planets.Item.Ammo : '!'
	, planets.Item.Bomb : '@'
	, planets.Item.Door : '|'
	, planets.Item.Dust : '%'
	, planets.Item.Box : '#'
	, planets.Item.BoxOnWheels : '#'
	, planets.Item.Key : '='
	, planets.Item.Exit : '\u263C'
	, planets.Item.Suprise : '?'
	, planets.Item.OneUp : '+'
	, planets.Item.MagnetLeft : ')'
	, planets.Item.MagnetRight : '('
	, planets.Item.CannonRight : '\u25B7'
	, planets.Item.CannonDown : '\u25BD'
	, planets.Item.CannonLeft : '\u25C1'
	, planets.Item.CannonUp : '\u25B3'
	, planets.Item.RotatingCannon1 : '\u25C7'
	, planets.Item.RotatingCannon2 : '\u25C7'
	, planets.Item.DustCannonRight : '>'
	, planets.Item.DustCannonLeft : '<'
	, planets.Item.DustCannonDown : 'v'
	, planets.Item.DustCannonUp : '^'
	, planets.Item.MovingCannonLeft : '^'
	, planets.Item.MovingCannonRight : '^'
	, planets.Item.LaserRight : '\u25B6'
	, planets.Item.LaserDown : '\u25BC'
	, planets.Item.LaserLeft : '\u25C0'
	, planets.Item.LaserUp : '\u25B2'
	, planets.Item.OwlRight : 'A'
	, planets.Item.OwlDown : 'B'
	, planets.Item.OwlLeft : 'C'
	, planets.Item.OwlUp : 'D'
	, planets.Item.CreatureRight : 'E'
	, planets.Item.CreatureDown : 'F'
	, planets.Item.CreatureLeft : 'G'
	, planets.Item.CreatureUp : 'H'
	, planets.Item.BirdLeft : 'I'
	, planets.Item.BirdRight : 'J'
	, planets.Item.BirdDown : 'L'
	, planets.Item.BirdUp : 'K'
	, planets.Item.BirdUnknown1 : 'M'
	, planets.Item.Eyes : '&'
	, planets.Item.Teleporter0 : '0'
	, planets.Item.Teleporter1 : '1'
	, planets.Item.Teleporter2 : '2'
	, planets.Item.Teleporter3 : '3'
	, planets.Item.Teleporter4 : '4'
	, planets.Item.Teleporter5 : '5'
	, planets.Item.Teleporter6 : '6'
	, planets.Item.Teleporter7 : '7'
	, planets.Item.Teleporter8 : '8'
	, planets.Item.Teleporter9 : '9'

	, planets.Item.BeltStart : '{'
	, planets.Item.Belt : '-'
	, planets.Item.BeltEnd : '}'

	, planets.Item.Void : '.'
	, planets.Item.Error : 'X'
}

def dumpPlanet( planet : planets.Planet ):
	for y in range( 31 ):
		for x in range( 16 ):
			c = ItemToDump[ planet.getItem( x, y ) ]
			print( c, end ='' )
		print( )
	
		
if __name__ == "__main__":
	if len( sys.argv ) != 2:
		raise RuntimeError( "Expected a file name" )

i = 1
allPlanets = planets.getPlanets( atari_file.ExecutableFile( sys.argv[1] ) )
for planet in allPlanets:
	print ( i )
	i = i + 1
	dumpPlanet( planet )
