package ui;

import lime.ui.MouseCursor;
import peote.ui.interactive.UITextLine;
import peote.ui.interactive.UIArea;
import peote.ui.interactive.UISlider;
import peote.ui.config.TextConfig;
import peote.ui.config.AreaConfig;
import peote.ui.config.SliderConfig;
import peote.ui.event.PointerEvent;
import peote.ui.event.WheelEvent;
import peote.ui.interactive.interfaces.ParentElement;

import Param;

class UiParamArea extends UIArea implements ParentElement
{
	public var labelText:UITextLine<UiFontStyle>;
	public var valueInput:UITextLine<UiFontStyle>;
	public var slider:UISlider;

	public var param:Param;

	public function new( param:Param,
		xPosition:Int, yPosition:Int, width:Int, height:Int, zIndex:Int = 0,
		?config:AreaConfig
	)
	{
		this.param = param;

		super(xPosition, yPosition, width, height, zIndex, config);
		
		var labelWidth:Int = 120;
		
		var labelTextConfig:TextConfig = {
			backgroundStyle:Ui.paramStyleFG.copy(0x11150f44, null, 0.0),
			textSpace: { left:5, right:5, top:1, bottom:1 }
		}
		
		// --------------------------
		// ----- label textline -----
		// --------------------------
		var fontStyleLabel = Ui.fontStyle.copy(0x55f011ff);
		labelText = new UITextLine<UiFontStyle>(1, 1,
			0,
			Std.int(Ui.fontStyle.height) + labelTextConfig.textSpace.top + labelTextConfig.textSpace.bottom,
			param.label, Ui.font, fontStyleLabel, labelTextConfig
		);
		// labelText.onPointerDown = (_, e:PointerEvent)-> {trace("switch");};
		add(labelText);
		
		// -----------------------------------------------------
		// ------------ number input ---------------------------
		// -----------------------------------------------------
		
		var paramTextConfig:TextConfig = {
			backgroundStyle:Ui.paramStyleFG.copy(0x00000044, null, 0.0),
			selectionStyle: Ui.selectionStyle,
			cursorStyle: Ui.cursorStyle,
			textSpace: { left:5, right:5, top:1, bottom:1 },
			undoBufferSize:30
		}
		
		// --------  value ----------
		
		valueInput = new UITextLine<UiFontStyle>(labelWidth, 1,
			width - labelWidth - 1,
			Std.int(Ui.fontStyle.height) + paramTextConfig.textSpace.top + paramTextConfig.textSpace.bottom,
			('${param.value}':String),
			Ui.font, Ui.fontStyle, paramTextConfig
		);
		
		valueInput.restrictedChars = "0-9.-";

		valueInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}
		
		valueInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		
		valueInput.onInsertText = valueInput.onDeleteText = function(t:UITextLine<UiFontStyle>, from:Int, to:Int, s:String) {
			var value:Float = Std.parseFloat(t.text);
			if (value < slider.valueStart) {
				slider.setValue( slider.valueStart, false);
				onChange(slider.valueStart);
			}
			else if (value > slider.valueEnd ) {
				slider.setValue(slider.valueEnd, false);
				onChange(slider.valueEnd);
			}
			else if (!Math.isNaN(value)) {
				slider.setValue(value, false);
				onChange(value);
			}
		}
		
		valueInput.onMouseWheel = function(t:UITextLine<UiFontStyle>, e:WheelEvent ) {
			var value:Float = Std.parseFloat(t.text);

			var dot_position = t.text.indexOf('.');
			if (dot_position < 0) dot_position = t.text.length;

			var offset:Float = 0.0;

			var exponent:Int = t.cursor - dot_position;

			if (exponent == 0) exponent++;
			if (exponent > 0) {
				offset = 1/(Math.pow(10,exponent));
			}
			else {
				exponent = - exponent - 1;
				offset = Math.pow(10,exponent);
			}

			if (e.deltaY > 0) value += offset else value -= offset;

			// OK, the LOGIC works -> now only need to update the text ;:)
			t.setText(('$value':String));
			t.xOffset = 0;
			t.updateVisibleLayout();
			slider.setValue(value, false);
			onChange(value);
		}

		add(valueInput);

		// ---------------------------
		// -------- slider -----------
		// ---------------------------
		
		var sliderConfig:SliderConfig = {
			
			draggerStyle: Ui.paramStyleFG.copy(0xbbdd22bb),
			
			//vertical:true,
			//reverse:true,
			value: param.value,
			valueStart: param.valueStart,
			valueEnd: param.valueEnd,
			
			//draggerSpace:{left:15, right:15},
			//backgroundSpace:{left:50},

			//backgroundLengthPercent:0.9,
			backgroundSizePercent:0.3,
			
			draggerLength:30,
			draggerLengthPercent:0.1,
			
			draggerSize:20,
			// draggerSizePercent:0.75,
			
			//draggerOffset:0,
			// draggerOffsetPercent:0.5,
			
			draggSpaceStart:0,
			draggSpaceEnd:0,
		};
		
		slider = new UISlider(1, Std.int(Ui.fontStyle.height), width - 1, height-Std.int(Ui.fontStyle.height), sliderConfig);
		slider.onMouseWheel = function(s:UISlider, e:WheelEvent) {
			//s.value += e.deltaY * 0.1;
			//s.setValue (s.value - e.deltaY * 0.05);
			s.setWheelDelta(1.0 - e.deltaY);
		}
		slider.onChange = function(s:UISlider, value:Float, percent:Float) {
			// trace( 'slider value:$value, percent:$percent' );
			valueInput.setText(('$value':String));
			valueInput.xOffset = 0;
			valueInput.updateVisibleLayout();
			onChange(value);
		}
		add(slider);
		
		// slider.updateDragger();
		


		// --- re-arrange inner content if area size is changing ---
		
		// TODO: outside ?
		onResizeWidth = (_, width:Int, deltaWidth:Int) -> {
			valueInput.width = width - labelWidth - 1;

			slider.width = width - 2;
		}

		onResizeHeight = (_, height:Int, deltaHeight:Int) -> {
			
		}


	}	

	public function onChange(value:Float) {
		param.value = value;
	}
}
