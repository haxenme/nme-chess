class Piece
{
   public var isWhite:Bool; 
   public var id:Int; 

   public function new(inIsWhite:Bool, inId:Int)
   {
      isWhite = inIsWhite;
      id = inId;
   }

   public function getPromoteText() return "";

   function tryAdd(from:BPos,board:BoardState,moves:Array<Move>,x:Int,y:Int, promote=false,
       enPassant=false, ?removePos:BPos, ?castleRook:BPos) : Array<Move>
   {
      if (x>=0 && y>=0 && x<8 && y<8)
      {
         var o = board.atXy(x,y);
         if (o==null || o.isWhite!=isWhite)
         {
            var to = BPos.create(x,y);
            var count = promote ? 4 : 1;
            for(i in 0...count)
            {
               var newBoard = board.clone();
               var newPromote:Piece = null;

               newBoard.set(from,0);

               if (removePos!=null)
               {
                  if (castleRook!=null)
                  {
                     var rook = newBoard.at(removePos);
                     newBoard.set(castleRook,rook.id);
                  }
                  newBoard.set(removePos,0);
               }

               var capture = false;
               if (promote)
               {
                  newPromote = BoardState.getPromote(i, isWhite);
                  capture = newBoard.set(to, newPromote.id);
               }
               else
                  capture = newBoard.set(to,id);

               newBoard.set(from,0);

               if (newBoard.isKingInCheck(isWhite))
                  continue;

               newBoard.enPassantFile = enPassant ? x : 0xff;
               newBoard.setWhitesTurn(!isWhite);

               var move = new Move(newBoard, from, to, newPromote);
               move.capture = capture;

               if (moves==null)
                  moves = [move];
               else
                  moves.push(move);
            }
         }
      }
      return moves;
   }
   public function getMoves(pos:BPos,board:BoardState,?moves:Array<Move>) : Array<Move>
   {
      return null;
   }
   public function getTile():Int return -1;
   public function isKing():Bool return false;
   public function isRook():Bool return false;
   public function getChar():String return "?";
   public function attacks(board:BoardState, px:Int, py:Int, ax:Int, ay:Int) return false;
}


class King extends Piece
{
   override public function getMoves(pos:BPos,board:BoardState,?moves:Array<Move>) : Array<Move>
   {
      var px = pos.x;
      var py = pos.y;
      for(tx in px-1...px+2)
         for(ty in py-1...py+2)
            if (tx!=px || ty!=py)
               moves = tryAdd(pos,board, moves, tx,ty);
      var short = board.sideCanCastle(isWhite,false);
      if (short && board.atXy(5,py)==null && board.atXy(6,py)==null &&
           !board.isAttacked(!isWhite,4,py) &&
           !board.isAttacked(!isWhite,5,py) &&
           !board.isAttacked(!isWhite,6,py)  )
         moves = tryAdd(pos,board, moves,6,py, false, false, BPos.create(7,py), BPos.create(5,py));

      var long = board.sideCanCastle(isWhite,true);
      if (long && board.atXy(1,py)==null && board.atXy(2,py)==null && board.atXy(3,py)==null &&
           !board.isAttacked(!isWhite,2,py) &&
           !board.isAttacked(!isWhite,3,py) &&
           !board.isAttacked(!isWhite,4,py) )
         moves = tryAdd(pos,board, moves,2,py, false, false, BPos.create(0,py), BPos.create(3,py));

      return moves;
   }
   override public function attacks(board:BoardState, px:Int, py:Int, ax:Int, ay:Int)
   {
      return Math.abs(px-ax)<2 && Math.abs(py-ay)<2;
   }

   override public function getTile():Int return isWhite ? 7 : 0;

   override public function isKing():Bool return true;
   override public function getChar():String return isWhite ? "k" : "K";
}


class Queen extends Piece
{
   override public function getMoves(pos:BPos,board:BoardState,?moves:Array<Move>) : Array<Move>
   {
      var dx = 0;
      var dy = 0;
      for(dir in 0...8)
      {
         if (dir<4)
         {
            // rook
            dx = dir==0 ? -1 : dir==1 ? 1 : 0;
            dy = dir==2 ? -1 : dir==3 ? 1 : 0;
         }
         else
         {
            // bishop
            dx = (dir==4 || dir==5) ? 1 : -1;
            dy = (dir==5 || dir==6) ? 1 : -1;
         }

         var px = pos.x + dx;
         var py = pos.y + dy;
         while(px>=0 && py>=0 && px<8 && py<8)
         {
            moves = tryAdd(pos,board,moves,px,py);
            if (board.atXy(px,py)!=null)
               break;
            px += dx;
            py += dy;
         }
      }
      return moves;
   }
   override public function getPromoteText() return "q";

   override public function getTile():Int return isWhite ? 8 : 1;

   override public function attacks(board:BoardState, px:Int, py:Int, ax:Int, ay:Int)
   {
      var dx =  ax-px;
      var dy =  ay-py;

      if (dx==dy || dx==-dy || dx==0 || dy==0)
      {
         dx = dx>0 ? 1 : dx<0 ? -1 : 0;
         dy = dy>0 ? 1 : dy<0 ? -1 : 0;
         px += dx;
         py += dy;
         while(px!=ax || py!=ay)
         {
            if (board.occupied(px,py))
               return false;
            px += dx;
            py += dy;
         }
         return true;
      }

      return false;
   }
   override public function getChar():String return isWhite ? "q" : "Q";

}

class Rook extends Piece
{
   override public function getMoves(pos:BPos,board:BoardState,?moves:Array<Move>) : Array<Move>
   {
      for(dir in 0...4)
      {
         var dx = dir==0 ? -1 : dir==1 ? 1 : 0;
         var dy = dir==2 ? -1 : dir==3 ? 1 : 0;
         var px = pos.x + dx;
         var py = pos.y + dy;
         while(px>=0 && py>=0 && px<8 && py<8)
         {
            moves = tryAdd(pos,board,moves,px,py);
            if (board.atXy(px,py)!=null)
               break;
            px += dx;
            py += dy;
         }
      }
      return moves;
   }

   override public function getTile():Int return isWhite ? 9 : 2;
   override public function isRook():Bool return true;

   override public function getPromoteText() return "r";

   override public function attacks(board:BoardState, px:Int, py:Int, ax:Int, ay:Int)
   {
      var dx =  ax-px;
      var dy =  ay-py;

      if (dx==0 || dy==0)
      {
         dx = dx>0 ? 1 : dx<0 ? -1 : 0;
         dy = dy>0 ? 1 : dy<0 ? -1 : 0;
         px += dx;
         py += dy;
         while(px!=ax || py!=ay)
         {
            if (board.occupied(px,py))
               return false;
            px += dx;
            py += dy;
         }
         return true;
      }

      return false;
   }
   override public function getChar():String return isWhite ? "r" : "R";
}


class Knight extends Piece
{
   override public function getMoves(pos:BPos,board:BoardState,?moves:Array<Move>) : Array<Move>
   {
      var px = pos.x;
      var py = pos.y;
      for(qy in 0...2)
         for(qx in 0...2)
            for(l in 0...2)
            {
               var tx = px + (qx==0?-1:1) * (l==1 ? 2 : 1 );
               var ty = py + (qy==0?-1:1) * (l==1 ? 1 : 2 );
               moves = tryAdd(pos,board, moves, tx,ty);
            }

      return moves;
   }

   override public function getTile():Int return isWhite ? 11 : 4;
   override public function getPromoteText() return "n";

   override public function attacks(board:BoardState, px:Int, py:Int, ax:Int, ay:Int)
   {
      var dx =  ax-px;
      if (dx<0) dx = -dx;
      var dy =  ay-py;
      if (dy<0) dy = -dy;

      return (dx==2 && dy==1) || (dx==1 && dy==2);
   }
   override public function getChar():String return isWhite ? "n" : "N";
}



class Bishop extends Piece
{
   override public function getMoves(pos:BPos, board:BoardState,?moves:Array<Move>) : Array<Move>
   {
      for(dir in 4...8)
      {
         var dx = (dir==4 || dir==5) ? 1 : -1;
         var dy = (dir==5 || dir==6) ? 1 : -1;
         var px = pos.x + dx;
         var py = pos.y + dy;
         while(px>=0 && py>=0 && px<8 && py<8)
         {
            moves = tryAdd(pos,board,moves,px,py);
            if (board.atXy(px,py)!=null)
               break;
            px += dx;
            py += dy;
         }
      }
      return moves;
   }
   override public function getPromoteText() return "b";

   override public function getTile():Int return isWhite ? 10 : 3;


   override public function attacks(board:BoardState, px:Int, py:Int, ax:Int, ay:Int)
   {
      var dx =  ax-px;
      var dy =  ay-py;

      if (dx==dy || dx==-dy)
      {
         dx = dx>0 ? 1 : -1;
         dy = dy>0 ? 1 : -1;
         px += dx;
         py += dy;
         while(px!=ax || py!=ay)
         {
            if (board.occupied(px,py))
               return false;
            px += dx;
            py += dy;
         }
         return true;
      }

      return false;
   }
   override public function getChar():String return isWhite ? "b" : "B";
}




class Pawn extends Piece
{
   override public function getMoves(pos:BPos,board:BoardState,?moves:Array<Move>) : Array<Move>
   {
      var px = pos.x;
      var py = pos.y;
      var dir = isWhite ? -1 : 1;
      var homeRank = isWhite ? py==6 : py==1;
      var passRank = isWhite ? py==3 : py==4;
      var promoteRank = isWhite ? py==1 : py==6;

      if ( board.atXy(px,py+dir)==null )
      {
         moves = tryAdd(pos,board, moves, px,py+dir, promoteRank);
         if (homeRank && board.atXy(px,py+dir*2)==null )
            moves = tryAdd(pos,board, moves, px,py+dir*2, false, true);
      }
      if ( px>0 && board.atXy(px-1,py+dir)!=null )
         moves = tryAdd(pos,board, moves, px-1,py+dir, promoteRank);
      if ( passRank && px>0 && board.enPassantFile==px-1 )
         moves = tryAdd(pos,board, moves, px-1,py+dir, false,false, BPos.create(px-1,py) );
      if ( px<7 && board.atXy(px+1,py+dir)!=null )
         moves = tryAdd(pos,board, moves, px+1,py+dir, promoteRank);
      if ( passRank && px<7 && board.enPassantFile==px+1 )
         moves = tryAdd(pos,board, moves, px+1,py+dir, false,false, BPos.create(px+1,py) );

      return moves;
   }
   override public function getTile():Int return isWhite ? 12 : 5;

   override public function attacks(board:BoardState, px:Int, py:Int, ax:Int, ay:Int)
   {
      var dx =  ax-px;
      if (dx!=1 && dx!=-1)
         return false;

      return ay == py + (isWhite ? -1 : 1);
   }

   override public function getChar():String return isWhite ? "p" : "P";

}

class Dummy extends Piece
{
   override public function getChar():String return "X";
}




