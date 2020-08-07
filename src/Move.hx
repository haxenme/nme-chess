

class Move
{
   public var newBoard:BoardState;
   public var displayFrom:BPos;
   public var displayTo:BPos;
   public var displayPromote:Piece;
   public var value:Int;
   public var stalemate:Bool;
   public var capture:Bool;


   public function new(board:BoardState,from:BPos,to:BPos,promote:Piece)
   {
      newBoard = board;
      displayFrom = from;
      displayTo = to;
      displayPromote = promote;
      stalemate = false;
      capture = false;
      value = 0;
   }

   public function getText()
   {
      var cap = capture ? "x" : "";
      var piece =  newBoard.atI(displayTo.index) & BoardState.MASK;
      if (piece==0)
         return "???";

      if (piece==BoardState.KING)
      {
         if (displayFrom.x==4 && displayTo.x==2)
            return "O-O-O";
         if (displayFrom.x==4 && displayTo.x==6)
            return "O-O";
         return "K" + cap + displayTo;
      }
      if (displayPromote!=null)
      {
         var promo = BoardState.pCodes[piece];
         if (capture)
            return BPos.file[displayFrom.x] + cap + displayTo + "=" + promo;
         return displayTo+"="+promo;
      }
      if (piece<BoardState.PAWN)
      {
         var which = "";
         var to = displayTo.index;
         var from = displayFrom.index;
         var white = to & BoardState.WHITE;
         var p = newBoard.atI(to);
         var sameRank = false;
         var sameFile = false;
         var needsWhich = false;

         for(i in 0...64)
            if (i!=from && newBoard.atI(i)==p)
            {
               // Do we need to specify which one?
               var rewind = newBoard.clone();
               // Should really check for moves not in Check
               rewind.set(displayTo,0);
               rewind.set(displayFrom,p);
               rewind.setWhitesTurn(white!=0);
               var idx = 0;
               var sx = displayTo.x;
               var sy = displayTo.y;
               for(y in 0...8)
                 for(x in 0...8)
                 {
                    if (idx!=from && (rewind.atI(idx)==p))
                    {
                       var canMove = false;
                       switch(p&BoardState.MASK)
                       {
                          case BoardState.KNIGHT:
                             var dx = Math.abs(sx-x);
                             var dy = Math.abs(sy-y);
                             canMove = (dx==1&&dy==1) || (dx==2&&dy==1);
                          case BoardState.BISHOP:
                             canMove = rewind.bishopPath(x,y,displayTo);
                          case BoardState.ROOK:
                             canMove = rewind.rookPath(x,y,displayTo);
                          case BoardState.QUEEN:
                             canMove = rewind.queenPath(x,y,displayTo);
                          default:
                       }
                       if (canMove)
                       {
                          needsWhich = true;
                          sameFile = sameFile || sx==x;
                          sameRank = sameRank || sy==y;
                          //trace('----- ${displayFrom.x},${displayFrom.y}  & $x,$y -> $sx,$sy  p=$p=${rewind.at(displayFrom)} file=$sameFile rank=$sameRank');
                          //rewind.printBoard();
                       }
                    }
                    idx++;
                 }
               break;
            }
         if (needsWhich)
         {
            if (sameRank && sameFile)
                which = displayFrom+"";
            else if (sameFile)
                which = BPos.rank[displayFrom.y];
            else
                which = BPos.file[displayFrom.x];
         }
         return BoardState.pCodes[piece] + which + cap + displayTo;
      }

      // Pawn...
      if (capture)
         return BPos.file[displayFrom.x] + cap + displayTo;

      return displayTo+"";
   }

   public function isTo(p:BPos)
   {
      return displayTo.x==p.x && displayTo.y==p.y;
   }

   public function toString()
   {
      if (newBoard.at(displayTo).isKing())
      {
         if (displayFrom.x==4 && displayTo.x==2)
            return "O-O-O";
         if (displayFrom.x==4 && displayTo.x==6)
            return "O-O";
      }
      var txt = displayFrom.toString() + "-" + displayTo.toString();
      if (displayPromote!=null)
         txt += displayPromote.getPromoteText();
      return txt;
   }

}


