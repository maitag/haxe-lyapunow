package ui;

import peote.ui.config.TextConfig;
import peote.ui.config.AreaConfig;
import peote.ui.interactive.UIArea;
import peote.ui.interactive.UITextLine;
import peote.ui.interactive.interfaces.ParentElement;

import Param.DefaultParams;

class UiMainArea extends UIArea implements ParentElement
{
	var defaultParams:DefaultParams;

	public var formulaInput:UITextLine<UiFontStyle>;
	public var sequenceInput:UITextLine<UiFontStyle>;

	public var iterMainArea:UiParamArea;
	public var iterPreArea:UiParamArea;
	public var startIndexArea:UiParamArea;
	public var balanceArea:UiParamArea;

	public function new(
		defaultParams:DefaultParams,
		xPosition:Int, yPosition:Int, width:Int, height:Int, zIndex:Int = 0,
		?config:AreaConfig
	) 
	{
		this.defaultParams = defaultParams;
		super(xPosition, yPosition, width, height, zIndex, config);
		
		// -----------------------------------------------------------
		// ---- creating an Area, header and Content-Area ------------
		// -----------------------------------------------------------
		
		var leftSpace:Int = 4;
		var rightSpace:Int = 4;
		var topSpace:Int = 2;
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
		
		formulaInput = new UITextLine<UiFontStyle>(leftSpace, topSpace,
			width - leftSpace - rightSpace,
			Std.int(Ui.fontStyle.height) + textConfig.textSpace.top + textConfig.textSpace.bottom,
			Ui.formula,
			Ui.font, Ui.fontStyle, textConfig
		);
		formulaInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}
		formulaInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		formulaInput.onInsertText = formulaInput.onDeleteText = function(t, from:Int, to:Int, value:String) {
			// trace("formula on change",from, to, value);
			Ui.formula = t.text;
			Ui.formulaChanged = true;
		}
		add(formulaInput);
		
		// --------------------------
		// ------- sequence ---------
		// --------------------------
		
		sequenceInput = new UITextLine<UiFontStyle>(leftSpace, formulaInput.bottom + gap,
			width - leftSpace - rightSpace,
			Std.int(Ui.fontStyle.height) + textConfig.textSpace.top + textConfig.textSpace.bottom,
			Ui.sequence,
			Ui.font, Ui.fontStyle, textConfig
		);		
		sequenceInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}		
		sequenceInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		sequenceInput.onInsertText = sequenceInput.onDeleteText = function(t, from:Int, to:Int, value:String) {
			trace("sequenceInput on change",from, to, value);
			Ui.sequence = t.text;
			Ui.sequenceChanged = true;
		}

		// Todo: 
		// sequenceInput.onChange
		
		add(sequenceInput);
		


		// -------------------------------------
		// ------- areas for parameters --------
		// -------------------------------------

		var paramAreaHeight:Int = Std.int(Ui.fontStyle.height) + 24;
		var paramAreaWidth:Int = width - leftSpace - rightSpace;
		var _y:Int = sequenceInput.bottom + gap;

		// -------------------------------------

		startIndexArea = new UiParamArea( defaultParams.startIndex,
			leftSpace, _y, paramAreaWidth, paramAreaHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
		);
		add(startIndexArea);

		// -------------------------------------
		_y += paramAreaHeight + gap;

		iterPreArea = new UiParamArea( defaultParams.iterPre,
			leftSpace, _y, paramAreaWidth, paramAreaHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
		);
		add(iterPreArea);

		// -------------------------------------
		_y += paramAreaHeight + gap;

		iterMainArea = new UiParamArea( defaultParams.iterMain,
			leftSpace, _y, paramAreaWidth, paramAreaHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
		);
		add(iterMainArea);

		// -------------------------------------
		_y += paramAreaHeight + gap;

		balanceArea = new UiParamArea( defaultParams.balance,
			leftSpace, _y, paramAreaWidth, paramAreaHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
		);
		add(balanceArea);


		
				
		// --- re-arrange inner content if area size is changing ---
		
		// TODO: outside ?
		onResizeWidth = (_, width:Int, deltaWidth:Int) -> {
			formulaInput.width = 
			sequenceInput.width =
			startIndexArea.width =
			iterPreArea.width =
			iterMainArea.width =
			balanceArea.width = width - leftSpace - rightSpace;
		}

		onResizeHeight = (_, height:Int, deltaHeight:Int) -> {
			
		}


	}	

	
	// TODO
	public function setParams() {
	}
}
