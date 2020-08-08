import gm2d.Game;
import gm2d.Screen;
import gm2d.ui.*;
import gm2d.svg.*;
import gm2d.skin.*;
import gm2d.skin.Shape;
import gm2d.skin.FillStyle;
import gm2d.skin.LineStyle;
import nme.display.*;
import nme.text.*;
import nme.geom.*;
import nme.Assets;
import haxe.io.BytesInput;
import Player;
import BoardMap;


class Main extends Screen
{
   static var pieces = [ "king", "queen", "rook", "bishop", "knight", "pawn" ];
   var tilesheet:Tilesheet;
   var boardGfx:Sprite;
   var gameGraphics:nme.display.Shape;
   var sqSize:Int;
   var selPos:BPos;
   var selMoves:Array<Move>;
   var lastMove:Move;
   var history:TextField;
   var historyW:Float;
   var historyY:Float;
   var game:GameState;
   var status:TextField;
   var book:BoardMap<BoardValue>;
   var gameStarted:Bool;
   var isComputing:Bool;
   var menuButton:Button;

   public function new()
   {
      super();

      setupSkin();

      selPos = BPos.create(3,3);
      selMoves = null;
      lastMove = null;
      gameStarted = false;
      isComputing = false;

      menuButton = Button.BMPButton(createHamburger(), showGameDialog, {padding:0,shape:ShapeNone} );
      addChild(menuButton);

      book = BoardValue.loadMap( new BytesInput(nme.Assets.getBytes("opening.book")));
      boardGfx = new Sprite();
      addChild(boardGfx);
      gameGraphics = new nme.display.Shape();
      boardGfx.addChild(gameGraphics);
      history = new TextField();
      var fmt = new TextFormat();
      fmt.size = gm2d.skin.Skin.dpiScale*20;
      fmt.font = "_monospace";
      history.defaultTextFormat = fmt;
      history.borderColor = 0x000000;
      history.border = true;
      history.multiline = true;
      addChild(history);
      history.text = " 101. Ra8xb5+ ... Ra8xb5# ";
      historyW = history.textWidth;
      history.text = " 1: ";

      var fmtS = new TextFormat();
      fmtS.size = gm2d.skin.Skin.dpiScale*20;
      fmtS.font = "Gothic";
      status = new TextField();
      fmtS.align = TextFormatAlign.CENTER;
      fmtS.bold = true;
      status.defaultTextFormat = fmtS;
      addChild(status);
      status.selectable = false;
      status.mouseEnabled = false;

      historyY = status.textHeight*2;

      reset();

      layout();

      newGame();

      makeCurrent();

      showGameDialog();
   }

   function reset()
   {
      history.text = " 1: ";
      isComputing = false;
      gameStarted = false;
      status.text = "NME Chess";
      lastMove = null;
   }

   function setupSkin()
   {
      function half(rgb:Int)
        return (rgb&0xfcfcfc)>>2;
      var p = Skin.scale(2);
      Skin.replaceAttribs( "DialogTitle", {
           align: Layout.AlignStretch | Layout.AlignCenterY,
           textAlign: "center",
           font: "Gothic",
           fontSize: Skin.scale(20),
           padding: Skin.scale(10),
           shape: ShapeNone,
           //hitBoxId: HitBoxes.Title,
      } );
      Skin.addAttribs( "TextLabel", {
           font: "Gothic",
      });
      Skin.addAttribs( "Panel", {
           lineGap: Skin.scale(20),
           buttonGap: Skin.scale(20),
      });

      Skin.replaceAttribs( "Dialog", {
           shape: ShapeRoundRectRad( 5*Skin.dpiScale ),
           //line: LineSolid(p, half(0x8C5934), 1 ),
           chromeFilters: Skin.shadowFilters,
           fill: FillSolid( 0xffffff,1 ),
           //fill: FillSolid( 0xffffff - half(0xffffff-0xE4CBa5),1),
      });
      var bx = Skin.scale(20);
      Skin.replaceAttribs( "Button", {
           parent:"Control",
           shape: ShapeRect,
           //fill: FillSolid( 0xffffff - half(0xffffff-0xE4CBa5),1),
           fill: FillSolid( 0xffffff, 1 ),
           line: LineSolid(1, half(0x8C5934), 1 ),
           textAlign: "center",
           itemAlign: Layout.AlignCenter,
           //padding: new Rectangle(buttonBorderX,buttonBorderY,buttonBorderX*2,buttonBorderY*2),
           padding: new Rectangle(bx,p,bx*2,p*2),
           offset: new Point(Skin.scale(1),Skin.scale(1)),
      });
   }

   function createHamburger()
   {
      var s = Skin.scale(28);
      var shape = new nme.display.Shape();
      var gfx = shape.graphics;
      gfx.beginFill(0x8C5934);
      for(b in 0...3)
      {
         var y0 = Std.int(s*(b*2+1)/7);
         var y1 = Std.int(s*(b*2+2)/7);

         gfx.drawRect( Std.int(s*0.1), y0, Std.int(s*0.8), y1-y0 );
      }
      var bmp = new BitmapData(s,s,false,0xffffff);
      bmp.draw(shape);
      return bmp;
   }

   function setScale()
   {
      var sh = (stage.stageHeight-historyY);
      var sw = (stage.stageWidth-historyW);
      var ss = Std.int( Math.min(sw,sh) / 8 );

      if (ss==sqSize)
         return;

      sqSize = ss;
      var bitmap = new BitmapData(7*sqSize, 3*sqSize, true, 0);

      var sprite = new Sprite();
      var px = 0;
      var pid = 0;
      var svg = new SvgRenderer(gm2d.reso.Resources.loadSvg("chess.svg"));
      for(p in pieces)
      {
         for(col in ["black", "white"])
         {
            var name = p + "-" + col;
            var filter = (_,path)->path[1]==name;
            var shape = svg.createShape(filter);
            sprite.addChild(shape);
            var r = shape.getBounds(sprite);
            var scale = sqSize/45;
            shape.x = (pid+0.5)*sqSize - (r.left+r.width*0.5)*scale;
            shape.y = (col=="black" ? sqSize*0.95-2 : sqSize*0.95-2+sqSize) - r.bottom*scale;
            shape.scaleX = shape.scaleY = scale;
         }
         pid++;
      }
      var gfx = sprite.graphics;
      //gfx.beginFill(0x40b0b0);
      gfx.beginFill(0x8C5934);
      gfx.drawRect(6*sqSize,0,sqSize,sqSize);
      gfx.beginFill(0xE4CB95);
      gfx.drawRect(6*sqSize,sqSize,sqSize,sqSize);

      gfx.lineStyle(2,0x000000);
      gfx.beginFill(0xffff00,0.5);
      gfx.drawCircle(sqSize*0.5, sqSize*2.5, sqSize*0.25);

      gfx.lineStyle(2,0x000000);
      gfx.beginFill(0xff0000,0.5);
      gfx.drawCircle(sqSize*1.5, sqSize*2.5, sqSize*0.25);

      gfx.lineStyle();
      gfx.beginFill(0xffff00,0.25);
      gfx.drawCircle(sqSize*2.5, sqSize*2.5, sqSize*0.4);

      bitmap.draw(sprite);
      //shape.scaleX = shape.scaleY = 2.5;

      var rects = [];
      for(ty in 0...3)
         for(tx in 0...7)
            rects.push(new Rectangle(tx*sqSize, ty*sqSize, sqSize, sqSize));
      tilesheet = new Tilesheet(bitmap, rects);

      createBoard();

      if (game!=null)
         drawGame();
   }



   function startGame(white:Player, black:Player)
   {
      game.reset();
      reset();
      game.setPlayers(white, black);
      gameStarted = true;
      drawGame();
   }

   function playerFromText(text:String)
   {
      for(i in 1...10)
      {
         if (text=="NME Level " + i)
            return PlayNme(i,false);
         if (text=="NME Brute " + i)
            return PlayNme(i,true);
      }
      return PlayHuman;
   }

   function showGameDialog()
   {
      var panel = new Panel("NME Chess - New Game");
      var playerOptions = ["Human",
                            "NME Level 1",//"NME Brute 1",
                            "NME Level 2",//"NME Brute 2",
                            "NME Level 3",//"NME Brute 3",
                            "NME Level 4",//"NME Brute 4",
                            "NME Level 5",
                            "NME Level 6"];
      var player1Options = ["White","Black","Random"];
      var data = {
         player1 : playerOptions[1],
         player2 : playerOptions[2],
         player1is : player1Options[0],
      };

      var panel = new gm2d.ui.Panel("Choose your NME");
      panel.addLabelObj("Player 1", new ComboBox("",playerOptions,{listOnly:true,id:"player1" }) );
      panel.addLabelObj("Player 2", new ComboBox("",playerOptions,{listOnly:true,id:"player2" }) );
      panel.addLabelObj("Player 1 Is:", new ComboBox(playerOptions[0],player1Options,{listOnly:true,id:"player1is" }) );

      panel.setItemSize(400);
      panel.bindOk(data, () -> {
         var player1IsWhite = data.player1is==player1Options[0] ||
                  ( data.player1is==player1Options[2] && Math.random()>0.5 );
         var white = data.player1;
         var black = data.player2;
         if (!player1IsWhite)
         {
            black = data.player1;
            white = data.player2;
         }
         startGame( playerFromText(white), playerFromText(black) );
      }, true, "playerInfo");
   }

   function newGame()
   {
      game = new GameState(book);
      drawGame();
   }

   function createBoard()
   {
      boardGfx.graphics.clear();
      var vals = new Array<Float>();
      for(y in 0...8)
         for(x in 0...8)
         {
            vals.push(x*sqSize);
            vals.push(y*sqSize);
            if ( ((x+y)&1) == 1)
               vals.push(6);
            else
               vals.push(6+7);
         }
      tilesheet.drawTiles(boardGfx.graphics,vals);
      boardGfx.graphics.lineStyle(1, 0x40b0b0);
      boardGfx.graphics.drawRect(-1.5,-1.5, sqSize*8+3, sqSize*8+3 );
   }

   override public function screenLayout(w:Int, h:Int) layout();
   function layout()
   {
      setScale();

      var m = Std.int( Math.max(0, (historyY-menuButton.height)*0.5 ) );
      menuButton.x = menuButton.y = m;

      var statusH = status.textHeight;
      status.x = 5;
      status.y = statusH*0.5;
      status.width = sqSize*8;

      //boardGfx.x = Std.int( (stage.stageWidth-sqSize*8)*0.5 );
      boardGfx.x = 5;
      boardGfx.y = historyY;
      history.x = sqSize*8 + 10;
      history.width = stage.stageWidth - history.x - 5;
      history.y = historyY;
      history.height = stage.stageHeight - historyY-5;

      history.scrollV = history.maxScrollV;
   }

   function localToBoard(inX:Float, inY:Float)
   {
      var b = boardGfx.globalToLocal( localToGlobal( new Point(inX,inY)) );
      var x = Std.int(b.x/sqSize);
      var y = Std.int(b.y/sqSize);

      if (x>=0 && y>=0 && x<8 && y<8)
         return BPos.create(x,y);

      return null;
   }

   function setSelection(bPos:BPos)
   {
      selPos = bPos;
      var piece = selPos==null ? null : game.board.at(selPos);
      if (piece!=null && piece.isWhite!=game.isWhiteTurn)
         piece = null;
      selMoves = piece==null ? null : piece.getMoves(selPos,game.board);
   }

   override public function updateDelta(inDT:Float)
   {
      if (!game.gameOver() && gameStarted)
      {
         if (!isComputing && game.isCpuMove() )
         {
            isComputing = true;
            game.startCpuMove(asyncAiMove);
         }
         else if (isComputing)
         {
            game.thinkALittle();
            status.text = game.getAiText();
         }
      }
   }


   function asyncAiMove(move:Move)
   {
      //trace((isWhiteTurn?"white":"black") + " -> checks " + evalCount + ":" + val);
      nme.app.Application.runOnMainThread( () -> {
         isComputing = false;
         game.makeMove(move);
         lastMove = move;
         setSelection(null);
         drawGame();
      });
   }


   override public function onMouseClick(inX:Float, inY:Float)
   {
      if (gameStarted && game.isHumanTurn())
      {
         var bPos = localToBoard(inX,inY);
         if (bPos!=null)
         {
            if (selMoves!=null)
            {
               for(m in selMoves)
                  if (m.isTo(bPos))
                  {
                     game.makeMove(m);
                     lastMove = m;
                     setSelection(null);
                     drawGame();
                     return;
                  }
               setSelection(null);
            }
            else
               setSelection(bPos);
         }
         else
            setSelection(null);

         drawGame( );
      }
   }

   function drawGame()
   {
      var gfx = gameGraphics.graphics;
      gfx.clear();

      if (gameStarted)
         status.text = game.getStatus();
      history.text = game.getHistory();
      history.scrollV = history.maxScrollV;

      var board = game.board;

      var vals = new Array<Float>();

      if (lastMove!=null)
      {
         vals.push(lastMove.displayFrom.x*sqSize);
         vals.push(lastMove.displayFrom.y*sqSize);
         vals.push(16);

         vals.push(lastMove.displayTo.x*sqSize);
         vals.push(lastMove.displayTo.y*sqSize);
         vals.push(16);
      }

      var idx = 0;
      for(y in 0...8)
         for(x in 0...8)
         {
            var p = board.atXy(x,y);
            if (p!=null)
            {
               vals.push(x*sqSize);
               vals.push(y*sqSize);
               vals.push(p.getTile());
            }
         }

      if (selPos!=null)
      {
         vals.push(selPos.x*sqSize);
         vals.push(selPos.y*sqSize);
         vals.push(18);

         if (selMoves!=null)
            for(m in selMoves)
            {
               vals.push(m.displayTo.x*sqSize);
               vals.push(m.displayTo.y*sqSize);
               vals.push(15);
            }
      }
      tilesheet.drawTiles(gfx,vals);
   }
}
