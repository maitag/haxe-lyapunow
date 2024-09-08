package ui;

import haxe.ds.Vector;

import lime.ui.MouseButton;
import lime.ui.MouseWheelMode;

import peote.ui.event.PointerEvent;
import peote.ui.event.WheelEvent;
import peote.ui.event.PointerType;
import peote.view.PeoteView;
import peote.view.Color;
import peote.view.UniformFloat;

import peote.text.Font;

import peote.ui.PeoteUIDisplay;
import peote.ui.style.RoundBorderStyle;
import peote.ui.style.BoxStyle;
import peote.ui.interactive.UISlider;
import peote.ui.config.ResizeType;
import peote.ui.event.WheelEvent;

import Param;
import Param.DefaultParams;
import Param.FormulaParams;

class Ui
{
	// statics callbacks
	public static var formula:String;
	public static var sequence:String;

	public static var formulaChanged = false;
	public static var sequenceChanged = false;
	public static var paramChanged = false;
	
	var peoteView:PeoteView;

	var updateUrlParams:Void->Void;

	var positionX:UniformFloat;
	var positionY:UniformFloat;
	var scaleX:UniformFloat;
	var scaleY:UniformFloat;

	var defaultParams:DefaultParams;
	var formulaParams:FormulaParams;
	var onInit:Void->Void;

	var peoteUiDisplay:PeoteUIDisplay;

	public var mainArea:UiMainArea;
	var mainSlider:UISlider;

	// statics into style (keep that in ORDER because if there is transparence the z-buffer gives glitches!)
	public static var font:Font<UiFontStyle>;
	public static var fontStyle = new UiFontStyle();

	public static var mainStyleBG = RoundBorderStyle.createById(0, 0x0000007a);
	public static var paramStyleBG = RoundBorderStyle.createById(1, 0x050a0380, 0xddff2205);
	public static var paramStyleFG = RoundBorderStyle.createById(2);

	public static var selectionStyle = BoxStyle.createById(0, Color.GREY3);
	public static var cursorStyle = BoxStyle.createById(1, 0xaa2211ff);

	var posColor:Color;
	var midColor:Color;
	var negColor:Color;

	public function new(
		peoteView:PeoteView,
		updateUrlParams:Void->Void,
		positionX:UniformFloat, positionY:UniformFloat, scaleX:UniformFloat, scaleY:UniformFloat, 
		defaultParams:DefaultParams,
		formulaParams:FormulaParams,
		posColor:Color, midColor:Color, negColor:Color, 
		formula:String,
		sequence:String,
		onInit:Void->Void)
	{
		this.peoteView = peoteView;
		this.updateUrlParams = updateUrlParams;
		this.positionX = positionX;
		this.positionY = positionY;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
		this.defaultParams = defaultParams;
		this.formulaParams = formulaParams;
		this.posColor = posColor; this.midColor = midColor; this.negColor = negColor;
		Ui.formula = formula;
		Ui.sequence = sequence;
		this.onInit = onInit;

		// load font for UI
		new Font<UiFontStyle>("assets/hack_ascii.json").load( onFontLoaded );
	}

	public function onFontLoaded(font:Font<UiFontStyle>)
	{
		Ui.font = font;

		// ---- layer styles props -----
		
		fontStyle.color = 0xc0f232ff;		
		
		// -------------------------------------------------------
		// --- PeoteUIDisplay with styles in Layer-Depth-Order ---
		// -------------------------------------------------------
		
		peoteUiDisplay = new PeoteUIDisplay(0, 0, peoteView.width, peoteView.height,
			[ mainStyleBG, paramStyleBG, paramStyleFG, selectionStyle, fontStyle, cursorStyle ]
		);
		peoteView.addDisplay(peoteUiDisplay);
		
		// ---------- peoteUiDisplay Events -------------
		// peoteUiDisplay.onPointerOver = (_, e:PointerEvent) -> trace("UI->onPointerOver", e);
		// peoteUiDisplay.onPointerOut = (_, e:PointerEvent) -> trace("UI->onPointerOut", e);
		peoteUiDisplay.onPointerDown = pointerDown;
		peoteUiDisplay.onPointerUp = pointerUp;	
		peoteUiDisplay.onPointerMove = pointerMove;
		// peoteUiDisplay.on

		// --------------------------------
		// ---------- main menu -----------
		// --------------------------------

		// TODO



		// --------------------------------
		// --------- main area ------------
		// --------------------------------
		

		widthBeforeOverflow = Std.int( Math.max( Math.min( peoteView.width / 3, 500 ), 200));
		mainArea_oldHeight = heightBeforeOverflow = Std.int( Math.max( Math.min( peoteView.height * 0.75, 500 ), 200));

		mainArea = new UiMainArea(
			defaultParams, formulaParams, posColor, midColor, negColor,
			peoteView.width - widthBeforeOverflow, 3,
			widthBeforeOverflow, 400,
			{
				backgroundStyle:mainStyleBG,
				resizeType:ResizeType.LEFT|ResizeType.BOTTOM|ResizeType.BOTTOM_LEFT,
				backgroundSpace:{top: -3, bottom: -3}, // TODO: adjust the resizers also into ui-lib!
				minWidth:130, minHeight:100
			}
		);
		
		mainArea.onPointerDown = (_, e:PointerEvent) ->{
			// trace("mainArea->onPointerDown", e);
		} 
		mainArea.onPointerUp = (_, e:PointerEvent) -> {
			// trace("mainArea->onPointerUp", e);
		}

		mainArea.moveEventsBubbleToDisplay = true;
		mainArea.upDownEventsBubbleToDisplay = false;


		peoteUiDisplay.add(mainArea);
		
		mainArea.onResizeHeight = (_, height:Int, deltaHeight:Int) -> {
			if (height > peoteUiDisplay.height - 6) {
				height = peoteUiDisplay.height - 6;
				mainArea.height = height;
				
			}

			mainSlider.height = height+6;
			mainSlider.updateLayout();

			// TODO: show and hide the slider,
			// resize all of mainArea with different right-space
			if (!mainSlider.isVisible && mainArea.innerHeight > mainArea.height) {
				mainSlider.show();
				mainArea.width -= mainSlider.width;
			} else if (mainSlider.isVisible && mainArea.innerHeight <= mainArea.height) {
				mainSlider.hide();
				mainArea.width += mainSlider.width;
			}
		};



		
		// ------------------------------------
		// ---- slider to scroll main area ----		
		// ------------------------------------
		
		mainSlider = new UISlider(peoteView.width - 20, 0, 20, mainArea.height, {
			draggerStyle: paramStyleFG.copy(0x071508bb, 0x7aa02add, 1),
			draggerSize:14,
			draggSpace:1,
		});
		peoteUiDisplay.add(mainSlider);
		if (mainArea.innerHeight <= mainArea.height) mainSlider.hide();
		
		mainSlider.onMouseWheel = (_, e:WheelEvent) -> {
			// mainSlider.setWheelDelta(e.deltaY);
			mainSlider.setDelta( e.deltaY * 17);
		} 
		
		// bind slider to mainArea
		mainArea.bindVSlider(mainSlider);
		
		
		/*
		\o/
		*/
		// ---------------------------------------------------------
		PeoteUIDisplay.registerEvents(peoteView.window);

		onInit();
		
		mainArea.height = mainArea.innerHeight + 6;
		mainArea.updateLayout(); // is need for inner UIAreas
		resize(peoteUiDisplay.width, peoteUiDisplay.height);
	}	

	// ------------------------------------------------
	// ----- Add/Remove formula-parameter -------------
	// ------------------------------------------------

	public function addFormulaParam(paramIdentifier:String, param:Param) {
		mainArea.addFormulaParam(paramIdentifier, param);
	}

	public function removeFormulaParam(paramIdentifier:String) {
		mainArea.removeFormulaParam(paramIdentifier);
	}

	// ------------------------------------------------
	// -------------- RESIZING ------------------------
	// ------------------------------------------------
	var widthIsOverflow = false;
	var widthBeforeOverflow:Int;
	var heightIsOverflow = false;
	var heightBeforeOverflow:Int;
	var mainArea_oldHeight:Int;

	public function resize(width:Int, height:Int) {
		peoteUiDisplay.width = width;
		peoteUiDisplay.height = height;

		if (mainSlider.isVisible) width -= mainSlider.width;
		height -= 6;

		if (widthIsOverflow) {
			if (mainArea.x > 0) {
				if (width < mainArea.width) {
					widthBeforeOverflow = mainArea.width;
					mainArea.width = width;
					mainArea.x = 0;
				}
				else {
					mainArea.right = width;
					widthBeforeOverflow = mainArea.width;
					widthIsOverflow = false;
				}
			}		
			else if (width > widthBeforeOverflow) {
				mainArea.width = widthBeforeOverflow;
				mainArea.right = width;
				widthIsOverflow = false;
			}
			else mainArea.width = width;
		}
		else {
			if (width < mainArea.width) {
				widthBeforeOverflow = mainArea.width;
				mainArea.width = width;
				mainArea.x = 0;
				widthIsOverflow = true;
			}
			else mainArea.right = width;
		}

		if (heightIsOverflow) {
			if (mainArea.height < mainArea_oldHeight) {
				if (height < mainArea.height) {
					heightBeforeOverflow = mainArea.height;
					mainArea_oldHeight = mainArea.height = height;
				}
				else {
					heightBeforeOverflow = mainArea.height;
					heightIsOverflow = false;
				}
			}		
			if (height > heightBeforeOverflow) {
				mainArea_oldHeight = mainArea.height = heightBeforeOverflow;
				heightIsOverflow = false;
			}
			else mainArea_oldHeight = mainArea.height = height;		
		}
		else {
			if (height < mainArea.height) {
				heightBeforeOverflow = mainArea.height;
				mainArea_oldHeight = mainArea.height = height;
				heightIsOverflow = true;
			}
		}
		
		mainSlider.height = mainArea.height+6;
		mainSlider.right = peoteUiDisplay.width;

		mainSlider.updateLayout();
		mainArea.updateLayout();
	}

	// ------------------------------------------------
	// -------------- DRAGGING ------------------------
	// ------------------------------------------------
	var mouse_x:Float = 0;
	var mouse_y:Float = 0;
	var mouse_start_x:Float = 0;
	var mouse_start_y:Float = 0;
	
	var mouse_mode:Bool = false;
	var touch_mode:Bool = false;

	var active_touch_id:Vector<{x:Float, y:Float}> = new Vector(10); // TODO: make depend on how much allowed at same time
	var active_touches = new Array<Int>(); // stores the touch-ids into order
	
	var touch_start_x:Float = 0; // center if 2 touchpoints
	var touch_start_y:Float = 0;
	var touch_start_distance:Float = 0;

	var touch_position_start_x:Float = 0;
	var touch_position_start_y:Float = 0;

	var touch_scale_start:Float = 0;

	function pointerDown(_, e:PointerEvent) {
		if (e.type == PointerType.TOUCH)
		{
			// trace("UI->onPointerDown TOUCH", e);
			active_touch_id.set(e.touch.id, { x: e.x, y: e.y });
			active_touches.unshift(e.touch.id);
			
			if (active_touches.length == 1) { // single touchpoint
				touch_start_x = e.x;
				touch_start_y = e.y;
			}
			else {
				var t = active_touch_id.get(active_touches[1]);
				touch_start_x = (t.x + e.x)/2;
				touch_start_y = (t.y + e.y)/2;
				touch_start_distance = Math.sqrt( (t.x - e.x)*(t.x - e.x) + (t.y - e.y)*(t.y - e.y) );
			}

			touch_position_start_x = positionX.value;
			touch_position_start_y = positionY.value;
			touch_scale_start = scaleX.value;

			touch_mode = true;
		}
		else // ----- MOUSE DOWN -------
		{
			// trace("UI->onPointerDown MOUSE", e);
			if ( e.type == PointerType.MOUSE && e.mouseButton != MouseButton.LEFT ) return;
			
			mouse_start_x = positionX.value - e.x;
			mouse_start_y = positionY.value - e.y;

			mouse_mode = true;
		}	
	}

	function pointerUp(_, e:PointerEvent) {
		if (e.type == PointerType.TOUCH)
		{
			// trace("UI->onPointerUp TOUCH", e);			
			active_touches.remove(e.touch.id);
			
			if (active_touches.length == 0) {
				touch_mode = false;
				updateUrlParams();
			}
			else {
				if (active_touches.length == 1) {
					var t = active_touch_id.get(active_touches[0]);
					touch_start_x = t.x;
					touch_start_y = t.y;
				}
				else {
					var t0 = active_touch_id.get(active_touches[0]);
					var t1 = active_touch_id.get(active_touches[1]);
					touch_start_x = (t0.x + t1.x)/2;
					touch_start_y = (t0.y + t1.y)/2;
					touch_start_distance = Math.sqrt( (t0.x - t1.x)*(t0.x - t1.x) + (t0.y - t1.y)*(t0.y - t1.y) );
				}
				touch_position_start_x = positionX.value;
				touch_position_start_y = positionY.value;
				touch_scale_start = scaleX.value;
			}

		}
		else // ----- MOUSE UP -------
		{
			// trace("UI->onPointerUp MOUSE", e);
			if ( e.type == PointerType.MOUSE && e.mouseButton != MouseButton.LEFT ) return;
			if (e.x != mouse_start_x || e.y != mouse_start_y) updateUrlParams();

			mouse_mode = false;
		}
	}
	
	function pointerMove(_, e:PointerEvent) {
		if (e.type == PointerType.TOUCH)
		{
			// trace("UI->onPointerMove TOUCH");		
			active_touch_id.set(e.touch.id, { x: e.x, y: e.y });

			if (active_touches.length == 1) {
				// simple DRAG by one touchpoint only
				var t = active_touch_id.get(e.touch.id);
				positionX.value = touch_position_start_x + (e.x - touch_start_x);
				positionY.value = touch_position_start_y + (e.y - touch_start_y);
			}
			else if (e.touch.id == active_touches[0] || e.touch.id == active_touches[1]) {
				// DRAGGING the Center of the latest pressed two touchpoints
				var t0 = active_touch_id.get(active_touches[0]);
				var t1 = active_touch_id.get(active_touches[1]);

				positionX.value = touch_position_start_x + (t0.x + t1.x)/2 - touch_start_x;
				positionY.value = touch_position_start_y + (t0.y + t1.y)/2 - touch_start_y;

				// ZOOMING by distance between the two latest pressed touchpoints
				var scale_new_value = touch_scale_start * Math.sqrt( (t0.x - t1.x)*(t0.x - t1.x) + (t0.y - t1.y)*(t0.y - t1.y) ) / touch_start_distance;

				var x:Float = (t0.x + t1.x)/2;
				var y:Float = (t0.y + t1.y)/2;

				if ( scale_new_value > 0.0001 && scale_new_value < 0xfffff) {
					positionX.value -= (scale_new_value/touch_scale_start) * (x - positionX.value) - (x - positionX.value);
					positionY.value -= (scale_new_value/touch_scale_start) * (y - positionY.value) - (y - positionY.value);
					scaleX.value = scaleY.value = scale_new_value;
				}
			} 


		}
		else // ----- MOUSE MOVE -------
		{
			// trace("UI->onPointerMove MOUSE");
			mouse_x = e.x;
			mouse_y = e.y;		
			if (!touch_mode && mouse_mode) {
				positionX.value = (mouse_start_x + mouse_x);
				positionY.value = (mouse_start_y + mouse_y);
			}
		}
	}

	public function mouseWheel(deltaX:Float, deltaY:Float, deltaMode:MouseWheelMode, isShift:Bool, zoomstep:Float = 1.2) {
		if (mouse_x >= mainArea.x && mouse_y <= mainArea.bottom) return;
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
}

