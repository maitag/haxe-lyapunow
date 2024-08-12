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
	var customParams = new CustomParams();
	var oldUsedParams = new CustomParams();
	
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

	var formula:Formula;
	var sequence:String;

	override function update(deltaTime:Int):Void 
	{
		// TODO: --------- check a seqence-change ---------
		if (Ui.sequenceChanged) {
			Ui.sequenceChanged = false;

			trace("-------- Sequence change --------:");
			// TODO: check that it allways have one "x" and one "y" inside
			// -> have to create also new ui-widgets for more (e.g. "z") 
		}


		var f:Formula = null;
		// --------- check a formula-change -----------
		if (Ui.formulaChanged) {
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
				for (p in customParams.keys()) {
					if (params.indexOf(p) < 0) {
						trace('remove param "$p"');
						oldUsedParams.set(p, customParams.get(p)); // store it for later usage
						customParams.remove(p);
						// TODO: remove that widget by UI !
					}
				}

				// check for new added parameters inside formula
				for (p in params) {
					if (p == "i") found_i = true;
					else if (p == "n") found_n = true;
					else {
						if ( ! customParams.exists(p)) {
							if (p.length > 8) {
								trace('ERROR, parameter "$p" should have not more then 8 chars');
								// TODO: give error-feedback by UI !
								param_length_ok = false;
								break;
							}
							
							if (oldUsedParams.exists(p)) customParams.set( p, oldUsedParams.get(p) ); // reuse from later storage
							else customParams.set( p, new Param(p, "uParam"+p, 0.0, 0.0, 1.0) );

							trace('add new param "$p"'); // TODO: add new widget for by UI !

							// change parameter identifier to have unique name for glsl
							f.bind( ("uParam"+p : Formula), p);
						}
					}
				}

				if (found_i && found_n && param_length_ok) {

					formula = f;

					trace("formula ready to update:");
					trace(f.toString("glsl") , Ui.sequence);
					trace('sequence: ${Ui.sequence}\n');

					// TODO: -------> call lyapunows update function
					
				}
				else {
					if (!found_i) trace('ERROR, formula is need parameter "i"');
					if (!found_n) trace('ERROR, formula is need parameter "n"');
					// TODO: give error-feedback by UI !
				}


			}

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
