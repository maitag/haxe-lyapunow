package ui;

// import peote.text.Font;

import peote.ui.interactive.UITextLine;
import peote.ui.interactive.UIArea;

import peote.ui.config.TextConfig;
import peote.ui.config.AreaConfig;

// import peote.ui.style.interfaces.Style;
import peote.ui.event.PointerEvent;
import peote.ui.event.WheelEvent;

import peote.ui.interactive.interfaces.ParentElement;

class UiMainArea extends UIArea implements ParentElement
{
	public var formulaInput:UITextLine<UiFontStyle>;


	public function new(xPosition:Int, yPosition:Int, width:Int, height:Int, zIndex:Int = 0,
		font:peote.text.Font<UiFontStyle>,
		fontStyle:UiFontStyle,
		textConfig:TextConfig,
		?config:AreaConfig
	) 
	{
		super(xPosition, yPosition, width, height, zIndex, config);
		
		// -----------------------------------------------------------
		// ---- creating an Area, header and Content-Area ------------
		// -----------------------------------------------------------
		
		var headerSize:Int = 20;
		var gap:Int = 4;		
		
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
			Std.int(fontStyle.height) + 3,
			"2.5*sin(x+y)^2+3",
				font, fontStyle, textConfig
		);
		
		formulaInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}
		
		formulaInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		add(formulaInput);
		
		// formula.onChange
		
				
		// --- re-arrange inner content if area size is changing ---
		
		// TODO: outside ?
		onResizeWidth = (_, width:Int, deltaWidth:Int) -> {
			formulaInput.width = width - gap - gap - 1;
		}

		onResizeHeight = (_, height:Int, deltaHeight:Int) -> {
			
		}


	}	

	
	// TODO
	public function setParams() {
	}
}
