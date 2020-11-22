import png
import sys
import atari_file

def paintHiResByte( _bitmap, _ram, _ramLocation : int, _x : int, _y : int ):
	for y in range( 8 ):
		line = _ram[ _ramLocation + y ]
		for x in range( 8 ):
			bit = 0
			if line & 0x80 > 0:
				bit = 1
			_bitmap[ _y + y ][ _x + x ] = bit
			line = line << 1

class Gfx:
		def __init__( self, _ram ):
			self.m_ram = _ram

def createBitmap( _columns : int, _rows : int ):
	width = _columns * 8
	height = _rows * 8
	return [ bytearray(1) * width for i in range( height )]

def getAllHiResBitmap( _ram ):
	bitmap = createBitmap( 32, 256 )
	for x in range( 32 ):
		for y in range( 256 ):
			ramLocation = x * 8 +( y * 32 * 8 )
			paintHiResByte( bitmap, _ram, ramLocation, x * 8, y * 8 )
	return bitmap

if __name__ == "__main__":
	if len( sys.argv ) != 2:
		raise RuntimeError( "Expected a file name" )
		

file = atari_file.ExecutableFile( sys.argv[1] )
ram = file.prepareRam()
bitmap = getAllHiResBitmap( ram )
w = png.Writer( len(bitmap[0]), len(bitmap), greyscale=True, bitdepth=1)
f = open( sys.argv[1] +'_hiresmem.png', 'wb')
w.write(f, bitmap)
f.close()
