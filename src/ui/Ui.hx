package ui;

import peote.view.PeoteView;
import peote.view.Color;

// import peote.text.Font;

import peote.ui.PeoteUIDisplay;
import peote.ui.style.RoundBorderStyle;
import peote.ui.style.BoxStyle;

import peote.ui.interactive.UISlider;

import peote.ui.config.TextConfig;
import peote.ui.config.ResizeType;
// import peote.ui.event.*;

class Ui
{
	var peoteView:PeoteView;
	var peoteUiDisplay:PeoteUIDisplay;
	var onInit:Void->Void;

	var mainArea:UiMainArea;
	var mainSlider:UISlider;

	public function new(peoteView:PeoteView, onInit:Void->Void)
	{
		this.peoteView = peoteView;
		this.onInit = onInit;

		// load font for UI
		new peote.text.Font<UiFontStyle>("assets/hack_ascii.json").load( onFontLoaded );
	}

	public function onFontLoaded(font:peote.text.Font<UiFontStyle>)
	{
		// ---- background layer styles -----

		var roundBorderStyle = RoundBorderStyle.createById(0);
		roundBorderStyle.borderRadius = 7;
		
		var boxStyle  = BoxStyle.createById(0);
		var selectionStyle = BoxStyle.createById(1, Color.GREY3);
		var cursorStyle = BoxStyle.createById(2, 0xaa2211ff);

		var fontStyle = new UiFontStyle();
		
		
		// -------------------------------------------------------
		// --- PeoteUIDisplay with styles in Layer-Depth-Order ---
		// -------------------------------------------------------
		
		peoteUiDisplay = new PeoteUIDisplay(0, 0, peoteView.width, peoteView.height,
			[ boxStyle, roundBorderStyle, selectionStyle, fontStyle, cursorStyle ]
		);
		peoteView.addDisplay(peoteUiDisplay);
		




		// --------------------------------
		// ---------- main menu -----------
		// --------------------------------

		// TODO







		// --------------------------------
		// --------- main area ------------
		// --------------------------------
		
		var textConfig:TextConfig = {
			backgroundStyle:roundBorderStyle.copy(Color.GREY5),
			selectionStyle: selectionStyle,
			cursorStyle: cursorStyle,
			textSpace: { left:3, right:1, top:1, bottom:1 },
			undoBufferSize:100
		}
					
		mainArea = new UiMainArea(
			500, 0, 300, 400, 0,
				font,
				fontStyle,
				// boxStyle,
				textConfig,
				{backgroundStyle:roundBorderStyle, resizeType:ResizeType.LEFT|ResizeType.BOTTOM|ResizeType.BOTTOM_LEFT, minWidth:200, minHeight:100}
		);	
		peoteUiDisplay.add(mainArea);

		// ------------------------------------
		// ---- slider to scroll main area ----		
		// ------------------------------------
		/*		
		mainSlider = new UISlider(mainArea.right, mainArea.top, 20, mainArea.height, {
			backgroundStyle: roundBorderStyle.copy(Color.GREY2),
			draggerStyle: roundBorderStyle.copy(Color.GREY3, Color.GREY2, 0.5),
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
	var widthBeforeOverflow:Int = 0;
	var heightIsOverflow = false;
	var heightBeforeOverflow:Int = 0;
	var mainArea_oldHeight:Int = 0;

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

