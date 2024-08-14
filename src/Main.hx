package;

import lime.app.Application;
import lime.ui.Window;
import lime.ui.MouseCursor;

import peote.view.*;

import Formula;
import FormulaException;

import ui.Ui;
import Param.DefaultParams;
import Param.FormulaParams;

class Main extends Application
{
	var peoteView:PeoteView;
	var lyapunowDisplay:Display;
	var ui:Ui;

	var defaultParams:DefaultParams;
	var formulaParams = new FormulaParams();
	var oldUsedParams = new FormulaParams();
	
	var formula:Formula;
	var sequence:Array<String>;

	override function onWindowCreate():Void
	{
		switch (window.context.type) {
			case WEBGL, OPENGL, OPENGLES:
				try init(window)
				catch (_) trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()), _);
			default: throw("Sorry, only works with OpenGL.");
		}
	}

	public function init(window:Window)
	{
		peoteView = new PeoteView(window);
		
		lyapunowDisplay = new Display(0, 0, window.width, window.height);
		peoteView.addDisplay(lyapunowDisplay);

		defaultParams = {
			startIndex: new Param( "Start index:"   , "uStartIndex", 0, -10,  10 ),
			iterPre:    new Param( "Pre-iteration:" , "uIterPre"   , 0,   0,  20 ),
			iterMain:   new Param( "Main-iteration:", "uIterMain"  , 3,   1, 200 ),
			balance:    new Param( "Balance:"       , "uBalance"   , 1,  -1,   3 ),
		};
		
		formulaParams = [
			"a" => new Param( "a:" , "uParama", 2.5, 0.0, 10 ),
			"b" => new Param( "b:" , "uParamb", 2.0, 0.0, 10 )
		];

		formula = "a*sin(i+n)^2+b";
		for (p in formulaParams.keys()) formula.bind( ("uParam"+p : Formula), p);
		
		sequence = ["x", "y"];

		ui = new Ui(peoteView, defaultParams, formulaParams, "a*sin(i+n)^2+b", "xy", onUIInit);
		
	}
	
	public function onUIInit() 
	{
		trace("onUiInit");

		Lyapunow.init(lyapunowDisplay, formula, sequence, defaultParams, formulaParams);

		// var timer = new haxe.Timer(1000); timer.run = updateTime;
	}	

	// ------------------------------------------------------------
	// ----------------- LIME EVENTS ------------------------------
	// ------------------------------------------------------------	

	// function updateTime():Void 
	override function update(deltaTime:Int):Void 
	{
		var updateShader = false;

		// --------- check a seqence-change ---------

		if (Ui.sequenceChanged) 
		{
			Ui.sequenceChanged = false;

			trace("-------- Sequence change --------:");

			// check for removed parameters
			for (s in sequence) {
				if ( Ui.sequence.indexOf(s) < 0  &&  formula.hasParam(s) == false ) {
					trace('remove sequence param "$s"');
					oldUsedParams.set(s, formulaParams.get(s)); // store it for later usage
					formulaParams.remove(s);
					ui.removeFormulaParam(s); // remove that widget by UI
				}
			}


			var found_x = false;
			var found_y = false;
			sequence = [];

			// check that it allways have one "x" and one "y" inside
			for (i in 0...Ui.sequence.length) {
				var c = Ui.sequence.charAt(i);
				if (c == "x") found_x = true;
				else if (c == "y") found_y = true;
				else if ( ! formulaParams.exists(c)) {
					var param:Param = (oldUsedParams.exists(c)) ? oldUsedParams.get(c) : new Param(c, "uParam"+c, 0.0, -10, 10);
					formulaParams.set( c, param );

					// add new widget by UI !
					ui.addFormulaParam(c, param);
				}					
				sequence.push(c);
			}

			if (found_x && found_y) {
				updateShader = true;
			}
			else {
				if (!found_x) trace('ERROR, formula is need parameter "x"');
				if (!found_y) trace('ERROR, formula is need parameter "y"');
				// TODO: give error-feedback by UI !
			}
		}


		// --------- check a formula-change -----------

		var f:Formula = null;
		if (Ui.formulaChanged) 
		{
			Ui.formulaChanged = false;
			
			trace("-------- Formula change -----------:");

			try { f = Ui.formula;
			} catch (e:FormulaException) {
				trace(e.msg);
				var spaces = ""; for (i in 0...e.pos) spaces += " ";
				trace(Ui.formula);
				trace(spaces + "^\n");
				// TODO: give error-feedback by UI !
			}

			// --------------------------
			if (f != null)
			{
				var found_i = false;
				var found_n = false;
				var param_length_ok = true;

				var params = f.params();

				// check for removed parameters inside formula
				for (p in formulaParams.keys()) {
					if (params.indexOf(p) < 0  &&  sequence.indexOf(p) < 0) {
						trace('remove param "$p"');
						oldUsedParams.set(p, formulaParams.get(p)); // store it for later usage
						formulaParams.remove(p);
						ui.removeFormulaParam(p); // remove that widget by UI
					}
				}

				// check for new added parameters inside formula
				for (p in params) {
					if (p == "i") found_i = true;
					else if (p == "n") found_n = true;
					else if (p != "x" && p != "y")
					{
						if ( ! formulaParams.exists(p)) {
							if (p.length > 8) {
								trace('ERROR, parameter "$p" should have not more then 8 chars');
								// TODO: give error-feedback by UI !
								param_length_ok = false;
								break;
							}
							
							var param:Param = (oldUsedParams.exists(p)) ? oldUsedParams.get(p) : new Param(p, "uParam"+p, 0.0, 0.0, 1.0);
							formulaParams.set( p, param );

							// add new widget by UI !
							ui.addFormulaParam(p, param);
						}
						// change parameter identifier to have unique name for glsl
						f.bind( ("uParam"+p : Formula), p);
					}
				}

				if (found_i && found_n && param_length_ok) {
					formula = f;
					updateShader = true;
				}
				else {
					if (!found_i) trace('ERROR, formula is need parameter "i"');
					if (!found_n) trace('ERROR, formula is need parameter "n"');
					// TODO: give error-feedback by UI !
				}
			}
		}

		if (updateShader) {
			// call lyapunows update function
			Lyapunow.updateShader(formula, sequence, defaultParams, formulaParams);
		}

	}

	// override function onMouseMove (x:Float, y:Float):Void {}

	// override function onMouseDown (x:Float, y:Float, button:lime.ui.MouseButton):Void {}
	// override function onMouseUp (x:Float, y:Float, button:lime.ui.MouseButton):Void {}	
	// override function onMouseWheel (deltaX:Float, deltaY:Float, deltaMode:lime.ui.MouseWheelMode):Void {}
	// override function onMouseMoveRelative (x:Float, y:Float):Void {}

	// ----------------- TOUCH EVENTS ------------------------------
	// override function onTouchStart (touch:lime.ui.Touch):Void {}
	// override function onTouchMove (touch:lime.ui.Touch):Void	{}
	// override function onTouchEnd (touch:lime.ui.Touch):Void {}
	
	// ----------------- KEYBOARD EVENTS ---------------------------
	// override function onKeyDown (keyCode:lime.ui.KeyCode, modifier:lime.ui.KeyModifier):Void {}	
	// override function onKeyUp (keyCode:lime.ui.KeyCode, modifier:lime.ui.KeyModifier):Void {}

	// -------------- other WINDOWS EVENTS ----------------------------
	override function onWindowResize (width:Int, height:Int):Void {
		lyapunowDisplay.width = width;
		lyapunowDisplay.height = height;
		if (ui != null) ui.resize(width, height);
	}
	
}
