import atari_file
import planets
import io
import array
import sys
import png

spacing = 8

class AtasciiFont:
	def __init__( self, filename : str ):
		self.m_characters = []
		file = io.open( filename, "rb" )
		for c in range( 128 ):
			character = []
			for line in range( 8 ):
				try:
					byte = file.read( 1 )[0]
					character.append( byte )
				except IOError:
					raise RuntimeError( "Unexpected error while reading file %1" % filename )
			self.m_characters.append( character )
			
	def putCharacter( self, bitmap, x : int, y : int, c : int ):
		negate = c > 127
		character = self.m_characters[ c & 127 ]
		for l in range( 8 ):
			line = character[ l ]
			for bitPos in range( 8 ):
				bit = False
				if line&128 > 0:
					bit = True
				if negate:
					bit = not bit
				line = line << 1
				bitValue = 0
				if bit:
					bitValue = 1
				bitmap[ y + l ][ x + bitPos ]= bitValue

def createBitmap( columns : int, rows : int ):
	width = columns * (8 * 16 + spacing ) + spacing
	height = rows * (8 * 31 + spacing ) + spacing
	return [ bytearray(1) * width for i in range( height )]

def dumpPlanet( _p : planets.Planet, _x : int, _y : int, _font : AtasciiFont, _bitmap ):
	for x in range( 16 ):
		left = _x + x * 8
		for y in range( 31 ):
			top = _y + y * 8
			_font.putCharacter( _bitmap, left, top, _p.getRawByte( x, y ) )

def dumpPlanets( _p, _font : AtasciiFont, _bitmap, columns : int ):
	for c in range( len( _p ) ):
		x = c % columns
		left = x * 8 * 16 + x * spacing + spacing 
		y = c // columns
		top = y * 8 * 31 + y * spacing + spacing
		dumpPlanet( _p[ c ], left, top, _font, _bitmap )

if __name__ == "__main__":
	if len( sys.argv ) != 2:
		raise RuntimeError( "Expected a file name" )

allPlanets = planets.getPlanets( atari_file.ExecutableFile( sys.argv[1] ) )

font = AtasciiFont( "data/atari-font-ascii.raw" );

bitmap = createBitmap( 8, 7 )

dumpPlanets( allPlanets, font, bitmap, 8 )

w = png.Writer( len(bitmap[0]), len(bitmap), greyscale=True, bitdepth=1)
f = open( sys.argv[1] +'.png', 'wb')
w.write(f, bitmap)
f.close()
