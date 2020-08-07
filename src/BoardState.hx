import Piece;
using StringTools;

#if cpp
import haxe.io.BytesData;
import cpp.NativeArray;
using cpp.NativeArray;
typedef ByteArray = BytesData;
#else
typedef ByteArray = js.lib.Uint8Array;
#end


// BoardState :
//  0-63: 8x8 x Piece.  Black starts at the top (rank 0) White bottom (rank 7)
//    0x8 : isWhite bit
//    0x7 : pieceMask
//    0x0 : empty
//    0x1 : King
//    0x2 : Queen
//    0x3 : Rook
//    0x4 : Bishop
//    0x5 : Knight
//    0x6 : Pawn
//
//  64: castleFlags
//    0x1 black-short-enable
//    0x2 black-long-enable
//    0x4 white-short-enable
//    0x8 white-long-enable
//  65: enPassant file
//    0-7  Opponent pawn on file just advanced 2
//    0xff No recent advance
//  66: isWhiteTurn
//  67: blackKingIdx
//  68: whiteKingIdx

abstract BoardState(ByteArray) to(ByteArray)
{
   public inline static var KING   = 0x01;
   public inline static var QUEEN  = 0x02;
   public inline static var ROOK   = 0x03;
   public inline static var BISHOP = 0x04;
   public inline static var KNIGHT = 0x05;
   public inline static var PAWN   = 0x06;
   public inline static var MASK   = 0x07;

   public inline static var WHITE  = 0x08;

   public inline static var CASTLE_SHORT = 0x01;
   public inline static var CASTLE_LONG  = 0x02;

   public inline static var files = "abcdefgh";
   public static var pCodes = ["","K","Q","R","B","N","P"];


   static var pieceHandlers = [ for(i in 0...16) createHandler(i) ];

   public var enPassantFile(get,set):Int;

   inline function new(board:ByteArray) this = board;

   public function clone() : BoardState
   {
      return new BoardState(#if cpp this.copy() #else this.slice(0,69) #end );
   }

   public static function start()
   {
      return BoardState.fromString(
       [  "RNBQKBNR",
          "PPPPPPPP",
          "        ",
          "        ",
          "        ",
          "        ",
          "pppppppp",
          "rnbqkbnr" ].join("")
      );
   }

   public static function create() : BoardState
   {
      #if cpp
      var board:ByteArray = NativeArray.create(69);
      #else
      var board:ByteArray = new js.lib.Uint8Array(69);
      #end
      board[65] = 0xff;
      board[66] = 1;
      board[67] = 0xff;
      board[68] = 0xff;
      return new BoardState(board);
   }

   public function eq(other:BoardState)
   {
      #if (!cpp || cppia)
      for(i in 0...67)
         if (this[i]!=other[i])
            return false;
      return true;
      #else
      return this.memcmp(other)==0;
      #end
   }

   #if (cpp && !cppia)
   static var hashMult:cpp.UInt32 = cast 2654435769;
   public function hashCode() : Int
   {
      var intPtr:cpp.Pointer<cpp.UInt32> = cast this.getBase().getBase();
      // 16*4 + 4 -> 68 elements.  King position is redundant and is not needed in the state
      //var result:cpp.UInt32 = intPtr.at(0);
      var result:cpp.UInt32 = 0;
      for(i in 0...17)
      {
         var val = intPtr.at(i);
         result = result*hashMult + val;
      }

      return result;
   }
   #else
   static var hashMult:Int = 0x9E3779B9;
   public function hashCode() : Int
   {
      var result = 0;
      var idx = 0;
      for(i in 0...17)
      {
         var val = this[idx] | (this[idx+1]<<8) | (this[idx+2]<<16) | (this[idx+3]<<24);
         #if js
         result = (js.lib.Math.imul(result,hashMult) + val) | 0;
         #else
         result = result*hashMult + val;
         #end
         idx += 4;
      }

      return result;
   }
   #end

   public function getPieceCount() : Int
   {
      var total = 0;
      for(i in 0...64)
         if (this[i]>0)
            total++;
      return total;
   }
   public function canWin()
   {
      var whiteCanWin = false;
      var whitePieces = 0;
      var blackCanWin = false;
      var blackPieces = 0;
      for(i in 0...64)
         if (this[i]>0)
         {
            var p = this[i];
            var isWhite = (p & WHITE)>0;
            p &= ~WHITE;
            if (p==ROOK || p==PAWN || p==QUEEN)
            {
               if (isWhite)
                  whiteCanWin = true;
               else
                  blackCanWin = true;
            }
            else if (p==KNIGHT || p==BISHOP)
            {
               if (isWhite)
                  whitePieces++;
               else
                  blackPieces++;
            }
         }
      return (whiteCanWin || blackCanWin || whitePieces>1 || blackPieces>1);
   }


   public function sideCanCastle(whiteSide:Bool,long:Bool)
   {
      var flag = (long?CASTLE_LONG : CASTLE_SHORT)<<(whiteSide?2:0);
      return (this[64] & flag) != 0;
   }

   public inline function isWhitesTurn() return this[66]!=0;

   public function setWhitesTurn(nextWhite:Bool)
   {
      this[66] = nextWhite ? 1 : 0;
   }
   public function set(pos:BPos, value:Int)
   {
      var capture = this[pos.index]>0;

      if (pos.y==0)
      {
         // Black King
         if (pos.x==4)
            this[64] &= ~( (CASTLE_LONG|CASTLE_SHORT) );
         else if (pos.x==0)
            this[64] &= ~( CASTLE_LONG );
         else if (pos.x==7)
            this[64] &= ~( CASTLE_SHORT );
      }
      else if (pos.y==7)
      {
         // White King
         if (pos.x==4)
            this[64] &= ~( (CASTLE_LONG|CASTLE_SHORT)<<2 );
         else if (pos.x==0)
            this[64] &= ~( CASTLE_LONG<<2 );
         else if (pos.x==7)
            this[64] &= ~( CASTLE_SHORT<<2 );
      }
      this[pos.index] = value;
      if ( (value & MASK)==KING )
         this[ ((value & WHITE)>0) ? 68 : 67 ] = pos.index;

      return capture;
   }

   public function isAttacked(byWhite:Bool,ax:Int, ay:Int) : Bool
   {
      var whiteBit = byWhite ? WHITE : 0;
      for(p in 0...64)
      {
         var val = this[p];
         if (val>0 && (val & WHITE)==whiteBit )
         {
            var piece = pieceHandlers[val];
            if (piece.attacks(new BoardState(this),p&7,p>>3,ax,ay))
               return true;
         }
      }
      return false;
   }
   
   public function isKingInCheck(whiteKing:Bool) : Bool
   {
      var kingSlot = this[ whiteKing ? 68 : 67 ];
      return isAttacked(!whiteKing, kingSlot&7, kingSlot>>3 );
   }

   inline function get_enPassantFile() return this[65];
   inline function set_enPassantFile(file:Int) return this[65] = file;

   @:op([])
   inline public function atI(index:Int):Int return this[index];

   public function at(pos:BPos)
   {
      return pieceHandlers[ this[pos.y*8+pos.x] ];
   }
   public function atXy(x:Int, y:Int)
   {
      return pieceHandlers[ this[y*8+x] ];
   }
   inline public function getColouredPiece(index:Int, isWhite:Bool)
   {
      var val = this[index];
      if (val>0 && ( (val&WHITE>0) == isWhite) )
         return pieceHandlers[val];
      return null;
   }
   inline public function occupied(x:Int, y:Int)
   {
      return this[y*8+x]>0;
   }

   public function findPiece(id:Int,qcode:Int=0,?start:BPos,?tx:Int, ?ty:Int):BPos
   {
      var p0 = start==null ? 0 : start.y*8 + start.x + 1;
      for(p in p0...64)
         if (this[p]==id)
         {
            if (qcode!=0)
            {
               if (qcode>='a'.code && qcode<='h'.code)
               {
                  if ( (qcode-'a'.code)!=(p&7) )
                     continue;
               }
               else
               {
                  var y = p>>3;
                  var rank = 8-y;
                  if ( (qcode-'0'.code)!=rank )
                     continue;
               }
            }
            else
            {
               // Might be unqualified if the move is illegal (rook, knight, promoted queen, b?)
               if (tx!=null && ty!=null)
               {
                  // check for other piece...
                  var other = -1;
                  for(p2 in p+1...64)
                     if (this[p2]==id)
                     {
                        other = p2;
                        break;
                     }
                  if (other>=0)
                  {
                     // Check position...
                     var origTarget = this[ty*8+tx];
                     this[ty*8+tx] = id;
                     this[p] = 0;
                     var badMove = isKingInCheck( this[66]!=0 );
                     // Restore...
                     this[ty*8+tx] = origTarget;
                     this[p] = id;
                     if (badMove)
                        return BPos.fromIndex(other);
                  }
               }
            }
            return BPos.fromIndex(p);
         }
      return null;
   }

   public function rookPath(sx:Int, sy:Int, pos:BPos)
   {
      if (sx==pos.x)
      {
         var y0 = sy;
         var y1 = pos.y;
         if (y0>y1)
         {
            y1 = sy;
            y0 = pos.y;
         }
         for(y in y0+1...y1)
            if (occupied(sx,y))
               return false;
         return true;
      }
      else if (sy==pos.y)
      {
         var x0 = sx;
         var x1 = pos.x;
         if (x0>x1)
         {
            x0 = pos.x;
            x1 = sx;
         }
         for(x in x0+1...x1)
            if (occupied(x,sy))
               return false;
         return true;
      }
      return false;
   }


   public function bishopPath(sx:Int, sy:Int, pos:BPos)
   {
      var dx = pos.x-sx;
      var dy = pos.y-sy;
      if (Math.abs(dx)!=Math.abs(dy))
         return false;
      dx = dx>0 ? 1 : -1;
      dy = dy>0 ? 1 : -1;

      sx+=dx;
      sy+=dy;
      while(sx!=pos.x)
      {
         if (occupied(sx,sy))
            return false;
         sx+=dx;
         sy+=dy;
      }
      return true;
   }

   public function queenPath(sx:Int, sy:Int, pos:BPos)
   {
      return rookPath(sx,sy,pos) || bishopPath(sx,sy,pos);
   }

   public function printBoard()
   {
      var idx = 0;
      var chars = new Array<String>();
      for(y in 0...8)
      {
         for(x in 0...8)
         {
            var p = atXy(x,y);
            if (p==null)
               chars.push( ((x+y)&1)==1 ?"." : " ");
            else
               chars.push( p.getChar() );
         }
         chars.push("\n");
      }
      #if sys
      Sys.println(chars.join(""));
      #else
      trace(chars.join(""));
      #end
   }

   public function moveString(white:Bool, move:String) : Bool
   {
      if (move==null || move=="1/2-1/2" || move=="1-0" || move=="0-1" || move.length==0)
         return false;

      var wflags = white?WHITE:0;
      var n = move.length;
      var promote = 0;
      var last = move.fastCodeAt( move.length-1 );
      if (last=='+'.code || last=="#".code)
         n--;
      if (n>2 && move.fastCodeAt(n-2)=='='.code)
      {
         promote = switch(move.fastCodeAt(n-1))
         {
            case 'Q'.code : QUEEN | wflags;
            case 'R'.code : ROOK | wflags;
            case 'B'.code : BISHOP | wflags;
            case 'N'.code : KNIGHT | wflags;
            default:
               trace("Unknown promote string:" + move);
               throw "Unknown promote";
         }
         n-=2;
      }

      if (move.startsWith("O-O-O"))
      {
         this[65] = 0xff;
         var y = white ? 7 : 0;
         set(BPos.create(2,y), this[4+8*y] );
         set(BPos.create(4,y), 0);
         set(BPos.create(3,y), this[0+8*y] );
         set(BPos.create(0,y), 0);
      }
      else if (move.startsWith("O-O"))
      {
         this[65] = 0xff;
         var y = white ? 7 : 0;
         set(BPos.create(6,y), this[4+8*y] );
         set(BPos.create(4,y), 0);
         set(BPos.create(5,y), this[7+8*y] );
         set(BPos.create(7,y), 0);
      }
      else
      {
         var tx = move.fastCodeAt(n-2)-'a'.code;
         var ty = 7-(move.fastCodeAt(n-1)-'1'.code);

         if (n==2)
         {
            var yDir = white ? 1 : -1;
            var y0 = ty+yDir;
            if (!occupied(tx,y0))
            {
               y0 = ty+yDir*2;
               if (!occupied(tx,y0))
               {
                  trace("Unknown pawn origin");
                  trace("move:" + move);
                  trace("white:" + white);
                  trace("target:" + tx + "," + ty);
                  printBoard();
                  throw "Unknown pawn origin";
               }
            }
            var idx = y0*8+tx;
            if ( this[idx] != PAWN|wflags )
            {
               trace("Pawn missing");
               throw "Parn missing";
            }
            this[ty*8+tx] = promote!=0 ? promote : this[idx];
            this[idx] = 0;
            if ( Math.abs(y0-ty)>1 )
               this[65] = tx;
            else
               this[65] = 0xff;
         }
         else
         {
            var srcLen = n-2;
            if (srcLen>1 && move.fastCodeAt(srcLen-1)=='x'.code)
               srcLen--;
            var qualify = srcLen>1 ? move.fastCodeAt(1) : 0;

            var srcType = move.fastCodeAt(0);
            if (srcType>='a'.code && srcType<='h'.code)
            {
               // Pawn capture
               var sx = srcType-'a'.code;
               var sy = ty + (white ? 1 : -1);

               var p =  PAWN|wflags;
               // En-passant?
               if (!occupied(tx,ty))
               {
                  if (this[sy*8+tx]!= PAWN|(WHITE-wflags))
                  {
                     trace("Missing target parn");
                     throw "Missing target pawn";
                  }
                  // Remove en-passant pawn
                  this[sy*8+tx] = 0;
               }
               this[ty*8+tx] = promote!=0 ? promote : p;
               this[sy*8+sx] = 0;
            }
            else
            {
               var srcPos:BPos = null;
               switch(srcType)
               {
                  case 'R'.code:
                     srcPos = findPiece(ROOK|wflags,qualify,null,tx,ty);
                     if (srcPos!=null && !rookPath(tx,ty,srcPos) )
                         srcPos = findPiece(ROOK|wflags,qualify,srcPos);

                  case 'N'.code:
                     srcPos = findPiece(KNIGHT|wflags,qualify,null,tx,ty);
                     if (srcPos!=null)
                     {
                        var dx = Std.int(Math.abs(srcPos.x-tx));
                        var dy = Std.int(Math.abs(srcPos.y-ty));
                        if ( !(  (dx==1 && dy==2) || (dx==2 && dy==1)  ))
                        {
                           //trace('Pos failed, try again: $srcPos $dx,$dy');
                           srcPos = findPiece(KNIGHT|wflags,qualify,srcPos);
                        }
                     }

                  case 'B'.code:
                     srcPos = findPiece(BISHOP|wflags,qualify);
                     if (srcPos!=null)
                     {
                        var dx = Std.int(Math.abs(srcPos.x-tx));
                        var dy = Std.int(Math.abs(srcPos.y-ty));
                        if ( dx!=dy )
                           srcPos = findPiece(BISHOP|wflags,qualify,srcPos);
                     }

                  case 'K'.code: srcPos = findPiece(KING|wflags);

                  case 'Q'.code:
                     srcPos = findPiece(QUEEN|wflags,qualify,null,tx,ty);
                     if (srcPos!=null && !queenPath(tx,ty,srcPos) )
                         srcPos = findPiece(QUEEN|wflags,qualify,srcPos);


                  default:
                     trace("Unknown piece type " + move);
                     throw "Unknown piece";
               }

               if (srcPos==null)
               {
                  trace("Could not find piece");
                  trace("move:");
                  trace("white:" + white);
                  trace("target:" + tx + "," + ty);
                  printBoard();
                  throw "Could not find piece";
               }
               else
               {
                  set( BPos.create(tx,ty), this[srcPos.index] );
                  set( srcPos,0);
               }
            }


            this[65] = 0xff;
         }
      }

      /*
      Sys.println("--------");
      Sys.println(move);
      printBoard();
      */

      setWhitesTurn(!white);
      return true;
   }

   static function createHandler(i:Int) : Piece
   {
      var pid = i & MASK;
      var white = i>=WHITE;
      switch(pid)
      {
         case KING:   return new King(white,i);
         case QUEEN:  return new Queen(white,i);
         case ROOK:   return new Rook(white,i);
         case BISHOP: return new Bishop(white,i);
         case KNIGHT: return new Knight(white,i);
         case PAWN:   return new Pawn(white,i);
         case MASK:   return new Dummy(white,i);
         default: return null;
      }
   }

   public static function getPromote(pid:Int, isWhite:Bool)
   {
      return pieceHandlers[ QUEEN+pid + (isWhite?WHITE:0) ];
   }

   public static function fromString(inBoard:String) : BoardState
   {
      var result = BoardState.create();
      var bytes:ByteArray = result;

      var idx = 0;
      if (inBoard!=null)
        for(y in 0...8)
         for(x in 0...8)
         {
            var p = inBoard.charAt(idx);
            bytes[idx] = switch(p) {
               case "K" : bytes[67] = idx; KING;
               case "Q" : QUEEN;
               case "R" : ROOK;
               case "B" : BISHOP;
               case "N" : KNIGHT;
               case "P" : PAWN;

               case "k" : bytes[68] = idx; KING | WHITE;
               case "q" : QUEEN | WHITE;
               case "r" : ROOK | WHITE;
               case "b" : BISHOP | WHITE;
               case "n" : KNIGHT | WHITE;
               case "p" : PAWN | WHITE;

               default: 0;
            }
            idx++;
        }

      if (bytes[4]==KING)
      {
         if (bytes[0]==ROOK)
            bytes[64] |= CASTLE_LONG;
         if (bytes[7]==ROOK)
            bytes[64] |= CASTLE_SHORT;
      }

      if (bytes[7*8+4]==KING|WHITE)
      {
         if (bytes[7*8]==ROOK|WHITE)
            bytes[64] |= CASTLE_LONG<<2;
         if (bytes[7*8+7]==ROOK|WHITE)
            bytes[64] |= CASTLE_SHORT<<2;
      }

      return result;
   }
}

