package;

import lime.app.Application;
import lime.ui.Window;
import lime.ui.MouseCursor;

import peote.view.*;

import Formula;
import FormulaException;

import ui.Ui;
import Param.DefaultParams;
import Param.CustomParams;

class Main extends Application
{
	var peoteView:PeoteView;
	var lyapunowDisplay:Display;
	var ui:Ui;

	var defaultParams:DefaultParams;
	var customParams:CustomParams;
	
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
		

		ui = new Ui(peoteView, defaultParams, "2.5*sin(i+n)^2+3", "xy", onUIInit);
		
	}
	
	public function onUIInit() 
	{
		trace("onUiInit");


		Lyapunow.init(lyapunowDisplay, defaultParams);

		// init uniforms
		// linesize = new UniformFloat("linesize", 0.1);
	}	

	// ------------------------------------------------------------
	// ----------------- LIME EVENTS ------------------------------
	// ------------------------------------------------------------	

	var f:Formula;
	override function update(deltaTime:Int):Void {
		if (Ui.formulaChanged) {
			Ui.formulaChanged = false;
			
			try {
				f = Ui.formula;
				var params = f.params();
				var found_i = false;
				var found_n = false;
				for (param in params) {
					if (param == "i") found_i = true;
					else if (param == "n") found_n = true;
					else {
						trace("param:",param);
						if (param.length > 8) trace('ERROR, parameter "$param" should have not more then 8 chars');
						f.bind( ("uParam"+param : Formula), param);
					}
				}

				if (found_i && found_n) {
					trace("ALL IS OK");
					
					trace(f.toString("glsl") );
					}
				else {
					if (!found_i) trace("ERROR, formula is need parameter i");
					if (!found_n) trace("ERROR, formula is need parameter n");
				}

			} catch (e:FormulaException) {
				trace(e.msg); // Error: Missing right operand.
				var spaces = ""; for (i in 0...e.pos) spaces += " ";
				trace(Ui.formula);
				trace(spaces + "^");
			}

			trace("update:", Ui.formula, Ui.sequence);
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
