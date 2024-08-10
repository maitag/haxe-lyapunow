package ui;

import peote.text.Font;

import peote.view.Color;
import peote.view.UniformFloat;

import peote.ui.interactive.UITextLine;
import peote.ui.interactive.UIArea;

import peote.ui.config.TextConfig;
import peote.ui.config.AreaConfig;

import peote.ui.style.interfaces.Style;
import peote.ui.style.BoxStyle;
import peote.ui.style.RoundBorderStyle;

import peote.ui.event.PointerEvent;
import peote.ui.event.WheelEvent;

import peote.ui.interactive.interfaces.ParentElement;

class UiMainArea extends UIArea implements ParentElement
{
	var uniformFloats:Array<UniformFloat>;

	public var formulaInput:UITextLine<UiFontStyle>;
	public var sequenceInput:UITextLine<UiFontStyle>;

	public var iterMainArea:UiParamArea;


	public function new(
		uniformFloats:Array<UniformFloat>,
		xPosition:Int, yPosition:Int, width:Int, height:Int, zIndex:Int = 0,
		?config:AreaConfig
	) 
	{
		this.uniformFloats = uniformFloats;
		super(xPosition, yPosition, width, height, zIndex, config);
		
		// -----------------------------------------------------------
		// ---- creating an Area, header and Content-Area ------------
		// -----------------------------------------------------------
		
		var headerSize:Int = 20;
		var gap:Int = 4;		
		
		var textConfig:TextConfig = {
			backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205),
			selectionStyle: Ui.selectionStyle,
			cursorStyle: Ui.cursorStyle,
			textSpace: { left:5, right:5, top:5, bottom:5 },
			undoBufferSize:50
		}
		// --------------------------
		// ---- header textline -----		
		// --------------------------
/*		
		var header = new UITextLine<UiFontStyle>(gap, gap,
			width - gap - gap, headerSize, 
			"Shader Code", fontUi, fontStyleUi, { backgroundStyle:bgStyleHeader, hAlign:HAlign.CENTER }
		);
		// start/stop area-dragging
		header.onPointerDown = (_, e:PointerEvent)-> startDragging(e);
		header.onPointerUp = (_, e:PointerEvent)-> stopDragging(e);
		add(header);
		
*/		
		// --------------------------
		// ------- formula --------
		// --------------------------
		
		formulaInput = new UITextLine<UiFontStyle>(gap, gap + 1,
			width - gap - gap - 1,
			Std.int(Ui.fontStyle.height) + textConfig.textSpace.top + textConfig.textSpace.bottom,
			"2.5*sin(i+n)^2+3",
			Ui.font, Ui.fontStyle, textConfig
		);
		
		formulaInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}
		
		formulaInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		add(formulaInput);
		
		formulaInput.onInsertText = formulaInput.onDeleteText = function(t, from:Int, to:Int, value:String) {
			trace("formula on change",from, to, value);
		}
		
		// --------------------------
		// ------- sequence --------
		// --------------------------
		
		sequenceInput = new UITextLine<UiFontStyle>(gap, formulaInput.bottom + gap + 1,
			width - gap - gap - 1,
			Std.int(Ui.fontStyle.height) + textConfig.textSpace.top + textConfig.textSpace.bottom,
			"xy",
			Ui.font, Ui.fontStyle, textConfig
		);
		
		sequenceInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}
		
		sequenceInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		add(sequenceInput);
		
		// sequenceInput.onChange


		// --------------------------
		// ------- parameter --------
		// --------------------------

		var sliderHeight:Int = 26;

		iterMainArea = new UiParamArea( "Main Iteration:", 3.0, 1.0, 4.0,
			120,
			gap, sequenceInput.bottom + gap,
			width - gap - gap, Std.int(Ui.fontStyle.height) + sliderHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
			// { backgroundStyle:null }
		);
		iterMainArea.onChange = (v:Float) -> {
			uniformFloats[0].value = v;
		};
		add(iterMainArea);


		
				
		// --- re-arrange inner content if area size is changing ---
		
		// TODO: outside ?
		onResizeWidth = (_, width:Int, deltaWidth:Int) -> {
			formulaInput.width = width - gap - gap - 1;
			sequenceInput.width = formulaInput.width;
			iterMainArea.width = formulaInput.width;
		}

		onResizeHeight = (_, height:Int, deltaHeight:Int) -> {
			
		}


	}	

	
	// TODO
	public function setParams() {
	}
}
