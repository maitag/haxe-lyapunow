package ui;

import peote.view.PeoteView;
import peote.view.Color;
import peote.view.UniformFloat;

import peote.text.Font;

import peote.ui.PeoteUIDisplay;
import peote.ui.style.RoundBorderStyle;
import peote.ui.style.BoxStyle;

import peote.ui.interactive.UISlider;

import peote.ui.config.TextConfig;
import peote.ui.config.ResizeType;
// import peote.ui.event.*;

class Ui
{
	// statics
	public static var font:Font<UiFontStyle>;
	public static var fontStyle = new UiFontStyle();

	public static var roundStyle = RoundBorderStyle.createById(0);
	public static var boxStyle  = BoxStyle.createById(0);
	public static var selectionStyle = BoxStyle.createById(1, Color.GREY3);
	public static var cursorStyle = BoxStyle.createById(2, 0xaa2211ff);



	var peoteView:PeoteView;
	var peoteUiDisplay:PeoteUIDisplay;
	var onInit:Void->Void;

	var mainArea:UiMainArea;
	var mainSlider:UISlider;

	var uniformFloats:Array<UniformFloat>;

	public function new(peoteView:PeoteView, uniformFloats:Array<UniformFloat>, onInit:Void->Void)
	{
		this.peoteView = peoteView;
		this.uniformFloats = uniformFloats;
		this.onInit = onInit;

		// load font for UI
		new Font<UiFontStyle>("assets/hack_ascii.json").load( onFontLoaded );
	}

	public function onFontLoaded(font:Font<UiFontStyle>)
	{
		Ui.font = font;

		// ---- layer styles props -----
		
		fontStyle.color = 0xc0f232ff;
		roundStyle.borderRadius = 7;
		
		
		// -------------------------------------------------------
		// --- PeoteUIDisplay with styles in Layer-Depth-Order ---
		// -------------------------------------------------------
		
		peoteUiDisplay = new PeoteUIDisplay(0, 0, peoteView.width, peoteView.height,
			[ boxStyle, roundStyle, selectionStyle, fontStyle, cursorStyle ]
		);
		peoteView.addDisplay(peoteUiDisplay);
		




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
			uniformFloats,
			peoteView.width - widthBeforeOverflow, 0,
			widthBeforeOverflow, 400,
			{ backgroundStyle:roundStyle.copy(0x00002266), resizeType:ResizeType.LEFT|ResizeType.BOTTOM|ResizeType.BOTTOM_LEFT, minWidth:200, minHeight:200 }
		);	
		peoteUiDisplay.add(mainArea);
		mainArea.updateLayout(); // is need for inner UIAreas

		// ------------------------------------
		// ---- slider to scroll main area ----		
		// ------------------------------------
		/*		
		mainSlider = new UISlider(mainArea.right, mainArea.top, 20, mainArea.height, {
			backgroundStyle: roundStyle.copy(Color.GREY2),
			draggerStyle: roundStyle.copy(Color.GREY3, Color.GREY2, 0.5),
			draggerSize:14,
			draggSpace:1,
		});
		peoteUiDisplay.add(mainSlider);
		mainSlider.onMouseWheel = (_, e:WheelEvent) -> mainSlider.setWheelDelta(e.deltaY); //.setDelta( e.deltaY * 15);

		// bind slider to mainArea
		mainArea.bindVSlider(mainSlider);
		*/

		/*
		\o/
		*/
		// ---------------------------------------------------------
		PeoteUIDisplay.registerEvents(peoteView.window);

		onInit();
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
		
		mainArea.updateLayout();
	}


}

