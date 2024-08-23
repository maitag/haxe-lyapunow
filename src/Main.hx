package;

import lime.app.Application;
import lime.ui.Window;
import lime.ui.MouseButton;
import lime.ui.MouseWheelMode;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;

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

	var positionX:UniformFloat;
	var positionY:UniformFloat;
	var scaleX:UniformFloat;
	var scaleY:UniformFloat;
	
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

		positionX = new UniformFloat("uPositionX", 0.0);
		positionY = new UniformFloat("uPositionY", 0.0);
		scaleX = new UniformFloat("uScaleX", 1.0);
		scaleY = new UniformFloat("uScaleY", 1.0);

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
	
	var uiInit = false;

	public function onUIInit() 
	{
		trace("onUiInit");

		Lyapunow.init(lyapunowDisplay, formula, sequence, positionX, positionY, scaleX, scaleY, defaultParams, formulaParams);

		uiInit = true;
		
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
			for (c in sequence) {
				if ( c != "x" && c != "y" && Ui.sequence.indexOf(c) < 0  &&  formula.hasParam(c) == false ) {
					// trace('remove sequence param "$c"');
					oldUsedParams.set(c, formulaParams.get(c)); // store it for later usage
					formulaParams.remove(c);
					ui.removeFormulaParam(c); // remove that widget by UI
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

		if (Ui.formulaChanged) 
		{
			Ui.formulaChanged = false;				
			trace("-------- Formula change -----------:");
				
			var f:Formula = null;
			
			try {
				f = Ui.formula;
			}
			catch (e:FormulaException) {
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
				var _formulaParamsKeys:Array<String> = [for (p in formulaParams.keys()) p]; // better this to not confuse the map-iterator into loop! 
				for (p in _formulaParamsKeys) {
				// for (p in formulaParams.keys()) {
					if (params.indexOf(p) < 0  &&  sequence.indexOf(p) < 0) {
						// trace('remove param "$p"');
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
			Lyapunow.updateShader(formula, sequence, positionX, positionY, scaleX, scaleY, defaultParams, formulaParams);
		}

	}

	// override function onMouseMoveRelative (x:Float, y:Float):Void {}

	// ----------------- TOUCH EVENTS ------------------------------
	// override function onTouchStart (touch:lime.ui.Touch):Void {}
	// override function onTouchMove (touch:lime.ui.Touch):Void	{}
	// override function onTouchEnd (touch:lime.ui.Touch):Void {}
	
	// ----------------- KEYBOARD EVENTS ---------------------------
	var isShift = false;
	override function onKeyDown (keyCode:KeyCode, modifier:KeyModifier):Void {
		if (keyCode == KeyCode.LEFT_SHIFT || keyCode == KeyCode.RIGHT_SHIFT) isShift = true;
	}	
	override function onKeyUp (keyCode:KeyCode, modifier:KeyModifier):Void {
		if (keyCode == KeyCode.LEFT_SHIFT || keyCode == KeyCode.RIGHT_SHIFT) isShift = false;
	}
	
	//THANK u BloooddSWEATbeers ;) -> OLD friend (^^)*hugs
	var mouse_x:Float = 0;
	var mouse_y:Float = 0;
	var dragstart_x:Float = 0;
	var dragstart_y:Float = 0;
	var dragmode:Bool = false;
	var changed:Bool = false;
	var zoom:Float = 1.0;
	var zoomstep:Float = 1.2;

	override function onMouseDown(x:Float, y:Float, button:MouseButton):Void {	
		if ( button == MouseButton.LEFT ) startDrag(x, y);
	}
	
	override function onMouseUp(x:Float, y:Float, button:MouseButton):Void {	
		if ( button == MouseButton.LEFT ) stopDrag();
	}
	
	override function onMouseMove (x:Float, y:Float):Void {
		moveDrag(x, y);
	}
	
	override function onMouseWheel (deltaX:Float, deltaY:Float, deltaMode:MouseWheelMode):Void {
		if (mouse_x >= ui.mainArea.x && mouse_y <= ui.mainArea.bottom) return;
		if ( deltaY > 0 ) {
			if (scaleX.value < 0xfffff) {
				positionX.value -= zoomstep * (mouse_x - positionX.value) - (mouse_x - positionX.value);
				scaleX.value *= zoomstep;
			}
			if ( !isShift && scaleY.value < 0xfffff) {
				positionY.value -= zoomstep * (mouse_y - positionY.value) - (mouse_y - positionY.value);
				scaleY.value *= zoomstep;
			}
		}
		else {
			if ( scaleX.value > 0.0001 ) {
				positionX.value -= (mouse_x - positionX.value) / zoomstep - (mouse_x - positionX.value);
				scaleX.value /= zoomstep;
			}
			if ( !isShift && scaleY.value > 0.0001 ) {
				positionY.value -= (mouse_y - positionY.value) / zoomstep - (mouse_y - positionY.value);
				scaleY.value /= zoomstep;
			}
		}
		
		// updateUrlParams();
	}

	// Dragging --------------------------------------------------
	
	inline function startDrag(x:Float, y:Float) {
		if (x >= ui.mainArea.x && y <= ui.mainArea.bottom) return;
		dragstart_x = positionX.value - x;
		dragstart_y = positionY.value - y;
		dragmode = true;		
	}
		
	inline function stopDrag() {
		dragmode = false;
		if (changed) {
			changed = false;
			// updateUrlParams();
		}
	}
	
	inline function moveDrag(x:Float, y:Float) {
		mouse_x = x;
		mouse_y = y;		
		if (dragmode) {
			positionX.value = (dragstart_x + mouse_x);
			positionY.value = (dragstart_y + mouse_y);
			changed = true;
		}
	}
	

	// -------------- other WINDOWS EVENTS ----------------------------
	override function onWindowResize (width:Int, height:Int):Void {
		if (!uiInit) return;
		lyapunowDisplay.width = width;
		lyapunowDisplay.height = height;
		ui.resize(width, height);
	}
	
}
