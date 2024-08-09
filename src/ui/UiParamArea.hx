package ui;

import peote.text.Font;
import peote.view.Color;

import peote.ui.interactive.UITextLine;
import peote.ui.interactive.UIArea;
import peote.ui.interactive.UISlider;

import peote.ui.config.TextConfig;
import peote.ui.config.AreaConfig;
import peote.ui.config.SliderConfig;
import peote.ui.config.HAlign;
import peote.ui.config.VAlign;

import peote.ui.style.interfaces.Style;
import peote.ui.style.BoxStyle;
import peote.ui.style.RoundBorderStyle;

import peote.ui.event.PointerEvent;
import peote.ui.event.WheelEvent;

import peote.ui.interactive.interfaces.ParentElement;

class UiParamArea extends UIArea implements ParentElement
{
	public var labelText:UITextLine<UiFontStyle>;
	public var startInput:UITextLine<UiFontStyle>;
	public var valueInput:UITextLine<UiFontStyle>;
	public var endInput:UITextLine<UiFontStyle>;
	public var slider:UISlider;

	public var onChange:Float->Void;

	public function new(
		label:String,
		labelWidth:Int,
		xPosition:Int, yPosition:Int, width:Int, height:Int, zIndex:Int = 0,
		font:Font<UiFontStyle>,
		fontStyle:UiFontStyle,
		boxStyle:BoxStyle,
		roundStyle:RoundBorderStyle,
		selectionStyle: Style,
		cursorStyle: Style,
		?config:AreaConfig
	) 
	{
		super(xPosition, yPosition, width, height, zIndex, config);
		
		var gap:Int = 4;

		var labelTextConfig:TextConfig = {
			// backgroundStyle:roundStyle.copy(0x55000032, 0xddff2255),
			backgroundStyle:roundStyle.copy(0x11150fbb, 0x11150fbb),
			// selectionStyle: selectionStyle,
			// cursorStyle: cursorStyle,
			textSpace: { left:5, right:5, top:1, bottom:1 },
			undoBufferSize:100
		}
		
		// --------------------------
		// ----- label textline -----
		// --------------------------
		var fontStyleLabel = fontStyle.copy(Color.GREEN3);
		labelText = new UITextLine<UiFontStyle>(0, 0, labelWidth, Std.int(fontStyle.height),
			// "main iteration", font, fontStyleLabel, { backgroundStyle:roundStyle.copy(Color.GREY1, Color.GREY1), hAlign:HAlign.LEFT, vAlign:VAlign.CENTER, textSpace:{left:4} }
			label, font, fontStyleLabel, labelTextConfig
		);
		// start/stop area-dragging
		labelText.onPointerDown = (_, e:PointerEvent)-> {trace("switch");};
		add(labelText);
		

		// ------------ PARAMETERS -----------------------------
		
		var textConfig:TextConfig = {
			// backgroundStyle:roundStyle.copy(0x55000032, 0xddff2255),
			backgroundStyle:roundStyle.copy(0x00000055, 0x33332255), //roundStyle.copy(0x11150fbb, 0xddff2205),
			selectionStyle: selectionStyle,
			cursorStyle: cursorStyle,
			textSpace: { left:5, right:5, top:1, bottom:1 },
			undoBufferSize:100
		}
		
		// ---------------------------
		// --------  values ----------
		// ---------------------------
		
		startInput = new UITextLine<UiFontStyle>(labelWidth + gap, 0,
			width - labelWidth - gap,
			Std.int(fontStyle.height),
			"3.14",
			font, fontStyle, textConfig
		);
		
		startInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}
		
		startInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		
		startInput.onInsertText = startInput.onDeleteText = function(t, from:Int, to:Int, value:String) {
			trace("startInput on change",from, to, value);
		}
		// add(startInput);
		
		
		// ---------------------------
		
		valueInput = new UITextLine<UiFontStyle>(labelWidth + gap, 0,
			width - labelWidth - gap,
			Std.int(fontStyle.height),
			"1",
			font, fontStyle, textConfig
		);
		
		valueInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}
		
		valueInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		
		valueInput.onInsertText = valueInput.onDeleteText = function(t, from:Int, to:Int, s:String) {
			var v:Float = Std.parseFloat(valueInput.text);
			if (v >= slider.valueStart && v <= slider.valueEnd ) slider.setValue(v, false);
		}
		
		add(valueInput);


		// ---------------------------
		// -------- slider -----------
		// ---------------------------
		
		var sliderConfig:SliderConfig = {
			// backgroundStyle: roundStyle,
			draggerStyle: roundStyle.copy(0xbbdd22bb),
			
			//vertical:true,
			//reverse:true,
			value: 1,
			valueStart: 1,
			valueEnd: 25,
			
			//draggerSpace:{left:15, right:15},
			//backgroundSpace:{left:50},

			//backgroundLengthPercent:0.9,
			backgroundSizePercent:0.3,
			
			draggerLength:30,
			draggerLengthPercent:0.1,
			
			draggerSize:20,
			draggerSizePercent:0.75,
			
			//draggerOffset:0,
			// draggerOffsetPercent:0.5,
			
			draggSpaceStart:2,
			draggSpaceEnd:2,
		};
		
		slider = new UISlider(0, Std.int(fontStyle.height), width, height-Std.int(fontStyle.height), sliderConfig);
		//slider.valueStart = -5;
		//slider.valueEnd = 10;
		slider.onMouseWheel = function(s:UISlider, e:WheelEvent) {
			//s.value += e.deltaY * 0.1;
			//s.setValue (s.value - e.deltaY * 0.05);
			s.setWheelDelta(e.deltaY);
		}
		slider.onChange = function(s:UISlider, value:Float, percent:Float) {
			// trace( 'slider value:$value, percent:$percent' );
			valueInput.setText(('$value':String), null, null, false);
			valueInput.update();
			onChange(value);
		}
		add(slider);
		
		//slider.reverse = true;
		//slider.value = -2;
		// slider.updateDragger();
		
		

		








		// --- re-arrange inner content if area size is changing ---
		
		// TODO: outside ?
		onResizeWidth = (_, width:Int, deltaWidth:Int) -> {
			startInput.width = width - labelWidth - gap;
			valueInput.width = width - labelWidth - gap;

			slider.width = width;
		}

		onResizeHeight = (_, height:Int, deltaHeight:Int) -> {
			
		}


	}	


}
