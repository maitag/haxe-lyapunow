package;

import peote.ui.interactive.UIArea;
import lime.app.Application;
import lime.ui.Window;
import lime.ui.MouseCursor;

import peote.view.PeoteView;
import peote.view.Display;
import peote.view.Program;
import peote.view.Buffer;
import peote.view.Element;
import peote.view.Color;

import peote.view.UniformFloat;


import ui.Ui;

class Main extends Application
{
	var peoteView:PeoteView;
	var lyapunowDisplay:Display;
	var ui:Ui;

	var uniformFloats = new Array<UniformFloat>();
	
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


		
		uniformFloats.push( new UniformFloat("uIterPre", 0.0) );
		uniformFloats.push( new UniformFloat("uIterMain", 3.0) );
		uniformFloats.push( new UniformFloat("uStartIndex", 0.0) );
		uniformFloats.push( new UniformFloat("uBalance", 0.5) );

		ui = new Ui(peoteView, uniformFloats, "2.5*sin(i+n)^2+3", "xy", onUIInit);
		
	}
	
	public function onUIInit() 
	{
		trace("onUiInit");


		Lyapunow.init(lyapunowDisplay, uniformFloats);

		// init uniforms
		// linesize = new UniformFloat("linesize", 0.1);
	}	

	// ------------------------------------------------------------
	// ----------------- LIME EVENTS ------------------------------
	// ------------------------------------------------------------	

	override function update(deltaTime:Int):Void {
		if (Ui.formulaChanged) {
			Ui.formulaChanged = false;
			

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
