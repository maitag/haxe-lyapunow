package;

#if html5
import js.Browser;
#end

import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.crypto.Base64;

import lime.app.Application;
import lime.ui.Window;
import lime.ui.MouseButton;
import lime.ui.MouseWheelMode;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Touch;

import peote.view.PeoteView;
import peote.view.Display;
import peote.view.Color;
import peote.view.UniformFloat;

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
	var formulaParamsLength:Int = 2;
	var oldUsedParams = new FormulaParams();
	
	var formula:Formula;
	var formulaString:String;
	var formulaBytes:Bytes = null;
	var sequence:Array<String>;

	var posColor:Color = Color.RED;
	var midColor:Color = Color.BLACK;
	var negColor:Color = Color.BLUE;

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


		// ----- param juggling -.-...-....-.-....---

		positionX = new UniformFloat("uPositionX", 0.0);
		positionY = new UniformFloat("uPositionY", 0.0);
		scaleX = new UniformFloat("uScaleX", 1.0);
		scaleY = new UniformFloat("uScaleY", 1.0);

		defaultParams = {
			startIndex: new Param( "Start index:"   , "uStartIndex", 0, -10,  10),
			iterPre:    new Param( "Pre-iteration:" , "uIterPre"   , 0,   0,  20, 0, 300 ),
			iterMain:   new Param( "Main-iteration:", "uIterMain"  , 3,   1, 200, 1, 500),
			balance:    new Param( "Balance:"       , "uBalance"   , 1,  -1,   3 ),
		};
		
		formulaString = "a*sin(i+n)^2+b";
		formula = formulaString;
		
		sequence = ["x", "y"];

		formulaParams = [
			"a" => new Param( "a:" , "uParama", 2.5, -5, 5 ),
			"b" => new Param( "b:" , "uParamb", 2.0, -5, 5 )
		];

		// ------------ only for the html browser --------- 
		#if html5
		// fetching all from URL
		var e:EReg = new EReg("\\?([" + Base64.CHARS + "]+)$", "");
		if (e.match(Browser.document.URL)) {
			var bytes:Bytes = Base64.decode( e.matched(1) , false);
			// TODO: decompress ! 
			unSerializeParams( new BytesInput(bytes) );
		}
		#end // -------------------------------------------

		for (p in formulaParams.keys()) formula.bind( ("uParam"+p : Formula), p);

		ui = new Ui(peoteView,
			updateUrlParams,
			positionX, positionY, scaleX, scaleY,
			defaultParams,
			formulaParams,
			posColor, midColor, negColor,
			formulaString,
			sequence.join(""),
			onUIInit
		);
		
	}
	
	var uiInit = false;

	public function onUIInit() 
	{
		trace("onUiInit");

		Lyapunow.init(lyapunowDisplay, formula, sequence, positionX, positionY, scaleX, scaleY, defaultParams, formulaParams, posColor, midColor, negColor);

		uiInit = true;
		
		// var timer = new haxe.Timer(1000); timer.run = updateTime;
	}	

	// ------------------------------------------------
	// --------------- URL handling -------------------
	// ------------------------------------------------
	// var history_state:Int = 0;
	inline function updateUrlParams()
	{	
		#if html5
		var b:BytesOutput = serializeParams();
		var base64:String = Base64.encode(b.getBytes(), false);
		Browser.window.history.replaceState('haxelyapunow', 'haxelyapunow', Browser.location.pathname + '?' + base64);

		// this adds a new state each time (so borwser can go back into history 
		// better let do this only by press a button to not spam the history [needs random salt at end of url or something to refresh the if it goes back!])
		// Browser.window.history.pushState('haxelyapunow'+(history_state++), "", Browser.location.pathname + '?' + base64);

		#else
		// for testing only:
		// var bytes = serializeParams().getBytes();
		// trace(Base64.encode(bytes, false));
		// unSerializeParams(new BytesInput(bytes));
		#end
	}
	
	public function serializeParams():BytesOutput
	{
		var b = new BytesOutput();
		b.writeFloat(positionX.value);
		b.writeFloat(positionY.value);
		b.writeFloat(scaleX.value);
		b.writeFloat(scaleY.value);

		b.writeFloat(defaultParams.startIndex.value);
		b.writeFloat(defaultParams.startIndex.valueStart);
		b.writeFloat(defaultParams.startIndex.valueEnd);

		b.writeFloat(defaultParams.iterPre.value);
		b.writeFloat(defaultParams.iterPre.valueStart);
		b.writeFloat(defaultParams.iterPre.valueEnd);

		b.writeFloat(defaultParams.iterMain.value);
		b.writeFloat(defaultParams.iterMain.valueStart);
		b.writeFloat(defaultParams.iterMain.valueEnd);

		b.writeFloat(defaultParams.balance.value);
		b.writeFloat(defaultParams.balance.valueStart);
		b.writeFloat(defaultParams.balance.valueEnd);

		b.writeInt32(Lyapunow.element.negColor);
		b.writeInt32(Lyapunow.element.midColor);
		b.writeInt32(Lyapunow.element.posColor);

		// Sequence
		_writeString(sequence.join(""), b);

		// Formula
		_writeString(formulaString, b);

		// Formulas param values
		var params = formula.params();
		for (p in params) {
			if (p == "i" || p == "n" || p == "x" || p == "y") continue;
			var fp = formulaParams.get(p);
			b.writeFloat(fp.value);
			b.writeFloat(fp.valueStart);
			b.writeFloat(fp.valueEnd);
		}
		
		// sequence-params what is not used by FORMULA!
		for (p in sequence) {
			if (p == "x" || p == "y" || params.indexOf(p) >= 0) continue;
			var fp = formulaParams.get(p);
			b.writeFloat(fp.value);
			b.writeFloat(fp.valueStart);
			b.writeFloat(fp.valueEnd);
		}
		
		return(b);
	}
	
	inline function _writeString(s:String, b:BytesOutput):Void {
		b.writeByte((s.length<255) ? s.length: 255);
		for (i in 0...((s.length<255) ? s.length: 255)) b.writeByte(s.charCodeAt(i));
	}

	static inline function _readString(b:BytesInput):String {
		var len:Int = b.readByte();
		var s:String = "";
		for (i in 0...len) s += String.fromCharCode(b.readByte());
		return s;
	}
				
	public function unSerializeParams(b:BytesInput)
	{
		//todo: TRY CATCH

		positionX.value = b.readFloat();
		positionY.value = b.readFloat();
		scaleX.value = b.readFloat();
		scaleY.value = b.readFloat();

		defaultParams.startIndex.value = b.readFloat();
		defaultParams.startIndex.valueStart = b.readFloat();
		defaultParams.startIndex.valueEnd = b.readFloat();

		defaultParams.iterPre.value = b.readFloat();
		defaultParams.iterPre.valueStart = b.readFloat();
		defaultParams.iterPre.valueEnd = b.readFloat();

		defaultParams.iterMain.value = b.readFloat();
		defaultParams.iterMain.valueStart = b.readFloat();
		defaultParams.iterMain.valueEnd = b.readFloat();

		defaultParams.balance.value = b.readFloat();
		defaultParams.balance.valueStart = b.readFloat();
		defaultParams.balance.valueEnd = b.readFloat();

		negColor = b.readInt32();
		midColor = b.readInt32();
		posColor = b.readInt32();

		// Sequence
		sequence = _readString(b).split("");
		//TODO: error if sequence is to long

		// Formula
		formulaString = _readString(b);
		formula = formulaString;

		// set all new for Formulas param values
		formulaParams = [];

		for (p in formula.params()) {
			if (p == "i" || p == "n" || p == "x" || p == "y") continue;
			formulaParams.set( p, new Param(p, "uParam"+p, b.readFloat(), b.readFloat(), b.readFloat()) );
			formulaParamsLength++; //TODO: error if TO MUCH PARAMETERS
		}
		
		// sequence-params what is not used by FORMULA!
		for (p in sequence) {
			if (p == "i" || p == "n" || p == "x" || p == "y" || formulaParams.exists(p)) continue;
			formulaParams.set( p, new Param(p, "uParam"+p, b.readFloat(), b.readFloat(), b.readFloat()) );
			formulaParamsLength++; //TODO: error if TO MUCH PARAMETERS
		}
		
		// trace(formulaParams);
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
			// trace("-------- Sequence change --------:");

			// check for removed parameters
			for (c in sequence) {
				if ( c != "x" && c != "y" && Ui.sequence.indexOf(c) < 0  &&  formula.hasParam(c) == false ) {
					// trace('remove sequence param "$c"');
					oldUsedParams.set(c, formulaParams.get(c)); // store it for later usage
					formulaParams.remove(c);
					formulaParamsLength--;
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
					var param:Param = (oldUsedParams.exists(c)) ? oldUsedParams.get(c) : new Param(c, "uParam"+c, 0.0, -5, 5);
					formulaParams.set( c, param );
					formulaParamsLength++; //TODO: erros if TO MUCH PARAMETERS
					// add new widget by UI !
					ui.addFormulaParam(c, param);
				}					
				sequence.push(c);
			}
			
			if (found_x && found_y) {
				updateShader = true;
			}
			else {
				if (!found_x) trace('ERROR, sequence is need parameter "x"');
				if (!found_y) trace('ERROR, sequence is need parameter "y"');
				// TODO: give error-feedback by UI !
			}
		}


		// --------- check a formula-change -----------

		if (Ui.formulaChanged) 
		{
			Ui.formulaChanged = false;				
			// trace("-------- Formula change -----------:");
				
			var f:Formula = null;
			
			try {
				f = Ui.formula;
			}
			catch (e:FormulaException) {
				/*trace(e.msg);
				var spaces = ""; for (i in 0...e.pos) spaces += " ";
				trace(Ui.formula);
				trace(spaces + "^\n");*/
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
						formulaParamsLength--;
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
								// trace('ERROR, parameter "$p" should have not more then 8 chars');
								// TODO: give error-feedback by UI !
								param_length_ok = false;
								break;
							}
							
							var param:Param = (oldUsedParams.exists(p)) ? oldUsedParams.get(p) : new Param(p, "uParam"+p, 0.0, -5, 5);
							formulaParams.set( p, param );
							formulaParamsLength++; //TODO: error if TO MUCH PARAMETERS
							// add new widget by UI !
							ui.addFormulaParam(p, param);
						}
						// change parameter identifier to have unique name for glsl
						f.bind( ("uParam"+p : Formula), p);
					}
				}

				if (found_i && found_n && param_length_ok) {
					formula = f;
					formulaString = Ui.formula;
					updateShader = true;
				}
				else {
					// if (!found_i) trace('ERROR, formula is need parameter "i"');
					// if (!found_n) trace('ERROR, formula is need parameter "n"');
					// TODO: give error-feedback by UI !
				}
			}
		}

		if (updateShader) {
			// call lyapunows update function
			Lyapunow.updateShader(formula, sequence, positionX, positionY, scaleX, scaleY, defaultParams, formulaParams);
			Ui.paramChanged = true;
		}

		if (Ui.paramChanged) {
			Ui.paramChanged = false;
			updateUrlParams();
		}

	}


	// ----------------- KEYBOARD EVENTS ---------------------------
	var isShift = false;
	override function onKeyDown(keyCode:KeyCode, modifier:KeyModifier):Void {
		if (keyCode == KeyCode.LEFT_SHIFT || keyCode == KeyCode.RIGHT_SHIFT) isShift = true;

		// save OSL
		if ((modifier & KeyModifier.CTRL>0) && (modifier & KeyModifier.SHIFT>0) && ( keyCode == KeyCode.RETURN || keyCode == KeyCode.NUMPAD_ENTER) )
			Exporter.saveDialogueOSL(formula, sequence, positionX, positionY, scaleX, scaleY, defaultParams, formulaParams);
		if ((modifier & KeyModifier.CTRL>0) && ( keyCode == KeyCode.RETURN || keyCode == KeyCode.NUMPAD_ENTER) )
			Exporter.saveOSL(formula, sequence, positionX, positionY, scaleX, scaleY, defaultParams, formulaParams);


	}

	override function onKeyUp(keyCode:KeyCode, modifier:KeyModifier):Void {
		if (keyCode == KeyCode.LEFT_SHIFT || keyCode == KeyCode.RIGHT_SHIFT) isShift = false;
	}
	
	override function onWindowLeave() {
		#if html5
		isShift = false;
		#end
	}

	// ----------------- TOUCH and MOUSE EVENTS ------------------------------
	/*
	var checkFirstTouch = true;
	var isTouch = false;

	var mouse_x:Float = 0;
	var mouse_y:Float = 0;
	var dragstart_x:Float = 0;
	var dragstart_y:Float = 0;
	var dragmode:Bool = false;
	var changed:Bool = false;
	//var zoom:Float = 1.0;
	var zoomstep:Float = 1.2;

	override function onTouchStart (touch:Touch):Void {
		if (checkFirstTouch) {checkFirstTouch = false; isTouch = true;}
		if (isTouch) startDrag(touch.x, touch.y);
	}
	override function onTouchMove (touch:Touch):Void {
		if (isTouch) moveDrag(touch.x, touch.y);
	}
	override function onTouchEnd (touch:Touch):Void {
		if (isTouch) stopDrag();
	}
	
	override function onMouseDown(x:Float, y:Float, button:MouseButton):Void {	
		if (checkFirstTouch) checkFirstTouch = false;
		if (!isTouch) if ( button == MouseButton.LEFT ) startDrag(x, y);
	}
	
	override function onMouseUp(x:Float, y:Float, button:MouseButton):Void {	
		if (!isTouch) if ( button == MouseButton.LEFT ) stopDrag();
	}
	
	override function onMouseMove (x:Float, y:Float):Void {
		if (!isTouch) moveDrag(x, y);
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
		
		updateUrlParams();
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
			updateUrlParams();
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
	*/

	// TODO: extend peote-ui to let the Display also have the mousewheel-handler
	override function onMouseWheel (deltaX:Float, deltaY:Float, deltaMode:MouseWheelMode):Void {
		ui.mouseWheel(deltaX, deltaY, deltaMode, isShift);
	}


	// -------------- other WINDOWS EVENTS ----------------------------
	override function onWindowResize (width:Int, height:Int):Void {
		if (!uiInit) return;
		lyapunowDisplay.width = width;
		lyapunowDisplay.height = height;
		ui.resize(width, height);
	}
	
}
