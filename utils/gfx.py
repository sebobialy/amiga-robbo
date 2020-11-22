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

def paintLoResByte( _bitmap, _ram, _ramLocation : int, _x : int, _y : int ):
	for y in range( 8 ):
		line = _ram[ _ramLocation + y ]
		for x in range( 4 ):
			nibble = 0
			if line & 0x80 > 0:
				nibble = 2
			if line & 0x40 > 0:
				nibble += 1
			_bitmap[ _y + y ][ ( _x+ x*2 + 0 ) * 3 + 0 ] = nibble* 50
			_bitmap[ _y + y ][ ( _x+ x*2 + 1 ) * 3 + 0 ] = nibble* 50
			_bitmap[ _y + y ][ ( _x+ x*2 + 0 ) * 3 + 1 ] = nibble* 50
			_bitmap[ _y + y ][ ( _x+ x*2 + 1 ) * 3 + 1 ] = nibble* 50
			_bitmap[ _y + y ][ ( _x+ x*2 + 0 ) * 3 + 2 ] = nibble* 50
			_bitmap[ _y + y ][ ( _x+ x*2 + 1 ) * 3 + 2 ] = nibble* 50
			line = line << 2

class Gfx:
		def __init__( self, _ram ):
			self.m_ram = _ram

def createHiResBitmap( _columns : int, _rows : int ):
	width = _columns * 8
	height = _rows * 8
	return [ bytearray(1) * width for i in range( height )]

def createLoResBitmap( _columns : int, _rows : int ):
	width = _columns * 8
	height = _rows * 8
	return [ bytearray(1) * 3 * width for i in range( height )]

def getAllHiResBitmap( _ram ):
	bitmap = createHiResBitmap( 32, 256 )
	for x in range( 32 ):
		for y in range( 256 ):
			ramLocation = x * 8 +( y * 32 * 8 )
			paintHiResByte( bitmap, _ram, ramLocation, x * 8, y * 8 )
	return bitmap

def getAllLoResBitmap( _ram ):
	bitmap = createLoResBitmap( 32, 256 )
	for x in range( 32 ):
		for y in range( 256 ):
			ramLocation = x * 8 +( y * 32 * 8 )
			paintLoResByte( bitmap, _ram, ramLocation, x * 8, y * 8 )
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
bitmap = getAllLoResBitmap( ram )
w = png.Writer( len(bitmap[0])//3, len(bitmap), greyscale=False)
f = open( sys.argv[1] +'_loresmem.png', 'wb')
w.write(f, bitmap)
f.close()
