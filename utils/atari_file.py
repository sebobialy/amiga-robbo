import os.path
import io
import sys
from enum import Enum

def getUnsignedShortFromBytes( bytes : bytearray ):
	assert( len( bytes ) == 2 )
	result = ( bytes[1] * 256 ) + bytes[0]
	return result

class HunkType( Enum ):
	Data = 0
	RamAllocationBlock = 1
	PositionIndependentBinaryBlock = 2
	Fixups = 3
	RequiredSymbols = 4
	SymbolDefinition = 5

knownHunkTypes = {
	  0xffff : HunkType.Data
	, 0xfffe : HunkType.RamAllocationBlock
	, 0xfffd : HunkType.Fixups
	, 0xfffc : HunkType.SymbolDefinition
	, 0xfffb : HunkType.RequiredSymbols
	}

class Hunk:
	def __init__( self, start : int, bytes : bytearray, type : HunkType ):
		self.m_start = start
		self.m_bytes = bytes
		self.m_type = type

	def start( self ):
		return self.m_start
		
	def size( self ):
		return len( self.m_bytes )
	
	def data( self ):
		return self.m_bytes
		
	def type( self ):
		return self.m_type
		
class ExecutableFile:
	def __init__( self, fileName : os.path ):
		m_file = io.open( fileName, "rb" )

		mustStartWithHeader = True
		self.m_hunks = []

		while True:
			try:
				header = m_file.read( 2 )
				if len( header ) == 0:
					break				
				start = getUnsignedShortFromBytes( header )
				try:
					hunkType = knownHunkTypes[start]
					if hunkType != HunkType.Data:
						raise RuntimeError( "Unsupported hunk header {}".format( hex( start ) ) )
					start = getUnsignedShortFromBytes( m_file.read( 2 ) )
				except KeyError:
					if mustStartWithHeader:
						raise RuntimeError( "Missing Atari's executable header" )
					hunkType = HunkType.Data
				mustStartWithHeader = False					
				stop = getUnsignedShortFromBytes( m_file.read( 2 ) )
				hunk = Hunk( start, m_file.read( stop - start + 1 ), hunkType )
				self.m_hunks.append( hunk )
			except IOError:
				raise RuntimeError( "Unexpected error while reading file" )
				
	def __iter__( self ):
		return self.m_hunks.__iter__()

def displayFileInformation( fileName : str ):
	file = ExecutableFile( fileName )
	for hunk in file:
		print( "Hunk: start: {}({}), size {}({})".format( hunk.start(), hex( hunk.start() ), hunk.size(), hex( hunk.size() ) ) )
		pass
		
if __name__ == "__main__":
	if len( sys.argv ) != 2:
		raise RuntimeError( "Expected a file name" )

	displayFileInformation( sys.argv[1] )
		