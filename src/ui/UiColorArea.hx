package ui;

import peote.ui.interactive.UITextLine;
import peote.ui.interactive.UIArea;
import peote.ui.interactive.UISlider;
import peote.ui.config.TextConfig;
import peote.ui.config.AreaConfig;
import peote.ui.config.SliderConfig;
import peote.ui.event.PointerEvent;
import peote.ui.event.WheelEvent;
import peote.ui.interactive.interfaces.ParentElement;

import peote.view.Color;

import Param;

class UiColorArea extends UIArea implements ParentElement
{
	public var labelText:UITextLine<UiFontStyle>;
	public var sliderR:UISlider;
	public var sliderG:UISlider;
	public var sliderB:UISlider;

	public var color:Color;


	public function new( label:String, color:Color, updateColor:Color -> Void,
		xPosition:Int, yPosition:Int, width:Int, height:Int, sliderHeight:Int, zIndex:Int = 0,
		?config:AreaConfig
	)
	{
		this.color = color;

		super(xPosition, yPosition, width, height, zIndex, config);
		
		var labelWidth:Int = 120;
		
		var labelTextConfig:TextConfig = {
			backgroundStyle:Ui.roundStyle.copy(0x11150f44, null, 0.0),
			textSpace: { left:5, right:5, top:1, bottom:1 }
		}
		
		// --------------------------
		// ----- label textline -----
		// --------------------------
		var fontStyleLabel = Ui.fontStyle.copy(0x55f011ff);
		labelText = new UITextLine<UiFontStyle>(1, 1,
			0,
			Std.int(Ui.fontStyle.height) + labelTextConfig.textSpace.top + labelTextConfig.textSpace.bottom,
			label,
			Ui.font, fontStyleLabel, labelTextConfig
		);
		labelText.onPointerDown = (_, e:PointerEvent)-> {trace("LATER");};
		add(labelText);
		

		// ---------------------------
		// -------- slider -----------
		// ---------------------------
		
		var sliderConfig:SliderConfig = {
			draggerStyle: Ui.roundStyle.copy(0xbbdd22bb),
			
			draggerLength:30,
			draggerLengthPercent:0.1,
			
			draggerSize:20,
						
			draggSpaceStart:0,
			draggSpaceEnd:0,
		};
		
		// ------ slider for red color

		var _y:Int = Std.int(Ui.fontStyle.height);
		
		sliderR = new UISlider(1, _y, width - 1, sliderHeight, sliderConfig);
		sliderR.onMouseWheel = function(s:UISlider, e:WheelEvent) {
			s.setWheelDelta(1.0 - e.deltaY);
		}
		sliderR.onChange = function(s:UISlider, value:Float, percent:Float) {
			color.rF = value;
			updateColor(color);
		}
		sliderR.value = color.rF;
		add(sliderR);
		
		// ------ slider for green color
		_y += sliderHeight + 1;
		
		sliderG = new UISlider(1, _y, width - 1, sliderHeight, sliderConfig);
		sliderG.onMouseWheel = function(s:UISlider, e:WheelEvent) {
			s.setWheelDelta(1.0 - e.deltaY);
		}
		sliderG.onChange = function(s:UISlider, value:Float, percent:Float) {
			color.gF = value;
			updateColor(color);
		}
		sliderG.value = color.gF;
		add(sliderG);
		
		// ------ slider for blue color
		_y += sliderHeight + 1;

		sliderB = new UISlider(1, _y, width - 1, sliderHeight, sliderConfig);
		sliderB.onMouseWheel = function(s:UISlider, e:WheelEvent) {
			s.setWheelDelta(1.0 - e.deltaY);
		}
		sliderB.onChange = function(s:UISlider, value:Float, percent:Float) {
			color.bF = value;
			updateColor(color);
		}
		sliderB.value = color.bF;
		add(sliderB);
		

		// --- re-arrange inner content if area size is changing ---
		
		// TODO: outside ?
		onResizeWidth = (_, width:Int, deltaWidth:Int) -> {
			sliderR.width = sliderG.width = sliderB.width = width - 2;
		}

		onResizeHeight = (_, height:Int, deltaHeight:Int) -> {
			
		}


	}	

	public function onChange(value:Float) {
		//todo
	}
}
